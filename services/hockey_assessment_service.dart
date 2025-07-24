// lib/services/hockey_assessment_service.dart
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/services/index.dart';

/// Assessment categories for player strengths/weaknesses
enum AssessmentCategory {
  accuracy, // Overall shooting accuracy
  power, // Shot power/velocity
  quickRelease, // Time to execute shot
  consistency, // Consistency across shot types
  zoneBalance, // Balance across different zones
  shotVariety, // Variety of shot types used
}

/// Workout group assignments based on assessment
enum WorkoutGroup {
  powerDevelopment, // Focus on increasing shot power
  accuracyRefinement, // Focus on shot placement precision
  quickReleaseTraining, // Focus on reducing release time
  balancedDevelopment, // Balanced improvement across all areas
  advancedTechnique, // For players with strong fundamentals
  gameReadiness, // Game-situation focus for well-rounded players
}

/// Client-side service for player assessment
class HockeyAssessmentService {
  final ApiService _api;

  HockeyAssessmentService(this._api);

  /// Get assessment from the server
  Future<Map<String, dynamic>> assessPlayer(int playerId) async {
    try {
      // Get assessment from API
      final assessment = await _api.fetchPlayerAssessment(playerId);
      
      // Convert server scores to Dart enum map
      final scores = <AssessmentCategory, double>{};
      scores[AssessmentCategory.accuracy] = assessment['scores']?['accuracy'] ?? 5.0;
      scores[AssessmentCategory.power] = assessment['scores']?['power'] ?? 5.0;
      scores[AssessmentCategory.quickRelease] = assessment['scores']?['quickRelease'] ?? 5.0;
      scores[AssessmentCategory.consistency] = assessment['scores']?['consistency'] ?? 5.0;
      scores[AssessmentCategory.zoneBalance] = assessment['scores']?['zoneBalance'] ?? 5.0;
      scores[AssessmentCategory.shotVariety] = assessment['scores']?['shotVariety'] ?? 5.0;
      
      // Convert server-side workout group to Dart enum
      final workoutGroupString = assessment['recommended_workout_group'] ?? 'balancedDevelopment';
      final workoutGroup = _stringToWorkoutGroup(workoutGroupString);
      
      // Extract strengths and weaknesses
      final List<String> strengthStrings = List<String>.from(assessment['strengths'] ?? []);
      final List<String> weaknessStrings = List<String>.from(assessment['weaknesses'] ?? []);
      
      final strengths = strengthStrings.map(_stringToCategory).whereType<AssessmentCategory>().toList();
      final weaknesses = weaknessStrings.map(_stringToCategory).whereType<AssessmentCategory>().toList();
      
      // Get most common zone (with null safety)
      final String mostCommonZone = assessment['most_common_zone'] ?? '0';
      
      return {
        'scores': scores,
        'strengths': strengths,
        'weaknesses': weaknesses,
        'workoutGroup': workoutGroup,
        'mostCommonZone': mostCommonZone,
      };
    } catch (e) {
      // Fallback to default values in case of error
      print('Error fetching assessment: $e');
      return {
        'scores': {
          AssessmentCategory.accuracy: 5.0,
          AssessmentCategory.power: 5.0,
          AssessmentCategory.quickRelease: 5.0,
          AssessmentCategory.consistency: 5.0,
          AssessmentCategory.zoneBalance: 5.0,
          AssessmentCategory.shotVariety: 5.0,
        },
        'strengths': <AssessmentCategory>[],
        'weaknesses': <AssessmentCategory>[],
        'workoutGroup': WorkoutGroup.balancedDevelopment,
        'mostCommonZone': '0',
      };
    }
  }
  
  // Helper methods to convert strings to enums
  AssessmentCategory? _stringToCategory(String categoryString) {
    try {
      return AssessmentCategory.values.firstWhere(
        (c) => c.toString().split('.').last.toLowerCase() == categoryString.toLowerCase()
      );
    } catch (e) {
      return null;
    }
  }
  
  WorkoutGroup _stringToWorkoutGroup(String groupString) {
    try {
      return WorkoutGroup.values.firstWhere(
        (g) => g.toString().split('.').last.toLowerCase() == groupString.toLowerCase(),
        orElse: () => WorkoutGroup.balancedDevelopment,
      );
    } catch (e) {
      return WorkoutGroup.balancedDevelopment;
    }
  }
  
  /// Gets human-readable name for an assessment category
  static String getCategoryName(AssessmentCategory category) {
    switch (category) {
      case AssessmentCategory.accuracy:
        return 'Accuracy';
      case AssessmentCategory.power:
        return 'Power';
      case AssessmentCategory.quickRelease:
        return 'Quick Release';
      case AssessmentCategory.consistency:
        return 'Consistency';
      case AssessmentCategory.zoneBalance:
        return 'Zone Coverage';
      case AssessmentCategory.shotVariety:
        return 'Shot Type Variety';
    }
  }

  /// Gets human-readable name for a workout group
  static String getWorkoutGroupName(WorkoutGroup group) {
    switch (group) {
      case WorkoutGroup.powerDevelopment:
        return 'Power Development';
      case WorkoutGroup.accuracyRefinement:
        return 'Accuracy Refinement';
      case WorkoutGroup.quickReleaseTraining:
        return 'Quick Release Training';
      case WorkoutGroup.balancedDevelopment:
        return 'Balanced Development';
      case WorkoutGroup.advancedTechnique:
        return 'Advanced Technique';
      case WorkoutGroup.gameReadiness:
        return 'Game Readiness';
    }
  }

  /// Gets the description of a workout group
  static String getWorkoutGroupDescription(WorkoutGroup group) {
    switch (group) {
      case WorkoutGroup.powerDevelopment:
        return 'Focus on developing shot power and velocity';
      case WorkoutGroup.accuracyRefinement:
        return 'Precision-focused training to improve shot placement';
      case WorkoutGroup.quickReleaseTraining:
        return 'Training focused on reducing shot preparation time';
      case WorkoutGroup.balancedDevelopment:
        return 'Comprehensive program addressing all shooting aspects';
      case WorkoutGroup.advancedTechnique:
        return 'High-level program for skilled shooters focusing on technical mastery';
      case WorkoutGroup.gameReadiness:
        return 'Prepare for real-game shooting scenarios and pressure situations';
    }
  }
  
  /// Gets workout plan details based on assigned group
  Map<String, dynamic> getWorkoutPlan(WorkoutGroup group, Map<AssessmentCategory, double> scores) {
    switch (group) {
      case WorkoutGroup.powerDevelopment:
        return _getPowerDevelopmentPlan(scores);
      case WorkoutGroup.accuracyRefinement:
        return _getAccuracyRefinementPlan(scores);
      case WorkoutGroup.quickReleaseTraining:
        return _getQuickReleaseTrainingPlan(scores);
      case WorkoutGroup.balancedDevelopment:
        return _getBalancedDevelopmentPlan(scores);
      case WorkoutGroup.advancedTechnique:
        return _getAdvancedTechniquePlan(scores);
      case WorkoutGroup.gameReadiness:
        return _getGameReadinessPlan(scores);
    }
  }
  
  // Specific workout plan details
  Map<String, dynamic> _getPowerDevelopmentPlan(Map<AssessmentCategory, double> scores) {
    final isWeak = scores[AssessmentCategory.power]! < 3.0;
    final isVeryWeak = scores[AssessmentCategory.power]! < 1.5;

    return {
      'title': 'Power Development Program',
      'description': 'Focus on developing shot power and velocity',
      'duration': '4-6 weeks',
      'primaryFocus': 'Shot power',
      'secondaryFocus': 'Shot mechanics and follow-through',
      'weeklyWorkouts': 3,
      'primaryPrograms': [
        'Power Shot Development',
        'Slap Shot Mastery',
        'Explosive Shot Training',
      ],
      'supplementalPrograms': [
        'Wrist Strengthening',
        'Core Power Development',
      ],
      'offIceTraining': [
        'Resistance band shooting',
        'Weighted stick handling',
        'Upper body/core strength training',
      ],
      'intensity': isVeryWeak ? 'High' : (isWeak ? 'Moderate-High' : 'Moderate'),
      'progressionMetric': 'Average shot power (measured in MPH)',
      'targetImprovement': '20-30% increase in shot power',
      'weeklyShots': 200,
      'zones': isWeak ? ['7', '8', '9'] : ['1', '3', '7', '9'], // Corner shots require more power
      'shotTypes': ['Slap', 'Snap', 'Wrist'],
    };
  }

  Map<String, dynamic> _getAccuracyRefinementPlan(Map<AssessmentCategory, double> scores) {
    final zoneBalanceWeakness = scores[AssessmentCategory.zoneBalance]! < 6.0;

    return {
      'title': 'Accuracy Refinement Program',
      'description': 'Precision-focused training to improve shot placement',
      'duration': '3-5 weeks',
      'primaryFocus': 'Shot accuracy and placement',
      'secondaryFocus': 'Consistency across zones',
      'weeklyWorkouts': 4,
      'primaryPrograms': [
        'Target Precision Training',
        'Zone Mastery Program',
        'Corner Sniper Workout',
      ],
      'supplementalPrograms': [
        'Vision Training',
        'Stick Handling Precision',
      ],
      'offIceTraining': [
        'Target practice with tennis balls',
        'Eye-hand coordination drills',
        'Balance and posture exercises',
      ],
      'intensity': 'Moderate',
      'progressionMetric': 'Shot success rate by zone',
      'targetImprovement': '15-25% increase in overall accuracy',
      'weeklyShots': 250,
      'zones': zoneBalanceWeakness ? ['1', '2', '3', '4', '5', '6', '7', '8', '9'] : ['1', '3', '7', '9'], // Focus on corners
      'shotTypes': ['Wrist', 'Snap'],
    };
  }

  Map<String, dynamic> _getQuickReleaseTrainingPlan(Map<AssessmentCategory, double> scores) {
    final isVeryWeak = scores[AssessmentCategory.quickRelease]! < 1.5;

    return {
      'title': 'Quick Release Development',
      'description': 'Training focused on reducing shot preparation time',
      'duration': '3-4 weeks',
      'primaryFocus': 'Shot release speed',
      'secondaryFocus': 'Receiving passes and transitioning to shots',
      'weeklyWorkouts': 5,
      'primaryPrograms': [
        'Quick Release Training',
        'Snap Shot Development',
        'Rapid Fire Program',
      ],
      'supplementalPrograms': [
        'Hand-Eye Coordination',
        'Reaction Time Training',
      ],
      'offIceTraining': [
        'Quick hands drills',
        'Rapid stick handling exercises',
        'Wrist and forearm exercises',
      ],
      'intensity': isVeryWeak ? 'High' : 'Moderate-High',
      'progressionMetric': 'Time from puck reception to release',
      'targetImprovement': '30% decrease in release time',
      'weeklyShots': 300,
      'zones': ['2', '5', '8'], // Focus on central zones for quick shots
      'shotTypes': ['Snap', 'Wrist', 'One-timer'],
    };
  }

  Map<String, dynamic> _getBalancedDevelopmentPlan(Map<AssessmentCategory, double> scores) {
    return {
      'title': 'Balanced Shot Development',
      'description': 'Comprehensive program addressing all shooting aspects',
      'duration': '6-8 weeks',
      'primaryFocus': 'Overall shooting skills',
      'secondaryFocus': 'Adaptability and versatility',
      'weeklyWorkouts': 3,
      'primaryPrograms': [
        'Complete Shooter Program',
        'Basic Shooting Practice',
        'All-Zone Training',
      ],
      'supplementalPrograms': [
        'Type Transition Drills',
        'Zone Coverage Practice',
      ],
      'offIceTraining': [
        'Full-body conditioning',
        'Shooting mechanics analysis',
        'Video review of proper technique',
      ],
      'intensity': 'Moderate',
      'progressionMetric': 'Overall success rate and zone coverage',
      'targetImprovement': '15% improvement across all metrics',
      'weeklyShots': 180,
      'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'], // Practice all zones
      'shotTypes': ['Wrist', 'Snap', 'Slap', 'Backhand'],
    };
  }

  Map<String, dynamic> _getAdvancedTechniquePlan(Map<AssessmentCategory, double> scores) {
    final weaknesses = _findWeaknesses(scores);

    return {
      'title': 'Advanced Technique Refinement',
      'description': 'High-level program for skilled shooters focusing on technical mastery',
      'duration': '4-6 weeks',
      'primaryFocus': 'Technical refinement',
      'secondaryFocus': weaknesses.isNotEmpty ? getCategoryName(weaknesses.first) : 'Shot deception',
      'weeklyWorkouts': 4,
      'primaryPrograms': [
        'Elite Shooter Development',
        'Technical Mastery Program',
        'Advanced Shot Placement',
      ],
      'supplementalPrograms': [
        'Deceptive Release Training',
        'Goalie Reading Skills',
      ],
      'offIceTraining': [
        'Advanced stick flex exercises',
        'Shot analysis with video feedback',
        'Mental visualization techniques',
      ],
      'intensity': 'Moderate-High',
      'progressionMetric': 'Technical precision scores',
      'targetImprovement': '10% improvement in technical execution',
      'weeklyShots': 220,
      'zones': ['1', '3', '5', '7', '9'], // Focus on key scoring zones
      'shotTypes': ['Wrist', 'Snap', 'Slap', 'One-timer'],
    };
  }

  Map<String, dynamic> _getGameReadinessPlan(Map<AssessmentCategory, double> scores) {
    return {
      'title': 'Game Situation Readiness',
      'description': 'Prepare for real-game shooting scenarios and pressure situations',
      'duration': '4 weeks',
      'primaryFocus': 'Game-situation shooting',
      'secondaryFocus': 'Decision making under pressure',
      'weeklyWorkouts': 3,
      'primaryPrograms': [
        'Game Situation Shots',
        'Pressure Training Series',
        'Decision-Speed Development',
      ],
      'supplementalPrograms': [
        'Defensive Pressure Simulation',
        'Time Constraint Shooting',
      ],
      'offIceTraining': [
        'Cognitive decision making drills',
        'Pressure simulation exercises',
        'Visual cue recognition training',
      ],
      'intensity': 'High',
      'progressionMetric': 'Success rate under simulated pressure',
      'targetImprovement': '15% improvement in game-situation effectiveness',
      'weeklyShots': 150,
      'zones': ['1', '3', '5', '7', '9'], // Focus on key scoring zones
      'shotTypes': ['Snap', 'One-timer', 'Wrist'],
    };
  }
  
  // Helper method to find weaknesses in scores
  List<AssessmentCategory> _findWeaknesses(Map<AssessmentCategory, double> scores) {
    final weaknesses = <AssessmentCategory>[];
    final lowThreshold = 3.0;
    
    for (final entry in scores.entries) {
      if (entry.value <= lowThreshold) {
        weaknesses.add(entry.key);
      }
    }
    
    // If no clear weaknesses, find lowest score
    if (weaknesses.isEmpty) {
      AssessmentCategory? lowestCategory;
      double lowestScore = 10.0;
      
      for (final entry in scores.entries) {
        if (entry.value < lowestScore) {
          lowestScore = entry.value;
          lowestCategory = entry.key;
        }
      }
      
      if (lowestCategory != null) {
        weaknesses.add(lowestCategory);
      }
    }
    
    return weaknesses;
  }
}