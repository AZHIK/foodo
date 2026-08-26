import 'package:flutter/foundation.dart';

/// Web downloads through the browser; there is no OS save dialog to offer.
bool get supportsSaveDialog => false;

/// Web has no file system to share from.
bool get sharesAfterSave => false;

/// Never called: [supportsSaveDialog] is false on this platform.
Future<String?> pickSaveLocation({
  required String suggestedName,
  required String extension,
  required String typeLabel,
}) async => null;

/// Never called: [supportsSaveDialog] is false on this platform.
Future<void> writeBytesTo(String path, Uint8List bytes) async {}

/// Returns null: this build has no `dart:io`, so there is nowhere to write.
///
/// The caller turns that into a friendly message rather than an exception —
/// a report button must never take the app down on an unsupported target.
Future<String?> writeExportFile(Uint8List bytes, String fileName) async => null;
