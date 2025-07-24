// lib/services/analytics/analytics_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// Service responsible for player analytics, metrics, trends, and performance data
/// 
/// This service provides:
/// - Comprehensive player analytics and performance metrics
/// - Shot and skating analytics with filtering capabilities
/// - Trend analysis and progression tracking
/// - Zone and shot type breakdown analytics
/// - Team performance metrics and comparisons
/// - Assessment analysis and player progression reports
class AnalyticsService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  AnalyticsService({
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
  // GENERAL PLAYER ANALYTICS
  // ==========================================
  
  /// Get comprehensive analytics for a player
  /// 
  /// Returns overall performance metrics across all assessment types.
  Future<Map<String, dynamic>> getPlayerAnalytics(
    int playerId, {
    String? timeRange,
    List<String>? assessmentTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player analytics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (assessmentTypes != null && assessmentTypes.isNotEmpty) {
        queryParams['assessment_types'] = assessmentTypes.join(',');
      }
      
      if (kDebugMode) {
        print('📊 AnalyticsService: Fetching player analytics for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultPlayerAnalytics();
      }
      
      if (kDebugMode) {
        print('✅ AnalyticsService: Player analytics retrieved successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching player analytics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get player skating analytics overview
  /// 
  /// Returns skating-specific performance metrics and analysis.
  Future<Map<String, dynamic>> getPlayerSkatingAnalytics(
    int playerId, {
    String? timeRange,
    List<String>? testTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating analytics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (testTypes != null && testTypes.isNotEmpty) {
        queryParams['test_types'] = testTypes.join(',');
      }
      
      if (kDebugMode) {
        print('⛸️ AnalyticsService: Fetching skating analytics for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/skating/$playerId/overview',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultSkatingAnalytics();
      }
      
      if (kDebugMode) {
        print('✅ AnalyticsService: Skating analytics retrieved successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching skating analytics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SHOT ANALYTICS & METRICS
  // ==========================================
  
  /// Fetch comprehensive analytics for a player
  Future<Map<String, dynamic>> fetchAnalytics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch analytics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      final response = await get(
        '/api/analytics/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Analytics data not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching analytics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch player performance metrics with filtering
  Future<Map<String, dynamic>> fetchPlayerMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player metrics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      if (kDebugMode) {
        print('📈 AnalyticsService: Fetching player metrics for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId/metrics',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Player metrics not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching player metrics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch zone-based metrics and analysis
  Future<Map<String, Map<String, dynamic>>> fetchZoneMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch zone metrics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      if (kDebugMode) {
        print('🎯 AnalyticsService: Fetching zone metrics for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId/zones',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Zone metrics not found', 404);
      }
      
      // Convert to proper format
      final Map<String, Map<String, dynamic>> zoneMetrics = {};
      result.forEach((zone, stats) {
        zoneMetrics[zone] = Map<String, dynamic>.from(stats);
      });
      
      return zoneMetrics;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching zone metrics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch shot type metrics and analysis
  Future<Map<String, Map<String, dynamic>>> fetchShotTypeMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shot type metrics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      if (kDebugMode) {
        print('🏒 AnalyticsService: Fetching shot type metrics for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId/shot-types',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Shot type metrics not found', 404);
      }
      
      // Convert to proper format
      final Map<String, Map<String, dynamic>> shotTypeMetrics = {};
      result.forEach((type, stats) {
        shotTypeMetrics[type] = Map<String, dynamic>.from(stats);
      });
      
      return shotTypeMetrics;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching shot type metrics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TREND ANALYSIS & PROGRESSION
  // ==========================================
  
  /// Fetch trend data for timeline analysis
  Future<List<Map<String, dynamic>>> fetchTrendData(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    String interval = 'week',
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch trend data');
    }
    
    try {
      // Convert timeRange to days for API
      int? days;
      if (timeRange == '7 days') days = 7;
      else if (timeRange == '30 days') days = 30;
      else if (timeRange == '90 days') days = 90;
      else if (timeRange == '365 days') days = 365;
      
      final queryParams = <String, String>{
        'interval': interval,
      };
      if (days != null) queryParams['days'] = days.toString();
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      if (kDebugMode) {
        print('📈 AnalyticsService: Fetching trend data for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId/trends',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return [];
      }
      
      final List<dynamic> timelineData = result['timeline_data'] ?? [];
      return timelineData.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching trend data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch complete analysis including all metrics
  Future<Map<String, dynamic>> fetchCompleteAnalysis(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch complete analysis');
    }
    
    try {
      // Convert timeRange to days for API
      int? days;
      if (timeRange == '7 days') days = 7;
      else if (timeRange == '30 days') days = 30;
      else if (timeRange == '90 days') days = 90;
      else if (timeRange == '365 days') days = 365;
      
      final queryParams = <String, String>{};
      if (days != null) queryParams['days'] = days.toString();
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      
      if (kDebugMode) {
        print('📊 AnalyticsService: Fetching complete analysis for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/$playerId/complete',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Complete analysis not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching complete analysis: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM ANALYTICS
  // ==========================================
  
  /// Fetch team performance metrics
  Future<Map<String, dynamic>> fetchTeamMetrics(
    int teamId, {
    String metricType = 'all',
    String? timeRange,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch team metrics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (metricType != 'all') queryParams['metric_type'] = metricType;
      if (timeRange != null) queryParams['time_range'] = timeRange;
      
      if (kDebugMode) {
        print('👥 AnalyticsService: Fetching team metrics for team $teamId');
      }
      
      final response = await get(
        ApiConfig.teamMetricsEndpoint(teamId),
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Team metrics not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching team metrics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch training impact analysis
  Future<Map<String, dynamic>> fetchTrainingImpact(
    int playerId, {
    int dateRange = 30,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch training impact');
    }
    
    try {
      if (kDebugMode) {
        print('🏋️ AnalyticsService: Fetching training impact for player $playerId');
      }
      
      final response = await get(
        ApiConfig.trainingImpactEndpoint(playerId),
        queryParameters: {'date_range': dateRange.toString()},
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Training impact data not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching training impact: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // PLAYER ASSESSMENT & PATTERNS
  // ==========================================
  
  /// Fetch comprehensive player assessment
  Future<Map<String, dynamic>> fetchPlayerAssessment(
    int playerId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player assessment');
    }
    
    try {
      if (kDebugMode) {
        print('🎯 AnalyticsService: Fetching player assessment for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/player-assessment/$playerId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result != null) {
        return result;
      }
      
      // Return default assessment if API call fails
      if (kDebugMode) {
        print('ℹ️ AnalyticsService: Using default player assessment data');
      }
      
      return {
        'scores': {
          'accuracy': 6.5,
          'power': 5.8,
          'quickRelease': 7.2,
          'consistency': 6.0,
          'zoneBalance': 5.5,
          'shotVariety': 6.8,
        },
        'strengths': ['quickRelease', 'shotVariety'],
        'weaknesses': ['zoneBalance', 'power'],
        'recommended_workout_group': 'balancedDevelopment',
        'most_common_zone': '5',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching player assessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      // Return default data on error
      return {
        'scores': {
          'accuracy': 6.5,
          'power': 5.8,
          'quickRelease': 7.2,
          'consistency': 6.0,
          'zoneBalance': 5.5,
          'shotVariety': 6.8,
        },
        'strengths': ['quickRelease', 'shotVariety'],
        'weaknesses': ['zoneBalance', 'power'],
        'recommended_workout_group': 'balancedDevelopment',
        'most_common_zone': '5',
      };
    }
  }
  
  /// Fetch shot pattern analysis
  Future<Map<String, dynamic>> fetchShotPatterns(
    int playerId, {
    String? zone,
    String? type,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shot patterns');
    }
    
    try {
      final queryParams = <String, String>{};
      if (zone != null) queryParams['zone'] = zone;
      if (type != null) queryParams['type'] = type;
      
      if (kDebugMode) {
        print('🎯 AnalyticsService: Fetching shot patterns for player $playerId');
      }
      
      final response = await get(
        '/api/analytics/patterns/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Shot patterns not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching shot patterns: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // PERFORMANCE REPORTS & SUMMARIES
  // ==========================================
  
  /// Fetch comprehensive performance report
  Future<Map<String, dynamic>> fetchPerformanceReport(
    int playerId, {
    String? timeRange,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch performance report');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      
      if (kDebugMode) {
        print('📋 AnalyticsService: Fetching performance report for player $playerId');
      }
      
      final response = await get(
        '/api/reports/performance/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Performance report not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AnalyticsService: Error fetching performance report: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // DEFAULT DATA PROVIDERS
  // ==========================================
  
  /// Default player analytics for offline use
  Map<String, dynamic> _getDefaultPlayerAnalytics() {
    return {
      'overall_stats': {
        'total_shots': 0,
        'total_goals': 0,
        'accuracy_percentage': 0.0,
        'total_assessments': 0,
      },
      'recent_performance': {
        'last_7_days': {
          'shots': 0,
          'goals': 0,
          'accuracy': 0.0,
        },
        'last_30_days': {
          'shots': 0,
          'goals': 0,
          'accuracy': 0.0,
        },
      },
      'zone_performance': {},
      'shot_type_performance': {},
      'trends': [],
    };
  }
  
  /// Default skating analytics for offline use
  Map<String, dynamic> _getDefaultSkatingAnalytics() {
    return {
      'overall_stats': {
        'total_sessions': 0,
        'total_tests': 0,
        'average_score': 0.0,
        'improvement_rate': 0.0,
      },
      'test_performance': {},
      'recent_sessions': [],
      'benchmarks': {},
      'recommendations': [],
    };
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  /// Get analytics permissions for current user
  Map<String, bool> getAnalyticsPermissions() {
    return {
      'canViewPlayerAnalytics': _authService.isAuthenticated(),
      'canViewTeamAnalytics': _authService.canManageTeams(),
      'canExportReports': _authService.canManageTeams(),
      'canViewAdvancedMetrics': _authService.canManageCoaches(),
      'canComparePlayers': _authService.canManageTeams(),
    };
  }
  
  /// Validate analytics query parameters
  Map<String, dynamic> validateAnalyticsQuery({
    String? timeRange,
    List<String>? shotTypes,
    List<String>? testTypes,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Time range validation
    if (timeRange != null) {
      const validTimeRanges = ['7 days', '30 days', '90 days', '365 days', 'All time'];
      if (!validTimeRanges.contains(timeRange)) {
        warnings.add('Time range "$timeRange" may not be standard');
      }
    }
    
    // Shot types validation
    if (shotTypes != null) {
      const validShotTypes = [
        'Wrist Shot', 'Slap Shot', 'Snap Shot', 'Backhand',
        'Tip-in', 'Deflection', 'One-timer', 'Penalty Shot'
      ];
      for (final shotType in shotTypes) {
        if (!validShotTypes.contains(shotType)) {
          warnings.add('Shot type "$shotType" may not be standard');
        }
      }
    }
    
    // Test types validation
    if (testTypes != null) {
      const validTestTypes = [
        'agility', 'acceleration', 'top_speed', 'backwards_skating',
        'crossovers', 'transitions', 'balance', 'edge_work'
      ];
      for (final testType in testTypes) {
        if (!validTestTypes.any((valid) => testType.toLowerCase().contains(valid))) {
          warnings.add('Test type "$testType" may not be standard');
        }
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