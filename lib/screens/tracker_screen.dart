import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../widgets/sticky_header.dart';
import '../widgets/wakeup_refresh.dart';

import '../models/baby_event.dart';
import '../models/baby_session.dart';
import '../services/event_store.dart';
import '../services/statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import 'add_entry_sheet.dart';
import 'app_shell.dart' show kFloatingNavReserve;

class TrackerScreen extends StatefulWidget {
  final EventStore store;
  const TrackerScreen({super.key, required this.store});

  @override
  State<TrackerScreen> createState() => _TrackerScreenState();
}

class _TrackerScreenState extends State<TrackerScreen> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    widget.store.addListener(_onStoreChanged);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  Future<void> _toggleSleep() async {
    final type =
        widget.store.isSleeping ? EventType.sleepEnd : EventType.sleepStart;
    await widget.store.add(type);
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _startFeed(String side) async {
    await widget.store.add(EventType.feedStart, meta: {'side': side});
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _stopFeed() async {
    await widget.store.add(EventType.feedEnd);
    unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _logDiaper(EventType type) async {
    await widget.store.add(type);
    unawaited(HapticFeedback.mediumImpact());
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final isSleeping = store.isSleeping;
    final isFeeding = store.isFeeding;

    final stats = Statistics(store.events);
    final today = stats.statsForDay(DateTime.now());

    final topInset = MediaQuery.of(context).padding.top;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyGlassHeader(
              topInset: topInset,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    'assets/logo/nomnap_mark_compact.svg',
                    height: 48,
                    semanticsLabel: 'NomNap',
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'nomnap',
                    style: TextStyle(
                      fontFamily: '.SF Pro Rounded',
                      fontFamilyFallback: ['SF Pro Rounded', '.SF Pro Display'],
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.2,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => LocaleScope.of(context).toggle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.sleepSoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        S.of(context).localeCode.toUpperCase(),
                        style: AppText.caption.copyWith(
                          color: AppColors.sleepAccent,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(44, 44),
                    onPressed: () => AddEntrySheet.show(context, widget.store),
                    child: const Icon(
                      CupertinoIcons.add_circled_solid,
                      color: AppColors.sleepAccent,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const WakeupRefreshControl(),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              4,
            ),
            sliver: SliverToBoxAdapter(
              child: Text(
                S.of(context).greetingForHour(DateTime.now().hour),
                style: AppText.subhead,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              MediaQuery.of(context).padding.bottom + kFloatingNavReserve,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _ActionCard(
                  title: S.of(context).sleep,
                  active: isSleeping,
                  startedAt: store.sleepStartedAt,
                  accent: AppColors.sleepAccent,
                  softBg: AppColors.sleepSoft,
                  icon: CupertinoIcons.moon_fill,
                  activeLabel: S.of(context).sleeping,
                  inactiveLabel: S.of(context).awake,
                  buttonStart: S.of(context).startSleep,
                  buttonStop: S.of(context).wakeUp,
                  onToggle: _toggleSleep,
                ),
                const SizedBox(height: 12),
                _FeedCard(
                  active: isFeeding,
                  startedAt: store.feedStartedAt,
                  side: store.feedSide,
                  onStart: _startFeed,
                  onStop: _stopFeed,
                ),
                const SizedBox(height: 12),
                _DiaperCard(onLog: _logDiaper),
                const SizedBox(height: 28),
                SectionHeader(S.of(context).today),
                _TodaySummary(daily: today),
                const SizedBox(height: 28),
                SectionHeader(S.of(context).recentActivity),
                _RecentActivity(
                  sessions: store.sessions,
                  diaperEvents: store.diaperEvents,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final bool active;
  final DateTime? startedAt;
  final Color accent;
  final Color softBg;
  final IconData icon;
  final String activeLabel;
  final String inactiveLabel;
  final String buttonStart;
  final String buttonStop;
  final Future<void> Function() onToggle;

  const _ActionCard({
    required this.title,
    required this.active,
    required this.startedAt,
    required this.accent,
    required this.softBg,
    required this.icon,
    required this.activeLabel,
    required this.inactiveLabel,
    required this.buttonStart,
    required this.buttonStop,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = active && startedAt != null
        ? DateTime.now().difference(startedAt!)
        : Duration.zero;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.headline),
                    const SizedBox(height: 2),
                    Text(
                      active ? activeLabel : inactiveLabel,
                      style: AppText.footnote.copyWith(
                        color: active ? accent : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                formatDurationLong(elapsed),
                style: AppText.timerLarge.copyWith(
                  fontSize: 36,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (startedAt != null) ...[
              const SizedBox(height: 2),
              Center(
                child: Text(
                  S.of(context).since(formatClock(startedAt!)),
                  style: AppText.footnote,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 46,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: active ? AppColors.surface : accent,
              onPressed: () => onToggle(),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: active
                      ? Border.all(color: accent, width: 1.4)
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  active ? buttonStop : buttonStart,
                  style: AppText.callout.copyWith(
                    color: active ? accent : CupertinoColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedCard extends StatelessWidget {
  final bool active;
  final DateTime? startedAt;
  final String? side;
  final Future<void> Function(String side) onStart;
  final Future<void> Function() onStop;

  const _FeedCard({
    required this.active,
    required this.startedAt,
    required this.side,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sl = s.sideLabel(side);
    final elapsed = active && startedAt != null
        ? DateTime.now().difference(startedAt!)
        : Duration.zero;

    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.feedSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(CupertinoIcons.drop_fill,
                    color: AppColors.feedAccent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.feed, style: AppText.headline),
                    const SizedBox(height: 2),
                    Text(
                      active
                          ? (sl.isNotEmpty
                              ? '${s.feeding} · $sl'
                              : s.feeding)
                          : s.notFeeding,
                      style: AppText.footnote.copyWith(
                        color: active
                            ? AppColors.feedAccent
                            : AppColors.textSecondary,
                        fontWeight: active ? FontWeight.w500 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (active)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.feedAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.feedAccent.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (active) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                formatDurationLong(elapsed),
                style: AppText.timerLarge.copyWith(
                  fontSize: 36,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (startedAt != null) ...[
              const SizedBox(height: 2),
              Center(
                child: Text(
                  S.of(context).since(formatClock(startedAt!)),
                  style: AppText.footnote,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          if (active)
            SizedBox(
              height: 46,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(AppRadius.button),
                color: AppColors.surface,
                onPressed: () => onStop(),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: AppColors.feedAccent, width: 1.4),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    s.stopFeed,
                    style: AppText.callout.copyWith(
                      color: AppColors.feedAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      color: AppColors.feedAccent,
                      onPressed: () => onStart('L'),
                      child: Text(
                        s.left,
                        style: AppText.callout.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 46,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      color: AppColors.feedAccent,
                      onPressed: () => onStart('R'),
                      child: Text(
                        s.right,
                        style: AppText.callout.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DiaperCard extends StatefulWidget {
  final Future<void> Function(EventType) onLog;
  const _DiaperCard({required this.onLog});

  @override
  State<_DiaperCard> createState() => _DiaperCardState();
}

class _DiaperCardState extends State<_DiaperCard> {
  // null = idle, 'pee' or 'poop' = which button is showing a checkmark
  String? _confirmed;

  Future<void> _onTap(EventType type) async {
    setState(() => _confirmed = type == EventType.diaperPee ? 'pee' : 'poop');
    await widget.onLog(type);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _confirmed = null);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.diaperSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/poop.svg',
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(AppColors.diaperAccent, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.of(context).diaper, style: AppText.headline),
                const SizedBox(height: 1),
                Text(S.of(context).logAChange, style: AppText.footnote),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _DiaperButton(
            label: S.of(context).pee,
            background: AppColors.diaperSoft,
            foreground: AppColors.diaperAccent,
            showCheck: _confirmed == 'pee',
            onPressed: () => _onTap(EventType.diaperPee),
          ),
          const SizedBox(width: 8),
          _DiaperButton(
            label: S.of(context).poop,
            background: AppColors.diaperAccent,
            foreground: CupertinoColors.white,
            showCheck: _confirmed == 'poop',
            onPressed: () => _onTap(EventType.diaperPoop),
          ),
        ],
      ),
    );
  }
}

class _DiaperButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final bool showCheck;
  final VoidCallback onPressed;

  const _DiaperButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.showCheck,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        borderRadius: BorderRadius.circular(AppRadius.button),
        color: background,
        onPressed: onPressed,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: showCheck
              ? Icon(
                  CupertinoIcons.checkmark_alt,
                  key: const ValueKey('check'),
                  color: foreground,
                  size: 20,
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: AppText.callout.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final DailyStats? daily;
  const _TodaySummary({required this.daily});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sleeps = daily?.sleepCount ?? 0;
    final feeds = daily?.feedCount ?? 0;
    final sleepTotal = daily?.sleepTotal ?? Duration.zero;
    final feedTotal = daily?.feedTotal ?? Duration.zero;
    final pees = daily?.peeCount ?? 0;
    final poops = daily?.poopCount ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: CupertinoIcons.moon_fill,
            accent: AppColors.sleepAccent,
            softBg: AppColors.sleepSoft,
            value: '$sleeps',
            label: s.sleepPlural(sleeps),
            detail: formatDuration(sleepTotal),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            icon: CupertinoIcons.drop_fill,
            accent: AppColors.feedAccent,
            softBg: AppColors.feedSoft,
            value: '$feeds',
            label: s.feedPlural(feeds),
            detail: formatDuration(feedTotal),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            iconWidget: Center(
              child: SvgPicture.asset(
                'assets/icons/poop.svg',
                width: 14,
                height: 14,
                colorFilter: const ColorFilter.mode(AppColors.diaperAccent, BlendMode.srcIn),
              ),
            ),
            accent: AppColors.diaperAccent,
            softBg: AppColors.diaperSoft,
            value: '${pees + poops}',
            label: s.diaperPlural(pees + poops),
            detail: '$pees Pee  $poops Poo',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final Color accent;
  final Color softBg;
  final String value;
  final String label;
  final String detail;
  const _StatTile({
    this.icon,
    this.iconWidget,
    required this.accent,
    required this.softBg,
    required this.value,
    required this.label,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: iconWidget ?? Icon(icon, color: accent, size: 15),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppText.title.copyWith(
              fontSize: 24,
              letterSpacing: -0.5,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppText.footnote),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: softBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              detail,
              style: AppText.caption.copyWith(
                color: accent,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<BabySession> sessions;
  final List<BabyEvent> diaperEvents;
  const _RecentActivity({required this.sessions, required this.diaperEvents});

  @override
  Widget build(BuildContext context) {
    final items = buildTimeline(sessions, diaperEvents);
    final recent = items.take(5).toList();
    if (recent.isEmpty) {
      return SectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              S.of(context).emptyTracker,
              style: AppText.subhead,
            ),
          ),
        ),
      );
    }
    return SectionCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            recent[i].when(
              session: (s) => SessionRow(session: s),
              diaper: (e) => DiaperRow(event: e),
            ),
            if (i < recent.length - 1)
              Container(
                margin: const EdgeInsets.only(left: 60),
                height: 0.5,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

/// One row representing a sleep or feed session.
/// Shows kind, duration (or "ongoing" with a pulsing dot), and time range.
class SessionRow extends StatelessWidget {
  final BabySession session;
  final VoidCallback? onTap;
  const SessionRow({super.key, required this.session, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSleep = session.kind == SessionKind.sleep;
    final accent = isSleep ? AppColors.sleepAccent : AppColors.feedAccent;
    final softBg = isSleep ? AppColors.sleepSoft : AppColors.feedSoft;
    final icon = isSleep ? CupertinoIcons.moon_fill : CupertinoIcons.drop_fill;

    final s = S.of(context);
    final ongoing = session.isOngoing;
    final sl = !isSleep ? s.sideLabel(session.side) : '';
    final sideTag = sl.isNotEmpty ? ' · $sl' : '';
    final title = ongoing
        ? (isSleep ? s.sleeping : '${s.feeding}$sideTag')
        : (isSleep ? s.slept : '${s.fed}$sideTag');

    final duration = ongoing
        ? DateTime.now().difference(session.start)
        : session.duration!;

    final rightText = ongoing
        ? s.since(formatClock(session.start))
        : '${formatClock(session.start)} – ${formatClock(session.end!)}';

    final content = Padding(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppText.callout.copyWith(
                        color: ongoing ? accent : AppColors.textPrimary,
                        fontWeight:
                            ongoing ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (ongoing) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(formatDuration(duration), style: AppText.footnote),
              ],
            ),
          ),
          Text(
            rightText,
            style: AppText.subhead.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: content,
    );
  }
}

class TimelineItem {
  final DateTime timestamp;
  final BabySession? _session;
  final BabyEvent? _diaper;

  TimelineItem.session(BabySession s)
      : timestamp = s.start,
        _session = s,
        _diaper = null;

  TimelineItem.diaper(BabyEvent e)
      : timestamp = e.timestamp,
        _session = null,
        _diaper = e;

  bool get isSession => _session != null;

  Widget when({
    required Widget Function(BabySession) session,
    required Widget Function(BabyEvent) diaper,
  }) {
    if (_session != null) return session(_session);
    return diaper(_diaper!);
  }
}

List<TimelineItem> buildTimeline(
  List<BabySession> sessions,
  List<BabyEvent> diaperEvents,
) {
  final items = <TimelineItem>[
    for (final s in sessions) TimelineItem.session(s),
    for (final e in diaperEvents) TimelineItem.diaper(e),
  ];
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
}

class DiaperRow extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback? onTap;
  const DiaperRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isPee = event.type == EventType.diaperPee;
    final title = isPee ? s.pee : s.poop;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.diaperSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: isPee
                ? Icon(CupertinoIcons.drop, color: AppColors.diaperAccent, size: 16)
                : Center(
                    child: SvgPicture.asset(
                      'assets/icons/poop.svg',
                      width: 15,
                      height: 15,
                      colorFilter: const ColorFilter.mode(AppColors.diaperAccent, BlendMode.srcIn),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: AppText.callout),
          ),
          Text(
            formatClock(event.timestamp),
            style: AppText.subhead.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(
              CupertinoIcons.chevron_right,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: content,
    );
  }
}
