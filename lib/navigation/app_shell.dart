import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:go_router/go_router.dart';


/// Root shell for authenticated users — wraps the app in a [Scaffold] with
/// a 4-tab bottom navigation bar. Each tab maintains its own nested
/// [Navigator] via [StatefulShellRoute] so back-stack state is preserved
/// when switching tabs.
///
/// Tabs: Home | Workout | Coach | Profile
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabNames = ['Home', 'Workout', 'Coach', 'Profile'];

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
    if (index != navigationShell.currentIndex && index < _tabNames.length) {
      SemanticsService.sendAnnouncement(
        View.of(context),
        '${_tabNames[index]} tab selected',
        Directionality.of(context),
      );
    }

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

/// Bottom nav — v4 Design System.
/// 4 icons, no labels, orange dot indicator, glass blur.
class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _inactiveColor = Color(0xFF48484A);
  static const _activeColor = Color(0xFFFF6B35);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF050505).withValues(alpha: 0.85),
            border: const Border(
              top: BorderSide(color: Color(0xFF1A1A1A), width: 0.5),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home,
                    isActive: currentIndex == 0,
                    semanticLabel: 'Home tab',
                    onTap: () => onTap(0),
                  ),
                  _NavItem(
                    icon: Icons.fitness_center,
                    activeIcon: Icons.fitness_center,
                    isActive: currentIndex == 1,
                    semanticLabel: 'Workout tab',
                    onTap: () => onTap(1),
                  ),
                  _NavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble,
                    isActive: currentIndex == 2,
                    semanticLabel: 'Coach tab',
                    onTap: () => onTap(2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    activeIcon: Icons.person,
                    isActive: currentIndex == 3,
                    semanticLabel: 'Profile tab',
                    onTap: () => onTap(3),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$semanticLabel${isActive ? ", selected" : ""}',
      button: true,
      selected: isActive,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                size: 24,
                color: isActive
                    ? _BottomNav._activeColor
                    : _BottomNav._inactiveColor,
              ),
              const SizedBox(height: 4),
              // Orange dot indicator for active tab — 6px
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                width: isActive ? 6 : 0,
                height: isActive ? 6 : 0,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFF6B35),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
