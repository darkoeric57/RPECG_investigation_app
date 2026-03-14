import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class PersistentNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const PersistentNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppTheme.primary,
      unselectedItemColor: AppTheme.textLight,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 10),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view),
          activeIcon: Icon(Icons.grid_view, fill: 1),
          label: 'HOME',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'ADD',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          activeIcon: Icon(Icons.search, fill: 1),
          label: 'SEARCH',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map, fill: 1),
          label: 'MAP',
        ),
      ],
    );
  }
}
