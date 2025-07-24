// File: lib/responsive_system/device_type.dart
enum DeviceType { 
  mobile, 
  tablet, 
  desktop 
}

/// CRITICAL FIX: Extension to add responsive method to DeviceType
/// This fixes all "The method 'responsive' isn't defined for the class 'DeviceType'" errors
extension DeviceTypeExtension on DeviceType {
  /// Returns different values based on the device type
  T responsive<T>({
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    switch (this) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
    }
  }

  /// Check if current device is mobile
  bool get isMobile => this == DeviceType.mobile;
  
  /// Check if current device is tablet
  bool get isTablet => this == DeviceType.tablet;
  
  /// Check if current device is desktop
  bool get isDesktop => this == DeviceType.desktop;

  /// Get display name for device type
  String get displayName {
    switch (this) {
      case DeviceType.mobile:
        return 'Mobile';
      case DeviceType.tablet:
        return 'Tablet';
      case DeviceType.desktop:
        return 'Desktop';
    }
  }

  /// Get icon for device type
  String get icon {
    switch (this) {
      case DeviceType.mobile:
        return '📱';
      case DeviceType.tablet:
        return '📱'; // Could be different tablet icon
      case DeviceType.desktop:
        return '💻';
    }
  }
}