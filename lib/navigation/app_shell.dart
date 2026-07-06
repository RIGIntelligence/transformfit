import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';
import 'package:transformfit/theme/digital_atelier.dart';

/// Root shell for authenticated users — wraps the app in a [Scaffold] with
/// a 5-tab bottom navigation bar. Each tab maintains its own nested
/// [Navigator] via [StatefulShellRoute] so back-stack state is preserved
/// when switching tabs.
///
/// Unauthenticated users (auth / onboarding) never see this shell.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  /// The [StatefulNavigationShell] provided by go_router's
  /// [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  static const _tabNames = ['Today', 'Workout', 'Coach', 'Wellness', 'Profile'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: _BottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    // Announce the tab switch for screen readers.
    if (index != navigationShell.currentIndex && index < _tabNames.length) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${_tabNames[index]} tab selected',
        Directionality.of(context),
      );
    }

    // When tapping the already-active tab, pop to the first route in that
    // branch (same behaviour as iOS UITabBarController).
    if (index == navigationShell.currentIndex) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    } else {
      navigationShell.goBranch(index);
    }
  }
}

/// Reusable tab icon with 44px minimum touch target and semantics label.
class _TabIcon extends StatelessWidget {
  const _TabIcon({required this.icon, required this.semanticLabel});

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      child: SizedBox(
        height: 44,
        child: Icon(icon),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _mutedColor = Color(0xFFA0A0A0);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: DigitalAtelierTokens2.surfaceElevated,
        border: Border(
          top: BorderSide(color: DigitalAtelierTokens2.surfaceBorder),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: DigitalAtelierTokens.accentOrange,
        unselectedItemColor: _mutedColor,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        iconSize: 24,
        items: [
          BottomNavigationBarItem(
            icon: _TabIcon(
              icon: Icons.today,
              semanticLabel: 'Today tab',
            ),
            activeIcon: _TabIcon(
              icon: Icons.today,
              semanticLabel: 'Today tab, selected',
            ),
            label: 'Today',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(
              icon: Icons.fitness_center,
              semanticLabel: 'Workout tab',
            ),
            activeIcon: _TabIcon(
              icon: Icons.fitness_center,
              semanticLabel: 'Workout tab, selected',
            ),
            label: 'Workout',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(
              icon: Icons.chat,
              semanticLabel: 'Coach tab',
            ),
            activeIcon: _TabIcon(
              icon: Icons.chat,
              semanticLabel: 'Coach tab, selected',
            ),
            label: 'Coach',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(
              icon: Icons.favorite,
              semanticLabel: 'Wellness tab',
            ),
            activeIcon: _TabIcon(
              icon: Icons.favorite,
              semanticLabel: 'Wellness tab, selected',
            ),
            label: 'Wellness',
          ),
          BottomNavigationBarItem(
            icon: _TabIcon(
              icon: Icons.person,
              semanticLabel: 'Profile tab',
            ),
            activeIcon: _TabIcon(
              icon: Icons.person,
              semanticLabel: 'Profile tab, selected',
            ),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
