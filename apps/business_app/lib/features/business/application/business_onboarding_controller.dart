import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../domain/business_create_request.dart';

part 'business_onboarding_controller.g.dart';

/// In-memory draft state for the two-step business-onboarding form.
///
/// Business type is hardcoded to [BusinessType.restaurant] since this app
/// is for restaurants only. The form has two steps: details and review.
///
/// Deliberately **not** persisted to Drift — the form takes well under a
/// minute to fill in and the production resumability requirement is met by
/// re-checking onboarding-status on every restart and simply restarting the
/// form (see [BusinessOnboardingDraft] for the reasoning).
class BusinessOnboardingDraftState {
  const BusinessOnboardingDraftState({
    this.name = '',
    this.city = '',
    this.countryCode = defaultBusinessCountryCode,
    this.taxId,
  });

  final String name;
  final String city;
  final String countryCode;
  final String? taxId;

  BusinessOnboardingDraftState copyWith({
    String? name,
    String? city,
    String? countryCode,
    Object? taxId = _unset,
  }) {
    return BusinessOnboardingDraftState(
      name: name ?? this.name,
      city: city ?? this.city,
      countryCode: countryCode ?? this.countryCode,
      taxId: identical(taxId, _unset) ? this.taxId : taxId as String?,
    );
  }

  static const Object _unset = Object();
}

/// Holds the in-progress onboarding form **in memory only**.
///
/// ## Resumability rationale — why partial drafts are not persisted
///
/// Persisting partially-entered form fields to Drift would add a table, a
/// repository, serialisation and cleanup for almost no user value: the form
/// is two short steps that take under a minute to complete. Instead,
/// resumability across an app kill is achieved by treating the server as
/// the single source of truth:
///
/// 1. While the business has not been created, `GET /users/me/onboarding-
///    status` keeps returning `needs_onboarding=true`, so the splash path
///    re-checks it on every launch and routes the user straight back to
///    this form — they simply re-enter their details.
/// 2. The moment the form is submitted, the business exists server-side and
///    the server flips the flag, so a later restart no longer needs
///    onboarding at all.
///
/// Because the provider is `keepAlive: false` it is also discarded as soon
/// as the onboarding screen is popped, so stale in-memory state never leaks
/// into the next flow.
@Riverpod(keepAlive: false)
class BusinessOnboardingDraft extends _$BusinessOnboardingDraft {
  @override
  BusinessOnboardingDraftState build() => const BusinessOnboardingDraftState();

  void setName(String value) => state = state.copyWith(name: value);

  void setCity(String value) => state = state.copyWith(city: value);

  void setCountryCode(String value) =>
      state = state.copyWith(countryCode: value);

  void setTaxId(String value) =>
      state = state.copyWith(taxId: value.trim().isEmpty ? null : value.trim());
}