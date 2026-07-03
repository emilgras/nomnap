import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart'
    show ReorderableListView, ReorderableDragStartListener, Material, MaterialType;
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/tracker_kind.dart';
import '../services/feedback_service.dart';
import '../services/home_config.dart';
import '../services/session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/tracker_visuals.dart';

/// Bottom sheet to show/hide and reorder the home-page trackers.
class CustomizeHomeSheet extends StatefulWidget {
  final HomeConfig config;
  const CustomizeHomeSheet({super.key, required this.config});

  static Future<void> show(BuildContext context, HomeConfig config) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CustomizeHomeSheet(config: config),
    );
  }

  @override
  State<CustomizeHomeSheet> createState() => _CustomizeHomeSheetState();
}

class _CustomizeHomeSheetState extends State<CustomizeHomeSheet> {
  HomeConfig get config => widget.config;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.82,
            child: Column(
              children: [
              // Header row: title + Done.
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(s.customizeHome, style: AppText.headline),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        s.done,
                        style: AppText.callout.copyWith(
                          color: AppColors.sleepAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(s.customizeHomeHint, style: AppText.footnote),
                ),
              ),
              // Listen to the config so switch positions and order update
              // live as the user edits. Cap the height so a long list (many
              // trackers) scrolls instead of overflowing the screen.
              // A single flat, freely-reorderable list — drag any tracker
              // anywhere so the user can arrange the home page exactly as they
              // like (no fixed category grouping).
              Expanded(
                child: ListenableBuilder(
                  listenable: config,
                  builder: (context, _) {
                    final order = config.order;
                    return ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      proxyDecorator: _liftedRowDecorator,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      itemCount: order.length,
                      onReorder: (oldIndex, newIndex) {
                        HapticFeedback.selectionClick();
                        config.reorder(oldIndex, newIndex);
                      },
                      itemBuilder: (context, i) {
                        final setting = order[i];
                        final hasOptions = _optionsFor(setting.kind).isNotEmpty;
                        return _TrackerRow(
                          key: ValueKey(setting.kind),
                          index: i,
                          kind: setting.kind,
                          enabled: setting.enabled,
                          onToggle: (v) {
                            HapticFeedback.selectionClick();
                            config.setEnabled(setting.kind, v);
                          },
                          onConfigure: hasOptions
                              ? () => TrackerOptionsSheet.show(
                                  context, config, setting.kind)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              // "Missing one?" — invite the user to suggest a tracker we'll add.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
                child: _SuggestTrackerCard(
                  onTap: () => SuggestTrackerSheet.show(context),
                ),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tappable footer prompting the user to suggest a missing tracker.
class _SuggestTrackerCard extends StatelessWidget {
  final VoidCallback onTap;
  const _SuggestTrackerCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: AppColors.textTertiary.withValues(alpha: 0.35),
          radius: AppRadius.card,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.add_circled,
                color: AppColors.textTertiary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.missingTrackerPrompt,
                      style: AppText.footnote.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      s.missingTrackerCta,
                      style: AppText.caption
                          .copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 14,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Paints a subtle dashed rounded-rectangle border (no fill) around its child.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  final double dashWidth = 5;
  final double dashGap = 4;
  final double strokeWidth = 1;

  const _DashedBorderPainter({
    required this.color,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color ||
      old.radius != radius ||
      old.dashWidth != dashWidth ||
      old.dashGap != dashGap ||
      old.strokeWidth != strokeWidth;
}

/// Replaces ReorderableListView's default rectangular Material elevation
/// (which looks square behind our rounded card) with a transparent proxy that
/// gently scales the row — the row keeps its own rounded shadow while lifted.
Widget _liftedRowDecorator(Widget child, int index, Animation<double> animation) {
  return Material(
    type: MaterialType.transparency,
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(animation.value);
        return Transform.scale(scale: 1 + 0.03 * t, child: child);
      },
    ),
  );
}

class _TrackerRow extends StatelessWidget {
  final int index;
  final TrackerKind kind;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onConfigure;

  const _TrackerRow({
    super.key,
    required this.index,
    required this.kind,
    required this.enabled,
    required this.onToggle,
    this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    final visuals = trackerVisuals(kind);
    final name = visuals.name(S.of(context));

    // The icon + name (+ chevron) is the tap target for configurable
    // trackers; the switch and drag handle sit outside it.
    final leading = Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: visuals.softBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: visuals.icon,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(name, style: AppText.headline)),
        if (onConfigure != null) ...[
          const Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
        ],
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: onConfigure == null
                  ? leading
                  : GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onConfigure,
                      child: leading,
                    ),
            ),
            const SizedBox(width: 8),
            CupertinoSwitch(
              value: enabled,
              activeTrackColor: visuals.accent,
              onChanged: onToggle,
            ),
            const SizedBox(width: 6),
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Icon(
                  CupertinoIcons.line_horizontal_3,
                  size: 22,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single configurable boolean option for a tracker.
class _OptionDef {
  final String key;
  final String Function(S) label;
  final bool fallback;
  const _OptionDef(this.key, this.label, this.fallback);
}

/// The configurable options for a tracker kind (empty = not configurable).
List<_OptionDef> _optionsFor(TrackerKind kind) {
  switch (kind) {
    case TrackerKind.diaper:
      return [_OptionDef('trackSize', (s) => s.trackSize, false)];
    case TrackerKind.bottle:
    case TrackerKind.tube:
      return [_OptionDef('trackAmount', (s) => s.trackAmount, true)];
    case TrackerKind.sleep:
    case TrackerKind.feed:
    case TrackerKind.weight:
    case TrackerKind.length:
    case TrackerKind.head:
      return const [];
  }
}

/// Bottom sheet with a free-text field for suggesting a tracker we should add.
/// The submission is written to Firestore (`feedback` collection) via
/// [FeedbackService] and reviewed out-of-band in the Firebase console.
class SuggestTrackerSheet extends StatefulWidget {
  const SuggestTrackerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => const SuggestTrackerSheet(),
    );
  }

  @override
  State<SuggestTrackerSheet> createState() => _SuggestTrackerSheetState();
}

class _SuggestTrackerSheetState extends State<SuggestTrackerSheet> {
  final _controller = TextEditingController();
  final _emailController = TextEditingController();
  final _feedback = FeedbackService();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  // Lenient sanity check — we only want to catch obvious typos, not enforce
  // RFC 5322. Server-side rules cap the length.
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    final email = _emailController.text.trim();
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      setState(() => _error = S.of(context).suggestEmailInvalid);
      return;
    }

    final session = SessionScope.of(context);
    final locale = S.of(context).localeCode;

    setState(() {
      _sending = true;
      _error = null;
    });

    try {
      await _feedback.submitSuggestion(
        text: text,
        uid: session.uid,
        householdId: session.householdId,
        locale: locale,
        email: email,
        platform: defaultTargetPlatform.name,
      );
      HapticFeedback.mediumImpact();
      if (mounted) setState(() => _sent = true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = S.of(context).suggestFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    // Lift the sheet above the keyboard while typing.
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
            child: _sent
                ? _buildThanks(s)
                : _buildForm(s),
          ),
        ),
      ),
    );
  }

  Widget _buildThanks(S s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.checkmark_alt,
              color: AppColors.success,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.suggestThanks,
            textAlign: TextAlign.center,
            style: AppText.headline,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: AppColors.sleepAccent,
              borderRadius: BorderRadius.circular(AppRadius.button),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                s.done,
                style: AppText.headline.copyWith(color: CupertinoColors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(S s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 4),
          child: Row(
            children: [
              Expanded(
                child:
                    Text(s.suggestTrackerTitle, style: AppText.headline),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: const Size(44, 44),
                onPressed:
                    _sending ? null : () => Navigator.of(context).pop(),
                child: Text(
                  s.done,
                  style: AppText.callout.copyWith(
                    color: AppColors.sleepAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s.missingTrackerCta, style: AppText.footnote),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: CupertinoTextField(
                    controller: _controller,
                    autofocus: true,
                    minLines: 3,
                    maxLines: 6,
                    maxLength: 2000,
                    enabled: !_sending,
                    textCapitalization: TextCapitalization.sentences,
                    placeholder: s.suggestTrackerPlaceholder,
                    placeholderStyle: AppText.callout
                        .copyWith(color: AppColors.textTertiary),
                    style: AppText.callout,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.divider),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: CupertinoTextField(
                    controller: _emailController,
                    enabled: !_sending,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.none,
                    placeholder: s.suggestEmailPlaceholder,
                    placeholderStyle: AppText.callout
                        .copyWith(color: AppColors.textTertiary),
                    style: AppText.callout,
                    padding: const EdgeInsets.all(14),
                    onSubmitted: (_) => _submit(),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.divider),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(s.suggestEmailHint, style: AppText.caption),
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _error!,
                        style: AppText.footnote
                            .copyWith(color: AppColors.danger),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: AppColors.sleepAccent,
                      borderRadius:
                          BorderRadius.circular(AppRadius.button),
                      onPressed: _sending ? null : _submit,
                      child: Text(
                        _sending ? s.sending : s.send,
                        style: AppText.headline
                            .copyWith(color: CupertinoColors.white),
                      ),
                    ),
                  ),
                ),
      ],
    );
  }
}

/// Per-tracker options sheet (e.g. diaper size, bottle/tube amount).
class TrackerOptionsSheet extends StatelessWidget {
  final HomeConfig config;
  final TrackerKind kind;
  const TrackerOptionsSheet({
    super.key,
    required this.config,
    required this.kind,
  });

  static Future<void> show(
      BuildContext context, HomeConfig config, TrackerKind kind) {
    return showCupertinoModalPopup(
      context: context,
      builder: (ctx) => TrackerOptionsSheet(config: config, kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final visuals = trackerVisuals(kind);
    final options = _optionsFor(kind);
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(visuals.name(s), style: AppText.headline),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(44, 44),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        s.done,
                        style: AppText.callout.copyWith(
                          color: AppColors.sleepAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListenableBuilder(
                listenable: config,
                builder: (context, _) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Column(
                      children: [
                        for (final opt in options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.card),
                                boxShadow: [
                                  BoxShadow(
                                    color: CupertinoColors.black
                                        .withValues(alpha: 0.04),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(opt.label(s),
                                        style: AppText.callout),
                                  ),
                                  CupertinoSwitch(
                                    value: config.optionBool(kind, opt.key,
                                        fallback: opt.fallback),
                                    activeTrackColor: visuals.accent,
                                    onChanged: (v) {
                                      HapticFeedback.selectionClick();
                                      config.setOption(kind, opt.key, v);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
