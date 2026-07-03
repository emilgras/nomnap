import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/app_localizations.dart';
import '../models/tracker_kind.dart';
import '../theme/app_theme.dart';
import 'app_icons.dart';

/// The accent colour, soft background, icon and localized name for a tracker
/// kind. Shared so the customize sheet and onboarding present each tracker
/// identically.
class TrackerVisuals {
  final Color accent;
  final Color softBg;
  final Widget icon;
  final String Function(S) name;
  const TrackerVisuals({
    required this.accent,
    required this.softBg,
    required this.icon,
    required this.name,
  });
}

String trackerGroupName(S s, TrackerGroup group) {
  switch (group) {
    case TrackerGroup.food:
      return s.groupFood;
    case TrackerGroup.activity:
      return s.groupActivity;
    case TrackerGroup.growth:
      return s.groupGrowth;
  }
}

TrackerVisuals trackerVisuals(TrackerKind kind) {
  switch (kind) {
    case TrackerKind.sleep:
      return const TrackerVisuals(
        accent: AppColors.sleepAccent,
        softBg: AppColors.sleepSoft,
        icon: Icon(CupertinoIcons.moon_fill,
            color: AppColors.sleepAccent, size: 18),
        name: _sleepName,
      );
    case TrackerKind.feed:
      return const TrackerVisuals(
        accent: AppColors.feedAccent,
        softBg: AppColors.feedSoft,
        icon: Icon(CupertinoIcons.drop_fill,
            color: AppColors.feedAccent, size: 18),
        name: _feedName,
      );
    case TrackerKind.bottle:
      return const TrackerVisuals(
        accent: AppColors.bottleAccent,
        softBg: AppColors.bottleSoft,
        icon: BottleIcon(color: AppColors.bottleAccent, size: 16),
        name: _bottleName,
      );
    case TrackerKind.tube:
      return const TrackerVisuals(
        accent: AppColors.tubeAccent,
        softBg: AppColors.tubeSoft,
        icon: TubeIcon(color: AppColors.tubeAccent, size: 16),
        name: _tubeName,
      );
    case TrackerKind.diaper:
      return TrackerVisuals(
        accent: AppColors.diaperAccent,
        softBg: AppColors.diaperSoft,
        icon: Center(
          child: SvgPicture.asset(
            'assets/icons/poop.svg',
            width: 18,
            height: 18,
            colorFilter: const ColorFilter.mode(
                AppColors.diaperAccent, BlendMode.srcIn),
          ),
        ),
        name: _diaperName,
      );
    case TrackerKind.weight:
      return const TrackerVisuals(
        accent: AppColors.weightAccent,
        softBg: AppColors.weightSoft,
        icon: Icon(CupertinoIcons.gauge,
            color: AppColors.weightAccent, size: 18),
        name: _weightName,
      );
    case TrackerKind.length:
      return const TrackerVisuals(
        accent: AppColors.lengthAccent,
        softBg: AppColors.lengthSoft,
        icon: Icon(CupertinoIcons.resize_v,
            color: AppColors.lengthAccent, size: 18),
        name: _lengthName,
      );
    case TrackerKind.head:
      return const TrackerVisuals(
        accent: AppColors.headAccent,
        softBg: AppColors.headSoft,
        icon: Icon(CupertinoIcons.smiley,
            color: AppColors.headAccent, size: 18),
        name: _headName,
      );
  }
}

// Top-level tear-offs so the visuals can stay `const`.
String _sleepName(S s) => s.sleep;
String _feedName(S s) => s.feed;
String _bottleName(S s) => s.bottle;
String _tubeName(S s) => s.tube;
String _diaperName(S s) => s.diaper;
String _weightName(S s) => s.weight;
String _lengthName(S s) => s.length;
String _headName(S s) => s.headCirc;
