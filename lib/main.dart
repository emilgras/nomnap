import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/event_store.dart';
import 'services/home_config.dart';
import 'services/household_service.dart';
import 'services/persistent_storage.dart';
import 'services/session_scope.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
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
      uid: user.uid,
      initialHouseholdId: householdId,
      households: households,
    ));
  } catch (e) {
    // First launch needs connectivity to create the anonymous account; if that
    // fails we show a recoverable message rather than crashing.
    runApp(_StartupErrorApp(localeProvider: localeProvider, error: e));
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
  final String uid;
  final String initialHouseholdId;
  final HouseholdService households;
  const NomNapApp({
    super.key,
    required this.localeProvider,
    required this.homeConfig,
    required this.uid,
    required this.initialHouseholdId,
    required this.households,
  });

  @override
  State<NomNapApp> createState() => _NomNapAppState();
}

class _NomNapAppState extends State<NomNapApp> {
  late String _householdId;
  EventStore? _store;

  @override
  void initState() {
    super.initState();
    _householdId = widget.initialHouseholdId;
    _bindStore(_householdId);
  }

  Future<void> _bindStore(String hid) async {
    final old = _store;
    if (mounted) setState(() => _store = null); // brief loader while swapping
    old?.dispose();
    final store = EventStore(_eventsCollection(hid));
    await store.load();
    if (!mounted) {
      store.dispose();
      return;
    }
    setState(() {
      _householdId = hid;
      _store = store;
    });
  }

  /// Called from the caregivers screen after joining another household.
  Future<void> _switchHousehold(String newHouseholdId) async {
    if (newHouseholdId == _householdId) return;
    await _bindStore(newHouseholdId);
  }

  @override
  void dispose() {
    _store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = _store;
    return SessionScope(
      uid: widget.uid,
      householdId: _householdId,
      households: widget.households,
      switchHousehold: _switchHousehold,
      child: HomeConfigScope(
        config: widget.homeConfig,
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
              home: store == null
                  ? const CupertinoPageScaffold(
                      backgroundColor: AppColors.background,
                      child: Center(child: CupertinoActivityIndicator()),
                    )
                  : AppShell(key: ValueKey(_householdId), store: store),
            ),
          ),
        ),
      ),
    );
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
