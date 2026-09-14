/// Production state: recipe catalog, history ledger, and recording.
///
/// Recipes and production events both live in Inventory Service but arrive
/// through different endpoints with different shapes, so they get their own
/// notifiers rather than hanging off `InventoryNotifier` — the stock list
/// owns on-hand counts, this file owns everything about making things.
library;

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/inventory_api_service.dart';
import 'inventory_api_provider.dart';
import 'inventory_provider.dart';
import 'permissions_provider.dart';

// ---------------------------------------------------------------------------
// Recipe catalog
// ---------------------------------------------------------------------------

/// The recipes the kitchen can produce, as the backend resolved them —
/// ingredient names and units included, so no screen has to join anything
/// itself before showing a recipe card or computing a suggestion.
class RecipesCatalogNotifier extends AsyncNotifier<List<RecipeDto>> {
  @override
  Future<List<RecipeDto>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    if (businessId == null) return const [];
    return ref.watch(inventoryApiServiceProvider).fetchRecipes(
          businessId: businessId,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    state = const AsyncLoading<List<RecipeDto>>().copyWithPrevious(state);
    state = AsyncData(
      await ref.read(inventoryApiServiceProvider).fetchRecipes(
            businessId: businessId,
          ),
    );
  }

  /// The recipe that produces the backend item with [catalogItemId], if one
  /// is defined — the link the "Record production" action follows from a
  /// menu-item detail screen.
  RecipeDto? recipeForSellable(String catalogItemId) {
    for (final recipe in state.valueOrNull ?? const <RecipeDto>[]) {
      if (recipe.sellableItemId == catalogItemId) return recipe;
    }
    return null;
  }

  /// Creates a recipe, then re-reads the catalog so pickers and detail
  /// screens see it. Returns what the server stored.
  Future<RecipeDto> createRecipe({
    required String sellableItemId,
    String? name,
    required List<RecipeComponentInput> components,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) throw StateError('No active business context');
    final saved = await ref.read(inventoryApiServiceProvider).createRecipe(
          businessId: businessId,
          sellableItemId: sellableItemId,
          name: name,
          components: components,
        );
    await refresh();
    return saved;
  }

  /// Replaces a recipe's component list as a full set (plus optional
  /// rename), then re-reads the catalog. Lines absent from [components]
  /// are deleted server-side.
  Future<RecipeDto> updateRecipe({
    required String recipeId,
    String? name,
    required List<RecipeComponentInput> components,
  }) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) throw StateError('No active business context');
    final saved = await ref.read(inventoryApiServiceProvider).updateRecipe(
          businessId: businessId,
          recipeId: recipeId,
          name: name,
          components: components,
        );
    await refresh();
    return saved;
  }

  /// Deletes a recipe and re-reads the catalog. Refused server-side with a
  /// 409 when production runs were recorded against it.
  Future<void> deleteRecipe(String recipeId) async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) throw StateError('No active business context');
    await ref.read(inventoryApiServiceProvider).deleteRecipe(
          businessId: businessId,
          recipeId: recipeId,
        );
    await refresh();
  }
}

final recipesCatalogProvider =
    AsyncNotifierProvider<RecipesCatalogNotifier, List<RecipeDto>>(
      RecipesCatalogNotifier.new,
    );

/// The catalog, unwrapped for pickers that just need the current list.
final recipesCatalogListProvider = Provider<List<RecipeDto>>(
  (ref) => ref.watch(recipesCatalogProvider).valueOrNull ?? const [],
);

// ---------------------------------------------------------------------------
// Suggestion math (pure, client-side preview of the server's ratio)
// ---------------------------------------------------------------------------

/// What a production run will consume and suggest, computed locally so the
/// dialog previews live while typing — the server recomputes authoritatively
/// on submit, so this is a preview, never the committed record.
///
/// Null when no preview is possible yet: unknown leading ingredient, an
/// empty quantity, or a zero requirement (which would divide by zero).
@immutable
class ProductionPreview {
  const ProductionPreview({
    required this.ratio,
    required this.consumedByItemId,
    required this.suggestedOutput,
  });

  /// `leadingQty ÷ leadingRequirement` — doubles as the suggested output
  /// count, since one recipe makes one unit of the sellable item.
  final double ratio;

  /// Every ingredient's consumption at this ratio, keyed by backend item id.
  /// The leading entry is the typed value exactly, never ratio-rounded.
  final Map<String, double> consumedByItemId;

  final double suggestedOutput;

  static ProductionPreview? of({
    required RecipeDto recipe,
    required String leadingItemId,
    required double leadingQty,
  }) {
    if (leadingQty <= 0) return null;
    RecipeIngredientDto? leading;
    for (final component in recipe.components) {
      if (component.rawMaterialItemId == leadingItemId) leading = component;
    }
    if (leading == null) return null;
    final requirement = double.parse(leading.quantityRequired.toString());
    if (requirement <= 0) return null;

    final ratio = leadingQty / requirement;
    return ProductionPreview(
      ratio: ratio,
      suggestedOutput: ratio,
      consumedByItemId: {
        for (final component in recipe.components)
          component.rawMaterialItemId:
              component.rawMaterialItemId == leadingItemId
                  ? leadingQty
                  : double.parse(component.quantityRequired.toString()) * ratio,
      },
    );
  }
}

// ---------------------------------------------------------------------------
// History ledger
// ---------------------------------------------------------------------------

/// Date-range filter over production history. Null ends are open — "from
/// last Monday" needs no end date, and clearing is one call.
@immutable
class ProductionDateFilter {
  const ProductionDateFilter({this.from, this.to});

  final DateTime? from;
  final DateTime? to;

  ProductionDateFilter copyWith({DateTime? from, DateTime? to}) =>
      ProductionDateFilter(from: from ?? this.from, to: to ?? this.to);
}

class ProductionDateFilterNotifier extends Notifier<ProductionDateFilter> {
  @override
  ProductionDateFilter build() => const ProductionDateFilter();

  void setRange(DateTime? from, DateTime? to) =>
      state = ProductionDateFilter(from: from, to: to);

  void clear() => state = const ProductionDateFilter();
}

final productionDateFilterProvider =
    NotifierProvider<ProductionDateFilterNotifier, ProductionDateFilter>(
      ProductionDateFilterNotifier.new,
    );

/// Recorded production runs, newest first — the kitchen's ledger.
///
/// With no business context this is empty (recording genuinely needs the
/// backend's atomic transaction; unlike stock counts there is no meaningful
/// demo-mode production to invent).
class ProductionHistoryNotifier extends AsyncNotifier<List<ProductionEventDto>> {
  InventoryApiService get _api => ref.read(inventoryApiServiceProvider);

  String? get _businessId => ref.read(currentBusinessIdProvider);

  @override
  Future<List<ProductionEventDto>> build() async {
    final businessId = ref.watch(currentBusinessIdProvider);
    final filter = ref.watch(productionDateFilterProvider);
    if (businessId == null) return const [];
    return ref.watch(inventoryApiServiceProvider).fetchProductionEvents(
          businessId: businessId,
          from: filter.from,
          to: filter.to,
        );
  }

  Future<void> refresh() async {
    final businessId = ref.read(currentBusinessIdProvider);
    if (businessId == null) return;
    final filter = ref.read(productionDateFilterProvider);
    state = const AsyncLoading<List<ProductionEventDto>>().copyWithPrevious(state);
    state = AsyncData(
      await _api.fetchProductionEvents(
        businessId: businessId,
        from: filter.from,
        to: filter.to,
      ),
    );
  }

  /// Records a production run, then re-reads history and stock counts.
  ///
  /// Both refreshes matter: the ledger must show the new run, and every
  /// touched stock count moved server-side. Returns the recorded event so
  /// the dialog can confirm with real numbers.
  Future<ProductionEventDto> recordProduction({
    required String recipeId,
    required String leadingItemId,
    required double leadingQuantity,
    double? actualOutput,
  }) async {
    final businessId = _businessId;
    if (businessId == null) throw StateError('No active business context');
    final event = await _api.recordProduction(
      businessId: businessId,
      recipeId: recipeId,
      leadingItemId: leadingItemId,
      leadingQuantityUsed: Decimal.parse(leadingQuantity.toString()),
      actualOutputQuantity: actualOutput == null
          ? null
          : Decimal.parse(actualOutput.toString()),
    );
    await refresh();
    // Stock moved on every leg — the grocery counts are stale until this
    // re-syncs, the same read-after-write discipline as item creation.
    await ref.read(inventoryItemsProvider.notifier).refresh();
    return event;
  }
}

final productionHistoryProvider =
    AsyncNotifierProvider<ProductionHistoryNotifier, List<ProductionEventDto>>(
      ProductionHistoryNotifier.new,
    );

/// The ledger, unwrapped for the history screen.
final productionHistoryListProvider = Provider<List<ProductionEventDto>>(
  (ref) => ref.watch(productionHistoryProvider).valueOrNull ?? const [],
);
