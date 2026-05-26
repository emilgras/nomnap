import 'package:flutter/cupertino.dart';

import '../services/event_store.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'tracker_screen.dart';

class AppShell extends StatelessWidget {
  final EventStore store;
  const AppShell({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.92),
        activeColor: AppColors.sleepAccent,
        inactiveColor: AppColors.textTertiary,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.circle_grid_3x3),
            label: 'Track',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_bar_alt_fill),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.time),
            label: 'History',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return CupertinoTabView(
          builder: (context) {
            switch (index) {
              case 0:
                return TrackerScreen(store: store);
              case 1:
                return StatsScreen(store: store);
              case 2:
              default:
                return HistoryScreen(store: store);
            }
          },
        );
      },
    );
  }
}
