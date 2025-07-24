// lib/utils/extensions.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

// Re-export the responsive system for convenience
export 'package:hockey_shot_tracker/responsive_system/index.dart';

// ============================================================================
// DOMAIN-SPECIFIC EXTENSIONS - Non-conflicting with responsive system
// ============================================================================

// Extension for lists and iterables to find an element or return null
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Explicitly specialized extensions for common types to avoid conflicts
extension TeamListExtension on List<Team> {
  Team? firstWhereOrNull(bool Function(Team) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension UserListExtension on List<User> {
  User? firstWhereOrNull(bool Function(User) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension PlayerListExtension on List<Player> {
  Player? firstWhereOrNull(bool Function(Player) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

// Date/time helpers
extension DateTimeExtension on DateTime {
  String toFormattedString() {
    return "${year}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
  }
  
  DateTime startOfDay() {
    return DateTime(year, month, day);
  }
  
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
}

// String helpers
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// ============================================================================
// ADDITIONAL HELPER EXTENSIONS (Non-conflicting)
// ============================================================================

// Widget extensions that don't conflict with responsive system
extension WidgetExtensions on Widget {
  Widget get expanded => Expanded(child: this);
  
  Widget get flexible => Flexible(child: this);
  
  Widget paddingAll(double padding) => Padding(
    padding: EdgeInsets.all(padding),
    child: this,
  );
  
  Widget paddingSymmetric({double horizontal = 0, double vertical = 0}) => Padding(
    padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical),
    child: this,
  );
}

// Theme helper extensions (safe, non-conflicting)
extension ThemeExtensions on BuildContext {
  // Helper for theme colors
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  
  // Helper for text theme
  TextTheme get textTheme => Theme.of(this).textTheme;
}

// Utility methods that leverage the existing responsive system
extension ResponsiveCardHelper on BuildContext {
  Widget responsiveElevatedCard({
    required Widget child,
    EdgeInsets? padding,
    double? elevation,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return Container(
      padding: padding ?? ResponsiveConfig.paddingAll(this, 16),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.surface,
        borderRadius: borderRadius ?? ResponsiveConfig.borderRadius(this, 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: elevation ?? ResponsiveConfig.dimension(this, 4),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Widget-specific responsive extensions that use the existing responsive system
extension ResponsiveWidgetExtensions on Widget {
  /// Wrap widget in responsive padding using existing responsive system
  Widget withResponsivePadding(BuildContext context, {
    double? horizontal,
    double? vertical,
  }) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(
        context,
        horizontal: horizontal ?? 16,
        vertical: vertical ?? 16,
      ),
      child: this,
    );
  }

  /// Wrap widget in responsive card using existing responsive system
  Widget asResponsiveCard(BuildContext context, {
    double? elevation,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return ResponsiveCard(
      padding: padding ?? ResponsiveConfig.paddingAll(context, 16),
      backgroundColor: Theme.of(context).cardColor,
      child: this,
    );
  }

  /// Wrap widget with responsive constraints using existing responsive system
  Widget withResponsiveConstraints(BuildContext context, {
    double? maxWidth,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: maxWidth ?? 1200,
        ),
        child: this,
      ),
    );
  }

  /// Make widget conditionally visible based on screen size using existing responsive system
  Widget visibleOn({
    bool mobile = true,
    bool tablet = true,
    bool desktop = true,
  }) {
    return Builder(
      builder: (context) {
        final deviceType = ResponsiveSystem.getDeviceType(context);
        bool shouldShow = false;
        
        switch (deviceType) {
          case DeviceType.mobile:
            shouldShow = mobile;
            break;
          case DeviceType.tablet:
            shouldShow = tablet;
            break;
          case DeviceType.desktop:
            shouldShow = desktop;
            break;
        }
        return shouldShow ? this : const SizedBox.shrink();
      },
    );
  }
}

// TextStyle responsive extensions that use existing responsive system
extension ResponsiveTextStyleExtensions on TextStyle {
  /// Apply responsive font scaling to existing TextStyle using the existing responsive system
  TextStyle responsive(BuildContext context, {double scale = 1.0}) {
    final baseFontSize = fontSize ?? 14;
    final scaledSize = baseFontSize * scale;
    
    return copyWith(
      fontSize: ResponsiveConfig.fontSize(context, scaledSize),
    );
  }
}

// List<Widget> extensions for responsive spacing using existing responsive system
extension ResponsiveWidgetListExtensions on List<Widget> {
  /// Add responsive spacing between list items using existing responsive system
  List<Widget> withResponsiveSpacing(BuildContext context, {
    double multiplier = 1.0,
    Axis direction = Axis.vertical,
  }) {
    if (isEmpty) return this;

    final spacing = ResponsiveConfig.spacing(context, 16 * multiplier);

    final spacedItems = <Widget>[];
    for (int i = 0; i < length; i++) {
      spacedItems.add(this[i]);
      if (i < length - 1) {
        spacedItems.add(
          direction == Axis.vertical
              ? SizedBox(height: spacing)
              : SizedBox(width: spacing),
        );
      }
    }
    return spacedItems;
  }
}

// MediaQuery responsive helpers that complement the existing responsive system
extension ResponsiveMediaQueryExtensions on MediaQueryData {
  /// Check if device is in landscape mode with sufficient width
  bool get isLandscapeWithSpace => orientation == Orientation.landscape && size.width > 600;
  
  /// Check if device supports side navigation
  bool get supportsSideNavigation => size.width >= 600;
  
  /// Check if device should use compact layout
  bool get shouldUseCompactLayout => size.width < 600;
  
  /// Get safe responsive padding that accounts for notches and system UI
  EdgeInsets get safeResponsivePadding {
    final basePadding = padding;
    return EdgeInsets.only(
      left: basePadding.left + (size.width < 600 ? 16 : 24),
      top: basePadding.top + 8,
      right: basePadding.right + (size.width < 600 ? 16 : 24),
      bottom: basePadding.bottom + 8,
    );
  }
}

// Additional helpful extensions that don't conflict
extension BuildContextHelpers on BuildContext {
  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;
  
  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;
  
  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;
  
  /// Get safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;
  
  /// Show responsive snackbar with appropriate sizing
  void showResponsiveSnackBar(String message, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: ResponsiveText(
          message,
          baseFontSize: 14,
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: ResponsiveConfig.paddingAll(this, 16),
        shape: RoundedRectangleBorder(
          borderRadius: ResponsiveConfig.borderRadius(this, 8),
        ),
      ),
    );
  }

  /// Show responsive dialog with appropriate sizing
  Future<T?> showResponsiveDialog<T>({
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: this,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: ResponsiveConfig.borderRadius(context, 8),
        ),
        child: Container(
          constraints: ResponsiveConfig.constraints(
            context,
            maxWidth: ResponsiveSystem.getDeviceType(context) == DeviceType.desktop ? 500 : screenWidth * 0.9,
          ),
          child: child,
        ),
      ),
    );
  }
}