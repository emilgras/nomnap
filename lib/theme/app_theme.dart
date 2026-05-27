import 'package:flutter/cupertino.dart';

/// iOS-style design tokens. Light, calm, professional.
class AppColors {
  // Backgrounds
  static const background = Color(0xFFF7F7F8); // iOS systemGroupedBackground-ish
  static const surface = CupertinoColors.white;
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF111114);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFFAEAEB2);

  // Dividers / borders
  static const divider = Color(0xFFE5E5EA);

  // Accents — kept restrained
  static const sleepAccent = Color(0xFF5B6CFF);   // calm indigo
  static const sleepSoft = Color(0xFFEEF0FF);
  static const feedAccent = Color(0xFFFF8A65);    // warm coral
  static const feedSoft = Color(0xFFFFF1EC);
  static const diaperAccent = Color(0xFF43A692);  // teal green
  static const diaperSoft = Color(0xFFE8F5F1);

  // Status
  static const success = Color(0xFF34C759);
  static const danger = Color(0xFFFF3B30);
}

class AppText {
  static const largeTitle = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const title = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    color: AppColors.textPrimary,
  );

  static const headline = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 17,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const callout = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const subhead = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const footnote = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const caption = TextStyle(
    fontFamily: '.SF Pro Text',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textTertiary,
  );

  static const timerLarge = TextStyle(
    fontFamily: '.SF Pro Display',
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class AppRadius {
  static const small = 10.0;
  static const card = 16.0;
  static const button = 14.0;
  static const large = 22.0;
}
