/// Fake implementation of ReordersCatalogApi for testing and demo mode.
library;

import 'reorders_catalog_api.dart';

/// Fake reorders catalog API — demo mode has no server-side purchase-order
/// list to pull; `ReordersNotifier` falls back to `MockReorders` directly
/// rather than routing through this.
class FakeReordersCatalogApi extends ReordersCatalogApi {
  final List<ReorderDto> reorders;

  FakeReordersCatalogApi({this.reorders = const []});

  @override
  Future<List<ReorderDto>> fetchReorders({required String storeId}) async => reorders;
}
