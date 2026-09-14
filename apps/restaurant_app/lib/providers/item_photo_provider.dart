/// Server-side product-photo bytes, fetched on demand with auth.
///
/// Photos live behind `inventory.view` — a raw `Image.network` cannot send
/// the bearer token, so bytes are pulled through the authenticated Dio
/// client and rendered with `Image.memory`, exactly like freshly picked
/// (not yet uploaded) photos. The provider family is keyed by the
/// server-side item id and `autoDispose`s: bytes are cached only while
/// something on screen is showing them, and a catalog refresh (new
/// `imageUrl`) naturally re-resolves through the watching widget.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'inventory_api_provider.dart';
import 'permissions_provider.dart';

/// Photo bytes for the server-side item [catalogItemId], or null when
/// there is no business context. Errors (including a 404 for a photo
/// removed since the last catalog pull) surface as an error state —
/// callers fall back to the placeholder, never to a broken image icon.
final itemPhotoBytesProvider =
    FutureProvider.autoDispose.family<Uint8List?, String>((ref, catalogItemId) async {
  final businessId = ref.watch(currentBusinessIdProvider);
  if (businessId == null) return null;
  final bytes = await ref
      .watch(inventoryApiServiceProvider)
      .fetchItemImageBytes(businessId: businessId, itemId: catalogItemId);
  return Uint8List.fromList(bytes);
});
