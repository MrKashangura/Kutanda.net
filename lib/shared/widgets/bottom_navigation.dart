// lib/shared/widgets/bottom_navigation.dart
import 'package:flutter/material.dart';

enum NavDestination {
  dashboard,
  explore,
  create,
  profile,
  settings
}

class BottomNavigation extends StatefulWidget {
  final NavDestination currentDestination;
  final Function(NavDestination) onDestinationSelected;
  final bool isSellerMode;
  final ScrollController? scrollController;
  final bool enableHiding;

  const BottomNavigation({
    required this.currentDestination,
    required this.onDestinationSelected,
    this.isSellerMode = false,
    this.scrollController,
    this.enableHiding = true,
    super.key,
  });

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  bool _isVisible = true;
  ScrollController? _scrollController;
  double _lastScrollPosition = 0.0;
  bool _isAtTop = true;
  
  // Constants
  final double _navBarHeight = kBottomNavigationBarHeight + 16;
  final Duration _animationDuration = const Duration(milliseconds: 200);

  @override
  void initState() {
    super.initState();
    _setupScrollController();
  }
  
  void _setupScrollController() {
    _scrollController = widget.scrollController;
    if (_scrollController != null && widget.enableHiding) {
      _scrollController!.addListener(_handleScroll);
      
      // Initial check if we're at the top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController!.hasClients) {
          _isAtTop = _scrollController!.position.pixels <= 0;
          setState(() {});
        }
      });
    }
  }

  @override
  void didUpdateWidget(BottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle scroll controller changes
    if (oldWidget.scrollController != widget.scrollController) {
      if (oldWidget.scrollController != null && oldWidget.enableHiding) {
        oldWidget.scrollController!.removeListener(_handleScroll);
      }
      _setupScrollController();
    }
  }

  @override
  void dispose() {
    if (_scrollController != null && widget.enableHiding) {
      _scrollController!.removeListener(_handleScroll);
    }
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController == null || !_scrollController!.hasClients) return;
    
    // Check if we're at the top of the scroll view
    final isAtTop = _scrollController!.position.pixels <= 0;
    
    // Always show navbar when at the top
    if (isAtTop) {
      if (!_isVisible) {
        setState(() {
          _isVisible = true;
          _isAtTop = true;
        });
      }
      return;
    }
    
    _isAtTop = false;
    
    // Calculate scroll direction
    final currentPosition = _scrollController!.position.pixels;
    final isScrollingDown = currentPosition > _lastScrollPosition;
    
    // Only update if we've scrolled enough to trigger a visibility change
    final double threshold = 10.0;
    if ((currentPosition - _lastScrollPosition).abs() > threshold) {
      if (isScrollingDown && _isVisible) {
        setState(() => _isVisible = false);
      } else if (!isScrollingDown && !_isVisible) {
        setState(() => _isVisible = true);
      }
      
      _lastScrollPosition = currentPosition;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _animationDuration,
      height: _navBarHeight,
      transform: Matrix4.translationValues(
        0.0, 
        _isVisible ? 0.0 : _navBarHeight, 
        0.0
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: NavigationBar(
        height: _navBarHeight,
        selectedIndex: widget.currentDestination.index,
        onDestinationSelected: (index) {
          widget.onDestinationSelected(NavDestination.values[index]);
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
          if (widget.isSellerMode)
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
      ),
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