// ============================================================================
// File: lib/responsive_system/adaptive_scaffold.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';

// CRITICAL FIX: Add missing imports
import 'device_type.dart';
import 'device_detector.dart';
import 'responsive_config.dart';
import 'enhanced_context_extensions.dart';
import 'adaptive_layout.dart';
import 'full_screen_container.dart';
import 'responsive_widgets.dart';

// ✅ NEW: Import breadcrumb navigation
import 'package:hockey_shot_tracker/widgets/navigation/breadcrumb_navigation.dart';

/// Navigation destination model
class AppNavigationDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;
  final List<String> roles;
  final bool requiresPermission;

  const AppNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
    this.roles = const [],
    this.requiresPermission = false,
  });
}

/// Enhanced adaptive scaffold with navigation
class AdaptiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final int currentIndex;
  final Function(int)? onDestinationSelected;
  final Color? backgroundColor;
  final Gradient? backgroundGradient;
  final bool extendBodyBehindAppBar;
  final bool resizeToAvoidBottomInset;
  final Widget? leading;
  final Widget? bottomNavigationBar;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool showBreadcrumbs; // ✅ NEW: Optional breadcrumbs
  final String? currentRoute; // ✅ NEW: Current route for breadcrumbs
  final bool showAppBar; // ✅ ADDED: Missing parameter

  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.title = '', // ✅ FIXED: Made optional with default value
    this.actions,
    this.floatingActionButton,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.backgroundColor,
    this.backgroundGradient,
    this.extendBodyBehindAppBar = false,
    this.resizeToAvoidBottomInset = true,
    this.leading,
    this.bottomNavigationBar,
    this.floatingActionButtonLocation,
    this.showBreadcrumbs = false, // ✅ NEW: Default false for main pages
    this.currentRoute, // ✅ NEW: For breadcrumb generation
    this.showAppBar = true, // ✅ ADDED: Missing parameter with default true
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final destinations = _getDestinationsForUser(appState);
        
        return AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            switch (deviceType) {
              case DeviceType.mobile:
                return _buildMobileLayout(context, destinations);
              case DeviceType.tablet:
                return _buildTabletLayout(context, destinations, isLandscape);
              case DeviceType.desktop:
                return _buildDesktopLayout(context, destinations);
            }
          },
        );
      },
    );
  }

  /// Get navigation destinations based on user permissions - UPDATED ROUTES
  List<AppNavigationDestination> _getDestinationsForUser(AppState appState) {
    final allDestinations = [
      const AppNavigationDestination(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        label: 'Home',
        route: '/home',
      ),
      const AppNavigationDestination(
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        label: 'Players',
        route: '/players',
      ),
      const AppNavigationDestination(
        icon: Icons.group_outlined,
        selectedIcon: Icons.group,
        label: 'Teams',
        route: '/teams',
        roles: ['coordinator', 'director', 'admin'],
        requiresPermission: true,
      ),
      const AppNavigationDestination(
        icon: Icons.assessment_outlined,
        selectedIcon: Icons.assessment,
        label: 'Assessments',
        route: '/assessments', // ✅ FIXED: Changed from /shot-assessment to /assessments
      ),
      const AppNavigationDestination(
        icon: Icons.analytics_outlined,
        selectedIcon: Icons.analytics,
        label: 'Analytics',
        route: '/analytics', // ✅ FIXED: Keep as /analytics
      ),
      const AppNavigationDestination(
        icon: Icons.psychology_outlined,
        selectedIcon: Icons.psychology,
        label: 'HIRE Mentorship',
        route: '/hire-mentorship',
      ),
      const AppNavigationDestination(
        icon: Icons.fitness_center_outlined,
        selectedIcon: Icons.fitness_center,
        label: 'Training',
        route: '/training-programs', // ✅ FIXED: Keep as /training-programs
      ),
      const AppNavigationDestination(
        icon: Icons.calendar_today_outlined,
        selectedIcon: Icons.calendar_today,
        label: 'Calendar',
        route: '/calendar',
      ),
      const AppNavigationDestination(
        icon: Icons.sports_outlined,
        selectedIcon: Icons.sports,
        label: 'Coaches',
        route: '/coaches',
        roles: ['director', 'admin'],
        requiresPermission: true,
      ),
      const AppNavigationDestination(
        icon: Icons.supervisor_account_outlined,
        selectedIcon: Icons.supervisor_account,
        label: 'Coordinators',
        route: '/coordinators', // ✅ ADDED: Missing coordinators route
        roles: ['admin'],
        requiresPermission: true,
      ),
      const AppNavigationDestination(
        icon: Icons.admin_panel_settings_outlined,
        selectedIcon: Icons.admin_panel_settings,
        label: 'Admin',
        route: '/admin-settings', // ✅ FIXED: Changed from /admin-settings to /admin-settings
        roles: ['admin'],
        requiresPermission: true,
      ),
      const AppNavigationDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Settings',
        route: '/settings',
      ),
    ];

    return allDestinations.where((destination) {
      if (!destination.requiresPermission) return true;
      
      final userRole = appState.getCurrentUserRole();
      if (userRole == null) return false;
      
      if (destination.roles.isNotEmpty && !destination.roles.contains(userRole)) {
        return false;
      }
      
      switch (destination.route) {
        case '/teams':
          return appState.canManageTeams();
        case '/coaches':
          return appState.canManageCoaches();
        case '/coordinators':
          return appState.canManageCoordinators();
        case '/admin-settings':
          return appState.isAdmin();
        default:
          return true;
      }
    }).toList();
  }

  /// Mobile layout with bottom navigation
  Widget _buildMobileLayout(BuildContext context, List<AppNavigationDestination> destinations) {
    return Scaffold(
      appBar: showAppBar ? _buildAppBar(context) : null, // ✅ FIXED: Conditional AppBar
      body: FullScreenContainer(
        gradient: backgroundGradient,
        backgroundColor: backgroundColor,
        child: SafeArea(
          child: _buildBodyWithBreadcrumbs(context),
        ),
      ),
      bottomNavigationBar: bottomNavigationBar ?? _buildBottomNavigation(context, destinations),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
    );
  }

  /// Tablet layout with navigation rail
  Widget _buildTabletLayout(BuildContext context, List<AppNavigationDestination> destinations, bool isLandscape) {
    return Scaffold(
      appBar: showAppBar ? _buildAppBar(context) : null, // ✅ FIXED: Conditional AppBar
      body: FullScreenContainer(
        gradient: backgroundGradient,
        backgroundColor: backgroundColor,
        child: SafeArea(
          child: Row(
            children: [
              _buildNavigationRail(context, destinations),
              Expanded(
                child: _buildBodyWithBreadcrumbs(context),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      backgroundColor: Colors.transparent,
    );
  }

  /// Desktop layout with persistent drawer
  Widget _buildDesktopLayout(BuildContext context, List<AppNavigationDestination> destinations) {
    return Scaffold(
      body: FullScreenContainer(
        gradient: backgroundGradient,
        backgroundColor: backgroundColor,
        child: Row(
          children: [
            _buildNavigationDrawer(context, destinations),
            Expanded(
              child: Column(
                children: [
                  if (showAppBar) _buildDesktopHeader(context), // ✅ FIXED: Conditional header
                  Expanded(
                    child: _buildBodyWithBreadcrumbs(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      backgroundColor: Colors.transparent,
    );
  }

  /// ✅ NEW: Build body with proper Material context and constraint handling
  Widget _buildBodyWithBreadcrumbs(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show breadcrumbs if enabled
            if (showBreadcrumbs && currentRoute != null && currentRoute != '/home')
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: 60, // Fixed height to prevent overflow
                ),
                child: Material(
                  color: Colors.grey[50],
                  child: AutoBreadcrumbNavigation(currentRoute: currentRoute!),
                ),
              ),
            
            // Main content with safe constraints and Material wrapper
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 1400, // Max width for desktop
                  maxHeight: constraints.maxHeight - (showBreadcrumbs && currentRoute != '/home' ? 60 : 0),
                ),
                child: ClipRect(
                  child: Container(
                    width: double.infinity,
                    padding: ResponsiveConfig.paddingAll(context, 16),
                    child: Material(
                      color: Colors.transparent,
                      child: body,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Enhanced app bar with responsive sizing
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 20),
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
      elevation: _getResponsiveElevation(context),
      actions: actions,
    );
  }

  double _getResponsiveElevation(BuildContext context) {
    final deviceType = DeviceDetector.getDeviceType(context);
    switch (deviceType) {
      case DeviceType.mobile:
        return 4;
      case DeviceType.tablet:
        return 2;
      case DeviceType.desktop:
        return 0;
    }
  }

  /// Enhanced bottom navigation with responsive sizing
  Widget _buildBottomNavigation(BuildContext context, List<AppNavigationDestination> destinations) {
    final mobileDestinations = _getMobileDestinations(destinations);
    
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _getCurrentIndex(mobileDestinations, context),
      onTap: (index) => _handleNavigation(context, mobileDestinations[index].route),
      selectedFontSize: ResponsiveConfig.fontSize(context, 12),
      unselectedFontSize: ResponsiveConfig.fontSize(context, 10),
      items: mobileDestinations.map((dest) => BottomNavigationBarItem(
        icon: Icon(dest.icon),
        activeIcon: Icon(dest.selectedIcon),
        label: dest.label,
      )).toList(),
    );
  }

  /// Enhanced navigation rail with responsive sizing
  Widget _buildNavigationRail(BuildContext context, List<AppNavigationDestination> destinations) {
    return NavigationRail(
      selectedIndex: _getCurrentIndex(destinations, context),
      onDestinationSelected: (index) => _handleNavigation(context, destinations[index].route),
      extended: MediaQuery.of(context).size.width > 900,
      minWidth: ResponsiveConfig.spacing(context, 72),
      backgroundColor: Theme.of(context).colorScheme.surface,
      destinations: destinations.map((dest) => NavigationRailDestination(
        icon: Icon(dest.icon),
        selectedIcon: Icon(dest.selectedIcon),
        label: Text(dest.label),
      )).toList(),
    );
  }

  /// Enhanced navigation drawer with responsive sizing
  Widget _buildNavigationDrawer(BuildContext context, List<AppNavigationDestination> destinations) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '/home';
    
    return Container(
      width: ResponsiveConfig.spacing(context, 280),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final dest = destinations[index];
                final isSelected = _isRouteSelected(dest.route, currentRoute);
                
                return ListTile(
                  leading: Icon(
                    isSelected ? dest.selectedIcon : dest.icon,
                    color: isSelected ? Theme.of(context).primaryColor : null,
                  ),
                  title: Text(
                    dest.label,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? Theme.of(context).primaryColor : null,
                      fontSize: ResponsiveConfig.fontSize(context, 14),
                    ),
                  ),
                  selected: isSelected,
                  onTap: () => _handleNavigation(context, dest.route),
                );
              },
            ),
          ),
          _buildUserInfo(context),
        ],
      ),
    );
  }

  /// Enhanced desktop header with proper constraint handling
  Widget _buildDesktopHeader(BuildContext context) {
    return Container(
      height: ResponsiveConfig.spacing(context, 64),
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.sports_hockey,
            size: ResponsiveConfig.spacing(context, 24),
            color: Theme.of(context).primaryColor,
          ),
          _buildHorizontalSpacing(context, 1),
          Flexible(
            child: Text(
              'HIRE Hockey',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
                fontSize: ResponsiveConfig.fontSize(context, 16),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            _buildHorizontalSpacing(context, 1),
            ...actions!.take(2).map((action) => Padding(
              padding: ResponsiveConfig.paddingOnly(context, left: 4),
              child: IconButton(
                icon: action is IconButton ? (action as IconButton).icon : const Icon(Icons.more_horiz),
                onPressed: action is IconButton ? (action as IconButton).onPressed : null,
                iconSize: ResponsiveConfig.spacing(context, 20),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(
                  minWidth: ResponsiveConfig.spacing(context, 32),
                  minHeight: ResponsiveConfig.spacing(context, 32),
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  /// Enhanced user info section
  Widget _buildUserInfo(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        final currentUser = appState.getCurrentUser();
        final userRole = appState.getCurrentUserRole();
        
        return Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                child: Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              _buildHorizontalSpacing(context, 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentUser?['name'] ?? 'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: ResponsiveConfig.fontSize(context, 14),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      userRole?.toUpperCase() ?? 'USER',
                      style: TextStyle(
                        fontSize: ResponsiveConfig.fontSize(context, 12),
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontalSpacing(BuildContext context, double multiplier) {
    return SizedBox(width: ResponsiveConfig.spacing(context, 8 * multiplier));
  }

  /// Get mobile-optimized destinations (priority routing)
  List<AppNavigationDestination> _getMobileDestinations(List<AppNavigationDestination> allDestinations) {
    final priority = ['/home', '/players', '/assessments', '/hire-mentorship','/analytics', '/settings'];
    final mobileDestinations = <AppNavigationDestination>[];
    
    for (final route in priority) {
      final dest = allDestinations.firstWhere(
        (d) => d.route == route,
        orElse: () => allDestinations.first,
      );
      if (!mobileDestinations.contains(dest)) {
        mobileDestinations.add(dest);
      }
      if (mobileDestinations.length >= 5) break;
    }
    
    return mobileDestinations;
  }

  /// Get current index based on current route - FIXED
  int _getCurrentIndex(List<AppNavigationDestination> destinations, BuildContext context) {
    // Try to get route from ModalRoute first
    String? currentRoute = ModalRoute.of(context)?.settings.name;
    
    // If no route from ModalRoute, try to determine from widget tree or use default
    currentRoute ??= '/home';
    
    for (int i = 0; i < destinations.length; i++) {
      if (_isRouteSelected(destinations[i].route, currentRoute)) {
        return i;
      }
    }
    return 0;
  }

  /// Check if route is selected - FIXED
  bool _isRouteSelected(String route, [String? currentRoute]) {
    // Use provided currentRoute or try to get from context
    final routeToCheck = currentRoute ?? '/home';
    return routeToCheck == route || routeToCheck.startsWith('$route/');
  }

  /// Handle navigation with special cases - UPDATED
  void _handleNavigation(BuildContext context, String route) {
    if (onDestinationSelected != null) {
      final destinations = _getDestinationsForUser(
        Provider.of<AppState>(context, listen: false),
      );
      final index = destinations.indexWhere((d) => d.route == route);
      if (index >= 0) {
        onDestinationSelected!(index);
      }
    }
    
    // Handle special navigation cases
    if (route == '/analytics') {
      _handleAnalyticsNavigation(context);
      return;
    }
    
    Navigator.pushNamed(context, route);
  }

  /// Handle analytics navigation with player context
  void _handleAnalyticsNavigation(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (appState.players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No players available for analysis. Please add players first.'),
        ),
      );
      Navigator.pushNamed(context, '/players');
      return;
    }
    
    final selectedPlayer = appState.players.firstWhere(
      (p) => p.name == appState.selectedPlayer,
      orElse: () => appState.players.first,
    );
    
    Navigator.pushNamed(context, '/analytics', arguments: selectedPlayer);
  }
}

/// Responsive container for content constraint
class _ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const _ResponsiveContainer({
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (maxWidth != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: content,
      );
    }

    if (padding != null) {
      content = Padding(
        padding: padding!,
        child: content,
      );
    }

    return Center(child: content);
  }
}