// lib/services/miss_pattern_analyzer.dart

import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';

class MissPatternAnalyzer {
  
  /// Analyze miss patterns from precision assessment results
  static Map<String, dynamic> analyzePrecisionAssessment({
    required AssessmentTemplate template,
    required Map<int, List<Shot>> shotResults,
  }) {
    final analysis = <String, dynamic>{
      'totalShots': 0,
      'overallAccuracy': 0.0,
      'groupAnalysis': <String, Map<String, dynamic>>{},
      'missPatterns': <String, dynamic>{},
      'recommendations': <String, dynamic>{},
    };

    int totalShots = 0;
    int totalSuccesses = 0;
    Map<String, int> overallMissCounts = {
      'high': 0,
      'low': 0, 
      'left': 0,
      'right': 0,
      'small_miss': 0,
      'large_miss': 0,
    };

    // Analyze each group
    for (int groupIndex = 0; groupIndex < template.groups.length; groupIndex++) {
      final group = template.groups[groupIndex];
      final shots = shotResults[groupIndex] ?? [];
      
      if (shots.isEmpty) continue;

      final groupAnalysis = _analyzeGroupMissPatterns(group, shots);
      analysis['groupAnalysis'][group.id] = groupAnalysis;
      
      totalShots += shots.length;
      totalSuccesses += groupAnalysis['successCount'] as int;
      
      // Aggregate miss patterns
      final groupMisses = groupAnalysis['missCounts'] as Map<String, int>;
      groupMisses.forEach((key, value) {
        overallMissCounts[key] = (overallMissCounts[key] ?? 0) + value;
      });
    }

    analysis['totalShots'] = totalShots;
    analysis['overallAccuracy'] = totalShots > 0 ? totalSuccesses / totalShots : 0.0;
    
    // Calculate miss pattern percentages
    analysis['missPatterns'] = _calculateMissPatternPercentages(overallMissCounts, totalShots);
    
    // Generate recommendations based on miss patterns
    analysis['recommendations'] = _generateMissPatternRecommendations(
      analysis['missPatterns'] as Map<String, dynamic>,
      analysis['groupAnalysis'] as Map<String, Map<String, dynamic>>,
    );

    return analysis;
  }

  /// Analyze miss patterns for a specific group
  static Map<String, dynamic> _analyzeGroupMissPatterns(
    AssessmentGroup group,
    List<Shot> shots,
  ) {
    final intendedZones = group.parameters['intentedZones'] as List<dynamic>? ?? [];
    final smallMissZones = group.parameters['smallMissZones'] as List<dynamic>? ?? [];
    final largeMissZones = group.parameters['largeMissZones'] as List<dynamic>? ?? [];
    final missPatternType = group.parameters['missPatternType'] as String? ?? '';

    int successCount = 0;
    int smallMissCount = 0;
    int largeMissCount = 0;
    Map<String, int> missCounts = {
      'high': 0,
      'low': 0,
      'left': 0, 
      'right': 0,
      'small_miss': 0,
      'large_miss': 0,
    };

    Map<String, int> zoneHitCounts = {};

    for (final shot in shots) {
      final zone = shot.zone;
      zoneHitCounts[zone] = (zoneHitCounts[zone] ?? 0) + 1;

      if (intendedZones.contains(zone)) {
        // Shot hit intended zone - success
        successCount++;
      } else if (smallMissZones.contains(zone)) {
        // Shot hit adjacent zone - small miss
        smallMissCount++;
        missCounts['small_miss'] = missCounts['small_miss']! + 1;
        _categorizeDirectionalMiss(zone, intendedZones.cast<String>(), missCounts);
      } else if (largeMissZones.contains(zone)) {
        // Shot hit opposite zone - large miss
        largeMissCount++;
        missCounts['large_miss'] = missCounts['large_miss']! + 1;
        _categorizeDirectionalMiss(zone, intendedZones.cast<String>(), missCounts);
      } else {
        // Shot hit unexpected zone - classify as miss
        smallMissCount++;
        missCounts['small_miss'] = missCounts['small_miss']! + 1;
      }
    }

    final accuracy = shots.isNotEmpty ? successCount / shots.length : 0.0;

    return {
      'groupId': group.id,
      'groupTitle': group.title,
      'missPatternType': missPatternType,
      'totalShots': shots.length,
      'successCount': successCount,
      'smallMissCount': smallMissCount,
      'largeMissCount': largeMissCount,
      'accuracy': accuracy,
      'intendedZones': intendedZones,
      'missCounts': missCounts,
      'zoneDistribution': zoneHitCounts,
    };
  }

  /// Categorize miss by direction (high/low/left/right)
  static void _categorizeDirectionalMiss(
    String hitZone,
    List<String> intendedZones,
    Map<String, int> missCounts,
  ) {
    final zoneNum = int.tryParse(hitZone) ?? 5;
    
    // Zone layout:
    // 1 2 3
    // 4 5 6  
    // 7 8 9
    
    // Determine if miss is high/low
    if ([1, 2, 3].contains(zoneNum)) {
      // Hit top zones
      if (!intendedZones.any((zone) => [1, 2, 3].contains(int.tryParse(zone)))) {
        missCounts['high'] = missCounts['high']! + 1;
      }
    } else if ([7, 8, 9].contains(zoneNum)) {
      // Hit bottom zones
      if (!intendedZones.any((zone) => [7, 8, 9].contains(int.tryParse(zone)))) {
        missCounts['low'] = missCounts['low']! + 1;
      }
    }
    
    // Determine if miss is left/right
    if ([1, 4, 7].contains(zoneNum)) {
      // Hit left zones
      if (!intendedZones.any((zone) => [1, 4, 7].contains(int.tryParse(zone)))) {
        missCounts['left'] = missCounts['left']! + 1;
      }
    } else if ([3, 6, 9].contains(zoneNum)) {
      // Hit right zones  
      if (!intendedZones.any((zone) => [3, 6, 9].contains(int.tryParse(zone)))) {
        missCounts['right'] = missCounts['right']! + 1;
      }
    }
  }

  /// Calculate miss pattern percentages
  static Map<String, dynamic> _calculateMissPatternPercentages(
    Map<String, int> missCounts,
    int totalShots,
  ) {
    if (totalShots == 0) {
      return {
        'high_percentage': 0.0,
        'low_percentage': 0.0,
        'left_percentage': 0.0,
        'right_percentage': 0.0,
        'small_miss_percentage': 0.0,
        'large_miss_percentage': 0.0,
      };
    }

    return {
      'high_percentage': (missCounts['high'] ?? 0) / totalShots,
      'low_percentage': (missCounts['low'] ?? 0) / totalShots,
      'left_percentage': (missCounts['left'] ?? 0) / totalShots,
      'right_percentage': (missCounts['right'] ?? 0) / totalShots,
      'small_miss_percentage': (missCounts['small_miss'] ?? 0) / totalShots,
      'large_miss_percentage': (missCounts['large_miss'] ?? 0) / totalShots,
      'wide_percentage': ((missCounts['left'] ?? 0) + (missCounts['right'] ?? 0)) / totalShots,
    };
  }

  /// Generate recommendations based on miss patterns
  static Map<String, dynamic> _generateMissPatternRecommendations(
    Map<String, dynamic> missPatterns,
    Map<String, Map<String, dynamic>> groupAnalysis,
  ) {
    final recommendations = <String, dynamic>{
      'primary_issues': <String>[],
      'mechanical_fixes': <String>[],
      'training_focus': <String>[],
      'priority_level': 'medium',
    };

    final highPercentage = missPatterns['high_percentage'] as double;
    final lowPercentage = missPatterns['low_percentage'] as double;
    final leftPercentage = missPatterns['left_percentage'] as double;
    final rightPercentage = missPatterns['right_percentage'] as double;
    final largeMissPercentage = missPatterns['large_miss_percentage'] as double;

    // Analyze primary miss patterns
    if (highPercentage > 0.25) {
      recommendations['primary_issues'].add('Shots consistently going high');
      recommendations['mechanical_fixes'].add('Improve weight transfer and follow-through');
      recommendations['training_focus'].add('Weight transfer drills');
    }

    if (lowPercentage > 0.25) {
      recommendations['primary_issues'].add('Shots consistently going low');
      recommendations['mechanical_fixes'].add('Improve puck contact point and blade control');
      recommendations['training_focus'].add('Puck contact drills');
    }

    if (leftPercentage > 0.25) {
      recommendations['primary_issues'].add('Shots consistently missing left');
      recommendations['mechanical_fixes'].add('Check body alignment and hip rotation');
      recommendations['training_focus'].add('Alignment and stance work');
    }

    if (rightPercentage > 0.25) {
      recommendations['primary_issues'].add('Shots consistently missing right');
      recommendations['mechanical_fixes'].add('Adjust body positioning and follow-through direction');
      recommendations['training_focus'].add('Body positioning drills');
    }

    if (largeMissPercentage > 0.20) {
      recommendations['primary_issues'].add('Poor overall accuracy and control');
      recommendations['mechanical_fixes'].add('Focus on fundamental shooting mechanics');
      recommendations['training_focus'].add('Basic accuracy training');
      recommendations['priority_level'] = 'high';
    }

    // Analyze group-specific issues
    groupAnalysis.forEach((groupId, analysis) {
      final accuracy = analysis['accuracy'] as double;
      final missPatternType = analysis['missPatternType'] as String;
      
      if (accuracy < 0.30) { // Less than 30% accuracy for intended zones
        switch (missPatternType) {
          case 'right_side_targeting':
            recommendations['training_focus'].add('Right side targeting practice');
            break;
          case 'left_side_targeting':
            recommendations['training_focus'].add('Left side targeting practice');
            break;
          case 'high_targeting':
            recommendations['training_focus'].add('Elevation control training');
            break;
          case 'low_targeting':
            recommendations['training_focus'].add('Low shot accuracy drills');
            break;
          case 'center_targeting':
            recommendations['training_focus'].add('Center mass accuracy work');
            break;
        }
      }
    });

    return recommendations;
  }

  /// Generate detailed report for coaches
  static Map<String, dynamic> generateCoachingReport(
    Map<String, dynamic> analysis,
    AssessmentTemplate template,
  ) {
    final report = <String, dynamic>{
      'player_summary': _generatePlayerSummary(analysis),
      'detailed_analysis': _generateDetailedAnalysis(analysis),
      'action_plan': _generateActionPlan(analysis),
      'progress_tracking': _generateProgressTracking(analysis),
    };

    return report;
  }

  static Map<String, dynamic> _generatePlayerSummary(Map<String, dynamic> analysis) {
    final overallAccuracy = analysis['overallAccuracy'] as double;
    final missPatterns = analysis['missPatterns'] as Map<String, dynamic>;
    final recommendations = analysis['recommendations'] as Map<String, dynamic>;
    
    String performanceLevel;
    if (overallAccuracy >= 0.70) {
      performanceLevel = 'Excellent';
    } else if (overallAccuracy >= 0.50) {
      performanceLevel = 'Good';
    } else if (overallAccuracy >= 0.30) {
      performanceLevel = 'Developing';
    } else {
      performanceLevel = 'Needs Improvement';
    }

    return {
      'overall_accuracy': overallAccuracy,
      'performance_level': performanceLevel,
      'primary_strengths': _identifyStrengths(analysis),
      'primary_weaknesses': recommendations['primary_issues'],
      'priority_level': recommendations['priority_level'],
    };
  }

  static List<String> _identifyStrengths(Map<String, dynamic> analysis) {
    final strengths = <String>[];
    final groupAnalysis = analysis['groupAnalysis'] as Map<String, Map<String, dynamic>>;
    
    groupAnalysis.forEach((groupId, group) {
      final accuracy = group['accuracy'] as double;
      final groupTitle = group['groupTitle'] as String;
      
      if (accuracy >= 0.60) {
        strengths.add('Strong performance in $groupTitle');
      }
    });

    if (strengths.isEmpty) {
      strengths.add('Consistent effort and participation');
    }

    return strengths;
  }

  static Map<String, dynamic> _generateDetailedAnalysis(Map<String, dynamic> analysis) {
    return {
      'miss_pattern_breakdown': analysis['missPatterns'],
      'group_performance': analysis['groupAnalysis'],
      'technical_insights': _generateTechnicalInsights(analysis),
    };
  }

  static List<String> _generateTechnicalInsights(Map<String, dynamic> analysis) {
    final insights = <String>[];
    final missPatterns = analysis['missPatterns'] as Map<String, dynamic>;
    
    final highPct = missPatterns['high_percentage'] as double;
    final lowPct = missPatterns['low_percentage'] as double;
    final leftPct = missPatterns['left_percentage'] as double;
    final rightPct = missPatterns['right_percentage'] as double;
    
    if (highPct > lowPct && highPct > 0.15) {
      insights.add('Tendency to shoot high suggests weight transfer issues or improper follow-through');
    }
    
    if (lowPct > highPct && lowPct > 0.15) {
      insights.add('Low shots indicate poor puck contact or insufficient follow-through');
    }
    
    if (leftPct > rightPct && leftPct > 0.15) {
      insights.add('Left bias suggests body alignment or hip rotation timing issues');
    }
    
    if (rightPct > leftPct && rightPct > 0.15) {
      insights.add('Right bias indicates need for stance and follow-through adjustment');
    }

    return insights;
  }

  static Map<String, dynamic> _generateActionPlan(Map<String, dynamic> analysis) {
    final recommendations = analysis['recommendations'] as Map<String, dynamic>;
    
    return {
      'immediate_focus': recommendations['mechanical_fixes'],
      'training_priorities': recommendations['training_focus'],
      'practice_recommendations': _generatePracticeRecommendations(analysis),
      'timeline': _generateTimeline(recommendations['priority_level'] as String),
    };
  }

  static List<String> _generatePracticeRecommendations(Map<String, dynamic> analysis) {
    final recommendations = <String>[];
    final missPatterns = analysis['missPatterns'] as Map<String, dynamic>;
    
    if ((missPatterns['high_percentage'] as double) > 0.20) {
      recommendations.add('Practice low follow-through drills');
      recommendations.add('Work on weight transfer exercises');
    }
    
    if ((missPatterns['wide_percentage'] as double) > 0.25) {
      recommendations.add('Use alignment gates during practice');
      recommendations.add('Focus on body positioning consistency');
    }
    
    recommendations.add('Repeat precision assessment in 2-3 weeks');
    
    return recommendations;
  }

  static Map<String, String> _generateTimeline(String priorityLevel) {
    switch (priorityLevel) {
      case 'high':
        return {
          'immediate': '1-2 practice sessions',
          'short_term': '1-2 weeks',
          'reassessment': '2 weeks',
        };
      case 'medium':
        return {
          'immediate': '2-3 practice sessions', 
          'short_term': '2-4 weeks',
          'reassessment': '3-4 weeks',
        };
      default:
        return {
          'immediate': '3-4 practice sessions',
          'short_term': '4-6 weeks', 
          'reassessment': '4-6 weeks',
        };
    }
  }

  static Map<String, dynamic> _generateProgressTracking(Map<String, dynamic> analysis) {
    return {
      'baseline_metrics': {
        'overall_accuracy': analysis['overallAccuracy'],
        'miss_patterns': analysis['missPatterns'],
      },
      'tracking_focus': [
        'Overall accuracy improvement',
        'Reduction in primary miss pattern',
        'Consistency across shot types',
      ],
      'success_indicators': [
        '15% improvement in target accuracy',
        '25% reduction in primary miss direction',
        'More balanced zone distribution',
      ],
    };
  }
}