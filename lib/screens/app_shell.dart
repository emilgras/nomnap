import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../services/event_store.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'tracker_screen.dart';

/// Total vertical space the floating pill nav occupies, including its bottom
/// gap. Scrollable screens should reserve this much padding at their bottom
/// so the last item isn't hidden behind the floating nav.
const double kFloatingNavReserve = 86;

class AppShell extends StatefulWidget {
  final EventStore store;
  const AppShell({super.key, required this.store});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return CupertinoPageScaffold(
      backgroundColor: AppColors.background,
      child: Stack(
        children: [
          IndexedStack(
            index: _index,
            children: [
              TrackerScreen(store: widget.store),
              StatsScreen(store: widget.store),
              HistoryScreen(store: widget.store),
            ],
          ),
          // Soft gradient backdrop *behind* the floating pill — gives the
          // nav a subtle "stage" so it visually pops without needing a
          // gradient on the glass itself.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.sleepAccent.withValues(alpha: 0),
                      AppColors.sleepAccent.withValues(alpha: 0.06),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset + 16,
            // Center + ConstrainedBox: keeps the nav at a phone-friendly
            // width even on tablet/desktop sizes (doesn't grow with screen).
            // Side padding still gives breathing room on small screens.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 380),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _FloatingPillNav(
                    currentIndex: _index,
                    onChanged: (i) => setState(() => _index = i),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

const List<_NavItem> _kNavItems = [
  _NavItem(CupertinoIcons.house_fill, 'Track'),
  _NavItem(CupertinoIcons.chart_bar_alt_fill, 'Stats'),
  _NavItem(CupertinoIcons.clock_fill, 'History'),
];

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  const _FloatingPillNav({
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Outer DecoratedBox carries the shadow (outside the clip);
    // inner ClipRRect clips the blur + solid background cleanly.
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.14),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: const Color(0xFF1A1A2E).withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 58,
            // Solid translucent white — the *menu* itself doesn't carry the
            // gradient (the soft tinted backdrop in AppShell does that job).
            color: CupertinoColors.white.withValues(alpha: 0.82),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                for (var i = 0; i < _kNavItems.length; i++)
                  Expanded(
                    // Each item gets exactly 1/n of the menu width and
                    // its pill fills that slot (minus a small gutter).
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: _PillNavItem(
                        item: _kNavItems[i],
                        active: currentIndex == i,
                        onTap: () => onChanged(i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PillNavItem extends StatelessWidget {
  final _NavItem item;
  final bool active;
  final VoidCallback onTap;
  const _PillNavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.sleepAccent : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      // Pill stretches to fill its 33% slot (minus the 2px gutter on
      // each side). When active the indigo tint lights up the whole slot.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        width: double.infinity,
        decoration: BoxDecoration(
          color: active
              ? AppColors.sleepAccent.withValues(alpha: 0.14)
              : CupertinoColors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: 0.1,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
