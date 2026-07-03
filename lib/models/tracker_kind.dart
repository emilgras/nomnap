/// The tracker types that can appear on the home page.
///
/// Stored by stable [key] (never reorder/rename the keys — persisted data
/// depends on them). [TrackerKind.values] order is the default home layout.
/// `feed` is the breast-feed card; `bottle`/`tube` are the other feed types.
enum TrackerKind { sleep, feed, bottle, tube, diaper, weight, length, head }

extension TrackerKindX on TrackerKind {
  String get key {
    switch (this) {
      case TrackerKind.sleep:
        return 'sleep';
      case TrackerKind.feed:
        return 'feed';
      case TrackerKind.bottle:
        return 'bottle';
      case TrackerKind.tube:
        return 'tube';
      case TrackerKind.diaper:
        return 'diaper';
      case TrackerKind.weight:
        return 'weight';
      case TrackerKind.length:
        return 'length';
      case TrackerKind.head:
        return 'head';
    }
  }

  /// Growth measurements (weight/length/head) — logged as a single value at a
  /// point in time, unlike the count/duration trackers.
  bool get isMeasurement =>
      this == TrackerKind.weight ||
      this == TrackerKind.length ||
      this == TrackerKind.head;

  /// The category this tracker belongs to in Tilpas and the + sheet.
  TrackerGroup get group {
    switch (this) {
      case TrackerKind.feed:
      case TrackerKind.bottle:
      case TrackerKind.tube:
        return TrackerGroup.food;
      case TrackerKind.sleep:
      case TrackerKind.diaper:
        return TrackerGroup.activity;
      case TrackerKind.weight:
      case TrackerKind.length:
      case TrackerKind.head:
        return TrackerGroup.growth;
    }
  }

  static TrackerKind? fromKey(String key) {
    for (final k in TrackerKind.values) {
      if (k.key == key) return k;
    }
    return null;
  }
}

/// Categories that group the trackers in Tilpas and the + sheet, in the order
/// they are displayed (Food → Activity → Growth).
enum TrackerGroup { food, activity, growth }

/// One tracker's home-page configuration: whether it's shown and its
/// per-tracker [options]. [options] is reserved for future per-component
/// configuration (e.g. diaper size tracking) and is unused for now.
class TrackerSetting {
  final TrackerKind kind;
  final bool enabled;
  final Map<String, dynamic> options;

  const TrackerSetting({
    required this.kind,
    this.enabled = true,
    this.options = const {},
  });

  TrackerSetting copyWith({bool? enabled, Map<String, dynamic>? options}) {
    return TrackerSetting(
      kind: kind,
      enabled: enabled ?? this.enabled,
      options: options ?? this.options,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.key,
        'enabled': enabled,
        if (options.isNotEmpty) 'options': options,
      };

  /// Returns null if the stored kind key is unknown (e.g. a tracker removed
  /// in a later app version) so the caller can drop it.
  static TrackerSetting? fromJson(Map<String, dynamic> json) {
    final kind = TrackerKindX.fromKey(json['kind'] as String? ?? '');
    if (kind == null) return null;
    return TrackerSetting(
      kind: kind,
      enabled: json['enabled'] as bool? ?? true,
      options: (json['options'] as Map<String, dynamic>?) ?? const {},
    );
  }
}
