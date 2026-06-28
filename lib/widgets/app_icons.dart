import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// A tintable SVG asset rendered like a regular [Icon].
class _SvgIcon extends StatelessWidget {
  final String asset;
  final Color color;
  final double size;
  const _SvgIcon(this.asset, {required this.color, required this.size});

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        asset,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
}

/// Custom baby-bottle icon for the bottle feed tracker.
class BottleIcon extends StatelessWidget {
  final Color color;
  final double size;
  const BottleIcon({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) =>
      _SvgIcon('assets/icons/bottle.svg', color: color, size: size);
}

/// Custom syringe/feeding-tube icon for the tube feed tracker.
class TubeIcon extends StatelessWidget {
  final Color color;
  final double size;
  const TubeIcon({super.key, required this.color, required this.size});

  @override
  Widget build(BuildContext context) =>
      _SvgIcon('assets/icons/tube.svg', color: color, size: size);
}
