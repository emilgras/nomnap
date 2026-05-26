import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import 'screens/app_shell.dart';
import 'services/event_store.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  final store = EventStore();
  await store.load();
  runApp(NomNapApp(store: store));
}

class NomNapApp extends StatelessWidget {
  final EventStore store;
  const NomNapApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'NomNap',
      debugShowCheckedModeBanner: false,
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
    );
  }
}
