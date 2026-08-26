import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';

/// Styled generic dropdown / select input.
///
/// Generic over type `T` so callers can work with typed enums, entity
/// IDs, etc. rather than stringly-typed values.  Values are matched by
/// equality (==) so `T` should have usable equality semantics.
///
/// Usage with an enum:
/// ```dart
/// AppDropdownField<PaymentMethod>(
///   label: 'Payment method',
///   value: _selected,
///   options: PaymentMethod.values,
///   labelBuilder: (m) => switch (m) {
///     PaymentMethod.cash => 'Cash',
///     PaymentMethod.card => 'Card',
///     _ => m.name,
///   },
///   onChanged: (m) => setState(() => _selected = m),
/// )
/// ```
class AppDropdownField<T> extends FormField<T> {
  AppDropdownField({
    super.key,
    required List<T> options,
    required String label,
    required ValueChanged<T?> onChanged,
    T? value,
    String? hint,
    String Function(T option)? labelBuilder,
    Widget Function(T option)? leadingBuilder,
    IconData? prefixIcon,
    super.enabled = true,
    bool isExpanded = true,
    super.validator,
  }) : super(
         initialValue: value,
         builder: (state) {
           final cs = Theme.of(state.context).colorScheme;
           final labelFor = labelBuilder ?? (T o) => o.toString();

           final border = OutlineInputBorder(
             borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
             borderSide: BorderSide(
               color: cs.outlineVariant.withValues(alpha: 0.9),
               width: 0.8,
             ),
           );

           final enabledBorder = OutlineInputBorder(
             borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
             borderSide: BorderSide(
               color: cs.outlineVariant.withValues(alpha: 0.9),
               width: 0.8,
             ),
           );

           final focusedBorder = OutlineInputBorder(
             borderRadius: BorderRadius.circular(AppDimensions.radiusMD),
             borderSide: BorderSide(color: cs.primary, width: 1.2),
           );

           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               InputDecorator(
                 decoration: InputDecoration(
                   labelText: label,
                   hintText: hint,
                   prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
                   border: border,
                   enabledBorder: enabled
                       ? enabledBorder
                       : enabledBorder.copyWith(
                           borderSide: BorderSide(
                             color: cs.onSurface.withValues(alpha: 0.12),
                           ),
                         ),
                   focusedBorder: focusedBorder,
                   contentPadding: const EdgeInsets.symmetric(
                     horizontal: AppDimensions.spaceMD,
                     vertical: AppDimensions.spaceSM,
                   ),
                   errorText: state.errorText,
                 ),
                 isEmpty: state.value == null,
                 isFocused: false,
                 child: DropdownButtonHideUnderline(
                   child: DropdownButton<T>(
                     value: state.value,
                     isDense: true,
                     isExpanded: isExpanded,
                     style: AppTextStyles.bodyLarge.copyWith(
                       color: enabled
                           ? cs.onSurface.withValues(alpha: 0.86)
                           : cs.onSurface.withValues(alpha: 0.38),
                     ),
                     icon: Icon(
                       Icons.arrow_drop_down_rounded,
                       color: enabled
                           ? cs.onSurface.withValues(alpha: 0.6)
                           : cs.onSurface.withValues(alpha: 0.38),
                     ),
                     items: options
                         .map(
                           (o) => DropdownMenuItem<T>(
                             value: o,
                             child: Row(
                               children: [
                                 if (leadingBuilder != null) ...[
                                   leadingBuilder(o),
                                   const SizedBox(width: AppDimensions.spaceSM),
                                 ],
                                 Expanded(
                                   child: Text(
                                     labelFor(o),
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         )
                         .toList(),
                     selectedItemBuilder: (ctx) => options
                         .map(
                           (o) => Text(
                             labelFor(o),
                             overflow: TextOverflow.ellipsis,
                             maxLines: 1,
                           ),
                         )
                         .toList(),
                     onChanged: enabled
                         ? (v) {
                             state.didChange(v);
                             onChanged(v);
                           }
                         : null,
                   ),
                 ),
               ),
             ],
           );
         },
       );
}
