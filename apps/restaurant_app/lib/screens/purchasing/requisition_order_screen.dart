/// Order screen (post-submit), Option 2 UX: ONE order grouped by supplier.
///
/// No PO numbers, no procurement terminology in this primary view — just the
/// date, the rollup status, the total, and one card per supplier with its
/// lines, subtotal, status badge, and primary action.
///
/// Layout only reflows by device: single-column stacked cards on mobile, a
/// multi-column grid on tablet/desktop as width allows (same components —
/// [LayoutBuilder] + [Breakpoints.of] on the available width).
///
/// Per-card actions are independent: each card tracks its own busy state in
/// [supplierCardStatesProvider], so one supplier's slow interaction never
/// blocks the others.
///
/// "Send via WhatsApp" opens the wa.me deep link (native app on mobile,
/// WhatsApp Web/desktop-app prompt on desktop/tablet) with the message
/// pre-filled. Immediately after, the card shows an inline "Did this send?
/// [Mark as Sent]" confirm — delivery can't be auto-detected yet. Same
/// manual pattern for "Mark Confirmed" once a reply arrives.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../constants/app_strings.dart';
import '../../models/requisition.dart';
import '../../providers/permissions_provider.dart';
import '../../providers/requisition_cart_provider.dart';
import '../../providers/requisition_order_provider.dart';
import '../../providers/whatsapp_provider.dart';
import '../../services/whatsapp_api_service.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';

/// Entry route: shows the just-submitted order when [requisitionId] matches
/// the cart's last submit, otherwise fetches from the backend.
class RequisitionOrderScreen extends ConsumerWidget {
  const RequisitionOrderScreen({super.key, required this.requisitionId});

  final String requisitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cached = ref.watch(
      requisitionCartProvider.select((c) => c.lastSubmitted),
    );
    if (cached != null && cached.id == requisitionId) {
      return _OrderView(order: cached);
    }
    final orderAsync = ref.watch(requisitionOrderProvider(requisitionId));
    return orderAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: _OrderError(message: e.toString(), requisitionId: requisitionId),
      ),
      data: (order) => _OrderView(order: order),
    );
  }
}

class _OrderError extends ConsumerWidget {
  const _OrderError({required this.message, required this.requisitionId});

  final String message;
  final String requisitionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          AppStrings.reqOrderLoadFailed,
          style: context.text.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: Insets.sm),
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
            onPressed: () =>
                ref.refresh(requisitionOrderProvider(requisitionId)),
            child: Text(AppStrings.retryAction),
          ),
        ),
      ],
    );
  }
}

class _OrderView extends ConsumerStatefulWidget {
  const _OrderView({required this.order});

  final SubmittedRequisition order;

  @override
  ConsumerState<_OrderView> createState() => _OrderViewState();
}

class _OrderViewState extends ConsumerState<_OrderView> {
  /// Local PO-status overrides from this session's mark-sent/mark-confirmed
  /// taps, so badges roll up instantly even when the order came from the
  /// just-submitted cart (no backend refetch needed). A refetch replaces
  /// them with server truth.
  final Map<String, String> _statusOverrides = {};

  SubmittedRequisition get order => widget.order;

  String _statusOf(RequisitionSupplierGroup g) =>
      _statusOverrides[g.poId] ?? g.status;

  String get _rollup {
    final statuses = order.groups.map(_statusOf).toList();
    if (statuses.every(
      (s) => s == 'confirmed' || s == 'fulfilled' || s == 'received',
    )) {
      return 'Confirmed';
    }
    if (statuses.every((s) => s == 'cancelled')) return 'Cancelled';
    if (statuses.any(
      (s) => s == 'confirmed' || s == 'fulfilled' || s == 'received',
    )) {
      return 'Partially Confirmed';
    }
    if (statuses.any((s) => s == 'sent')) return 'Sent';
    return order.rollupStatus;
  }

  @override
  Widget build(BuildContext context) {
    final form = context.formFactor;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.reqOrderReady),
        actions: [
          IconButton(
            tooltip: AppStrings.reqExportTitle,
            onPressed: () => context.push(AppRoute.requisitionExport(order.id)),
            icon: const Icon(Icons.receipt_long_outlined),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final gridForm = Breakpoints.of(constraints.maxWidth);
          final columns = gridForm.isMobile
              ? 1
              : (constraints.maxWidth >= 1100 ? 3 : 2);
          return SingleChildScrollView(
            padding: EdgeInsets.all(Insets.page(form)),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: Breakpoints.maxContentWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _OrderHeader(order: order, rollup: _rollup),
                    const SizedBox(height: Insets.lg),
                    if (order.priceUnconfirmedItems.isNotEmpty)
                      _TbcBanner(items: order.priceUnconfirmedItems),
                    if (order.priceUnconfirmedItems.isNotEmpty)
                      const SizedBox(height: Insets.lg),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: Insets.lg,
                        mainAxisSpacing: Insets.lg,
                        // Cards size to content; enough height for lines +
                        // action row without inner scrolling.
                        mainAxisExtent: 340,
                      ),
                      itemCount: order.groups.length,
                      itemBuilder: (context, i) {
                        final group = order.groups[i];
                        return _SupplierCard(
                          group: group,
                          status: _statusOf(group),
                          onStatusChanged: (poId, status) {
                            setState(() => _statusOverrides[poId] = status);
                            // Backend refetch when this order is provider-
                            // backed (deep link / reload path); no-op when
                            // the order came from the just-submitted cart.
                            ref.invalidate(requisitionOrderProvider(order.id));
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, required this.rollup});

  final SubmittedRequisition order;
  final String rollup;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: Insets.lg,
          runSpacing: Insets.sm,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderedAt == null
                      ? AppStrings.reqTodaysOrder
                      : 'Order · ${Fmt.relativeDateTime(order.orderedAt!)}',
                  style: context.text.titleMedium,
                ),
                if (order.expectedAt != null)
                  Text(
                    AppStrings.reqDeliverySet(
                      '${order.expectedAt!.day}/${order.expectedAt!.month}/${order.expectedAt!.year}',
                    ),
                    style: context.text.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            _RollupChip(status: rollup),
            Text(
              Fmt.money(order.total),
              style: context.text.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RollupChip extends StatelessWidget {
  const _RollupChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Confirmed' => context.semantic.success,
      'Partially Confirmed' => context.semantic.warning,
      'Sent' => context.colors.primary,
      'Cancelled' => context.colors.error,
      _ => context.colors.onSurfaceVariant,
    };
    return Chip(
      avatar: Icon(
        status == 'Confirmed'
            ? Icons.check_circle_rounded
            : Icons.pending_outlined,
        size: 18,
        color: color,
      ),
      label: Text(status),
      side: BorderSide(color: color),
    );
  }
}

class _TbcBanner extends StatelessWidget {
  const _TbcBanner({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: context.semantic.warningContainer,
      child: Padding(
        padding: const EdgeInsets.all(Insets.md),
        child: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: context.semantic.onWarning),
            const SizedBox(width: Insets.sm),
            Expanded(
              child: Text(
                AppStrings.reqTbcBanner(items.join(', ')),
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.onWarning,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One supplier card: name/icon, lines, subtotal, badge, primary action.
/// Own busy state via [supplierCardStatesProvider]; own send-confirm flag.
class _SupplierCard extends ConsumerStatefulWidget {
  const _SupplierCard({
    required this.group,
    required this.status,
    required this.onStatusChanged,
  });

  final RequisitionSupplierGroup group;

  /// Live status (parent-owned override or server value).
  final String status;
  final void Function(String poId, String status) onStatusChanged;

  @override
  ConsumerState<_SupplierCard> createState() => _SupplierCardState();
}

class _SupplierCardState extends ConsumerState<_SupplierCard> {
  /// Set right after the wa.me link opens — the "Did this send?" confirm.
  bool _awaitingSendConfirm = false;

  /// Set when the automatic Cloud API send fails — the card then offers the
  /// manual wa.me send instead of retrying blindly.
  bool _apiFailed = false;
  String? _actionError;

  RequisitionSupplierGroup get group => widget.group;
  String get status => widget.status;

  String get badge {
    return switch (status) {
      'sent' => 'Sent',
      'confirmed' || 'fulfilled' || 'received' => 'Confirmed',
      'partially_fulfilled' || 'partially_received' => 'Partial',
      'cancelled' => 'Cancelled',
      _ => 'Not sent',
    };
  }

  bool get isTerminal =>
      status == 'confirmed' ||
      status == 'fulfilled' ||
      status == 'received' ||
      status == 'cancelled';

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(supplierCardStatesProvider)[group.poId] ?? false;
    final messenger = ScaffoldMessenger.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(Insets.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: context.colors.surfaceContainerHighest,
                  child: Text(
                    group.supplierName.isEmpty
                        ? '?'
                        : group.supplierName.characters.first.toUpperCase(),
                    style: context.text.titleSmall,
                  ),
                ),
                const SizedBox(width: Insets.sm),
                Expanded(
                  child: Text(
                    group.supplierName,
                    style: context.text.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(label: badge),
              ],
            ),
            const SizedBox(height: Insets.sm),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: Insets.sm),
                children: [
                  for (final line in group.lines)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: Insets.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${line.name} · ${line.qty} ${line.unit}',
                              style: context.text.bodyMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (line.priceUnconfirmed)
                            Text(
                              'price TBC',
                              style: context.text.labelSmall?.copyWith(
                                color: context.semantic.warning,
                              ),
                            )
                          else
                            Text(
                              line.lineTotal ?? '',
                              style: context.text.bodyMedium,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Subtotal', style: context.text.bodyMedium),
                Text(
                  Fmt.money(group.subtotal),
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Insets.sm),
            if (_actionError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Insets.xs),
                child: Text(
                  _actionError!,
                  style: context.text.bodySmall?.copyWith(
                    color: context.colors.error,
                  ),
                ),
              ),
            if (!group.hasWhatsapp)
              Text(
                AppStrings.reqAddWhatsappToSend,
                style: context.text.bodySmall?.copyWith(
                  color: context.semantic.warning,
                ),
              )
            else if (_awaitingSendConfirm)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.reqDidItSend,
                      style: context.text.bodyMedium,
                    ),
                  ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() => _awaitingSendConfirm = false),
                    child: Text(AppStrings.reqNotYet),
                  ),
                  FilledButton(
                    onPressed: busy
                        ? null
                        : () => _mark(messenger, 'sent', ref),
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppStrings.reqMarkSent),
                  ),
                ],
              )
            else if (badge == 'Not sent')
              _SendAction(
                busy: busy,
                apiReady:
                    ref
                        .watch(whatsappConnectionProvider)
                        .valueOrNull
                        ?.isConnected ??
                    false,
                apiFailed: _apiFailed,
                onSendApi: () => _sendViaApi(messenger, ref),
                onSendApp: () => _sendViaWhatsapp(messenger),
              )
            else if (!isTerminal)
              OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => _mark(messenger, 'confirmed', ref),
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(AppStrings.reqMarkConfirmed),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              )
            else
              Text(
                badge == 'Confirmed'
                    ? AppStrings.reqConfirmedNote
                    : AppStrings.reqTerminalNote(badge.toLowerCase()),
                style: context.text.bodySmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendViaWhatsapp(ScaffoldMessengerState messenger) async {
    final link = group.deepLink;
    if (link == null) return;
    final uri = Uri.tryParse(link);
    if (uri == null) {
      setState(() => _actionError = AppStrings.reqLinkInvalid);
      return;
    }
    // Mobile: native WhatsApp app. Desktop/tablet: WhatsApp Web or the
    // desktop-app prompt. Both open with the message pre-filled.
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      setState(() => _actionError = AppStrings.reqWhatsappFailed);
      return;
    }
    if (mounted) {
      // Delivery can't be auto-detected — ask inline, right away.
      setState(() {
        _awaitingSendConfirm = true;
        _actionError = null;
      });
    }
  }

  /// Automatic send through the connected WhatsApp Business number. The
  /// backend advances the PO to sent and reports the provider id; the card
  /// rolls up instantly via the parent override. Any failure falls back to
  /// the manual wa.me send rather than stranding the order.
  Future<void> _sendViaApi(
    ScaffoldMessengerState messenger,
    WidgetRef ref,
  ) async {
    setState(() {
      _actionError = null;
      _apiFailed = false;
    });
    try {
      await ref.read(supplierCardStatesProvider.notifier).run(
        group.poId,
        () async {
          final businessId = ref.read(currentBusinessIdProvider);
          if (businessId == null) throw StateError('No business context');
          await ref
              .read(whatsappApiServiceProvider)
              .sendOrder(businessId: businessId, orderId: group.poId);
          if (!mounted) return;
          widget.onStatusChanged(group.poId, 'sent');
          messenger.showSnackBar(
            SnackBar(content: Text(AppStrings.reqSentViaApi)),
          );
        },
      );
    } on WhatsAppApiException catch (e) {
      if (mounted) {
        setState(() {
          _apiFailed = true;
          _actionError = e.statusCode == 409 || e.statusCode == 422
              ? '${e.message} ${AppStrings.reqApiSendFailedFallback}'
              : e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _apiFailed = true;
          _actionError = e.toString();
        });
      }
    }
  }

  Future<void> _mark(
    ScaffoldMessengerState messenger,
    String kind,
    WidgetRef ref,
  ) async {
    setState(() => _actionError = null);
    try {
      await ref.read(supplierCardStatesProvider.notifier).run(
        group.poId,
        () async {
          final businessId = ref.read(currentBusinessIdProvider);
          if (businessId == null) throw StateError('No business context');
          final api = ref.read(requisitionApiServiceProvider);
          final result = kind == 'sent'
              ? await api.markSent(businessId: businessId, orderId: group.poId)
              : await api.markConfirmed(
                  businessId: businessId,
                  orderId: group.poId,
                );
          if (!mounted) return;
          // Parent rolls badges up instantly; provider invalidate refreshes
          // server truth on the fetch-backed path (no-op for the cached
          // just-submitted path).
          widget.onStatusChanged(group.poId, result['status'] as String);
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                result['status'] == 'sent'
                    ? AppStrings.reqMarkedSent
                    : AppStrings.reqMarkedConfirmed,
              ),
            ),
          );
          setState(() => _awaitingSendConfirm = false);
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _actionError = e.toString());
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Confirmed' => context.semantic.success,
      'Partial' => context.semantic.warning,
      'Sent' => context.colors.primary,
      'Cancelled' => context.colors.error,
      _ => context.colors.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Insets.sm,
        vertical: Insets.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Text(
        label,
        style: context.text.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

/// The "Not sent" send action: automatic Cloud API send when the business
/// number is connected, otherwise the manual wa.me send. After an API
/// failure the manual send stays one tap away.
class _SendAction extends StatelessWidget {
  const _SendAction({
    required this.busy,
    required this.apiReady,
    required this.apiFailed,
    required this.onSendApi,
    required this.onSendApp,
  });

  final bool busy;
  final bool apiReady;
  final bool apiFailed;
  final VoidCallback onSendApi;
  final VoidCallback onSendApp;

  @override
  Widget build(BuildContext context) {
    if (apiReady && !apiFailed) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.icon(
            onPressed: busy ? null : onSendApi,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: Text(AppStrings.reqSendViaApi),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: Insets.xs),
          TextButton.icon(
            onPressed: busy ? null : onSendApp,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(AppStrings.reqOpenInWhatsapp),
          ),
        ],
      );
    }
    return FilledButton.icon(
      onPressed: busy ? null : onSendApp,
      icon: const Icon(Icons.send_rounded, size: 18),
      label: Text(AppStrings.reqSendWhatsapp),
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    );
  }
}
