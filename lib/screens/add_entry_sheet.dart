import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/baby_event.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';

enum _Kind { sleep, feed }

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
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _kind = _inferKind();
    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(hours: 1));
  }

  _Kind _inferKind() {
    // Default to whichever kind was last logged.
    for (var i = widget.store.events.length - 1; i >= 0; i--) {
      final t = widget.store.events[i].type;
      if (t == EventType.sleepStart || t == EventType.sleepEnd) {
        return _Kind.sleep;
      }
      if (t == EventType.feedStart || t == EventType.feedEnd) {
        return _Kind.feed;
      }
    }
    return _Kind.sleep;
  }

  Future<void> _save() async {
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End must be after start.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    HapticFeedback.mediumImpact();
    final startType = _kind == _Kind.sleep
        ? EventType.sleepStart
        : EventType.feedStart;
    final endType =
        _kind == _Kind.sleep ? EventType.sleepEnd : EventType.feedEnd;
    await widget.store.addSession(
      startType: startType,
      endType: endType,
      start: _start,
      end: _end,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _pickTime({required bool isStart}) {
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
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          isStart ? 'Start time' : 'End time',
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
                        'Done',
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
    final accent = _kind == _Kind.sleep
        ? AppColors.sleepAccent
        : AppColors.feedAccent;
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
                      child: const Text('Cancel'),
                    ),
                    Expanded(
                      child: Center(
                        child: Text('Add entry', style: AppText.headline),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _saving ? null : _save,
                      child: Text(
                        'Save',
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
                    text: 'Sleep',
                    selected: _kind == _Kind.sleep,
                    accent: AppColors.sleepAccent,
                  ),
                  _Kind.feed: _SegmentLabel(
                    icon: CupertinoIcons.drop_fill,
                    text: 'Feed',
                    selected: _kind == _Kind.feed,
                    accent: AppColors.feedAccent,
                  ),
                },
              ),
              const SizedBox(height: 20),
              _TimeRow(
                label: 'Started',
                value: _formatStamp(_start),
                onTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 10),
              _TimeRow(
                label: 'Ended',
                value: _formatStamp(_end),
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Duration  ${formatDuration(duration)}',
                  style: AppText.subhead.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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

  String _formatStamp(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dd = DateTime(t.year, t.month, t.day);
    final diff = today.difference(dd).inDays;
    String prefix;
    if (diff == 0) {
      prefix = 'Today';
    } else if (diff == 1) {
      prefix = 'Yesterday';
    } else {
      prefix = DateFormat('EEE, MMM d').format(t);
    }
    return '$prefix  ${DateFormat('HH:mm').format(t)}';
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
