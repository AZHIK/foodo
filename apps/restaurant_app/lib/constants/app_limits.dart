/// Every numeric limit the app enforces or assumes, in one place.
///
/// Page sizes, batch caps, picker suggestion counts, validation lengths and
/// upload bounds. Screen-specific tables that share a density read the same
/// value, so "8 rows" stops being a coincidence repeated in six providers.
library;

abstract final class AppLimits {
  // -------------------------------------------------------------------------
  // Tables & lists
  // -------------------------------------------------------------------------

  /// Default data-table page size.
  static const tablePageSize = 10;

  /// Dense tables (groceries, menu items, sales, staff, expenses, incomes,
  /// customer orders, movement history).
  static const tablePageSizeDense = 8;

  static const locationsPageSize = 25;
  static const rolesPageSize = 50;

  // -------------------------------------------------------------------------
  // Sync
  // -------------------------------------------------------------------------

  /// Backend list endpoints cap a page at 100 rows — a full-catalog sync
  /// pages through until a page comes back short of this.
  static const catalogFetchPageSize = 100;

  /// Outbox batch size per sync flush (sales, finance, customers).
  static const syncBatchSize = 50;

  // -------------------------------------------------------------------------
  // Dashboard & pickers
  // -------------------------------------------------------------------------

  static const customerPickerSuggestions = 20;
  static const dashboardRecentOrders = 6;
  static const dashboardTopItems = 3;
  static const activeStaffShown = 3;

  /// Rows shown in dashboard lists (top items, activity feed preview).
  static const dashboardListLimit = 5;
  static const insightHighlights = 3;
  static const lowStockNamesShown = 3;

  /// How many permissions to name before summarising the rest.
  static const rolePreviewCount = 3;

  /// Trend lookback in days.
  static const trendDays = 7;

  // -------------------------------------------------------------------------
  // Reports
  // -------------------------------------------------------------------------

  static const reportsItemMixLimit = 50;

  /// Length of the stable short id shown where the backend only knows an
  /// actor/item UUID (staff rows, takings exports).
  static const shortIdLength = 8;

  /// Tables offered by the order-type table picker (1..N plus counter).
  static const posTableCount = 24;

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  static const pinLength = 6;
  static const otpCodeLength = 6;
  static const tzPhoneDigits = 9;
  static const pinMaxAttempts = 3;
  static const adjustReasonMinLength = 3;
  static const orderNumberWidth = 4;

  /// Modulus for the generated placeholder SKU suffix (0–9999).
  static const skuSuffixMod = 10000;
  static const staffCountMaxDigits = 3;
  static const taxWholeDigits = 3;
  static const taxFractionDigits = 2;
  static const receiptPrefixLength = 8;

  // -------------------------------------------------------------------------
  // Photos
  // -------------------------------------------------------------------------

  /// Upload cap, mirroring the backend's 5 MB limit — and the hint text the
  /// picker shows, which must never disagree with it (see `AppStrings`).
  static const imageMaxBytes = 5 * 1024 * 1024;

  /// Picker downscale target: plenty for a ~190px thumbnail.
  static const pickerMaxWidth = 1200.0;
  static const pickerMaxHeight = 1200.0;
  static const pickerQuality = 85;
}
