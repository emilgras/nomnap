import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/baby_event.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';

enum _Kind { sleep, feed, diaper }

class AddEntrySheet extends StatefulWidget {
  final EventStore store;
  const AddEntrySheet({super.key, required this.store});

  /// Smart defaults: type = most recent kind logged (else sleep);
  /// start = 1 hour ago, end = now.
  static Future<void> show(BuildContext context, EventStore store) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => AddEntrySheet(store: store),
    );
  }

  @override
  State<AddEntrySheet> createState() => _AddEntrySheetState();
}

class _AddEntrySheetState extends State<AddEntrySheet> {
  late _Kind _kind;
  late DateTime _start;
  late DateTime _end;
  bool _ongoing = false;
  bool _saving = false;
  String? _error;
  bool _isPoop = false;
  String _feedSide = 'L';

  @override
  void initState() {
    super.initState();
    _kind = _inferKind();
    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(hours: 1));
  }

  _Kind _inferKind() {
    for (var i = widget.store.events.length - 1; i >= 0; i--) {
      final t = widget.store.events[i].type;
      if (t == EventType.sleepStart || t == EventType.sleepEnd) {
        return _Kind.sleep;
      }
      if (t == EventType.feedStart || t == EventType.feedEnd) {
        return _Kind.feed;
      }
      if (t.isDiaper) return _Kind.diaper;
    }
    return _Kind.sleep;
  }

  bool get _kindAlreadyOngoing => _kind == _Kind.sleep
      ? widget.store.isSleeping
      : widget.store.isFeeding;

  Future<void> _save() async {
    final s = S.of(context);
    if (_kind == _Kind.diaper) {
      if (_start.isAfter(DateTime.now())) {
        setState(() => _error = s.errorTimeFuture);
        return;
      }
      setState(() {
        _saving = true;
        _error = null;
      });
      HapticFeedback.mediumImpact();
      final type = _isPoop ? EventType.diaperPoop : EventType.diaperPee;
      await widget.store.add(type, at: _start);
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (_ongoing) {
      if (_kindAlreadyOngoing) {
        setState(() => _error =
            _kind == _Kind.sleep ? s.sleepAlreadyInProgress : s.feedAlreadyInProgress);
        return;
      }
      if (_start.isAfter(DateTime.now())) {
        setState(() => _error = s.errorStartFuture);
        return;
      }
    } else {
      if (!_end.isAfter(_start)) {
        setState(() => _error = s.errorEndAfterStart);
        return;
      }
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final startType = _kind == _Kind.sleep
        ? EventType.sleepStart
        : EventType.feedStart;
    final feedMeta = _kind == _Kind.feed ? {'side': _feedSide} : null;
    if (_ongoing) {
      await widget.store.add(startType, at: _start, meta: feedMeta);
    } else {
      final endType =
          _kind == _Kind.sleep ? EventType.sleepEnd : EventType.feedEnd;
      await widget.store.addSession(
        startType: startType,
        endType: endType,
        start: _start,
        end: _end,
        startMeta: feedMeta,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _pickTime({required bool isStart}) {
    final s = S.of(context);
    final initial = isStart ? _start : _end;
    DateTime working = initial;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Container(
        height: 300,
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(s.cancel),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          isStart ? s.startTime : s.endTime,
                          style: AppText.headline,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        setState(() {
                          if (isStart) {
                            _start = working;
                          } else {
                            _end = working;
                          }
                          _error = null;
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        s.done,
                        style: AppText.headline.copyWith(
                          color: AppColors.sleepAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.dateAndTime,
                  initialDateTime: initial,
                  maximumDate: DateTime.now().add(const Duration(minutes: 1)),
                  use24hFormat: true,
                  onDateTimeChanged: (v) => working = v,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final accent = _kind == _Kind.sleep
        ? AppColors.sleepAccent
        : _kind == _Kind.feed
            ? AppColors.feedAccent
            : AppColors.diaperAccent;
    final duration = _end.isAfter(_start)
        ? _end.difference(_start)
        : Duration.zero;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(s.cancel),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(s.addEntry, style: AppText.headline),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _saving ? null : _save,
                      child: Text(
                        s.save,
                        style: AppText.headline.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              CupertinoSlidingSegmentedControl<_Kind>(
                groupValue: _kind,
                onValueChanged: (v) {
                  if (v != null) setState(() => _kind = v);
                },
                thumbColor: AppColors.surface,
                backgroundColor: AppColors.divider.withValues(alpha: 0.6),
                children: {
                  _Kind.sleep: _SegmentLabel(
                    icon: CupertinoIcons.moon_fill,
                    text: s.sleep,
                    selected: _kind == _Kind.sleep,
                    accent: AppColors.sleepAccent,
                  ),
                  _Kind.feed: _SegmentLabel(
                    icon: CupertinoIcons.drop_fill,
                    text: s.feed,
                    selected: _kind == _Kind.feed,
                    accent: AppColors.feedAccent,
                  ),
                  _Kind.diaper: _SegmentLabel(
                    icon: CupertinoIcons.tornado,
                    text: s.diaper,
                    selected: _kind == _Kind.diaper,
                    accent: AppColors.diaperAccent,
                  ),
                },
              ),
              const SizedBox(height: 16),
              if (_kind == _Kind.feed) ...[
                CupertinoSlidingSegmentedControl<String>(
                  groupValue: _feedSide,
                  onValueChanged: (v) {
                    if (v != null) setState(() => _feedSide = v);
                  },
                  thumbColor: AppColors.surface,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.6),
                  children: {
                    'L': _SegmentLabel(
                      icon: CupertinoIcons.arrow_left,
                      text: s.left,
                      selected: _feedSide == 'L',
                      accent: AppColors.feedAccent,
                    ),
                    'R': _SegmentLabel(
                      icon: CupertinoIcons.arrow_right,
                      text: s.right,
                      selected: _feedSide == 'R',
                      accent: AppColors.feedAccent,
                    ),
                  },
                ),
                const SizedBox(height: 10),
              ],
              if (_kind == _Kind.diaper) ...[
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _isPoop,
                  onValueChanged: (v) {
                    if (v != null) setState(() => _isPoop = v);
                  },
                  thumbColor: AppColors.surface,
                  backgroundColor: AppColors.divider.withValues(alpha: 0.6),
                  children: {
                    false: _SegmentLabel(
                      icon: CupertinoIcons.drop,
                      text: s.pee,
                      selected: !_isPoop,
                      accent: AppColors.diaperAccent,
                    ),
                    true: _SegmentLabel(
                      icon: CupertinoIcons.circle_fill,
                      text: s.poop,
                      selected: _isPoop,
                      accent: AppColors.diaperAccent,
                    ),
                  },
                ),
                const SizedBox(height: 10),
                _TimeRow(
                  label: s.time,
                  value: s.formatStamp(_start),
                  onTap: () => _pickTime(isStart: true),
                ),
              ] else ...[
                _OngoingRow(
                  value: _ongoing,
                  accent: accent,
                  onChanged: (v) => setState(() {
                    _ongoing = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 10),
                _TimeRow(
                  label: s.started,
                  value: s.formatStamp(_start),
                  onTap: () => _pickTime(isStart: true),
                ),
                if (!_ongoing) ...[
                  const SizedBox(height: 10),
                  _TimeRow(
                    label: s.ended,
                    value: s.formatStamp(_end),
                    onTap: () => _pickTime(isStart: false),
                  ),
                ],
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    _ongoing
                        ? s.inProgress
                        : s.durationLabel(formatDuration(duration)),
                    style: AppText.subhead.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    _error!,
                    style: AppText.footnote.copyWith(color: AppColors.danger),
                  ),
                ),
              ],
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

}

class _SegmentLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool selected;
  final Color accent;
  const _SegmentLabel({
    required this.icon,
    required this.text,
    required this.selected,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: selected ? accent : AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppText.callout.copyWith(
              color: selected ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OngoingRow extends StatelessWidget {
  final bool value;
  final Color accent;
  final ValueChanged<bool> onChanged;
  const _OngoingRow({
    required this.value,
    required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Row(
        children: [
          Text(S.of(context).stillInProgress, style: AppText.callout),
          const Spacer(),
          CupertinoSwitch(
            value: value,
            activeTrackColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _TimeRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  const _TimeRow({
    required this.label,
    required this.value,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Row(
          children: [
            Text(label, style: AppText.callout),
            const Spacer(),
            Text(
              value,
              style: AppText.callout.copyWith(
                color: AppColors.textSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
