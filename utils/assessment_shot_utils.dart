import 'package:flutter/material.dart';
import 'dart:math' as Math;
import '../models/shot.dart';

class AssessmentShotUtils {
  // Calculate assessment results with intended vs actual zone analysis
  static Map<String, dynamic> calculateResults(
    Map<String, dynamic> assessment,
    Map<int, List<Shot>> shotResults,
  ) {
    // Get assessment groups with intended zone configuration
    final groups = (assessment['groups'] as List<dynamic>? ?? [])
        .map((g) => g as Map<String, dynamic>)
        .toList();

    // Initialize tracking structures
    final zoneRates = <String, double>{};
    final typeRates = <String, double>{};
    final categoryScores = <String, double>{
      'Accuracy': 0.0,
      'Technique': 0.0,
      'Power': 0.0,
      'Consistency': 0.0,
    };

    // NEW: Miss pattern tracking
    final missPatterns = <String, int>{
      'miss_left': 0,
      'miss_high': 0,
      'miss_right': 0,
      'zone_misses': 0, // Wrong zone within net
    };

    // NEW: Intended vs actual zone tracking
    final intendedZonePerformance = <int, Map<String, dynamic>>{};
    
    int totalShots = 0;
    int totalSuccesses = 0;
    int totalIntendedHits = 0; // NEW: Shots that hit intended zones
    double totalPower = 0.0;
    int powerShotCount = 0;

    // Process each group with its intended zone configuration
    for (var entry in shotResults.entries) {
      final groupIndex = entry.key;
      final groupShots = entry.value;
      
      // Get group configuration
      final groupConfig = groupIndex < groups.length ? groups[groupIndex] : null;
      final intendedZones = groupConfig?['intendedZones'] as List<dynamic>? ?? 
                           groupConfig?['targetZones'] as List<dynamic>? ?? [];
      final adjacentZones = groupConfig?['adjacentZones'] as List<dynamic>? ?? [];
      
      // Track group performance
      int groupTotal = 0;
      int groupIntendedHits = 0;
      int groupSuccesses = 0;
      
      for (var shot in groupShots) {
        final zone = shot.zone;
        final shotType = shot.type;
        final isSuccess = shot.success;
        
        groupTotal++;
        totalShots++;
        
        if (isSuccess) {
          groupSuccesses++;
          totalSuccesses++;
        }
        
        // NEW: Analyze miss patterns
        if (zone.startsWith('miss_')) {
          missPatterns[zone] = (missPatterns[zone] ?? 0) + 1;
        } else {
          // Shot hit the net - check if it hit intended zone
          if (intendedZones.map((z) => z.toString()).contains(zone)) {
            groupIntendedHits++;
            totalIntendedHits++;
          } else {
            // Hit net but wrong zone
            missPatterns['zone_misses'] = (missPatterns['zone_misses'] ?? 0) + 1;
          }
        }
        
        // Track zone performance (traditional)
        final zoneKey = zone.startsWith('miss_') ? 'misses' : zone;
        final currentZoneShots = _getZoneShots(zoneRates, zoneKey);
        final currentZoneSuccesses = _getZoneSuccesses(zoneRates, zoneKey);
        zoneRates[zoneKey] = (currentZoneSuccesses + (isSuccess ? 1 : 0)) / 
                            (currentZoneShots + 1);
        
        // Track shot type performance
        final currentTypeShots = _getTypeShots(typeRates, shotType);
        final currentTypeSuccesses = _getTypeSuccesses(typeRates, shotType);
        typeRates[shotType] = (currentTypeSuccesses + (isSuccess ? 1 : 0)) / 
                             (currentTypeShots + 1);
        
        // Track power
        if (shot.power != null) {
          totalPower += shot.power!;
          powerShotCount++;
        }
      }
      
      // Store group performance
      intendedZonePerformance[groupIndex] = {
        'total_shots': groupTotal,
        'intended_hits': groupIntendedHits,
        'successes': groupSuccesses,
        'intended_hit_rate': groupTotal > 0 ? groupIntendedHits / groupTotal : 0.0,
        'success_rate': groupTotal > 0 ? groupSuccesses / groupTotal : 0.0,
        'group_config': groupConfig,
      };
    }

    // Calculate overall metrics
    final overallRate = totalShots > 0 ? totalSuccesses / totalShots : 0.0;
    final intendedHitRate = totalShots > 0 ? totalIntendedHits / totalShots : 0.0;
    final averagePower = powerShotCount > 0 ? totalPower / powerShotCount : 0.0;

    // NEW: Calculate sophisticated category scores
    categoryScores['Accuracy'] = _calculateAccuracyScore(intendedHitRate, missPatterns, totalShots);
    categoryScores['Power'] = _calculatePowerScore(averagePower);
    categoryScores['Technique'] = _calculateTechniqueScore(missPatterns, totalShots, overallRate);
    categoryScores['Consistency'] = _calculateConsistencyScore(intendedZonePerformance);

    // Calculate overall score
    final overallScore = _calculateOverallScore(categoryScores, assessment);

    // Determine performance level
    final performanceLevel = _getPerformanceLevel(overallScore);

    // Generate strengths and improvements with sophisticated analysis
    final analysis = _generateStrengthsAndImprovements(
      categoryScores, 
      intendedZonePerformance, 
      missPatterns, 
      totalShots
    );

    // NEW: Generate miss pattern analysis for recommendation engine
    final missPatternAnalysis = _generateMissPatternAnalysis(missPatterns, totalShots);

    return {
      'overallScore': overallScore,
      'overallRate': overallRate,
      'intendedHitRate': intendedHitRate, // NEW
      'categoryScores': categoryScores,
      'zoneRates': zoneRates,
      'typeRates': typeRates,
      'performanceLevel': performanceLevel,
      'strengths': analysis['strengths'],
      'improvements': analysis['improvements'],
      // NEW: Enhanced data for recommendation engine
      'missPatterns': missPatterns,
      'missPatternAnalysis': missPatternAnalysis,
      'intendedZonePerformance': intendedZonePerformance,
      'totalShots': totalShots,
      'totalIntendedHits': totalIntendedHits,
      'averagePower': averagePower,
    };
  }

  // NEW: Calculate accuracy score based on intended zone performance
  static double _calculateAccuracyScore(double intendedHitRate, Map<String, int> missPatterns, int totalShots) {
    if (totalShots == 0) return 0.0;
    
    // Base score from intended zone hits (0-7 points)
    double baseScore = intendedHitRate * 7.0;
    
    // Penalty for missing the net entirely (up to -3 points)
    final totalMisses = (missPatterns['miss_left'] ?? 0) + 
                       (missPatterns['miss_high'] ?? 0) + 
                       (missPatterns['miss_right'] ?? 0);
    final missRate = totalMisses / totalShots;
    final missPenalty = missRate * 3.0;
    
    return Math.max(0.0, Math.min(10.0, baseScore - missPenalty + 3.0));
  }

  // NEW: Calculate technique score based on miss patterns
  static double _calculateTechniqueScore(Map<String, int> missPatterns, int totalShots, double successRate) {
    if (totalShots == 0) return 0.0;
    
    // Base score from success rate
    double baseScore = successRate * 6.0;
    
    // Analyze miss patterns for technique issues
    final highMisses = missPatterns['miss_high'] ?? 0;
    final sideMisses = (missPatterns['miss_left'] ?? 0) + (missPatterns['miss_right'] ?? 0);
    
    // High misses indicate trajectory/weight transfer issues
    final highMissRate = highMisses / totalShots;
    final highPenalty = highMissRate * 2.0;
    
    // Side misses indicate alignment issues
    final sideMissRate = sideMisses / totalShots;
    final sidePenalty = sideMissRate * 1.5;
    
    return Math.max(0.0, Math.min(10.0, baseScore - highPenalty - sidePenalty + 4.0));
  }

  // NEW: Calculate consistency score based on intended zone performance across groups
  static double _calculateConsistencyScore(Map<int, Map<String, dynamic>> intendedZonePerformance) {
    if (intendedZonePerformance.isEmpty) return 5.0;
    
    final hitRates = intendedZonePerformance.values
        .map((group) => group['intended_hit_rate'] as double)
        .toList();
    
    if (hitRates.isEmpty) return 5.0;
    
    // Calculate coefficient of variation
    final mean = hitRates.reduce((a, b) => a + b) / hitRates.length;
    if (mean == 0) return 5.0;
    
    final variance = hitRates.map((rate) => Math.pow(rate - mean, 2)).reduce((a, b) => a + b) / hitRates.length;
    final stdDev = Math.sqrt(variance);
    final coefficientOfVariation = stdDev / mean;
    
    // Convert to 0-10 scale (lower CV = higher consistency score)
    return Math.max(0.0, Math.min(10.0, 10.0 - (coefficientOfVariation * 15.0)));
  }

  // NEW: Generate miss pattern analysis for recommendation engine
  static Map<String, dynamic> _generateMissPatternAnalysis(Map<String, int> missPatterns, int totalShots) {
    if (totalShots == 0) {
      return {
        'high_percentage': 0.0,
        'low_percentage': 0.0,
        'wide_percentage': 0.0,
        'total_shots': 0,
      };
    }
    
    final highMisses = missPatterns['miss_high'] ?? 0;
    final wideMisses = (missPatterns['miss_left'] ?? 0) + (missPatterns['miss_right'] ?? 0);
    // Note: We don't track low misses with current miss buttons, but could be inferred from zone data
    
    return {
      'high_percentage': highMisses / totalShots,
      'low_percentage': 0.0, // Could be enhanced to detect low shots in zones 7,8,9
      'wide_percentage': wideMisses / totalShots,
      'total_shots': totalShots,
      'miss_distribution': {
        'high': highMisses,
        'wide': wideMisses,
        'zone_misses': missPatterns['zone_misses'] ?? 0,
      },
    };
  }

  // NEW: Generate sophisticated strengths and improvements
  static Map<String, List<String>> _generateStrengthsAndImprovements(
    Map<String, double> categoryScores,
    Map<int, Map<String, dynamic>> intendedZonePerformance,
    Map<String, int> missPatterns,
    int totalShots,
  ) {
    final strengths = <String>[];
    final improvements = <String>[];

    // Category-based analysis
    for (var entry in categoryScores.entries) {
      if (entry.value >= 7.5) {
        strengths.add('Excellent ${entry.key.toLowerCase()} (${entry.value.toStringAsFixed(1)}/10)');
      } else if (entry.value < 4.5) {
        improvements.add('${entry.key} needs development (${entry.value.toStringAsFixed(1)}/10)');
      }
    }

    // Miss pattern analysis
    if (totalShots > 0) {
      final highMissRate = (missPatterns['miss_high'] ?? 0) / totalShots;
      final wideMissRate = ((missPatterns['miss_left'] ?? 0) + (missPatterns['miss_right'] ?? 0)) / totalShots;
      
      if (highMissRate > 0.2) {
        improvements.add('Shots missing high - focus on weight transfer and follow-through');
      }
      if (wideMissRate > 0.25) {
        improvements.add('Directional accuracy - work on body alignment and hip rotation');
      }
      if (highMissRate < 0.1 && wideMissRate < 0.15) {
        strengths.add('Excellent shot trajectory control');
      }
    }

    // Intended zone performance analysis
    for (var entry in intendedZonePerformance.entries) {
      final groupData = entry.value;
      final intendedHitRate = groupData['intended_hit_rate'] as double;
      final groupConfig = groupData['group_config'] as Map<String, dynamic>?;
      final groupTitle = groupConfig?['title'] as String? ?? 'Group ${entry.key + 1}';
      
      if (intendedHitRate >= 0.7) {
        strengths.add('Strong performance in $groupTitle (${(intendedHitRate * 100).toStringAsFixed(0)}% on target)');
      } else if (intendedHitRate < 0.4) {
        improvements.add('$groupTitle accuracy needs work (${(intendedHitRate * 100).toStringAsFixed(0)}% on target)');
      }
    }

    // Ensure we have at least some feedback
    if (strengths.isEmpty) {
      strengths.add('Basic shooting fundamentals in place');
    }
    if (improvements.isEmpty) {
      improvements.add('Continue practicing for consistency');
    }

    return {
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  // Existing helper methods (updated)
  static double _calculatePowerScore(double power) {
    if (power >= 90) return 10.0;
    if (power >= 85) return 9.0;
    if (power >= 80) return 8.0;
    if (power >= 75) return 7.0;
    if (power >= 70) return 6.0;
    if (power >= 65) return 5.0;
    if (power >= 60) return 4.0;
    if (power >= 55) return 3.0;
    if (power >= 50) return 2.0;
    if (power > 0) return 1.0;
    return 0.0;
  }

  static double _calculateOverallScore(Map<String, double> categoryScores, Map<String, dynamic> assessment) {
    final categoryWeights = assessment['categoryWeights'] as Map<String, dynamic>?;
    
    if (categoryWeights != null && categoryWeights.isNotEmpty) {
      double weightedScore = 0.0;
      double totalWeight = 0.0;
      
      for (var category in categoryScores.keys) {
        if (categoryWeights.containsKey(category)) {
          final weight = (categoryWeights[category] as num).toDouble();
          weightedScore += categoryScores[category]! * weight;
          totalWeight += weight;
        }
      }
      
      return totalWeight > 0 ? weightedScore / totalWeight : 0.0;
    } else {
      // Default equal weighting
      return categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;
    }
  }

  static String _getPerformanceLevel(double score) {
    if (score >= 8.5) return 'Elite';
    if (score >= 7.0) return 'Advanced';
    if (score >= 5.5) return 'Intermediate';
    if (score >= 4.0) return 'Developing';
    return 'Beginner';
  }

  // Helper methods for zone/type tracking
  static int _getZoneShots(Map<String, double> zoneRates, String zone) {
    // This is a simplified helper - in a full implementation, you'd track counts separately
    return 1; // Placeholder
  }

  static int _getZoneSuccesses(Map<String, double> zoneRates, String zone) {
    // This is a simplified helper - in a full implementation, you'd track successes separately
    return zoneRates[zone] != null ? (zoneRates[zone]! * 1).round() : 0; // Placeholder
  }

  static int _getTypeShots(Map<String, double> typeRates, String type) {
    return 1; // Placeholder
  }

  static int _getTypeSuccesses(Map<String, double> typeRates, String type) {
    return typeRates[type] != null ? (typeRates[type]! * 1).round() : 0; // Placeholder
  }

  // Existing color methods
  static Color getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.5) return Colors.lightGreen;
    if (score >= 5.0) return Colors.orange;
    if (score >= 3.5) return Colors.deepOrange;
    return Colors.red;
  }

  static Color getSuccessRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.orange;
    if (rate >= 0.2) return Colors.deepOrange;
    return Colors.red;
  }

  // Existing helper methods
  static Map<int, List<Shot>> convertExistingShotResults(Map<int, List<dynamic>> existingResults) {
    final result = <int, List<Shot>>{};

    existingResults.forEach((groupIndex, shots) {
      result[groupIndex] = [];

      for (var existingShot in shots) {
        final shot = Shot(
          id: DateTime.now().millisecondsSinceEpoch,
          playerId: int.tryParse(existingShot['playerId']?.toString() ?? '0') ?? 0,
          zone: existingShot['zone']?.toString() ?? '0',
          type: existingShot['type']?.toString() ?? 'Wrist',
          success: existingShot['success'] == true || existingShot['success'] == 1,
          outcome: existingShot['success'] == true ? 'Goal' : 'Miss',
          timestamp: DateTime.now(),
          power: (existingShot['power'] as num?)?.toDouble(),
          quickRelease: (existingShot['quick_release'] as num?)?.toDouble(),
          source: 'assessment',
        );
        
        result[groupIndex]!.add(shot);
      }
    });

    return result;
  }

  static Map<String, dynamic> createResultsFromAnalytics(
    Map<String, dynamic> analytics,
    {String? playerName}
  ) {
    return analytics;
  }
}