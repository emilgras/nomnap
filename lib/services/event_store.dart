import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/baby_event.dart';
import '../models/baby_session.dart';

class EventStore extends ChangeNotifier {
  static const _storageKey = 'babytrack.events.v1';

  final List<BabyEvent> _events = [];
  bool _loaded = false;
  final _rng = Random();

  List<BabyEvent> get events => List.unmodifiable(_events);
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _events
          ..clear()
          ..addAll(BabyEvent.decodeList(raw));
        _sort();
      } catch (_) {
        // corrupt data; start fresh
        _events.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, BabyEvent.encodeList(_events));
  }

  String _newId() {
    final ts = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final rand = _rng.nextInt(0x7FFFFFFF).toRadixString(36);
    return '$ts-$rand';
  }

  void _sort() {
    _events.sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<BabyEvent> add(EventType type, {DateTime? at, Map<String, String>? meta}) async {
    final event = BabyEvent(
      id: _newId(),
      type: type,
      timestamp: at ?? DateTime.now(),
      meta: meta,
    );
    _events.add(event);
    _sort();
    notifyListeners();
    await _persist();
    return event;
  }

  Future<void> remove(String id) async {
    _events.removeWhere((e) => e.id == id);
    notifyListeners();
    await _persist();
  }

  Future<void> update(String id, DateTime newTimestamp) async {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _events[idx] = _events[idx].copyWith(timestamp: newTimestamp);
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> updateMeta(String id, Map<String, String> meta) async {
    final idx = _events.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    _events[idx] = _events[idx].copyWith(meta: meta);
    notifyListeners();
    await _persist();
  }

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
    _events.add(BabyEvent(id: _newId(), type: startType, timestamp: start, meta: startMeta));
    _events.add(BabyEvent(id: _newId(), type: endType, timestamp: end));
    _sort();
    notifyListeners();
    await _persist();
  }

  Future<void> clearAll() async {
    _events.clear();
    notifyListeners();
    await _persist();
  }

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

  List<BabySession> get sessions => BabySession.from(_events);

  Future<void> deleteSession(BabySession session) async {
    _events.removeWhere(
      (e) => e.id == session.startEventId || e.id == session.endEventId,
    );
    notifyListeners();
    await _persist();
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

  String exportJson() => BabyEvent.encodeList(_events);

  Future<int> importJson(String json) async {
    final imported = BabyEvent.decodeList(json);
    if (imported.isEmpty) return 0;
    final existingIds = _events.map((e) => e.id).toSet();
    final newEvents = imported.where((e) => !existingIds.contains(e.id)).toList();
    if (newEvents.isEmpty) return 0;
    _events.addAll(newEvents);
    _sort();
    notifyListeners();
    await _persist();
    return newEvents.length;
  }
}
