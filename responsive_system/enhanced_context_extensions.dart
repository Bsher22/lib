// ============================================================================
// File: lib/responsive_system/enhanced_context_extensions.dart (NEW)
// ============================================================================
import 'package:flutter/material.dart';
import 'device_type.dart';
import 'device_detector.dart';
import 'responsive_config.dart';

/// Enhanced responsive extensions (merging your existing with new features)
extension ResponsiveContext on BuildContext {
  // Screen information (keeping your existing)
  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;
  Orientation get orientation => MediaQuery.of(this).orientation;
  
  // Updated device type detection (using new smart detector)
  DeviceType get deviceType => DeviceDetector.getDeviceType(this);
  
  // Quick device checks (updated to use new detector)
  bool get isMobile => DeviceDetector.isMobile(this);
  bool get isTablet => DeviceDetector.isTablet(this);
  bool get isDesktop => DeviceDetector.isDesktop(this);
  bool get isLandscape => DeviceDetector.isLandscape(this);
  bool get isPortrait => orientation == Orientation.portrait;
  
  /// Responsive value selection (keeping your 4-tier system)
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
    T? largeDesktop,
  }) {
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        // Check if it's a large desktop (≥1440px)
        if (screenWidth >= 1440) {
          return largeDesktop ?? desktop ?? tablet ?? mobile;
        }
        return desktop ?? tablet ?? mobile;
    }
  }
  
  // Responsive grid columns (keeping your existing logic)
  int get gridColumns => responsive<int>(
    mobile: 1,
    tablet: 2,
    desktop: 3,
    largeDesktop: 4,
  );
  
  // Responsive padding (keeping your existing)
  EdgeInsets get screenPadding => EdgeInsets.symmetric(
    horizontal: responsive<double>(
      mobile: 16,
      tablet: 24,
      desktop: 32,
      largeDesktop: 48,
    ),
    vertical: 16,
  );
  
  // Responsive container constraints (keeping your existing)
  double get maxContentWidth => responsive<double>(
    mobile: double.infinity,
    tablet: 800,
    desktop: 1200,
    largeDesktop: 1400,
  );
  
  // Responsive border radius (using new scaling)
  BorderRadius get responsiveBorderRadius => ResponsiveConfig.borderRadius(
    this,
    responsive<double>(
      mobile: 8,
      tablet: 12,
      desktop: 16,
      largeDesktop: 20,
    ),
  );
  
  // Responsive icon size (using new scaling)
  double get responsiveIconSize => ResponsiveConfig.spacing(
    this,
    responsive<double>(
      mobile: 20,
      tablet: 24,
      desktop: 28,
      largeDesktop: 32,
    ),
  );
  
  // Responsive elevation (keeping your existing)
  double get responsiveElevation => responsive<double>(
    mobile: 2,
    tablet: 4,
    desktop: 6,
    largeDesktop: 8,
  );
  
  // Responsive app bar height (keeping your existing)
  double get responsiveAppBarHeight => responsive<double>(
    mobile: 56,
    tablet: 64,
    desktop: 72,
    largeDesktop: 80,
  );
  
  // NEW: Direct scaling methods (from specification)
  double fontSize(double baseSize) => ResponsiveConfig.fontSize(this, baseSize);
  double spacing(double baseSpacing) => ResponsiveConfig.spacing(this, baseSpacing);
  double padding(double basePadding) => ResponsiveConfig.padding(this, basePadding);
}

// Keep your existing ScreenType enum for backward compatibility
enum ScreenType { mobile, tablet, desktop, largeDesktop }
