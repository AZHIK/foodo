import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

import 'export_exceptions.dart';

/// True where the OS offers a native "Save as" dialog worth showing.
///
/// Phones do not: Android and iOS expose a share/"Save to Files" sheet
/// instead, which is handled after the write rather than before it.
bool get supportsSaveDialog =>
    Platform.isLinux || Platform.isWindows || Platform.isMacOS;

/// True where a saved file is not reachable through a file manager, so the OS
/// share sheet is the only way the user can actually get at it.
bool get sharesAfterSave => Platform.isAndroid || Platform.isIOS;

/// Asks the user where to put the file.
///
/// Returns the chosen path, or null if they cancelled — a cancel is a normal
/// outcome, not a failure, and the caller reports it as such.
Future<String?> pickSaveLocation({
  required String suggestedName,
  required String extension,
  required String typeLabel,
}) async {
  final FileSaveLocation? location;
  try {
    location = await getSaveLocation(
      suggestedName: suggestedName,
      confirmButtonText: 'Export',
      acceptedTypeGroups: [
        XTypeGroup(label: typeLabel, extensions: [extension]),
      ],
      // Opens where a user expects to put a report, when the platform can
      // tell us where that is.
      initialDirectory: await _defaultDirectory(),
    );
  } catch (error) {
    // Any failure to reach the dialog — an unregistered plugin, an
    // uninitialised binding, a platform quirk — means falling back to
    // choosing a location ourselves. Losing the export because the *picker*
    // misbehaved would be a much worse outcome than saving it somewhere
    // predictable and saying where.
    debugPrint('Export: save dialog unavailable ($error)');
    throw const SaveDialogUnavailable();
  }

  if (location == null) return null;

  // Some desktop dialogs return the name without the extension when the user
  // types their own; make sure the file is still openable by double-click.
  return location.path.toLowerCase().endsWith('.$extension')
      ? location.path
      : '${location.path}.$extension';
}

/// Writes [bytes] to an exact path the caller already chose.
Future<void> writeBytesTo(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

/// Writes [bytes] to a directory this code picks — the path used on phones,
/// and the fallback if a save dialog is unavailable.
///
/// The directory is chosen by cascade rather than by a single call, because
/// every individual option can fail on a real machine:
///
///  * a platform's path_provider implementation may not have registered at
///    all — the exact failure that made exports report
///    "only available on macOS" on Linux;
///  * XDG may have no DOCUMENTS entry, or the folder may not exist;
///  * documents and temp both need a working plugin registration.
///
/// `Directory.systemTemp` needs no plugin at all, so the last step always
/// succeeds. An export should degrade to a less convenient location, never
/// fail outright.
Future<String?> writeExportFile(Uint8List bytes, String fileName) async {
  final directory = await _targetDirectory();
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}

Future<String?> _defaultDirectory() async => (await _documentsDirectory())?.path;

/// The device's Documents folder — where the save dialog opens and where an
/// automatic save lands.
///
/// `getApplicationDocumentsDirectory` is the right answer on Android and iOS,
/// where it *is* the app's documents folder. On desktop it is not: it returns
/// app-private storage (`~/.local/share/<app>` on Linux, roaming AppData on
/// Windows), which no one would think to look in for a report. So desktop
/// resolves the user's real Documents folder instead.
Future<Directory?> _documentsDirectory() async {
  if (Platform.isAndroid || Platform.isIOS) {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (_) {
      return null;
    }
  }

  if (Platform.isLinux) {
    // Honours a relocated or localised Documents folder, which guessing
    // "$HOME/Documents" would miss.
    try {
      final xdgDocuments = xdg.getUserDirectory('DOCUMENTS');
      if (xdgDocuments != null && await xdgDocuments.exists()) {
        return xdgDocuments;
      }
    } catch (_) {
      // Fall through to the home-relative guess below.
    }
  }

  final home =
      Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
  if (home == null) return null;

  final documents = Directory('$home${Platform.pathSeparator}Documents');
  return await documents.exists() ? documents : null;
}

Future<Directory> _targetDirectory() async {
  final probes = <Future<Directory?> Function()>[
    // Documents first: the folder the user asked exports to default to.
    _documentsDirectory,
    getApplicationDocumentsDirectory,
    getTemporaryDirectory,
  ];

  for (final probe in probes) {
    try {
      final directory = await probe();
      if (directory != null && await directory.exists()) return directory;
    } catch (_) {
      // Try the next option — a missing or unsupported plugin implementation
      // is exactly what this cascade exists to absorb.
      continue;
    }
  }

  return Directory.systemTemp;
}
