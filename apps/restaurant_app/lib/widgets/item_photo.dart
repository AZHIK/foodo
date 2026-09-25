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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../theme/breakpoints.dart';
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
    final colors = context.colors;
    final local = bytes;
    if (local != null) {
      return Image.memory(local, fit: BoxFit.cover);
    }
    final remoteId = catalogItemId;
    if (imageUrl == null || remoteId == null) {
      return _Placeholder(emojiSize: emojiSize, colors: colors);
    }
    final remote = ref.watch(itemPhotoBytesProvider(remoteId));
    return remote.when(
      data: (remoteBytes) => remoteBytes == null
          ? _Placeholder(emojiSize: emojiSize, colors: colors)
          : Image.memory(remoteBytes, fit: BoxFit.cover),
      // Loading and error both degrade to the placeholder: a photo is
      // decorative, never worth a spinner or an error glyph in a list row.
      loading: () => _Placeholder(emojiSize: emojiSize, colors: colors),
      error: (_, _) => _Placeholder(emojiSize: emojiSize, colors: colors),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.emojiSize, required this.colors});

  final double emojiSize;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final bright = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(
        color: bright == Brightness.light
            ? Colors.grey.shade100
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(Radii.sm),
      ),
      alignment: Alignment.center,
      child: Icon(
        CupertinoIcons.photo,
        size: emojiSize,
        color: bright == Brightness.light
            ? Colors.grey.shade500
            : Colors.grey.shade400,
      ),
    );
  }
}
