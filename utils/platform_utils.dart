import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web-safe platform utilities
/// Combines basic platform detection with feature capability checking
class PlatformUtils {
  // ==========================================
  // BASIC PLATFORM DETECTION
  // ==========================================
  
  /// Check if running on web
  static bool get isWeb => kIsWeb;
  
  /// Check if running on mobile (iOS or Android)
  static bool get isMobile => !kIsWeb;
  
  /// Check if running on desktop (Windows, macOS, Linux)
  static bool get isDesktop {
    if (kIsWeb) return false;
    try {
      return [
        TargetPlatform.windows,
        TargetPlatform.macOS,
        TargetPlatform.linux,
      ].contains(defaultTargetPlatform);
    } catch (e) {
      return false;
    }
  }
  
  /// Check if running on iOS (only works on mobile)
  static bool get isIOS {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.iOS;
    } catch (e) {
      return false;
    }
  }
  
  /// Check if running on Android (only works on mobile)
  static bool get isAndroid {
    if (kIsWeb) return false;
    try {
      return defaultTargetPlatform == TargetPlatform.android;
    } catch (e) {
      return false;
    }
  }
  
  /// Get platform name safely
  static String get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'unknown';
    }
  }

  // ==========================================
  // FEATURE CAPABILITY DETECTION
  // ==========================================
  
  /// Check if a specific feature is supported on current platform
  static bool supportsFeature(PlatformFeature feature) {
    switch (feature) {
      case PlatformFeature.fileUpload:
      case PlatformFeature.camera:
      case PlatformFeature.localDatabase:
      case PlatformFeature.fileSystem:
      case PlatformFeature.speechToText:
        return !isWeb; // These features work on mobile/desktop but not web
      case PlatformFeature.httpRequests:
      case PlatformFeature.localStorage:
      case PlatformFeature.pushNotifications:
        return true; // These work on all platforms
      case PlatformFeature.nativeSharing:
        return isMobile; // Sharing works best on mobile
      case PlatformFeature.printingPdf:
        return !isWeb || isDesktop; // Printing works on desktop, limited on web
    }
  }
  
  /// Get user-friendly message about feature availability
  static String getFeatureMessage(PlatformFeature feature) {
    if (supportsFeature(feature)) {
      return '${feature.displayName} is available on $platformName';
    } else {
      return '${feature.displayName} is not available on $platformName';
    }
  }
  
  /// Show platform limitation warning to user
  static void showFeatureWarning(BuildContext context, PlatformFeature feature) {
    if (!supportsFeature(feature)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getFeatureMessage(feature)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
          ),
        ),
      );
    }
  }
  
  // ==========================================
  // DEVELOPMENT HELPERS
  // ==========================================
  
  /// Log platform information (debug mode only)
  static void logPlatformInfo() {
    if (kDebugMode) {
      print('=== PLATFORM INFO ===');
      print('Platform: $platformName');
      print('Is Web: $isWeb');
      print('Is Mobile: $isMobile');
      print('Is Desktop: $isDesktop');
      if (!isWeb) {
        print('Is iOS: $isIOS');
        print('Is Android: $isAndroid');
      }
      print('====================');
    }
  }
  
  /// Check multiple features at once
  static Map<PlatformFeature, bool> checkFeatures(List<PlatformFeature> features) {
    return {
      for (var feature in features) feature: supportsFeature(feature)
    };
  }
  
  /// Get recommended alternative for unsupported features
  static String? getAlternative(PlatformFeature feature) {
    if (supportsFeature(feature)) return null;
    
    switch (feature) {
      case PlatformFeature.fileUpload:
        return isWeb ? 'Use HTML5 file input with drag & drop' : null;
      case PlatformFeature.camera:
        return isWeb ? 'Use HTML5 MediaDevices API' : null;
      case PlatformFeature.localDatabase:
        return isWeb ? 'Use IndexedDB or browser storage' : null;
      case PlatformFeature.speechToText:
        return isWeb ? 'Use Web Speech API (limited browser support)' : null;
      default:
        return 'Feature not available on this platform';
    }
  }
  
  // ==========================================
  // CONVENIENCE METHODS
  // ==========================================
  
  /// Check if file operations are supported
  static bool get canHandleFiles => supportsFeature(PlatformFeature.fileUpload);
  
  /// Check if camera operations are supported
  static bool get canUseCamera => supportsFeature(PlatformFeature.camera);
  
  /// Check if local database operations are supported
  static bool get canUseLocalDatabase => supportsFeature(PlatformFeature.localDatabase);
  
  /// Get a safe platform identifier for analytics/logging
  static String get platformIdentifier {
    if (isWeb) return 'web';
    if (isIOS) return 'ios';
    if (isAndroid) return 'android';
    if (isDesktop) return 'desktop_$platformName';
    return 'unknown';
  }
  
  /// Check if current platform supports full app functionality
  static bool get isFullySupported => !isWeb;
  
  /// Get a user-friendly description of current platform
  static String get platformDescription {
    if (isWeb) return 'Web Browser';
    if (isIOS) return 'iOS Device';
    if (isAndroid) return 'Android Device';
    if (isDesktop) return '${platformName.toUpperCase()} Desktop';
    return 'Unknown Platform';
  }
}

/// Enumeration of platform features that can be checked
enum PlatformFeature {
  fileUpload('File Upload'),
  camera('Camera Access'),
  localDatabase('Local Database'),
  fileSystem('File System Access'),
  httpRequests('HTTP Requests'),
  localStorage('Local Storage'),
  pushNotifications('Push Notifications'),
  speechToText('Speech to Text'),
  nativeSharing('Native Sharing'),
  printingPdf('PDF Printing');
  
  const PlatformFeature(this.displayName);
  final String displayName;
}
