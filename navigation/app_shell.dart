import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/widgets/navigation/breadcrumb_navigation.dart';

// ✅ SIMPLIFIED: AppShell now only handles breadcrumbs and content wrapper
// Navigation is completely handled by AdaptiveScaffold
class AppShell extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String? title;
  final List<Widget>? actions;
  final bool showBreadcrumbs;
  
  const AppShell({
    Key? key,
    required this.child,
    required this.currentRoute,
    this.title,
    this.actions,
    this.showBreadcrumbs = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ SIMPLIFIED: Just return content with optional breadcrumbs
    // No navigation components at all
    return Material(
      color: Colors.transparent,
      child: _buildContentWithBreadcrumbs(context),
    );
  }

  Widget _buildContentWithBreadcrumbs(BuildContext context) {
    // ✅ FIX: Use flexible layout that doesn't cause overflow
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Show breadcrumbs if enabled and not on home page
            if (showBreadcrumbs && _shouldShowBreadcrumbs()) 
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: 60, // Fixed height to prevent overflow
                ),
                padding: ResponsiveConfig.paddingSymmetric(
                  context, 
                  horizontal: 16, 
                  vertical: 8
                ),
                color: Colors.grey[50],
                child: Material(
                  color: Colors.transparent,
                  child: AutoBreadcrumbNavigation(currentRoute: currentRoute),
                ),
              ),
            
            // ✅ FIX: Use Flexible instead of Expanded to prevent overflow
            // ✅ ADD: ClipRect to prevent any child overflow from breaking parent layout
            Flexible(
              child: ClipRect(
                child: Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    maxWidth: 1400, // Max width for desktop
                    maxHeight: constraints.maxHeight - (showBreadcrumbs && _shouldShowBreadcrumbs() ? 60 : 0),
                  ),
                  padding: ResponsiveConfig.paddingAll(context, 16),
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Check if we should show breadcrumbs (not on home page)
  bool _shouldShowBreadcrumbs() {
    return currentRoute != '/home';
  }

  /// Get title for the current route (used by breadcrumbs)
  String getRouteTitle(String route) {
    switch (route) {
      case '/home':
        return 'Home';
      case '/players':
        return 'Players';
      case '/teams':
        return 'Teams';
      case '/assessments':
        return 'Assessments';
      case '/shot-assessment':
        return 'Shot Assessment';
      case '/skating-assessment':
        return 'Skating Assessment';
      case '/team-shot-assessment':
        return 'Team Shot Assessment';
      case '/team-skating-assessment':
        return 'Team Skating Assessment';
      case '/hire-mentorship':
        return 'HIRE Mentorship';
      case '/training-programs':
        return 'Training Programs';
      case '/analytics':
        return 'Analytics';
      case '/calendar':
        return 'Calendar';
      case '/coaches':
        return 'Coaches';
      case '/coordinators':
        return 'Coordinators';
      case '/admin-settings':
        return 'Admin Settings';
      case '/settings':
        return 'Settings';
      default:
        if (route.startsWith('/players')) return 'Players';
        if (route.startsWith('/teams')) return 'Teams';
        if (route.startsWith('/assessments')) return 'Assessments';
        if (route.startsWith('/training')) return 'Training';
        if (route.startsWith('/analytics')) return 'Analytics';
        if (route.startsWith('/hire-mentorship')) return 'HIRE Mentorship';
        return 'Hockey Tracker';
    }
  }
}

/// Helper extension for easy AppShell usage
extension AppShellHelper on Widget {
  /// Wrap any widget with AppShell
  Widget withAppShell({
    required String currentRoute,
    String? title,
    List<Widget>? actions,
    bool showBreadcrumbs = true,
  }) {
    return AppShell(
      currentRoute: currentRoute,
      title: title,
      actions: actions,
      showBreadcrumbs: showBreadcrumbs,
      child: this,
    );
  }
}