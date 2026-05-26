import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../models/baby_event.dart';
import '../models/baby_session.dart';
import '../services/event_store.dart';
import '../services/statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import 'add_entry_sheet.dart';

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

  Future<void> _toggleFeed() async {
    final type =
        widget.store.isFeeding ? EventType.feedEnd : EventType.feedStart;
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

    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: SvgPicture.asset(
              'assets/logo/nomnap_wordmark.svg',
              height: 38,
              semanticsLabel: 'NomNap',
            ),
            backgroundColor: AppColors.background,
            border: null,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(10),
              child: SizedBox.shrink(),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              minimumSize: const Size(32, 32),
              onPressed: () => AddEntrySheet.show(context, widget.store),
              child: const Icon(
                CupertinoIcons.add_circled_solid,
                color: AppColors.sleepAccent,
                size: 28,
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              MediaQuery.of(context).padding.bottom + 24,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _Greeting(store: store),
                const SizedBox(height: 16),
                _ActionCard(
                  title: 'Sleep',
                  active: isSleeping,
                  startedAt: store.sleepStartedAt,
                  accent: AppColors.sleepAccent,
                  softBg: AppColors.sleepSoft,
                  icon: CupertinoIcons.moon_fill,
                  activeLabel: 'Sleeping',
                  inactiveLabel: 'Awake',
                  buttonStart: 'Start Sleep',
                  buttonStop: 'Wake Up',
                  onToggle: _toggleSleep,
                ),
                const SizedBox(height: 14),
                _ActionCard(
                  title: 'Feed',
                  active: isFeeding,
                  startedAt: store.feedStartedAt,
                  accent: AppColors.feedAccent,
                  softBg: AppColors.feedSoft,
                  icon: CupertinoIcons.drop_fill,
                  activeLabel: 'Feeding',
                  inactiveLabel: 'Not feeding',
                  buttonStart: 'Start Feed',
                  buttonStop: 'Stop Feed',
                  onToggle: _toggleFeed,
                ),
                const SizedBox(height: 28),
                const SectionHeader('Today'),
                _TodaySummary(daily: today),
                const SizedBox(height: 28),
                const SectionHeader('Recent activity'),
                _RecentActivity(sessions: store.sessions),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  final EventStore store;
  const _Greeting({required this.store});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'Good night';
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        _greeting(),
        style: AppText.subhead,
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
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: softBg,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: accent, size: 20),
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
                      style: AppText.subhead.copyWith(
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
          const SizedBox(height: 18),
          Center(
            child: Text(
              active ? formatDurationLong(elapsed) : '—',
              style: AppText.timerLarge.copyWith(
                color: active ? AppColors.textPrimary : AppColors.textTertiary,
              ),
            ),
          ),
          if (active && startedAt != null) ...[
            const SizedBox(height: 2),
            Center(
              child: Text(
                'Since ${formatClock(startedAt!)}',
                style: AppText.footnote,
              ),
            ),
          ],
          const SizedBox(height: 18),
          _BigButton(
            label: active ? buttonStop : buttonStart,
            background: active ? AppColors.surface : accent,
            foreground: active ? accent : CupertinoColors.white,
            border: active ? accent : null,
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

class _BigButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Color? border;
  final Future<void> Function() onPressed;
  const _BigButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadius.button),
        color: background,
        onPressed: () => onPressed(),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: border != null
                ? Border.all(color: border!, width: 1.4)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppText.headline.copyWith(
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
    final sleeps = daily?.sleepCount ?? 0;
    final feeds = daily?.feedCount ?? 0;
    final sleepTotal = daily?.sleepTotal ?? Duration.zero;
    final feedTotal = daily?.feedTotal ?? Duration.zero;

    return SectionCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _SummaryCell(
              value: '$sleeps',
              caption: 'Sleeps',
              accent: AppColors.sleepAccent,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _SummaryCell(
              value: formatDuration(sleepTotal),
              caption: 'Slept',
              accent: AppColors.sleepAccent,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _SummaryCell(
              value: '$feeds',
              caption: 'Feeds',
              accent: AppColors.feedAccent,
            ),
          ),
          const _CellDivider(),
          Expanded(
            child: _SummaryCell(
              value: formatDuration(feedTotal),
              caption: 'Fed',
              accent: AppColors.feedAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCell extends StatelessWidget {
  final String value;
  final String caption;
  final Color accent;
  const _SummaryCell({
    required this.value,
    required this.caption,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppText.title.copyWith(
            fontSize: 20,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(caption, style: AppText.caption),
      ],
    );
  }
}

class _CellDivider extends StatelessWidget {
  const _CellDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 30,
      color: AppColors.divider,
    );
  }
}

class _RecentActivity extends StatelessWidget {
  final List<BabySession> sessions;
  const _RecentActivity({required this.sessions});

  @override
  Widget build(BuildContext context) {
    final recent = sessions.reversed.take(5).toList();
    if (recent.isEmpty) {
      return SectionCard(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Tap a button above to start tracking.',
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
            SessionRow(session: recent[i]),
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

    final ongoing = session.isOngoing;
    final title = ongoing
        ? (isSleep ? 'Sleeping' : 'Feeding')
        : (isSleep ? 'Slept' : 'Fed');

    final duration = ongoing
        ? DateTime.now().difference(session.start)
        : session.duration!;

    final rightText = ongoing
        ? 'Since ${formatClock(session.start)}'
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
