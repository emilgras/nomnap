import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Writes [content] to a temporary file and opens the system share sheet so the
/// user can save it to Files / Drive / send it elsewhere. On mobile there is no
/// silent "downloads" folder, so sharing is the idiomatic way to hand a file to
/// the user.
///
/// [sharePositionOrigin] anchors the share popover on iPad; it is required there
/// to avoid an assertion and ignored on other platforms.
Future<void> downloadFile(
  String filename,
  String content, {
  Rect? sharePositionOrigin,
}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.writeAsString(content);
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/json', name: filename)],
    subject: filename,
    sharePositionOrigin: sharePositionOrigin,
  );
}

/// Opens the system file picker for a JSON file and returns its text contents,
/// or null if the user cancels.
Future<String?> pickAndReadFile() async {
  final result = await FilePicker.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json'],
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  final bytes = picked.bytes;
  if (bytes != null) return utf8.decode(bytes);

  // Fall back to reading from the path if bytes weren't loaded.
  final path = picked.path;
  if (path != null) return File(path).readAsString();

  return null;
}
