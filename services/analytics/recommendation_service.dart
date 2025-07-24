// lib/services/recommendations/recommendation_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for recommendations, insights, and coaching suggestions
/// 
/// This service provides:
/// - Assessment-based recommendations and coaching insights
/// - Performance improvement suggestions
/// - Training program recommendations
/// - Miss pattern analysis and correction strategies
/// - Personalized coaching tips and development plans
/// - Progress-based recommendation updates
class RecommendationService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  RecommendationService({
    required super.baseUrl,
    required AuthService authService,
    super.onTokenExpired,
  }) : _authService = authService;
  
  // ==========================================
  // BASE API SERVICE IMPLEMENTATION
  // ==========================================
  
  @override
  Future<Map<String, String>> getAuthHeaders() async {
    return await _authService.getAuthHeaders();
  }
  
  @override
  bool isAuthenticated() {
    return _authService.isAuthenticated();
  }
  
  @override
  void handleAuthenticationError(BuildContext? context) {
    _authService.handleAuthenticationError(context);
  }
  
  // ==========================================
  // GENERAL RECOMMENDATIONS
  // ==========================================
  
  /// Get comprehensive recommendations for a player
  /// 
  /// Returns personalized recommendations based on recent performance,
  /// assessment results, and training history.
  Future<Map<String, dynamic>> getRecommendations(
    int playerId, {
    String? assessmentId,
    String? focusArea,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      if (focusArea != null) queryParams['focus_area'] = focusArea;
      
      if (kDebugMode) {
        print('💡 RecommendationService: Fetching recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultRecommendations();
      }
      
      if (kDebugMode) {
        print('✅ RecommendationService: Recommendations retrieved successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error fetching recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch general recommendations for a player
  Future<Map<String, dynamic>> fetchRecommendations(
    int playerId, {
    BuildContext? context,
  }) async {
    return getRecommendations(playerId, context: context);
  }
  
  // ==========================================
  // SHOT ASSESSMENT RECOMMENDATIONS
  // ==========================================
  
  /// Get recommendations based on shot assessment results
  /// 
  /// Analyzes shot assessment data to provide specific improvement suggestions.
  Future<Map<String, dynamic>> getShotAssessmentRecommendations(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment recommendations');
    }
    
    try {
      if (kDebugMode) {
        print('🎯 RecommendationService: Fetching shot assessment recommendations for $assessmentId');
      }
      
      final response = await get(
        '/api/recommendations/shot-assessment/$assessmentId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultShotRecommendations();
      }
      
      if (kDebugMode) {
        print('✅ RecommendationService: Shot assessment recommendations retrieved');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error fetching shot assessment recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Complete assessment with recommendations
  /// 
  /// Marks assessment as complete and generates final recommendations.
  Future<Map<String, dynamic>> completeAssessmentWithRecommendations(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to complete assessment');
    }
    
    try {
      if (kDebugMode) {
        print('✅ RecommendationService: Completing assessment $assessmentId with recommendations');
      }
      
      final response = await put(
        '/api/recommendations/shot-assessment/$assessmentId/complete',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to complete assessment with recommendations');
      }
      
      if (kDebugMode) {
        print('✅ RecommendationService: Assessment completed with recommendations');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error completing assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Regenerate shot assessment recommendations
  /// 
  /// Updates recommendations based on latest assessment data.
  Future<Map<String, dynamic>> regenerateShotRecommendations(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to regenerate recommendations');
    }
    
    try {
      if (kDebugMode) {
        print('🔄 RecommendationService: Regenerating recommendations for assessment $assessmentId');
      }
      
      final response = await post(
        '/api/recommendations/shot-assessment/$assessmentId/regenerate',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to regenerate recommendations');
      }
      
      if (kDebugMode) {
        print('✅ RecommendationService: Recommendations regenerated successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error regenerating recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SKATING RECOMMENDATIONS
  // ==========================================
  
  /// Get skating-specific recommendations
  /// 
  /// Provides recommendations based on skating assessment results.
  Future<Map<String, dynamic>> getSkatingRecommendations(
    int playerId, {
    String? sessionId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get skating recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (sessionId != null) queryParams['session_id'] = sessionId;
      
      if (kDebugMode) {
        print('⛸️ RecommendationService: Fetching skating recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/skating/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultSkatingRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error fetching skating recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // ASSESSMENT ANALYSIS & INSIGHTS
  // ==========================================
  
  /// Get detailed assessment analysis with insights
  /// 
  /// Provides comprehensive analysis and actionable insights.
  Future<Map<String, dynamic>> getAssessmentAnalysis(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment analysis');
    }
    
    try {
      if (kDebugMode) {
        print('📊 RecommendationService: Fetching assessment analysis for $assessmentId');
      }
      
      final response = await get(
        '/api/analytics/assessment-analysis/$assessmentId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultAssessmentAnalysis();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error fetching assessment analysis: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get miss pattern analysis and recommendations
  /// 
  /// Analyzes miss patterns and provides specific correction strategies.
  Future<Map<String, dynamic>> getMissPatternRecommendations(
    int playerId, {
    String? assessmentId,
    int? dateRange,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get miss pattern recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      if (dateRange != null) queryParams['date_range'] = dateRange.toString();
      
      if (kDebugMode) {
        print('🎯 RecommendationService: Analyzing miss patterns for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/miss-patterns/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultMissPatternRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting miss pattern recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get power analysis recommendations
  /// 
  /// Provides recommendations for improving shot power and effectiveness.
  Future<Map<String, dynamic>> getPowerRecommendations(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get power recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      if (kDebugMode) {
        print('💪 RecommendationService: Fetching power recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/power/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultPowerRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting power recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get consistency improvement recommendations
  /// 
  /// Provides strategies for improving shot consistency and reliability.
  Future<Map<String, dynamic>> getConsistencyRecommendations(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get consistency recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      if (kDebugMode) {
        print('🎯 RecommendationService: Fetching consistency recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/consistency/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultConsistencyRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting consistency recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TRAINING & DEVELOPMENT RECOMMENDATIONS
  // ==========================================
  
  /// Get training program recommendations
  /// 
  /// Suggests appropriate training programs based on player assessment.
  Future<Map<String, dynamic>> getTrainingRecommendations(
    int playerId, {
    String? focusArea,
    String? skillLevel,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get training recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (focusArea != null) queryParams['focus_area'] = focusArea;
      if (skillLevel != null) queryParams['skill_level'] = skillLevel;
      
      if (kDebugMode) {
        print('🏋️ RecommendationService: Fetching training recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/training/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultTrainingRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting training recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get development plan recommendations
  /// 
  /// Provides long-term development suggestions and milestones.
  Future<Map<String, dynamic>> getDevelopmentRecommendations(
    int playerId, {
    String? timeframe,
    List<String>? priorities,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get development recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeframe != null) queryParams['timeframe'] = timeframe;
      if (priorities != null && priorities.isNotEmpty) {
        queryParams['priorities'] = priorities.join(',');
      }
      
      if (kDebugMode) {
        print('📈 RecommendationService: Fetching development recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/development/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultDevelopmentRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting development recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // PROGRESS-BASED RECOMMENDATIONS
  // ==========================================
  
  /// Get recommendations based on progress comparison
  /// 
  /// Compares current and past performance to suggest next steps.
  Future<Map<String, dynamic>> getProgressBasedRecommendations(
    int playerId,
    String baselineAssessmentId, {
    String? comparisonAssessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get progress recommendations');
    }
    
    try {
      final queryParams = <String, String>{
        'baseline_id': baselineAssessmentId,
      };
      if (comparisonAssessmentId != null) {
        queryParams['comparison_id'] = comparisonAssessmentId;
      }
      
      if (kDebugMode) {
        print('📊 RecommendationService: Fetching progress-based recommendations for player $playerId');
      }
      
      final response = await get(
        '/api/recommendations/progress/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultProgressRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting progress recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM RECOMMENDATIONS
  // ==========================================
  
  /// Get team-level recommendations
  /// 
  /// Provides recommendations for team improvement and development.
  Future<Map<String, dynamic>> getTeamRecommendations(
    int teamId, {
    String? focusArea,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get team recommendations');
    }
    
    try {
      final queryParams = <String, String>{};
      if (focusArea != null) queryParams['focus_area'] = focusArea;
      
      if (kDebugMode) {
        print('👥 RecommendationService: Fetching team recommendations for team $teamId');
      }
      
      final response = await get(
        '/api/recommendations/team/$teamId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultTeamRecommendations();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ RecommendationService: Error getting team recommendations: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // DEFAULT RECOMMENDATION PROVIDERS
  // ==========================================
  
  /// Default general recommendations
  Map<String, dynamic> _getDefaultRecommendations() {
    return {
      'recommendations': [
        {
          'type': 'accuracy',
          'title': 'Focus on Shot Accuracy',
          'description': 'Continue practicing accurate shooting to improve goal scoring',
          'priority': 'high',
          'timeframe': 'short_term',
        },
      ],
      'focus_areas': ['accuracy', 'consistency'],
      'training_suggestions': [
        'Practice shooting from different zones',
        'Work on shot placement drills',
      ],
      'next_assessment': {
        'recommended_date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
        'type': 'follow_up',
      },
    };
  }
  
  /// Default shot assessment recommendations
  Map<String, dynamic> _getDefaultShotRecommendations() {
    return {
      'accuracy_recommendations': [
        'Focus on target practice in zones 1, 3, 7, and 9',
        'Practice shot placement consistency',
      ],
      'power_recommendations': [
        'Work on weight transfer during shot',
        'Practice follow-through technique',
      ],
      'consistency_recommendations': [
        'Focus on repeatable shooting mechanics',
        'Practice same shot type from various positions',
      ],
      'priority_areas': ['accuracy'],
      'training_focus': 'Technical fundamentals',
    };
  }
  
  /// Default skating recommendations
  Map<String, dynamic> _getDefaultSkatingRecommendations() {
    return {
      'agility_recommendations': [
        'Practice cone weaving drills',
        'Work on quick direction changes',
      ],
      'speed_recommendations': [
        'Focus on acceleration techniques',
        'Practice longer stride development',
      ],
      'balance_recommendations': [
        'Single-leg balance exercises',
        'Edge work fundamentals',
      ],
      'priority_areas': ['balance', 'agility'],
      'training_focus': 'Fundamental skating skills',
    };
  }
  
  /// Default assessment analysis
  Map<String, dynamic> _getDefaultAssessmentAnalysis() {
    return {
      'strengths': ['Shot variety', 'Consistency in practiced zones'],
      'weaknesses': ['Accuracy in challenging zones', 'Shot power'],
      'improvement_areas': [
        'Zone 8 and 9 accuracy',
        'Shot power development',
      ],
      'overall_score': 6.5,
      'recommendations': _getDefaultRecommendations(),
    };
  }
  
  /// Default miss pattern recommendations
  Map<String, dynamic> _getDefaultMissPatternRecommendations() {
    return {
      'common_miss_patterns': ['High and wide', 'Low and left'],
      'correction_strategies': [
        'Focus on follow-through direction',
        'Practice shooting with visual targets',
      ],
      'drills': [
        'Target practice with immediate feedback',
        'Video analysis of shooting mechanics',
      ],
    };
  }
  
  /// Default power recommendations
  Map<String, dynamic> _getDefaultPowerRecommendations() {
    return {
      'power_improvement': [
        'Strengthen core and legs',
        'Practice weight transfer',
      ],
      'technique_focus': [
        'Loading and release timing',
        'Stick flex utilization',
      ],
      'exercises': [
        'Squats and lunges',
        'Medicine ball throws',
      ],
    };
  }
  
  /// Default consistency recommendations
  Map<String, dynamic> _getDefaultConsistencyRecommendations() {
    return {
      'consistency_focus': [
        'Develop repeatable mechanics',
        'Practice under pressure',
      ],
      'mental_game': [
        'Visualization exercises',
        'Routine development',
      ],
      'practice_structure': [
        'Block practice for technique',
        'Random practice for transfer',
      ],
    };
  }
  
  /// Default training recommendations
  Map<String, dynamic> _getDefaultTrainingRecommendations() {
    return {
      'recommended_programs': [
        {
          'name': 'Shooting Accuracy Fundamentals',
          'duration': '4 weeks',
          'focus': 'Technical accuracy',
        },
      ],
      'weekly_structure': {
        'technique_sessions': 2,
        'power_sessions': 1,
        'game_situation_sessions': 1,
      },
      'progression_milestones': [
        'Achieve 70% accuracy in preferred zones',
        'Develop consistent shot mechanics',
      ],
    };
  }
  
  /// Default development recommendations
  Map<String, dynamic> _getDefaultDevelopmentRecommendations() {
    return {
      'short_term_goals': [
        'Improve shot accuracy by 10%',
        'Develop consistent shooting mechanics',
      ],
      'long_term_goals': [
        'Become a reliable goal scorer',
        'Master all shot types',
      ],
      'development_phases': [
        {
          'phase': 'Foundation',
          'duration': '8 weeks',
          'focus': 'Basic shooting mechanics',
        },
      ],
    };
  }
  
  /// Default progress recommendations
  Map<String, dynamic> _getDefaultProgressRecommendations() {
    return {
      'progress_summary': 'Steady improvement observed',
      'areas_of_improvement': ['Accuracy', 'Consistency'],
      'areas_needing_focus': ['Power', 'Zone variety'],
      'next_steps': [
        'Continue current training approach',
        'Add power development exercises',
      ],
      'reassessment_timeline': '2 weeks',
    };
  }
  
  /// Default team recommendations
  Map<String, dynamic> _getDefaultTeamRecommendations() {
    return {
      'team_strengths': ['Consistent effort', 'Good fundamentals'],
      'team_needs': ['Power development', 'Advanced techniques'],
      'training_focus': [
        'Individual skill development',
        'Team shooting drills',
      ],
      'program_suggestions': [
        'Implement position-specific training',
        'Regular assessment schedule',
      ],
    };
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  /// Get recommendation permissions for current user
  Map<String, bool> getRecommendationPermissions() {
    return {
      'canViewRecommendations': _authService.isAuthenticated(),
      'canGenerateRecommendations': _authService.canManageTeams(),
      'canModifyRecommendations': _authService.canManageCoaches(),
      'canCreateDevelopmentPlans': _authService.canManageTeams(),
      'canViewTeamRecommendations': _authService.canManageTeams(),
    };
  }
  
  /// Validate recommendation request parameters
  Map<String, dynamic> validateRecommendationRequest({
    String? focusArea,
    String? timeframe,
    String? skillLevel,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Focus area validation
    if (focusArea != null) {
      const validFocusAreas = [
        'accuracy', 'power', 'consistency', 'variety',
        'agility', 'speed', 'balance', 'technique'
      ];
      if (!validFocusAreas.contains(focusArea.toLowerCase())) {
        warnings.add('Focus area "$focusArea" may not be standard');
      }
    }
    
    // Timeframe validation
    if (timeframe != null) {
      const validTimeframes = [
        'short_term', 'medium_term', 'long_term',
        'immediate', 'seasonal', 'yearly'
      ];
      if (!validTimeframes.contains(timeframe.toLowerCase())) {
        warnings.add('Timeframe "$timeframe" may not be standard');
      }
    }
    
    // Skill level validation
    if (skillLevel != null) {
      const validSkillLevels = [
        'beginner', 'intermediate', 'advanced', 'elite'
      ];
      if (!validSkillLevels.contains(skillLevel.toLowerCase())) {
        warnings.add('Skill level "$skillLevel" may not be standard');
      }
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
}