// Create lib/utils/file_helper.dart
import 'package:flutter/foundation.dart';

class FileHelper {
  static bool get canUploadFiles => !kIsWeb;
  
  static String get platformMessage {
    if (kIsWeb) {
      return 'File uploads are not supported on web. Please use the mobile app.';
    }
    return 'File uploads are supported on this platform.';
  }
  
  static void showPlatformMessage(BuildContext context) {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(platformMessage),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
