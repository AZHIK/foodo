/// High-level auth orchestration: OTP login, token management, device locking.
///
/// Handles the full auth flow:
/// 1. Request OTP for phone
/// 2. Verify OTP code → get tokens
/// 3. Check onboarding status
/// 4. Either: create business (owner) or switch context (invited staff)
/// 5. If the business already has a store, lock the device to the primary
///    one — a business with none yet (owner still mid-onboarding) leaves
///    the device unprovisioned rather than failing the login
/// 6. Persist tokens & profile
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../auth/auth_dtos.dart';
import '../auth/identity_service_api.dart';
import '../auth/jwt_decoder.dart';
import '../auth/token_refresh_interceptor.dart';
import '../auth/token_storage.dart';
import '../database/app_database.dart';
import '../database/local_profile_repository.dart';
import '../utils/pin_hasher.dart';
import 'database_providers.dart';

/// Auth flow state machine.
enum AuthState {
  unauthenticated,
  requestingOtp,
  verifyingOtp,
  checkingOnboarding,
  creatingBusiness,
  switchingContext,
  complete,
}

/// Auth context: tracks where we are in the login flow.
class AuthContext {
  final AuthState state;
  final String? phone;
  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final OnboardingStatusOutput? onboardingStatus;
  final String? selectedBusinessId;
  final String? selectedStoreId;
  final String? error;

  const AuthContext({
    this.state = AuthState.unauthenticated,
    this.phone,
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.onboardingStatus,
    this.selectedBusinessId,
    this.selectedStoreId,
    this.error,
  });

  /// True when the account has no name on file yet — set by the phone-first
  /// (OTP-only) signup path, which never asks for one. The UI routes to
  /// CompleteProfileScreen before continuing when this is true.
  bool get needsProfile => onboardingStatus?.needsProfile ?? false;

  String? get fullName => onboardingStatus?.fullName;

  AuthContext copyWith({
    AuthState? state,
    String? phone,
    String? accessToken,
    String? refreshToken,
    String? userId,
    OnboardingStatusOutput? onboardingStatus,
    String? selectedBusinessId,
    String? selectedStoreId,
    String? error,
  }) =>
      AuthContext(
        state: state ?? this.state,
        phone: phone ?? this.phone,
        accessToken: accessToken ?? this.accessToken,
        refreshToken: refreshToken ?? this.refreshToken,
        userId: userId ?? this.userId,
        onboardingStatus: onboardingStatus ?? this.onboardingStatus,
        selectedBusinessId: selectedBusinessId ?? this.selectedBusinessId,
        selectedStoreId: selectedStoreId ?? this.selectedStoreId,
        error: error ?? this.error,
      );
}

/// Orchestrates the auth flow.
class AuthNotifier extends Notifier<AuthContext> {
  late final IdentityServiceApi _api;
  late final TokenStorage _tokenStorage;
  late final LocalProfileRepository _profileRepo;

  @override
  AuthContext build() {
    _api = IdentityServiceApi(dio: ref.watch(identityServiceDioProvider));
    _tokenStorage = TokenStorage();
    _profileRepo = ref.watch(localProfileRepositoryProvider);

    // On build, check if tokens are already stored (returning user).
    _checkStoredSession();
    return const AuthContext();
  }

  /// Checks if a valid session is already stored locally.
  Future<void> _checkStoredSession() async {
    try {
      final tokenSet = await _tokenStorage.getTokenSet();
      if (tokenSet != null && !tokenSet.isExpired) {
        // Session exists and is valid. Restore it.
        state = state.copyWith(
          state: AuthState.complete,
          accessToken: tokenSet.accessToken,
          refreshToken: tokenSet.refreshToken,
          userId: tokenSet.userId,
        );
      }
    } catch (_) {
      // If storage read fails, continue without prior session.
    }
  }

  /// Step 1: Request OTP code for a phone number.
  Future<void> requestOtp(String phone) async {
    state = state.copyWith(state: AuthState.requestingOtp);
    try {
      await _api.requestOtp(phone);
      state = state.copyWith(
        phone: phone,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Step 2: Verify OTP code and get tokens.
  Future<void> verifyOtp(String code) async {
    state = state.copyWith(state: AuthState.verifyingOtp);
    try {
      final phone = state.phone;
      if (phone == null) throw StateError('Phone not set');

      final tokenOutput = await _api.verifyOtp(phone: phone, code: code);

      // Decode JWT to get user ID and expiry.
      final claims = decodeAccessToken(tokenOutput.accessToken);
      final userId = claims.sub;

      state = state.copyWith(
        state: AuthState.checkingOnboarding,
        accessToken: tokenOutput.accessToken,
        refreshToken: tokenOutput.refreshToken,
        userId: userId,
      );

      // Step 3: Check onboarding status.
      await _checkOnboarding(tokenOutput.accessToken);
    } catch (e) {
      state = state.copyWith(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Step 3: Check onboarding and branch.
  Future<void> _checkOnboarding(String accessToken) async {
    try {
      final onboardingStatus = await _api.getOnboardingStatus(accessToken);
      state = state.copyWith(onboardingStatus: onboardingStatus);

      // If user needs onboarding, they must create a business.
      // If not, they were invited and have a business already — switch to it.
      if (onboardingStatus.needsOnboarding) {
        // Flow stops here; caller proceeds to onboarding screen.
        // createBusinessAndOnboard will be called from the UI.
        state = state.copyWith(state: AuthState.complete);
      } else {
        // User has a business already (invited staff).
        final businessId = onboardingStatus.businessId;
        if (businessId != null) {
          await _switchContextAndLock(businessId, accessToken);
        }
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Records the caller's own name/email — the first thing a phone-first
  /// (OTP-only) signup does, since /auth/otp/verify never collects one.
  Future<void> completeProfile({
    required String fullName,
    String? email,
  }) async {
    try {
      final accessToken = state.accessToken;
      if (accessToken == null) throw StateError('No access token');

      final output = await _api.updateProfile(
        input: UpdateProfileInput(fullName: fullName, email: email),
        bearerToken: accessToken,
      );

      final status = state.onboardingStatus;
      state = state.copyWith(
        onboardingStatus: OnboardingStatusOutput(
          needsOnboarding: status?.needsOnboarding ?? true,
          businessId: status?.businessId,
          businessName: status?.businessName,
          fullName: output.fullName,
          email: output.email,
        ),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Create a business and lock the device to it (owner onboarding path).
  Future<void> createBusinessAndOnboard({
    required String name,
    required String address,
    required String phone,
    String? city,
    String? countryCode,
    String? timezone,
    String? taxId,
    String? registrationNumber,
    String? cuisineType,
    String? licenseDocumentUrl,
  }) async {
    try {
      state = state.copyWith(state: AuthState.creatingBusiness);

      final accessToken = state.accessToken;
      if (accessToken == null) throw StateError('No access token');

      final businessInput = BusinessCreateInput(
        name: name,
        businessType: 'restaurant',
        phone: phone,
        address: address,
        city: city,
        countryCode: countryCode ?? 'TZ',
        timezone: timezone ?? 'Africa/Dar_es_Salaam',
        taxId: taxId,
        registrationNumber: registrationNumber,
        cuisineType: cuisineType,
        licenseDocumentUrl: licenseDocumentUrl,
      );

      final businessOutput = await _api.createBusiness(
        input: businessInput,
        bearerToken: accessToken,
      );

      state = state.copyWith(selectedBusinessId: businessOutput.businessId);

      // Now switch context and lock to this business.
      await _switchContextAndLock(businessOutput.businessId, accessToken);

      // The owner's PIN (and LocalUserProfiles row) was already set before
      // reaching onboarding, so their role/business can be cached now,
      // explicitly, as soon as the business is saved. Invited staff get
      // this in setPin() instead — see that method for why the two flows
      // need separate write sites (LocalUserProfiles/CachedPermissions FK
      // ordering is reversed between them).
      if (state.userId != null &&
          state.selectedBusinessId != null &&
          state.selectedStoreId != null) {
        await _cachePermissions(
          userId: state.userId!,
          businessId: state.selectedBusinessId!,
          businessLocationId: state.selectedStoreId!,
          businessName: name,
          claims: decodeAccessToken(state.accessToken!),
        );
      }
    } catch (e) {
      state = state.copyWith(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Step 4: Switch context to business and lock device.
  Future<void> _switchContextAndLock(
    String businessId,
    String accessToken,
  ) async {
    try {
      state = state.copyWith(state: AuthState.switchingContext);

      // Call the context switch endpoint. This alone is what authenticates
      // the user into this business context — everything below is optional
      // device provisioning, not a login requirement.
      final switchOutput = await _api.switchContext(
        businessId: businessId,
        bearerToken: accessToken,
      );

      // Look up stores only to lock this terminal to one, if it already has
      // one. A business the owner hasn't finished setting up yet — or one
      // this account was invited to before any store existed — has none,
      // and that must not block login: the device just stays unprovisioned
      // (see DeviceConfig's doc comment) until a store exists to lock to.
      final stores = await _api.listStores(
        businessId: businessId,
        bearerToken: switchOutput.accessToken,
      );
      final primaryStore = stores.isEmpty
          ? null
          : stores.firstWhere((s) => s.isPrimary, orElse: () => stores.first);

      if (primaryStore != null) {
        final businessName = state.onboardingStatus?.businessName ?? 'Restaurant';
        await _profileRepo.provisionDevice(
          businessId: businessId,
          businessLocationId: primaryStore.id,
          businessName: businessName,
        );
      }

      // Save tokens (access token may have changed after context switch).
      final expiresAt = DateTime.now().add(
        const Duration(minutes: 15), // Assume 15-min TTL (env config default)
      );
      await _tokenStorage.saveTokenSet(
        TokenSet(
          accessToken: switchOutput.accessToken,
          refreshToken: switchOutput.refreshToken,
          expiresAt: expiresAt,
          userId: state.userId!,
        ),
      );

      state = state.copyWith(
        state: AuthState.complete,
        accessToken: switchOutput.accessToken,
        refreshToken: switchOutput.refreshToken,
        selectedBusinessId: businessId,
        selectedStoreId: primaryStore?.id,
      );
    } catch (e) {
      state = state.copyWith(
        state: AuthState.unauthenticated,
        error: e.toString(),
      );
      rethrow;
    }
  }

  /// Save PIN to local profile.
  ///
  /// Invited staff already have a business context by this point (their
  /// `_switchContextAndLock()` ran during `_checkOnboarding()`, before Set
  /// PIN) — so this is also where their real role and permissions get
  /// cached, from the access token's `roles`/`permissions` claims.
  ///
  /// This was originally an explicit lookup — `GET .../staff` (find self by
  /// user id) then `GET .../roles/{id}/permissions` per role — rather than
  /// trusting the token. That turned out to be backwards: both endpoints
  /// require admin-level permissions (`user_business_roles.view`,
  /// `business_roles.view`) that an ordinary invited staff member's own
  /// role doesn't carry, so the lookup 403s for anyone but a manager/owner.
  /// The backend's own authorization layer (`require_business_permission`,
  /// `require_business_context`) reads `roles`/`permissions`/
  /// `active_business_id` straight off these same decoded claims for every
  /// request — there is no more authoritative source available to a
  /// non-admin caller, so this uses that directly.
  ///
  /// A fresh owner has no business yet at this point (they onboard after
  /// Set PIN) — there is nothing to cache here for them; see
  /// `createBusinessAndOnboard()` for their write site.
  Future<void> setPin(String pin) async {
    try {
      final userId = state.userId;
      if (userId == null) throw StateError('User ID not set');

      final salt = PinHasher.generateSalt();
      final pinHash = PinHasher.hash(pin, salt);
      final now = DateTime.now();
      final claims = decodeAccessToken(state.accessToken!);

      // Create or update the profile.
      final name = state.fullName;
      await _profileRepo.upsertProfile(
        LocalUserProfilesCompanion(
          id: Value(userId),
          displayName: Value(name != null && name.isNotEmpty ? name : 'Staff Member'),
          pinHash: Value(pinHash),
          pinSalt: Value(salt),
          roleLabel: Value(claims.roles.isNotEmpty ? claims.roles.join(', ') : null),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      if (state.selectedBusinessId != null && state.selectedStoreId != null) {
        await _cachePermissions(
          userId: userId,
          businessId: state.selectedBusinessId!,
          businessLocationId: state.selectedStoreId!,
          businessName: state.onboardingStatus?.businessName ?? 'Restaurant',
          claims: claims,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  /// Refreshes the local RBAC cache for [userId] from [claims]. Callers must
  /// only invoke this once a `LocalUserProfiles` row for [userId] already
  /// exists (FK, cascade-delete) — see the two call sites (`setPin` and
  /// `createBusinessAndOnboard`) for why that's guaranteed differently for
  /// each account type.
  Future<void> _cachePermissions({
    required String userId,
    required String businessId,
    required String businessLocationId,
    required String businessName,
    required JwtClaims claims,
  }) {
    return _profileRepo.upsertPermissions(
      CachedPermissionsCompanion.insert(
        userId: userId,
        businessId: businessId,
        businessName: businessName,
        businessLocationId: businessLocationId,
        roleName: claims.roles.isNotEmpty ? claims.roles.join(', ') : 'Staff',
        permissionCodes: jsonEncode(claims.permissions),
        cachedAt: DateTime.now(),
      ),
    );
  }

  /// Reset state for next login.
  void reset() {
    state = const AuthContext();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthContext>(
  AuthNotifier.new,
);

/// Provides the Dio client for auth API calls (no bearer token yet).
///
/// Public (not `_dioClientProvider`) so tests can override it with a fake
/// `HttpClientAdapter` instead of hitting a live backend.
final identityServiceDioProvider = Provider<Dio>((ref) {
  const baseUrl = 'http://localhost:8009/api/v1';

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    sendTimeout: const Duration(seconds: 30),
  ));

  // Auto-attaches the current access token to every request and silently
  // refreshes-and-retries on a 401 — this is now the one real, working
  // client for every identity-service call (auth, business, staff/roles),
  // not a second parallel setup. Callers built against this provider don't
  // need to thread a bearer token through every method themselves.
  dio.interceptors.add(TokenRefreshInterceptor(
    tokenStorage: TokenStorage(),
    baseUrl: baseUrl,
  ));

  // Add logging for debugging.
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  return dio;
});
