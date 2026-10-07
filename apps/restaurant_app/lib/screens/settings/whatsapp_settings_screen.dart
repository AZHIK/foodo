/// WhatsApp Business connection settings.
///
/// One screen for the whole connection lifecycle: connect (paste sender
/// credentials from the Meta dashboard — saving verifies them live),
/// status with test/disconnect, and the webhook details needed for
/// delivery reports + supplier replies. Gated on `procurement.create` —
/// the same permission as the requisition send it enables.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../constants/app_strings.dart';
import '../../models/permission.dart';
import '../../providers/inventory_api_provider.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/whatsapp_provider.dart';
import '../../services/whatsapp_api_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../widgets/data_page/status_badge.dart';
import '../../widgets/labeled_form_field.dart';
import '../../widgets/permission_gated_widget.dart';

class WhatsAppSettingsScreen extends ConsumerStatefulWidget {
  const WhatsAppSettingsScreen({super.key});

  @override
  ConsumerState<WhatsAppSettingsScreen> createState() =>
      _WhatsAppSettingsScreenState();
}

class _WhatsAppSettingsScreenState
    extends ConsumerState<WhatsAppSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberId = TextEditingController();
  final _displayNumber = TextEditingController();
  final _accessToken = TextEditingController();

  bool _busy = false;
  bool _obscureToken = true;
  String? _error;

  @override
  void dispose() {
    _phoneNumberId.dispose();
    _displayNumber.dispose();
    _accessToken.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(whatsappApiServiceProvider)
          .connect(
            businessId: businessId,
            phoneNumberId: _phoneNumberId.text.trim(),
            accessToken: _accessToken.text.trim(),
            displayPhoneNumber: _displayNumber.text.trim().isEmpty
                ? null
                : _displayNumber.text.trim(),
          );
      _accessToken.clear();
      ref.invalidate(whatsappConnectionProvider);
    } on WhatsAppApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _test() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(whatsappApiServiceProvider)
          .testConnection(businessId: businessId);
      ref.invalidate(whatsappConnectionProvider);
      if (mounted && result['status'] != 'connected') {
        setState(
          () => _error =
              result['last_error'] as String? ?? AppStrings.waConnectionError,
        );
      }
    } on WhatsAppApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(whatsappApiServiceProvider)
          .disconnect(businessId: businessId);
      ref.invalidate(whatsappConnectionProvider);
    } on WhatsAppApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.waCopied)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessId = ref.watch(currentBusinessIdProvider);
    final baseUrl = ref.watch(inventoryServiceDioProvider).options.baseUrl;
    return PermissionGatedScreen(
      requiredPermission: AppPermissions.procurementCreate,
      title: AppStrings.waSettingsTitle,
      child: Scaffold(
        appBar: AppBar(title: Text(AppStrings.waSettingsTitle)),
        body: ref
            .watch(whatsappConnectionProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(whatsappConnectionProvider),
              ),
              data: (info) => _Body(
                info: info,
                webhookUrl: businessId == null
                    ? null
                    : '$baseUrl${info?.webhookPath ?? '/api/v1/whatsapp/webhook'}'
                          '?business_id=$businessId&t=${info?.verifyToken ?? '<verify-token>'}',
                formKey: _formKey,
                phoneNumberId: _phoneNumberId,
                displayNumber: _displayNumber,
                accessToken: _accessToken,
                busy: _busy,
                obscureToken: _obscureToken,
                error: _error,
                onToggleObscure: () =>
                    setState(() => _obscureToken = !_obscureToken),
                onConnect: _connect,
                onTest: _test,
                onDisconnect: _disconnect,
                onCopy: _copy,
              ),
            ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        const SizedBox(height: Insets.xl * 2),
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(height: Insets.md),
        Text(
          message,
          style: context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.lg),
        Center(
          child: FilledButton.tonal(
            onPressed: onRetry,
            child: Text(AppStrings.retryAction),
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.info,
    required this.webhookUrl,
    required this.formKey,
    required this.phoneNumberId,
    required this.displayNumber,
    required this.accessToken,
    required this.busy,
    required this.obscureToken,
    required this.error,
    required this.onToggleObscure,
    required this.onConnect,
    required this.onTest,
    required this.onDisconnect,
    required this.onCopy,
  });

  final WhatsAppConnectionInfo? info;
  final String? webhookUrl;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneNumberId;
  final TextEditingController displayNumber;
  final TextEditingController accessToken;
  final bool busy;
  final bool obscureToken;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onConnect;
  final VoidCallback onTest;
  final VoidCallback onDisconnect;
  final Future<void> Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Insets.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatusCard(info: info),
                const SizedBox(height: Insets.lg),
                _ConnectPanel(
                  info: info,
                  formKey: formKey,
                  phoneNumberId: phoneNumberId,
                  displayNumber: displayNumber,
                  accessToken: accessToken,
                  busy: busy,
                  obscureToken: obscureToken,
                  error: error,
                  onToggleObscure: onToggleObscure,
                  onConnect: onConnect,
                  onTest: onTest,
                  onDisconnect: onDisconnect,
                ),
                if (info != null && info!.isConnected) ...[
                  const SizedBox(height: Insets.lg),
                  _WebhookPanel(
                    info: info!,
                    webhookUrl: webhookUrl,
                    onCopy: onCopy,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.info});

  final WhatsAppConnectionInfo? info;

  @override
  Widget build(BuildContext context) {
    final connected = info?.isConnected ?? false;
    final hasError = (info?.status ?? '') == 'error';
    final tone = connected
        ? StatusTone.positive
        : hasError
        ? StatusTone.danger
        : StatusTone.neutral;
    final label = connected
        ? AppStrings.waConnected
        : hasError
        ? AppStrings.waConnectionError
        : AppStrings.waNotConnected;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.chat_outlined,
                size: 23,
                color: connected
                    ? context.semantic.success
                    : context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Insets.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(label: label, tone: tone, dense: true),
                  if (info?.displayPhoneNumber != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${AppStrings.waConnectedAs}: ${info!.displayPhoneNumber}',
                      style: context.text.bodySmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (hasError && info?.lastError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      info!.lastError!,
                      style: context.text.bodySmall?.copyWith(
                        color: context.semantic.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectPanel extends StatelessWidget {
  const _ConnectPanel({
    required this.info,
    required this.formKey,
    required this.phoneNumberId,
    required this.displayNumber,
    required this.accessToken,
    required this.busy,
    required this.obscureToken,
    required this.error,
    required this.onToggleObscure,
    required this.onConnect,
    required this.onTest,
    required this.onDisconnect,
  });

  final WhatsAppConnectionInfo? info;
  final GlobalKey<FormState> formKey;
  final TextEditingController phoneNumberId;
  final TextEditingController displayNumber;
  final TextEditingController accessToken;
  final bool busy;
  final bool obscureToken;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onConnect;
  final VoidCallback onTest;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    if (phoneNumberId.text.isEmpty && (info?.phoneNumberId ?? '').isNotEmpty) {
      phoneNumberId.text = info!.phoneNumberId;
    }
    if (displayNumber.text.isEmpty &&
        (info?.displayPhoneNumber ?? '').isNotEmpty) {
      displayNumber.text = info!.displayPhoneNumber!;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppStrings.waConnectTitle, style: context.text.titleSmall),
              const SizedBox(height: Insets.xs),
              Text(
                AppStrings.waConnectHint,
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Insets.md),
              LabeledFormField(
                label: AppStrings.waPhoneNumberIdLabel,
                isRequired: true,
                child: TextFormField(
                  controller: phoneNumberId,
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? AppStrings.waRequiredField
                      : null,
                ),
              ),
              const SizedBox(height: Insets.md),
              LabeledFormField(
                label: AppStrings.waDisplayNumberLabel,
                child: TextFormField(
                  controller: displayNumber,
                  keyboardType: TextInputType.phone,
                ),
              ),
              const SizedBox(height: Insets.md),
              LabeledFormField(
                label: AppStrings.waAccessTokenLabel,
                isRequired: true,
                helper: info?.tokenPreview == null
                    ? null
                    : 'Current: ${info!.tokenPreview} — paste a new token to replace it.',
                child: TextFormField(
                  controller: accessToken,
                  obscureText: obscureToken,
                  validator: (v) =>
                      (info == null && (v == null || v.trim().isEmpty))
                      ? AppStrings.waRequiredField
                      : null,
                  decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscureToken
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: Insets.sm),
                Text(
                  error!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.semantic.danger,
                  ),
                ),
              ],
              const SizedBox(height: Insets.md),
              Wrap(
                spacing: Insets.sm,
                runSpacing: Insets.sm,
                children: [
                  FilledButton.icon(
                    onPressed: busy ? null : onConnect,
                    icon: const Icon(Icons.link_rounded, size: 18),
                    label: Text(
                      info == null
                          ? AppStrings.waConnectAction
                          : AppStrings.waSaveAction,
                    ),
                  ),
                  if (info != null) ...[
                    OutlinedButton.icon(
                      onPressed: busy ? null : onTest,
                      icon: const Icon(Icons.bolt_outlined, size: 18),
                      label: Text(AppStrings.waTestAction),
                    ),
                    OutlinedButton.icon(
                      onPressed: busy ? null : onDisconnect,
                      icon: const Icon(Icons.link_off_rounded, size: 18),
                      label: Text(AppStrings.waDisconnectAction),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: context.semantic.danger,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebhookPanel extends StatelessWidget {
  const _WebhookPanel({
    required this.info,
    required this.webhookUrl,
    required this.onCopy,
  });

  final WhatsAppConnectionInfo info;
  final String? webhookUrl;
  final Future<void> Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppStrings.waWebhookTitle, style: context.text.titleSmall),
            const SizedBox(height: Insets.xs),
            Text(
              AppStrings.waWebhookHint,
              style: context.text.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: Insets.md),
            if (webhookUrl != null)
              _CopyRow(
                label: AppStrings.waWebhookUrlLabel,
                value: webhookUrl!,
                onCopy: onCopy,
              ),
            if (info.verifyToken != null) ...[
              const SizedBox(height: Insets.sm),
              _CopyRow(
                label: AppStrings.waVerifyTokenLabel,
                value: info.verifyToken!,
                onCopy: onCopy,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  final String label;
  final String value;
  final Future<void> Function(String text) onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Insets.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.text.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                SelectableText(value, style: context.text.bodySmall),
              ],
            ),
          ),
          IconButton(
            tooltip: AppStrings.waCopied,
            onPressed: () => onCopy(value),
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
