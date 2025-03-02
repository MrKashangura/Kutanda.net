// lib/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';

enum NavDestination {
  dashboard,
  explore,
  create,
  profile,
  settings
}

class BottomNavigation extends StatelessWidget {
  final NavDestination currentDestination;
  final Function(NavDestination) onDestinationSelected;
  final bool isSellerMode;

  const BottomNavigation({
    required this.currentDestination,
    required this.onDestinationSelected,
    this.isSellerMode = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentDestination.index,
      onDestinationSelected: (index) {
        onDestinationSelected(NavDestination.values[index]);
      },
      destinations: [
        const NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        const NavigationDestination(
          icon: Icon(Icons.search_outlined),
          selectedIcon: Icon(Icons.search),
          label: 'Explore',
        ),
        if (isSellerMode)
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Create',
          ),
        const NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
        const NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

// Extension to use in our screens
extension NavExtension on State {
  void handleNavigation(BuildContext context, NavDestination destination, bool isSellerMode) {
    switch (destination) {
      case NavDestination.dashboard:
        if (isSellerMode) {
          Navigator.pushReplacementNamed(context, '/seller_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/buyer_dashboard');
        }
        break;
      case NavDestination.explore:
        Navigator.pushNamed(context, '/explore');
        break;
      case NavDestination.create:
        if (isSellerMode) {
          Navigator.pushNamed(context, '/create_auction');
        }
        break;
      case NavDestination.profile:
        Navigator.pushNamed(context, '/profile');
        break;
      case NavDestination.settings:
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }
}