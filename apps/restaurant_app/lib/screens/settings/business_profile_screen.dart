import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/business_profile.dart';
import '../../providers/settings_provider.dart';
import '../../router/app_router.dart';
import '../../theme/app_theme.dart';
import '../../theme/brand_palette.dart';
import '../../theme/breakpoints.dart';
import '../../utils/formatters.dart';
import '../../widgets/detail_page/detail_page_scaffold.dart';
import '../../widgets/field_pair.dart';
import '../../widgets/image_upload_field.dart';
import '../../widgets/labeled_form_field.dart';

/// Widget keys for the profile form's controls.
///
/// The labels sit outside the inputs, so there is no `labelText` for a test to
/// find a field by — the same reason [ItemFormKeys] and [StockDialogKeys]
/// exist.
abstract final class BusinessProfileKeys {
  static const name = Key('businessProfile.name');
  static const legalName = Key('businessProfile.legalName');
  static const type = Key('businessProfile.type');
  static const email = Key('businessProfile.email');
  static const website = Key('businessProfile.website');
  static const taxId = Key('businessProfile.taxId');
  static const receiptFooter = Key('businessProfile.receiptFooter');
  static const brandColor = Key('businessProfile.brandColor');
  static const save = Key('businessProfile.save');
}

/// Edits who the venue *is* — the name, marks and contact details that appear
/// on receipts and any customer-facing surface.
///
/// A screen rather than a dialog: this is a dozen fields across three concerns,
/// and a modal that tall stops being a modal. It keeps the detail-page shell so
/// it still reads as part of the same app, and so the Save button rides in the
/// pinned header rather than at the bottom of a form nobody scrolls back up.
///
/// How the store *behaves* — tax, currency, hours — is Store Settings' job.
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _address1 = TextEditingController();
  final _address2 = TextEditingController();
  final _city = TextEditingController();
  final _postcode = TextEditingController();
  final _country = TextEditingController();
  final _taxId = TextEditingController();
  final _receiptFooter = TextEditingController();

  BusinessType _type = BusinessType.restaurant;
  bool _seeded = false;

  /// Set on the first edit, so the Save button is inert until something has
  /// actually changed — a form that always looks saveable teaches people to
  /// press Save without reading.
  bool _dirty = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seeded) return;
    _seeded = true;

    final profile = ref.read(businessProfileProvider);
    _name.text = profile.name;
    _legalName.text = profile.legalName;
    _email.text = profile.email;
    _phone.text = profile.phone;
    _website.text = profile.website;
    _address1.text = profile.addressLine1;
    _address2.text = profile.addressLine2;
    _city.text = profile.city;
    _postcode.text = profile.postcode;
    _country.text = profile.country;
    _taxId.text = profile.taxId;
    _receiptFooter.text = profile.receiptFooter;
    _type = profile.type;
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _legalName,
      _email,
      _phone,
      _website,
      _address1,
      _address2,
      _city,
      _postcode,
      _country,
      _taxId,
      _receiptFooter,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _touch() {
    if (!_dirty) setState(() => _dirty = true);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final existing = ref.read(businessProfileProvider);
    ref
        .read(businessProfileProvider.notifier)
        .save(
          existing.copyWith(
            name: _name.text.trim(),
            legalName: _legalName.text.trim(),
            type: _type,
            email: _email.text.trim(),
            phone: _phone.text.trim(),
            website: _website.text.trim(),
            addressLine1: _address1.text.trim(),
            addressLine2: _address2.text.trim(),
            city: _city.text.trim(),
            postcode: _postcode.text.trim(),
            country: _country.text.trim(),
            taxId: _taxId.text.trim(),
            receiptFooter: _receiptFooter.text.trim(),
          ),
        );

    setState(() => _dirty = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Business profile saved')));
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(businessProfileProvider);

    return Form(
      key: _formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      onChanged: _touch,
      child: DetailPageScaffold(
        maxContentWidth: 1080,
        header: DetailPageHeader(
          title: 'Business profile',
          subtitle:
              'Appears on receipts and every customer-facing surface',
          onBack: () => context.canPop()
              ? context.pop()
              : context.goNamed(AppRoute.settingsName),
          actions: [
            FilledButton.icon(
              key: BusinessProfileKeys.save,
              onPressed: _dirty ? _save : null,
              icon: const Icon(Icons.check_rounded, size: 18),
              label: const Text('Save changes'),
            ),
          ],
        ),
        // Branding leads the stacked order on mobile: the logo is the one part
        // of this screen someone opens it specifically to change.
        sidePanel: [
          _BrandingPanel(
            profile: profile,
            onLogoPicked: (fileName, bytes) {
              ref
                  .read(businessProfileProvider.notifier)
                  .setLogo(fileName, bytes);
              _touch();
            },
            onLogoRemoved: () {
              ref.read(businessProfileProvider.notifier).clearLogo();
              _touch();
            },
            onColorPicked: (color) {
              ref.read(businessProfileProvider.notifier).setBrandColor(color);
              _touch();
            },
          ),
          const _ReceiptPreview(),
        ],
        children: [
          _DetailsPanel(
            name: _name,
            legalName: _legalName,
            taxId: _taxId,
            type: _type,
            onTypeChanged: (value) {
              setState(() {
                _type = value;
                _dirty = true;
              });
            },
          ),
          _ContactPanel(
            email: _email,
            phone: _phone,
            website: _website,
            address1: _address1,
            address2: _address2,
            city: _city,
            postcode: _postcode,
            country: _country,
          ),
          _ReceiptFooterPanel(controller: _receiptFooter),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Panels
// ---------------------------------------------------------------------------

/// Logo and accent colour — the two things that decide what a printed receipt
/// looks like before a word of it is read.
class _BrandingPanel extends StatelessWidget {
  const _BrandingPanel({
    required this.profile,
    required this.onLogoPicked,
    required this.onLogoRemoved,
    required this.onColorPicked,
  });

  final BusinessProfile profile;
  final void Function(String name, Uint8List bytes) onLogoPicked;
  final VoidCallback onLogoRemoved;
  final ValueChanged<Color> onColorPicked;

  @override
  Widget build(BuildContext context) {
    // The panel is a full-width block on a phone, where a 140px square looks
    // marooned; in the side column it is the panel's whole subject.
    final compact = context.isMobile;
    final logoSize = compact ? 100.0 : 140.0;

    return DetailPanel(
      title: 'Branding',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: compact ? Alignment.center : Alignment.centerLeft,
            child: ImageUploadField(
              image: profile.logoBytes,
              size: logoSize,
              label: 'Add logo',
              hint: '',
              onPicked: onLogoPicked,
              onRemoved: onLogoRemoved,
            ),
          ),
          const SizedBox(height: Insets.xs),
          Text(
            'Square PNG or JPG reads best on a receipt',
            textAlign: compact ? TextAlign.center : TextAlign.start,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Insets.xl),
          _BrandColorPicker(
            selected: profile.brandColor,
            onPicked: onColorPicked,
          ),
        ],
      ),
    );
  }
}

/// A row of preset swatches plus a custom entry.
///
/// Presets rather than a full colour wheel because the eight here are hues the
/// rest of the app already pairs well with; the custom option exists for the
/// venue whose brand book says otherwise.
class _BrandColorPicker extends StatelessWidget {
  const _BrandColorPicker({required this.selected, required this.onPicked});

  final Color selected;
  final ValueChanged<Color> onPicked;

  static const double _swatchSize = 34;

  @override
  Widget build(BuildContext context) {
    final custom = BrandPalette.match(selected) == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Accent colour',
          style: context.text.labelLarge?.copyWith(
            color: context.colors.onSurface,
          ),
        ),
        const SizedBox(height: Insets.sm),
        Wrap(
          key: BusinessProfileKeys.brandColor,
          spacing: Insets.sm,
          runSpacing: Insets.sm,
          children: [
            for (final swatch in BrandPalette.swatches)
              _Swatch(
                color: swatch.color,
                tooltip: swatch.name,
                selected:
                    swatch.color.toARGB32() == selected.toARGB32(),
                onTap: () => onPicked(swatch.color),
              ),
            _CustomSwatch(
              selected: custom,
              color: selected,
              onPicked: onPicked,
            ),
          ],
        ),
        const SizedBox(height: Insets.md),
        _BrandPreviewStrip(color: selected),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        selected: selected,
        button: true,
        label: tooltip,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            height: _BrandColorPicker._swatchSize,
            width: _BrandColorPicker._swatchSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              // Selection is a ring around the swatch rather than a tint of
              // it: the swatch's own colour is the thing being chosen, so
              // nothing may alter it.
              border: Border.all(
                color: selected
                    ? context.colors.onSurface
                    : context.semantic.hairline,
                width: selected ? 2.5 : 1,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

/// Opens a small palette of extra hues.
///
/// A real colour wheel is a dependency this build does not carry, so "custom"
/// offers a second tier of choices rather than pretending to be an eyedropper.
class _CustomSwatch extends StatelessWidget {
  const _CustomSwatch({
    required this.selected,
    required this.color,
    required this.onPicked,
  });

  final bool selected;
  final Color color;
  final ValueChanged<Color> onPicked;

  static const _extras = <Color>[
    Color(0xFF0F766E),
    Color(0xFF166534),
    Color(0xFF9A3412),
    Color(0xFF7E22CE),
    Color(0xFF0E7490),
    Color(0xFF9F1239),
    Color(0xFF1F2937),
    Color(0xFF854D0E),
  ];

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: selected ? 'Custom · ${BrandPalette.hex(color)}' : 'Custom',
      child: PopupMenuButton<Color>(
        onSelected: onPicked,
        tooltip: '',
        itemBuilder: (menuContext) => [
          for (final extra in _extras)
            PopupMenuItem(
              value: extra,
              child: Row(
                children: [
                  Container(
                    height: 18,
                    width: 18,
                    decoration: BoxDecoration(
                      color: extra,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: Insets.md),
                  Text(BrandPalette.hex(extra)),
                ],
              ),
            ),
        ],
        child: Container(
          height: _BrandColorPicker._swatchSize,
          width: _BrandColorPicker._swatchSize,
          decoration: BoxDecoration(
            color: selected ? color : context.colors.surfaceContainerHigh,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? context.colors.onSurface
                  : context.semantic.hairline,
              width: selected ? 2.5 : 1,
            ),
          ),
          child: Icon(
            Icons.add_rounded,
            size: 17,
            color: selected ? Colors.white : context.colors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// Shows the chosen accent at the three weights a receipt actually uses it at,
/// so a colour that looks fine as a dot but muddy as a fill is caught here.
class _BrandPreviewStrip extends StatelessWidget {
  const _BrandPreviewStrip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(Radii.sm),
      child: SizedBox(
        height: 26,
        child: Row(
          children: [
            Expanded(child: ColoredBox(color: color)),
            Expanded(
              child: ColoredBox(color: color.withValues(alpha: 0.55)),
            ),
            Expanded(
              child: ColoredBox(color: color.withValues(alpha: 0.16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsPanel extends StatelessWidget {
  const _DetailsPanel({
    required this.name,
    required this.legalName,
    required this.taxId,
    required this.type,
    required this.onTypeChanged,
  });

  final TextEditingController name;
  final TextEditingController legalName;
  final TextEditingController taxId;
  final BusinessType type;
  final ValueChanged<BusinessType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return DetailPanel(
      title: 'Business details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LabeledFormField(
            label: 'Business name',
            isRequired: true,
            helper: 'Shown in the sidebar and on receipts',
            child: TextFormField(
              key: BusinessProfileKeys.name,
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'The Copper Fig'),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'The business needs a name'
                  : null,
            ),
          ),
          const SizedBox(height: Insets.lg),
          FieldPair(
            left: LabeledFormField(
              label: 'Business type',
              child: DropdownButtonFormField<BusinessType>(
                key: BusinessProfileKeys.type,
                initialValue: type,
                isExpanded: true,
                items: [
                  for (final option in BusinessType.values)
                    DropdownMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          Icon(option.icon, size: 17),
                          const SizedBox(width: Insets.sm),
                          Flexible(
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) onTypeChanged(value);
                },
              ),
            ),
            right: LabeledFormField(
              label: 'Tax ID',
              helper: 'Printed on receipts where required',
              child: TextFormField(
                key: BusinessProfileKeys.taxId,
                controller: taxId,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'Optional'),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          // Secondary to the trading name above: most venues never fill it in,
          // and the smaller label keeps it from reading as a second required
          // field.
          LabeledFormField(
            label: 'Legal / registered name',
            helper: 'Only if it differs from the business name',
            child: TextFormField(
              key: BusinessProfileKeys.legalName,
              controller: legalName,
              textCapitalization: TextCapitalization.words,
              style: context.text.bodySmall,
              decoration: const InputDecoration(
                hintText: 'Copper Fig Hospitality Ltd',
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactPanel extends StatelessWidget {
  const _ContactPanel({
    required this.email,
    required this.phone,
    required this.website,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.country,
  });

  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController website;
  final TextEditingController address1;
  final TextEditingController address2;
  final TextEditingController city;
  final TextEditingController postcode;
  final TextEditingController country;

  @override
  Widget build(BuildContext context) {
    return DetailPanel(
      title: 'Contact & location',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          FieldPair(
            left: LabeledFormField(
              label: 'Phone',
              child: TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: '+1 415 555 0100'),
              ),
            ),
            right: LabeledFormField(
              label: 'Email',
              child: TextFormField(
                key: BusinessProfileKeys.email,
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'hello@example.com',
                ),
                validator: (value) {
                  final text = (value ?? '').trim();
                  if (text.isEmpty) return null;
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                      ? null
                      : 'Enter a valid email address';
                },
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Website',
            child: TextFormField(
              key: BusinessProfileKeys.website,
              controller: website,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Address',
            child: TextFormField(
              controller: address1,
              // Multiline, because a street address is not reliably one line
              // and a single-line field forces people to abbreviate.
              maxLines: 2,
              minLines: 2,
              textCapitalization: TextCapitalization.words,
              decoration: _multilineDecoration(
                context,
                hint: '84 Riverside Walk',
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Address line 2',
            child: TextFormField(
              controller: address2,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'Optional'),
            ),
          ),
          const SizedBox(height: Insets.lg),
          FieldPair(
            left: LabeledFormField(
              label: 'City',
              child: TextFormField(
                controller: city,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(hintText: 'San Francisco'),
              ),
            ),
            right: LabeledFormField(
              label: 'Postal code',
              child: TextFormField(
                controller: postcode,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(hintText: 'CA 94107'),
              ),
            ),
          ),
          const SizedBox(height: Insets.lg),
          LabeledFormField(
            label: 'Country',
            child: TextFormField(
              controller: country,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'United States'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptFooterPanel extends StatelessWidget {
  const _ReceiptFooterPanel({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return DetailPanel(
      title: 'Receipt footer',
      child: LabeledFormField(
        label: 'Thank-you message',
        helper: 'Printed at the bottom of every receipt',
        child: TextFormField(
          key: BusinessProfileKeys.receiptFooter,
          controller: controller,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: _multilineDecoration(
            context,
            hint: 'Thank you for dining with us!',
          ),
        ),
      ),
    );
  }
}

/// The theme's input decoration is a pill, which looks wrong wrapped around two
/// lines of text — these fields square it off without restating the rest.
InputDecoration _multilineDecoration(
  BuildContext context, {
  required String hint,
}) {
  return InputDecoration(
    hintText: hint,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: context.semantic.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(Radii.md),
      borderSide: BorderSide(color: context.colors.primary, width: 1.5),
    ),
  );
}

/// A live receipt header, so the effect of an address, accent or footer edit is
/// visible without printing one.
///
/// Reads the profile and the store's tax settings from their own providers
/// rather than taking them as arguments: this is the same pair of sources the
/// real receipt reads, so a preview that agrees with it here agrees with it on
/// paper.
class _ReceiptPreview extends ConsumerWidget {
  const _ReceiptPreview();

  /// A plausible ticket, purely so the totals block has numbers to show.
  static const _subtotal = 48.00;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(businessProfileProvider);
    final settings = ref.watch(storeSettingsProvider);
    final colors = context.colors;
    final muted = context.text.bodySmall?.copyWith(
      color: colors.onSurfaceVariant,
    );

    final service = _subtotal * settings.serviceChargeRate;
    final tax = _subtotal * settings.taxRate;
    final total = settings.taxInclusive
        ? _subtotal + service
        : _subtotal + service + tax;

    return DetailPanel(
      title: 'Receipt preview',
      child: Container(
        padding: const EdgeInsets.all(Insets.lg),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(Radii.sm),
          border: Border.all(color: context.semantic.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // The accent rule is where the brand colour actually lands on a
            // printed receipt, so the preview shows it there and nowhere else.
            Container(
              height: 4,
              width: 54,
              decoration: BoxDecoration(
                color: profile.brandColor,
                borderRadius: BorderRadius.circular(Radii.pill),
              ),
            ),
            const SizedBox(height: Insets.md),
            if (profile.logoBytes case final bytes?) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Image.memory(bytes, height: 44, fit: BoxFit.contain),
              ),
              const SizedBox(height: Insets.sm),
            ],
            Text(
              profile.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (profile.hasAddress) ...[
              const SizedBox(height: 2),
              Text(
                profile.formattedAddress,
                textAlign: TextAlign.center,
                style: muted,
              ),
            ],
            if (profile.phone.trim().isNotEmpty)
              Text(profile.phone, textAlign: TextAlign.center, style: muted),
            if (profile.website.trim().isNotEmpty)
              Text(profile.website, textAlign: TextAlign.center, style: muted),
            if (profile.taxId.trim().isNotEmpty)
              Text(
                'Tax ID ${profile.taxId}',
                textAlign: TextAlign.center,
                style: muted,
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Insets.md),
              child: Divider(height: 1),
            ),
            _PreviewLine(label: 'Subtotal', value: Fmt.money(_subtotal)),
            if (settings.serviceChargeRate > 0)
              _PreviewLine(
                label: 'Service (${Fmt.percent(settings.serviceChargeRate)})',
                value: Fmt.money(service),
              ),
            _PreviewLine(
              label: settings.taxInclusive
                  ? 'Tax included (${Fmt.percent(settings.taxRate)})'
                  : 'Tax (${Fmt.percent(settings.taxRate)})',
              value: Fmt.money(tax),
            ),
            const SizedBox(height: Insets.sm),
            _PreviewLine(
              label: 'Total',
              value: Fmt.money(total),
              emphasised: true,
            ),
            if (profile.receiptFooter.trim().isNotEmpty) ...[
              const SizedBox(height: Insets.md),
              Text(
                profile.receiptFooter,
                textAlign: TextAlign.center,
                style: muted?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({
    required this.label,
    required this.value,
    this.emphasised = false,
  });

  final String label;
  final String value;
  final bool emphasised;

  @override
  Widget build(BuildContext context) {
    final style = emphasised
        ? context.text.bodyMedium?.copyWith(fontWeight: FontWeight.w800)
        : context.text.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: Insets.sm),
          Text(value, maxLines: 1, style: style),
        ],
      ),
    );
  }
}
