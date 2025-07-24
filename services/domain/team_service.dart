// lib/services/domain/team_service.dart

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http_parser/http_parser.dart';

import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';
import 'package:hockey_shot_tracker/utils/platform_utils.dart';

/// Service responsible for team CRUD operations and management
/// 
/// This service provides:
/// - Team creation, updates, and deletion
/// - Team data retrieval and filtering
/// - Team player management
/// - Team logo upload and management
/// - Team statistics and metadata
class TeamService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  TeamService({
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
  
  /// Safe casting helper for team lists from API responses
  static List<Team> _castTeamList(dynamic teamList) {
    if (teamList is List) {
      return teamList.map((json) => Team.fromJson(json as Map<String, dynamic>)).toList();
    } else if (teamList is Map && teamList.containsKey('teams')) {
      final list = teamList['teams'];
      if (list is List) {
        return list.map((json) => Team.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
    if (kDebugMode) {
      print('⚠️ TeamService: Unexpected teamList type: ${teamList.runtimeType}');
    }
    return <Team>[];
  }

  /// Safe casting helper for player lists from API responses
  static List<Player> _castPlayerList(dynamic playerList) {
    if (playerList is List) {
      return playerList.map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
    } else if (playerList is Map && playerList.containsKey('players')) {
      final list = playerList['players'];
      if (list is List) {
        return list.map((json) => Player.fromJson(json as Map<String, dynamic>)).toList();
      }
    }
    if (kDebugMode) {
      print('⚠️ TeamService: Unexpected playerList type: ${playerList.runtimeType}');
    }
    return <Player>[];
  }
  
  // ==========================================
  // TEAM CREATION & MANAGEMENT
  // ==========================================
  
  /// Create a new team in the system
  /// 
  /// [teamData] must contain:
  /// - name: Team name
  /// - league: League or division name
  /// - age_group: Team age group
  /// Optional fields:
  /// - description: Team description
  /// - season: Current season
  /// - coach_id: ID of the assigned coach
  /// - home_arena: Home arena name
  Future<Team> createTeam(
    Map<String, dynamic> teamData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to create teams');
    }
    
    // Check permissions - only coordinators, directors, and admins can create teams
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to create teams');
    }
    
    try {
      // Validate required fields
      validateRequiredFields(teamData, [
        'name',
        'league',
        'age_group',
      ]);
      
      // Clean and prepare team data
      final cleanedData = cleanRequestData(teamData);
      
      if (kDebugMode) {
        print('🏒 TeamService: Creating team: ${cleanedData['name']} (${cleanedData['league']})');
      }
      
      final response = await post(
        '/api/teams',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to create team: empty response');
      }
      
      final team = Team.fromJson(result);
      
      if (kDebugMode) {
        print('✅ TeamService: Team created successfully: ${team.name} (ID: ${team.id})');
      }
      
      return team;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error creating team: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Update an existing team's information
  /// 
  /// Only users with appropriate permissions can update teams.
  Future<Team> updateTeam(
    int teamId,
    Map<String, dynamic> teamData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update teams');
    }
    
    // Check permissions
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to update teams');
    }
    
    try {
      // Clean the update data (remove null/empty values)
      final cleanedData = cleanRequestData(teamData);
      
      if (kDebugMode) {
        print('🏒 TeamService: Updating team $teamId with data: ${cleanedData.keys}');
      }
      
      final response = await put(
        '/api/teams/$teamId',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update team: empty response');
      }
      
      final team = Team.fromJson(result);
      
      if (kDebugMode) {
        print('✅ TeamService: Team $teamId updated successfully');
      }
      
      return team;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error updating team $teamId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Delete a team (admin/director only)
  /// 
  /// This is a destructive operation that removes the team and optionally
  /// all associated player and assessment data.
  Future<void> deleteTeam(
    int teamId, {
    bool deletePlayersAndData = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete teams');
    }
    
    // Check permissions - only admins and directors can delete teams
    if (!_authService.canDeleteTeams()) {
      throw AuthorizationException('Insufficient permissions to delete teams');
    }
    
    try {
      final queryParams = <String, String>{};
      if (deletePlayersAndData) queryParams['delete_data'] = 'true';
      
      if (kDebugMode) {
        print('🗑️ TeamService: Deleting team $teamId');
      }
      
      final response = await delete(
        '/api/teams/$teamId',
        queryParameters: queryParams,
        context: context,
      );
      
      if (response.statusCode != 200) {
        final errorData = handleResponse(response);
        throw ApiException('Failed to delete team: ${errorData?['message'] ?? 'Unknown error'}');
      }
      
      if (kDebugMode) {
        print('✅ TeamService: Team $teamId deleted successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error deleting team $teamId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM RETRIEVAL
  // ==========================================
  
  /// Fetch all teams accessible to the current user
  /// 
  /// Returns teams based on user permissions:
  /// - Coaches see their assigned teams
  /// - Coordinators/Directors/Admins see all teams
  Future<List<Team>> fetchTeams({
    String? league,
    String? ageGroup,
    String? season,
    String? search,
    bool includeInactive = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch teams');
    }
    
    try {
      final queryParams = <String, dynamic>{};
      
      if (league != null && league.isNotEmpty) queryParams['league'] = league;
      if (ageGroup != null && ageGroup.isNotEmpty) queryParams['age_group'] = ageGroup;
      if (season != null && season.isNotEmpty) queryParams['season'] = season;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (includeInactive) queryParams['include_inactive'] = 'true';
      
      if (kDebugMode) {
        print('🏒 TeamService: Fetching teams with filters: $queryParams');
      }
      
      final response = await get(
        '/api/teams',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ TeamService: No teams found');
        }
        return [];
      }
      
      // ✅ FIX: Use safe casting helper
      final teams = _castTeamList(result);
      
      if (kDebugMode) {
        print('✅ TeamService: Retrieved ${teams.length} teams');
      }
      
      return teams;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error fetching teams: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch a specific team by ID
  /// 
  /// Returns detailed team information including player count and statistics.
  Future<Team> fetchTeam(
    int teamId, {
    bool includeStats = false,
    bool includePlayers = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch team details');
    }
    
    try {
      final queryParams = <String, String>{};
      if (includeStats) queryParams['include_stats'] = 'true';
      if (includePlayers) queryParams['include_players'] = 'true';
      
      if (kDebugMode) {
        print('🏒 TeamService: Fetching team $teamId');
      }
      
      final response = await get(
        '/api/teams/$teamId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Team not found', 404);
      }
      
      final team = Team.fromJson(result);
      
      if (kDebugMode) {
        print('✅ TeamService: Team retrieved: ${team.name} (ID: ${team.id})');
      }
      
      return team;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error fetching team $teamId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch all players belonging to a specific team
  /// 
  /// Returns players with optional position filtering.
  Future<List<Player>> fetchTeamPlayers(
    int teamId, {
    String? position,
    bool includeInactive = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch team players');
    }
    
    try {
      final queryParams = <String, String>{};
      if (position != null && position.isNotEmpty) queryParams['position'] = position;
      if (includeInactive) queryParams['include_inactive'] = 'true';
      
      if (kDebugMode) {
        print('🏒 TeamService: Fetching players for team $teamId');
      }
      
      final response = await get(
        '/api/teams/$teamId/players',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ TeamService: No players found for team $teamId');
        }
        return [];
      }
      
      // ✅ FIX: Use safe casting helper
      final players = _castPlayerList(result);
      
      if (kDebugMode) {
        print('✅ TeamService: Retrieved ${players.length} players for team $teamId');
      }
      
      return players;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error fetching team $teamId players: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM LOGO MANAGEMENT
  // ==========================================
  
  /// ✅ FIX: Upload a team logo with required teamId parameter
  /// 
  /// Supports platform-specific file handling for web and mobile platforms.
  /// Returns the URL of the uploaded logo.
  Future<String?> uploadTeamLogo(
    int teamId,
    dynamic logoFile, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to upload team logo');
    }
    
    // Check if file upload is supported on current platform
    if (!PlatformUtils.supportsFeature(PlatformFeature.fileUpload)) {
      if (context != null) {
        PlatformUtils.showFeatureWarning(context, PlatformFeature.fileUpload);
      }
      if (kDebugMode) {
        print('⚠️ TeamService: File upload not supported on ${PlatformUtils.platformDescription}');
      }
      return null;
    }
    
    // Check permissions
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to upload team logos');
    }
    
    try {
      FormData formData;
      final fileTypeName = logoFile.runtimeType.toString();
      
      if (fileTypeName.contains('File') && PlatformUtils.canHandleFiles) {
        // Handle dart:io File object on mobile/desktop
        try {
          final filePath = _getFilePath(logoFile);
          if (filePath != null) {
            formData = FormData.fromMap({
              'team_id': teamId.toString(),
              'logo': await MultipartFile.fromFile(
                filePath,
                contentType: MediaType('image', 'jpeg'),
              ),
            });
          } else {
            throw Exception('Could not extract file path');
          }
        } catch (e) {
          throw Exception('Failed to process logo file: $e');
        }
      } else if (logoFile is WebSafeFile) {
        // Handle WebSafeFile for web platform
        formData = FormData.fromMap({
          'team_id': teamId.toString(),
          'logo': MultipartFile.fromBytes(
            logoFile.bytes,
            filename: logoFile.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        });
      } else {
        throw Exception('Unsupported file type: $fileTypeName on ${PlatformUtils.platformName}');
      }
      
      if (kDebugMode) {
        print('📸 TeamService: Uploading logo for team $teamId');
      }
      
      final response = await post(
        '/api/teams/$teamId/logo',
        data: formData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to upload team logo: empty response');
      }
      
      final logoPath = result['logo_path'] as String?;
      
      if (kDebugMode) {
        print('✅ TeamService: Team logo uploaded successfully: $logoPath');
      }
      
      return logoPath;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error uploading team logo: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      return null;
    }
  }
  
  /// Delete team logo
  Future<void> deleteTeamLogo(
    int teamId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete team logo');
    }
    
    if (!_authService.canManageTeams()) {
      throw AuthorizationException('Insufficient permissions to delete team logos');
    }
    
    try {
      await delete(
        '/api/teams/$teamId/logo',
        context: context,
      );
      
      if (kDebugMode) {
        print('✅ TeamService: Team logo deleted for team $teamId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error deleting team logo: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM STATISTICS & ANALYTICS
  // ==========================================
  
  /// Get team statistics summary
  /// 
  /// Returns aggregated statistics for all players on the team.
  Future<Map<String, dynamic>> getTeamStats(
    int teamId, {
    String? timeRange,
    String? assessmentType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get team stats');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      
      final response = await get(
        '/api/teams/$teamId/stats',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'team_summary': {
            'total_players': 0,
            'active_players': 0,
            'total_assessments': 0,
          },
          'player_stats': [],
          'team_averages': {},
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error fetching team stats: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get team's recent activity
  /// 
  /// Returns recent assessments, player additions, and other team activities.
  Future<List<Map<String, dynamic>>> getTeamActivity(
    int teamId, {
    int limit = 20,
    String? activityType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get team activity');
    }
    
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (activityType != null) queryParams['type'] = activityType;
      
      final response = await get(
        '/api/teams/$teamId/activity',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return [];
      }
      
      final activities = result['activities'] as List? ?? [];
      return activities.cast<Map<String, dynamic>>();
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error fetching team activity: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // TEAM VALIDATION & UTILITIES
  // ==========================================
  
  /// Validate team data before submission
  Map<String, dynamic> validateTeamData(Map<String, dynamic> teamData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    final name = teamData['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      errors.add('Team name is required');
    } else if (name.length > 100) {
      errors.add('Team name must be 100 characters or less');
    }
    
    final league = teamData['league'] as String?;
    if (league == null || league.trim().isEmpty) {
      errors.add('League is required');
    } else if (league.length > 100) {
      errors.add('League name must be 100 characters or less');
    }
    
    final ageGroup = teamData['age_group'] as String?;
    if (ageGroup == null || ageGroup.trim().isEmpty) {
      errors.add('Age group is required');
    } else {
      const validAgeGroups = [
        'youth_8_10',
        'youth_11_14', 
        'youth_15_18',
        'adult'
      ];
      if (!validAgeGroups.contains(ageGroup)) {
        warnings.add('Age group should be one of: ${validAgeGroups.join(', ')}');
      }
    }
    
    // Optional field validation
    final description = teamData['description'] as String?;
    if (description != null && description.length > 500) {
      errors.add('Description must be 500 characters or less');
    }
    
    final coachId = teamData['coach_id'];
    if (coachId != null && (coachId is! int || coachId <= 0)) {
      errors.add('Coach ID must be a valid positive integer');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Check if current user can modify a specific team
  bool canModifyTeam(int teamId) {
    // Admins and directors can modify any team
    if (_authService.canManageTeams()) return true;
    
    // Coordinators might have specific team assignments
    if (_authService.isCoordinator()) {
      // This would require checking the user's assigned teams
      // For now, assume coordinators can modify teams
      return true;
    }
    
    // Coaches might only modify their assigned team
    // This would require checking the user's team assignment
    return false;
  }
  
  /// Get team management permissions for current user
  Map<String, bool> getTeamPermissions() {
    return {
      'canCreateTeams': _authService.canManageTeams(),
      'canModifyTeams': _authService.canManageTeams(),
      'canDeleteTeams': _authService.canDeleteTeams(),
      'canViewAllTeams': _authService.isAuthenticated(),
      'canUploadLogos': _authService.canManageTeams(),
      'canManageRosters': _authService.canManageTeams(),
    };
  }
  
  /// Helper method to extract file path dynamically (for mobile/desktop)
  String? _getFilePath(dynamic file) {
    if (PlatformUtils.isWeb) return null;
    
    try {
      // Use dynamic property access to get the path
      return file?.path?.toString();
    } catch (e) {
      if (kDebugMode) {
        print('Could not extract file path: $e');
      }
      return null;
    }
  }
  
  /// Get team by name (for validation/duplicate checking)
  Future<Team?> findTeamByName(
    String teamName, {
    String? league,
    BuildContext? context,
  }) async {
    try {
      final teams = await fetchTeams(
        search: teamName,
        league: league,
        context: context,
      );
      
      // Look for exact name match
      for (final team in teams) {
        if (team.name.toLowerCase() == teamName.toLowerCase()) {
          return team;
        }
      }
      
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ TeamService: Error finding team by name: $e');
      }
      return null;
    }
  }
}

/// Web-safe File helper class for team logo uploads
class WebSafeFile {
  final String path;
  final String name; 
  final List<int> bytes;
  
  WebSafeFile({
    required this.path,
    required this.name,
    required this.bytes,
  });
}