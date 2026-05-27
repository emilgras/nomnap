import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart';

import '../l10n/app_localizations.dart';
import '../services/event_store.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'tracker_screen.dart';

/// Total vertical space the floating pill nav occupies, including its bottom
/// gap. Scrollable screens should reserve this much padding at their bottom
/// so the last item isn't hidden behind the floating nav.
const double kFloatingNavReserve = 140;

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
            bottom: bottomInset + 28,
            // Center + ConstrainedBox: keeps the nav at a phone-friendly
            // width even on tablet/desktop sizes (doesn't grow with screen).
            // Side padding still gives breathing room on small screens.
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
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

List<_NavItem> _navItems(S s) => [
  _NavItem(CupertinoIcons.house_fill, s.navTrack),
  _NavItem(CupertinoIcons.chart_bar_alt_fill, s.navStats),
  _NavItem(CupertinoIcons.clock_fill, s.navHistory),
];

class _FloatingPillNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  const _FloatingPillNav({
    required this.currentIndex,
    required this.onChanged,
  });

  // For concentric rounded corners: inner radius = outer radius − inset.
  // height=58 ⇒ full stadium radius = 29; with a uniform 4px inset on all
  // sides the inner active pill needs radius 25 to match the outer curve.
  static const double _outerRadius = 29;
  static const double _innerInset = 4;
  static const double _innerRadius = _outerRadius - _innerInset; // 25

  @override
  Widget build(BuildContext context) {
    final items = _navItems(S.of(context));
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_outerRadius),
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
        borderRadius: BorderRadius.circular(_outerRadius),
        clipBehavior: Clip.antiAlias,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          child: Container(
            height: 58,
            color: CupertinoColors.white.withValues(alpha: 0.82),
            padding: const EdgeInsets.all(_innerInset),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final slotWidth =
                    constraints.maxWidth / items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 320),
                      curve: Curves.easeOutCubic,
                      left: currentIndex * slotWidth,
                      top: 0,
                      bottom: 0,
                      width: slotWidth,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.sleepAccent
                              .withValues(alpha: 0.14),
                          borderRadius:
                              BorderRadius.circular(_innerRadius),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          Expanded(
                            child: _PillNavItem(
                              item: items[i],
                              active: currentIndex == i,
                              onTap: () => onChanged(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
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
    // Lerp icon/label color in sync with the sliding indicator so the
    // selection state visually settles together (instead of color snapping
    // before the pill arrives).
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        tween: Tween(begin: active ? 1.0 : 0.0, end: active ? 1.0 : 0.0),
        builder: (context, t, _) {
          final color = Color.lerp(
            AppColors.textSecondary,
            AppColors.sleepAccent,
            t,
          )!;
          return Center(
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
          );
        },
      ),
    );
  }
}
