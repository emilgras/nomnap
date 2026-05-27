import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../services/event_store.dart';
import '../services/statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import '../widgets/sticky_header.dart';
import '../widgets/wakeup_refresh.dart';
import 'app_shell.dart' show kFloatingNavReserve;

class StatsScreen extends StatefulWidget {
  final EventStore store;
  const StatsScreen({super.key, required this.store});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
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
    final stats = Statistics(widget.store.events);
    final daily = stats.dailyStats;
    final hasData = daily.isNotEmpty;

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
                if (!hasData)
                  SectionCard(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          S.of(context).noDataYet,
                          textAlign: TextAlign.center,
                          style: AppText.subhead,
                        ),
                      ),
                    ),
                  )
                else ...[
                  SectionHeader(S.of(context).dailyAverages),
                  _AvgGrid(stats: stats),
                  const SizedBox(height: 12),
                  _DiaperAvgTile(stats: stats),
                  const SizedBox(height: 24),
                  SectionHeader(S.of(context).sessionAverages),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _StatRow(
                          label: S.of(context).avgSleepLength,
                          value: formatDuration(stats.avgSleepDuration),
                          accent: AppColors.sleepAccent,
                        ),
                        const _RowDivider(),
                        _StatRow(
                          label: S.of(context).avgFeedLength,
                          value: formatDuration(stats.avgFeedDuration),
                          accent: AppColors.feedAccent,
                        ),
                        const _RowDivider(),
                        _StatRow(
                          label: S.of(context).longestSleep,
                          value: formatDuration(stats.longestSleep),
                          accent: AppColors.sleepAccent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(S.of(context).byDay),
                  SectionCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (var i = 0; i < daily.length; i++) ...[
                          _DailyRow(d: daily[i]),
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

class _AvgGrid extends StatelessWidget {
  final Statistics stats;
  const _AvgGrid({required this.stats});
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return Row(
      children: [
        Expanded(
          child: _AvgTile(
            icon: CupertinoIcons.moon_fill,
            accent: AppColors.sleepAccent,
            softBg: AppColors.sleepSoft,
            value: formatDuration(stats.avgDailySleep),
            label: s.sleepPerDay,
            sub: '${stats.avgSleepsPerDay.toStringAsFixed(1)} ${s.sessions}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _AvgTile(
            icon: CupertinoIcons.drop_fill,
            accent: AppColors.feedAccent,
            softBg: AppColors.feedSoft,
            value: formatDuration(stats.avgDailyFeed),
            label: s.feedingPerDay,
            sub: '${stats.avgFeedsPerDay.toStringAsFixed(1)} ${s.sessions}',
          ),
        ),
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
                  '${stats.avgPeesPerDay.toStringAsFixed(1)} Pee  ${stats.avgPoopsPerDay.toStringAsFixed(1)} Poo',
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
  const _DailyRow({required this.d});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(S.of(context).formatDayHeader(d.day), style: AppText.callout),
          ),
          _Chip(
            icon: CupertinoIcons.moon_fill,
            text: formatDuration(d.sleepTotal),
            sub: '×${d.sleepCount}',
            accent: AppColors.sleepAccent,
            softBg: AppColors.sleepSoft,
          ),
          const SizedBox(width: 8),
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
