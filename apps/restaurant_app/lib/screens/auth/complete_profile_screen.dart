import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../constants/app_strings.dart';
import '../../providers/session_provider.dart';
import '../../utils/email_validation.dart';
import '../../widgets/auth/auth_scaffold.dart';
import '../../widgets/labeled_form_field.dart';

abstract final class CompleteProfileKeys {
  static const fullName = Key('completeProfile.fullName');
  static const email = Key('completeProfile.email');
  static const submit = Key('completeProfile.submit');
}

/// Collects the registrant's name (and optionally email) right after OTP
/// verification.
///
/// The phone-first (OTP-only) sign-in never asks for a name — a phone number
/// is all it needs to create the account — so this is the one place that
/// gap gets closed, before the business wizard starts putting that name on
/// receipts and staff lists.
class CompleteProfileScreen extends ConsumerStatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _fullName.dispose();
    _email.dispose();
    super.dispose();
  }

  bool get _emailLooksValid =>
      _email.text.trim().isEmpty || isValidEmailFormat(_email.text);

  bool get _canSubmit =>
      _fullName.text.trim().isNotEmpty && _emailLooksValid && !_submitting;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final email = _email.text.trim();
      await ref.read(authProvider.notifier).completeProfile(
            fullName: _fullName.text.trim(),
            email: email.isEmpty ? null : email,
          );
      if (!mounted) return;
      context.go(ref.read(sessionProvider).entryRoute);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = AppStrings.saveDetailsFailed(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: AppStrings.tellUsWhoYouAre,
      subtitle: AppStrings.profileSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledFormField(
            label: AppStrings.fullName,
            isRequired: true,
            child: TextField(
              key: CompleteProfileKeys.fullName,
              controller: _fullName,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: AppStrings.nameExample),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 16),
          LabeledFormField(
            label: AppStrings.emailLabel,
            helper: AppStrings.emailHelper,
            child: TextField(
              key: CompleteProfileKeys.email,
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: AppStrings.emailExample,
                errorText:
                    _emailLooksValid ? null : AppStrings.invalidEmail,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(
              _error!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton(
            key: CompleteProfileKeys.submit,
            onPressed: _canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.continueAction),
          ),
        ],
      ),
    );
  }
}
