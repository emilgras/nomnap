import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/baby_profile_service.dart';
import 'services/event_store.dart';
import 'services/home_config.dart';
import 'services/household_service.dart';
import 'services/persistent_storage.dart';
import 'services/session_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  // Run everything inside a guarded zone so that even errors thrown outside the
  // Flutter framework's own callbacks (async gaps, stream listeners) are caught
  // and reported instead of silently terminating the isolate.
  runZonedGuarded(_bootstrap, (error, stack) {
    FlutterError.presentError(
      FlutterErrorDetails(exception: error, stack: stack),
    );
    unawaited(_reportError(error, stack, fatal: true));
  });
}

Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('da');

  final localeProvider = LocaleProvider();
  await localeProvider.load();
  final homeConfig = HomeConfig();
  await homeConfig.load();
  unawaited(requestPersistentStorage());

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Route uncaught framework + platform errors to Crashlytics so we have
    // visibility into failures in the field. Disabled in debug to keep noise
    // out of the dashboard. Wrapped so a Crashlytics hiccup can never block
    // startup.
    try {
      await FirebaseCrashlytics.instance
          .setCrashlyticsCollectionEnabled(!kDebugMode);
    } catch (_) {/* non-fatal */}
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (!kDebugMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(details);
      }
    };
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      unawaited(_reportError(error, stack, fatal: true));
      return true;
    };

    // Silent anonymous account → stable uid for membership/rules.
    final auth = AuthService();
    final user = await auth.ensureSignedIn();

    // Resolve (or create on first run) the household that owns this baby.
    final households = HouseholdService();
    final householdId = await households.ensureHousehold(user.uid);

    // Lift any pre-existing local-only events into the cloud, once.
    await EventStore.migrateLegacyLocalEvents(_eventsCollection(householdId));

    runApp(NomNapApp(
      localeProvider: localeProvider,
      homeConfig: homeConfig,
      auth: auth,
      uid: user.uid,
      initialHouseholdId: householdId,
      households: households,
    ));
  } catch (e, stack) {
    // First launch needs connectivity to create the anonymous account; if that
    // fails we show a recoverable message rather than crashing.
    unawaited(_reportError(e, stack, fatal: false));
    runApp(_StartupErrorApp(localeProvider: localeProvider, error: e));
  }
}

/// Records an error to Crashlytics when collection is available. Guarded so a
/// reporting failure (e.g. Crashlytics not yet initialized) never masks the
/// original error.
Future<void> _reportError(Object error, StackTrace? stack,
    {required bool fatal}) async {
  if (kDebugMode) return;
  try {
    await FirebaseCrashlytics.instance.recordError(error, stack, fatal: fatal);
  } catch (_) {
    // Nothing more we can do; the error was already surfaced to the console.
  }
}

CollectionReference<Map<String, dynamic>> _eventsCollection(String hid) =>
    FirebaseFirestore.instance
        .collection('households')
        .doc(hid)
        .collection('events');

/// Root of the app. Owns the [EventStore] lifecycle so it can rebuild it when
/// the active household changes (e.g. after joining one via an invite), giving
/// a live data swap with no restart.
class NomNapApp extends StatefulWidget {
  final LocaleProvider localeProvider;
  final HomeConfig homeConfig;
  final AuthService auth;
  final String uid;
  final String initialHouseholdId;
  final HouseholdService households;
  const NomNapApp({
    super.key,
    required this.localeProvider,
    required this.homeConfig,
    required this.auth,
    required this.uid,
    required this.initialHouseholdId,
    required this.households,
  });

  @override
  State<NomNapApp> createState() => _NomNapAppState();
}

class _NomNapAppState extends State<NomNapApp> {
  late String _householdId;
  late String _uid;
  // Whether this device owns the current household. Owners (admins) can wipe
  // the shared data; caregivers who joined via an invite can only leave.
  bool _isOwner = true;
  EventStore? _store;
  BabyProfileService? _profile;

  @override
  void initState() {
    super.initState();
    _householdId = widget.initialHouseholdId;
    _uid = widget.uid;
    _bindStore(_householdId);
  }

  Future<void> _bindStore(String hid) async {
    final oldStore = _store;
    final oldProfile = _profile;
    if (mounted) {
      setState(() {
        _store = null; // brief loader while swapping
        _profile = null;
      });
    }
    oldStore?.dispose();
    oldProfile?.dispose();
    final store = EventStore(_eventsCollection(hid));
    final profile = BabyProfileService(householdId: hid);
    await store.load();
    await profile.load();
    // Resolve this device's role in the household so the profile screen can
    // gate data deletion to the owner. Defaults to caregiver if it can't be
    // read (least-privilege), so a lookup hiccup can never grant wipe rights.
    final role = await widget.households.memberRole(hid, _uid);
    if (!mounted) {
      store.dispose();
      profile.dispose();
      return;
    }
    setState(() {
      _householdId = hid;
      _store = store;
      _profile = profile;
      _isOwner = role == 'owner';
    });
  }

  /// Called from the caregivers screen after joining another household.
  Future<void> _switchHousehold(String newHouseholdId) async {
    if (newHouseholdId == _householdId) return;
    await _bindStore(newHouseholdId);
  }

  /// Removes this device's profile and bootstraps a fresh, empty one so the app
  /// stays usable. Invoked from the profile screen behind a confirmation.
  ///
  /// Only the owner (admin) wipes the shared baby's data; a caregiver who
  /// joined via an invite simply leaves, so the data stays for everyone else.
  /// Ordering matters: everything needing the current identity (deleting
  /// events, leaving the household) happens *before* the account is deleted.
  Future<void> _deleteProfile() async {
    // 1) Only the owner may wipe the shared tracked data.
    if (_isOwner) await _store?.clearAll();

    // 2) Leave the household (drop this device's membership). Best-effort —
    //    a fresh household is created below regardless.
    try {
      await widget.households.removeMember(_householdId, _uid);
    } catch (_) {/* non-fatal */}

    // 3) Forget the cached household so ensureHousehold() makes a new one.
    await widget.households.clearActiveHousehold();

    // 4) Delete the anonymous account last, so the writes above still had auth.
    try {
      await widget.auth.deleteAccount();
    } catch (_) {/* non-fatal; the sign-in below still refreshes identity */}

    // 5) Start over with a brand-new empty profile.
    final user = await widget.auth.ensureSignedIn();
    final newHid = await widget.households.ensureHousehold(user.uid);
    if (!mounted) return;
    setState(() => _uid = user.uid);
    await _bindStore(newHid);
  }

  @override
  void dispose() {
    _store?.dispose();
    _profile?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    final profile = _profile;
    return SessionScope(
      uid: _uid,
      householdId: _householdId,
      households: widget.households,
      isOwner: _isOwner,
      switchHousehold: _switchHousehold,
      deleteProfile: _deleteProfile,
      child: HomeConfigScope(
        config: widget.homeConfig,
        child: _MaybeProfileScope(
          service: profile,
          child: LocaleScope(
          provider: widget.localeProvider,
          child: ListenableBuilder(
            listenable: widget.localeProvider,
            builder: (context, _) => CupertinoApp(
              title: 'NomNap',
              debugShowCheckedModeBanner: false,
              locale: widget.localeProvider.locale,
              supportedLocales: S.supportedLocales,
              localizationsDelegates: const [
                S.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              theme: const CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: AppColors.sleepAccent,
                scaffoldBackgroundColor: AppColors.background,
                barBackgroundColor: AppColors.surface,
                textTheme: CupertinoTextThemeData(
                  primaryColor: AppColors.textPrimary,
                  textStyle: AppText.body,
                  navTitleTextStyle: AppText.headline,
                  navLargeTitleTextStyle: AppText.largeTitle,
                ),
              ),
              // Keyed by household so switching forces a fresh AppShell subtree
              // that re-subscribes its screens to the new store.
              home: (store == null || profile == null)
                  ? const CupertinoPageScaffold(
                      backgroundColor: AppColors.background,
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : AppShell(key: ValueKey(_householdId), store: store),
            ),
          ),
          ),
        ),
      ),
    );
  }
}

/// Wraps [child] in a [BabyProfileScope] once the per-household profile service
/// is ready. While it's still binding ([service] == null) the child is shown
/// without the scope — the app root is displaying its loader at that point, so
/// nothing below actually reads the profile yet.
class _MaybeProfileScope extends StatelessWidget {
  final BabyProfileService? service;
  final Widget child;
  const _MaybeProfileScope({required this.service, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = service;
    if (s == null) return child;
    return BabyProfileScope(service: s, child: child);
  }
}

/// Shown when Firebase init / first sign-in fails (typically no network on the
/// very first launch). Lets the user retry by relaunching.
class _StartupErrorApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  final Object error;
  const _StartupErrorApp({required this.localeProvider, required this.error});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      supportedLocales: S.supportedLocales,
      localizationsDelegates: const [
        S.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: CupertinoPageScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(CupertinoIcons.wifi_slash,
                    size: 48, color: AppColors.textSecondary),
                const SizedBox(height: 16),
                Text(
                  'Couldn’t connect',
                  style: AppText.headline,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'NomNap needs an internet connection the first time it starts. '
                  'Please connect and reopen the app.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
