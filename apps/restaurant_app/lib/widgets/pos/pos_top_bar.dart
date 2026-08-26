import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/menu_providers.dart';
import '../../providers/settings_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/breakpoints.dart';
import '../nav_shell_scope.dart';

/// Search, barcode scan and the signed-in cashier.
///
/// [ConsumerStatefulWidget] only because the [TextEditingController] is
/// genuinely widget-lifetime state; the query itself lives in Riverpod so the
/// grid and the empty state read it from one place.
class PosTopBar extends ConsumerStatefulWidget {
  const PosTopBar({super.key, required this.form});

  final FormFactor form;

  @override
  ConsumerState<PosTopBar> createState() => _PosTopBarState();
}

class _PosTopBarState extends ConsumerState<PosTopBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final isMobile = widget.form.isMobile;

    // Keep the field in step when something else clears the query.
    if (_controller.text != query) {
      _controller.value = TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: query.length),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Insets.page(widget.form),
        Insets.sm,
        Insets.page(widget.form),
        Insets.sm,
      ),
      child: Row(
        children: [
          const NavMenuButton(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Insets.sm),
              child: TextField(
                controller: _controller,
                onChanged: (value) =>
                    ref.read(searchQueryProvider.notifier).state = value,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: isMobile
                      ? 'Search menu'
                      : 'Search menu items, categories…',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              ref.read(searchQueryProvider.notifier).state = '',
                        ),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isMobile ? 8 : 12,
                    horizontal: Insets.md,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: Insets.xs),
          _IconAction(
            icon: Icons.qr_code_scanner_rounded,
            tooltip: 'Scan barcode',
            // A real terminal hands this to a scanner service; the affordance
            // has to exist for the layout to be honest.
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Scanner not connected')),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: Insets.md),
            const _CashierChip(),
          ],
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: 44,
      width: 44,
      child: Material(
        color: colors.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.md),
          side: BorderSide(color: context.semantic.hairline, width: 1),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20),
          color: colors.onSurfaceVariant,
          splashRadius: 20,
        ),
      ),
    );
  }
}

class _CashierChip extends ConsumerWidget {
  const _CashierChip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final staff = ref.watch(currentStaffProvider);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colors.primaryContainer,
          child: Text(
            staff.characters.first.toUpperCase(),
            style: context.text.titleSmall?.copyWith(
              color: colors.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: Insets.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              staff,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall,
            ),
            Text(
              'Cashier',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
