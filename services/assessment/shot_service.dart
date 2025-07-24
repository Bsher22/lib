// lib/services/shot/shot_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for basic shot CRUD operations and data management
/// 
/// This service provides:
/// - Basic shot creation, retrieval, and deletion
/// - Shot data filtering and search capabilities
/// - Workout-shot linking functionality
/// - Shot metadata and validation
/// - Shot data import/export utilities
class ShotService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  ShotService({
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
  // SHOT CREATION & MANAGEMENT
  // ==========================================
  
  /// Add a new shot to the system
  /// 
  /// [shotData] must contain:
  /// - player_id: ID of the player who took the shot
  /// - zone: Shot zone (1-9 or custom zone identifier)
  /// - type: Type of shot (Wrist Shot, Slap Shot, etc.)
  /// - success: Whether the shot was successful (goal/save/miss)
  /// - outcome: Specific outcome (Goal, Save, Miss, Post, etc.)
  /// Optional fields:
  /// - assessment_id: ID of associated assessment
  /// - workout_id: ID of associated workout
  /// - power: Shot power rating
  /// - quick_release: Quick release rating
  /// - intended_zone: Intended target zone
  /// - intended_direction: Intended shot direction
  Future<Map<String, dynamic>> addShot(
    Map<String, dynamic> shotData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to add shots');
    }
    
    try {
      // Validate required fields
      validateRequiredFields(shotData, [
        'player_id',
        'zone',
        'type',
        'success',
        'outcome',
      ]);
      
      // Clean and prepare shot data
      final cleanedData = _prepareShotData(shotData);
      
      // Validate shot data
      final validation = validateShotData(cleanedData);
      if (!validation['isValid']) {
        throw ValidationException('Invalid shot data: ${validation['errors'].join(', ')}');
      }
      
      if (kDebugMode) {
        print('🎯 ShotService: Adding shot for player ${cleanedData['player_id']} in zone ${cleanedData['zone']}');
      }
      
      final response = await post(
        '/api/shots',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to add shot: empty response');
      }
      
      if (kDebugMode) {
        print('✅ ShotService: Shot added successfully: ${result['id']}');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error adding shot: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Delete a shot by ID
  /// 
  /// Only the shot owner or users with appropriate permissions can delete shots.
  Future<void> deleteShot(
    int shotId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete shots');
    }
    
    try {
      if (kDebugMode) {
        print('🗑️ ShotService: Deleting shot $shotId');
      }
      
      final response = await delete(
        '/api/shots/$shotId',
        context: context,
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('✅ ShotService: Shot $shotId deleted successfully');
        }
        return;
      }
      
      final errorData = handleResponse(response);
      throw ApiException('Failed to delete shot: ${errorData?['message'] ?? 'Unknown error'}');
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error deleting shot $shotId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Update shot data
  /// 
  /// Allows modification of shot details like power, quick_release, notes, etc.
  Future<Map<String, dynamic>> updateShot(
    int shotId,
    Map<String, dynamic> updateData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update shots');
    }
    
    try {
      final cleanedData = cleanRequestData(updateData);
      
      if (kDebugMode) {
        print('🎯 ShotService: Updating shot $shotId with data: ${cleanedData.keys}');
      }
      
      final response = await patch(
        '/api/shots/$shotId',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update shot: empty response');
      }
      
      if (kDebugMode) {
        print('✅ ShotService: Shot $shotId updated successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error updating shot $shotId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SHOT RETRIEVAL & FILTERING
  // ==========================================
  
  /// Fetch shots for a specific player with filtering options
  /// 
  /// Returns shots based on various filter criteria including assessment,
  /// workout, time range, shot type, and outcome.
  Future<List<Shot>> fetchShots(
    int playerId, {
    Map<String, dynamic>? queryParameters,
    String? assessmentId,
    int? workoutId,
    String? shotType,
    String? outcome,
    String? zone,
    String? dateFrom,
    String? dateTo,
    int? limit,
    int offset = 0,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shots');
    }
    
    try {
      // Build query parameters
      final params = <String, dynamic>{
        'offset': offset.toString(),
      };
      
      // Add filter parameters
      if (assessmentId != null) params['assessment_id'] = assessmentId;
      if (workoutId != null) params['workout_id'] = workoutId.toString();
      if (shotType != null) params['type'] = shotType;
      if (outcome != null) params['outcome'] = outcome;
      if (zone != null) params['zone'] = zone;
      if (dateFrom != null) params['date_from'] = dateFrom;
      if (dateTo != null) params['date_to'] = dateTo;
      if (limit != null) params['limit'] = limit.toString();
      
      // Merge with custom query parameters
      if (queryParameters != null) {
        params.addAll(queryParameters);
      }
      
      if (kDebugMode) {
        print('🎯 ShotService: Fetching shots for player $playerId with filters: $params');
      }
      
      final response = await get(
        '/api/shots/$playerId',
        queryParameters: params,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ ShotService: No shots found for player $playerId');
        }
        return [];
      }
      
      // Handle grouped assessment data if present
      if (params['group_by_assessments'] == 'true' && params['source'] == 'assessment') {
        if (result['grouped_by_assessments'] == true) {
          final assessmentGroups = result['assessment_groups'] as List;
          final shots = <Shot>[];
          
          for (final group in assessmentGroups) {
            final groupShots = (group['shots'] as List)
                .cast<Map<String, dynamic>>()
                .map((json) => Shot.fromJson(json))
                .toList();
            shots.addAll(groupShots);
          }
          
          if (kDebugMode) {
            print('✅ ShotService: Retrieved ${shots.length} shots from ${assessmentGroups.length} assessment groups');
          }
          
          return shots;
        }
      }
      
      // ✅ FIX: Handle both List and Map responses properly
      List<dynamic> shotListRaw;
      
      // Since result is Map<String, dynamic>, check if it contains a 'shots' key
      if (result.containsKey('shots') && result['shots'] is List) {
        shotListRaw = result['shots'] as List<dynamic>;
      } else {
        // If no 'shots' key, treat the entire result as empty
        shotListRaw = <dynamic>[];
      }
      
      // ✅ FIX: Cast elements to Map<String, dynamic> and map to Shot objects
      final shots = shotListRaw
          .whereType<Map<String, dynamic>>()
          .map((json) => Shot.fromJson(json))
          .toList();
      
      if (kDebugMode) {
        print('✅ ShotService: Retrieved ${shots.length} shots for player $playerId');
      }
      
      return shots;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error fetching shots for player $playerId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch shots by assessment ID
  /// 
  /// Returns all shots associated with a specific assessment.
  Future<List<Map<String, dynamic>>> getShotsByAssessment(
    String assessmentId, {
    bool includeGroupIndex = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch assessment shots');
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
        print('❌ ShotService: Error fetching shots for assessment $assessmentId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get shot by ID
  /// 
  /// Returns detailed information for a specific shot.
  Future<Shot?> getShot(
    int shotId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch shot details');
    }
    
    try {
      final response = await get(
        '/api/shots/detail/$shotId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return null;
      }
      
      return Shot.fromJson(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error fetching shot $shotId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // WORKOUT-SHOT LINKING
  // ==========================================
  
  /// Link shots to a workout
  /// 
  /// Associates multiple shots with a specific workout session.
  Future<void> linkShotsToWorkout(
    List<int> shotIds,
    int workoutId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to link shots to workouts');
    }
    
    try {
      if (kDebugMode) {
        print('🔗 ShotService: Linking ${shotIds.length} shots to workout $workoutId');
      }
      
      final response = await put(
        '/api/shots/update-workout-link',
        data: {
          'shot_ids': shotIds,
          'workout_id': workoutId,
        },
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to link shots to workout: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ ShotService: Successfully linked shots to workout $workoutId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error linking shots to workout: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Unlink shots from workout
  /// 
  /// Removes the workout association from specified shots.
  Future<void> unlinkShotsFromWorkout(
    List<int> shotIds, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to unlink shots from workouts');
    }
    
    try {
      if (kDebugMode) {
        print('🔗 ShotService: Unlinking ${shotIds.length} shots from workout');
      }
      
      final response = await put(
        '/api/shots/remove-workout-link',
        data: {
          'shot_ids': shotIds,
        },
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to unlink shots from workout: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ ShotService: Successfully unlinked shots from workout');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error unlinking shots from workout: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // BATCH OPERATIONS
  // ==========================================
  
  /// Add multiple shots in a single request
  /// 
  /// Efficiently creates multiple shots with transaction safety.
  Future<List<Map<String, dynamic>>> addMultipleShots(
    List<Map<String, dynamic>> shotsData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to add multiple shots');
    }
    
    try {
      // Validate and clean all shot data
      final cleanedShots = <Map<String, dynamic>>[];
      for (int i = 0; i < shotsData.length; i++) {
        final shotData = shotsData[i];
        
        // Validate required fields
        validateRequiredFields(shotData, [
          'player_id',
          'zone',
          'type',
          'success',
          'outcome',
        ]);
        
        final cleanedData = _prepareShotData(shotData);
        final validation = validateShotData(cleanedData);
        if (!validation['isValid']) {
          throw ValidationException('Invalid shot data at index $i: ${validation['errors'].join(', ')}');
        }
        
        cleanedShots.add(cleanedData);
      }
      
      if (kDebugMode) {
        print('🎯 ShotService: Adding ${cleanedShots.length} shots in batch');
      }
      
      final response = await post(
        '/api/shots/batch',
        data: {
          'shots': cleanedShots,
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to add multiple shots: empty response');
      }
      
      final createdShots = result['shots'] as List? ?? [];
      
      if (kDebugMode) {
        print('✅ ShotService: Successfully added ${createdShots.length} shots in batch');
      }
      
      return createdShots.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error adding multiple shots: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Delete multiple shots
  /// 
  /// Efficiently deletes multiple shots with validation.
  Future<void> deleteMultipleShots(
    List<int> shotIds, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete multiple shots');
    }
    
    try {
      if (kDebugMode) {
        print('🗑️ ShotService: Deleting ${shotIds.length} shots in batch');
      }
      
      final response = await delete(
        '/api/shots/batch',
        data: {
          'shot_ids': shotIds,
        },
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to delete multiple shots: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ ShotService: Successfully deleted ${shotIds.length} shots in batch');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error deleting multiple shots: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SHOT VALIDATION & UTILITIES
  // ==========================================
  
  /// Validate shot data before submission
  Map<String, dynamic> validateShotData(Map<String, dynamic> shotData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Player ID validation
    final playerId = shotData['player_id'];
    if (playerId == null || (playerId is! int || playerId <= 0)) {
      errors.add('Valid player ID is required');
    }
    
    // Zone validation
    final zone = shotData['zone'] as String?;
    if (zone == null || zone.trim().isEmpty) {
      errors.add('Shot zone is required');
    } else {
      // Validate zone format (1-9 or custom zones)
      if (!_isValidZone(zone)) {
        warnings.add('Zone "$zone" may not be a standard zone (1-9)');
      }
    }
    
    // Shot type validation
    final type = shotData['type'] as String?;
    if (type == null || type.trim().isEmpty) {
      errors.add('Shot type is required');
    } else {
      const validTypes = [
        'Wrist Shot',
        'Slap Shot',
        'Snap Shot',
        'Backhand',
        'Tip-in',
        'Deflection',
        'One-timer',
        'Penalty Shot',
      ];
      if (!validTypes.contains(type)) {
        warnings.add('Shot type "$type" may not be a standard type');
      }
    }
    
    // Success validation
    final success = shotData['success'];
    if (success == null || success is! bool) {
      errors.add('Success status (true/false) is required');
    }
    
    // Outcome validation
    final outcome = shotData['outcome'] as String?;
    if (outcome == null || outcome.trim().isEmpty) {
      errors.add('Shot outcome is required');
    } else {
      const validOutcomes = [
        'Goal',
        'Save',
        'Miss',
        'Post',
        'Crossbar',
        'Block',
        'Wide',
        'High',
        'Low',
      ];
      if (!validOutcomes.contains(outcome)) {
        warnings.add('Outcome "$outcome" may not be a standard outcome');
      }
    }
    
    // Power validation (if provided)
    final power = shotData['power'];
    if (power != null && (power is! num || power < 1 || power > 10)) {
      errors.add('Power rating must be between 1 and 10');
    }
    
    // Quick release validation (if provided)
    final quickRelease = shotData['quick_release'];
    if (quickRelease != null && (quickRelease is! num || quickRelease < 1 || quickRelease > 10)) {
      errors.add('Quick release rating must be between 1 and 10');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Prepare shot data for API submission
  Map<String, dynamic> _prepareShotData(Map<String, dynamic> shotData) {
    final prepared = cleanRequestData(shotData);
    
    // Set default values
    prepared['date'] ??= DateTime.now().toIso8601String();
    prepared['source'] ??= 'manual';
    
    // Ensure assessment shots have assessment_id
    if (prepared['source'] == 'assessment') {
      if (prepared['assessment_id'] == null || prepared['assessment_id'].toString().isEmpty) {
        throw ValidationException('Assessment shots must have a valid assessment_id');
      }
    }
    
    return prepared;
  }
  
  /// Check if zone is valid
  bool _isValidZone(String zone) {
    // Standard zones are 1-9
    if (RegExp(r'^[1-9]$').hasMatch(zone)) return true;
    
    // Allow custom zone identifiers
    if (zone.length <= 10 && zone.trim().isNotEmpty) return true;
    
    return false;
  }
  
  /// Get shot statistics for a player
  Future<Map<String, dynamic>> getShotStatistics(
    int playerId, {
    String? timeRange,
    String? shotType,
    String? zone,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get shot statistics');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (shotType != null) queryParams['shot_type'] = shotType;
      if (zone != null) queryParams['zone'] = zone;
      
      final response = await get(
        '/api/shots/$playerId/statistics',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'total_shots': 0,
          'goals': 0,
          'accuracy': 0.0,
          'zone_breakdown': {},
          'type_breakdown': {},
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error fetching shot statistics: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get available shot types and zones for dropdowns
  Future<Map<String, List<String>>> getShotMetadata({
    BuildContext? context,
  }) async {
    try {
      final response = await get(
        '/api/shots/metadata',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return _getDefaultShotMetadata();
      }
      
      return {
        'shot_types': (result['shot_types'] as List).cast<String>(),
        'zones': (result['zones'] as List).cast<String>(),
        'outcomes': (result['outcomes'] as List).cast<String>(),
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ ShotService: Error fetching shot metadata: $e');
      }
      
      // Return default metadata if API call fails
      return _getDefaultShotMetadata();
    }
  }
  
  /// Default shot metadata for offline use
  Map<String, List<String>> _getDefaultShotMetadata() {
    return {
      'shot_types': [
        'Wrist Shot',
        'Slap Shot',
        'Snap Shot',
        'Backhand',
        'Tip-in',
        'Deflection',
        'One-timer',
        'Penalty Shot',
      ],
      'zones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
      'outcomes': [
        'Goal',
        'Save',
        'Miss',
        'Post',
        'Crossbar',
        'Block',
        'Wide',
        'High',
        'Low',
      ],
    };
  }
}