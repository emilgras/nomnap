import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// A purely decorative pull-to-refresh control. The mascot starts wide
/// awake; pulling lulls it to sleep — eyes drift from round dots to
/// closed eyelash arcs, the mouth softens from a little open "o" to a
/// gentle U smile, and two Zzz fade in and float upward. Releasing past
/// the trigger holds the asleep state briefly, then the indicator
/// retracts and the face wakes back up. It does not refresh any data —
/// the effect exists only because it's cute.
class WakeupRefreshControl extends StatelessWidget {
  const WakeupRefreshControl({super.key});

  static const double _triggerExtent = 96.0;
  static const double _indicatorExtent = 78.0;

  @override
  Widget build(BuildContext context) {
    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: _triggerExtent,
      refreshIndicatorExtent: _indicatorExtent,
      onRefresh: () => Future.delayed(const Duration(milliseconds: 700)),
      builder: (
        ctx,
        state,
        pulledExtent,
        triggerExtent,
        indicatorExtent,
      ) {
        return _SleepyFaceIndicator(
          refreshState: state,
          pulledExtent: pulledExtent,
          triggerExtent: triggerExtent,
          indicatorExtent: indicatorExtent,
        );
      },
    );
  }
}

class _SleepyFaceIndicator extends StatefulWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double triggerExtent;
  final double indicatorExtent;

  const _SleepyFaceIndicator({
    required this.refreshState,
    required this.pulledExtent,
    required this.triggerExtent,
    required this.indicatorExtent,
  });

  @override
  State<_SleepyFaceIndicator> createState() => _SleepyFaceIndicatorState();
}

class _SleepyFaceIndicatorState extends State<_SleepyFaceIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zCtrl;

  @override
  void initState() {
    super.initState();
    _zCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void dispose() {
    _zCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.triggerExtent <= 0
        ? 0.0
        : (widget.pulledExtent / widget.triggerExtent).clamp(0.0, 1.0);
    final held = widget.refreshState == RefreshIndicatorMode.armed ||
        widget.refreshState == RefreshIndicatorMode.refresh;
    final sleepiness = held ? 1.0 : progress;

    return AnimatedBuilder(
      animation: _zCtrl,
      builder: (ctx, _) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: SizedBox(
              height: widget.indicatorExtent - 12,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 256,
                  height: 256,
                  child: CustomPaint(
                    painter: _FacePainter(
                      sleepiness: sleepiness,
                      zPhase: _zCtrl.value,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FacePainter extends CustomPainter {
  final double sleepiness;
  final double zPhase;

  _FacePainter({required this.sleepiness, required this.zPhase});

  static const _faceColor = Color(0xFFFFD8B5);
  static const _cheekColor = Color(0xFFFF8A65);
  static const _strokeColor = Color(0xFF2D3142);

  // Smoothstep eases the swap of features through the mid-point so neither
  // form lingers half-strength, which would otherwise look like a double
  // mouth/eye smear during the crossfade.
  static double _smooth(double t) {
    final c = t.clamp(0.0, 1.0);
    return c * c * (3 - 2 * c);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 256.0);

    canvas.drawCircle(
      const Offset(128, 128),
      116,
      Paint()..color = _faceColor,
    );

    _drawCheek(canvas, const Offset(68, 152));
    _drawCheek(canvas, const Offset(188, 152));

    _drawEye(canvas, const Offset(88, 112));
    _drawEye(canvas, const Offset(168, 112));

    _drawMouth(canvas);

    if (sleepiness > 0.02) {
      _drawZs(canvas);
    }
  }

  void _drawCheek(Canvas canvas, Offset center) {
    final rect = Rect.fromCenter(center: center, width: 52, height: 32);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          _cheekColor.withValues(alpha: 0.6),
          _cheekColor.withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawOval(rect, paint);
  }

  void _drawEye(Canvas canvas, Offset c) {
    final asleep = _smooth(sleepiness);
    final awake = 1 - asleep;

    if (asleep > 0.01) {
      final stroke = Paint()
        ..color = _strokeColor.withValues(alpha: asleep)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(c.dx - 18, c.dy - 6)
        ..quadraticBezierTo(c.dx, c.dy + 10, c.dx + 18, c.dy - 6);
      canvas.drawPath(path, stroke);
    }

    if (awake > 0.01) {
      // Open eyes start full-size; pupil shrinks as they close.
      final r = 9 * awake;
      canvas.drawCircle(
        c,
        r,
        Paint()..color = _strokeColor.withValues(alpha: awake),
      );
      if (awake > 0.55) {
        final h = ((awake - 0.55) / 0.45).clamp(0.0, 1.0);
        canvas.drawCircle(
          c + const Offset(-2.6, -2.8),
          2.4,
          Paint()..color = CupertinoColors.white.withValues(alpha: h),
        );
      }
    }
  }

  void _drawMouth(Canvas canvas) {
    final asleep = _smooth(sleepiness);
    final awake = 1 - asleep;

    if (asleep > 0.01) {
      final stroke = Paint()
        ..color = _strokeColor.withValues(alpha: asleep)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(110, 172)
        ..quadraticBezierTo(128, 186, 146, 172);
      canvas.drawPath(path, stroke);
    }

    if (awake > 0.01) {
      final fill = Paint()
        ..color = _strokeColor.withValues(alpha: awake);
      canvas.drawOval(
        Rect.fromCenter(center: const Offset(128, 176), width: 16, height: 11),
        fill,
      );
    }
  }

  void _drawZs(Canvas canvas) {
    void drawZ({
      required double tx,
      required double ty,
      required double size,
      required double strokeWidth,
      required double phaseOffset,
    }) {
      final p = (zPhase + phaseOffset) % 1.0;
      final rise = p * 14;
      final bob = math.sin(p * math.pi * 2) * 2.5;
      final lifecycle = math.sin(p * math.pi).clamp(0.0, 1.0);
      final alpha = (sleepiness * (0.35 + 0.65 * lifecycle)).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = AppColors.sleepAccent.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.save();
      canvas.translate(tx, ty - rise + bob);
      canvas.rotate(-10 * math.pi / 180);
      final path = Path()
        ..moveTo(0, 0)
        ..lineTo(size, 0)
        ..lineTo(0, size)
        ..lineTo(size, size);
      canvas.drawPath(path, paint);
      canvas.restore();
    }

    drawZ(tx: 196, ty: 50, size: 32, strokeWidth: 8, phaseOffset: 0);
    drawZ(tx: 224, ty: 26, size: 16, strokeWidth: 5.5, phaseOffset: 0.45);
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      old.sleepiness != sleepiness || old.zPhase != zPhase;
}
