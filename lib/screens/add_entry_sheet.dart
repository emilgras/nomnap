import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/baby_event.dart';
import '../models/tracker_kind.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icons.dart';
import '../widgets/format.dart';
import 'customize_home_sheet.dart' show SuggestTrackerSheet;

/// The + sheet: a grouped picker of every loggable action (Mad / Aktivitet /
/// Vækst); pick one and a detail form collects the right values, then saves.
class AddEntrySheet extends StatefulWidget {
  final EventStore store;
  const AddEntrySheet({super.key, required this.store});

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
  TrackerKind? _kind; // null → show the picker
  late DateTime _start;
  late DateTime _end;
  bool _ongoing = false;
  bool _saving = false;
  String? _error;
  bool _isPoop = false;
  String _feedSide = 'L';
  final _amountCtl = TextEditingController();
  final _valueCtl = TextEditingController();
  // Focus for the amount/measurement field. We request it *after* the sheet
  // transition so the keyboard doesn't pop up mid-animation and bounce the
  // sheet up then down.
  final _fieldFocus = FocusNode();
  // Drives the direction of the picker↔detail transition: forward (push in
  // from the right) when opening an action, backward when returning.
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _end = now;
    _start = now.subtract(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _amountCtl.dispose();
    _valueCtl.dispose();
    _fieldFocus.dispose();
    super.dispose();
  }

  List<TrackerKind> _kindsIn(TrackerGroup g) =>
      [for (final k in TrackerKind.values) if (k.group == g) k];

  void _selectKind(TrackerKind kind) {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _forward = true;
      _kind = kind;
      _error = null;
      _ongoing = false;
      // Point-in-time actions default to "now"; sessions to the last hour.
      if (kind == TrackerKind.sleep || kind == TrackerKind.feed) {
        _start = now.subtract(const Duration(hours: 1));
        _end = now;
      } else {
        _start = now;
      }
    });
    // Fields that take a typed value (bottle/tube amount, growth measurement):
    // raise the keyboard only after the push transition has (mostly) settled.
    final needsField = kind == TrackerKind.bottle ||
        kind == TrackerKind.tube ||
        kind.isMeasurement;
    if (needsField) {
      Future.delayed(const Duration(milliseconds: 340), () {
        if (mounted && _kind == kind) _fieldFocus.requestFocus();
      });
    }
  }

  void _back() {
    // Dismiss the keyboard first so the picker doesn't get briefly lifted by
    // the keyboard inset (which caused an up-then-down bump on the way back).
    _fieldFocus.unfocus();
    setState(() {
      _forward = false;
      _kind = null;
      _error = null;
    });
  }

  EventType _measurementType(TrackerKind k) => k == TrackerKind.weight
      ? EventType.weight
      : k == TrackerKind.length
          ? EventType.length
          : EventType.headCirc;

  String _measurementUnit(S s, TrackerKind k) =>
      k == TrackerKind.weight ? s.gramsUnit : s.cmUnit;

  void _setSaving() => setState(() {
        _saving = true;
        _error = null;
      });

  void _fail(S s) {
    if (mounted) {
      setState(() {
        _saving = false;
        _error = s.errSave;
      });
    }
  }

  void _close() {
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _save() async {
    final s = S.of(context);
    final kind = _kind!;
    final now = DateTime.now();

    // Growth measurement (weight/length/head).
    if (kind.isMeasurement) {
      final raw = _valueCtl.text.trim().replaceAll(',', '.');
      final n = double.tryParse(raw);
      if (n == null || n <= 0) {
        setState(() => _error = s.notMeasuredYet);
        return;
      }
      if (_start.isAfter(now)) {
        setState(() => _error = s.errorTimeFuture);
        return;
      }
      _setSaving();
      try {
        await widget.store.add(
          _measurementType(kind),
          at: _start,
          meta: {'value': raw, 'unit': _measurementUnit(s, kind)},
        );
      } catch (_) {
        _fail(s);
        return;
      }
      HapticFeedback.mediumImpact();
      _close();
      return;
    }

    // Instant feed (bottle / tube).
    if (kind == TrackerKind.bottle || kind == TrackerKind.tube) {
      if (_start.isAfter(now)) {
        setState(() => _error = s.errorTimeFuture);
        return;
      }
      _setSaving();
      final type =
          kind == TrackerKind.bottle ? EventType.feedBottle : EventType.feedTube;
      final amount = _amountCtl.text.trim();
      try {
        await widget.store.add(
          type,
          at: _start,
          meta: amount.isNotEmpty ? {'amount': amount} : null,
        );
      } catch (_) {
        _fail(s);
        return;
      }
      HapticFeedback.mediumImpact();
      _close();
      return;
    }

    // Diaper.
    if (kind == TrackerKind.diaper) {
      if (_start.isAfter(now)) {
        setState(() => _error = s.errorTimeFuture);
        return;
      }
      _setSaving();
      try {
        await widget.store.add(
          _isPoop ? EventType.diaperPoop : EventType.diaperPee,
          at: _start,
        );
      } catch (_) {
        _fail(s);
        return;
      }
      HapticFeedback.mediumImpact();
      _close();
      return;
    }

    // Session: sleep or breastfeed (Amning).
    final isSleep = kind == TrackerKind.sleep;
    if (_ongoing) {
      if (isSleep ? widget.store.isSleeping : widget.store.isFeeding) {
        setState(() => _error =
            isSleep ? s.sleepAlreadyInProgress : s.feedAlreadyInProgress);
        return;
      }
      if (_start.isAfter(now)) {
        setState(() => _error = s.errorStartFuture);
        return;
      }
    } else {
      if (!_end.isAfter(_start)) {
        setState(() => _error = s.errorEndAfterStart);
        return;
      }
    }
    _setSaving();
    final startType = isSleep ? EventType.sleepStart : EventType.feedStart;
    final feedMeta = isSleep ? null : {'side': _feedSide};
    try {
      if (_ongoing) {
        await widget.store.add(startType, at: _start, meta: feedMeta);
      } else {
        await widget.store.addSession(
          startType: startType,
          endType: isSleep ? EventType.sleepEnd : EventType.feedEnd,
          start: _start,
          end: _end,
          startMeta: feedMeta,
        );
      }
    } catch (_) {
      _fail(s);
      return;
    }
    HapticFeedback.mediumImpact();
    _close();
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
                        style: AppText.headline
                            .copyWith(color: AppColors.sleepAccent),
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
    // Only reserve space for the keyboard while a detail form (with a field) is
    // showing. On the picker there's no field, so ignoring the inset there
    // keeps it from being lifted as the keyboard dismisses on "back".
    final keyboardInset =
        _kind == null ? 0.0 : MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        // AnimatedPadding smooths the keyboard inset: viewInsets updates in
        // discrete jumps (and snaps to 0 on "back"), and animating the padding
        // turns those jumps into a glide instead of a pop.
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + keyboardInset),
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
              // Shared-axis (horizontal) transition between picker and detail:
              // the incoming view pushes in from the right (or left on "back")
              // while the outgoing view fades and slides the opposite way.
              // AnimatedSize smooths the height difference between the two.
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      ?currentChild,
                    ],
                  ),
                  transitionBuilder: (child, animation) {
                    final dir = _forward ? 1.0 : -1.0;
                    return DualTransitionBuilder(
                      animation: animation,
                      forwardBuilder: (context, anim, child) => FadeTransition(
                        opacity: CurvedAnimation(
                            parent: anim, curve: const Interval(0.15, 1.0)),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.10 * dir, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeOutCubic)),
                          child: child,
                        ),
                      ),
                      reverseBuilder: (context, anim, child) => FadeTransition(
                        opacity: ReverseAnimation(CurvedAnimation(
                            parent: anim, curve: const Interval(0.0, 0.85))),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset.zero,
                            end: Offset(-0.10 * dir, 0),
                          ).animate(CurvedAnimation(
                              parent: anim, curve: Curves.easeInCubic)),
                          child: child,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_kind),
                    child: _kind == null ? _buildPicker(s) : _buildDetail(s),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 84),
              Expanded(
                child: Center(
                  child: Text(s.addEntry, style: AppText.headline),
                ),
              ),
              SizedBox(
                width: 84,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerRight,
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    s.cancel,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        for (final group in TrackerGroup.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
            child: Text(
              _groupName(s, group).toUpperCase(),
              style: AppText.caption.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          _PickerRow(kinds: _kindsIn(group), onTap: _selectKind),
        ],
        const SizedBox(height: 28),
        // Text prompt (no icon) to suggest a missing action.
        Center(
          child: CupertinoButton(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            minimumSize: const Size(0, 0),
            onPressed: () => SuggestTrackerSheet.show(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  s.missingTrackerPrompt,
                  textAlign: TextAlign.center,
                  style: AppText.subhead.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  s.missingTrackerCta,
                  textAlign: TextAlign.center,
                  style: AppText.subhead
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _buildDetail(S s) {
    final kind = _kind!;
    final visuals = _kindVisuals(kind);
    final accent = visuals.accent;
    final isSession = kind == TrackerKind.sleep || kind == TrackerKind.feed;
    final duration =
        _end.isAfter(_start) ? _end.difference(_start) : Duration.zero;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  onPressed: _saving ? null : _back,
                  child: const Icon(CupertinoIcons.chevron_back,
                      color: AppColors.sleepAccent),
                ),
              ),
              Expanded(
                child: Center(
                  child: Text(visuals.name(s), style: AppText.headline),
                ),
              ),
              SizedBox(
                width: 60,
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerRight,
                  onPressed: _saving ? null : _save,
                  child: Text(
                    s.save,
                    style: AppText.headline
                        .copyWith(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Amning: which side.
        if (kind == TrackerKind.feed) ...[
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
                accent: accent,
              ),
              'R': _SegmentLabel(
                icon: CupertinoIcons.arrow_right,
                text: s.right,
                selected: _feedSide == 'R',
                accent: accent,
              ),
            },
          ),
          const SizedBox(height: 10),
        ],

        // Diaper: pee or poop.
        if (kind == TrackerKind.diaper) ...[
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
                accent: accent,
              ),
              true: _SegmentLabel(
                icon: CupertinoIcons.circle_fill,
                text: s.poop,
                selected: _isPoop,
                accent: accent,
              ),
            },
          ),
          const SizedBox(height: 10),
        ],

        // Bottle / tube: optional amount.
        if (kind == TrackerKind.bottle || kind == TrackerKind.tube) ...[
          _ValueField(
            controller: _amountCtl,
            unit: s.ml,
            allowDecimal: false,
            placeholder: '120',
            focusNode: _fieldFocus,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
        ],

        // Growth: the measurement value.
        if (kind.isMeasurement) ...[
          _ValueField(
            controller: _valueCtl,
            unit: _measurementUnit(s, kind),
            allowDecimal: kind != TrackerKind.weight,
            placeholder: kind == TrackerKind.weight ? '4250' : '55',
            focusNode: _fieldFocus,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 10),
        ],

        // Session vs point-in-time time controls.
        if (isSession) ...[
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
            const SizedBox(height: 14),
            Center(
              child: Text(
                s.durationLabel(formatDuration(duration)),
                style: AppText.subhead
                    .copyWith(color: accent, fontWeight: FontWeight.w500),
              ),
            ),
          ] else ...[
            const SizedBox(height: 14),
            Center(
              child: Text(
                s.inProgress,
                style: AppText.subhead
                    .copyWith(color: accent, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ] else
          _TimeRow(
            label: s.time,
            value: s.formatStamp(_start),
            onTap: () => _pickTime(isStart: true),
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
    );
  }
}

String _groupName(S s, TrackerGroup group) {
  switch (group) {
    case TrackerGroup.food:
      return s.groupFood;
    case TrackerGroup.activity:
      return s.groupActivity;
    case TrackerGroup.growth:
      return s.groupGrowth;
  }
}

/// A row of up to three action tiles, padded to keep a consistent tile size.
class _PickerRow extends StatelessWidget {
  final List<TrackerKind> kinds;
  final ValueChanged<TrackerKind> onTap;
  const _PickerRow({required this.kinds, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: i < kinds.length
                ? _PickerTile(kind: kinds[i], onTap: () => onTap(kinds[i]))
                : const SizedBox(),
          ),
        ],
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  final TrackerKind kind;
  final VoidCallback onTap;
  const _PickerTile({required this.kind, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final v = _kindVisuals(kind);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: v.softBg,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Center(child: v.icon),
            ),
            const SizedBox(height: 8),
            Text(
              v.name(S.of(context)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.footnote.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KindVisuals {
  final Color accent;
  final Color softBg;
  final Widget icon;
  final String Function(S) name;
  const _KindVisuals({
    required this.accent,
    required this.softBg,
    required this.icon,
    required this.name,
  });
}

_KindVisuals _kindVisuals(TrackerKind kind) {
  switch (kind) {
    case TrackerKind.sleep:
      return _KindVisuals(
        accent: AppColors.sleepAccent,
        softBg: AppColors.sleepSoft,
        icon: const Icon(CupertinoIcons.moon_fill,
            color: AppColors.sleepAccent, size: 20),
        name: (s) => s.sleep,
      );
    case TrackerKind.feed:
      return _KindVisuals(
        accent: AppColors.feedAccent,
        softBg: AppColors.feedSoft,
        icon: const Icon(CupertinoIcons.drop_fill,
            color: AppColors.feedAccent, size: 20),
        name: (s) => s.feed,
      );
    case TrackerKind.bottle:
      return _KindVisuals(
        accent: AppColors.bottleAccent,
        softBg: AppColors.bottleSoft,
        icon: const BottleIcon(color: AppColors.bottleAccent, size: 20),
        name: (s) => s.bottle,
      );
    case TrackerKind.tube:
      return _KindVisuals(
        accent: AppColors.tubeAccent,
        softBg: AppColors.tubeSoft,
        icon: const TubeIcon(color: AppColors.tubeAccent, size: 20),
        name: (s) => s.tube,
      );
    case TrackerKind.diaper:
      return _KindVisuals(
        accent: AppColors.diaperAccent,
        softBg: AppColors.diaperSoft,
        icon: SvgPicture.asset(
          'assets/icons/poop.svg',
          width: 20,
          height: 20,
          colorFilter: const ColorFilter.mode(
              AppColors.diaperAccent, BlendMode.srcIn),
        ),
        name: (s) => s.diaper,
      );
    case TrackerKind.weight:
      return _KindVisuals(
        accent: AppColors.weightAccent,
        softBg: AppColors.weightSoft,
        icon: const Icon(CupertinoIcons.gauge,
            color: AppColors.weightAccent, size: 20),
        name: (s) => s.weight,
      );
    case TrackerKind.length:
      return _KindVisuals(
        accent: AppColors.lengthAccent,
        softBg: AppColors.lengthSoft,
        icon: const Icon(CupertinoIcons.resize_v,
            color: AppColors.lengthAccent, size: 20),
        name: (s) => s.length,
      );
    case TrackerKind.head:
      return _KindVisuals(
        accent: AppColors.headAccent,
        softBg: AppColors.headSoft,
        icon: const Icon(CupertinoIcons.smiley,
            color: AppColors.headAccent, size: 20),
        name: (s) => s.headCirc,
      );
  }
}

/// A single-line numeric field with a trailing unit (ml / g / cm).
class _ValueField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;
  final bool allowDecimal;
  final String placeholder;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  const _ValueField({
    required this.controller,
    required this.unit,
    required this.allowDecimal,
    required this.placeholder,
    this.focusNode,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
        LengthLimitingTextInputFormatter(5),
      ],
      placeholder: placeholder,
      style: AppText.callout,
      textAlign: TextAlign.center,
      onSubmitted: onSubmitted,
      suffix: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Text(unit, style: AppText.subhead),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
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
