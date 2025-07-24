// ============================================================================
// File: lib/widgets/navigation/breadcrumb_navigation.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// Enhanced breadcrumb navigation with Material wrapper
class AutoBreadcrumbNavigation extends StatelessWidget {
  final String currentRoute;
  final TextStyle? textStyle;
  final Color? dividerColor;
  final EdgeInsetsGeometry? padding;
  final bool showHomeIcon;

  const AutoBreadcrumbNavigation({
    Key? key,
    required this.currentRoute,
    this.textStyle,
    this.dividerColor,
    this.padding,
    this.showHomeIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Wrap everything in Material to provide proper context
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: padding ?? ResponsiveConfig.paddingSymmetric(
          context,
          horizontal: 16,
          vertical: 8,
        ),
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _buildBreadcrumbs(context, deviceType);
          },
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, DeviceType deviceType) {
    final breadcrumbs = _generateBreadcrumbs(currentRoute);
    
    if (breadcrumbs.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ FIX: Use SingleChildScrollView to prevent overflow
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildBreadcrumbWidgets(context, breadcrumbs, deviceType),
      ),
    );
  }

  List<Widget> _buildBreadcrumbWidgets(
    BuildContext context, 
    List<BreadcrumbItem> breadcrumbs,
    DeviceType deviceType,
  ) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < breadcrumbs.length; i++) {
      final item = breadcrumbs[i];
      final isLast = i == breadcrumbs.length - 1;
      
      // Add breadcrumb item
      widgets.add(_buildBreadcrumbItem(context, item, isLast, deviceType));
      
      // Add divider (except for last item)
      if (!isLast) {
        widgets.add(_buildDivider(context));
      }
    }
    
    return widgets;
  }

  Widget _buildBreadcrumbItem(
    BuildContext context, 
    BreadcrumbItem item, 
    bool isLast,
    DeviceType deviceType,
  ) {
    final style = textStyle ?? TextStyle(
      fontSize: ResponsiveConfig.fontSize(context, 14),
      color: isLast ? Colors.blueGrey[800] : Colors.blueGrey[600],
      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: ResponsiveConfig.fontSize(context, 16),
            color: style.color,
          ),
          SizedBox(width: ResponsiveConfig.spacing(context, 4)),
        ],
        // ✅ FIX: Constrain text width to prevent overflow
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: deviceType == DeviceType.mobile ? 120 : 200,
          ),
          child: Text(
            item.label,
            style: style,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );

    // If it's the last item or no route, return non-clickable text
    if (isLast || item.route == null) {
      return content;
    }

    // ✅ FIX: InkWell now has proper Material ancestor
    return InkWell(
      onTap: () => _navigateToRoute(context, item.route!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: ResponsiveConfig.paddingSymmetric(
          context,
          horizontal: 4,
          vertical: 2,
        ),
        child: content,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
      child: Icon(
        Icons.chevron_right,
        size: ResponsiveConfig.fontSize(context, 16),
        color: dividerColor ?? Colors.blueGrey[400],
      ),
    );
  }

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pushNamed(context, route);
  }

  /// Generate breadcrumb items based on current route
  List<BreadcrumbItem> _generateBreadcrumbs(String route) {
    final breadcrumbs = <BreadcrumbItem>[];
    
    // Always start with home if enabled
    if (showHomeIcon && route != '/home') {
      breadcrumbs.add(BreadcrumbItem(
        label: 'Home',
        route: '/home',
        icon: Icons.home,
      ));
    }
    
    // Parse route segments
    final segments = route.split('/').where((s) => s.isNotEmpty).toList();
    String currentPath = '';
    
    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      currentPath += '/$segment';
      
      final item = _createBreadcrumbItem(currentPath, segment, i == segments.length - 1);
      if (item != null) {
        breadcrumbs.add(item);
      }
    }
    
    return breadcrumbs;
  }

  /// Create breadcrumb item for a route segment
  BreadcrumbItem? _createBreadcrumbItem(String fullPath, String segment, bool isLast) {
    switch (fullPath) {
      case '/players':
        return BreadcrumbItem(
          label: 'Players',
          route: isLast ? null : '/players',
          icon: Icons.people,
        );
      case '/teams':
        return BreadcrumbItem(
          label: 'Teams',
          route: isLast ? null : '/teams',
          icon: Icons.group,
        );
      case '/assessments':
        return BreadcrumbItem(
          label: 'Assessments',
          route: isLast ? null : '/assessments',
          icon: Icons.assessment,
        );
      case '/shot-assessment':
        return BreadcrumbItem(
          label: 'Shot Assessment',
          route: null, // No navigation - this is a detail page
        );
      case '/skating-assessment':
        return BreadcrumbItem(
          label: 'Skating Assessment',
          route: null,
        );
      case '/team-shot-assessment':
        return BreadcrumbItem(
          label: 'Team Shot Assessment',
          route: null,
        );
      case '/team-skating-assessment':
        return BreadcrumbItem(
          label: 'Team Skating Assessment',
          route: null,
        );
      case '/analytics':
        return BreadcrumbItem(
          label: 'Analytics',
          route: isLast ? null : '/analytics',
          icon: Icons.analytics,
        );
      case '/training-programs':
        return BreadcrumbItem(
          label: 'Training Programs',
          route: isLast ? null : '/training-programs',
          icon: Icons.fitness_center,
        );
      case '/calendar':
        return BreadcrumbItem(
          label: 'Calendar',
          route: isLast ? null : '/calendar',
          icon: Icons.calendar_today,
        );
      case '/coaches':
        return BreadcrumbItem(
          label: 'Coaches',
          route: isLast ? null : '/coaches',
          icon: Icons.sports,
        );
      case '/coordinators':
        return BreadcrumbItem(
          label: 'Coordinators',
          route: isLast ? null : '/coordinators',
          icon: Icons.supervisor_account,
        );
      case '/admin-settings':
        return BreadcrumbItem(
          label: 'Admin Settings',
          route: isLast ? null : '/admin-settings',
          icon: Icons.admin_panel_settings,
        );
      case '/settings':
        return BreadcrumbItem(
          label: 'Settings',
          route: isLast ? null : '/settings',
          icon: Icons.settings,
        );
      default:
        // Handle dynamic routes
        if (fullPath.startsWith('/players/')) {
          return BreadcrumbItem(
            label: _formatSegmentLabel(segment),
            route: null,
          );
        } else if (fullPath.startsWith('/teams/')) {
          return BreadcrumbItem(
            label: _formatSegmentLabel(segment),
            route: null,
          );
        } else if (fullPath.startsWith('/training/')) {
          return BreadcrumbItem(
            label: _formatSegmentLabel(segment),
            route: null,
          );
        }
        return null;
    }
  }

  /// Format segment label for display
  String _formatSegmentLabel(String segment) {
    // Convert kebab-case to Title Case
    return segment
        .split('-')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
}

/// Breadcrumb item model
class BreadcrumbItem {
  final String label;
  final String? route;
  final IconData? icon;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.icon,
  });
}

/// Simple breadcrumb navigation without auto-generation
class BreadcrumbNavigation extends StatelessWidget {
  final List<BreadcrumbItem> items;
  final TextStyle? textStyle;
  final Color? dividerColor;
  final EdgeInsetsGeometry? padding;

  const BreadcrumbNavigation({
    Key? key,
    required this.items,
    this.textStyle,
    this.dividerColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // ✅ FIX: Wrap in Material widget
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        padding: padding ?? ResponsiveConfig.paddingSymmetric(
          context,
          horizontal: 16,
          vertical: 8,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: _buildItems(context),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildItems(BuildContext context) {
    final widgets = <Widget>[];
    
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final isLast = i == items.length - 1;
      
      widgets.add(_buildItem(context, item, isLast));
      
      if (!isLast) {
        widgets.add(_buildDivider(context));
      }
    }
    
    return widgets;
  }

  Widget _buildItem(BuildContext context, BreadcrumbItem item, bool isLast) {
    final style = textStyle ?? TextStyle(
      fontSize: ResponsiveConfig.fontSize(context, 14),
      color: isLast ? Colors.blueGrey[800] : Colors.blueGrey[600],
      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
    );

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (item.icon != null) ...[
          Icon(
            item.icon,
            size: ResponsiveConfig.fontSize(context, 16),
            color: style.color,
          ),
          SizedBox(width: ResponsiveConfig.spacing(context, 4)),
        ],
        Text(item.label, style: style),
      ],
    );

    if (isLast || item.route == null) {
      return content;
    }

    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route!),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: ResponsiveConfig.paddingSymmetric(
          context,
          horizontal: 4,
          vertical: 2,
        ),
        child: content,
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
      child: Icon(
        Icons.chevron_right,
        size: ResponsiveConfig.fontSize(context, 16),
        color: dividerColor ?? Colors.blueGrey[400],
      ),
    );
  }
}