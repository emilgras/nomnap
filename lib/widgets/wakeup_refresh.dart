import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// A purely decorative pull-to-refresh control. Pulling down opens the
/// sleepy mascot's eyes and floats away the Zzz's; releasing past the
/// trigger plays a brief "wake up" bounce, then the face drifts back to
/// sleep as the indicator retracts. It does not refresh any data — the
/// effect exists only because it's cute.
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
        return _WakingFaceIndicator(
          refreshState: state,
          pulledExtent: pulledExtent,
          triggerExtent: triggerExtent,
          indicatorExtent: indicatorExtent,
        );
      },
    );
  }
}

class _WakingFaceIndicator extends StatefulWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double triggerExtent;
  final double indicatorExtent;

  const _WakingFaceIndicator({
    required this.refreshState,
    required this.pulledExtent,
    required this.triggerExtent,
    required this.indicatorExtent,
  });

  @override
  State<_WakingFaceIndicator> createState() => _WakingFaceIndicatorState();
}

class _WakingFaceIndicatorState extends State<_WakingFaceIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _wakeCtrl;
  late final AnimationController _zCtrl;

  @override
  void initState() {
    super.initState();
    _wakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _zCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat();
  }

  @override
  void didUpdateWidget(_WakingFaceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    final entering = widget.refreshState == RefreshIndicatorMode.refresh &&
        oldWidget.refreshState != RefreshIndicatorMode.refresh;
    if (entering) {
      _wakeCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _wakeCtrl.dispose();
    _zCtrl.dispose();
    super.dispose();
  }

  double _easeOut(double t) {
    final c = (1 - t).clamp(0.0, 1.0);
    return 1 - c * c * c;
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.triggerExtent <= 0
        ? 0.0
        : (widget.pulledExtent / widget.triggerExtent).clamp(0.0, 1.0);
    final dragOpen = _easeOut(progress);
    final isAwake = widget.refreshState == RefreshIndicatorMode.armed ||
        widget.refreshState == RefreshIndicatorMode.refresh;

    return AnimatedBuilder(
      animation: Listenable.merge([_wakeCtrl, _zCtrl]),
      builder: (ctx, _) {
        final wake = _wakeCtrl.value;
        final wakePulse = math.sin(wake * math.pi).clamp(0.0, 1.0);
        final bounce = isAwake ? 1 + wakePulse * 0.09 : 1.0;
        final eyeOpen = isAwake ? 1.0 : dragOpen;
        final smileExtra = isAwake ? wakePulse : 0.0;
        final zVisibility = (1 - dragOpen).clamp(0.0, 1.0) *
            (isAwake ? 0.0 : 1.0);

        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SizedBox(
              height: widget.indicatorExtent - 8,
              child: FittedBox(
                fit: BoxFit.contain,
                child: SizedBox(
                  width: 256,
                  height: 256,
                  child: Transform.scale(
                    scale: bounce,
                    child: CustomPaint(
                      painter: _FacePainter(
                        eyeOpen: eyeOpen,
                        zPhase: _zCtrl.value,
                        zVisibility: zVisibility,
                        smileExtra: smileExtra,
                      ),
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
  final double eyeOpen;
  final double zPhase;
  final double zVisibility;
  final double smileExtra;

  _FacePainter({
    required this.eyeOpen,
    required this.zPhase,
    required this.zVisibility,
    required this.smileExtra,
  });

  static const _faceColor = Color(0xFFFFD8B5);
  static const _cheekColor = Color(0xFFFF8A65);
  static const _strokeColor = Color(0xFF2D3142);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(
      const Offset(128, 128),
      116,
      Paint()..color = _faceColor,
    );

    _drawCheek(canvas, const Offset(68, 152));
    _drawCheek(canvas, const Offset(188, 152));

    _drawEye(canvas, const Offset(88, 112));
    _drawEye(canvas, const Offset(168, 112));

    _drawSmile(canvas);

    if (zVisibility > 0.01) {
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
    final closedOpacity = (1 - eyeOpen).clamp(0.0, 1.0);
    if (closedOpacity > 0.01) {
      final stroke = Paint()
        ..color = _strokeColor.withValues(alpha: closedOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(c.dx - 18, c.dy - 6)
        ..quadraticBezierTo(c.dx, c.dy + 10, c.dx + 18, c.dy - 6);
      canvas.drawPath(path, stroke);
    }

    final openOpacity = eyeOpen.clamp(0.0, 1.0);
    if (openOpacity > 0.01) {
      final r = 9 * openOpacity;
      final fill = Paint()
        ..color = _strokeColor.withValues(alpha: openOpacity);
      canvas.drawCircle(c, r, fill);
      if (openOpacity > 0.6) {
        final highlightAlpha = ((openOpacity - 0.6) / 0.4).clamp(0.0, 1.0);
        final highlight = Paint()
          ..color = CupertinoColors.white.withValues(alpha: highlightAlpha);
        canvas.drawCircle(c + const Offset(-2.6, -2.8), 2.4, highlight);
      }
    }
  }

  void _drawSmile(Canvas canvas) {
    final stroke = Paint()
      ..color = _strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final widen = 1 + smileExtra * 0.18;
    final w = 18 * widen;
    final dy = 14 * (1 + smileExtra * 0.45);
    final path = Path()
      ..moveTo(128 - w, 172)
      ..quadraticBezierTo(128, 172 + dy, 128 + w, 172);
    canvas.drawPath(path, stroke);
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
      final bob = math.sin(p * math.pi * 2) * 2.5;
      final rise = p * 10;
      // Gentle in/out so the Zs don't pop at the wrap.
      final fade = (math.sin(p * math.pi)).clamp(0.0, 1.0);
      final alpha = (zVisibility * (0.55 + 0.45 * fade)).clamp(0.0, 1.0);
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
      old.eyeOpen != eyeOpen ||
      old.zPhase != zPhase ||
      old.zVisibility != zVisibility ||
      old.smileExtra != smileExtra;
}
