import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void initializeDatabaseForPlatform() {
  try {
    print('🔧 Initializing SQLite for mobile/desktop platform...');
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('✅ SQLite database initialized successfully');
  } catch (e) {
    print('❌ Failed to initialize SQLite database: $e');
  }
}

void initializeDatabaseForWeb() {
  print('⚠️ Web database initialization called on IO platform');
  initializeDatabaseForPlatform();
}
