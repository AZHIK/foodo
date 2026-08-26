/// Platform-specific file writing for exports.
///
/// Conditional export so `dart:io` is never referenced on web, where it does
/// not exist and would break the build outright.
library;

export 'file_sink_stub.dart' if (dart.library.io) 'file_sink_io.dart';
