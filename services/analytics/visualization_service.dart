// lib/services/visualization/visualization_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// Service responsible for chart data, visualization endpoints, and dashboard data
/// 
/// This service provides:
/// - Chart data preparation for various visualization types
/// - Shot pattern and zone visualization data
/// - Skating performance visualization data
/// - Team comparison and overview visualizations
/// - Progress tracking and trend visualization data
/// - Custom visualization data generation
class VisualizationService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  VisualizationService({
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
  // GENERAL VISUALIZATION DATA
  // ==========================================
  
  /// Fetch visualization data for various chart types
  /// 
  /// This is the main method for fetching visualization data with automatic
  /// routing to specialized endpoints based on data type.
  Future<Map<String, dynamic>> fetchVisualizationData(
    String dataType,
    Map<String, dynamic> parameters, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch visualization data');
    }
    
    try {
      // Check if this is a skating-specific visualization
      const skatingTypes = [
        'skating_categories',
        'skating_comparison', 
        'skating_trends',
        'team_skating_overview',
        'skating_benchmarks'
      ];
      
      if (skatingTypes.contains(dataType)) {
        return fetchSkatingVisualizationData(
          dataType,
          playerId: parameters['player_id'] as int?,
          teamId: parameters['team_id'] as int?,
          dateRange: parameters['date_range'] as int? ?? 90,
          ageGroup: parameters['age_group'] as String? ?? 'youth_15_18',
          position: parameters['position'] as String? ?? 'forward',
          testTypes: parameters['test_types'] as List<String>?,
          context: context,
        );
      }
      
      // Handle general visualization data
      final queryParams = <String, String>{};
      parameters.forEach((key, value) {
        if (value != null) queryParams[key] = value.toString();
      });
      
      if (kDebugMode) {
        print('📊 VisualizationService: Fetching $dataType visualization data');
      }
      
      final response = await get(
        ApiConfig.visualizationEndpoint(dataType),
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultVisualizationData(dataType);
      }
      
      if (kDebugMode) {
        print('✅ VisualizationService: $dataType visualization data retrieved');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching $dataType visualization data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SKATING VISUALIZATION DATA
  // ==========================================
  
  /// Fetch skating-specific visualization data
  /// 
  /// Provides specialized visualization data for skating assessments and analytics.
  Future<Map<String, dynamic>> fetchSkatingVisualizationData(
    String chartType, {
    int? playerId,
    int? teamId,
    int dateRange = 90,
    String ageGroup = 'youth_15_18',
    String position = 'forward',
    List<String>? testTypes,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating visualization data');
    }
    
    try {
      final queryParams = <String, String>{
        'date_range': dateRange.toString(),
        'age_group': ageGroup,
        'position': position,
      };
      
      if (playerId != null) queryParams['player_id'] = playerId.toString();
      if (teamId != null) queryParams['team_id'] = teamId.toString();
      if (testTypes != null && testTypes.isNotEmpty) queryParams['test_types'] = testTypes.join(',');
      
      if (kDebugMode) {
        print('⛸️ VisualizationService: Fetching skating $chartType visualization data');
      }
      
      final response = await get(
        '/api/analytics/skating/visualization/$chartType',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultSkatingVisualizationData(chartType);
      }
      
      if (kDebugMode) {
        print('✅ VisualizationService: Skating $chartType visualization data retrieved');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching skating visualization data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SHOT VISUALIZATION DATA
  // ==========================================
  
  /// Fetch shot pattern visualization data
  /// 
  /// Provides data for shot zone heatmaps and pattern visualizations.
  Future<Map<String, dynamic>> fetchShotPatternData(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shot pattern data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      if (kDebugMode) {
        print('🎯 VisualizationService: Fetching shot pattern data for player $playerId');
      }
      
      final response = await get(
        '/api/visualization/shot-patterns/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultShotPatternData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching shot pattern data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch zone accuracy visualization data
  /// 
  /// Provides data for zone-based accuracy charts and comparisons.
  Future<Map<String, dynamic>> fetchZoneAccuracyData(
    int playerId, {
    String? timeRange,
    String? assessmentId,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch zone accuracy data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      if (kDebugMode) {
        print('🎯 VisualizationService: Fetching zone accuracy data for player $playerId');
      }
      
      final response = await get(
        '/api/visualization/zone-accuracy/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultZoneAccuracyData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching zone accuracy data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch shot type distribution data
  /// 
  /// Provides data for shot type breakdown and effectiveness charts.
  Future<Map<String, dynamic>> fetchShotTypeDistributionData(
    int playerId, {
    String? timeRange,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shot type data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      
      if (kDebugMode) {
        print('🏒 VisualizationService: Fetching shot type distribution for player $playerId');
      }
      
      final response = await get(
        '/api/visualization/shot-types/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultShotTypeData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching shot type data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // PROGRESS & TREND VISUALIZATION
  // ==========================================
  
  /// Fetch progress timeline visualization data
  /// 
  /// Provides data for progress tracking charts and trend analysis.
  Future<Map<String, dynamic>> fetchProgressTimelineData(
    int playerId, {
    String? startDate,
    String? endDate,
    String? metricType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch progress timeline data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (metricType != null) queryParams['metric_type'] = metricType;
      
      if (kDebugMode) {
        print('📈 VisualizationService: Fetching progress timeline for player $playerId');
      }
      
      final response = await get(
        '/api/visualization/progress-timeline/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultProgressTimelineData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching progress timeline data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch assessment comparison visualization data
  /// 
  /// Provides data for comparing multiple assessments visually.
  Future<Map<String, dynamic>> fetchAssessmentComparisonData(
    List<String> assessmentIds, {
    String? comparisonType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch assessment comparison data');
    }
    
    try {
      final queryParams = <String, String>{
        'assessment_ids': assessmentIds.join(','),
      };
      if (comparisonType != null) queryParams['comparison_type'] = comparisonType;
      
      if (kDebugMode) {
        print('📊 VisualizationService: Fetching assessment comparison data');
      }
      
      final response = await get(
        '/api/visualization/assessment-comparison',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultAssessmentComparisonData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching assessment comparison data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM VISUALIZATION DATA
  // ==========================================
  
  /// Fetch team overview visualization data
  /// 
  /// Provides data for team dashboard and overview charts.
  Future<Map<String, dynamic>> fetchTeamOverviewData(
    int teamId, {
    String? timeRange,
    String? metricType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch team overview data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (metricType != null) queryParams['metric_type'] = metricType;
      
      if (kDebugMode) {
        print('👥 VisualizationService: Fetching team overview data for team $teamId');
      }
      
      final response = await get(
        '/api/visualization/team-overview/$teamId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultTeamOverviewData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching team overview data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch team player comparison data
  /// 
  /// Provides data for comparing players within a team.
  Future<Map<String, dynamic>> fetchTeamPlayerComparisonData(
    int teamId, {
    String? metricType,
    List<int>? playerIds,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch team player comparison data');
    }
    
    try {
      final queryParams = <String, String>{};
      if (metricType != null) queryParams['metric_type'] = metricType;
      if (playerIds != null && playerIds.isNotEmpty) {
        queryParams['player_ids'] = playerIds.join(',');
      }
      
      if (kDebugMode) {
        print('👥 VisualizationService: Fetching team player comparison for team $teamId');
      }
      
      final response = await get(
        '/api/visualization/team-player-comparison/$teamId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultTeamPlayerComparisonData();
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error fetching team player comparison data: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // CUSTOM VISUALIZATION DATA
  // ==========================================
  
  /// Generate custom visualization data
  /// 
  /// Allows for flexible visualization data generation with custom parameters.
  Future<Map<String, dynamic>> generateCustomVisualizationData(
    String visualizationType,
    Map<String, dynamic> customParameters, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to generate custom visualization data');
    }
    
    try {
      if (kDebugMode) {
        print('🎨 VisualizationService: Generating custom $visualizationType visualization');
      }
      
      final response = await post(
        '/api/visualization/custom',
        data: {
          'type': visualizationType,
          'parameters': customParameters,
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to generate custom visualization data');
      }
      
      if (kDebugMode) {
        print('✅ VisualizationService: Custom visualization data generated');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ VisualizationService: Error generating custom visualization: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // DEFAULT VISUALIZATION DATA PROVIDERS
  // ==========================================
  
  /// Default visualization data for offline use
  Map<String, dynamic> _getDefaultVisualizationData(String dataType) {
    switch (dataType) {
      case 'shot_patterns':
        return _getDefaultShotPatternData();
      case 'zone_accuracy':
        return _getDefaultZoneAccuracyData();
      case 'shot_types':
        return _getDefaultShotTypeData();
      case 'progress_timeline':
        return _getDefaultProgressTimelineData();
      case 'team_overview':
        return _getDefaultTeamOverviewData();
      default:
        return {
          'data': [],
          'labels': [],
          'metadata': {
            'chart_type': dataType,
            'data_points': 0,
            'generated_at': DateTime.now().toIso8601String(),
          },
        };
    }
  }
  
  /// Default shot pattern visualization data
  Map<String, dynamic> _getDefaultShotPatternData() {
    return {
      'zone_data': {
        '1': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '2': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '3': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '4': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '5': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '6': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '7': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '8': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
        '9': {'shots': 0, 'goals': 0, 'accuracy': 0.0},
      },
      'heat_map_data': [],
      'preferred_zones': [],
      'metadata': {
        'total_shots': 0,
        'total_goals': 0,
        'overall_accuracy': 0.0,
      },
    };
  }
  
  /// Default zone accuracy visualization data
  Map<String, dynamic> _getDefaultZoneAccuracyData() {
    return {
      'zone_accuracy': {
        'labels': ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Zone 5', 'Zone 6', 'Zone 7', 'Zone 8', 'Zone 9'],
        'data': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
        'background_colors': List.filled(9, '#e0e0e0'),
      },
      'zone_attempts': {
        'labels': ['Zone 1', 'Zone 2', 'Zone 3', 'Zone 4', 'Zone 5', 'Zone 6', 'Zone 7', 'Zone 8', 'Zone 9'],
        'data': [0, 0, 0, 0, 0, 0, 0, 0, 0],
      },
    };
  }
  
  /// Default shot type visualization data
  Map<String, dynamic> _getDefaultShotTypeData() {
    return {
      'shot_type_distribution': {
        'labels': ['Wrist Shot', 'Slap Shot', 'Snap Shot', 'Backhand'],
        'data': [0, 0, 0, 0],
        'background_colors': ['#FF6384', '#36A2EB', '#FFCE56', '#4BC0C0'],
      },
      'shot_type_accuracy': {
        'labels': ['Wrist Shot', 'Slap Shot', 'Snap Shot', 'Backhand'],
        'data': [0.0, 0.0, 0.0, 0.0],
      },
    };
  }
  
  /// Default progress timeline visualization data
  Map<String, dynamic> _getDefaultProgressTimelineData() {
    return {
      'timeline': {
        'labels': [],
        'datasets': [
          {
            'label': 'Accuracy',
            'data': [],
            'border_color': '#36A2EB',
            'background_color': 'rgba(54, 162, 235, 0.1)',
          },
        ],
      },
      'milestones': [],
      'trends': {
        'direction': 'stable',
        'improvement_rate': 0.0,
      },
    };
  }
  
  /// Default skating visualization data
  Map<String, dynamic> _getDefaultSkatingVisualizationData(String chartType) {
    switch (chartType) {
      case 'skating_categories':
        return {
          'categories': {
            'agility': {'score': 0.0, 'percentile': 0},
            'speed': {'score': 0.0, 'percentile': 0},
            'balance': {'score': 0.0, 'percentile': 0},
          },
          'radar_data': {
            'labels': ['Agility', 'Speed', 'Balance'],
            'data': [0.0, 0.0, 0.0],
          },
        };
      case 'skating_trends':
        return {
          'trend_data': {
            'labels': [],
            'datasets': [
              {
                'label': 'Overall Score',
                'data': [],
                'border_color': '#4BC0C0',
              },
            ],
          },
        };
      default:
        return {
          'data': [],
          'labels': [],
          'chart_type': chartType,
        };
    }
  }
  
  /// Default assessment comparison data
  Map<String, dynamic> _getDefaultAssessmentComparisonData() {
    return {
      'comparison_chart': {
        'labels': ['Accuracy', 'Power', 'Consistency'],
        'datasets': [],
      },
      'improvement_indicators': [],
      'summary': {
        'overall_improvement': 0.0,
        'best_improvement': 'None',
        'needs_focus': 'None',
      },
    };
  }
  
  /// Default team overview data
  Map<String, dynamic> _getDefaultTeamOverviewData() {
    return {
      'team_stats': {
        'total_players': 0,
        'active_players': 0,
        'total_assessments': 0,
        'average_accuracy': 0.0,
      },
      'player_distribution': {
        'labels': ['Forwards', 'Defense', 'Goalies'],
        'data': [0, 0, 0],
      },
      'performance_overview': {
        'labels': ['Excellent', 'Good', 'Average', 'Needs Improvement'],
        'data': [0, 0, 0, 0],
      },
    };
  }
  
  /// Default team player comparison data
  Map<String, dynamic> _getDefaultTeamPlayerComparisonData() {
    return {
      'player_comparison': {
        'labels': [],
        'datasets': [
          {
            'label': 'Accuracy',
            'data': [],
            'background_color': '#36A2EB',
          },
        ],
      },
      'top_performers': [],
      'improvement_opportunities': [],
    };
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  /// Get visualization permissions for current user
  Map<String, bool> getVisualizationPermissions() {
    return {
      'canViewPlayerVisualizations': _authService.isAuthenticated(),
      'canViewTeamVisualizations': _authService.canManageTeams(),
      'canGenerateCustomVisualizations': _authService.canManageCoaches(),
      'canExportVisualizationData': _authService.canManageTeams(),
      'canViewAdvancedAnalytics': _authService.canManageCoaches(),
    };
  }
  
  /// Validate visualization request parameters
  Map<String, dynamic> validateVisualizationRequest({
    String? chartType,
    String? timeRange,
    String? metricType,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Chart type validation
    if (chartType != null) {
      const validChartTypes = [
        'line', 'bar', 'pie', 'radar', 'scatter',
        'heatmap', 'timeline', 'comparison'
      ];
      if (!validChartTypes.contains(chartType.toLowerCase())) {
        warnings.add('Chart type "$chartType" may not be standard');
      }
    }
    
    // Time range validation
    if (timeRange != null) {
      const validTimeRanges = ['7 days', '30 days', '90 days', '365 days', 'All time'];
      if (!validTimeRanges.contains(timeRange)) {
        warnings.add('Time range "$timeRange" may not be standard');
      }
    }
    
    // Metric type validation
    if (metricType != null) {
      const validMetricTypes = [
        'accuracy', 'power', 'consistency', 'speed',
        'agility', 'balance', 'overall'
      ];
      if (!validMetricTypes.contains(metricType.toLowerCase())) {
        warnings.add('Metric type "$metricType" may not be standard');
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