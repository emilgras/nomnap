import 'dart:io';
import 'dart:ui';

import 'package:file_selector/file_selector.dart';
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
  const typeGroup = XTypeGroup(
    label: 'JSON',
    extensions: ['json'],
    mimeTypes: ['application/json'],
    uniformTypeIdentifiers: ['public.json'],
  );
  final file = await openFile(acceptedTypeGroups: [typeGroup]);
  if (file == null) return null;
  return file.readAsString();
}
