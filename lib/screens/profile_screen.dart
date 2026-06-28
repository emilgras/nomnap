import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../theme/app_theme.dart';
import '../widgets/sticky_header.dart';
import 'app_shell.dart' show kFloatingNavReserve;
import 'caregivers_screen.dart';

/// The "Profile" tab: account, sharing, backup and about — the home for
/// everything that isn't day-to-day tracking.
class ProfileScreen extends StatefulWidget {
  final EventStore store;
  const ProfileScreen({super.key, required this.store});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _openCaregivers() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (_) => const CaregiversScreen()),
    );
  }

  void _pickLanguage() {
    final s = S.of(context);
    final locale = LocaleScope.of(context);
    final current = locale.locale.languageCode;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(s.language),
        actions: [
          for (final code in S.languageCodes)
            CupertinoActionSheetAction(
              onPressed: () {
                locale.setLocale(Locale(code));
                Navigator.pop(ctx);
              },
              isDefaultAction: code == current,
              child: Text(S.languageNames[code] ?? code),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.cancel),
        ),
      ),
    );
  }

  Future<void> _pickDayStart() async {
    final s = S.of(context);
    final config = HomeConfigScope.of(context);
    int working = config.dayStartHour;
    final saved = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (ctx) => Container(
        height: 280,
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(s.cancel),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(s.dayStartTitle, style: AppText.headline),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        s.save,
                        style: AppText.headline
                            .copyWith(color: AppColors.sleepAccent),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: config.dayStartHour,
                  ),
                  itemExtent: 36,
                  onSelectedItemChanged: (i) => working = i,
                  children: [
                    for (var h = 0; h < 24; h++)
                      Center(child: Text(s.dayStartValue(h))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (saved == true) await config.setDayStartHour(working);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final config = HomeConfigScope.of(context);
    final topInset = MediaQuery.of(context).padding.top;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: StickyGlassHeader(
              topInset: topInset,
              title: StickyHeaderTitle(s.navProfile),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, kFloatingNavReserve),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _sectionLabel(s.profileAccount),
                _card([
                  _row(
                    icon: CupertinoIcons.device_phone_portrait,
                    title: s.profileThisDevice,
                    subtitle: s.profileThisDeviceSub,
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionLabel(s.profilePreferences),
                _card([
                  _row(
                    icon: CupertinoIcons.globe,
                    title: s.language,
                    subtitle: s.languageSub,
                    trailing: Text(
                      S.languageNames[s.localeCode] ?? 'English',
                      style: AppText.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: _pickLanguage,
                    chevron: true,
                  ),
                  _divider(),
                  _row(
                    icon: CupertinoIcons.clock,
                    title: s.dayStart,
                    subtitle: s.dayStartSub,
                    trailing: Text(
                      s.dayStartValue(config.dayStartHour),
                      style: AppText.body
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    onTap: _pickDayStart,
                    chevron: true,
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionLabel(s.profileSharing),
                _card([
                  _row(
                    icon: CupertinoIcons.person_2_fill,
                    title: s.caregivers,
                    subtitle: s.caregiversSub,
                    onTap: _openCaregivers,
                    chevron: true,
                  ),
                ]),
                const SizedBox(height: 24),
                _sectionLabel(s.profileAbout),
                _card([
                  _row(
                    icon: CupertinoIcons.heart_fill,
                    title: 'NomNap',
                    subtitle: s.appTagline,
                    trailing: Text('v1.0.0',
                        style: AppText.footnote
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Text(
          text,
          style: AppText.body.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _divider() => Container(
        margin: const EdgeInsets.only(left: 50),
        height: 0.5,
        color: AppColors.divider,
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      );

  Widget _row({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    bool chevron = false,
    bool enabled = true,
  }) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(icon,
              size: 22,
              color: enabled
                  ? AppColors.sleepAccent
                  : AppColors.textSecondary.withValues(alpha: 0.5)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppText.body.copyWith(
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppText.footnote
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing],
          if (chevron)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Icon(CupertinoIcons.chevron_forward,
                  size: 16,
                  color: AppColors.textSecondary.withValues(alpha: 0.6)),
            ),
        ],
      ),
    );
    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
