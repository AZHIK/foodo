/// Product photography with a graceful fallback chain.
///
/// 1. Freshly picked local bytes (not yet uploaded) win — the user just
///    chose this photo and must see it immediately, even offline.
/// 2. Otherwise the server-side photo, fetched with auth (see
///    `itemPhotoBytesProvider`) — a plain `Image.network` cannot send the
///    bearer token, so this path also ends in `Image.memory`.
/// 3. Otherwise the emoji placeholder — including while the remote photo
///    is loading or when it fails (a 404 for a photo removed since the
///    last catalog pull must not flash an error icon).
///
/// Sizing/clipping stays with the caller: this renders only the content
/// (a cover-fit image or a sized emoji glyph) for whatever box it is
/// placed in.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/item_photo_provider.dart';

class ItemPhoto extends ConsumerWidget {
  const ItemPhoto({
    super.key,
    required this.emoji,
    this.emojiSize = 18,
    this.bytes,
    this.imageUrl,
    this.catalogItemId,
  });

  /// Placeholder glyph — the pre-photography stand-in, still the fallback.
  final String emoji;

  final double emojiSize;

  /// Freshly picked local photo bytes, when present.
  final Uint8List? bytes;

  /// Service-relative URL of the server-side photo, when the item has one.
  final String? imageUrl;

  /// Server-side item id the photo is fetched under. Null (demo items,
  /// unsynced rows) means there is nothing remote to fetch.
  final String? catalogItemId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = bytes;
    if (local != null) {
      return Image.memory(local, fit: BoxFit.cover);
    }
    final remoteId = catalogItemId;
    if (imageUrl == null || remoteId == null) {
      return Text(emoji, style: TextStyle(fontSize: emojiSize));
    }
    final remote = ref.watch(itemPhotoBytesProvider(remoteId));
    return remote.when(
      data: (remoteBytes) => remoteBytes == null
          ? Text(emoji, style: TextStyle(fontSize: emojiSize))
          : Image.memory(remoteBytes, fit: BoxFit.cover),
      // Loading and error both degrade to the placeholder: a photo is
      // decorative, never worth a spinner or an error glyph in a list row.
      loading: () => Text(emoji, style: TextStyle(fontSize: emojiSize)),
      error: (_, _) => Text(emoji, style: TextStyle(fontSize: emojiSize)),
    );
  }
}
