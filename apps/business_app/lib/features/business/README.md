/// ── business/ ──────────────────────────────────────────────────────
///
/// Feature: Business registration and owner onboarding.
///
/// A self-registered owner (authenticated but with no prior business role,
/// represented in the auth state machine by `AuthState.onboardingRequired`)
/// completes a short adaptive three-step form here, which creates their
/// business via `POST /businesses` and then promotes them to a fully ready
/// `AuthState.sessionActive`.
///
/// Module layout:
/// - `domain/`          — `BusinessType` enum, `BusinessCreateRequest` and
///                        `BusinessCreateResult` mirroring the backend schema.
/// - `data/business_api.dart` — client for `POST /businesses`.
/// - `application/`     — in-memory `BusinessOnboardingDraft` Riverpod
///                        notifier (never written to Drift).
/// - `presentation/screens/` — the adaptive 3-step `BusinessOnboardingScreen`.
///
/// Onboarding is resumable because the *server* is the source of truth: the
/// boot path re-checks onboarding-status on every launch, so a user killed
/// mid-onboarding is routed straight back here until their business exists.
const String _businessReadme = '';