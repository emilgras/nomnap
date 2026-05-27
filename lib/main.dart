import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'screens/app_shell.dart';
import 'services/event_store.dart';
import 'services/persistent_storage.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await initializeDateFormatting('da');
  final store = EventStore();
  await store.load();
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  unawaited(requestPersistentStorage());
  runApp(NomNapApp(store: store, localeProvider: localeProvider));
}

class NomNapApp extends StatelessWidget {
  final EventStore store;
  final LocaleProvider localeProvider;
  const NomNapApp({super.key, required this.store, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    return LocaleScope(
      provider: localeProvider,
      child: ListenableBuilder(
        listenable: localeProvider,
        builder: (context, _) => CupertinoApp(
          title: 'NomNap',
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
          home: AppShell(store: store),
        ),
      ),
    );
  }
}
