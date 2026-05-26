import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../models/baby_event.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';

class HistoryScreen extends StatefulWidget {
  final EventStore store;
  const HistoryScreen({super.key, required this.store});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.store.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() => setState(() {});

  Map<DateTime, List<BabyEvent>> _groupByDay(List<BabyEvent> events) {
    final map = <DateTime, List<BabyEvent>>{};
    for (final e in events) {
      final k = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      map.putIfAbsent(k, () => []).add(e);
    }
    return map;
  }

  Future<void> _confirmClear() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Clear all data?'),
        content: const Text(
          'This will permanently delete every tracked sleep and feed. This cannot be undone.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete all'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.clearAll();
    }
  }

  Future<void> _editEvent(BabyEvent event) async {
    DateTime selected = event.timestamp;
    final action = await showCupertinoModalPopup<_EditAction>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 320,
          color: AppColors.surface,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () =>
                            Navigator.pop(ctx, _EditAction.cancel),
                        child: const Text('Cancel'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text('Edit time', style: AppText.headline),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(ctx, _EditAction.save),
                        child: Text(
                          'Save',
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
                    initialDateTime: event.timestamp,
                    maximumDate: DateTime.now().add(const Duration(minutes: 1)),
                    use24hFormat: true,
                    onDateTimeChanged: (v) => selected = v,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (action == _EditAction.save) {
      await widget.store.update(event.id, selected);
    }
  }

  Future<void> _confirmDelete(BabyEvent event) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete entry?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.remove(event.id);
    }
  }

  void _openRowMenu(BabyEvent event) {
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          DateFormat('EEE, MMM d  HH:mm').format(event.timestamp),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _editEvent(event);
            },
            child: const Text('Edit time'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(event);
            },
            child: const Text('Delete'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final events = widget.store.events.reversed.toList();
    final grouped = _groupByDay(events);
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('History'),
            backgroundColor: AppColors.background,
            border: null,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(10),
              child: SizedBox.shrink(),
            ),
            trailing: events.isEmpty
                ? null
                : CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _confirmClear,
                    child: const Icon(
                      CupertinoIcons.trash,
                      color: AppColors.danger,
                      size: 22,
                    ),
                  ),
          ),
          if (events.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: Text(
                    'Your tracked events will appear here.',
                    textAlign: TextAlign.center,
                    style: AppText.subhead,
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                16,
                4,
                16,
                MediaQuery.of(context).padding.bottom + 24,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final day = days[idx];
                    final dayEvents = grouped[day]!;
                    return Padding(
                      padding: EdgeInsets.only(top: idx == 0 ? 0 : 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(formatDayHeader(day)),
                          SectionCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (var i = 0; i < dayEvents.length; i++) ...[
                                  _HistoryRow(
                                    event: dayEvents[i],
                                    onTap: () => _openRowMenu(dayEvents[i]),
                                  ),
                                  if (i < dayEvents.length - 1)
                                    Container(
                                      margin: const EdgeInsets.only(left: 60),
                                      height: 0.5,
                                      color: AppColors.divider,
                                    ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: days.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _EditAction { cancel, save }

class _HistoryRow extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback onTap;
  const _HistoryRow({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSleep = event.type == EventType.sleepStart ||
        event.type == EventType.sleepEnd;
    final accent = isSleep ? AppColors.sleepAccent : AppColors.feedAccent;
    final softBg = isSleep ? AppColors.sleepSoft : AppColors.feedSoft;
    final icon = isSleep ? CupertinoIcons.moon_fill : CupertinoIcons.drop_fill;
    String label;
    switch (event.type) {
      case EventType.sleepStart:
        label = 'Sleep started';
        break;
      case EventType.sleepEnd:
        label = 'Sleep ended';
        break;
      case EventType.feedStart:
        label = 'Feed started';
        break;
      case EventType.feedEnd:
        label = 'Feed ended';
        break;
    }
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: softBg,
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppText.callout),
            ),
            Text(
              formatClock(event.timestamp),
              style: AppText.subhead.copyWith(
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
