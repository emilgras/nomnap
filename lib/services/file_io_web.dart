import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<void> downloadFile(String filename, String content) async {
  final blob = web.Blob(
    [content.toJS].toJS,
    web.BlobPropertyBag(type: 'application/json'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = filename
    ..style.display = 'none';
  web.document.body!.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

Future<String?> pickAndReadFile() async {
  final completer = Completer<String?>();
  final input = web.document.createElement('input') as web.HTMLInputElement
    ..type = 'file'
    ..accept = '.json,application/json'
    ..style.display = 'none';

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.length == 0) {
      completer.complete(null);
      input.remove();
      return;
    }
    final reader = web.FileReader();
    reader.addEventListener('load', (web.Event e) {
      completer.complete((reader.result as JSString?)?.toDart);
      input.remove();
    }.toJS);
    reader.addEventListener('error', (web.Event e) {
      completer.complete(null);
      input.remove();
    }.toJS);
    reader.readAsText(files.item(0)!);
  });

  web.document.body!.appendChild(input);
  input.click();
  return completer.future;
}
