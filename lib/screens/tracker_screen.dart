import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../widgets/sticky_header.dart';
import '../widgets/wakeup_refresh.dart';

import '../models/baby_event.dart';
import '../models/baby_session.dart';
import '../models/tracker_kind.dart';
import '../services/baby_profile_service.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../services/statistics.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/async_action.dart';
import '../widgets/format.dart';
import '../widgets/section_card.dart';
import 'add_entry_sheet.dart';
import 'app_shell.dart' show kFloatingNavReserve;
import 'customize_home_sheet.dart';
import 'feed_amount_sheet.dart';
import 'measurement_sheet.dart';

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
    // Only repaint each second when there's a live elapsed timer to advance
    // (an ongoing sleep/feed). When nothing is running this would otherwise
    // rebuild the whole screen — and recompute Statistics — once a second for
    // no visible change.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && (widget.store.isSleeping || widget.store.isFeeding)) {
        setState(() {});
      }
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
    final ok = await runGuarded(context, () => widget.store.add(type));
    if (ok) unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _startFeed(String side) async {
    final ok = await runGuarded(
        context, () => widget.store.add(EventType.feedStart, meta: {'side': side}));
    if (ok) unawaited(HapticFeedback.mediumImpact());
  }

  Future<void> _stopFeed() async {
    final ok =
        await runGuarded(context, () => widget.store.add(EventType.feedEnd));
    if (ok) unawaited(HapticFeedback.mediumImpact());
  }

  /// Returns true if the diaper event was logged, so the card only flashes its
  /// confirmation checkmark on a real success.
  Future<bool> _logDiaper(EventType type, {String? size}) async {
    final ok = await runGuarded(
      context,
      () => widget.store.add(type, meta: size != null ? {'size': size} : null),
    );
    if (ok) unawaited(HapticFeedback.mediumImpact());
    return ok;
  }

  Future<bool> _logQuickFeed(EventType type, {String? amount}) async {
    final ok = await runGuarded(
      context,
      () =>
          widget.store.add(type, meta: amount != null ? {'amount': amount} : null),
    );
    if (ok) unawaited(HapticFeedback.mediumImpact());
    return ok;
  }

  Future<bool> _logMeasurement(
      EventType type, String value, String unit) async {
    final ok = await runGuarded(
      context,
      () => widget.store.add(type, meta: {'value': value, 'unit': unit}),
    );
    if (ok) unawaited(HapticFeedback.mediumImpact());
    return ok;
  }

  /// "4250 g · 2d ago" for a measurement card, or null if never measured.
  String? _lastMeasurement(EventType type, String unit) {
    final e = widget.store.lastOf(type);
    final v = e?.meta?['value'];
    if (e == null || v == null) return null;
    final s = S.of(context);
    return s.lastMeasured(
      s.measurementValue(v, e.meta?['unit'] ?? unit),
      s.relativeTimeAgo(e.timestamp),
    );
  }

  /// Builds the enabled tracker cards in configured order, with 12px gaps.
  /// Shows an empty-state hint (with a Customize shortcut) when none are on.
  List<Widget> _buildTrackerCards(BuildContext context, HomeConfig config) {
    final kinds = config.enabledInOrder;
    if (kinds.isEmpty) {
      return [
        SectionCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  S.of(context).noTrackersHint,
                  textAlign: TextAlign.center,
                  style: AppText.subhead,
                ),
              ),
              CupertinoButton(
                onPressed: () => CustomizeHomeSheet.show(context, config),
                child: Text(S.of(context).customize),
              ),
            ],
          ),
        ),
      ];
    }
    final cards = <Widget>[];
    for (var i = 0; i < kinds.length; i++) {
      if (i > 0) cards.add(const SizedBox(height: 12));
      cards.add(_cardFor(context, config, kinds[i]));
    }
    return cards;
  }

  /// "Last X ago" subtitle for an idle card, or null if that type has no
  /// history yet (caller falls back to the static label).
  String? _lastAgo(EventType type, String Function(String) label) {
    final at = widget.store.lastOf(type)?.timestamp;
    if (at == null) return null;
    return label(S.of(context).relativeTimeAgo(at));
  }

  Widget _cardFor(BuildContext context, HomeConfig config, TrackerKind kind) {
    final store = widget.store;
    final s = S.of(context);
    switch (kind) {
      case TrackerKind.sleep:
        return _ActionCard(
          title: s.sleep,
          active: store.isSleeping,
          startedAt: store.sleepStartedAt,
          accent: AppColors.sleepAccent,
          softBg: AppColors.sleepSoft,
          icon: CupertinoIcons.moon_fill,
          activeLabel: s.sleeping,
          inactiveLabel: s.awake,
          idleDetail: _lastAgo(EventType.sleepEnd, s.lastSlept),
          buttonStart: s.startSleep,
          buttonStop: s.wakeUp,
          onToggle: _toggleSleep,
        );
      case TrackerKind.feed:
        return _FeedCard(
          active: store.isFeeding,
          startedAt: store.feedStartedAt,
          side: store.feedSide,
          idleDetail: _lastAgo(EventType.feedEnd, s.lastFed),
          onStart: _startFeed,
          onStop: _stopFeed,
        );
      case TrackerKind.bottle:
        return _QuickFeedCard(
          title: s.bottle,
          icon: const BottleIcon(color: AppColors.bottleAccent, size: 22),
          accent: AppColors.bottleAccent,
          softBg: AppColors.bottleSoft,
          trackAmount: config.optionBool(kind, 'trackAmount', fallback: true),
          idleDetail: _lastAgo(EventType.feedBottle, s.lastAgo),
          onLog: (amount) =>
              _logQuickFeed(EventType.feedBottle, amount: amount),
        );
      case TrackerKind.tube:
        return _QuickFeedCard(
          title: s.tube,
          icon: const TubeIcon(color: AppColors.tubeAccent, size: 22),
          accent: AppColors.tubeAccent,
          softBg: AppColors.tubeSoft,
          trackAmount: config.optionBool(kind, 'trackAmount', fallback: true),
          idleDetail: _lastAgo(EventType.feedTube, s.lastAgo),
          onLog: (amount) => _logQuickFeed(EventType.feedTube, amount: amount),
        );
      case TrackerKind.diaper:
        final parts = [
          _lastAgo(EventType.diaperPee, s.lastPee),
          _lastAgo(EventType.diaperPoop, s.lastPoo),
        ].whereType<String>().toList();
        return _DiaperCard(
          trackSize: config.optionBool(kind, 'trackSize', fallback: false),
          idleDetail: parts.isEmpty ? null : parts.join('  ·  '),
          onLog: _logDiaper,
        );
      case TrackerKind.weight:
        return _MeasurementCard(
          type: EventType.weight,
          title: s.weight,
          unit: s.gramsUnit,
          allowDecimal: false,
          icon: CupertinoIcons.gauge,
          accent: AppColors.weightAccent,
          softBg: AppColors.weightSoft,
          idleDetail: _lastMeasurement(EventType.weight, s.gramsUnit),
          onLog: (value) =>
              _logMeasurement(EventType.weight, value, s.gramsUnit),
        );
      case TrackerKind.length:
        return _MeasurementCard(
          type: EventType.length,
          title: s.length,
          unit: s.cmUnit,
          allowDecimal: true,
          icon: CupertinoIcons.resize_v,
          accent: AppColors.lengthAccent,
          softBg: AppColors.lengthSoft,
          idleDetail: _lastMeasurement(EventType.length, s.cmUnit),
          onLog: (value) => _logMeasurement(EventType.length, value, s.cmUnit),
        );
      case TrackerKind.head:
        return _MeasurementCard(
          type: EventType.headCirc,
          title: s.headCirc,
          unit: s.cmUnit,
          allowDecimal: true,
          icon: CupertinoIcons.smiley,
          accent: AppColors.headAccent,
          softBg: AppColors.headSoft,
          idleDetail: _lastMeasurement(EventType.headCirc, s.cmUnit),
          onLog: (value) =>
              _logMeasurement(EventType.headCirc, value, s.cmUnit),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final config = HomeConfigScope.of(context);

    final stats = Statistics(store.events, dayStartHour: config.dayStartHour);
    final today = stats.statsForDay(DateTime.now());

    // TODAY tiles mirror what's enabled on the home page: a feed tile shows if
    // any feed-type tracker (breast/bottle/tube) is on. Hide the whole section
    // when nothing relevant is enabled.
    final enabled = config.enabledInOrder.toSet();
    final showSleep = enabled.contains(TrackerKind.sleep);
    final showFeed = enabled.contains(TrackerKind.feed) ||
        enabled.contains(TrackerKind.bottle) ||
        enabled.contains(TrackerKind.tube);
    final showDiaper = enabled.contains(TrackerKind.diaper);
    final showToday = showSleep || showFeed || showDiaper;

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
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed: () => AddEntrySheet.show(context, widget.store),
                child: const Icon(
                  CupertinoIcons.add_circled_solid,
                  color: AppColors.sleepAccent,
                  size: 32,
                ),
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
              child: Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final s = S.of(context);
                        final p = BabyProfileScope.of(context).profile;
                        final greeting =
                            s.greetingForHour(DateTime.now().hour);
                        final name = p.hasName ? ' ${p.name}' : '';
                        final age = (p.hasName && p.birthDate != null)
                            ? s.formatAge(p.birthDate!)
                            : '';
                        final text = age.isEmpty
                            ? '$greeting$name'
                            : '$greeting$name · $age';
                        return Text(
                          text,
                          style: AppText.subhead,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                  ),
                  _CustomizePill(
                    onTap: () => CustomizeHomeSheet.show(context, config),
                  ),
                ],
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
                ..._buildTrackerCards(context, config),
                if (showToday) ...[
                  const SizedBox(height: 28),
                  SectionHeader(S.of(context).today),
                  _TodaySummary(
                    daily: today,
                    showSleep: showSleep,
                    showFeed: showFeed,
                    showDiaper: showDiaper,
                  ),
                ],
                const SizedBox(height: 28),
                SectionHeader(S.of(context).recentActivity),
                _RecentActivity(
                  sessions: store.sessions,
                  pointEvents: store.pointEvents,
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
  final String? idleDetail;
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
    this.idleDetail,
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
                      active ? activeLabel : (idleDetail ?? inactiveLabel),
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
  final String? idleDetail;
  final Future<void> Function(String side) onStart;
  final Future<void> Function() onStop;

  const _FeedCard({
    required this.active,
    required this.startedAt,
    required this.side,
    this.idleDetail,
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
                          : (idleDetail ?? s.notFeeding),
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
  final bool trackSize;
  final String? idleDetail;
  final Future<bool> Function(EventType, {String? size}) onLog;
  const _DiaperCard({
    required this.trackSize,
    this.idleDetail,
    required this.onLog,
  });

  @override
  State<_DiaperCard> createState() => _DiaperCardState();
}

class _DiaperCardState extends State<_DiaperCard> {
  // null = idle, 'pee' or 'poop' = which button is showing a checkmark
  String? _confirmed;

  Future<void> _onTap(EventType type) async {
    String? size;
    if (widget.trackSize) {
      size = await _pickSize(type);
      if (size == null) return; // cancelled
    }
    final ok = await widget.onLog(type, size: size);
    if (!ok || !mounted) return;
    setState(() => _confirmed = type == EventType.diaperPee ? 'pee' : 'poop');
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _confirmed = null);
  }

  Future<String?> _pickSize(EventType type) {
    final s = S.of(context);
    return showCupertinoModalPopup<String>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(s.diaperSize),
        actions: [
          for (final size in const ['S', 'M', 'L'])
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(ctx).pop(size),
              child: Text(s.sizeLabel(size)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(s.cancel),
        ),
      ),
    );
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
                Text(
                  widget.idleDetail ?? S.of(context).logAChange,
                  style: AppText.footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
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

/// A one-tap feed card (bottle / tube). Logs instantly; when [trackAmount]
/// is on, first prompts for an amount in ml. Shows a brief checkmark on log.
class _QuickFeedCard extends StatefulWidget {
  final String title;
  final Widget icon;
  final Color accent;
  final Color softBg;
  final bool trackAmount;
  final String? idleDetail;
  final Future<bool> Function(String? amount) onLog;

  const _QuickFeedCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.softBg,
    required this.trackAmount,
    this.idleDetail,
    required this.onLog,
  });

  @override
  State<_QuickFeedCard> createState() => _QuickFeedCardState();
}

class _QuickFeedCardState extends State<_QuickFeedCard> {
  bool _confirmed = false;

  Future<void> _onTap() async {
    String? amount;
    if (widget.trackAmount) {
      amount = await FeedAmountSheet.show(context, accent: widget.accent);
      if (amount == null) return; // cancelled
    }
    final ok = await widget.onLog(amount);
    if (!ok || !mounted) return;
    setState(() => _confirmed = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _confirmed = false);
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
              color: widget.softBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: widget.icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppText.headline),
                const SizedBox(height: 1),
                Text(
                  widget.idleDetail ?? S.of(context).tapToLog,
                  style: AppText.footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: widget.accent,
              onPressed: _onTap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _confirmed
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        key: ValueKey('check'),
                        color: CupertinoColors.white,
                        size: 20,
                      )
                    : Text(
                        S.of(context).add,
                        key: const ValueKey('label'),
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
    );
  }
}

/// A growth-measurement card (weight/length/head). Tapping "Add" opens a
/// numeric sheet; on save it logs the value and flashes a checkmark.
class _MeasurementCard extends StatefulWidget {
  final EventType type;
  final String title;
  final String unit;
  final bool allowDecimal;
  final IconData icon;
  final Color accent;
  final Color softBg;
  final String? idleDetail;
  final Future<bool> Function(String value) onLog;

  const _MeasurementCard({
    required this.type,
    required this.title,
    required this.unit,
    required this.allowDecimal,
    required this.icon,
    required this.accent,
    required this.softBg,
    required this.onLog,
    this.idleDetail,
  });

  @override
  State<_MeasurementCard> createState() => _MeasurementCardState();
}

class _MeasurementCardState extends State<_MeasurementCard> {
  bool _confirmed = false;

  Future<void> _onTap() async {
    final value = await MeasurementSheet.show(
      context,
      title: widget.title,
      unit: widget.unit,
      accent: widget.accent,
      allowDecimal: widget.allowDecimal,
    );
    if (value == null) return; // cancelled
    final ok = await widget.onLog(value);
    if (!ok || !mounted) return;
    setState(() => _confirmed = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _confirmed = false);
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
              color: widget.softBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.icon, color: widget.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: AppText.headline),
                const SizedBox(height: 1),
                Text(
                  widget.idleDetail ?? S.of(context).notMeasuredYet,
                  style: AppText.footnote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 40,
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              borderRadius: BorderRadius.circular(AppRadius.button),
              color: widget.accent,
              onPressed: _onTap,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: _confirmed
                    ? const Icon(
                        CupertinoIcons.checkmark_alt,
                        key: ValueKey('check'),
                        color: CupertinoColors.white,
                        size: 20,
                      )
                    : Text(
                        S.of(context).add,
                        key: const ValueKey('label'),
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
    );
  }
}

/// Small tinted "Tilpas" pill shown at the end of the greeting row.
class _CustomizePill extends StatelessWidget {
  final VoidCallback onTap;
  const _CustomizePill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      minimumSize: const Size(0, 0),
      borderRadius: BorderRadius.circular(AppRadius.button),
      color: AppColors.sleepSoft,
      onPressed: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            CupertinoIcons.slider_horizontal_3,
            color: AppColors.sleepAccent,
            size: 17,
          ),
          const SizedBox(width: 7),
          Text(
            S.of(context).customize,
            style: AppText.subhead.copyWith(
              color: AppColors.sleepAccent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TodaySummary extends StatelessWidget {
  final DailyStats? daily;
  final bool showSleep;
  final bool showFeed;
  final bool showDiaper;
  const _TodaySummary({
    required this.daily,
    required this.showSleep,
    required this.showFeed,
    required this.showDiaper,
  });

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final sleeps = daily?.sleepCount ?? 0;
    final feeds = daily?.feedCount ?? 0;
    final sleepTotal = daily?.sleepTotal ?? Duration.zero;
    final feedTotal = daily?.feedTotal ?? Duration.zero;
    final pees = daily?.peeCount ?? 0;
    final poops = daily?.poopCount ?? 0;

    final tiles = <Widget>[
      if (showSleep)
        _StatTile(
          icon: CupertinoIcons.moon_fill,
          accent: AppColors.sleepAccent,
          softBg: AppColors.sleepSoft,
          value: '$sleeps',
          label: s.sleepPlural(sleeps),
          detail: formatDuration(sleepTotal),
        ),
      if (showFeed)
        _StatTile(
          icon: CupertinoIcons.drop_fill,
          accent: AppColors.feedAccent,
          softBg: AppColors.feedSoft,
          value: '$feeds',
          label: s.feedPlural(feeds),
          detail: formatDuration(feedTotal),
        ),
      if (showDiaper)
        _StatTile(
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
          detail: '$pees ${s.pee}  $poops ${s.poop}',
        ),
    ];

    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: tiles[i]),
        ],
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
  final List<BabyEvent> pointEvents;
  const _RecentActivity({required this.sessions, required this.pointEvents});

  @override
  Widget build(BuildContext context) {
    final items = buildTimeline(sessions, pointEvents);
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
              point: (e) => buildPointRow(e),
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
  final BabyEvent? _point;

  TimelineItem.session(BabySession s)
      : timestamp = s.start,
        _session = s,
        _point = null;

  TimelineItem.point(BabyEvent e)
      : timestamp = e.timestamp,
        _session = null,
        _point = e;

  bool get isSession => _session != null;

  Widget when({
    required Widget Function(BabySession) session,
    required Widget Function(BabyEvent) point,
  }) {
    if (_session != null) return session(_session);
    return point(_point!);
  }
}

List<TimelineItem> buildTimeline(
  List<BabySession> sessions,
  List<BabyEvent> pointEvents,
) {
  final items = <TimelineItem>[
    for (final s in sessions) TimelineItem.session(s),
    for (final e in pointEvents) TimelineItem.point(e),
  ];
  items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return items;
}

/// Renders a point event row: a diaper row or a bottle/tube feed row.
Widget buildPointRow(BabyEvent event, {VoidCallback? onTap}) {
  if (event.type.isInstantFeed) {
    return FeedPointRow(event: event, onTap: onTap);
  }
  if (event.type.isMeasurement) {
    return MeasurementRow(event: event, onTap: onTap);
  }
  return DiaperRow(event: event, onTap: onTap);
}

/// Visual metadata for a growth measurement (icon / colors / label / unit),
/// shared by the home card and the timeline row.
class MeasurementInfo {
  final Color accent;
  final Color softBg;
  final IconData icon;
  final String Function(S) name;
  final String Function(S) unit;
  const MeasurementInfo({
    required this.accent,
    required this.softBg,
    required this.icon,
    required this.name,
    required this.unit,
  });
}

MeasurementInfo measurementInfoFor(EventType type) {
  switch (type) {
    case EventType.length:
      return MeasurementInfo(
        accent: AppColors.lengthAccent,
        softBg: AppColors.lengthSoft,
        icon: CupertinoIcons.resize_v,
        name: (s) => s.length,
        unit: (s) => s.cmUnit,
      );
    case EventType.headCirc:
      return MeasurementInfo(
        accent: AppColors.headAccent,
        softBg: AppColors.headSoft,
        icon: CupertinoIcons.smiley,
        name: (s) => s.headCirc,
        unit: (s) => s.cmUnit,
      );
    case EventType.weight:
    default:
      return MeasurementInfo(
        accent: AppColors.weightAccent,
        softBg: AppColors.weightSoft,
        icon: CupertinoIcons.gauge,
        name: (s) => s.weight,
        unit: (s) => s.gramsUnit,
      );
  }
}

/// One timeline row for a growth measurement (weight/length/head).
class MeasurementRow extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback? onTap;
  const MeasurementRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final info = measurementInfoFor(event.type);
    final value = event.meta?['value'];
    final unit = event.meta?['unit'] ?? info.unit(s);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: info.softBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(info.icon, color: info.accent, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(info.name(s), style: AppText.callout)),
                if (value != null && value.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MetaBadge(
                    text: s.measurementValue(value, unit),
                    accent: info.accent,
                    softBg: info.softBg,
                  ),
                ],
              ],
            ),
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

class DiaperRow extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback? onTap;
  const DiaperRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isPee = event.type == EventType.diaperPee;
    final title = isPee ? s.pee : s.poop;
    final sizeLabel = s.sizeLabel(event.meta?['size']);

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
            child: Row(
              children: [
                Flexible(child: Text(title, style: AppText.callout)),
                if (sizeLabel.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MetaBadge(
                    text: sizeLabel,
                    accent: AppColors.diaperAccent,
                    softBg: AppColors.diaperSoft,
                  ),
                ],
              ],
            ),
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

/// One row representing an instant feed (bottle or tube), with optional amount.
class FeedPointRow extends StatelessWidget {
  final BabyEvent event;
  final VoidCallback? onTap;
  const FeedPointRow({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isBottle = event.type == EventType.feedBottle;
    final accent = isBottle ? AppColors.bottleAccent : AppColors.tubeAccent;
    final softBg = isBottle ? AppColors.bottleSoft : AppColors.tubeSoft;
    final icon = isBottle
        ? const BottleIcon(color: AppColors.bottleAccent, size: 18)
        : const TubeIcon(color: AppColors.tubeAccent, size: 18);
    final title = isBottle ? s.bottle : s.tube;
    final amount = event.meta?['amount'];

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
            child: Center(child: icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: [
                Flexible(child: Text(title, style: AppText.callout)),
                if (amount != null && amount.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _MetaBadge(
                    text: s.amountMl(amount),
                    accent: accent,
                    softBg: softBg,
                  ),
                ],
              ],
            ),
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

/// Small pill badge for inline metadata (diaper size, feed amount).
class _MetaBadge extends StatelessWidget {
  final String text;
  final Color accent;
  final Color softBg;
  const _MetaBadge({
    required this.text,
    required this.accent,
    required this.softBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: softBg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppText.caption.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
