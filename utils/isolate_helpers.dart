// lib/utils/isolate_helpers.dart

import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/skating_assessments.dart';
import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/services/database_service.dart';

// Background worker functions
class IsolateHelpers {
  // Load players in background
  static Future<List<Player>> loadPlayersIsolate(_) async {
    final db = LocalDatabaseService.instance;
    return await db.getPlayers();
  }
  
  // Load shots in background
  static Future<List<Shot>> loadShotsIsolate(int playerId) async {
    final db = LocalDatabaseService.instance;
    return await db.getShots(playerId);
  }
  
  // Load skating assessments in background
  static Future<List<SkatingAssessment>> loadSkatingAssessmentsIsolate(int playerId) async {
    final db = LocalDatabaseService.instance;
    return await db.getSkatingAssessments(playerId);
  }
  
  // Load completed workouts in background
  static Future<List<CompletedWorkout>> loadCompletedWorkoutsIsolate(int playerId) async {
    final db = LocalDatabaseService.instance;
    return await db.getCompletedWorkouts(playerId);
  }
  
  // Load training programs in background
  static Future<List<TrainingProgram>> loadTrainingProgramsIsolate(_) async {
    final db = LocalDatabaseService.instance;
    return await db.getTrainingPrograms();
  }
}