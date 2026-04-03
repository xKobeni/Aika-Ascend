import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'home_screen.dart';
import 'challenges_screen.dart';
import 'stats_screen.dart';
import 'achievements_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  List<Widget> get _screens => [
    HomeScreen(),
    ChallengesScreen(),
    StatsScreen(),
    AchievementsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: const Border(
            top: BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          color: AppColors.surface,
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.transparent,
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            _dest(Icons.home_outlined, Icons.home, 'HOME'),
            _dest(Icons.fitness_center_outlined, Icons.fitness_center, 'CHALLENGES'),
            _dest(Icons.bar_chart_outlined, Icons.bar_chart, 'STATS'),
            _dest(Icons.military_tech_outlined, Icons.military_tech, 'BADGES'),
            _dest(Icons.person_outline, Icons.person, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _dest(IconData icon, IconData activeIcon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted, size: 22),
      selectedIcon: Icon(activeIcon, color: AppColors.violet, size: 22),
      label: label,
      tooltip: '',
    );
  }
}
