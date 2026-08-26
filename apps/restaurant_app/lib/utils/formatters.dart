import 'package:intl/intl.dart';

import '../models/store_settings.dart';

/// Display formatting helpers. Centralised so currency/locale becomes a single
/// change when the app is localised or a backend supplies the store's currency.
abstract final class Fmt {
  /// The store's currency, applied by [use].
  ///
  /// A mutable static rather than something threaded through every call site:
  /// money is formatted in a few hundred places, and none of them wants a
  /// `WidgetRef` to print a price. The app root watches `currencyProvider` and
  /// calls [use] before the tree below it builds, so the value is always the
  /// configured one by the time anything reads it.
  static Currency _currency = Currency.usd;

  static NumberFormat _money = _moneyFormat(Currency.usd);
  static NumberFormat _compactMoney = _compactFormat(Currency.usd);

  static Currency get currency => _currency;

  /// Points every money formatter at [currency]. Cheap and idempotent — it
  /// rebuilds the formatters only when the currency actually changed.
  static void use(Currency currency) {
    if (currency == _currency) return;
    _currency = currency;
    _money = _moneyFormat(currency);
    _compactMoney = _compactFormat(currency);
  }

  static NumberFormat _moneyFormat(Currency currency) => NumberFormat.currency(
    locale: currency.locale,
    symbol: currency.symbol,
    decimalDigits: currency.decimalDigits,
  );

  static NumberFormat _compactFormat(Currency currency) =>
      NumberFormat.compactCurrency(
        locale: currency.locale,
        symbol: currency.symbol,
      );

  static final _time = DateFormat.jm();
  static final _dayMonth = DateFormat('d MMM');
  static final _dayMonthTime = DateFormat('d MMM, h:mm a');
  static final _weekday = DateFormat('EEEE, d MMMM');

  static String money(double value) => _money.format(value);

  /// Formats in a currency that is *not* the configured one.
  ///
  /// For previews only — the Store Settings dropdown has to show what a price
  /// will look like before the choice is saved, which is the one place the
  /// app deliberately formats money outside its own currency.
  static String moneyIn(Currency currency, double value) =>
      _moneyFormat(currency).format(value);

  /// The bare currency symbol, for prefixing an amount the user types — where
  /// a fully formatted string would fight with the text being edited.
  static String get currencySymbol => _money.currencySymbol;

  /// A typed amount rendered back into the field: no symbol, no grouping, so
  /// what the cashier sees is what the parser will read.
  static String editableAmount(double value) =>
      value.toStringAsFixed(_currency.decimalDigits);

  /// Parses what the cashier typed. Tolerates the currency symbol, spaces and
  /// thousands separators, because people paste and fat-finger.
  static double? parseAmount(String input) {
    final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  /// Shortens to `$1.2K` past four figures — keeps summary tiles from wrapping.
  static String moneyCompact(double value) =>
      value.abs() >= 10000 ? _compactMoney.format(value) : _money.format(value);

  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(fraction * 100 % 1 == 0 ? 0 : 2)}%';

  static String time(DateTime dt) => _time.format(dt);

  static String dayMonth(DateTime dt) => _dayMonth.format(dt);

  static String dayMonthTime(DateTime dt) => _dayMonthTime.format(dt);

  static String longDate(DateTime dt) => _weekday.format(dt);

  /// "Today, 2:15 PM" / "Yesterday, 9:03 AM" / "6 Aug, 7:40 PM".
  static String relativeDateTime(DateTime dt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final days = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;

    return switch (days) {
      0 => 'Today, ${time(dt)}',
      1 => 'Yesterday, ${time(dt)}',
      _ => dayMonthTime(dt),
    };
  }
}
