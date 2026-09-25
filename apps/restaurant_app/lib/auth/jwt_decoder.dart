/// Simple JWT decoder for extracting claims client-side.
///
/// No signature verification — the token transport is already trusted
/// (received over TLS from login response, stored in secure storage).
/// Claims are used only for local bookkeeping (expiry check, user id),
/// not as a security boundary. The backend always re-validates the token
/// signature on every authenticated request.
library;

import 'dart:convert';

import '../constants/app_durations.dart';

/// Decoded JWT payload claims for a business-user access token (RS256).
class JwtClaims {
  final String sub; // user UUID
  final int exp; // expiry as epoch seconds
  final String? activeBusinessId;

  /// Store scope, set by POST /auth/context/switch-store. Business-staff
  /// tokens from login/business-switch carry none — the terminal's store
  /// then lives in AuthContext.selectedStoreId/DeviceConfig instead.
  final String? activeStoreId;

  /// `business_staff` vs `business_store_staff` — the switch UI is for the
  /// former only (the backend rejects the latter outright).
  final String? userCategory;
  final List<String> permissions;
  final List<String> roles;

  JwtClaims({
    required this.sub,
    required this.exp,
    this.activeBusinessId,
    this.activeStoreId,
    this.userCategory,
    this.permissions = const [],
    this.roles = const [],
  });

  bool get isBusinessStaff => userCategory == 'business_staff';

  /// True if the token carries [code], or the wildcard `*` (owner tokens).
  bool can(String code) => permissions.contains('*') || permissions.contains(code);

  /// Returns when this token expires as a DateTime.
  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);

  /// True if the token is already expired (or expires within 1 second).
  bool get isExpired {
    final now = DateTime.now().toUtc();
    return now.isAfter(expiresAt.subtract(AppDurations.jwtDecodeSkew));
  }
}

/// Decodes the payload segment of a JWT without verifying the signature.
JwtClaims decodeAccessToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException('JWT must have 3 parts (header.payload.signature)');
    }

    final payload = parts[1];
    // Add padding if needed (base64url drops trailing `=`).
    final padded = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
    final bytes = base64Url.decode(padded);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    return JwtClaims(
      sub: json['sub'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      activeBusinessId: json['active_business_id'] as String?,
      activeStoreId: json['active_store_id'] as String?,
      userCategory: json['user_category'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>() ?? const [],
      roles: (json['roles'] as List<dynamic>?)?.cast<String>() ?? const [],
    );
  } catch (e) {
    throw FormatException('Failed to decode JWT: $e');
  }
}
