/// Pulls a human-readable message out of a Dio error body, whatever shape
/// the backend (or a proxy, or a 500 plain-text page) gave it.
///
/// FastAPI answers `{"detail": "..."}` for HTTPExceptions and
/// `{"detail": [...]}` for validation errors; Starlette's unhandled-500
/// page is a bare string. Indexing `data?['detail']` directly crashes on
/// the latter two shapes (`String` is not a subtype of `int`), which is
/// why this helper exists — every error snackbar should read through it.
String errorDetail(Object? data, {required String fallback}) {
  if (data == null) return fallback;
  if (data is String) return data.trim().isEmpty ? fallback : data;
  if (data is List) {
    final parts = [
      for (final entry in data) _entryText(entry),
    ].where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? fallback : parts.join('\n');
  }
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String && detail.trim().isNotEmpty) return detail;
    if (detail is List) return errorDetail(detail, fallback: fallback);
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
  }
  return fallback;
}

String _entryText(Object? entry) {
  if (entry is String) return entry;
  if (entry is Map) {
    final msg = entry['msg'];
    if (msg is String) {
      final loc = entry['loc'];
      final where = loc is List && loc.isNotEmpty ? '${loc.last}: ' : '';
      return '$where$msg';
    }
  }
  return '';
}
