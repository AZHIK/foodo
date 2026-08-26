/// Shared widget library for FoodLink Business App.
///
/// Import this single file to access every reusable widget:
/// ```dart
/// import '../../../shared/widgets/widgets.dart';
/// ```
library;

// ── Auth / layout primitives (kept at root for back-compat) ────────
export 'app_auth_page.dart';
export 'app_button.dart' show AppTextButton;
export 'app_card.dart';
export 'app_list_tile.dart';
export 'app_empty_state.dart';
export 'app_offline_banner.dart';
export 'app_pin_pad.dart';
export 'app_responsive_layout.dart';
export 'app_section_header.dart';
export 'app_status_chip.dart';

// ── cards/ ─────────────────────────────────────────────────────────
export 'cards/stat_card.dart';
export 'cards/product_card.dart';
export 'cards/info_card.dart';

// ── forms/ ─────────────────────────────────────────────────────────
export 'forms/app_text_field.dart';
export 'forms/app_number_field.dart';
export 'forms/app_dropdown_field.dart';
export 'forms/app_search_field.dart';
export 'forms/filter_pill_bar.dart';
export 'forms/money_field.dart';

// ── buttons/ ───────────────────────────────────────────────────────
export 'buttons/app_primary_button.dart';
export 'buttons/app_secondary_button.dart';
export 'buttons/app_icon_button.dart';
export 'buttons/app_fab.dart';

// ── feedback/ ──────────────────────────────────────────────────────
export 'feedback/skeleton_loader.dart';
export 'feedback/status_badge.dart';
export 'feedback/app_snackbar.dart';
export 'feedback/app_dialog.dart';

// ── data_table/ ────────────────────────────────────────────────────
export 'data_table/app_data_table.dart';
export 'data_table/export_service.dart';
