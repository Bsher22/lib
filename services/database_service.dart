import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'dart:convert';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:get_it/get_it.dart';

class LocalDatabaseService {
  static final LocalDatabaseService instance = LocalDatabaseService._init();
  static Database? _database;
  final getIt = GetIt.instance;

  LocalDatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hockey_tracker_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 11, onCreate: _createDB, onUpgrade: _upgradeDB); // Increment version to 11
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      team_id INTEGER,
      team_name TEXT,
      primary_coach_id INTEGER,
      primary_coach_name TEXT,
      coordinator_id INTEGER,
      coordinator_name TEXT,
      email TEXT,
      phone TEXT,
      jersey_number INTEGER,
      preferred_position TEXT,
      birth_date TEXT,
      height INTEGER,
      weight INTEGER,
      age_group TEXT,
      position TEXT
    )
    ''');

    await db.execute('''
    CREATE TABLE shots (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_id INTEGER NOT NULL,
      zone TEXT NOT NULL,
      type TEXT NOT NULL,
      success INTEGER NOT NULL,
      outcome TEXT NOT NULL,
      timestamp TEXT NOT NULL,
      power REAL,
      quick_release REAL,
      workout TEXT,
      video_path TEXT,
      source TEXT NOT NULL,
      workout_id INTEGER,
      assessment_id TEXT, -- Changed to TEXT
      session_notes TEXT,
      FOREIGN KEY (player_id) REFERENCES players(id)
    )
    ''');

    await db.execute('''
    CREATE TABLE completed_workouts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_id INTEGER NOT NULL,
      program_id INTEGER NOT NULL,
      program_name TEXT,
      date_completed TEXT NOT NULL,
      total_shots INTEGER NOT NULL,
      successful_shots INTEGER NOT NULL,
      notes TEXT,
      FOREIGN KEY (player_id) REFERENCES players(id)
    )
    ''');

    await db.execute('''
    CREATE TABLE training_programs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      description TEXT,
      difficulty TEXT NOT NULL,
      type TEXT NOT NULL,
      duration TEXT NOT NULL,
      total_shots INTEGER NOT NULL,
      created_at TEXT NOT NULL,
      estimated_duration INTEGER
    )
    ''');

    // ✅ ADD: Create skating_assessments table
    await db.execute('''
    CREATE TABLE skating_assessments (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      player_id INTEGER NOT NULL,
      date TEXT NOT NULL,
      age_group TEXT NOT NULL,
      position TEXT NOT NULL,
      type TEXT NOT NULL,
      scores TEXT NOT NULL,
      test_times TEXT NOT NULL,
      notes TEXT,
      overall_score REAL,
      performance_level TEXT,
      team_assessment INTEGER DEFAULT 0,
      team_name TEXT,
      title TEXT NOT NULL,
      description TEXT,
      assessment_id TEXT,
      is_assessment INTEGER DEFAULT 1,
      assessment_type TEXT DEFAULT 'skating_assessment',
      FOREIGN KEY (player_id) REFERENCES players(id)
    )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 7) {
      await db.execute('DROP TABLE IF EXISTS skating_assessments');
      await db.execute('''
      CREATE TABLE skating_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        age_group TEXT NOT NULL,
        position TEXT NOT NULL,
        type TEXT NOT NULL,
        scores TEXT NOT NULL,
        test_times TEXT NOT NULL,
        notes TEXT,
        overall_score REAL NOT NULL,
        performance_level TEXT,
        team_assessment INTEGER DEFAULT 0,
        team_name TEXT,
        title TEXT NOT NULL,
        description TEXT,
        FOREIGN KEY (player_id) REFERENCES players(id)
      )
      ''');
    }

    if (oldVersion < 8) {
      await db.execute('''
      CREATE TABLE shots_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        zone TEXT NOT NULL,
        type TEXT NOT NULL,
        success INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        power REAL,
        quick_release REAL,
        workout TEXT,
        video_path TEXT,
        source TEXT NOT NULL,
        workout_id INTEGER,
        assessment_id INTEGER,
        session_notes TEXT,
        FOREIGN KEY (player_id) REFERENCES players(id)
      )
      ''');

      await db.execute('''
      INSERT INTO shots_new (
        id, player_id, zone, type, success, outcome, timestamp,
        power, quick_release, workout, video_path, source
      )
      SELECT 
        id, player_id, goal_x, type, success, outcome, date,
        power, quick_release, workout, video_path, 'individual'
      FROM shots
      ''');

      await db.execute('DROP TABLE shots');
      await db.execute('ALTER TABLE shots_new RENAME TO shots');
    }

    if (oldVersion < 9) {
      await db.execute('DROP TABLE IF EXISTS shot_assessments');
      await db.execute('DROP TABLE IF EXISTS skating_assessments');

      await db.execute('ALTER TABLE players ADD COLUMN team_id INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN team_name TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN primary_coach_id INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN primary_coach_name TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN coordinator_id INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN coordinator_name TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN email TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN phone TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN jersey_number INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN preferred_position TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN birth_date TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN height INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN weight INTEGER');
      await db.execute('ALTER TABLE players ADD COLUMN age_group TEXT');
      await db.execute('ALTER TABLE players ADD COLUMN position TEXT');
    }

    if (oldVersion < 10) {
      // Create a new shots table with assessment_id as TEXT
      await db.execute('''
      CREATE TABLE shots_new (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        zone TEXT NOT NULL,
        type TEXT NOT NULL,
        success INTEGER NOT NULL,
        outcome TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        power REAL,
        quick_release REAL,
        workout TEXT,
        video_path TEXT,
        source TEXT NOT NULL,
        workout_id INTEGER,
        assessment_id TEXT, -- Changed to TEXT
        session_notes TEXT,
        FOREIGN KEY (player_id) REFERENCES players(id)
      )
      ''');

      // Migrate data, converting assessment_id to TEXT
      await db.execute('''
      INSERT INTO shots_new (
        id, player_id, zone, type, success, outcome, timestamp,
        power, quick_release, workout, video_path, source,
        workout_id, assessment_id, session_notes
      )
      SELECT 
        id, player_id, zone, type, success, outcome, timestamp,
        power, quick_release, workout, video_path, source,
        workout_id, CAST(assessment_id AS TEXT), session_notes
      FROM shots
      ''');

      // Drop the old table and rename the new one
      await db.execute('DROP TABLE shots');
      await db.execute('ALTER TABLE shots_new RENAME TO shots');
    }

    if (oldVersion < 11) {
      // ✅ ADD: Recreate skating_assessments table with enhanced schema
      await db.execute('DROP TABLE IF EXISTS skating_assessments');
      await db.execute('''
      CREATE TABLE skating_assessments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        player_id INTEGER NOT NULL,
        date TEXT NOT NULL,
        age_group TEXT NOT NULL,
        position TEXT NOT NULL,
        type TEXT NOT NULL,
        scores TEXT NOT NULL,
        test_times TEXT NOT NULL,
        notes TEXT,
        overall_score REAL,
        performance_level TEXT,
        team_assessment INTEGER DEFAULT 0,
        team_name TEXT,
        title TEXT NOT NULL,
        description TEXT,
        assessment_id TEXT,
        is_assessment INTEGER DEFAULT 1,
        assessment_type TEXT DEFAULT 'skating_assessment',
        FOREIGN KEY (player_id) REFERENCES players(id)
      )
      ''');
    }
  }

  // ==========================================
  // PLAYER OPERATIONS
  // ==========================================

  Future<void> insertPlayer(Player player) async {
    final db = await database;
    await db.insert(
        'players',
        {
          'id': player.id,
          'name': player.name,
          'created_at': player.createdAt.toIso8601String(),
          'team_id': player.teamId,
          'team_name': player.teamName,
          'primary_coach_id': player.primaryCoachId,
          'primary_coach_name': player.primaryCoachName,
          'coordinator_id': player.coordinatorId,
          'coordinator_name': player.coordinatorName,
          'email': player.email,
          'phone': player.phone,
          'jersey_number': player.jerseyNumber,
          'preferred_position': player.preferredPosition,
          'birth_date': player.birthDate?.toIso8601String(),
          'height': player.height,
          'weight': player.weight,
          'age_group': player.ageGroup,
          'position': player.position,
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Player>> getPlayers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('players');
    return List.generate(maps.length, (i) {
      return Player(
        id: maps[i]['id'],
        name: maps[i]['name'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        teamId: maps[i]['team_id'],
        teamName: maps[i]['team_name'],
        primaryCoachId: maps[i]['primary_coach_id'],
        primaryCoachName: maps[i]['primary_coach_name'],
        coordinatorId: maps[i]['coordinator_id'],
        coordinatorName: maps[i]['coordinator_name'],
        email: maps[i]['email'],
        phone: maps[i]['phone'],
        jerseyNumber: maps[i]['jersey_number'],
        preferredPosition: maps[i]['preferred_position'],
        birthDate: maps[i]['birth_date'] != null ? DateTime.parse(maps[i]['birth_date']) : null,
        height: maps[i]['height'],
        weight: maps[i]['weight'],
        ageGroup: maps[i]['age_group'],
        position: maps[i]['position'],
      );
    });
  }

  // ✅ ADD: Missing deletePlayer method
  Future<void> deletePlayer(int playerId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Delete related data first
      await txn.delete('shots', where: 'player_id = ?', whereArgs: [playerId]);
      await txn.delete('completed_workouts', where: 'player_id = ?', whereArgs: [playerId]);
      await txn.delete('skating_assessments', where: 'player_id = ?', whereArgs: [playerId]);
      
      // Delete the player
      await txn.delete('players', where: 'id = ?', whereArgs: [playerId]);
    });
    print('✅ Player $playerId and all related data deleted from local database');
  }

  // ✅ ADD: updatePlayer method (using insertPlayer with replace)
  Future<void> updatePlayer(Player player) async {
    await insertPlayer(player); // Using REPLACE conflict algorithm
    print('✅ Player ${player.id} updated in local database');
  }

  // ==========================================
  // SHOT OPERATIONS
  // ==========================================

  Future<void> insertShot(Shot shot) async {
    final db = await database;
    final shotMap = {
      'id': shot.id,
      'player_id': shot.playerId,
      'zone': shot.zone,
      'type': shot.type,
      'success': shot.success ? 1 : 0,
      'outcome': shot.outcome,
      'timestamp': shot.timestamp.toIso8601String(),
      'power': shot.power,
      'quick_release': shot.quickRelease,
      'workout': shot.workout,
      'video_path': shot.videoPath,
      'source': shot.source,
      'workout_id': shot.workoutId,
      'assessment_id': shot.assessmentId,
      'session_notes': shot.sessionNotes,
    };
    await db.insert('shots', shotMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Shot>> getShots(int playerId, {
    int limit = 0,
    int offset = 0,
    String? source,
    int? workoutId,
    String? assessmentId, // Changed to String?
  }) async {
    final db = await database;
    final whereClauses = <String>['player_id = ?'];
    final whereArgs = <dynamic>[playerId];

    if (source != null) {
      whereClauses.add('source = ?');
      whereArgs.add(source);
    }
    if (workoutId != null) {
      whereClauses.add('workout_id = ?');
      whereArgs.add(workoutId);
    }
    if (assessmentId != null) {
      whereClauses.add('assessment_id = ?');
      whereArgs.add(assessmentId);
    }

    final whereClause = whereClauses.join(' AND ');

    final List<Map<String, dynamic>> maps = await db.query(
      'shots',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'timestamp DESC',
      limit: limit > 0 ? limit : null,
      offset: offset,
    );
    return List.generate(maps.length, (i) {
      return Shot(
        id: maps[i]['id'],
        playerId: maps[i]['player_id'],
        zone: maps[i]['zone'],
        type: maps[i]['type'],
        success: maps[i]['success'] == 1,
        outcome: maps[i]['outcome'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        power: maps[i]['power'],
        quickRelease: maps[i]['quick_release'],
        workout: maps[i]['workout'],
        videoPath: maps[i]['video_path'],
        source: maps[i]['source'] ?? 'individual',
        workoutId: maps[i]['workout_id'],
        assessmentId: maps[i]['assessment_id']?.toString(), // Ensure String
        sessionNotes: maps[i]['session_notes'],
      );
    });
  }

  // ✅ ADD: Missing updateShot method
  Future<void> updateShot(Shot shot) async {
    await insertShot(shot); // Using REPLACE conflict algorithm
    print('✅ Shot ${shot.id} updated in local database');
  }

  // ✅ ADD: Missing deleteShot method
  Future<void> deleteShot(String shotId) async {
    final db = await database;
    final result = await db.delete('shots', where: 'id = ?', whereArgs: [shotId]);
    print('✅ Shot $shotId deleted from local database (affected rows: $result)');
  }

  // ==========================================
  // COMPLETED WORKOUT OPERATIONS
  // ==========================================

  Future<void> insertCompletedWorkout(CompletedWorkout workout) async {
    final db = await database;
    final workoutMap = {
      'id': workout.id,
      'player_id': workout.playerId,
      'program_id': workout.programId,
      'program_name': workout.programName,
      'date_completed': workout.dateCompleted.toIso8601String(),
      'total_shots': workout.totalShots,
      'successful_shots': workout.successfulShots,
      'notes': workout.notes,
    };
    await db.insert('completed_workouts', workoutMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<CompletedWorkout>> getCompletedWorkouts(int playerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'completed_workouts',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'date_completed DESC',
    );
    return List.generate(maps.length, (i) {
      return CompletedWorkout(
        id: maps[i]['id'],
        playerId: maps[i]['player_id'],
        programId: maps[i]['program_id'],
        programName: maps[i]['program_name'],
        dateCompleted: DateTime.parse(maps[i]['date_completed']),
        totalShots: maps[i]['total_shots'],
        successfulShots: maps[i]['successful_shots'],
        notes: maps[i]['notes'],
      );
    });
  }

  // ✅ ADD: Missing updateCompletedWorkout method
  Future<void> updateCompletedWorkout(CompletedWorkout workout) async {
    await insertCompletedWorkout(workout); // Using REPLACE conflict algorithm
    print('✅ Completed workout ${workout.id} updated in local database');
  }

  // ✅ ADD: Missing deleteCompletedWorkout method
  Future<void> deleteCompletedWorkout(String workoutId) async {
    final db = await database;
    final result = await db.delete('completed_workouts', where: 'id = ?', whereArgs: [workoutId]);
    print('✅ Completed workout $workoutId deleted from local database (affected rows: $result)');
  }

  // ==========================================
  // TRAINING PROGRAM OPERATIONS
  // ==========================================

  Future<void> insertTrainingProgram(TrainingProgram program) async {
    final db = await database;
    final programMap = {
      'id': program.id,
      'name': program.name,
      'description': program.description,
      'difficulty': program.difficulty,
      'type': program.type,
      'duration': program.duration,
      'total_shots': program.totalShots,
      'created_at': program.createdAt.toIso8601String(),
      'estimated_duration': program.estimatedDuration,
    };
    await db.insert('training_programs', programMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TrainingProgram>> getTrainingPrograms() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('training_programs', orderBy: 'created_at DESC');
    return List.generate(maps.length, (i) {
      return TrainingProgram(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        difficulty: maps[i]['difficulty'],
        type: maps[i]['type'],
        duration: maps[i]['duration'],
        totalShots: maps[i]['total_shots'],
        createdAt: DateTime.parse(maps[i]['created_at']),
        estimatedDuration: maps[i]['estimated_duration'],
      );
    });
  }

  // ==========================================
  // SKATING ASSESSMENTS OPERATIONS ✅ NEW
  // ==========================================

  Future<void> insertSkating(Skating skating) async {
    final db = await database;
    final skatingMap = {
      'id': skating.id,
      'player_id': skating.playerId,
      'date': skating.date.toIso8601String(),
      'age_group': skating.ageGroup,
      'position': skating.position,
      'type': skating.assessmentType,
      'scores': jsonEncode(skating.scores),
      'test_times': jsonEncode(skating.testTimes),
      'notes': skating.description,
      'overall_score': _calculateOverallScore(skating.scores),
      'performance_level': _determinePerformanceLevel(skating.scores),
      'team_assessment': 0,
      'team_name': '',
      'title': skating.title,
      'description': skating.description,
      'assessment_id': skating.assessmentId,
      'is_assessment': skating.isAssessment ? 1 : 0,
      'assessment_type': skating.assessmentType,
    };
    await db.insert('skating_assessments', skatingMap, conflictAlgorithm: ConflictAlgorithm.replace);
    print('✅ Skating assessment ${skating.id} inserted into local database');
  }

  Future<List<Skating>> getSkatingAssessments(int playerId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'skating_assessments',
      where: 'player_id = ?',
      whereArgs: [playerId],
      orderBy: 'date DESC',
    );
    
    return List.generate(maps.length, (i) {
      return Skating(
        id: maps[i]['id'],
        playerId: maps[i]['player_id'],
        date: DateTime.parse(maps[i]['date']),
        ageGroup: maps[i]['age_group'] ?? 'youth_15_18',
        position: maps[i]['position'] ?? 'forward',
        testTimes: _parseTestTimes(maps[i]['test_times']),
        scores: _parseScores(maps[i]['scores']),
        isAssessment: (maps[i]['is_assessment'] ?? 1) == 1,
        assessmentType: maps[i]['assessment_type'] ?? 'skating_assessment',
        title: maps[i]['title'] ?? 'Skating Assessment',
        description: maps[i]['description'] ?? '',
        assessmentId: maps[i]['assessment_id'] ?? '',
      );
    });
  }

  Future<void> updateSkating(Skating skating) async {
    await insertSkating(skating); // Using REPLACE conflict algorithm
    print('✅ Skating assessment ${skating.id} updated in local database');
  }

  Future<void> deleteSkating(int skatingId) async {
    final db = await database;
    final result = await db.delete('skating_assessments', where: 'id = ?', whereArgs: [skatingId]);
    print('✅ Skating assessment $skatingId deleted from local database (affected rows: $result)');
  }

  // ==========================================
  // HELPER METHODS FOR SKATING
  // ==========================================

  Map<String, double?> _parseTestTimes(String? testTimesJson) {
    if (testTimesJson == null || testTimesJson.isEmpty) return {};
    try {
      final parsed = jsonDecode(testTimesJson) as Map<String, dynamic>;
      return parsed.map((key, value) => MapEntry(key, value is num ? value.toDouble() : null));
    } catch (e) {
      print('Error parsing test times: $e');
      return {};
    }
  }

  Map<String, double> _parseScores(String? scoresJson) {
    if (scoresJson == null || scoresJson.isEmpty) return {};
    try {
      final parsed = jsonDecode(scoresJson) as Map<String, dynamic>;
      return parsed.map((key, value) => MapEntry(key, value is num ? value.toDouble() : 0.0));
    } catch (e) {
      print('Error parsing scores: $e');
      return {};
    }
  }

  double _calculateOverallScore(Map<String, double> scores) {
    if (scores.isEmpty) return 0.0;
    final total = scores.values.fold(0.0, (sum, score) => sum + score);
    return total / scores.length;
  }

  String _determinePerformanceLevel(Map<String, double> scores) {
    final averageScore = _calculateOverallScore(scores);
    if (averageScore >= 8.0) return 'excellent';
    if (averageScore >= 6.0) return 'good';
    if (averageScore >= 4.0) return 'average';
    if (averageScore >= 2.0) return 'below_average';
    return 'needs_improvement';
  }

  // ==========================================
  // SYNC OPERATIONS
  // ==========================================

  Future<void> syncWithBackend() async {
    print("Starting database synchronization");

    try {
      final api = getIt<ApiService>();

      if (!api.isAuthenticated()) {
        print("Authentication required for sync - please log in");
        return;
      }

      print("Syncing players...");
      final remotePlayers = await api.fetchPlayers();
      print("Fetched ${remotePlayers.length} players from server");

      for (var player in remotePlayers) {
        await insertPlayer(player);
      }

      print("Players synchronized successfully");

      for (var player in remotePlayers) {
        if (player.id == null) continue;

        print("Syncing data for player: ${player.name}");

        print("Syncing shots for player ${player.id}");
        try {
          final remoteShots = await api.fetchShots(player.id!);
          for (var shot in remoteShots) {
            await insertShot(shot);
          }
        } catch (e) {
          print("Error syncing shots: $e");
        }

        print("Syncing completed workouts for player ${player.id}");
        try {
          final remoteWorkouts = await api.fetchCompletedWorkouts(player.id!);
          for (var workout in remoteWorkouts) {
            await insertCompletedWorkout(workout);
          }
        } catch (e) {
          print("Error syncing completed workouts: $e");
        }
      }

      print("Syncing training programs");
      try {
        final remotePrograms = await api.fetchTrainingPrograms();
        for (var program in remotePrograms) {
          await insertTrainingProgram(program);
        }
      } catch (e) {
        print("Error syncing training programs: $e");
      }

      print("Database synchronization completed successfully");
    } catch (e) {
      print("Error during database synchronization: $e");
      rethrow;
    }
  }

  // ==========================================
  // UTILITY OPERATIONS
  // ==========================================

  Future<void> clearShots() async {
    final db = await database;
    await db.delete('shots');
  }

  Future<void> clearPlayers() async {
    final db = await database;
    await db.delete('players');
  }

  Future<void> clearCompletedWorkouts() async {
    final db = await database;
    await db.delete('completed_workouts');
  }

  Future<void> clearSkatingAssessments() async {
    final db = await database;
    await db.delete('skating_assessments');
  }

  Future<void> clearTrainingPrograms() async {
    final db = await database;
    await db.delete('training_programs');
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('shots');
      await txn.delete('completed_workouts');
      await txn.delete('skating_assessments');
      await txn.delete('training_programs');
      await txn.delete('players');
    });
    print('✅ All local database data cleared');
  }

  // ==========================================
  // DATABASE STATISTICS & HEALTH
  // ==========================================

  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final playerCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM players')) ?? 0;
    final shotCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM shots')) ?? 0;
    final workoutCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM completed_workouts')) ?? 0;
    final skatingCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM skating_assessments')) ?? 0;
    final programCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM training_programs')) ?? 0;
    
    return {
      'players': playerCount,
      'shots': shotCount,
      'completed_workouts': workoutCount,
      'skating_assessments': skatingCount,
      'training_programs': programCount,
    };
  }

  Future<void> vacuum() async {
    final db = await database;
    await db.rawQuery('VACUUM');
    print('✅ Database vacuum completed');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
    print('✅ Database connection closed');
  }
}