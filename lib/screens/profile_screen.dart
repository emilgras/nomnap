import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../models/baby_profile.dart';
import '../services/baby_profile_service.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../services/session_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/async_action.dart';
import '../widgets/sticky_header.dart';
import 'app_shell.dart' show kFloatingNavReserve;
import 'caregivers_screen.dart';
import 'onboarding_flow.dart';

/// The "Profile" tab: account, sharing, backup and about — the home for
/// everything that isn't day-to-day tracking.
class ProfileScreen extends StatefulWidget {
  final EventStore store;
  const ProfileScreen({super.key, required this.store});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _deleting = false;

  Future<void> _confirmDeleteProfile() async {
    final s = S.of(context);
    final session = SessionScope.of(context);
    // Owners (admins) wipe the shared baby's data; caregivers only leave and
    // remove their own profile, so the wording and consequences differ.
    final isOwner = session.isOwner;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: Text(isOwner ? s.deleteProfileTitle : s.leaveProfileTitle),
        content:
            Text(isOwner ? s.deleteProfileMessage : s.leaveProfileMessage),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
                isOwner ? s.deleteProfileConfirm : s.leaveProfileConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    // On success the whole app subtree is rebuilt onto a fresh household, so
    // this screen is disposed — no need to reset _deleting in that case.
    final ok = await runGuarded(context, session.deleteProfile,
        errorMessage: s.errUpdate);
    if (!ok && mounted) setState(() => _deleting = false);
  }

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

  void _openBabyProfile() {
    final profileService = BabyProfileScope.of(context);
    OnboardingFlow.show(
      context,
      store: widget.store,
      initial: profileService.profile,
      isEditing: true,
    );
  }

  /// The baby-profile row for the top of the tab: a "finish setup" prompt when
  /// nothing has been entered yet, or the baby's name + age + sex once it has.
  Widget _babyRow(S s, BabyProfileService service) {
    final p = service.profile;
    if (p.isEmpty) {
      return _row(
        icon: CupertinoIcons.person_crop_circle_badge_plus,
        title: service.onboardingComplete
            ? s.profileBabyDetails
            : s.profileFinishSetup,
        subtitle: service.onboardingComplete
            ? s.profileAddDetails
            : s.profileFinishSetupSub,
        onTap: _openBabyProfile,
        chevron: true,
      );
    }
    final parts = <String>[
      if (p.birthDate != null && s.formatAge(p.birthDate!).isNotEmpty)
        s.formatAge(p.birthDate!),
      if (p.sex != null) (p.sex == Sex.boy ? s.sexBoy : s.sexGirl),
    ];
    return _row(
      icon: CupertinoIcons.person_crop_circle,
      title: p.hasName ? p.name : s.profileBabyDetails,
      subtitle: parts.isEmpty ? null : parts.join('  ·  '),
      onTap: _openBabyProfile,
      chevron: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final config = HomeConfigScope.of(context);
    final babyProfile = BabyProfileScope.of(context);
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
                _sectionLabel(s.profileBaby),
                _card([_babyRow(s, babyProfile)]),
                const SizedBox(height: 24),
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
                const SizedBox(height: 24),
                _sectionLabel(s.profileData),
                _card([_deleteRow(s)]),
                // Debug-only: replay the full first-run onboarding (all 8
                // pages, incl. language/track/measurements). Never in release.
                if (kDebugMode) ...[
                  const SizedBox(height: 24),
                  _sectionLabel('DEBUG'),
                  _card([
                    _row(
                      icon: CupertinoIcons.arrow_counterclockwise_circle,
                      title: 'Replay onboarding',
                      subtitle: 'Opens the full first-run flow',
                      onTap: () =>
                          OnboardingFlow.show(context, store: widget.store),
                      chevron: true,
                    ),
                  ]),
                ],
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

  /// A destructive row that removes this profile. For an owner it wipes the
  /// shared data ("Delete profile & data"); for a caregiver it only leaves the
  /// household ("Leave & delete profile"). Shows a spinner while it runs.
  Widget _deleteRow(S s) {
    final isOwner = SessionScope.of(context).isOwner;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(isOwner ? CupertinoIcons.trash : CupertinoIcons.square_arrow_right,
              size: 22, color: AppColors.danger),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isOwner ? s.deleteProfile : s.leaveProfile,
                    style: AppText.body.copyWith(color: AppColors.danger)),
                const SizedBox(height: 2),
                Text(isOwner ? s.deleteProfileSub : s.leaveProfileSub,
                    style: AppText.footnote
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (_deleting)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: CupertinoActivityIndicator(),
            ),
        ],
      ),
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _deleting ? null : _confirmDeleteProfile,
      child: content,
    );
  }
}
