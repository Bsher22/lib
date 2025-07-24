// Core responsive system exports
export 'responsive_config.dart';
export 'responsive_widgets.dart';
export 'adaptive_layout.dart';
export 'adaptive_scaffold.dart';
export 'device_type.dart';
export 'full_screen_container.dart';

// Import Flutter material for types
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

// Import our responsive system components
import 'device_type.dart';

// Navigation destination with different name to avoid conflicts
class AppNavigationDestination {
  final String route;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final bool enabled;

  const AppNavigationDestination({
    required this.route,
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.enabled = true,
  });
}

// ResponsiveSystem class implementation
class ResponsiveSystem {
  /// Get device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < BreakPoints.mobile) {
      return DeviceType.mobile;
    } else if (width < BreakPoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Check if device is mobile (< 600dp)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < BreakPoints.mobile;
  }

  /// Check if device is tablet (600-1240dp)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= BreakPoints.mobile && width < BreakPoints.tablet;
  }

  /// Check if device is desktop (> 1240dp)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= BreakPoints.desktop;
  }

  /// Get responsive value based on device type
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(context);
    return deviceType.responsive<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// PRIMARY BuildContext extension - this takes precedence
/// Use specific naming to avoid conflicts with enhanced_context_extensions.dart
extension ResponsiveContextExtension on BuildContext {
  /// Get device type for current context
  DeviceType get deviceType => ResponsiveSystem.getDeviceType(this);

  /// Check if device is mobile (< 600dp)
  bool get isMobile => ResponsiveSystem.isMobile(this);

  /// Check if device is tablet (600-1240dp)
  bool get isTablet => ResponsiveSystem.isTablet(this);

  /// Check if device is desktop (> 1240dp)
  bool get isDesktop => ResponsiveSystem.isDesktop(this);

  /// Get screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Get screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Get screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Responsive value selector based on device type
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return deviceType.responsive<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }

  /// Get safe area insets
  EdgeInsets get safeAreaInsets => MediaQuery.of(this).padding;

  /// Get orientation
  Orientation get orientation => MediaQuery.of(this).orientation;

  /// Check if device is in landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Check if device is in portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Get text scale factor
  double get textScaleFactor => MediaQuery.of(this).textScaleFactor;

  /// Get platform brightness
  Brightness get platformBrightness => MediaQuery.of(this).platformBrightness;

  /// Check if dark mode
  bool get isDarkMode => platformBrightness == Brightness.dark;

  /// Get theme data
  ThemeData get theme => Theme.of(this);

  /// Get color scheme - renamed to avoid conflicts
  ColorScheme get themeColorScheme => theme.colorScheme;

  /// Get text theme
  TextTheme get textTheme => theme.textTheme;
}

/// Screen size breakpoints (following Material Design guidelines)
class BreakPoints {
  static const double mobile = 600;
  static const double tablet = 1240;
  static const double desktop = 1240;
}

/// Screen size categories
enum ScreenSize {
  small,    // < 600dp
  medium,   // 600-1240dp  
  large,    // > 1240dp
}

/// Device orientation helper
enum DeviceOrientation {
  portrait,
  landscape,
}

/// Responsive helper functions
class ResponsiveHelper {
  /// Get device type from screen width
  static DeviceType getDeviceType(double width) {
    if (width < BreakPoints.mobile) {
      return DeviceType.mobile;
    } else if (width < BreakPoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Get screen size category
  static ScreenSize getScreenSize(double width) {
    if (width < BreakPoints.mobile) {
      return ScreenSize.small;
    } else if (width < BreakPoints.tablet) {
      return ScreenSize.medium;
    } else {
      return ScreenSize.large;
    }
  }

  /// Check if width is mobile
  static bool isMobile(double width) => width < BreakPoints.mobile;

  /// Check if width is tablet
  static bool isTablet(double width) => 
      width >= BreakPoints.mobile && width < BreakPoints.tablet;

  /// Check if width is desktop
  static bool isDesktop(double width) => width >= BreakPoints.desktop;

  /// Get responsive value based on width
  static T getResponsiveValue<T>({
    required double width,
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    final deviceType = getDeviceType(width);
    return deviceType.responsive<T>(
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
}

/// Global responsive constants
class ResponsiveConstants {
  // Spacing multipliers
  static const double spacingXS = 0.25;
  static const double spacingS = 0.5;
  static const double spacingM = 1.0;
  static const double spacingL = 1.5;
  static const double spacingXL = 2.0;
  static const double spacingXXL = 3.0;

  // Font size bases
  static const double fontSizeXS = 10.0;
  static const double fontSizeS = 12.0;
  static const double fontSizeM = 14.0;
  static const double fontSizeL = 16.0;
  static const double fontSizeXL = 18.0;
  static const double fontSizeXXL = 24.0;

  // Border radius bases
  static const double borderRadiusXS = 2.0;
  static const double borderRadiusS = 4.0;
  static const double borderRadiusM = 8.0;
  static const double borderRadiusL = 12.0;
  static const double borderRadiusXL = 16.0;

  // Icon sizes
  static const double iconSizeXS = 12.0;
  static const double iconSizeS = 16.0;
  static const double iconSizeM = 20.0;
  static const double iconSizeL = 24.0;
  static const double iconSizeXL = 32.0;
  static const double iconSizeXXL = 48.0;
}