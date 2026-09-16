import 'package:intl/intl.dart';

import '../constants/app_strings.dart';
import '../l10n/l10n.dart';
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
  static Currency _currency = Currency.tzs;

  static NumberFormat _money = _moneyFormat(Currency.tzs);
  static NumberFormat _compactMoney = _compactFormat(Currency.tzs);

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

  /// Locale-aware date formats, built per call so a language toggle takes
  /// effect on the next build. (Cached `static final` formats would pin
  /// month/weekday names to the launch language.)
  ///
  /// Swahili symbols load async at startup (`initializeDateFormatting` in
  /// `main`); if they are not ready yet — tests, first frame — formatting
  /// falls back to the default locale instead of throwing.
  static String _date(String pattern, DateTime dt) {
    if (L10n.isSw) {
      try {
        return DateFormat(pattern, 'sw').format(dt);
      } catch (_) {
        return DateFormat(pattern).format(dt);
      }
    }
    return DateFormat(pattern).format(dt);
  }

  static String _timeOfDay(DateTime dt) {
    if (L10n.isSw) {
      try {
        return DateFormat.jm('sw').format(dt);
      } catch (_) {
        return DateFormat.jm().format(dt);
      }
    }
    return DateFormat.jm().format(dt);
  }

  static String time(DateTime dt) => _timeOfDay(dt);

  static String dayMonth(DateTime dt) => _date('d MMM', dt);

  static String dayMonthTime(DateTime dt) => _date('d MMM, h:mm a', dt);

  static String longDate(DateTime dt) => _date('EEEE, d MMMM', dt);

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

  /// Shortens to `TSh 12K` past four figures — keeps summary tiles from wrapping.
  static String moneyCompact(double value) =>
      value.abs() >= 10000 ? _compactMoney.format(value) : _money.format(value);

  static String percent(double fraction) =>
      '${(fraction * 100).toStringAsFixed(fraction * 100 % 1 == 0 ? 0 : 2)}%';

  static final _quantity = NumberFormat('#,##0.###');

  /// A stock quantity: whole units print as `35`, fractional ones (kg/L
  /// items) as `2.5` — never `35.0` or a long float tail.
  static String quantity(double value) => _quantity.format(value);

  /// "Today, 2:15 PM" / "Yesterday, 9:03 AM" / "6 Aug, 7:40 PM"
  /// (localized day words + month names).
  static String relativeDateTime(DateTime dt, {DateTime? now}) {
    final reference = now ?? DateTime.now();
    final days = DateTime(
      reference.year,
      reference.month,
      reference.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;

    return switch (days) {
      0 => AppStrings.relativeToday(time(dt)),
      1 => AppStrings.relativeYesterday(time(dt)),
      _ => dayMonthTime(dt),
    };
  }
}
