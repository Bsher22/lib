// utils/assessment_skating_utils.dart
import 'package:flutter/material.dart';
import '../models/skating.dart';
import 'skating_utils.dart'; // Import centralized utilities

class AssessmentSkatingUtils {
  // Calculate assessment results - returns a Map instead of SkatingAssessmentResults
  static Map<String, dynamic> calculateResults(
    Skating assessment,
    Map<String, double> testResults,
  ) {
    // Category scores
    Map<String, double> categoryScores = {
      'Forward Speed': 0.0,
      'Backward Speed': 0.0,
      'Agility': 0.0,
      'Transitions': 0.0,
    };

    // Individual test scores
    Map<String, double> testScores = {};

    // Benchmark ratings - FIXED: renamed to avoid collision
    Map<String, String> benchmarkRatings = {};

    // Process all test results
    for (var entry in testResults.entries) {
      final testId = entry.key;
      final time = entry.value;

      // Determine category from test name
      String category = _getCategoryFromTestName(testId);
      
      // Use default benchmarks for age group
      final ageGroup = assessment.ageGroup ?? 'adult';
      final allBenchmarks = SkatingUtils.getDefaultBenchmarks(ageGroup);
      final testBenchmarksData = allBenchmarks[testId] ?? {}; // FIXED: renamed local variable
      
      if (testBenchmarksData.isEmpty) continue;

      // Convert to dynamic map for calculation
      final nonNullableBenchmarks = <String, dynamic>{
        'Excellent': testBenchmarksData['Excellent'],
        'Good': testBenchmarksData['Good'],
        'Average': testBenchmarksData['Average'],
        'Below Average': testBenchmarksData['Below Average'],
      };
      
      // Calculate score for this test (0-10 scale)
      double testScore = _calculateTestScore(nonNullableBenchmarks, time);
      testScores[testId] = testScore;

      // Determine benchmark rating using centralized utility - FIXED: use correct map
      benchmarkRatings[testId] = SkatingUtils.determineBenchmarkLevelDynamic(time, nonNullableBenchmarks);

      // Add to category score
      if (categoryScores.containsKey(category)) {
        categoryScores[category] = categoryScores[category]! + testScore;
      }
    }

    // Calculate average scores per category
    Map<String, int> categoryCounts = {};
    for (var testId in testResults.keys) {
      String category = _getCategoryFromTestName(testId);
      
      // Count tests per category
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }

    // Calculate category averages
    for (var category in categoryScores.keys) {
      if (categoryCounts.containsKey(category) && categoryCounts[category]! > 0) {
        categoryScores[category] = categoryScores[category]! / categoryCounts[category]!;
      } else {
        categoryScores[category] = 0.0;
      }
    }

    // Calculate overall score (weighted by position)
    double overallScore = 0.0;
    double weightedCount = 0.0;

    if (assessment.position == 'forward') {
      // Forward weighting: Forward Speed > Agility > Transitions > Backward Speed
      if (categoryCounts.containsKey('Forward Speed')) {
        overallScore += categoryScores['Forward Speed']! * 2;
        weightedCount += 2.0;
      }
      if (categoryCounts.containsKey('Agility')) {
        overallScore += categoryScores['Agility']! * 1.5;
        weightedCount += 1.5;
      }
      if (categoryCounts.containsKey('Transitions')) {
        overallScore += categoryScores['Transitions']!;
        weightedCount += 1.0;
      }
      if (categoryCounts.containsKey('Backward Speed')) {
        overallScore += categoryScores['Backward Speed']! * 0.5;
        weightedCount += 0.5;
      }
    } else {
      // Defenseman weighting: Backward Speed > Transitions > Agility > Forward Speed
      if (categoryCounts.containsKey('Backward Speed')) {
        overallScore += categoryScores['Backward Speed']! * 2;
        weightedCount += 2.0;
      }
      if (categoryCounts.containsKey('Transitions')) {
        overallScore += categoryScores['Transitions']! * 1.5;
        weightedCount += 1.5;
      }
      if (categoryCounts.containsKey('Agility')) {
        overallScore += categoryScores['Agility']!;
        weightedCount += 1.0;
      }
      if (categoryCounts.containsKey('Forward Speed')) {
        overallScore += categoryScores['Forward Speed']! * 0.5;
        weightedCount += 0.5;
      }
    }

    // Calculate weighted average
    overallScore = weightedCount > 0 ? overallScore / weightedCount : 0.0;

    // Add overall score to category scores
    categoryScores['Overall'] = overallScore;

    // Determine performance level using centralized utility
    String performanceLevel = SkatingUtils.getPerformanceLevelFromScore(overallScore);

    // Generate strengths and improvements
    List<String> strengths = [];
    List<String> improvements = [];

    // Analyze category performance
    for (var category in categoryScores.keys) {
      if (category == 'Overall') continue;

      if (categoryScores[category]! >= 7.0) {
        if (assessment.position == 'forward' && category == 'Forward Speed') {
          strengths.add('Excellent forward speed provides competitive advantage for breakaways and zone entries');
        } else if (assessment.position == 'defenseman' && category == 'Backward Speed') {
          strengths.add('Strong backward speed enables effective gap control and defensive positioning');
        } else if (category == 'Agility') {
          strengths.add('Excellent agility allows quick direction changes and effective maneuvering in traffic');
        } else if (category == 'Transitions') {
          strengths.add('Smooth transitions between forward and backward skating create versatility in all zones');
        } else {
          strengths.add('Strong performance in $category');
        }
      } else if (categoryScores[category]! <= 4.0 && categoryScores[category]! > 0) {
        if (assessment.position == 'forward' && category == 'Forward Speed') {
          improvements.add('Forward Speed development needed to create separation and scoring opportunities');
        } else if (assessment.position == 'defenseman' && category == 'Backward Speed') {
          improvements.add('Backward Speed improvement would enhance defensive positioning and gap control');
        } else if (category == 'Agility') {
          improvements.add('Agility development through edge work would increase effectiveness in tight spaces');
        } else if (category == 'Transitions') {
          improvements.add('Smoother transitions would improve adaptability to changing game situations');
        } else {
          improvements.add('$category needs significant improvement');
        }
      }
    }

    // Add position-specific insights
    if (assessment.position == 'forward') {
      if (!strengths.any((s) => s.contains('Forward Speed')) && !improvements.any((i) => i.contains('Forward Speed'))) {
        improvements.add('Forward acceleration development would benefit offensive capabilities');
      }
    } else {
      if (!strengths.any((s) => s.contains('Backward Speed')) && !improvements.any((i) => i.contains('Backward Speed'))) {
        improvements.add('Backward skating speed would improve defensive zone coverage');
      }
    }

    // Ensure we have at least one strength
    if (strengths.isEmpty) {
      if (overallScore >= 5.0) {
        strengths.add('Balanced skating profile provides foundation for further development');
      } else {
        strengths.add('Determination and effort in completing assessment');
      }
    }

    // Ensure we have at least one improvement area
    if (improvements.isEmpty) {
      improvements.add('Edge work refinement would enhance overall skating efficiency');
    }

    // Return a Map instead of SkatingAssessmentResults
    return {
      'categoryScores': categoryScores,
      'performanceLevel': performanceLevel,
      'strengths': strengths,
      'improvements': improvements,
      'testBenchmarks': benchmarkRatings, // FIXED: use correct variable name
    };
  }

  // Calculate individual test score (0-10 scale)
  static double _calculateTestScore(Map<String, dynamic> benchmarks, double time) {
    // Extract benchmark times
    final excellentTime = benchmarks['Excellent'] is num
        ? (benchmarks['Excellent'] as num).toDouble()
        : double.parse(benchmarks['Excellent']?.toString() ?? '0');

    final goodTime = benchmarks['Good'] is num
        ? (benchmarks['Good'] as num).toDouble()
        : double.parse(benchmarks['Good']?.toString() ?? '0');

    final averageTime = benchmarks['Average'] is num
        ? (benchmarks['Average'] as num).toDouble()
        : double.parse(benchmarks['Average']?.toString() ?? '0');

    final belowAverageTime = benchmarks['Below Average'] is num
        ? (benchmarks['Below Average'] as num).toDouble()
        : double.parse(benchmarks['Below Average']?.toString() ?? '0');

    // Set score ranges
    // Excellent: 8.0-10.0
    // Good: 6.0-8.0
    // Average: 4.0-6.0
    // Below Average: 2.0-4.0
    // Poor: 0.0-2.0

    if (time <= excellentTime) {
      // Excellent or better
      double ratio = (excellentTime - time) / (excellentTime * 0.3);
      ratio = ratio.clamp(0.0, 1.0);
      return 8.0 + ratio * 2.0;
    } else if (time <= goodTime) {
      // Between excellent and good
      double ratio = (goodTime - time) / (goodTime - excellentTime);
      ratio = ratio.clamp(0.0, 1.0);
      return 6.0 + ratio * 2.0;
    } else if (time <= averageTime) {
      // Between good and average
      double ratio = (averageTime - time) / (averageTime - goodTime);
      ratio = ratio.clamp(0.0, 1.0);
      return 4.0 + ratio * 2.0;
    } else if (time <= belowAverageTime) {
      // Between average and below average
      double ratio = (belowAverageTime - time) / (belowAverageTime - averageTime);
      ratio = ratio.clamp(0.0, 1.0);
      return 2.0 + ratio * 2.0;
    } else {
      // Below average or worse
      double ratio = belowAverageTime / time;
      ratio = ratio.clamp(0.0, 1.0);
      return ratio * 2.0;
    }
  }

  // Helper to convert existing test results to the new format
  static Map<String, double> convertExistingTestResults(
    Map<String, dynamic> existingResults,
  ) {
    final result = <String, double>{};

    existingResults.forEach((testId, testResult) {
      if (testResult is! Map) return;

      if (testResult.containsKey('time')) {
        result[testId] = testResult['time'] is num ? (testResult['time'] as num).toDouble() : 0.0;
      }
    });

    return result;
  }

  // Return a Map instead of SkatingAssessmentResults
  static Map<String, dynamic> createResultsFromScores(
    Map<String, dynamic> scores, 
    {String? playerName}
  ) {
    // Create category scores from the provided scores
    Map<String, double> categoryScores = {};
    for (var entry in scores.entries) {
      if (entry.value is num) {
        categoryScores[entry.key] = (entry.value as num).toDouble();
      }
    }
    
    // Determine performance level using centralized utility
    String performanceLevel = SkatingUtils.getPerformanceLevelFromScore(
      categoryScores['Overall'] ?? 0.0
    );
    
    // Generate some basic strengths and improvements
    List<String> strengths = [];
    List<String> improvements = [];
    
    for (var entry in categoryScores.entries) {
      if (entry.key == 'Overall') continue;
      
      if (entry.value >= 7.0) {
        strengths.add('${entry.key} (${entry.value.toStringAsFixed(1)})');
      } else if (entry.value < 5.0) {
        improvements.add('${entry.key} (${entry.value.toStringAsFixed(1)})');
      }
    }
    
    // Ensure we have at least one strength and improvement
    if (strengths.isEmpty) {
      strengths.add('General skating ability');
    }
    
    if (improvements.isEmpty) {
      improvements.add('Overall skating consistency');
    }
    
    return {
      'categoryScores': categoryScores,
      'performanceLevel': performanceLevel,
      'strengths': strengths,
      'improvements': improvements,
      'playerName': playerName,
    };
  }

  // Helper function to determine category from test name
  static String _getCategoryFromTestName(String testName) {
    switch (testName.toLowerCase()) {
      case 'forward_speed_test':
        return 'Forward Speed';
      case 'backward_speed_test':
        return 'Backward Speed';
      case 'agility_test':
        return 'Agility';
      case 'transitions_test':
        return 'Transitions';
      case 'crossovers_test':
        return 'Agility'; // Crossovers are part of agility
      case 'stop_start_test':
        return 'Forward Speed'; // Stop/start is part of forward speed
      default:
        return 'Forward Speed'; // Default fallback
    }
  }
}