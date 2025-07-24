// lib/services/skating/skating_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for skating assessments, session management, and skating analytics
/// 
/// This service provides:
/// - Modern session-based skating assessment creation
/// - Test addition to existing sessions
/// - Player skating session retrieval and management
/// - Skating analytics and benchmarking
/// - Team skating batch assessment capabilities
/// - Legacy compatibility methods for existing code
class SkatingService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  SkatingService({
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
  // MODERN SESSION-BASED SKATING ASSESSMENTS
  // ==========================================
  
  /// Creates a new skating assessment session
  /// 
  /// This should be called first before any tests are executed.
  /// Returns the session framework ready for test additions.
  Future<Map<String, dynamic>> createSkatingSession({
    required int playerId,
    required String ageGroup,
    required String position,
    String? assessmentId,
    String? title,
    String? description,
    String assessmentType = 'comprehensive',
    int totalTests = 5,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to create skating sessions');
    }
    
    try {
      // Normalize age group to database-compatible format
      final normalizedAgeGroup = _normalizeAgeGroup(ageGroup);
      
      // Normalize position to database-compatible format
      final normalizedPosition = _normalizePosition(position);
      
      final sessionData = {
        'player_id': playerId,
        'age_group': normalizedAgeGroup,
        'position': normalizedPosition,
        'assessment_id': assessmentId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title ?? 'Skating Assessment Session',
        'description': description ?? 'Comprehensive skating assessment',
        'assessment_type': assessmentType,
        'total_tests': totalTests,
      };
      
      if (kDebugMode) {
        print('🚀 SkatingService: Creating skating session: ${sessionData['assessment_id']}');
        print('   Original ageGroup: "$ageGroup" → Normalized: "$normalizedAgeGroup"');
        print('   Original position: "$position" → Normalized: "$normalizedPosition"');
      }
      
      final response = await post(
        '/api/skating/sessions',
        data: sessionData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to create skating session: empty response');
      }
      
      if (kDebugMode) {
        print('✅ SkatingService: Successfully created skating session');
      }
      
      return result['session'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error creating skating session: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Gets complete session data including all tests and analytics
  /// 
  /// This is the primary endpoint for retrieving session results.
  Future<Map<String, dynamic>> getSkatingSession(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating sessions');
    }
    
    try {
      if (kDebugMode) {
        print('📥 SkatingService: Fetching skating session: $assessmentId');
      }
      
      final response = await get(
        '/api/skating/sessions/$assessmentId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Skating session not found', 404);
      }
      
      if (kDebugMode) {
        print('✅ SkatingService: Successfully retrieved skating session');
      }
      
      return result['session'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skating session: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Adds test results to an existing skating session
  /// 
  /// This replaces the complex assessment creation - tests are added incrementally.
  Future<Map<String, dynamic>> addTestToSession({
    required String assessmentId,
    required Map<String, dynamic> testTimes,
    String? notes,
    String? title,
    String? description,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to add tests to sessions');
    }
    
    try {
      // Validate test times data
      final validation = validateTestTimes(testTimes);
      if (!validation['isValid']) {
        throw ValidationException('Invalid test times: ${validation['errors'].join(', ')}');
      }
      
      final testData = {
        'test_times': testTimes,
        'notes': notes,
        'title': title,
        'description': description,
      };
      
      if (kDebugMode) {
        print('🧪 SkatingService: Adding test to session: $assessmentId');
      }
      
      final response = await post(
        '/api/skating/sessions/$assessmentId/tests',
        data: testData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to add test to session: empty response');
      }
      
      if (kDebugMode) {
        print('✅ SkatingService: Successfully added test to session');
      }
      
      return result['session'];
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error adding test to session: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Gets all skating sessions for a player
  /// 
  /// This replaces the complex player assessment retrieval with session-based approach.
  Future<List<Map<String, dynamic>>> getPlayerSkatingSessions({
    required int playerId,
    int? limit,
    int offset = 0,
    String? status,
    String? assessmentType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player skating sessions');
    }
    
    try {
      final queryParams = <String, dynamic>{
        'offset': offset.toString(),
      };
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      
      if (kDebugMode) {
        print('📋 SkatingService: Fetching skating sessions for player: $playerId');
      }
      
      final response = await get(
        '/api/skating/players/$playerId/sessions',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ SkatingService: No skating sessions found for player $playerId');
        }
        return [];
      }
      
      final sessions = result['session']['sessions'] as List? ?? [];
      
      if (kDebugMode) {
        print('✅ SkatingService: Retrieved ${sessions.length} skating sessions');
      }
      
      return sessions.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching player skating sessions: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // LEGACY COMPATIBILITY METHODS
  // ==========================================
  
  /// Legacy method: Create skating assessment (deprecated)
  /// 
  /// Redirects to new session-based approach for backward compatibility.
  @Deprecated('Use createSkatingSession() and addTestToSession() instead')
  Future<Map<String, dynamic>> createSkatingAssessment(
    Map<String, dynamic> skatingData, {
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      print('⚠️ SkatingService: createSkatingAssessment() is deprecated. Use createSkatingSession() and addTestToSession() instead.');
    }
    
    // For backward compatibility, redirect to new session-based approach
    if (skatingData['save'] == false) {
      // Just analyze without saving - call legacy endpoint temporarily
      return analyzeSkating(skatingData, context: context);
    }
    
    // Create session and add test
    try {
      final assessmentId = skatingData['assessment_id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create session first
      final sessionData = await createSkatingSession(
        playerId: skatingData['player_id'],
        ageGroup: skatingData['age_group'] ?? 'youth_15_18',
        position: skatingData['position'] ?? 'forward',
        assessmentId: assessmentId,
        title: skatingData['title'] ?? 'Skating Assessment',
        description: skatingData['description'],
        assessmentType: skatingData['assessment_type'] ?? 'comprehensive',
        totalTests: 1, // Legacy assessments are single tests
        context: context,
      );
      
      // Add test to session
      final sessionWithTest = await addTestToSession(
        assessmentId: assessmentId,
        testTimes: skatingData['test_times'],
        notes: skatingData['notes'],
        title: skatingData['title'],
        description: skatingData['description'],
        context: context,
      );
      
      return {
        'assessment_id': assessmentId,
        'player_id': skatingData['player_id'],
        'session': sessionWithTest,
        'message': 'Legacy assessment created using new session approach',
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error in legacy createSkatingAssessment: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Legacy method: Analyze skating (deprecated)
  /// 
  /// For analysis-only operations without saving.
  @Deprecated('Use addTestToSession() for full functionality')
  Future<Map<String, dynamic>> analyzeSkating(
    Map<String, dynamic> skatingData, {
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      print('⚠️ SkatingService: analyzeSkating() is deprecated. Use addTestToSession() for full functionality.');
    }
    
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to analyze skating');
    }
    
    skatingData['save'] = false;
    
    try {
      // Legacy endpoint for analysis only
      final response = await post(
        '/api/skating/assessments',
        data: skatingData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to analyze skating: empty response');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error analyzing skating: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Legacy method: Save skating (deprecated)
  /// 
  /// Redirects to new approach.
  @Deprecated('Use createSkatingSession() and addTestToSession() instead')
  Future<Map<String, dynamic>> saveSkating(
    Map<String, dynamic> skatingData, {
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      print('⚠️ SkatingService: saveSkating() is deprecated. Use createSkatingSession() and addTestToSession() instead.');
    }
    
    // Redirect to new approach
    skatingData['save'] = true;
    return createSkatingAssessment(skatingData, context: context);
  }
  
  // ==========================================
  // UPDATED SKATING RETRIEVAL METHODS
  // ==========================================
  
  /// Updated method to use new session-based backend
  Future<List<Skating>> fetchSkatings(
    int playerId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating data');
    }
    
    try {
      // Use new session-based endpoint
      final sessions = await getPlayerSkatingSessions(
        playerId: playerId,
        context: context,
      );
      
      final List<Skating> allSkatings = [];
      for (final session in sessions) {
        if (session['tests'] != null) {
          final tests = session['tests'] as List;
          for (final test in tests) {
            allSkatings.add(Skating.fromJson(test));
          }
        }
      }
      
      return allSkatings;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skatings: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Updated method to fetch specific skating test
  Future<Skating> fetchSkating(
    int skatingId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating details');
    }
    
    try {
      final response = await get(
        '/api/skating/assessments/detail/$skatingId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Skating assessment not found', 404);
      }
      
      return Skating.fromJson(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skating: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Updated method to get skating assessments by session ID
  Future<Map<String, dynamic>> getSkatingAssessmentsBySession(
    String assessmentId, {
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      print('ℹ️ SkatingService: Using new getSkatingSession() method');
    }
    
    try {
      final session = await getSkatingSession(assessmentId, context: context);
      
      // Format in legacy-compatible way
      final tests = session['tests'] as List? ?? [];
      return {
        'assessments': tests,
        'session_id': assessmentId,
        'count': tests.length,
      };
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skating assessments by session: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // SIMPLIFIED SKATING ANALYTICS
  // ==========================================
  
  /// Simplified method to get player skating assessments
  /// 
  /// This now uses the session-based approach internally
  Future<List<Map<String, dynamic>>> getPlayerSkatingAssessments(
    int playerId, {
    Map<String, dynamic>? filters,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch skating assessments');
    }
    
    try {
      // Use new session-based approach
      final sessions = await getPlayerSkatingSessions(
        playerId: playerId,
        context: context,
      );
      
      final List<Map<String, dynamic>> assessments = [];
      for (final session in sessions) {
        // Convert session to assessment format for compatibility
        final assessment = {
          'id': session['assessment_id'],
          'player_id': session['player_id'],
          'player_name': session['player_name'],
          'title': session['session_title'] ?? 'Skating Assessment',
          'description': session['session_description'],
          'status': session['status'],
          'completed_at': session['completed_at'],
          'created_at': session['started_at'],
          'total_tests': session['total_tests_planned'],
          'completed_tests': session['completed_tests'],
          'tests': session['tests'] ?? [],
          'analytics': session['analytics'],
        };
        assessments.add(assessment);
      }
      
      return assessments;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skating assessments: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      throw ApiException('Failed to load skating assessments: $e');
    }
  }
  
  /// Updated skating comparison method
  Future<Map<String, dynamic>> getSkatingComparison(
    int skatingId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get skating comparison');
    }
    
    try {
      final response = await get(
        '/api/analytics/skating/comparison/$skatingId',
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Skating comparison data not found', 404);
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error fetching skating comparison: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM SKATING METHODS
  // ==========================================
  
  /// Simplified team skating batch assessment
  Future<List<Map<String, dynamic>>> saveTeamSkating(
    Skating assessment,
    String teamName,
    List<Player> players,
    Map<String, Map<String, double>> playerTestTimes, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to save team skating');
    }
    
    // Generate team session ID
    final teamSessionId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final List<Map<String, dynamic>> results = [];
      
      // Create individual sessions for each player
      for (final player in players) {
        // Skip players without valid IDs
        if (player.id == null) {
          if (kDebugMode) {
            print('⚠️ SkatingService: Skipping player ${player.name} - no valid ID');
          }
          continue;
        }
        
        final playerId = player.id!;
        final playerIdStr = playerId.toString();
        if (!playerTestTimes.containsKey(playerIdStr) || playerTestTimes[playerIdStr]!.isEmpty) {
          continue;
        }
        
        // Create session for this player
        final playerSessionId = '${teamSessionId}_player_$playerId';
        final sessionData = await createSkatingSession(
          playerId: playerId,
          ageGroup: player.ageGroup,
          position: player.position?.toLowerCase() ?? 'forward',
          assessmentId: playerSessionId,
          title: '$teamName - ${assessment.title}',
          description: 'Team assessment for ${player.name}',
          assessmentType: assessment.assessmentType,
          totalTests: 1,
          context: context,
        );
        
        // Add test results
        final sessionWithTest = await addTestToSession(
          assessmentId: playerSessionId,
          testTimes: playerTestTimes[playerIdStr]!,
          title: '${assessment.title} - ${player.name}',
          description: 'Team assessment results',
          context: context,
        );
        
        results.add(sessionWithTest);
      }
      
      if (kDebugMode) {
        print('✅ SkatingService: Created ${results.length} team skating assessments');
      }
      
      return results;
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error saving team skating: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // UTILITY & VALIDATION METHODS
  // ==========================================
  
  /// Normalize age group to database-compatible format
  String _normalizeAgeGroup(String ageGroup) {
    switch (ageGroup.toLowerCase().trim()) {
      case 'adult':
      case 'adults':
        return 'adult';
      case 'youth_15_18':
      case 'youth 15-18':
      case '15-18':
      case 'youth_15_to_18':
        return 'youth_15_18';
      case 'youth_11_14':
      case 'youth 11-14':
      case '11-14':
      case 'youth_11_to_14':
        return 'youth_11_14';
      case 'youth_8_10':
      case 'youth 8-10':
      case '8-10':
      case 'youth_8_to_10':
        return 'youth_8_10';
      case 'unknown':
      case '':
        return 'youth_15_18'; // Safe fallback
      default:
        if (kDebugMode) {
          print('⚠️ SkatingService: Unrecognized age group: "$ageGroup", using fallback');
        }
        return 'youth_15_18';
    }
  }
  
  /// Normalize position to database-compatible format
  String _normalizePosition(String position) {
    switch (position.toLowerCase().trim()) {
      case 'forward':
      case 'forwards':
      case 'f':
        return 'forward';
      case 'defenseman':
      case 'defense':
      case 'defenceman':
      case 'defence':
      case 'd':
        return 'defense';
      case 'goalie':
      case 'goalkeeper':
      case 'goaltender':
      case 'g':
        return 'goalie';
      case 'unknown':
      case '':
        return 'forward'; // Safe fallback
      default:
        if (kDebugMode) {
          print('⚠️ SkatingService: Unrecognized position: "$position", using fallback');
        }
        return 'forward';
    }
  }
  
  /// Validate test times data
  Map<String, dynamic> validateTestTimes(Map<String, dynamic> testTimes) {
    final errors = <String>[];
    final warnings = <String>[];
    
    if (testTimes.isEmpty) {
      errors.add('Test times cannot be empty');
    }
    
    // Check for valid test categories
    const validCategories = [
      'agility',
      'acceleration',
      'top_speed',
      'backwards_skating',
      'crossovers',
      'transitions',
      'balance',
      'edge_work',
    ];
    
    testTimes.forEach((test, time) {
      // Validate test name
      if (!validCategories.any((cat) => test.toLowerCase().contains(cat.toLowerCase()))) {
        warnings.add('Test "$test" may not be a standard skating test');
      }
      
      // Validate time value
      if (time == null) {
        errors.add('Test "$test" has null time value');
      } else if (time is! num) {
        errors.add('Test "$test" time must be a number');
      } else if (time <= 0) {
        errors.add('Test "$test" time must be positive');
      } else if (time > 300) {
        warnings.add('Test "$test" time seems unusually high (${time}s)');
      }
    });
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Show migration guidance for developers
  static void showSkatingApiMigrationGuidance() {
    if (!kDebugMode) return;
    
    print('''
🔄 SKATING API MIGRATION GUIDE:

OLD METHODS (deprecated):
❌ createSkatingAssessment()
❌ analyzeSkating()
❌ saveSkating()

NEW SESSION-BASED APPROACH:
✅ 1. createSkatingSession() - Create session framework
✅ 2. addTestToSession() - Add test results incrementally  
✅ 3. getSkatingSession() - Retrieve complete session data
✅ 4. getPlayerSkatingSessions() - Get all player sessions

MIGRATION PATTERN:
OLD:
final result = await apiService.saveSkating(data);

NEW:
// 1. Create session
final session = await skatingService.createSkatingSession(
  playerId: playerId,
  ageGroup: ageGroup,
  position: position,
);

// 2. Add test results
final updatedSession = await skatingService.addTestToSession(
  assessmentId: session['assessment_id'],
  testTimes: testData,
);

This provides better error handling, clearer data flow, and matches the backend architecture.
''');
  }
  
  /// Delete a skating session and all associated tests
  Future<void> deleteSkatingSession(
    String assessmentId, {
    bool deleteTests = true,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete skating sessions');
    }
    
    // Check permissions
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to delete skating sessions');
    }
    
    try {
      final queryParams = <String, String>{};
      if (deleteTests) queryParams['delete_tests'] = 'true';
      
      if (kDebugMode) {
        print('🗑️ SkatingService: Deleting skating session $assessmentId');
      }
      
      final response = await delete(
        '/api/skating/sessions/$assessmentId',
        queryParameters: queryParams,
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to delete skating session: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ SkatingService: Skating session $assessmentId deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ SkatingService: Error deleting skating session: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
}