import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/baby_event.dart';
import '../models/tracker_kind.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../services/statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import '../widgets/sticky_header.dart';
import '../widgets/wakeup_refresh.dart';
import 'app_shell.dart' show kFloatingNavReserve;

/// Time window the stats are computed over.
enum _Range { today, week, month, all }

class StatsScreen extends StatefulWidget {
  final EventStore store;
  const StatsScreen({super.key, required this.store});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _Range _range = _Range.week;

  /// Restrict events to the selected window. Rolling windows (7/30 days) keyed
  /// off the logical day boundary; "all" returns everything.
  List<BabyEvent> _eventsInRange(List<BabyEvent> events, int dayStartHour) {
    if (_range == _Range.all) return events;
    final key = dayKeyFor(DateTime.now(), dayStartHour);
    final todayStart = DateTime(key.year, key.month, key.day)
        .add(Duration(hours: dayStartHour));
    final cutoff = switch (_range) {
      _Range.today => todayStart,
      _Range.week => todayStart.subtract(const Duration(days: 6)),
      _Range.month => todayStart.subtract(const Duration(days: 29)),
      _Range.all => todayStart, // unreachable
    };
    return events.where((e) => !e.timestamp.isBefore(cutoff)).toList();
  }

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

  @override
  Widget build(BuildContext context) {
    final config = HomeConfigScope.of(context);
    final stats = Statistics(
      _eventsInRange(widget.store.events, config.dayStartHour),
      dayStartHour: config.dayStartHour,
    );
    final daily = stats.dailyStats;
    final hasData = daily.isNotEmpty;

    // Mirror the home page: only surface a tracker's stats when it's enabled.
    // In particular, hide breastfeed (Amning) figures when that card is off.
    final enabled = config.enabledInOrder.toSet();
    final showSleep = enabled.contains(TrackerKind.sleep);
    final showFeed = enabled.contains(TrackerKind.feed);
    final hasSessionAverages = showSleep || showFeed;

    final topInset = MediaQuery.of(context).padding.top;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyGlassHeader(
              topInset: topInset,
              title: StickyHeaderTitle(S.of(context).stats),
            ),
          ),
          const WakeupRefreshControl(),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.of(context).padding.bottom + kFloatingNavReserve,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _RangeSelector(
                  range: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: 18),
                if (!hasData)
                  SectionCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          _range == _Range.all
                              ? S.of(context).noDataYet
                              : S.of(context).noDataInRange,
                          textAlign: TextAlign.center,
                          style: AppText.subhead,
                        ),
                      ),
                    ),
                  )
                else ...[
                  SectionHeader(S.of(context).dailyAverages),
                  if (showSleep || showFeed) ...[
                    _AvgGrid(
                      stats: stats,
                      showSleep: showSleep,
                      showFeed: showFeed,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _DiaperAvgTile(stats: stats),
                  if (stats.hasSupplementalFeeds) ...[
                    const SizedBox(height: 12),
                    _VolumeTile(stats: stats),
                  ],
                  if (hasSessionAverages) ...[
                    const SizedBox(height: 24),
                    SectionHeader(S.of(context).sessionAverages),
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          for (final row in [
                            if (showSleep)
                              _StatRow(
                                label: S.of(context).avgSleepLength,
                                value: formatDuration(stats.avgSleepDuration),
                                accent: AppColors.sleepAccent,
                              ),
                            if (showFeed)
                              _StatRow(
                                label: S.of(context).avgFeedLength,
                                value: formatDuration(stats.avgFeedDuration),
                                accent: AppColors.feedAccent,
                              ),
                            if (showSleep)
                              _StatRow(
                                label: S.of(context).longestSleep,
                                value: formatDuration(stats.longestSleep),
                                accent: AppColors.sleepAccent,
                              ),
                          ].indexed)
                            ...[
                            if (row.$1 > 0) const _RowDivider(),
                            row.$2,
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SectionHeader(S.of(context).byDay),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < daily.length; i++) ...[
                          _DailyRow(
                            d: daily[i],
                            showSleep: showSleep,
                            showFeed: showFeed,
                          ),
                          if (i < daily.length - 1) const _RowDivider(),
                        ],
                      ],
                    ),
                  ),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  final _Range range;
  final ValueChanged<_Range> onChanged;
  const _RangeSelector({required this.range, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    String label(_Range r) => switch (r) {
          _Range.today => s.today,
          _Range.week => s.rangeWeek,
          _Range.month => s.rangeMonth,
          _Range.all => s.rangeAll,
        };
    return SizedBox(
      width: double.infinity,
      child: CupertinoSlidingSegmentedControl<_Range>(
        groupValue: range,
        backgroundColor: AppColors.divider.withValues(alpha: 0.6),
        thumbColor: AppColors.surface,
        onValueChanged: (r) {
          if (r != null) {
            HapticFeedback.selectionClick();
            onChanged(r);
          }
        },
        children: {
          for (final r in _Range.values)
            r: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label(r),
                style: AppText.footnote.copyWith(
                  color: range == r
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: range == r ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
        },
      ),
    );
  }
}

class _AvgGrid extends StatelessWidget {
  final Statistics stats;
  final bool showSleep;
  final bool showFeed;
  const _AvgGrid({
    required this.stats,
    required this.showSleep,
    required this.showFeed,
  });
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final tiles = <Widget>[
      if (showSleep)
        _AvgTile(
          icon: CupertinoIcons.moon_fill,
          accent: AppColors.sleepAccent,
          softBg: AppColors.sleepSoft,
          value: formatDuration(stats.avgDailySleep),
          label: s.sleepPerDay,
          sub: '${stats.avgSleepsPerDay.toStringAsFixed(1)} ${s.sessions}',
        ),
      if (showFeed)
        _AvgTile(
          icon: CupertinoIcons.drop_fill,
          accent: AppColors.feedAccent,
          softBg: AppColors.feedSoft,
          value: formatDuration(stats.avgDailyFeed),
          label: s.feedingPerDay,
          sub: '${stats.avgFeedsPerDay.toStringAsFixed(1)} ${s.sessions}',
        ),
    ];
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: tiles[i]),
        ],
      ],
    );
  }
}

class _AvgTile extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final Color softBg;
  final String value;
  final String label;
  final String sub;
  const _AvgTile({
    required this.icon,
    required this.accent,
    required this.softBg,
    required this.value,
    required this.label,
    required this.sub,
  });
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 14),
          Text(value, style: AppText.title),
          const SizedBox(height: 4),
          Text(label, style: AppText.subhead),
          const SizedBox(height: 2),
          Text(sub, style: AppText.caption),
        ],
      ),
    );
  }
}

class _DiaperAvgTile extends StatelessWidget {
  final Statistics stats;
  const _DiaperAvgTile({required this.stats});
  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.diaperSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Center(
              child: SvgPicture.asset(
                'assets/icons/poop.svg',
                width: 16,
                height: 16,
                colorFilter: const ColorFilter.mode(AppColors.diaperAccent, BlendMode.srcIn),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).diapersPerDay(stats.avgDiapersPerDay.toStringAsFixed(1)),
                  style: AppText.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  '${stats.avgPeesPerDay.toStringAsFixed(1)} ${S.of(context).pee}  '
                  '${stats.avgPoopsPerDay.toStringAsFixed(1)} ${S.of(context).poop}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottle + tube summary. Shown only when supplemental feeds exist. Headline is
/// the all-feeds-per-day figure; the sub-line breaks out volume by Flaske/Sonde
/// (or, if amounts aren't tracked, per-day counts).
class _VolumeTile extends StatelessWidget {
  final Statistics stats;
  const _VolumeTile({required this.stats});

  String _sub(S s) {
    final days = stats.dailyStats;
    final b = stats.avgDailyBottleMl.round();
    final t = stats.avgDailyTubeMl.round();
    final parts = <String>[];
    if (b > 0) parts.add('$b ml ${s.bottle}');
    if (t > 0) parts.add('$t ml ${s.tube}');
    if (parts.isNotEmpty) return parts.join('   ·   ');
    // No volumes tracked — fall back to average counts per day.
    if (days.isEmpty) return '';
    final bc = days.fold<int>(0, (a, d) => a + d.bottleCount) / days.length;
    final tc = days.fold<int>(0, (a, d) => a + d.tubeCount) / days.length;
    final counts = <String>[];
    if (bc > 0) counts.add('${bc.toStringAsFixed(1)} ${s.bottle}');
    if (tc > 0) counts.add('${tc.toStringAsFixed(1)} ${s.tube}');
    return counts.join('   ·   ');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return SectionCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.bottleSoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Center(
              child: BottleIcon(color: AppColors.bottleAccent, size: 16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s.feedsPerDay(stats.avgTotalFeedsPerDay.toStringAsFixed(1)),
                  style: AppText.title.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(_sub(s), style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  const _StatRow({
    required this.label,
    required this.value,
    required this.accent,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppText.callout)),
          Text(
            value,
            style: AppText.callout.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyRow extends StatelessWidget {
  final DailyStats d;
  final bool showSleep;
  final bool showFeed;
  const _DailyRow({
    required this.d,
    required this.showSleep,
    required this.showFeed,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              S.of(context).formatDayHeader(
                    d.day,
                    dayStartHour: HomeConfigScope.of(context).dayStartHour,
                  ),
              style: AppText.callout,
            ),
          ),
          if (showSleep) ...[
            _Chip(
              icon: CupertinoIcons.moon_fill,
              text: formatDuration(d.sleepTotal),
              sub: '×${d.sleepCount}',
              accent: AppColors.sleepAccent,
              softBg: AppColors.sleepSoft,
            ),
            const SizedBox(width: 8),
          ],
          if (showFeed)
            _Chip(
              icon: CupertinoIcons.drop_fill,
              text: formatDuration(d.feedTotal),
              sub: '×${d.feedCount}',
              accent: AppColors.feedAccent,
              softBg: AppColors.feedSoft,
            ),
          if (d.diaperCount > 0) ...[
            const SizedBox(width: 8),
            _Chip(
              iconWidget: SvgPicture.asset(
                'assets/icons/poop.svg',
                width: 12,
                height: 12,
                colorFilter: const ColorFilter.mode(AppColors.diaperAccent, BlendMode.srcIn),
              ),
              text: '${d.diaperCount}',
              sub: '',
              accent: AppColors.diaperAccent,
              softBg: AppColors.diaperSoft,
            ),
          ],
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String text;
  final String sub;
  final Color accent;
  final Color softBg;
  const _Chip({
    this.icon,
    this.iconWidget,
    required this.text,
    required this.sub,
    required this.accent,
    required this.softBg,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconWidget ?? Icon(icon, color: accent, size: 12),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppText.footnote.copyWith(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(sub, style: AppText.caption.copyWith(color: accent)),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 18),
      height: 0.5,
      color: AppColors.divider,
    );
  }
}
