/// Raised when a platform claims to support a native save dialog but the
/// plugin behind it is not actually reachable — a stale plugin registration,
/// or a headless/test process with no platform channels.
///
/// Its own type so the export can quietly fall back to choosing a location
/// itself, instead of surfacing a plugin error to someone who just wanted a
/// spreadsheet.
class SaveDialogUnavailable implements Exception {
  const SaveDialogUnavailable();

  @override
  String toString() => 'SaveDialogUnavailable';
}
