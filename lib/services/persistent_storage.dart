import 'persistent_storage_stub.dart'
    if (dart.library.js_interop) 'persistent_storage_web.dart' as impl;

/// Asks the browser to mark this origin's storage as persistent so it
/// won't be evicted under cache pressure or by routine "clear cache" actions.
/// Returns true when persistence is granted (or already granted), false
/// otherwise. No-op on non-web platforms, which already have durable storage.
Future<bool> requestPersistentStorage() => impl.requestPersistentStorage();
