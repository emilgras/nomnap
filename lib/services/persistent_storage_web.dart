import 'dart:js_interop';

@JS('navigator')
external _Navigator get _navigator;

extension type _Navigator._(JSObject _) implements JSObject {
  external _StorageManager? get storage;
}

extension type _StorageManager._(JSObject _) implements JSObject {
  external JSPromise<JSBoolean> persist();
  external JSPromise<JSBoolean> persisted();
}

Future<bool> requestPersistentStorage() async {
  try {
    final storage = _navigator.storage;
    if (storage == null) return false;
    final already = (await storage.persisted().toDart).toDart;
    if (already) return true;
    final granted = (await storage.persist().toDart).toDart;
    return granted;
  } catch (_) {
    return false;
  }
}
