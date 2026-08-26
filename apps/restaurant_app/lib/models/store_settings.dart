import 'package:flutter/material.dart';

import 'order.dart';

/// The currencies a venue can be configured in.
///
/// Locale and symbol travel together because [NumberFormat] needs both: a
/// symbol without its locale puts the group separators in the wrong places, and
/// a locale without its symbol prints the wrong currency entirely.
enum Currency {
  usd('USD', r'$', 'en_US', 'US dollar'),
  eur('EUR', '€', 'de_DE', 'Euro'),
  gbp('GBP', '£', 'en_GB', 'Pound sterling'),
  idr('IDR', 'Rp', 'id_ID', 'Indonesian rupiah'),
  sgd('SGD', r'S$', 'en_SG', 'Singapore dollar'),
  aud('AUD', r'A$', 'en_AU', 'Australian dollar');

  const Currency(this.code, this.symbol, this.locale, this.description);

  final String code;
  final String symbol;
  final String locale;
  final String description;

  /// Rupiah is quoted in whole units — "Rp 48.000,50" is not a price anyone
  /// writes — where the rest of these carry cents.
  int get decimalDigits => this == Currency.idr ? 0 : 2;

  String get label => '$code · $symbol';
}

/// A single day's trading hours.
///
/// [open] and [close] are kept even while [isOpen] is false, so toggling a day
/// shut for a public holiday and back on again does not lose the times someone
/// already set.
@immutable
class DayHours {
  const DayHours({
    required this.isOpen,
    this.open = const TimeOfDay(hour: 9, minute: 0),
    this.close = const TimeOfDay(hour: 22, minute: 0),
  });

  final bool isOpen;
  final TimeOfDay open;
  final TimeOfDay close;

  /// True where the shift runs past midnight — a bar closing at 02:00 is a
  /// normal Friday, not a mistake, so it is described rather than rejected.
  bool get isOvernight =>
      _minutes(close) <= _minutes(open) && isOpen;

  static int _minutes(TimeOfDay t) => t.hour * 60 + t.minute;

  DayHours copyWith({bool? isOpen, TimeOfDay? open, TimeOfDay? close}) =>
      DayHours(
        isOpen: isOpen ?? this.isOpen,
        open: open ?? this.open,
        close: close ?? this.close,
      );

  @override
  bool operator ==(Object other) =>
      other is DayHours &&
      other.isOpen == isOpen &&
      other.open == open &&
      other.close == close;

  @override
  int get hashCode => Object.hash(isOpen, open, close);
}

/// Weekday labels for the operating-hours list, Monday first — a trading week
/// starts on Monday everywhere this app is likely to be installed.
const kWeekdayNames = <String>[
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

const kWeekdayShortNames = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// How this terminal *behaves* — as distinct from [BusinessProfile], which is
/// who the business *is*.
///
/// The split matters because the two are edited by different people at
/// different times: a tax rate change is an accounting decision, a logo change
/// is a marketing one. Everything here has a consumer elsewhere in the app —
/// the tax rate opens every ticket, the default order type pre-selects the POS
/// panel, the currency formats every amount on screen.
@immutable
class StoreSettings {
  const StoreSettings({
    this.taxRate = 0.0825,
    this.taxInclusive = false,
    this.serviceChargeRate = 0,
    this.currency = Currency.usd,
    this.defaultOrderType = OrderType.dineIn,
    this.receiptPrefix = 'INV-',
    this.autoPrintReceipt = true,
    // Always seven entries, Monday first. Not asserted: the constructor is
    // const, and a const evaluation cannot read a list's length.
    this.hours = defaultHours,
  });

  /// Stored as a fraction (0.0825), entered as a percentage. Keeping the
  /// fraction canonical means the checkout maths never divides by 100.
  final double taxRate;

  /// Whether menu prices already include tax. Changes what a receipt says, not
  /// what the customer pays.
  final bool taxInclusive;

  final double serviceChargeRate;

  final Currency currency;

  /// Pre-selected on the POS order panel when a ticket is started.
  final OrderType defaultOrderType;

  /// Prepended to receipt numbers, e.g. "INV-" → "INV-1042".
  final String receiptPrefix;

  final bool autoPrintReceipt;

  /// Monday-first, always seven entries.
  final List<DayHours> hours;

  /// A restaurant week: closed Monday, long weekend service.
  static const defaultHours = <DayHours>[
    DayHours(isOpen: false),
    DayHours(isOpen: true),
    DayHours(isOpen: true),
    DayHours(isOpen: true),
    DayHours(
      isOpen: true,
      open: TimeOfDay(hour: 11, minute: 0),
      close: TimeOfDay(hour: 23, minute: 30),
    ),
    DayHours(
      isOpen: true,
      open: TimeOfDay(hour: 10, minute: 0),
      close: TimeOfDay(hour: 23, minute: 30),
    ),
    DayHours(
      isOpen: true,
      open: TimeOfDay(hour: 10, minute: 0),
      close: TimeOfDay(hour: 21, minute: 0),
    ),
  ];

  /// "Closed Mondays" / "Open every day" — the one-line readout the settings
  /// index shows without opening the screen.
  String get hoursSummary {
    final closed = [
      for (var i = 0; i < hours.length; i++)
        if (!hours[i].isOpen) kWeekdayShortNames[i],
    ];
    if (closed.isEmpty) return 'Open every day';
    if (closed.length == 7) return 'Closed all week';
    return 'Closed ${closed.join(', ')}';
  }

  StoreSettings copyWith({
    double? taxRate,
    bool? taxInclusive,
    double? serviceChargeRate,
    Currency? currency,
    OrderType? defaultOrderType,
    String? receiptPrefix,
    bool? autoPrintReceipt,
    List<DayHours>? hours,
  }) {
    return StoreSettings(
      taxRate: taxRate ?? this.taxRate,
      taxInclusive: taxInclusive ?? this.taxInclusive,
      serviceChargeRate: serviceChargeRate ?? this.serviceChargeRate,
      currency: currency ?? this.currency,
      defaultOrderType: defaultOrderType ?? this.defaultOrderType,
      receiptPrefix: receiptPrefix ?? this.receiptPrefix,
      autoPrintReceipt: autoPrintReceipt ?? this.autoPrintReceipt,
      hours: hours ?? this.hours,
    );
  }

  /// Replaces one day without the caller having to rebuild the whole list.
  StoreSettings withDay(int index, DayHours day) => copyWith(
    hours: [
      for (var i = 0; i < hours.length; i++)
        if (i == index) day else hours[i],
    ],
  );

  @override
  bool operator ==(Object other) =>
      other is StoreSettings &&
      other.taxRate == taxRate &&
      other.taxInclusive == taxInclusive &&
      other.serviceChargeRate == serviceChargeRate &&
      other.currency == currency &&
      other.defaultOrderType == defaultOrderType &&
      other.receiptPrefix == receiptPrefix &&
      other.autoPrintReceipt == autoPrintReceipt &&
      _sameHours(other.hours, hours);

  @override
  int get hashCode => Object.hash(
    taxRate,
    taxInclusive,
    serviceChargeRate,
    currency,
    defaultOrderType,
    receiptPrefix,
    autoPrintReceipt,
    Object.hashAll(hours),
  );

  static bool _sameHours(List<DayHours> a, List<DayHours> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
