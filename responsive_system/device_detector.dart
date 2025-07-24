// ============================================================================
// File: lib/responsive_system/device_detector.dart
// ============================================================================
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'device_type.dart';

class DeviceDetector {
  /// Smart device detection based on platform AND screen dimensions
  /// Follows the specification requirements exactly
  static DeviceType getDeviceType(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;
    
    // Web detection
    if (kIsWeb) {
      return _getWebDeviceType(screenWidth);
    }
    
    // Platform-specific detection
    final platform = Theme.of(context).platform;
    
    switch (platform) {
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return DeviceType.desktop;
        
      case TargetPlatform.iOS:
        // iOS devices ≥768px width = tablet (per specification)
        return screenWidth >= 768 ? DeviceType.tablet : DeviceType.mobile;
        
      case TargetPlatform.android:
        // Android devices ≥600px width AND ≥600px height = tablet (per specification)
        return (screenWidth >= 600 && screenHeight >= 600) 
            ? DeviceType.tablet 
            : DeviceType.mobile;
            
      default:
        return _getWebDeviceType(screenWidth);
    }
  }
  
  /// Web device type detection
  static DeviceType _getWebDeviceType(double screenWidth) {
    if (screenWidth > 1024) return DeviceType.desktop;
    if (screenWidth > 768) return DeviceType.tablet;
    return DeviceType.mobile;
  }
  
  /// Orientation detection
  static bool isLandscape(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.orientation == Orientation.landscape;
  }
  
  /// Quick device type checks
  static bool isMobile(BuildContext context) => 
      getDeviceType(context) == DeviceType.mobile;
      
  static bool isTablet(BuildContext context) => 
      getDeviceType(context) == DeviceType.tablet;
      
  static bool isDesktop(BuildContext context) => 
      getDeviceType(context) == DeviceType.desktop;
}
