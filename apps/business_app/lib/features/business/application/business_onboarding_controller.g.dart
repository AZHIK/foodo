// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_onboarding_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(BusinessOnboardingDraft)
final businessOnboardingDraftProvider = BusinessOnboardingDraftProvider._();

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
final class BusinessOnboardingDraftProvider
    extends
        $NotifierProvider<
          BusinessOnboardingDraft,
          BusinessOnboardingDraftState
        > {
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
  BusinessOnboardingDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'businessOnboardingDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$businessOnboardingDraftHash();

  @$internal
  @override
  BusinessOnboardingDraft create() => BusinessOnboardingDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BusinessOnboardingDraftState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BusinessOnboardingDraftState>(value),
    );
  }
}

String _$businessOnboardingDraftHash() =>
    r'a51476f91f7108f16bb1e4c79292ead1dec19068';

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

abstract class _$BusinessOnboardingDraft
    extends $Notifier<BusinessOnboardingDraftState> {
  BusinessOnboardingDraftState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<BusinessOnboardingDraftState, BusinessOnboardingDraftState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                BusinessOnboardingDraftState,
                BusinessOnboardingDraftState
              >,
              BusinessOnboardingDraftState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
