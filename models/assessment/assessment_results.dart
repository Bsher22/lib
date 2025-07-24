class AssessmentResults {
  final double overallScore;
  final double overallRate;
  final Map<String, double> categoryScores;
  final Map<String, double> zoneRates;
  final Map<String, double> typeRates;
  final String performanceLevel;
  final List<String> strengths;
  final List<String> improvements;
  final String? previousAssessmentId;
  final Map<String, double>? previousCategoryScores;
  final Map<String, Map<String, dynamic>>? zoneMetrics;
  final List<Map<String, dynamic>>? assessmentHistory;
  final int? totalShots;

  AssessmentResults({
    required this.overallScore,
    required this.overallRate,
    required this.categoryScores,
    required this.zoneRates,
    required this.typeRates,
    required this.performanceLevel,
    required this.strengths,
    required this.improvements,
    this.previousAssessmentId,
    this.previousCategoryScores,
    this.zoneMetrics,
    this.assessmentHistory,
    this.totalShots,
  });

  factory AssessmentResults.fromJson(Map<String, dynamic> json) {
    return AssessmentResults(
      overallScore: (json['overall_score'] as num).toDouble(),
      overallRate: (json['overall_rate'] as num).toDouble(),
      categoryScores: Map<String, double>.from(json['category_scores']),
      zoneRates: Map<String, double>.from(json['zone_rates']),
      typeRates: Map<String, double>.from(json['type_rates']),
      performanceLevel: json['performance_level'],
      strengths: List<String>.from(json['strengths']),
      improvements: List<String>.from(json['improvements']),
      previousAssessmentId: json['previous_assessment_id'],
      previousCategoryScores: json['previous_category_scores'] != null
          ? Map<String, double>.from(json['previous_category_scores'])
          : null,
      zoneMetrics: json['zone_metrics'] != null
          ? Map<String, Map<String, dynamic>>.from(json['zone_metrics'])
          : null,
      assessmentHistory: json['assessment_history'] != null
          ? List<Map<String, dynamic>>.from(json['assessment_history'])
          : null,
      totalShots: json['total_shots'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'overall_score': overallScore,
      'overall_rate': overallRate,
      'category_scores': categoryScores,
      'zone_rates': zoneRates,
      'type_rates': typeRates,
      'performance_level': performanceLevel,
      'strengths': strengths,
      'improvements': improvements,
      'previous_assessment_id': previousAssessmentId,
      'previous_category_scores': previousCategoryScores,
      'zone_metrics': zoneMetrics,
      'assessment_history': assessmentHistory,
      'total_shots': totalShots,
    };
  }
}