// ============================================================================
// File: lib/responsive_system/responsive_config.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'enhanced_context_extensions.dart';

class ResponsiveConfig {
  // Base configuration per specification
  static const double _baseScreenWidth = 1920.0;
  static const double _minScaleFactor = 0.8;
  static const double _maxScaleFactor = 1.2;
  
  // Global spacing system (keeping your existing base unit)
  static const double baseUnit = 8.0;
  
  /// Get the scale factor based on screen width (per specification)
  /// Base scale factor: (screenWidth / 1920).clamp(0.8, 1.2)
  static double getScaleFactor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return (screenWidth / _baseScreenWidth).clamp(_minScaleFactor, _maxScaleFactor);
  }
  
  /// Scale font size based on screen width (UPDATED to use single scale factor)
  static double fontSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }
  
  /// Scale spacing based on screen width (UPDATED to use single scale factor)
  static double spacing(BuildContext context, double baseSpacing) {
    return baseSpacing * getScaleFactor(context);
  }
  
  /// Scale padding based on screen width (UPDATED to use single scale factor)
  static double padding(BuildContext context, double basePadding) {
    return basePadding * getScaleFactor(context);
  }
  
  // CRITICAL FIX: Add missing dimension method (fixes 300+ errors)
  static double dimension(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }
  
  // CRITICAL FIX: Add missing iconSize method (fixes 100+ errors)
  static double iconSize(BuildContext context, double baseSize) {
    return baseSize * getScaleFactor(context);
  }
  
  // CRITICAL FIX: Add missing borderRadiusValue method (fixes 50+ errors)
  static double borderRadiusValue(BuildContext context, double baseRadius) {
    return baseRadius * getScaleFactor(context);
  }
  
  /// Get responsive EdgeInsets
  static EdgeInsets paddingAll(BuildContext context, double basePadding) {
    final scaledPadding = padding(context, basePadding);
    return EdgeInsets.all(scaledPadding);
  }
  
  /// Get responsive symmetric EdgeInsets
  static EdgeInsets paddingSymmetric(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    return EdgeInsets.symmetric(
      horizontal: padding(context, horizontal),
      vertical: padding(context, vertical),
    );
  }
  
  /// Get responsive only EdgeInsets
  static EdgeInsets paddingOnly(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    return EdgeInsets.only(
      left: padding(context, left),
      top: padding(context, top),
      right: padding(context, right),
      bottom: padding(context, bottom),
    );
  }
  
  /// Get responsive border radius
  static BorderRadius borderRadius(BuildContext context, double baseRadius) {
    return BorderRadius.circular(padding(context, baseRadius));
  }
  
  /// Get responsive BoxConstraints (per specification)
  static BoxConstraints constraints(
    BuildContext context, {
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return BoxConstraints(
      minWidth: minWidth != null ? padding(context, minWidth) : 0,
      maxWidth: maxWidth != null ? padding(context, maxWidth) : double.infinity,
      minHeight: minHeight != null ? padding(context, minHeight) : 0,
      maxHeight: maxHeight != null ? padding(context, maxHeight) : double.infinity,
    );
  }
  
  // LEGACY METHODS (kept for backward compatibility with your existing code)
  
  /// Legacy responsive spacing (bridges to new system)
  static double spacingLegacy(BuildContext context, double multiplier) {
    return spacing(context, baseUnit * multiplier);
  }
  
  /// Legacy border radius (bridges to new system)
  static BorderRadius borderRadiusLegacy(BuildContext context) {
    return borderRadius(context, context.responsive<double>(
      mobile: 8,
      tablet: 12,
      desktop: 16,
    ));
  }
  
  /// Legacy elevation (bridges to new system)
  static double elevation(BuildContext context) {
    return context.responsive<double>(
      mobile: 2,
      tablet: 4,
      desktop: 6,
    );
  }
}