import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/tracker_kind.dart';

/// Persisted home-page layout: which trackers are shown and in what order.
///
/// Mirrors the `ChangeNotifier` + `SharedPreferences` shape of `EventStore`
/// and `LocaleProvider`. Access in the widget tree via [HomeConfigScope].
class HomeConfig extends ChangeNotifier {
  static const _storageKey = 'babytrack.homeconfig.v1';
  static const _dayStartKey = 'babytrack.daystarthour.v1';

  List<TrackerSetting> _order = _defaultOrder();

  /// Hour (0–23) at which a tracking day rolls over for stats and history.
  /// 0 = midnight (default); e.g. 6 means a day runs 06:00 → next 06:00.
  int _dayStartHour = 0;
  int get dayStartHour => _dayStartHour;

  static List<TrackerSetting> _defaultOrder() =>
      [for (final k in TrackerKind.values) TrackerSetting(kind: k)];

  /// Full ordered list including disabled trackers (for the editor).
  List<TrackerSetting> get order => List.unmodifiable(_order);

  /// Enabled trackers in the user's custom display order (for the home page).
  List<TrackerKind> get enabledInOrder =>
      [for (final s in _order) if (s.enabled) s.kind];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_dayStartKey);
    if (hour != null && hour >= 0 && hour <= 23) _dayStartHour = hour;
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List<dynamic>)
            .map((e) => TrackerSetting.fromJson(e as Map<String, dynamic>))
            .whereType<TrackerSetting>()
            .toList();
        _order = _withMissingAppended(list);
      } catch (_) {
        _order = _defaultOrder();
      }
    }
  }

  /// Appends any tracker kind missing from [stored] (e.g. added in a newer
  /// app version) so new trackers surface enabled rather than disappearing.
  List<TrackerSetting> _withMissingAppended(List<TrackerSetting> stored) {
    final present = stored.map((s) => s.kind).toSet();
    return [
      ...stored,
      for (final k in TrackerKind.values)
        if (!present.contains(k)) TrackerSetting(kind: k),
    ];
  }

  /// Writes the layout to local storage. The in-memory state and listeners are
  /// already updated by the caller, so a persistence failure is swallowed (and
  /// logged in debug) rather than thrown as an unhandled async error from a UI
  /// callback — the worst case is the change not surviving a restart.
  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(_order.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      debugPrint('HomeConfig: failed to persist layout: $e');
    }
  }

  Future<void> setDayStartHour(int hour) async {
    final clamped = hour.clamp(0, 23);
    if (clamped == _dayStartHour) return;
    _dayStartHour = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_dayStartKey, clamped);
    } catch (e) {
      debugPrint('HomeConfig: failed to persist day-start hour: $e');
    }
  }

  Future<void> setEnabled(TrackerKind kind, bool enabled) async {
    final idx = _order.indexWhere((s) => s.kind == kind);
    if (idx == -1) return;
    _order[idx] = _order[idx].copyWith(enabled: enabled);
    notifyListeners();
    await _persist();
  }

  /// Reads a per-tracker boolean option (e.g. diaper `trackSize`,
  /// bottle/tube `trackAmount`), falling back to [fallback] when unset.
  bool optionBool(TrackerKind kind, String key, {bool fallback = false}) {
    final idx = _order.indexWhere((s) => s.kind == kind);
    if (idx == -1) return fallback;
    final value = _order[idx].options[key];
    return value is bool ? value : fallback;
  }

  Future<void> setOption(TrackerKind kind, String key, Object value) async {
    final idx = _order.indexWhere((s) => s.kind == kind);
    if (idx == -1) return;
    final options = Map<String, dynamic>.from(_order[idx].options)
      ..[key] = value;
    _order[idx] = _order[idx].copyWith(options: options);
    notifyListeners();
    await _persist();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    // ReorderableListView reports newIndex as the insertion slot before the
    // item is removed; adjust when moving an item downward.
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _order.removeAt(oldIndex);
    _order.insert(newIndex, item);
    notifyListeners();
    await _persist();
  }
}

class HomeConfigScope extends InheritedNotifier<HomeConfig> {
  const HomeConfigScope({
    super.key,
    required HomeConfig config,
    required super.child,
  }) : super(notifier: config);

  static HomeConfig of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<HomeConfigScope>()!
        .notifier!;
  }
}
