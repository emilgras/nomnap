import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../l10n/locale_provider.dart';
import '../models/baby_event.dart';
import '../models/baby_profile.dart';
import '../models/tracker_kind.dart';
import '../services/baby_profile_service.dart';
import '../services/event_store.dart';
import '../services/home_config.dart';
import '../theme/app_theme.dart';
import '../widgets/tracker_visuals.dart';

/// The steps shown in the onboarding flow. First run walks the full set;
/// editing an existing profile shows only the data-entry steps.
enum _Step { welcome, name, birth, sex, feeding, track, measure, done }

/// First-run (and "finish setup") onboarding: a short, skippable paged flow
/// that captures the baby's name, birth date, sex, feeding method and optional
/// birth measurements.
///
/// Everything is optional — a top-right **Skip** abandons the flow at any
/// point, and each field can be left blank. The captured profile is shared
/// across caregivers (stored on the household doc via [BabyProfileService]);
/// birth measurements become real growth events at the birth date; the feeding
/// method pre-selects the relevant feed trackers.
class OnboardingFlow extends StatefulWidget {
  final EventStore store;
  final BabyProfile initial;
  final bool isEditing;

  const OnboardingFlow({
    super.key,
    required this.store,
    this.initial = const BabyProfile(),
    this.isEditing = false,
  });

  /// Presents the flow as a full-screen route. Use [isEditing] (with [initial]
  /// pre-filled) when reopening it from the Profile tab to change details.
  static Future<void> show(
    BuildContext context, {
    required EventStore store,
    BabyProfile initial = const BabyProfile(),
    bool isEditing = false,
  }) {
    return Navigator.of(context).push(
      CupertinoPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => OnboardingFlow(
          store: store,
          initial: initial,
          isEditing: isEditing,
        ),
      ),
    );
  }

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  late final List<_Step> _steps = widget.isEditing
      ? const [_Step.name, _Step.birth, _Step.sex, _Step.feeding]
      : const [
          _Step.welcome,
          _Step.name,
          _Step.birth,
          _Step.sex,
          _Step.feeding,
          _Step.track,
          _Step.measure,
          _Step.done,
        ];

  /// The trackers the user wants on their home page. Seeded from the current
  /// home config on first build, nudged by the feeding step, then written back
  /// to [HomeConfig] on finish. Null until seeded.
  Set<TrackerKind>? _selectedTrackers;

  final _pageController = PageController();
  int _index = 0;

  late final TextEditingController _nameController =
      TextEditingController(text: widget.initial.name);
  final _nameFocus = FocusNode();
  final _weightController = TextEditingController();
  final _lengthController = TextEditingController();
  final _headController = TextEditingController();

  late DateTime _birthDate = widget.initial.birthDate ?? _today();
  late Sex? _sex = widget.initial.sex;
  late FeedingMethod? _feeding = widget.initial.feeding;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  _Step get _current => _steps[_index];
  bool get _isLast => _index == _steps.length - 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Seed the tracker selection from what's currently on the home page (the
    // defaults on a fresh install), once the config scope is available.
    _selectedTrackers ??= HomeConfigScope.of(context).enabledInOrder.toSet();
  }

  /// Records the feeding choice and nudges the tracker selection to match, so
  /// the "what to track" step arrives with the right feed trackers pre-ticked.
  void _selectFeeding(FeedingMethod method) {
    setState(() {
      _feeding = method;
      final sel = _selectedTrackers;
      if (sel == null) return;
      switch (method) {
        case FeedingMethod.breast:
          sel.add(TrackerKind.feed);
          sel.remove(TrackerKind.bottle);
          break;
        case FeedingMethod.bottle:
          sel.add(TrackerKind.bottle);
          sel.remove(TrackerKind.feed);
          break;
        case FeedingMethod.mixed:
          sel.add(TrackerKind.feed);
          sel.add(TrackerKind.bottle);
          break;
      }
    });
  }

  void _toggleTracker(TrackerKind kind) {
    final sel = _selectedTrackers;
    if (sel == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!sel.remove(kind)) sel.add(kind);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _nameFocus.dispose();
    _weightController.dispose();
    _lengthController.dispose();
    _headController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (_isLast) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    await _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    // Pop the keyboard only once the page has settled — focusing mid-swipe
    // resizes the viewport during the animation and garbles the layout.
    if (_steps[_index] == _Step.name) _nameFocus.requestFocus();
  }

  void _back() {
    FocusScope.of(context).unfocus();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  BabyProfile _collect({required bool includeBirthDate}) => BabyProfile(
        name: _nameController.text.trim(),
        birthDate: includeBirthDate ? _birthDate : null,
        sex: _sex,
        feeding: _feeding,
      );

  Future<void> _finish() async {
    final navigator = Navigator.of(context);
    final profileService = BabyProfileScope.of(context);
    final config = HomeConfigScope.of(context);

    await profileService.save(_collect(includeBirthDate: true));
    if (!widget.isEditing) {
      await _applyTrackerSelection(config);
      await _logBirthMeasurements();
    }
    await profileService.markOnboardingComplete();

    HapticFeedback.mediumImpact();
    if (mounted) navigator.pop();
  }

  Future<void> _skip() async {
    final navigator = Navigator.of(context);
    final profileService = BabyProfileScope.of(context);

    // Keep anything already entered so a skip late in the flow isn't wasted;
    // only trust the birth date if the user actually reached that step. The
    // home layout is left at its defaults — skipping means "dive right in".
    final birthIdx = _steps.indexOf(_Step.birth);
    final partial = _collect(includeBirthDate: _index > birthIdx);
    if (!partial.isEmpty) await profileService.save(partial);
    await profileService.markOnboardingComplete();

    if (mounted) navigator.pop();
  }

  /// Applies the chosen trackers to the home page, writing only the ones whose
  /// visibility actually changed.
  Future<void> _applyTrackerSelection(HomeConfig config) async {
    final sel = _selectedTrackers;
    if (sel == null) return;
    final currentlyEnabled = config.enabledInOrder.toSet();
    for (final kind in TrackerKind.values) {
      final want = sel.contains(kind);
      if (want != currentlyEnabled.contains(kind)) {
        await config.setEnabled(kind, want);
      }
    }
  }

  Future<void> _logBirthMeasurements() async {
    Future<void> log(TextEditingController c, EventType type, String unit) async {
      final raw = c.text.trim().replaceAll(',', '.');
      final value = double.tryParse(raw);
      if (value == null || value <= 0) return;
      await widget.store.add(type, at: _birthDate, meta: {
        'value': raw,
        'unit': unit,
      });
    }

    await log(_weightController, EventType.weight, 'g');
    await log(_lengthController, EventType.length, 'cm');
    await log(_headController, EventType.headCirc, 'cm');
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final showSkip = !widget.isEditing && _current != _Step.done;
    // No manual viewInsets here: CupertinoPageScaffold already resizes for the
    // keyboard, so adding them again would push the content off-screen.
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            _topBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                children: [for (final step in _steps) _buildStep(s, step)],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _primaryButton(
                    label: _isLast
                        ? (widget.isEditing ? s.save : s.onboardingStart)
                        : s.onboardingContinue,
                    onPressed: _next,
                  ),
                  // Understated skip below the primary button. Reserves its
                  // height even when hidden so the layout never jumps.
                  SizedBox(
                    height: 44,
                    child: showSkip
                        ? CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _skip,
                            child: Text(
                              s.onboardingSkip,
                              style: AppText.subhead.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    final showBack = _index > 0;
    final showClose = widget.isEditing && _index == 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Align(
              alignment: Alignment.centerLeft,
              child: (showBack || showClose)
                  ? CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(44, 44),
                      onPressed: showBack
                          ? _back
                          : () => Navigator.of(context).pop(),
                      child: Icon(
                        showBack
                            ? CupertinoIcons.chevron_back
                            : CupertinoIcons.xmark,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    )
                  : null,
            ),
          ),
          Expanded(child: Center(child: _dots())),
          const SizedBox(width: 64),
        ],
      ),
    );
  }

  Widget _dots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _steps.length; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            width: i == _index ? 20 : 7,
            height: 7,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: i == _index
                  ? AppColors.sleepAccent
                  : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }

  Widget _primaryButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadius.button),
        color: AppColors.sleepAccent,
        onPressed: onPressed,
        child: Text(
          label,
          style: AppText.headline.copyWith(color: CupertinoColors.white),
        ),
      ),
    );
  }

  Widget _buildStep(S s, _Step step) {
    switch (step) {
      case _Step.welcome:
        return _welcomeStep(s);
      case _Step.name:
        return _nameStep(s);
      case _Step.birth:
        return _birthStep(s);
      case _Step.sex:
        return _sexStep(s);
      case _Step.feeding:
        return _feedingStep(s);
      case _Step.track:
        return _trackStep(s);
      case _Step.measure:
        return _measureStep(s);
      case _Step.done:
        return _doneStep(s);
    }
  }

  /// Shared scaffold for a step: a large emoji, a title, an optional subtitle,
  /// and the step's content, all comfortably centred and scrollable.
  Widget _stepScaffold({
    required String emoji,
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.sleepSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 20),
          Text(title, style: AppText.title, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Text(
              subtitle,
              style: AppText.subhead,
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget _welcomeStep(S s) {
    final locale = LocaleScope.of(context);
    final current = locale.locale.languageCode;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const _WelcomeHero(),
          const SizedBox(height: 24),
          Text(
            s.onboardingWelcomeTitle,
            style: AppText.title.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            s.onboardingWelcomeBody,
            style: AppText.subhead.copyWith(fontSize: 16, height: 1.45),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Center(
            child: Text(
              s.language,
              style: AppText.footnote.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final code in S.languageCodes)
                _chip(
                  label: S.languageNames[code] ?? code,
                  selected: code == current,
                  onTap: () => locale.setLocale(Locale(code)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nameStep(S s) {
    return _stepScaffold(
      emoji: '📝',
      title: s.onboardingNameTitle,
      child: CupertinoTextField(
        controller: _nameController,
        focusNode: _nameFocus,
        textCapitalization: TextCapitalization.words,
        textAlign: TextAlign.center,
        placeholder: s.onboardingNamePlaceholder,
        style: AppText.title,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _next(),
      ),
    );
  }

  Widget _birthStep(S s) {
    final name = _nameController.text.trim();
    return _stepScaffold(
      emoji: '🎂',
      title: name.isEmpty
          ? s.onboardingBirthTitle
          : s.onboardingBirthTitleNamed(name),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        clipBehavior: Clip.antiAlias,
        height: 216,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: _birthDate,
          minimumDate: DateTime(DateTime.now().year - 5),
          maximumDate: _today(),
          onDateTimeChanged: (d) =>
              _birthDate = DateTime(d.year, d.month, d.day),
        ),
      ),
    );
  }

  Widget _sexStep(S s) {
    return _stepScaffold(
      emoji: '🌷',
      title: s.onboardingSexTitle,
      child: Row(
        children: [
          Expanded(
            child: _bigChoice(
              emoji: '👦',
              label: s.sexBoy,
              accent: AppColors.lengthAccent,
              selected: _sex == Sex.boy,
              onTap: () => setState(() => _sex = Sex.boy),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _bigChoice(
              emoji: '👧',
              label: s.sexGirl,
              accent: AppColors.weightAccent,
              selected: _sex == Sex.girl,
              onTap: () => setState(() => _sex = Sex.girl),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feedingStep(S s) {
    Widget option(FeedingMethod m, String emoji, String label) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _rowChoice(
            emoji: emoji,
            label: label,
            selected: _feeding == m,
            onTap: () => _selectFeeding(m),
          ),
        );
    return _stepScaffold(
      emoji: '🍼',
      title: s.onboardingFeedingTitle,
      subtitle: s.onboardingFeedingBody,
      child: Column(
        children: [
          option(FeedingMethod.breast, '🤱', s.feedingBreast),
          option(FeedingMethod.bottle, '🍼', s.feedingBottle),
          option(FeedingMethod.mixed, '🔄', s.feedingMixed),
        ],
      ),
    );
  }

  Widget _trackStep(S s) {
    final sel = _selectedTrackers ?? const <TrackerKind>{};
    return _stepScaffold(
      emoji: '✅',
      title: s.onboardingTrackTitle,
      subtitle: s.onboardingTrackBody,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final group in TrackerGroup.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  trackerGroupName(s, group).toUpperCase(),
                  style: AppText.caption.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            for (final kind in TrackerKind.values.where((k) => k.group == group))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _trackerCheckRow(s, kind, sel.contains(kind)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _trackerCheckRow(S s, TrackerKind kind, bool selected) {
    final v = trackerVisuals(kind);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleTracker(kind),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? v.accent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: v.softBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: v.icon,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(v.name(s), style: AppText.headline)),
            Icon(
              selected
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.circle,
              color: selected ? v.accent : AppColors.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _measureStep(S s) {
    return _stepScaffold(
      emoji: '📏',
      title: s.onboardingMeasureTitle,
      subtitle: s.onboardingMeasureBody,
      child: Column(
        children: [
          _measureField(s.measureWeight, _weightController, s.gramsUnit,
              allowDecimal: false),
          const SizedBox(height: 12),
          _measureField(s.measureLength, _lengthController, s.cmUnit,
              allowDecimal: true),
          const SizedBox(height: 12),
          _measureField(s.measureHead, _headController, s.cmUnit,
              allowDecimal: true),
        ],
      ),
    );
  }

  Widget _doneStep(S s) {
    final name = _nameController.text.trim();
    return _stepScaffold(
      emoji: '🎉',
      title: s.onboardingDoneTitle,
      subtitle: name.isEmpty ? s.onboardingDoneBody : '$name 💜',
      child: const SizedBox.shrink(),
    );
  }

  // ── Small building blocks ──────────────────────────────────────────────

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.sleepAccent : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.sleepAccent : AppColors.divider,
          ),
        ),
        child: Text(
          label,
          style: AppText.callout.copyWith(
            color: selected ? CupertinoColors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _bigChoice({
    required String emoji,
    required String label,
    required Color accent,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? accent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppText.headline.copyWith(
                color: selected ? accent : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rowChoice({
    required String emoji,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.sleepAccent.withValues(alpha: 0.12)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: selected ? AppColors.sleepAccent : AppColors.divider,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected
                      ? AppColors.sleepAccent
                      : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(CupertinoIcons.checkmark_circle_fill,
                  color: AppColors.sleepAccent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _measureField(
    String label,
    TextEditingController controller,
    String unit, {
    required bool allowDecimal,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          child: Text(label, style: AppText.body),
        ),
        Expanded(
          child: CupertinoTextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(
                allowDecimal ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
              ),
              LengthLimitingTextInputFormatter(5),
            ],
            placeholder: allowDecimal ? '—' : '—',
            textAlign: TextAlign.center,
            style: AppText.headline,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.small),
              border: Border.all(color: AppColors.divider),
            ),
            suffix: Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Text(unit, style: AppText.subhead),
            ),
          ),
        ),
      ],
    );
  }
}

/// The welcome page's hero: a baby in a soft gradient circle with a few
/// floating hearts and stars around it — warm and hyggelig, no assets needed.
class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 220,
        height: 150,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 116,
              height: 116,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.sleepSoft, AppColors.feedSoft],
                ),
              ),
              alignment: Alignment.center,
              child: const Text('👶', style: TextStyle(fontSize: 54)),
            ),
            const Align(
              alignment: Alignment(0.55, -0.85),
              child: Text('💜', style: TextStyle(fontSize: 24)),
            ),
            const Align(
              alignment: Alignment(-0.62, -0.5),
              child: Text('😴', style: TextStyle(fontSize: 20)),
            ),
            const Align(
              alignment: Alignment(0.72, 0.5),
              child: Text('🍼', style: TextStyle(fontSize: 20)),
            ),
            const Align(
              alignment: Alignment(-0.5, 0.8),
              child: Text('✨', style: TextStyle(fontSize: 17)),
            ),
          ],
        ),
      ),
    );
  }
}
