import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_durations.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/error/failure.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/application/auth_notifier.dart';
import '../../application/business_onboarding_controller.dart';
import '../../data/business_api.dart';
import '../../domain/business_create_request.dart';
import '../../domain/business_type.dart';

/// Two-step business onboarding for a self-registered restaurant owner.
///
/// Business type is hardcoded to [BusinessType.restaurant] since this app
/// is for restaurants only.
///
/// The router guarantees this screen is only reached while [AuthState
/// .onboardingRequired]. On completion it calls [BusinessApi.createBusiness]
/// and then [AuthNotifier.completeOnboarding], which flips the state to the
/// terminal [AuthState.sessionActive] and lands the user on the dashboard.
///
/// Form input lives in the in-memory [businessOnboardingDraftProvider] only
/// (not Drift). Resumability across an app kill is handled *by the server*:
/// on relaunch the boot path re-checks `onboarding-status`, which still
/// reports `needs_onboarding=true` until a business actually exists, and
/// routes the user straight back here to restart the form — there's no need
/// to persist a partially-filled 2-step form that takes under a minute.
class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  const BusinessOnboardingScreen({super.key});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _taxIdCtrl = TextEditingController();

  int _step = 0;
  bool _submitting = false;
  String? _submitError;

  /// Whether `POST /businesses` has already succeeded in this flow.
  ///
  /// Guards the submit button so that a retry after the business was created
  /// (e.g. the session-scoping step failed) retries only the scoping step —
  /// it never creates a second business.
  bool _businessCreated = false;

  @override
  void initState() {
    super.initState();
    final draft = ref.read(businessOnboardingDraftProvider);
    if (draft.name.isNotEmpty) _nameCtrl.text = draft.name;
    if (draft.city.isNotEmpty) _cityCtrl.text = draft.city;
    if (draft.taxId != null) _taxIdCtrl.text = draft.taxId!;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _cityCtrl.dispose();
    _taxIdCtrl.dispose();
    super.dispose();
  }

  void _goBack() {
    setState(() {
      _step -= 1;
      _submitError = null;
    });
  }

  Future<void> _advanceFromDetails() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() {
      _step = 1;
      _submitError = null;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final draft = ref.read(businessOnboardingDraftProvider);

    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final request = BusinessCreateRequest(
      name: draft.name.trim(),
      businessType: BusinessType.restaurant,
      taxId: draft.taxId,
      countryCode: draft.countryCode,
      city: draft.city.trim(),
    );

    try {
      // Only create the business once. If the earlier attempt reached the
      // session-scoping step, the business already exists server-side and a
      // retry must not create a duplicate.
      if (!_businessCreated) {
        await ref.read(businessApiProvider).createBusiness(request);
        _businessCreated = true;
      }

      final failure =
          await ref.read(authProvider.notifier).completeOnboarding();
      if (!mounted) return;
      if (failure != null) {
        setState(() {
          _submitting = false;
          _submitError = _mapFailure(failure);
        });
        return;
      }

      if (!mounted) return;
      AppSnackBar.showSuccess(context, AppStrings.onboardingComplete);
      context.go(AppRoutes.dashboard);
    } on Failure catch (failure) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = _mapFailure(failure);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = AppStrings.unknownError;
      });
    }
  }

  String _mapFailure(Failure f) => f.when(
        network: (m, _) => m ?? AppStrings.networkError,
        validation: (m) => m ?? AppStrings.unknownError,
        auth: (m) => m ?? AppStrings.authError,
        unknown: (m, _) => m ?? AppStrings.unknownError,
      );

  @override
  Widget build(BuildContext context) {
    final (title, subtitle) = switch (_step) {
      0 => (
          AppStrings.onboardingDetailsStepTitle,
          AppStrings.onboardingDetailsStepSubtitle,
        ),
      _ => (
          AppStrings.onboardingReviewStepTitle,
          AppStrings.onboardingReviewStepSubtitle,
        ),
    };

    return AppAuthPage(
      leading: _step > 0
          ? IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: AppStrings.onboardingBack,
              onPressed: _goBack,
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Hero ─────────────────────────────────────────────
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.seedTerracotta, AppColors.seedSage],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
              ),
              child: const Icon(
                Icons.storefront_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: AppDimensions.spaceLG),

          Text(
            AppStrings.onboardingTitle,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spaceSM),

          Text(
            title,
            style: AppTextStyles.headlineSmall.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spaceXS),
          Text(
            subtitle,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppDimensions.spaceLG),

          _StepIndicator(current: _step),

          const SizedBox(height: AppDimensions.spaceLG),

          switch (_step) {
            0 => _buildStep0(),
            _ => _buildStep1(),
          },
        ],
      ),
    );
  }

  Widget _buildStep0() {
    final notifier = ref.read(businessOnboardingDraftProvider.notifier);
    final draft = ref.watch(businessOnboardingDraftProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            key: const ValueKey('business-name'),
            controller: _nameCtrl,
            label: AppStrings.onboardingBusinessName,
            hint: AppStrings.onboardingBusinessNameHint,
            prefixIcon: Icons.storefront_outlined,
            textInputAction: TextInputAction.next,
            onChanged: notifier.setName,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppStrings.onboardingBusinessNameRequired
                : null,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            key: const ValueKey('business-city'),
            controller: _cityCtrl,
            label: AppStrings.onboardingCity,
            hint: AppStrings.onboardingCityHint,
            prefixIcon: Icons.location_city_outlined,
            textInputAction: TextInputAction.next,
            onChanged: notifier.setCity,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? AppStrings.onboardingCityRequired
                : null,
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          DropdownButtonFormField<String>(
            key: const ValueKey('business-country'),
            initialValue: draft.countryCode,
            decoration: const InputDecoration(
              labelText: AppStrings.onboardingCountry,
              prefixIcon: Icon(Icons.public_outlined),
            ),
            items: [
              for (final country in _countries)
                DropdownMenuItem(
                  value: country.code,
                  child: Text(country.name),
                ),
            ],
            onChanged: (code) {
              if (code != null) notifier.setCountryCode(code);
            },
          ),
          const SizedBox(height: AppDimensions.spaceMD),
          AppTextField(
            key: const ValueKey('business-tax-id'),
            controller: _taxIdCtrl,
            label: AppStrings.onboardingTaxId,
            hint: AppStrings.onboardingTaxIdHint,
            prefixIcon: Icons.badge_outlined,
            textInputAction: TextInputAction.done,
            onChanged: notifier.setTaxId,
          ),
          if (_submitError != null) ...[
            const SizedBox(height: AppDimensions.spaceMD),
            _ErrorBanner(message: _submitError!),
          ],
          const SizedBox(height: AppDimensions.spaceXL),
          AppPrimaryButton(
            label: AppStrings.onboardingContinue,
            icon: Icons.arrow_forward,
            onPressed: _advanceFromDetails,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    final draft = ref.watch(businessOnboardingDraftProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ReviewCard(draft: draft),
        if (_submitError != null) ...[
          const SizedBox(height: AppDimensions.spaceMD),
          _ErrorBanner(message: _submitError!),
        ],
        const SizedBox(height: AppDimensions.spaceXL),
        AppPrimaryButton(
          label: _businessCreated
              ? AppStrings.onboardingRetrySession
              : AppStrings.onboardingCreateBusiness,
          icon: Icons.check_circle_outline,
          onPressed: _submitting ? null : _submit,
          isLoading: _submitting,
        ),
      ],
    );
  }
}

/// Pulsing-less dot indicator for the two onboarding steps.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == current;
        final done = i < current;
        return AnimatedContainer(
          duration: AppDurations.fast,
          margin: const EdgeInsets.symmetric(horizontal: AppDimensions.spaceXS),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: done
                ? colorScheme.primary.withValues(alpha: 0.5)
                : active
                    ? colorScheme.primary
                    : colorScheme.outline.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
          ),
        );
      }),
    );
  }
}

/// Read-only summary of the draft, shown on the final review step.
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.draft});

  final BusinessOnboardingDraftState draft;

  @override
  Widget build(BuildContext context) {
    return AppCard.outlined(
      padding: const EdgeInsets.all(AppDimensions.spaceLG),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ReviewRow(
            label: AppStrings.onboardingBusinessTypeLabel,
            value: BusinessType.restaurant.label,
          ),
          _ReviewRow(
            label: AppStrings.onboardingBusinessName,
            value: draft.name,
          ),
          _ReviewRow(label: AppStrings.onboardingCity, value: draft.city),
          _ReviewRow(
            label: AppStrings.onboardingCountry,
            value: _countryNameFor(draft.countryCode),
          ),
          if (draft.taxId != null)
            _ReviewRow(
              label: AppStrings.onboardingTaxId,
              value: draft.taxId!,
            ),
        ],
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.spaceSM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimensions.spaceXXS),
          Text(
            value,
            style: AppTextStyles.bodyLarge.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

/// Small, coloured error callout used on every step.
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppInfoContainer(
      icon: Icons.error_outline,
      color: colorScheme.errorContainer,
      child: Text(
        message,
        style: AppTextStyles.bodySmall.copyWith(
          color: colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _CountryOption {
  const _CountryOption(this.code, this.name);

  final String code;
  final String name;
}

/// Sensible default markets for the onboarding country selector.
const List<_CountryOption> _countries = [
  _CountryOption('TZ', 'Tanzania'),
  _CountryOption('KE', 'Kenya'),
  _CountryOption('UG', 'Uganda'),
  _CountryOption('RW', 'Rwanda'),
  _CountryOption('BI', 'Burundi'),
  _CountryOption('ZM', 'Zambia'),
  _CountryOption('MW', 'Malawi'),
  _CountryOption('ZA', 'South Africa'),
  _CountryOption('GH', 'Ghana'),
  _CountryOption('NG', 'Nigeria'),
];

String _countryNameFor(String code) => _countries
    .firstWhere((c) => c.code == code, orElse: () => _CountryOption(code, code))
    .name;