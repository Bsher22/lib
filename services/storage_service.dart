// lib/services/storage_service.dart (Flutter Frontend)
import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hockey_shot_tracker/models/shot.dart';

/// Simple service for local storage and caching
class StorageService {
  static final StorageService instance = StorageService._init();
  static Database? _database;
  
  StorageService._init();
  
  /// Get database instance, creating it if needed
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hockey_tracker.db');
    return _database!;
  }
  
  /// Initialize the database
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    
    return await openDatabase(
      path,
      version: 2, // ✅ Increased version to handle schema changes
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }
  
  /// Create database tables
  Future _createDB(Database db, int version) async {
    // Create shots table matching your Shot model
    await db.execute('''
    CREATE TABLE shots(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      server_id INTEGER,
      player_id INTEGER NOT NULL,
      zone TEXT NOT NULL,
      type TEXT NOT NULL,
      success INTEGER NOT NULL,
      outcome TEXT,
      timestamp TEXT NOT NULL,
      power REAL,
      quick_release REAL,
      workout TEXT,
      video_path TEXT,
      source TEXT DEFAULT 'individual',
      workout_id INTEGER,
      assessment_id TEXT,
      session_notes TEXT,
      group_index INTEGER,
      group_id TEXT,
      intended_zone TEXT,
      intended_direction TEXT,
      synced INTEGER DEFAULT 0
    )
    ''');
    
    // Create simple cache table for API responses
    await db.execute('''
    CREATE TABLE cache(
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      timestamp TEXT NOT NULL
    )
    ''');
  }
  
  /// Upgrade database schema
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for enhanced Shot model
      try {
        await db.execute('ALTER TABLE shots ADD COLUMN source TEXT DEFAULT "individual"');
        await db.execute('ALTER TABLE shots ADD COLUMN workout_id INTEGER');
        await db.execute('ALTER TABLE shots ADD COLUMN assessment_id TEXT');
        await db.execute('ALTER TABLE shots ADD COLUMN session_notes TEXT');
        await db.execute('ALTER TABLE shots ADD COLUMN group_index INTEGER');
        await db.execute('ALTER TABLE shots ADD COLUMN group_id TEXT');
        await db.execute('ALTER TABLE shots ADD COLUMN intended_zone TEXT');
        await db.execute('ALTER TABLE shots ADD COLUMN intended_direction TEXT');
        
        // Rename date column to timestamp if it exists
        await db.execute('ALTER TABLE shots RENAME COLUMN date TO timestamp');
      } catch (e) {
        print('Error upgrading database: $e');
        // If upgrade fails, recreate the table
        await db.execute('DROP TABLE IF EXISTS shots');
        await _createDB(db, newVersion);
      }
    }
  }
  
  /// Store a shot locally
  Future<int> saveShot(Shot shot) async {
    final db = await database;
    
    // Check if this shot has a server ID and already exists
    if (shot.id != 0) {
      final existing = await db.query(
        'shots',
        where: 'server_id = ?',
        whereArgs: [shot.id],
      );
      
      if (existing.isNotEmpty) {
        // Update existing shot
        await db.update(
          'shots',
          {
            'zone': shot.zone,
            'type': shot.type,
            'success': shot.success ? 1 : 0,
            'outcome': shot.outcome,
            'timestamp': shot.timestamp.toIso8601String(), // ✅ FIXED: Use timestamp
            'power': shot.power,
            'quick_release': shot.quickRelease,
            'workout': shot.workout,
            'video_path': shot.videoPath,
            'source': shot.source,
            'workout_id': shot.workoutId,
            'assessment_id': shot.assessmentId,
            'session_notes': shot.sessionNotes,
            'group_index': shot.groupIndex,
            'group_id': shot.groupId,
            'intended_zone': shot.intendedZone,
            'intended_direction': shot.intendedDirection,
            'synced': 1,
          },
          where: 'server_id = ?',
          whereArgs: [shot.id],
        );
        return existing.first['id'] as int;
      }
    }
    
    // Insert new shot
    return await db.insert('shots', {
      'server_id': shot.id != 0 ? shot.id : null,
      'player_id': shot.playerId,
      'zone': shot.zone,
      'type': shot.type,
      'success': shot.success ? 1 : 0,
      'outcome': shot.outcome,
      'timestamp': shot.timestamp.toIso8601String(), // ✅ FIXED: Use timestamp
      'power': shot.power,
      'quick_release': shot.quickRelease,
      'workout': shot.workout,
      'video_path': shot.videoPath,
      'source': shot.source,
      'workout_id': shot.workoutId,
      'assessment_id': shot.assessmentId,
      'session_notes': shot.sessionNotes,
      'group_index': shot.groupIndex,
      'group_id': shot.groupId,
      'intended_zone': shot.intendedZone,
      'intended_direction': shot.intendedDirection,
      'synced': shot.id != 0 ? 1 : 0,
    });
  }
  
  /// Get all shots for a player from local storage
  Future<List<Shot>> getShots(int playerId) async {
    final db = await database;
    final result = await db.query(
      'shots',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'timestamp DESC', // ✅ FIXED: Order by timestamp
    );
    
    return result.map((row) => Shot(
      id: (row['server_id'] as int?) ?? 0,
      playerId: row['player_id'] as int,
      zone: row['zone'] as String,
      type: row['type'] as String,
      success: row['success'] == 1,
      outcome: row['outcome'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String), // ✅ FIXED: Use timestamp
      power: row['power'] as double?,
      quickRelease: row['quick_release'] as double?,
      workout: row['workout'] as String?,
      videoPath: row['video_path'] as String?,
      source: row['source'] as String? ?? 'individual',
      workoutId: row['workout_id'] as int?,
      assessmentId: row['assessment_id'] as String?,
      sessionNotes: row['session_notes'] as String?,
      groupIndex: row['group_index'] as int?,
      groupId: row['group_id'] as String?,
      intendedZone: row['intended_zone'] as String?,
      intendedDirection: row['intended_direction'] as String?,
    )).toList();
  }
  
  /// Get unsynced shots
  Future<List<Shot>> getUnsyncedShots() async {
    final db = await database;
    final result = await db.query(
      'shots',
      where: 'synced = ?',
      whereArgs: [0],
    );
    
    return result.map((row) => Shot(
      id: 0, // No server ID yet
      playerId: row['player_id'] as int,
      zone: row['zone'] as String,
      type: row['type'] as String,
      success: row['success'] == 1,
      outcome: row['outcome'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String), // ✅ FIXED: Use timestamp
      power: row['power'] as double?,
      quickRelease: row['quick_release'] as double?,
      workout: row['workout'] as String?,
      videoPath: row['video_path'] as String?,
      source: row['source'] as String? ?? 'individual',
      workoutId: row['workout_id'] as int?,
      assessmentId: row['assessment_id'] as String?,
      sessionNotes: row['session_notes'] as String?,
      groupIndex: row['group_index'] as int?,
      groupId: row['group_id'] as String?,
      intendedZone: row['intended_zone'] as String?,
      intendedDirection: row['intended_direction'] as String?,
    )).toList();
  }
  
  /// Mark a shot as synced with its server ID
  Future<void> markShotAsSynced(int localId, int serverId) async {
    final db = await database;
    await db.update(
      'shots',
      {'server_id': serverId, 'synced': 1},
      where: 'id = ?',
      whereArgs: [localId],
    );
  }
  
  /// Delete a shot
  Future<void> deleteShot(int id) async {
    final db = await database;
    await db.delete(
      'shots',
      where: 'server_id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get shots by source (individual, assessment, workout)
  Future<List<Shot>> getShotsBySource(int playerId, String source) async {
    final db = await database;
    final result = await db.query(
      'shots',
      where: 'player_id = ? AND source = ?',
      whereArgs: [playerId, source],
      orderBy: 'timestamp DESC',
    );
    
    return result.map((row) => Shot(
      id: (row['server_id'] as int?) ?? 0,
      playerId: row['player_id'] as int,
      zone: row['zone'] as String,
      type: row['type'] as String,
      success: row['success'] == 1,
      outcome: row['outcome'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String),
      power: row['power'] as double?,
      quickRelease: row['quick_release'] as double?,
      workout: row['workout'] as String?,
      videoPath: row['video_path'] as String?,
      source: row['source'] as String? ?? 'individual',
      workoutId: row['workout_id'] as int?,
      assessmentId: row['assessment_id'] as String?,
      sessionNotes: row['session_notes'] as String?,
      groupIndex: row['group_index'] as int?,
      groupId: row['group_id'] as String?,
      intendedZone: row['intended_zone'] as String?,
      intendedDirection: row['intended_direction'] as String?,
    )).toList();
  }
  
  /// Get shots by workout ID
  Future<List<Shot>> getShotsByWorkout(int playerId, int workoutId) async {
    final db = await database;
    final result = await db.query(
      'shots',
      where: 'player_id = ? AND workout_id = ?',
      whereArgs: [playerId, workoutId],
      orderBy: 'timestamp DESC',
    );
    
    return result.map((row) => Shot(
      id: (row['server_id'] as int?) ?? 0,
      playerId: row['player_id'] as int,
      zone: row['zone'] as String,
      type: row['type'] as String,
      success: row['success'] == 1,
      outcome: row['outcome'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String),
      power: row['power'] as double?,
      quickRelease: row['quick_release'] as double?,
      workout: row['workout'] as String?,
      videoPath: row['video_path'] as String?,
      source: row['source'] as String? ?? 'individual',
      workoutId: row['workout_id'] as int?,
      assessmentId: row['assessment_id'] as String?,
      sessionNotes: row['session_notes'] as String?,
      groupIndex: row['group_index'] as int?,
      groupId: row['group_id'] as String?,
      intendedZone: row['intended_zone'] as String?,
      intendedDirection: row['intended_direction'] as String?,
    )).toList();
  }
  
  /// Get shots by assessment ID
  Future<List<Shot>> getShotsByAssessment(int playerId, String assessmentId) async {
    final db = await database;
    final result = await db.query(
      'shots',
      where: 'player_id = ? AND assessment_id = ?',
      whereArgs: [playerId, assessmentId],
      orderBy: 'timestamp DESC',
    );
    
    return result.map((row) => Shot(
      id: (row['server_id'] as int?) ?? 0,
      playerId: row['player_id'] as int,
      zone: row['zone'] as String,
      type: row['type'] as String,
      success: row['success'] == 1,
      outcome: row['outcome'] as String?,
      timestamp: DateTime.parse(row['timestamp'] as String),
      power: row['power'] as double?,
      quickRelease: row['quick_release'] as double?,
      workout: row['workout'] as String?,
      videoPath: row['video_path'] as String?,
      source: row['source'] as String? ?? 'individual',
      workoutId: row['workout_id'] as int?,
      assessmentId: row['assessment_id'] as String?,
      sessionNotes: row['session_notes'] as String?,
      groupIndex: row['group_index'] as int?,
      groupId: row['group_id'] as String?,
      intendedZone: row['intended_zone'] as String?,
      intendedDirection: row['intended_direction'] as String?,
    )).toList();
  }
  
  /// Clear all shots for a player
  Future<void> clearPlayerShots(int playerId) async {
    final db = await database;
    await db.delete(
      'shots',
      where: 'player_id = ?',
      whereArgs: [playerId],
    );
  }
  
  /// Clear all shots
  Future<void> clearAllShots() async {
    final db = await database;
    await db.delete('shots');
  }
  
  /// Cache API response data with a key
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    final db = await database;
    
    // Check if key exists
    final existing = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    final timestamp = DateTime.now().toIso8601String();
    final jsonData = jsonEncode(data);
    
    if (existing.isEmpty) {
      // Insert new cache entry
      await db.insert('cache', {
        'key': key,
        'value': jsonData,
        'timestamp': timestamp,
      });
    } else {
      // Update existing cache
      await db.update(
        'cache',
        {
          'value': jsonData,
          'timestamp': timestamp,
        },
        where: 'key = ?',
        whereArgs: [key],
      );
    }
  }
  
  /// Get cached data by key
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    final db = await database;
    final result = await db.query(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
    
    if (result.isEmpty) return null;
    
    final value = result.first['value'] as String;
    final timestamp = result.first['timestamp'] as String;
    
    return {
      'data': jsonDecode(value),
      'timestamp': timestamp,
    };
  }
  
  /// Check if cached data is still valid (within given hours)
  Future<bool> isCacheValid(String key, {int hoursValid = 24}) async {
    final cached = await getCachedData(key);
    if (cached == null) return false;
    
    final cachedTime = DateTime.parse(cached['timestamp'] as String);
    final now = DateTime.now();
    final difference = now.difference(cachedTime);
    
    return difference.inHours < hoursValid;
  }
  
  /// Clear specific cached data
  Future<void> clearCachedData(String key) async {
    final db = await database;
    await db.delete(
      'cache',
      where: 'key = ?',
      whereArgs: [key],
    );
  }
  
  /// Clear old cached data (older than specified hours)
  Future<void> clearOldCache({int hoursOld = 72}) async {
    final db = await database;
    final cutoffTime = DateTime.now().subtract(Duration(hours: hoursOld));
    
    await db.delete(
      'cache',
      where: 'timestamp < ?',
      whereArgs: [cutoffTime.toIso8601String()],
    );
  }
  
  /// Clear all cached data
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('cache');
  }
  
  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final shotCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM shots')
    ) ?? 0;
    
    final cacheCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM cache')
    ) ?? 0;
    
    final unsyncedCount = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM shots WHERE synced = 0')
    ) ?? 0;
    
    return {
      'total_shots': shotCount,
      'cached_items': cacheCount,
      'unsynced_shots': unsyncedCount,
    };
  }
  
  /// Close database
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}