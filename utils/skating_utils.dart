// utils/skating_utils.dart
import 'package:flutter/material.dart';

class SkatingUtils {
  // Updated benchmark levels (v3.0)
  static const List<String> benchmarkLevels = ['Elite', 'Advanced', 'Developing', 'Beginner'];
  static const List<String> skillLevels = ['recreational', 'competitive', 'elite'];
  static const List<String> genderOptions = ['male', 'female'];
  
  // Legacy to new benchmark level mapping
  static const Map<String, String> legacyBenchmarkMapping = {
    'Excellent': 'Elite',
    'Good': 'Advanced',
    'Average': 'Developing',
    'Below Average': 'Beginner',
  };
  
  // Research-based benchmarks v3.0
  static const Map<String, Map<String, Map<String, double>>> updatedBenchmarks = {
    'youth_8_10': {
      'forward_speed_test': {'Elite': 5.8, 'Advanced': 6.2, 'Developing': 6.6, 'Beginner': 7.2},
      'backward_speed_test': {'Elite': 6.8, 'Advanced': 7.4, 'Developing': 8.0, 'Beginner': 8.8},
      'agility_test': {'Elite': 15.0, 'Advanced': 16.5, 'Developing': 18.0, 'Beginner': 20.0},
      'transitions_test': {'Elite': 6.0, 'Advanced': 6.5, 'Developing': 7.0, 'Beginner': 7.8},
      'crossovers_test': {'Elite': 12.0, 'Advanced': 13.5, 'Developing': 15.0, 'Beginner': 17.0},
      'stop_start_test': {'Elite': 3.2, 'Advanced': 3.5, 'Developing': 3.8, 'Beginner': 4.2}
    },
    'youth_11_14': {
      'forward_speed_test': {'Elite': 4.7, 'Advanced': 5.1, 'Developing': 5.5, 'Beginner': 6.0},
      'backward_speed_test': {'Elite': 5.8, 'Advanced': 6.3, 'Developing': 6.8, 'Beginner': 7.4},
      'agility_test': {'Elite': 11.5, 'Advanced': 12.5, 'Developing': 13.8, 'Beginner': 15.2},
      'transitions_test': {'Elite': 5.0, 'Advanced': 5.5, 'Developing': 6.0, 'Beginner': 6.7},
      'crossovers_test': {'Elite': 9.5, 'Advanced': 10.5, 'Developing': 11.8, 'Beginner': 13.2},
      'stop_start_test': {'Elite': 2.7, 'Advanced': 2.9, 'Developing': 3.2, 'Beginner': 3.6}
    },
    'youth_15_18': {
      'forward_speed_test': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2},
      'backward_speed_test': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5},
      'agility_test': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8},
      'transitions_test': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5},
      'crossovers_test': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2},
      'stop_start_test': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2}
    },
    'adult': {
      'forward_speed_test': {'Elite': 3.9, 'Advanced': 4.2, 'Developing': 4.5, 'Beginner': 4.9},
      'backward_speed_test': {'Elite': 4.8, 'Advanced': 5.2, 'Developing': 5.6, 'Beginner': 6.2},
      'agility_test': {'Elite': 8.3, 'Advanced': 9.0, 'Developing': 9.8, 'Beginner': 10.8},
      'transitions_test': {'Elite': 3.8, 'Advanced': 4.2, 'Developing': 4.6, 'Beginner': 5.2},
      'crossovers_test': {'Elite': 7.2, 'Advanced': 7.8, 'Developing': 8.5, 'Beginner': 9.4},
      'stop_start_test': {'Elite': 2.0, 'Advanced': 2.2, 'Developing': 2.5, 'Beginner': 2.9}
    }
  };
  
  // Skill level adjustments (seconds to add/subtract)
  static const Map<String, Map<String, double>> skillLevelAdjustments = {
    'recreational': {
      'youth_8_10': 0.5, 'youth_11_14': 0.4, 'youth_15_18': 0.3, 'adult': 0.4
    },
    'competitive': {
      'youth_8_10': 0.0, 'youth_11_14': 0.0, 'youth_15_18': 0.0, 'adult': 0.0
    },
    'elite': {
      'youth_8_10': -0.2, 'youth_11_14': -0.2, 'youth_15_18': -0.3, 'adult': -0.3
    }
  };
  
  // Gender adjustments for 15+ age groups (seconds to add/subtract)
  static const Map<String, Map<String, double>> genderAdjustments = {
    'male': {'youth_15_18': -0.2, 'adult': -0.3},
    'female': {'youth_15_18': 0.2, 'adult': 0.3}
  };

  /// Get updated benchmarks with skill level and gender adjustments
  static Map<String, Map<String, double>> getUpdatedBenchmarks(
    String ageGroup, 
    String? skillLevel, 
    String? gender
  ) {
    final baseBenchmarks = updatedBenchmarks[ageGroup] ?? updatedBenchmarks['adult']!;
    final adjustedBenchmarks = <String, Map<String, double>>{};
    
    for (var testName in baseBenchmarks.keys) {
      final testBenchmarks = baseBenchmarks[testName]!;
      final adjustedTestBenchmarks = <String, double>{};
      
      for (var level in testBenchmarks.keys) {
        double adjustedTime = testBenchmarks[level]!;
        
        // Apply skill level adjustment
        if (skillLevel != null && skillLevelAdjustments.containsKey(skillLevel)) {
          final skillAdj = skillLevelAdjustments[skillLevel]![ageGroup] ?? 0.0;
          adjustedTime += skillAdj;
        }
        
        // Apply gender adjustment for 15+ age groups
        if (gender != null && 
            genderAdjustments.containsKey(gender) && 
            (ageGroup == 'youth_15_18' || ageGroup == 'adult')) {
          final genderAdj = genderAdjustments[gender]![ageGroup] ?? 0.0;
          adjustedTime += genderAdj;
        }
        
        adjustedTestBenchmarks[level] = adjustedTime.clamp(1.0, double.infinity);
      }
      
      adjustedBenchmarks[testName] = adjustedTestBenchmarks;
    }
    
    return adjustedBenchmarks;
  }

  /// Legacy method for backward compatibility
  static Map<String, Map<String, double>> getDefaultBenchmarks(String ageGroup) {
    // For backward compatibility, return legacy format (Excellent/Good/Average/Below Average)
    return getDefaultBenchmarksLegacy(ageGroup);
  }

  /// Convert benchmark map to double values (handles both String and double keys)
  static Map<String, double> convertBenchmarksToDouble(Map<String, dynamic> benchmarks) {
    final result = <String, double>{};
    
    for (var entry in benchmarks.entries) {
      final value = entry.value;
      if (value is num) {
        result[entry.key] = value.toDouble();
      }
    }
    
    return result;
  }

  /// Determine benchmark level using updated 4-tier system
  static String determineUpdatedBenchmarkLevel(double time, Map<String, double> benchmarks) {
    final elite = benchmarks['Elite'] ?? double.infinity;
    final advanced = benchmarks['Advanced'] ?? double.infinity;
    final developing = benchmarks['Developing'] ?? double.infinity;
    final beginner = benchmarks['Beginner'] ?? double.infinity;
    
    if (time <= elite) return 'Elite';
    if (time <= advanced) return 'Advanced';
    if (time <= developing) return 'Developing';
    return 'Beginner';
  }

  /// Legacy method for backward compatibility
  static String determineBenchmarkLevel(double time, Map<String, double> benchmarks) {
    // Convert legacy benchmark names to updated ones
    final updatedBenchmarks = <String, double>{};
    for (var entry in benchmarks.entries) {
      final updatedKey = legacyBenchmarkMapping[entry.key] ?? entry.key;
      updatedBenchmarks[updatedKey] = entry.value;
    }
    return determineUpdatedBenchmarkLevel(time, updatedBenchmarks);
  }

  /// Calculate percentile using updated 4-tier system
  static double calculateUpdatedPercentile(double time, Map<String, double> benchmarks) {
    final elite = benchmarks['Elite'] ?? 0;
    final advanced = benchmarks['Advanced'] ?? 0;
    final developing = benchmarks['Developing'] ?? 0;
    final beginner = benchmarks['Beginner'] ?? 0;
    
    if (time <= elite) return 95.0;
    if (time <= advanced) return 75.0;
    if (time <= developing) return 50.0;
    if (time <= beginner) return 25.0;
    return 10.0;
  }

  /// Legacy method for backward compatibility
  static double calculatePercentile(double time, Map<String, double> benchmarks) {
    final updatedBenchmarks = <String, double>{};
    for (var entry in benchmarks.entries) {
      final updatedKey = legacyBenchmarkMapping[entry.key] ?? entry.key;
      updatedBenchmarks[updatedKey] = entry.value;
    }
    return calculateUpdatedPercentile(time, updatedBenchmarks);
  }

  /// Get color for benchmark level using updated system
  static Color getUpdatedBenchmarkColor(String benchmarkLevel) {
    switch (benchmarkLevel.toLowerCase()) {
      case 'elite':
        return Colors.green;
      case 'advanced':
        return Colors.lightGreen;
      case 'developing':
        return Colors.orange;
      case 'beginner':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Legacy method for backward compatibility
  static Color getBenchmarkColor(String benchmarkLevel) {
    // Map legacy levels to updated colors
    final mappedLevel = legacyBenchmarkMapping[benchmarkLevel] ?? benchmarkLevel;
    return getUpdatedBenchmarkColor(mappedLevel);
  }

  /// Get color for score using updated thresholds
  static Color getUpdatedScoreColor(double score) {
    if (score >= 8.0) return Colors.green;        // Elite (was 8.5)
    if (score >= 6.0) return Colors.lightGreen;   // Advanced (was 7.0)
    if (score >= 4.0) return Colors.orange;       // Developing (was 5.5)
    return Colors.red;                            // Beginner
  }

  /// Legacy method for backward compatibility
  static Color getScoreColor(double score) {
    return getUpdatedScoreColor(score);
  }

  /// Get color for percentile using updated thresholds
  static Color getUpdatedPercentileColor(double percentile) {
    if (percentile >= 90) return Colors.green;      // Elite
    if (percentile >= 70) return Colors.lightGreen; // Advanced (was 75)
    if (percentile >= 40) return Colors.orange;     // Developing (was 50)
    return Colors.red;                              // Beginner
  }

  /// Legacy method for backward compatibility
  static Color getPercentileColor(double percentile) {
    return getUpdatedPercentileColor(percentile);
  }

  /// Get benchmark level from score using updated thresholds
  static String getUpdatedBenchmarkLevelFromScore(double score) {
    if (score >= 8.0) return 'Elite';
    if (score >= 6.0) return 'Advanced';
    if (score >= 4.0) return 'Developing';
    return 'Beginner';
  }

  /// Calculate improvement potential (unchanged)
  static double calculateImprovement(double avgTime, double bestTime) {
    if (avgTime <= 0 || bestTime <= 0 || bestTime >= avgTime) return 0.0;
    return ((avgTime - bestTime) / avgTime) * 100;
  }

  /// Calculate trend based on score and percentile (simplified)
  static String calculateTrend(double score, double percentile) {
    if (score >= 7.0 || percentile >= 80) return 'improving';
    if (score >= 4.0 || percentile >= 40) return 'stable';
    return 'needs_focus';
  }

  /// Get trend label for display
  static String getTrendLabel(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return 'Improving';
      case 'stable':
        return 'Stable';
      case 'needs_focus':
        return 'Needs Focus';
      default:
        return 'Unknown';
    }
  }

  /// Get trend color
  static Color getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'improving':
        return Colors.green;
      case 'stable':
        return Colors.blue;
      case 'needs_focus':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get category icon
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'forward speed':
      case 'speed':
        return Icons.speed;
      case 'backward speed':
        return Icons.keyboard_return;
      case 'agility':
        return Icons.shuffle;
      case 'transitions':
        return Icons.swap_horiz;
      case 'crossovers':
        return Icons.compare_arrows;
      case 'technique':
        return Icons.precision_manufacturing;
      case 'power':
        return Icons.bolt;
      case 'endurance':
        return Icons.timer;
      default:
        return Icons.sports_hockey;
    }
  }

  /// Format category name for display
  static String formatCategoryName(String category) {
    return category.split('_').map((word) => 
      word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  /// Format test name for display
  static String formatTestName(String testName) {
    return testName.replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ')
        .replaceAll('Test', '');
  }

  /// Format age group for display
  static String formatAgeGroup(String ageGroup) {
    switch (ageGroup) {
      case 'youth_8_10':
        return 'Youth (8-10)';
      case 'youth_11_14':
        return 'Youth (11-14)';
      case 'youth_15_18':
        return 'Youth (15-18)';
      case 'adult':
        return 'Adult (18+)';
      default:
        return ageGroup.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// Format position for display
  static String formatPosition(String position) {
    switch (position.toLowerCase()) {
      case 'forward':
        return 'Forward';
      case 'defenseman':
      case 'defense':
        return 'Defenseman';
      case 'goalie':
      case 'goalkeeper':
        return 'Goalie';
      default:
        return position[0].toUpperCase() + position.substring(1);
    }
  }

  /// Format skill level for display
  static String formatSkillLevel(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'recreational':
        return 'Recreational';
      case 'competitive':
        return 'Competitive';
      case 'elite':
        return 'Elite';
      default:
        return skillLevel[0].toUpperCase() + skillLevel.substring(1);
    }
  }

  /// Format age category for display
  static String formatAgeCategory(String ageCategory) {
    switch (ageCategory.toLowerCase()) {
      case 'youth':
        return 'Youth';
      case 'adolescent':
        return 'Adolescent';
      case 'adult':
        return 'Adult';
      default:
        return ageCategory[0].toUpperCase() + ageCategory.substring(1);
    }
  }

  /// Get age group from birth date
  static String getAgeGroupFromBirthDate(DateTime birthDate) {
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays ~/ 365;
    
    if (age <= 10) return 'youth_8_10';
    if (age <= 14) return 'youth_11_14';
    if (age <= 18) return 'youth_15_18';
    return 'adult';
  }

  /// Check if age group supports gender-specific benchmarks
  static bool supportsGenderSpecificBenchmarks(String ageGroup) {
    return ageGroup == 'youth_15_18' || ageGroup == 'adult';
  }

  /// Get expected seasonal improvement percentage
  static double getExpectedSeasonalImprovement(String ageGroup, String skillLevel) {
    const baseImprovement = {
      'youth_8_10': 8.0,    // High developmental potential
      'youth_11_14': 6.0,   // Growth spurt variability
      'youth_15_18': 4.0,   // Approaching mature performance
      'adult': 2.0,         // Maintenance/small gains
    };
    
    const skillMultiplier = {
      'recreational': 0.7,   // Slower improvement
      'competitive': 1.0,    // Normal improvement
      'elite': 1.3,          // Accelerated improvement
    };
    
    final base = baseImprovement[ageGroup] ?? 3.0;
    final multiplier = skillMultiplier[skillLevel] ?? 1.0;
    
    return base * multiplier;
  }

  /// Get biological age considerations for age group
  static Map<String, dynamic> getBiologicalAgeConsiderations(String ageGroup) {
    switch (ageGroup) {
      case 'youth_8_10':
        return {
          'variability': 'Moderate (15-20%)',
          'considerations': [
            'Early vs late maturation patterns emerging',
            'Focus on fun and fundamental movement',
            'High variability in coordination and strength'
          ],
          'assessment_frequency': 'Every 6 months',
        };
      case 'youth_11_14':
        return {
          'variability': 'Very High (25-35%)',
          'considerations': [
            'Peak Height Velocity (PHV) creates massive performance differences',
            'Early maturers may dominate temporarily',
            'Late maturers need patience and appropriate expectations',
            'Consider biological age assessment tools'
          ],
          'assessment_frequency': 'Every 3-4 months',
        };
      case 'youth_15_18':
        return {
          'variability': 'Moderate (10-20%)',
          'considerations': [
            'Late maturers beginning to catch up',
            'Gender differences become pronounced',
            'Approaching adult performance levels'
          ],
          'assessment_frequency': 'Every 4-6 months',
        };
      case 'adult':
        return {
          'variability': 'Low (5-10%)',
          'considerations': [
            'Mature performance patterns established',
            'Focus on maintenance and injury prevention',
            'Skill level more important than age'
          ],
          'assessment_frequency': 'Every 6-12 months',
        };
      default:
        return {
          'variability': 'Unknown',
          'considerations': ['Standard assessment protocols'],
          'assessment_frequency': 'Every 6 months',
        };
    }
  }

  /// Validate assessment data against expected ranges
  static Map<String, dynamic> validateAssessmentData(
    String testName, 
    double time, 
    String ageGroup, 
    String? skillLevel,
    String? gender
  ) {
    final benchmarks = getUpdatedBenchmarks(ageGroup, skillLevel, gender);
    final testBenchmarks = benchmarks[testName];
    
    if (testBenchmarks == null) {
      return {
        'isValid': false,
        'error': 'Unknown test type: $testName',
        'suggestions': [],
      };
    }
    
    final beginner = testBenchmarks['Beginner']!;
    final elite = testBenchmarks['Elite']!;
    
    // Check for unrealistic times (too fast or too slow)
    if (time < elite * 0.8) {
      return {
        'isValid': false,
        'error': 'Time appears unrealistically fast',
        'suggestions': [
          'Check timing method (electronic vs manual)',
          'Verify test distance and protocol',
          'Consider measurement error'
        ],
      };
    }
    
    if (time > beginner * 1.5) {
      return {
        'isValid': false,
        'error': 'Time appears unrealistically slow',
        'suggestions': [
          'Check for timing errors',
          'Consider if player completed test properly',
          'Verify equipment and ice conditions'
        ],
      };
    }
    
    return {
      'isValid': true,
      'error': null,
      'suggestions': [],
      'level': determineUpdatedBenchmarkLevel(time, testBenchmarks),
      'percentile': calculateUpdatedPercentile(time, testBenchmarks),
    };
  }

  // ======================
  // LEGACY COMPATIBILITY METHODS
  // ======================

  /// Get age-specific default benchmarks (legacy format with Excellent/Good/Average/Below Average)
  static Map<String, Map<String, double>> getDefaultBenchmarksLegacy(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'youth_8_10':
        return {
          'forward_speed_test': {'Excellent': 3.5, 'Good': 4.0, 'Average': 4.5, 'Below Average': 5.0},
          'backward_speed_test': {'Excellent': 4.2, 'Good': 4.8, 'Average': 5.4, 'Below Average': 6.0},
          'agility_test': {'Excellent': 12.5, 'Good': 14.0, 'Average': 15.5, 'Below Average': 17.0},
          'transitions_test': {'Excellent': 4.5, 'Good': 5.0, 'Average': 5.5, 'Below Average': 6.0},
          'crossovers_test': {'Excellent': 8.5, 'Good': 9.5, 'Average': 10.5, 'Below Average': 12.0},
          'stop_start_test': {'Excellent': 2.8, 'Good': 3.1, 'Average': 3.4, 'Below Average': 3.8}
        };
      case 'youth_11_14':
        return {
          'forward_speed_test': {'Excellent': 3.0, 'Good': 3.5, 'Average': 4.0, 'Below Average': 4.5},
          'backward_speed_test': {'Excellent': 3.8, 'Good': 4.3, 'Average': 4.8, 'Below Average': 5.4},
          'agility_test': {'Excellent': 8.5, 'Good': 9.5, 'Average': 11.0, 'Below Average': 12.5},
          'transitions_test': {'Excellent': 3.8, 'Good': 4.3, 'Average': 4.8, 'Below Average': 5.4},
          'crossovers_test': {'Excellent': 7.0, 'Good': 8.0, 'Average': 9.0, 'Below Average': 10.5},
          'stop_start_test': {'Excellent': 2.4, 'Good': 2.7, 'Average': 3.0, 'Below Average': 3.4}
        };
      case 'youth_15_18':
        return {
          'forward_speed_test': {'Excellent': 2.6, 'Good': 3.0, 'Average': 3.4, 'Below Average': 3.8},
          'backward_speed_test': {'Excellent': 3.2, 'Good': 3.6, 'Average': 4.0, 'Below Average': 4.5},
          'agility_test': {'Excellent': 6.8, 'Good': 7.5, 'Average': 8.2, 'Below Average': 9.0},
          'transitions_test': {'Excellent': 3.2, 'Good': 3.6, 'Average': 4.0, 'Below Average': 4.5},
          'crossovers_test': {'Excellent': 5.5, 'Good': 6.2, 'Average': 7.0, 'Below Average': 8.0},
          'stop_start_test': {'Excellent': 2.1, 'Good': 2.4, 'Average': 2.7, 'Below Average': 3.1}
        };
      case 'adult':
      default:
        return {
          'forward_speed_test': {'Excellent': 2.4, 'Good': 2.8, 'Average': 3.2, 'Below Average': 3.6},
          'backward_speed_test': {'Excellent': 2.8, 'Good': 3.2, 'Average': 3.6, 'Below Average': 4.1},
          'agility_test': {'Excellent': 5.8, 'Good': 6.5, 'Average': 7.2, 'Below Average': 8.0},
          'transitions_test': {'Excellent': 2.8, 'Good': 3.2, 'Average': 3.6, 'Below Average': 4.1},
          'crossovers_test': {'Excellent': 5.0, 'Good': 5.5, 'Average': 6.0, 'Below Average': 7.0},
          'stop_start_test': {'Excellent': 1.8, 'Good': 2.1, 'Average': 2.4, 'Below Average': 2.8}
        };
    }
  }

  /// Determine benchmark level from dynamic benchmarks (handles Map<String, dynamic>)
  static String determineBenchmarkLevelDynamic(double playerTime, Map<String, dynamic> benchmarks) {
    final excellent = benchmarks['Excellent'] is num
        ? (benchmarks['Excellent'] as num).toDouble()
        : double.parse(benchmarks['Excellent']?.toString() ?? '0');

    final good = benchmarks['Good'] is num
        ? (benchmarks['Good'] as num).toDouble()
        : double.parse(benchmarks['Good']?.toString() ?? '0');

    final average = benchmarks['Average'] is num
        ? (benchmarks['Average'] as num).toDouble()
        : double.parse(benchmarks['Average']?.toString() ?? '0');

    final belowAverage = benchmarks['Below Average'] is num
        ? (benchmarks['Below Average'] as num).toDouble()
        : double.parse(benchmarks['Below Average']?.toString() ?? '0');

    if (playerTime <= excellent) return 'Excellent';
    if (playerTime <= good) return 'Good';
    if (playerTime <= average) return 'Average';
    if (playerTime <= belowAverage) return 'Below Average';
    return 'Poor';
  }

  /// Get performance level from score (0-10 scale)
  static String getPerformanceLevelFromScore(double score) {
    if (score >= 8.0) return 'Elite';
    if (score >= 6.5) return 'Advanced';
    if (score >= 5.0) return 'Intermediate';
    if (score >= 3.5) return 'Developing';
    return 'Beginner';
  }

  /// Get benchmarks for a specific test
  static Map<String, double> getBenchmarksForTest(String testName, String ageGroup) {
    final allBenchmarks = getDefaultBenchmarksLegacy(ageGroup);
    return allBenchmarks[testName] ?? {};
  }
}