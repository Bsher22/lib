// lib/services/assessment/shot_assessment_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for shot assessments, analysis, and miss pattern detection
/// 
/// This service provides:
/// - Shot assessment creation with multiple shots
/// - Assessment completion and result analysis
/// - Miss pattern detection and analysis
/// - Assessment-based recommendations
/// - Assessment comparison and progress tracking
class ShotAssessmentService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  ShotAssessmentService({
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
  // ✅ FIX: CASTING HELPER METHODS
  // ==========================================
  
  /// Safe casting helper for shot assessment lists from API responses
  static List<ShotAssessment> _castAssessmentList(dynamic assessmentList) {
    if (assessmentList is List) {
      return assessmentList.map((json) => ShotAssessment.fromJson(json as Map<String, dynamic>)).toList();
    } else if (assessmentList is Map && assessmentList.containsKey('assessments')) {
      final list = assessmentList['assessments'];
      if (list is List) {
        return list.map((json) => ShotAssessment.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
    if (kDebugMode) {
      print('⚠️ ShotAssessmentService: Unexpected assessmentList type: ${assessmentList.runtimeType}');
    }
    return <ShotAssessment>[];
  }
  
  // ==========================================
  // ASSESSMENT CREATION & MANAGEMENT
  // ==========================================
  
  /// Create a shot assessment with multiple shots
  /// 
  /// This is the primary method for creating comprehensive shot assessments
  /// that include both the assessment metadata and all associated shots.
  Future<Map<String, dynamic>> createShotAssessmentWithShots({
    required Map<String, dynamic> assessmentData,
    required List<Map<String, dynamic>> shots,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to create shot assessments');
    }
    
    try {
      // Sanitize and validate assessment data
      final sanitizedAssessment = _sanitizeAssessmentData(assessmentData);
      final sanitizedShots = _sanitizeShotsData(shots, sanitizedAssessment['id']);
      
      // Validate assessment data
      final validation = validateAssessmentData(sanitizedAssessment);
      if (!validation['isValid']) {
        throw ValidationException('Invalid assessment data: ${validation['errors'].join(', ')}');
      }
      
      if (kDebugMode) {
        print('🎯 ShotAssessmentService: Creating assessment ${sanitizedAssessment['id']} with ${sanitizedShots.length} shots');
        print('   Assessment Type: ${sanitizedAssessment['assessment_type']}');
        print('   Player ID: ${sanitizedAssessment['player_id']}');
      }
      
      final response = await post(
        '/api/shots/batch',
        data: {
          'assessment': sanitizedAssessment,
          'shots': sanitizedShots,
          'create_assessment': true,
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to create shot assessment: empty response');
      }
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Assessment created successfully: ${result['assessment']?['id']}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error creating assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }

  /// ✅ FIX: Add missing createShotAssessment method for backward compatibility
  Future<Map<String, dynamic>> createShotAssessment(Map<String, dynamic> assessmentData) async {
    try {
      // This delegates to the existing createShotAssessmentWithShots method
      // Extract shots if they exist in the data
      final shots = assessmentData['shots'] as List<Map<String, dynamic>>? ?? [];
      
      // Remove shots from assessment data to avoid duplication
      final cleanAssessmentData = Map<String, dynamic>.from(assessmentData);
      cleanAssessmentData.remove('shots');
      
      return await createShotAssessmentWithShots(
        assessmentData: cleanAssessmentData,
        shots: shots,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error in createShotAssessment: $e');
      }
      rethrow;
    }
  }

  /// ✅ FIX: Add missing completeShotAssessment method
  Future<Map<String, dynamic>> completeShotAssessment(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to complete assessments');
    }
    
    try {
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Completing assessment $assessmentId');
      }
      
      final response = await put(
        '/api/shots/assessments/$assessmentId/complete',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to complete assessment: empty response');
      }
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Assessment $assessmentId completed successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error completing assessment $assessmentId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Save a shot assessment (alternative method for simpler data structure)
  /// 
  /// This method accepts a simpler data structure with embedded shots.
  Future<Map<String, dynamic>> saveShotAssessment(
    Map<String, dynamic> assessmentData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to save shot assessments');
    }
    
    try {
      final shots = assessmentData['shots'] as List<dynamic>? ?? [];
      if (shots.isEmpty) {
        throw ValidationException('No shots provided in assessment');
      }
      
      // Extract assessment metadata
      final assessment = {
        'player_id': assessmentData['player_id'],
        'assessment_type': assessmentData['assessment_type'] ?? 'standard',
        'title': assessmentData['title'] ?? 'Shot Assessment',
        'description': assessmentData['description'],
        'assessment_config': assessmentData['assessment_config'] ?? {},
      };
      
      // Convert shots data
      final convertedShots = shots.map((shot) => {
        ...shot as Map<String, dynamic>,
        'player_id': assessmentData['player_id'],
        'source': 'assessment',
        'date': shot['timestamp'] ?? DateTime.now().toIso8601String(),
      }).toList();
      
      if (kDebugMode) {
        print('🎯 ShotAssessmentService: Saving assessment with ${shots.length} shots');
      }
      
      return await createShotAssessmentWithShots(
        assessmentData: assessment,
        shots: convertedShots,
        context: context,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error saving shot assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // ASSESSMENT RETRIEVAL
  // ==========================================
  
  /// Get a specific shot assessment by ID
  /// 
  /// Returns complete assessment data including shots and analysis.
  Future<ShotAssessment> getShotAssessment(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch assessments');
    }
    
    try {
      if (kDebugMode) {
        print('🎯 ShotAssessmentService: Fetching assessment $assessmentId');
      }
      
      final response = await get(
        '/api/shots/assessments/$assessmentId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Assessment not found', 404);
      }
      
      final assessment = ShotAssessment.fromJson(result);
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Assessment retrieved: ${assessment.title}');
      }
      
      return assessment;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error fetching assessment $assessmentId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get all shot assessments for a player
  /// 
  /// Returns assessments with optional status filtering.
  Future<List<ShotAssessment>> getPlayerShotAssessments(
    int playerId, {
    String? status,
    String? assessmentType,
    int? limit,
    int offset = 0,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player assessments');
    }
    
    try {
      final queryParams = <String, String>{
        'offset': offset.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      if (limit != null) queryParams['limit'] = limit.toString();
      
      if (kDebugMode) {
        print('🎯 ShotAssessmentService: Fetching assessments for player $playerId');
      }
      
      final response = await get(
        '/api/shots/assessments/player/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ ShotAssessmentService: No assessments found for player $playerId');
        }
        return [];
      }
      
      // ✅ FIX: Use safe casting helper
      final assessments = _castAssessmentList(result);
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Retrieved ${assessments.length} assessments for player $playerId');
      }
      
      return assessments;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error fetching player assessments: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // ASSESSMENT ANALYSIS & RESULTS
  // ==========================================
  
  /// Get shot assessment results and analysis
  /// 
  /// Returns comprehensive analysis including accuracy, patterns, and recommendations.
  Future<Map<String, dynamic>> getShotAssessmentResults(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment results');
    }
    
    try {
      if (kDebugMode) {
        print('📊 ShotAssessmentService: Fetching results for assessment $assessmentId');
      }
      
      final response = await get(
        '/api/shots/assessments/$assessmentId/results',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Assessment results not found', 404);
      }
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Assessment results retrieved');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error fetching assessment results: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get enhanced baseline assessment results
  /// 
  /// Returns baseline results with additional shot-level data for detailed analysis.
  Future<Map<String, dynamic>> getEnhancedBaselineResults(
    String baselineAssessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get enhanced baseline results');
    }
    
    try {
      // Get basic assessment results
      final basicResults = await getShotAssessmentResults(
        baselineAssessmentId,
        context: context,
      );
      
      // Get detailed shot-level data
      final shotLevelData = await getShotsByAssessment(
        baselineAssessmentId,
        includeGroupIndex: true,
        context: context,
      );
      
      // Combine results
      final enhancedResults = Map<String, dynamic>.from(basicResults);
      enhancedResults['shotLevelData'] = shotLevelData;
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Enhanced baseline results retrieved');
      }
      
      return enhancedResults;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting enhanced baseline results: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get shots by assessment with detailed metadata
  Future<List<Map<String, dynamic>>> getShotsByAssessment(
    String assessmentId, {
    bool includeGroupIndex = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment shots');
    }
    
    try {
      final response = await get(
        '/api/analytics/shots/assessment/$assessmentId',
        queryParameters: {
          'include_group_index': includeGroupIndex.toString(),
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return [];
      }
      
      return (result['shots'] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting shots by assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // MISS PATTERN ANALYSIS
  // ==========================================
  
  /// Get miss pattern analysis for an assessment
  /// 
  /// Analyzes miss patterns and provides insights on shooting tendencies.
  Future<Map<String, dynamic>> getMissPatterns(
    int playerId, {
    String? assessmentId,
    int? dateRange,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get miss patterns');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      if (dateRange != null) queryParams['date_range'] = dateRange.toString();
      
      if (kDebugMode) {
        print('🎯 ShotAssessmentService: Analyzing miss patterns for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/miss-patterns/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'patterns': [],
          'summary': {
            'most_common_miss': 'None',
            'miss_percentage': 0.0,
            'improvement_areas': [],
          }
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting miss patterns: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get power analysis for assessment
  /// 
  /// Analyzes shot power distribution and effectiveness.
  Future<Map<String, dynamic>> getPowerAnalysis(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get power analysis');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      final response = await get(
        '/api/analytics/power-analysis/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'average_power': 0.0,
          'power_distribution': {},
          'power_effectiveness': {},
          'recommendations': [],
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting power analysis: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get consistency analysis for assessment
  /// 
  /// Analyzes shot consistency and reliability patterns.
  Future<Map<String, dynamic>> getConsistencyAnalysis(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get consistency analysis');
    }
    
    try {
      final queryParams = <String, String>{};
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      final response = await get(
        '/api/analytics/consistency-analysis/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'consistency_score': 0.0,
          'variance_analysis': {},
          'streak_analysis': {},
          'recommendations': [],
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting consistency analysis: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // ASSESSMENT COMPARISON & PROGRESS
  // ==========================================
  
  /// Compare two assessments
  /// 
  /// Provides detailed comparison between baseline and follow-up assessments.
  Future<Map<String, dynamic>> compareAssessments(
    String baselineAssessmentId,
    String comparisonAssessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to compare assessments');
    }
    
    try {
      if (kDebugMode) {
        print('📊 ShotAssessmentService: Comparing assessments $baselineAssessmentId vs $comparisonAssessmentId');
      }
      
      final response = await get(
        '/api/analytics/assessment-comparison',
        queryParameters: {
          'baseline_id': baselineAssessmentId,
          'comparison_id': comparisonAssessmentId,
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Comparison data not available', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error comparing assessments: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get assessment progress timeline
  /// 
  /// Returns progression data across multiple assessments.
  Future<Map<String, dynamic>> getAssessmentProgress(
    int playerId, {
    String? baselineAssessmentId,
    int? limit,
    String? assessmentType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment progress');
    }
    
    try {
      final queryParams = <String, String>{};
      if (baselineAssessmentId != null) queryParams['baseline_id'] = baselineAssessmentId;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      
      final response = await get(
        '/api/analytics/assessment-progress/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'timeline': [],
          'trend_analysis': {},
          'improvement_areas': [],
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting assessment progress: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // ASSESSMENT VALIDATION & UTILITIES
  // ==========================================
  
  /// Validate assessment data before submission
  Map<String, dynamic> validateAssessmentData(Map<String, dynamic> assessmentData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    if (assessmentData['player_id'] == null) {
      errors.add('Player ID is required');
    }
    
    if (assessmentData['id'] == null || assessmentData['id'].toString().isEmpty) {
      errors.add('Assessment ID is required');
    }
    
    // Assessment type validation
    final assessmentType = assessmentData['assessment_type'] as String?;
    if (assessmentType != null) {
      const validTypes = ['accuracy', 'power', 'quick_release', 'comprehensive', 'baseline', 'follow_up'];
      if (!validTypes.contains(assessmentType)) {
        warnings.add('Assessment type "$assessmentType" may not be standard');
      }
    }
    
    // Title and description validation
    final title = assessmentData['title'] as String?;
    if (title != null && title.length > 200) {
      errors.add('Assessment title must be 200 characters or less');
    }
    
    final description = assessmentData['description'] as String?;
    if (description != null && description.length > 1000) {
      errors.add('Assessment description must be 1000 characters or less');
    }
    
    // Assessment config validation
    final config = assessmentData['assessment_config'];
    if (config != null && config is! Map) {
      errors.add('Assessment config must be a valid configuration object');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Sanitize assessment data for API submission
  Map<String, dynamic> _sanitizeAssessmentData(Map<String, dynamic> assessmentData) {
    final sanitized = Map<String, dynamic>.from(assessmentData);
    
    // Ensure ID is properly set
    sanitized['id'] = sanitized['id'] ?? 
                     sanitized['assessmentId'] ?? 
                     DateTime.now().millisecondsSinceEpoch.toString();
    
    // Clean up legacy field names
    sanitized.remove('assessmentId');
    
    // Ensure player_id is set correctly
    sanitized['player_id'] = sanitized['player_id'] ?? sanitized['playerId'];
    sanitized.remove('playerId');
    
    // Set default values
    sanitized['assessment_type'] ??= 'accuracy';
    sanitized['title'] ??= 'Shot Assessment';
    sanitized['date'] ??= DateTime.now().toIso8601String();
    
    // Handle groups data
    if (sanitized['assessment_config'] != null && 
        sanitized['assessment_config']['groups'] != null) {
      // Groups are in assessment_config, keep as is
    } else if (sanitized['groups'] != null) {
      // Move groups to assessment_config
      sanitized['assessment_config'] = {
        'groups': sanitized['groups']
      };
      sanitized.remove('groups');
    }
    
    return cleanRequestData(sanitized);
  }
  
  /// Sanitize shots data for API submission
  List<Map<String, dynamic>> _sanitizeShotsData(
    List<Map<String, dynamic>> shots,
    String assessmentId,
  ) {
    return shots.map((shot) {
      return {
        'player_id': shot['player_id'],
        'zone': shot['zone'] as String? ?? '0',
        'type': shot['type'] as String? ?? 'Wrist Shot',
        'success': shot['success'] as bool? ?? false,
        'outcome': shot['outcome'] as String? ?? (shot['success'] as bool? ?? false ? 'Goal' : 'Miss'),
        'date': shot['date'] as String? ?? DateTime.now().toIso8601String(),
        'source': shot['source'] as String? ?? 'assessment',
        'assessment_id': assessmentId,
        'power': shot['power'],
        'quick_release': shot['quick_release'],
        'group_index': shot['group_index'],
        'group_id': shot['group_id'],
        'intended_zone': shot['intended_zone'] as String?,
        'intended_direction': shot['intended_direction'] as String?,
      };
    }).toList();
  }
  
  /// Get assessment statistics summary
  Future<Map<String, dynamic>> getAssessmentStatistics(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get assessment statistics');
    }
    
    try {
      final response = await get(
        '/api/shots/assessments/$assessmentId/statistics',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'total_shots': 0,
          'successful_shots': 0,
          'accuracy_percentage': 0.0,
          'zone_breakdown': {},
          'type_breakdown': {},
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error getting assessment statistics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Delete an assessment and all associated shots
  Future<void> deleteAssessment(
    String assessmentId, {
    bool deleteShots = true,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete assessments');
    }
    
    // Check permissions - only coaches and above can delete assessments
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to delete assessments');
    }
    
    try {
      final queryParams = <String, String>{};
      if (deleteShots) queryParams['delete_shots'] = 'true';
      
      if (kDebugMode) {
        print('🗑️ ShotAssessmentService: Deleting assessment $assessmentId');
      }
      
      final response = await delete(
        '/api/shots/assessments/$assessmentId',
        queryParameters: queryParams,
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to delete assessment: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ ShotAssessmentService: Assessment $assessmentId deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotAssessmentService: Error deleting assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
}