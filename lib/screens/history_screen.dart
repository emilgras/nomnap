import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../models/baby_session.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import 'tracker_screen.dart' show SessionRow;

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

  Map<DateTime, List<BabySession>> _groupByDay(List<BabySession> sessions) {
    final map = <DateTime, List<BabySession>>{};
    for (final s in sessions) {
      final k = DateTime(s.start.year, s.start.month, s.start.day);
      map.putIfAbsent(k, () => []).add(s);
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

  Future<DateTime?> _pickTime({
    required String title,
    required DateTime initial,
    DateTime? min,
    DateTime? max,
  }) async {
    DateTime working = initial;
    final saved = await showCupertinoModalPopup<bool>(
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
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel'),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(title, style: AppText.headline),
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(ctx, true),
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
                    initialDateTime: initial,
                    minimumDate: min,
                    maximumDate:
                        max ?? DateTime.now().add(const Duration(minutes: 1)),
                    use24hFormat: true,
                    onDateTimeChanged: (v) => working = v,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (saved == true) return working;
    return null;
  }

  Future<void> _editStart(BabySession session) async {
    final picked = await _pickTime(
      title: 'Edit start',
      initial: session.start,
      max: session.end ?? DateTime.now(),
    );
    if (picked != null) {
      await widget.store.editSession(session, newStart: picked);
    }
  }

  Future<void> _editEnd(BabySession session) async {
    if (session.endEventId == null) return;
    final picked = await _pickTime(
      title: 'Edit end',
      initial: session.end!,
      min: session.start,
    );
    if (picked != null) {
      await widget.store.editSession(session, newEnd: picked);
    }
  }

  Future<void> _endNow(BabySession session) async {
    await widget.store.endOngoingSession(session);
  }

  Future<void> _confirmDelete(BabySession session) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('Delete this session?'),
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
      await widget.store.deleteSession(session);
    }
  }

  void _openRowMenu(BabySession session) {
    final kindLabel =
        session.kind == SessionKind.sleep ? 'Sleep' : 'Feed';
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(
          '$kindLabel · ${DateFormat('EEE, MMM d').format(session.start)}',
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _editStart(session);
            },
            child: const Text('Edit start time'),
          ),
          if (session.endEventId != null)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _editEnd(session);
              },
              child: const Text('Edit end time'),
            ),
          if (session.isOngoing)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _endNow(session);
              },
              child: const Text('End now'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(ctx);
              _confirmDelete(session);
            },
            child: const Text('Delete session'),
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
    final sessions = widget.store.sessions.reversed.toList();
    final grouped = _groupByDay(sessions);
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
            trailing: sessions.isEmpty
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
          if (sessions.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: Text(
                    'Your tracked sessions will appear here.',
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
                    final daySessions = grouped[day]!;
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
                                for (var i = 0; i < daySessions.length; i++) ...[
                                  SessionRow(
                                    session: daySessions[i],
                                    onTap: () => _openRowMenu(daySessions[i]),
                                  ),
                                  if (i < daySessions.length - 1)
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
