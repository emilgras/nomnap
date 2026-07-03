import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_event.dart';
import '../models/baby_session.dart';

/// Backs the baby's events onto Firestore at households/{hid}/events.
///
/// The public API is unchanged from the old shared_preferences version, so
/// screens don't care where data lives. Firestore's offline cache makes reads
/// and writes work without a connection and sync automatically; the realtime
/// listener keeps every caregiver's device in step. The in-memory [_events]
/// list is the read model and is mutated *only* by the snapshot listener, so
/// there is a single source of truth.
class EventStore extends ChangeNotifier {
  EventStore(this._col);

  final CollectionReference<Map<String, dynamic>> _col;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  final _rng = Random();

  final List<BabyEvent> _events = [];
  bool _loaded = false;

  List<BabyEvent> get events => List.unmodifiable(_events);
  bool get loaded => _loaded;

  /// Starts the realtime listener and resolves once the first snapshot (from
  /// cache or server) has populated the list.
  Future<void> load() async {
    final firstSnapshot = Completer<void>();
    void settle() {
      _loaded = true;
      notifyListeners();
      if (!firstSnapshot.isCompleted) firstSnapshot.complete();
    }

    _sub = _col.snapshots().listen(
      (snap) {
        _events
          ..clear()
          ..addAll(snap.docs.map(_fromDoc).whereType<BabyEvent>());
        _sort();
        settle();
      },
      onError: (_) => settle(), // don't block startup on a transient error
    );
    return firstSnapshot.future;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// Maps a Firestore doc to a [BabyEvent], or null if it can't be parsed
  /// (unknown type from a newer client, malformed timestamp). Returning null
  /// keeps one bad document from breaking the entire snapshot for everyone.
  BabyEvent? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      final type = EventTypeX.fromIdOrNull(data['type'] as String?);
      if (type == null) return null;
      final ts = data['ts'];
      final timestamp = ts is Timestamp
          ? ts.toDate().toLocal()
          : DateTime.parse(ts as String).toLocal();
      return BabyEvent(
        id: doc.id,
        type: type,
        timestamp: timestamp,
        meta: (data['meta'] as Map<String, dynamic>?)
            ?.map((k, v) => MapEntry(k, v as String)),
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _toDoc(BabyEvent e) => {
        'type': e.type.id,
        'ts': Timestamp.fromDate(e.timestamp.toUtc()),
        if (e.meta != null && e.meta!.isNotEmpty) 'meta': e.meta,
      };

  String _newId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _rng.nextInt(0x7FFFFFFF).toRadixString(36);
    return '$ts-$rand';
  }

  void _sort() {
    _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  /// Commits writes/deletes in chunks under Firestore's 500-op batch limit.
  Future<void> _runBatched<T>(
    List<T> items,
    void Function(WriteBatch batch, T item) op,
  ) async {
    const chunk = 450;
    for (var i = 0; i < items.length; i += chunk) {
      final batch = _col.firestore.batch();
      for (final item in items.sublist(i, min(i + chunk, items.length))) {
        op(batch, item);
      }
      await batch.commit();
    }
  }

  Future<BabyEvent> add(EventType type,
      {DateTime? at, Map<String, String>? meta}) async {
    final event = BabyEvent(
      id: _newId(),
      type: type,
      timestamp: at ?? DateTime.now(),
      meta: meta,
    );
    await _col.doc(event.id).set(_toDoc(event));
    return event;
  }

  Future<void> remove(String id) => _col.doc(id).delete();

  Future<void> update(String id, DateTime newTimestamp) =>
      _col.doc(id).update({'ts': Timestamp.fromDate(newTimestamp.toUtc())});

  Future<void> updateMeta(String id, Map<String, String> meta) =>
      _col.doc(id).update({'meta': meta});

  /// Add a completed session (used by manual entry).
  /// Creates a start + end event pair atomically.
  Future<void> addSession({
    required EventType startType,
    required EventType endType,
    required DateTime start,
    required DateTime end,
    Map<String, String>? startMeta,
  }) async {
    if (!end.isAfter(start)) {
      throw ArgumentError('End must be after start');
    }
    final startEvent = BabyEvent(
        id: _newId(), type: startType, timestamp: start, meta: startMeta);
    final endEvent = BabyEvent(id: _newId(), type: endType, timestamp: end);
    final batch = _col.firestore.batch();
    batch.set(_col.doc(startEvent.id), _toDoc(startEvent));
    batch.set(_col.doc(endEvent.id), _toDoc(endEvent));
    await batch.commit();
  }

  Future<void> clearAll() =>
      _runBatched(_events.toList(), (b, e) => b.delete(_col.doc(e.id)));

  /// Returns the most recent event of a given type, or null if none.
  BabyEvent? lastOf(EventType type) {
    for (var i = _events.length - 1; i >= 0; i--) {
      if (_events[i].type == type) return _events[i];
    }
    return null;
  }

  /// Is the baby currently sleeping?
  bool get isSleeping {
    final lastStart = lastOf(EventType.sleepStart);
    final lastEnd = lastOf(EventType.sleepEnd);
    if (lastStart == null) return false;
    if (lastEnd == null) return true;
    return lastStart.timestamp.isAfter(lastEnd.timestamp);
  }

  /// Is the baby currently feeding?
  bool get isFeeding {
    final lastStart = lastOf(EventType.feedStart);
    final lastEnd = lastOf(EventType.feedEnd);
    if (lastStart == null) return false;
    if (lastEnd == null) return true;
    return lastStart.timestamp.isAfter(lastEnd.timestamp);
  }

  DateTime? get sleepStartedAt =>
      isSleeping ? lastOf(EventType.sleepStart)?.timestamp : null;

  DateTime? get feedStartedAt =>
      isFeeding ? lastOf(EventType.feedStart)?.timestamp : null;

  String? get feedSide {
    if (!isFeeding) return null;
    return lastOf(EventType.feedStart)?.meta?['side'];
  }

  List<BabyEvent> get diaperEvents =>
      _events.where((e) => e.type.isDiaper).toList();

  /// All point-in-time events (diaper + bottle/tube feeds) for the timeline.
  List<BabyEvent> get pointEvents =>
      _events.where((e) => e.type.isPointEvent).toList();

  List<BabySession> get sessions => BabySession.from(_events);

  Future<void> deleteSession(BabySession session) async {
    final batch = _col.firestore.batch();
    batch.delete(_col.doc(session.startEventId));
    if (session.endEventId != null) {
      batch.delete(_col.doc(session.endEventId!));
    }
    await batch.commit();
  }

  /// Update either the start or the end of a session in place.
  /// `start` and `end` are new values; pass null to leave that side unchanged.
  /// `end` may be null only if the session is already ongoing.
  Future<void> editSession(
    BabySession session, {
    DateTime? newStart,
    DateTime? newEnd,
  }) async {
    if (newStart != null) {
      await update(session.startEventId, newStart);
    }
    if (newEnd != null && session.endEventId != null) {
      await update(session.endEventId!, newEnd);
    }
  }

  /// Append an end event to an ongoing session at the given time (defaults to now).
  Future<void> endOngoingSession(BabySession session, {DateTime? at}) async {
    if (!session.isOngoing) return;
    await add(session.kind.endType, at: at);
  }

  /// One-time push of events stored by the old local-only version into the
  /// household's Firestore collection. Idempotent (doc id == event id) and
  /// gated by a flag so deleting a synced event won't resurrect it.
  static Future<void> migrateLegacyLocalEvents(
    CollectionReference<Map<String, dynamic>> col,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    const migratedFlag = 'nomnap.migrated.v1';
    const legacyKey = 'babytrack.events.v1';
    if (prefs.getBool(migratedFlag) == true) return;

    final raw = prefs.getString(legacyKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final events = BabyEvent.decodeList(raw);
        const chunk = 450;
        for (var i = 0; i < events.length; i += chunk) {
          final batch = col.firestore.batch();
          for (final e in events.sublist(i, min(i + chunk, events.length))) {
            batch.set(col.doc(e.id), {
              'type': e.type.id,
              'ts': Timestamp.fromDate(e.timestamp.toUtc()),
              if (e.meta != null && e.meta!.isNotEmpty) 'meta': e.meta,
            });
          }
          await batch.commit();
        }
      } catch (_) {
        // Corrupt legacy blob — skip, still mark migrated so we don't retry.
      }
    }
    await prefs.setBool(migratedFlag, true);
  }
}
