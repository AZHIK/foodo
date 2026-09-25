import '../models/order.dart';
import '../utils/formatters.dart';
import 'thermal_receipt.dart';

/// Builds the claim coupon: store proof, the order number, and big items.
///
/// The items are the most visible thing on the paper — the kitchen and the
/// counter read dishes first, the order number second. Deliberately minimal
/// otherwise: no prices, totals or payment. What the customer holds up at
/// the counter: *these dishes, from this restaurant*.
List<ThermalLine> buildThermalCoupon({
  required Order order,
  required String storeName,
  String? phone,
  List<String> addressLines = const [],
  int lineWidth = ThermalReceipt.lineWidth,
}) {
  final lines = <ThermalLine>[];

  // ——— Store proof ———
  for (final wrapped in wrapThermalText(storeName, lineWidth)) {
    lines.add(
      ThermalLine.text(wrapped, align: ThermalAlign.center, bold: true),
    );
  }
  for (final address in addressLines) {
    for (final wrapped in wrapThermalText(address, lineWidth)) {
      lines.add(ThermalLine.text(wrapped, align: ThermalAlign.center));
    }
  }
  if (phone != null && phone.trim().isNotEmpty) {
    lines.add(
      ThermalLine.text('Tel: ${phone.trim()}', align: ThermalAlign.center),
    );
  }
  lines.add(const ThermalLine.rule());

  // ——— Order number: bold and ruled off, but second to the items ———
  lines.add(
    ThermalLine.text(order.id, align: ThermalAlign.center, bold: true),
  );
  lines.add(const ThermalLine.rule());

  // ——— Items: the largest thing on the paper ———
  for (final line in order.lines) {
    // Single space: the wrapper splits on runs of whitespace, so a double
    // space would not survive to the paper anyway.
    final label = '${line.quantity}x ${line.name}';
    final wrapped = wrapThermalText(label, lineWidth);
    for (var i = 0; i < wrapped.length; i++) {
      lines.add(
        ThermalLine.text(
          // Continuation rows indent under the quantity, so "2x" stays the
          // eye's anchor even on a wrapped name.
          i == 0 ? wrapped[i] : '    ${wrapped[i]}',
          bold: true,
          big: true,
        ),
      );
    }
  }
  lines.add(const ThermalLine.rule());

  // ——— Footnote: when, and where to claim ———
  final table = order.tableLabel?.trim();
  final footnote = table != null && table.isNotEmpty
      ? '${Fmt.dayMonthTime(order.placedAt)} · $table'
      : Fmt.dayMonthTime(order.placedAt);
  for (final wrapped in wrapThermalText(footnote, lineWidth)) {
    lines.add(ThermalLine.text(wrapped, align: ThermalAlign.center));
  }

  return lines;
}
