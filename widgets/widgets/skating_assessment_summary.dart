// lib/models/skating_assessment_summary.dart

import 'skating_assessments.dart';
import 'hockey_position_assessment.dart';

class SkatingAssessmentSummary {
  final SkatingAssessment assessment;
  final SkatingAssessment? previousAssessment;
  final Map<String, double> improvements;
  final List<String> recommendedDrills;

  SkatingAssessmentSummary({
    required this.assessment,
    this.previousAssessment,
    required this.improvements,
    required this.recommendedDrills,
  });

  factory SkatingAssessmentSummary.calculate({
    required SkatingAssessment assessment,
    SkatingAssessment? previousAssessment,
  }) {
    final improvements = <String, double>{};
    if (previousAssessment != null) {
      for (final category in AssessmentCategory.values) {
        final categoryName = SkatingAssessmentHelper.getCategoryDisplayName(category);
        final currentScore = assessment.scores[categoryName] ?? 0.0;
        final previousScore = previousAssessment.scores[categoryName] ?? 0.0;
        improvements[categoryName] = currentScore - previousScore;
      }
      improvements['Overall'] = assessment.overallScore - previousAssessment.overallScore;
    }
    final recommendedDrills = _generateRecommendedDrills(assessment);
    return SkatingAssessmentSummary(
      assessment: assessment,
      previousAssessment: previousAssessment,
      improvements: improvements,
      recommendedDrills: recommendedDrills,
    );
  }

  static List<String> _generateRecommendedDrills(SkatingAssessment assessment) {
    final weaknesses = assessment.weaknesses;
    final drills = <String>[];
    final isForward = assessment.position == 'forward';
    for (final weakness in weaknesses) {
      switch (weakness) {
        case 'Forward Speed':
          drills.add(isForward ? 'Acceleration Sprints' : 'Defensive Rush Drills');
          drills.add('Forward Stride Power Training');
          break;
        case 'Backward Speed':
          drills.add(isForward ? 'Backcheck Sprints' : 'Gap Control Drills');
          drills.add('Backward C-Cuts Speed Series');
          break;
        case 'Agility':
          drills.add('Figure-Eight Tight Turns');
          drills.add(isForward ? 'Puck Control Obstacle Course' : 'Defensive Pivot Series');
          break;
        case 'Transitions':
          drills.add('Forward-to-Backward Transition Drill');
          drills.add(isForward ? 'Zone Entry Transitions' : 'Blue Line Transitions');
          break;
      }
    }
    if (drills.isEmpty) {
      drills.add('Complete Skater Development Series');
      drills.add(isForward ? 'Offensive Zone Mobility' : 'Defensive Zone Coverage');
    }
    return drills.take(5).toList();
  }

  String getProgressDescription() {
    if (previousAssessment == null) {
      return 'First assessment completed. Establish this as baseline performance.';
    }
    final overallChange = improvements['Overall'] ?? 0.0;
    if (overallChange >= 1.5) {
      return 'Excellent improvement since last assessment. Training plan is highly effective.';
    } else if (overallChange >= 0.5) {
      return 'Good progress since last assessment. Continue current training with focus on weaknesses.';
    } else if (overallChange >= -0.5) {
      return 'Maintaining current level. Consider adjusting training to target specific weaknesses.';
    } else {
      return 'Performance has dropped since last assessment. Evaluate training and recovery factors.';
    }
  }

  String? getMostImprovedCategory() {
    if (previousAssessment == null) {
      return null;
    }
    String? bestCategory;
    double maxImprovement = 0.0;
    for (final entry in improvements.entries) {
      if (entry.key != 'Overall' && entry.value > maxImprovement) {
        maxImprovement = entry.value;
        bestCategory = entry.key;
      }
    }
    return maxImprovement > 0.0 ? bestCategory : null;
  }

  String? getMostNeededImprovement() {
    String? worstCategory;
    double minScore = 10.0;
    for (final category in AssessmentCategory.values) {
      final categoryName = SkatingAssessmentHelper.getCategoryDisplayName(category);
      final score = assessment.scores[categoryName] ?? 0.0;
      if (score < minScore && score > 0.0) {
        minScore = score;
        worstCategory = categoryName;
      }
    }
    return worstCategory;
  }

  String getPositionInsights() {
    final isForward = assessment.position == 'forward';
    if (isForward) {
      final forwardSpeed = assessment.scores['Forward Speed'] ?? 0.0;
      final agility = assessment.scores['Agility'] ?? 0.0;
      if (forwardSpeed >= 7.0 && agility >= 7.0) {
        return 'Excellent forward skating profile. Speed and agility support offensive rushes and breakaways.';
      } else if (forwardSpeed >= 6.0) {
        return 'Good forward speed with room for agility improvement. Focus on quick turns in offensive zone.';
      } else {
        return 'Work on acceleration and top speed to create more offensive opportunities and breakaways.';
      }
    } else {
      final backwardSpeed = assessment.scores['Backward Speed'] ?? 0.0;
      final transitions = assessment.scores['Transitions'] ?? 0.0;
      if (backwardSpeed >= 7.0 && transitions >= 7.0) {
        return 'Strong defensive skating profile. Good backward mobility and gap control capability.';
      } else if (backwardSpeed >= 6.0) {
        return 'Solid backward skating with room for transition improvement. Work on pivots at blue line.';
      } else {
        return 'Improve backward speed and mobility to maintain defensive positioning against fast forwards.';
      }
    }
  }

  String getImprovementTimeframe() {
    final weakestCategory = getMostNeededImprovement();
    if (weakestCategory == null) {
      return 'Maintain current training plan to preserve skills.';
    }
    final score = assessment.scores[weakestCategory] ?? 0.0;
    if (score <= 3.0) {
      return 'Intensive focus needed. Expect 8-12 weeks for significant improvement in $weakestCategory.';
    } else if (score <= 5.0) {
      return 'Regular practice needed. Expect 4-8 weeks for noticeable improvement in $weakestCategory.';
    } else {
      return 'Refinement phase. Expect 2-4 weeks for fine-tuning $weakestCategory technique.';
    }
  }

  bool isPositionSuitable() {
    final isForward = assessment.position == 'forward';
    if (isForward) {
      final forwardSpeed = assessment.scores['Forward Speed'] ?? 0.0;
      final agility = assessment.scores['Agility'] ?? 0.0;
      return forwardSpeed >= 5.0 && agility >= 5.0;
    } else {
      final backwardSpeed = assessment.scores['Backward Speed'] ?? 0.0;
      final transitions = assessment.scores['Transitions'] ?? 0.0;
      return backwardSpeed >= 5.0 && transitions >= 5.0;
    }
  }

  String? getAlternativePositionRecommendation() {
    if (isPositionSuitable()) {
      return null;
    }
    final isForward = assessment.position == 'forward';
    final forwardSpeed = assessment.scores['Forward Speed'] ?? 0.0;
    final backwardSpeed = assessment.scores['Backward Speed'] ?? 0.0;
    final agility = assessment.scores['Agility'] ?? 0.0;
    final transitions = assessment.scores['Transitions'] ?? 0.0;
    if (isForward) {
      if (backwardSpeed >= 5.0 && transitions >= 5.0) {
        return 'Consider defensive position based on stronger backward skating skills.';
      } else {
        return 'Work on fundamental skating skills before position specialization.';
      }
    } else {
      if (forwardSpeed >= 5.0 && agility >= 5.0) {
        return 'Consider forward position based on stronger forward skating skills.';
      } else {
        return 'Work on fundamental skating skills before position specialization.';
      }
    }
  }

  DateTime getSuggestedNextAssessmentDate() {
    int daysToNextAssessment = 90;
    if (assessment.ageGroup == 'youth_12_14') {
      daysToNextAssessment = 60;
    } else if (assessment.ageGroup == 'adult') {
      daysToNextAssessment = 120;
    }
    final overallScore = assessment.overallScore;
    if (overallScore < 4.0) {
      daysToNextAssessment = (daysToNextAssessment * 0.75).round();
    } else if (overallScore > 7.0) {
      daysToNextAssessment = (daysToNextAssessment * 1.25).round();
    }
    return assessment.date.add(Duration(days: daysToNextAssessment));
  }

  Map<String, dynamic> toJson() {
    return {
      'assessment': assessment.toJson(),
      'previous_assessment': previousAssessment?.toJson(),
      'improvements': improvements,
      'recommended_drills': recommendedDrills,
    };
  }
}