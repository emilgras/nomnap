import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';
import '../models/baby_event.dart';
import '../models/baby_session.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../services/statistics.dart' show dayKeyFor;
import '../theme/app_theme.dart';
import '../widgets/async_action.dart';
import '../widgets/section_card.dart';
import '../widgets/sticky_header.dart';
import '../widgets/wakeup_refresh.dart';
import 'app_shell.dart' show kFloatingNavReserve;
import 'tracker_screen.dart'
    show SessionRow, TimelineItem, buildTimeline, buildPointRow;

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

  Map<DateTime, List<TimelineItem>> _groupByDay(
      List<TimelineItem> items, int dayStartHour) {
    final map = <DateTime, List<TimelineItem>>{};
    for (final item in items) {
      final k = dayKeyFor(item.timestamp, dayStartHour);
      map.putIfAbsent(k, () => []).add(item);
    }
    return map;
  }

  Future<void> _confirmClear() async {
    final s = S.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(s.clearAllTitle),
        content: Text(s.clearAllMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.deleteAll),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await runGuarded(context, () => widget.store.clearAll(),
          errorMessage: s.errUpdate);
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
                        child: Text(S.of(context).cancel),
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
                          S.of(context).save,
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
      title: S.of(context).editStart,
      initial: session.start,
      max: session.end ?? DateTime.now(),
    );
    if (picked != null && mounted) {
      await runGuarded(
          context, () => widget.store.editSession(session, newStart: picked),
          errorMessage: S.of(context).errUpdate);
    }
  }

  Future<void> _editEnd(BabySession session) async {
    if (session.endEventId == null) return;
    final picked = await _pickTime(
      title: S.of(context).editEnd,
      initial: session.end!,
      min: session.start,
    );
    if (picked != null && mounted) {
      await runGuarded(
          context, () => widget.store.editSession(session, newEnd: picked),
          errorMessage: S.of(context).errUpdate);
    }
  }

  Future<void> _endNow(BabySession session) async {
    await runGuarded(context, () => widget.store.endOngoingSession(session),
        errorMessage: S.of(context).errUpdate);
  }

  Future<void> _confirmDelete(BabySession session) async {
    final s = S.of(context);
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(s.deleteThisSession),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await runGuarded(context, () => widget.store.deleteSession(session),
          errorMessage: s.errUpdate);
    }
  }

  Future<void> _editPointTime(BabyEvent event) async {
    final picked = await _pickTime(
      title: S.of(context).editTime,
      initial: event.timestamp,
    );
    if (picked != null && mounted) {
      await runGuarded(context, () => widget.store.update(event.id, picked),
          errorMessage: S.of(context).errUpdate);
    }
  }

  Future<void> _confirmDeletePoint(BabyEvent event) async {
    final s = S.of(context);
    final message =
        event.type.isDiaper ? s.deleteThisDiaper : s.deleteThisEntry;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await runGuarded(context, () => widget.store.remove(event.id),
          errorMessage: s.errUpdate);
    }
  }

  String _pointLabel(S s, BabyEvent event) {
    switch (event.type) {
      case EventType.diaperPee:
        return s.pee;
      case EventType.diaperPoop:
        return s.poop;
      case EventType.feedBottle:
        return s.bottle;
      case EventType.feedTube:
        return s.tube;
      default:
        return '';
    }
  }

  void _openPointMenu(BabyEvent event) {
    final s = S.of(context);
    final label = _pointLabel(s, event);
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: CupertinoActionSheet(
          title: Text(
            '$label · ${s.formatDateShort(event.timestamp)}',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _editPointTime(event);
              },
              child: Text(s.editTime),
            ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDeletePoint(event);
              },
              child: Text(s.delete),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
        ),
      ),
    );
  }

  Future<void> _switchFeedSide(BabySession session) async {
    final newSide = session.side == 'L' ? 'R' : 'L';
    await runGuarded(
        context,
        () => widget.store.updateMeta(session.startEventId, {'side': newSide}),
        errorMessage: S.of(context).errUpdate);
  }

  void _openRowMenu(BabySession session) {
    final s = S.of(context);
    final isFeed = session.kind == SessionKind.feed;
    final sl = s.sideLabel(session.side);
    final sideTag = isFeed && sl.isNotEmpty ? ' · $sl' : '';
    final kindLabel = isFeed ? '${s.breast}$sideTag' : s.sleep;
    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: CupertinoActionSheet(
          title: Text(
            '$kindLabel · ${s.formatDateShort(session.start)}',
          ),
          actions: [
            if (isFeed)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  _switchFeedSide(session);
                },
                child: Text(
                  session.side == 'L' ? s.switchToRight : s.switchToLeft,
                ),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(ctx);
                _editStart(session);
              },
              child: Text(s.editStartTime),
            ),
            if (session.endEventId != null)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  _editEnd(session);
                },
                child: Text(s.editEndTime),
              ),
            if (session.isOngoing)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(ctx);
                  _endNow(session);
                },
                child: Text(s.endNow),
              ),
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(ctx);
                _confirmDelete(session);
              },
              child: Text(s.deleteSession),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final timeline = buildTimeline(
      widget.store.sessions,
      widget.store.pointEvents,
    );
    final dayStartHour = HomeConfigScope.of(context).dayStartHour;
    final grouped = _groupByDay(timeline, dayStartHour);
    final days = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    final topInset = MediaQuery.of(context).padding.top;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyGlassHeader(
              topInset: topInset,
              title: StickyHeaderTitle(S.of(context).history),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (timeline.isNotEmpty)
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 44),
                      onPressed: _confirmClear,
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: AppColors.danger,
                        size: 22,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const WakeupRefreshControl(),
          if (timeline.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Center(
                  child: Text(
                    S.of(context).emptyHistory,
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
                MediaQuery.of(context).padding.bottom + kFloatingNavReserve,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final day = days[idx];
                    final dayItems = grouped[day]!;
                    return Padding(
                      padding: EdgeInsets.only(top: idx == 0 ? 0 : 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(S.of(context)
                              .formatDayHeader(day, dayStartHour: dayStartHour)),
                          SectionCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              children: [
                                for (var i = 0; i < dayItems.length; i++) ...[
                                  dayItems[i].when(
                                    session: (s) => SessionRow(
                                      session: s,
                                      onTap: () => _openRowMenu(s),
                                    ),
                                    point: (e) => buildPointRow(
                                      e,
                                      onTap: () => _openPointMenu(e),
                                    ),
                                  ),
                                  if (i < dayItems.length - 1)
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
