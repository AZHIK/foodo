import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/l10n.dart';
import '../theme/breakpoints.dart';

/// How tightly the data tables pack their rows.
///
/// A device preference rather than a business one: the same venue's counter
/// terminal wants comfortable rows for a thumb, and the back-office laptop
/// wants to see twenty lines of stock at once.
enum TableDensity {
  comfortable(
    'comfortableDensity',
    'Comfortable',
    'comfortableBlurb',
    'Roomier rows, easier to tap',
  ),
  compact(
    'compactDensity',
    'Compact',
    'compactBlurb',
    'More rows on screen at once',
  );

  const TableDensity(
    this.labelKey,
    this.labelDefault,
    this.descriptionKey,
    this.descriptionDefault,
  );

  final String labelKey;
  final String labelDefault;
  final String descriptionKey;
  final String descriptionDefault;

  /// Localized display name — re-evaluated on every build.
  String get label => L10n.t(labelKey, labelDefault);

  String get description => L10n.t(descriptionKey, descriptionDefault);

  /// Vertical padding inside a table row. Read by [ReusableDataTable], which is
  /// what makes this setting a real one rather than a stored boolean.
  double get rowPadding => switch (this) {
    TableDensity.comfortable => Insets.md - 2,
    TableDensity.compact => Insets.xs + 1,
  };

  /// Header rows track the body so the two never look mismatched.
  double get headerPadding => switch (this) {
    TableDensity.comfortable => Insets.md - 2,
    TableDensity.compact => Insets.sm - 2,
  };

  /// How many rows a card list shows between separators. Cards stay
  /// comfortable on a phone regardless — a compact card is just a cramped one.
  double get cardGap => switch (this) {
    TableDensity.comfortable => Insets.md,
    TableDensity.compact => Insets.sm,
  };
}

class TableDensityNotifier extends Notifier<TableDensity> {
  @override
  TableDensity build() => TableDensity.comfortable;

  void set(TableDensity density) => state = density;
}

final tableDensityProvider =
    NotifierProvider<TableDensityNotifier, TableDensity>(
      TableDensityNotifier.new,
    );

/// The languages the UI is offered in.
///
/// One entry today. The dropdown exists anyway because the shape of the
/// setting is what a second language needs, and adding one should be a line
/// here rather than a new control on the screen.
enum AppLanguage {
  english('en'),
  swahili('sw');

  const AppLanguage(this.code);

  final String code;

  /// Display name — English localizes to 'Kiingereza', Kiswahili is the
  /// same word in both languages.
  String get label => switch (this) {
    AppLanguage.english => L10n.t('englishLanguage', 'English'),
    AppLanguage.swahili => 'Kiswahili',
  };
}

class AppLanguageNotifier extends Notifier<AppLanguage> {
  @override
  AppLanguage build() {
    // Provider is the source of truth for the UI; keep the synchronous
    // L10n runtime in sync so L10n.t()/isSw and the API Accept-Language
    // header always match the visible selection.
    final initial = L10n.isSw ? AppLanguage.swahili : AppLanguage.english;
    if (L10n.code.value != initial.code) L10n.code.value = initial.code;
    return initial;
  }

  void set(AppLanguage language) {
    if (state == language && L10n.code.value == language.code) return;
    state = language;
    if (L10n.code.value != language.code) L10n.code.value = language.code;
  }
}

final appLanguageProvider = NotifierProvider<AppLanguageNotifier, AppLanguage>(
  AppLanguageNotifier.new,
);

/// Which alerts this terminal raises.
@immutable
class NotificationPrefs {
  const NotificationPrefs({
    this.lowStock = true,
    this.orderSounds = true,
    this.dailySummary = false,
  });

  /// Warn when a stock line drops under its reorder level.
  final bool lowStock;

  /// Chime when a ticket lands at this terminal.
  final bool orderSounds;

  /// Email yesterday's takings to the owner each morning.
  final bool dailySummary;

  NotificationPrefs copyWith({
    bool? lowStock,
    bool? orderSounds,
    bool? dailySummary,
  }) {
    return NotificationPrefs(
      lowStock: lowStock ?? this.lowStock,
      orderSounds: orderSounds ?? this.orderSounds,
      dailySummary: dailySummary ?? this.dailySummary,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationPrefs &&
      other.lowStock == lowStock &&
      other.orderSounds == orderSounds &&
      other.dailySummary == dailySummary;

  @override
  int get hashCode => Object.hash(lowStock, orderSounds, dailySummary);
}

class NotificationPrefsNotifier extends Notifier<NotificationPrefs> {
  @override
  NotificationPrefs build() => const NotificationPrefs();

  void setLowStock(bool value) => state = state.copyWith(lowStock: value);

  void setOrderSounds(bool value) => state = state.copyWith(orderSounds: value);

  void setDailySummary(bool value) =>
      state = state.copyWith(dailySummary: value);
}

final notificationPrefsProvider =
    NotifierProvider<NotificationPrefsNotifier, NotificationPrefs>(
      NotificationPrefsNotifier.new,
    );
