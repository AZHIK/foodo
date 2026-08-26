import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../shared/fakes/fake_data_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../widgets/pos_catalog_view.dart';
import '../widgets/pos_layout_model.dart';
import 'payment_screen.dart';
import 'pos/pos_desktop_layout.dart';
import 'pos/pos_mobile_layout.dart';
import 'pos/pos_tablet_layout.dart';
import 'receipt_screen.dart';

/// Main POS sale-builder screen.
///
/// POS is deliberately offline-first: the ticket is built entirely in local
/// widget state, using the same fake inventory catalog that powers Inventory.
/// Completing the ticket hands the locally computed cart to the payment step;
/// there is no server-side open-sale state and no network/sync blocking UI in
/// the sale-building flow.
///
/// ## Responsive structure
///
/// This screen holds *state only*. The visual tree is one of three
/// per-form-factor layouts, each in its own file under `screens/pos/`:
///
/// | Tier    | Width      | Layout                                        |
/// |---------|------------|-----------------------------------------------|
/// | Mobile  | <600px     | [PosMobileLayout] — segmented Browse/Cart,     |
/// |         |            | own Scaffold, persistent checkout bar          |
/// | Tablet  | 600–899px  | [PosTabletLayout] — dense two-panel, cart      |
/// |         |            | width proportional, compact cart rows          |
/// | Desktop | >=900px    | [PosDesktopLayout] — roomy two-panel, header   |
/// |         |            | with breadcrumb, detailed cart rows            |
///
/// All three receive the same [PosLayoutModel] — the filtered catalog, the
/// computed totals, and the callbacks below — so cart maths lives in exactly
/// one place and a layout can be reworked for its form factor without any
/// risk of the tiers drifting apart behaviourally.
///
/// Dispatch reads [MediaQuery] width, not the local constraints, so this
/// screen's tier always matches the one [MainShell] used to pick its own
/// chrome. Constraint-based dispatch would disagree with the shell whenever
/// the sidebar/rail eats enough width to cross a breakpoint — e.g. a 640px
/// window (shell shows its rail, so this screen must *not* draw its own
/// AppBar) leaves only ~550px of body, which reads as "mobile".
///
/// The tablet and desktop layouts share one two-panel skeleton on purpose:
/// crossing 900px mid-resize changes density, not structure. A hard
/// widget-tree swap at that boundary is what made resizing unstable before.
///
/// Payment flow decision: payment is a separate modal/screen widget
/// ([PaymentScreen]) launched from this screen. This keeps the sale-building
/// surface focused and lets receipt generation live with payment completion.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  static const double _defaultTaxRate = 0.18;

  final TextEditingController _searchController = TextEditingController();
  final Map<String, PosCartLine> _cart = <String, PosCartLine>{};

  String _query = '';
  String _category = PosCatalogFilters.allCategories;
  int _saleDiscountSenti = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int get _subtotalSenti {
    return _cart.values.fold<int>(0, (sum, line) => sum + line.lineTotalSenti);
  }

  int get _taxableSenti =>
      (_subtotalSenti - _saleDiscountSenti).clamp(0, 1 << 62).toInt();

  int get _taxSenti => (_taxableSenti * _defaultTaxRate).round();

  int get _totalSenti => _taxableSenti + _taxSenti;

  int get _cartQuantity {
    return _cart.values.fold<int>(0, (sum, line) => sum + line.quantity);
  }

  bool get _hasCart => _cart.isNotEmpty;

  void _addItem(FakeInventoryItem item) {
    if (!item.isActive || item.isOutOfStock) return;
    setState(() {
      final existing = _cart[item.id];
      if (existing == null) {
        _cart[item.id] = PosCartLine(item: item);
      } else {
        _cart[item.id] = existing.copyWith(quantity: existing.quantity + 1);
      }
    });
  }

  void _setQuantity(String itemId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _cart.remove(itemId);
        return;
      }
      final existing = _cart[itemId];
      if (existing != null) {
        _cart[itemId] = existing.copyWith(quantity: quantity);
      }
    });
  }

  void _removeLine(String itemId) {
    setState(() => _cart.remove(itemId));
  }

  void _setLineDiscount(String itemId, int discountSenti) {
    setState(() {
      final existing = _cart[itemId];
      if (existing == null) return;
      _cart[itemId] = existing.copyWith(
        discountSenti: discountSenti.clamp(0, existing.grossTotalSenti),
      );
    });
  }

  void _setSaleDiscount(int discountSenti) {
    setState(() {
      _saleDiscountSenti = discountSenti.clamp(0, _subtotalSenti);
    });
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _saleDiscountSenti = 0;
    });
  }

  Future<void> _completeSale() async {
    if (!_hasCart) return;
    final sale = await showDialog<FakeSale>(
      context: context,
      builder: (context) => PaymentScreen(
        lines: _cart.values
            .map(
              (line) => PaymentLineDraft(
                itemId: line.item.id,
                itemName: line.item.name,
                quantity: line.quantity,
                unitPriceSenti: line.item.priceSenti,
                discountSenti: line.discountSenti,
              ),
            )
            .toList(),
        subtotalSenti: _subtotalSenti,
        saleDiscountSenti: _saleDiscountSenti,
        taxSenti: _taxSenti,
        totalSenti: _totalSenti,
      ),
    );
    if (!mounted || sale == null) return;
    _clearCart();
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => ReceiptScreen(sale: sale)));
  }

  List<FakeInventoryItem> _filter(List<FakeInventoryItem> items) {
    final query = _query.trim().toLowerCase();
    return items.where((item) {
      final matchesCategory =
          _category == PosCatalogFilters.allCategories ||
          item.category == _category;
      final matchesQuery =
          query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return item.isActive && matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = ref.watch(fakeInventoryProvider);

    final model = PosLayoutModel(
      items: _filter(items),
      categories: <String>{
        PosCatalogFilters.allCategories,
        for (final item in items) item.category,
      }.toList(),
      selectedCategory: _category,
      searchController: _searchController,
      lines: _cart.values.toList(),
      subtotalSenti: _subtotalSenti,
      saleDiscountSenti: _saleDiscountSenti,
      taxSenti: _taxSenti,
      totalSenti: _totalSenti,
      cartQuantity: _cartQuantity,
      onSearchChanged: (value) => setState(() => _query = value),
      onCategoryChanged: (value) => setState(() => _category = value),
      onItemSelected: _addItem,
      onQuantityChanged: _setQuantity,
      onLineRemoved: _removeLine,
      onLineDiscountChanged: _setLineDiscount,
      onSaleDiscountChanged: _setSaleDiscount,
      onClearCart: _clearCart,
      onCompleteSale: _completeSale,
      onOpenSalesHistory: () => context.go(AppRoutes.posSales),
    );

    if (context.isDesktop) return PosDesktopLayout(model: model);
    if (context.isTablet) return PosTabletLayout(model: model);
    return PosMobileLayout(model: model);
  }
}
