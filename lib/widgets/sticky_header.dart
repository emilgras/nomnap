import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// Shared sticky frosted-glass header used at the top of each top-level screen.
/// Accepts an arbitrary [title] widget (so the Tracker screen can pass its
/// logo + wordmark composition) and an optional [trailing] widget such as an
/// add or trash button. Title and trailing are vertically centered together.
class StickyGlassHeader extends SliverPersistentHeaderDelegate {
  final double topInset;
  final Widget title;
  final Widget? trailing;

  static const double contentHeight = 72;

  const StickyGlassHeader({
    required this.topInset,
    required this.title,
    this.trailing,
  });

  @override
  double get minExtent => contentHeight + topInset;
  @override
  double get maxExtent => contentHeight + topInset;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: CupertinoColors.white.withValues(alpha: 0.72),
            border: Border(
              bottom: BorderSide(
                color: AppColors.divider
                    .withValues(alpha: overlapsContent ? 1.0 : 0.4),
                width: 0.5,
              ),
            ),
          ),
          padding: EdgeInsets.only(top: topInset),
          child: SizedBox(
            height: contentHeight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 12, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: title,
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickyGlassHeader old) =>
      old.topInset != topInset ||
      old.title != title ||
      old.trailing != trailing;
}

/// Default text title used by Stats / History — visually consistent with
/// Cupertino's large-title metrics but living inside our glass header.
class StickyHeaderTitle extends StatelessWidget {
  final String text;
  const StickyHeaderTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: '.SF Pro Display',
        fontSize: 30,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        color: AppColors.textPrimary,
      ),
    );
  }
}
