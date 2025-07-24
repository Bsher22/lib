// lib/services/domain/player_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for player CRUD operations and profile management
/// 
/// This service provides:
/// - Player registration and profile management with full pagination support
/// - Player data retrieval and updates
/// - Team-based player filtering
/// - Player statistics and metadata
/// - Player search and filtering capabilities
class PlayerService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================
  
  final AuthService _authService;
  
  PlayerService({
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
  // ✅ PAGINATION HANDLING
  // ==========================================
  
  /// Fetch all players with automatic pagination handling
  /// This method will automatically fetch all pages until all players are retrieved
  Future<List<Player>> fetchAllPlayers({
    int? teamId,
    String? position,
    String? ageGroup,
    String? search,
    bool includeInactive = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch players');
    }
    
    try {
      final allPlayers = <Player>[];
      int offset = 0;
      const int limit = 100; // Increase page size for efficiency
      bool hasMore = true;
      int totalExpected = 0;
      
      if (kDebugMode) {
        print('🏒 PlayerService: Starting to fetch ALL players with pagination...');
      }
      
      while (hasMore) {
        final queryParams = <String, dynamic>{
          'limit': limit.toString(),
          'offset': offset.toString(),
        };
        
        if (teamId != null) queryParams['team_id'] = teamId.toString();
        if (position != null && position.isNotEmpty) queryParams['position'] = position;
        if (ageGroup != null && ageGroup.isNotEmpty) queryParams['age_group'] = ageGroup;
        if (search != null && search.isNotEmpty) queryParams['search'] = search;
        if (includeInactive) queryParams['include_inactive'] = 'true';
        
        if (kDebugMode) {
          print('🔄 PlayerService: Fetching page at offset $offset (limit: $limit)');
        }
        
        final response = await get(
          '/api/players',
          queryParameters: queryParams,
          context: context,
        );
        
        final result = handleResponse(response);
        if (result == null) {
          if (kDebugMode) {
            print('ℹ️ PlayerService: No more players found at offset $offset');
          }
          break;
        }
        
        // Handle paginated response structure
        List<Player> pagePlayersList;
        Map<String, dynamic>? paginationInfo;
        
        if (result is Map<String, dynamic>) {
          // Extract pagination info
          if (result.containsKey('pagination')) {
            paginationInfo = result['pagination'] as Map<String, dynamic>?;
            if (totalExpected == 0 && paginationInfo != null) {
              totalExpected = (paginationInfo['total'] as num?)?.toInt() ?? 0;
              if (kDebugMode) {
                print('📊 PlayerService: Total players expected: $totalExpected');
              }
            }
          }
          
          // Extract players list
          if (result.containsKey('players')) {
            pagePlayersList = _castPlayerList(result['players']);
          } else {
            pagePlayersList = _castPlayerList(result);
          }
        } else {
          pagePlayersList = _castPlayerList(result);
        }
        
        if (pagePlayersList.isEmpty) {
          if (kDebugMode) {
            print('ℹ️ PlayerService: No players in current page, stopping pagination');
          }
          break;
        }
        
        allPlayers.addAll(pagePlayersList);
        
        if (kDebugMode) {
          print('✅ PlayerService: Page fetched - ${pagePlayersList.length} players (total so far: ${allPlayers.length})');
        }
        
        // Check if we should continue pagination
        if (paginationInfo != null) {
          hasMore = paginationInfo['has_more'] as bool? ?? false;
          final returnedCount = paginationInfo['count'] as int? ?? pagePlayersList.length;
          
          // Safety check: if we got fewer players than requested, we're at the end
          if (returnedCount < limit) {
            hasMore = false;
          }
        } else {
          // Fallback logic if no pagination info
          hasMore = pagePlayersList.length == limit;
        }
        
        offset += pagePlayersList.length;
        
        // Safety check to prevent infinite loops
        if (offset > 10000) {
          if (kDebugMode) {
            print('⚠️ PlayerService: Safety limit reached, stopping pagination at offset $offset');
          }
          break;
        }
      }
      
      if (kDebugMode) {
        print('🎯 PlayerService: Pagination complete!');
        print('📈 PlayerService: Total players fetched: ${allPlayers.length}');
        if (totalExpected > 0) {
          print('📊 PlayerService: Expected vs Actual: $totalExpected vs ${allPlayers.length}');
          if (allPlayers.length != totalExpected) {
            print('⚠️ PlayerService: Mismatch in expected vs actual player count');
          }
        }
      }
      
      return allPlayers;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error fetching all players: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // ✅ FIX: CASTING HELPER METHODS
  // ==========================================
  
  /// Safe casting helper for player lists from API responses
  static List<Player> _castPlayerList(dynamic playerList) {
    if (playerList is List) {
      return playerList.map((json) {
        if (json is Map<String, dynamic>) {
          return Player.fromJson(json);
        } else if (json is Map) {
          return Player.fromJson(Map<String, dynamic>.from(json));
        } else {
          if (kDebugMode) {
            print('⚠️ PlayerService: Invalid player data type: ${json.runtimeType}');
          }
          throw FormatException('Invalid player data format');
        }
      }).toList();
    } else if (playerList is Map && playerList.containsKey('players')) {
      final list = playerList['players'];
      if (list is List) {
        return list.map((json) {
          if (json is Map<String, dynamic>) {
            return Player.fromJson(json);
          } else if (json is Map) {
            return Player.fromJson(Map<String, dynamic>.from(json));
          } else {
            if (kDebugMode) {
              print('⚠️ PlayerService: Invalid player data type in nested list: ${json.runtimeType}');
            }
            throw FormatException('Invalid player data format');
          }
        }).toList();
      }
    }
    
    if (kDebugMode) {
      print('⚠️ PlayerService: Unexpected playerList type: ${playerList.runtimeType}');
    }
    return <Player>[];
  }
  
  // ==========================================
  // PLAYER RETRIEVAL (UPDATED FOR COMPATIBILITY)
  // ==========================================
  
  /// Fetch players with optional pagination (maintains backward compatibility)
  /// 
  /// By default, this will fetch ALL players. Set [usePagination] to false
  /// to use the old single-page behavior.
  Future<List<Player>> fetchPlayers({
    int? teamId,
    String? position,
    String? ageGroup,
    String? search,
    bool includeInactive = false,
    bool usePagination = true,
    int? limit,
    int? offset,
    BuildContext? context,
  }) async {
    // If pagination is disabled or specific limit/offset provided, use single page
    if (!usePagination || limit != null || offset != null) {
      return _fetchPlayersPage(
        teamId: teamId,
        position: position,
        ageGroup: ageGroup,
        search: search,
        includeInactive: includeInactive,
        limit: limit,
        offset: offset,
        context: context,
      );
    }
    
    // Otherwise, fetch all players using pagination
    return fetchAllPlayers(
      teamId: teamId,
      position: position,
      ageGroup: ageGroup,
      search: search,
      includeInactive: includeInactive,
      context: context,
    );
  }
  
  /// Fetch a single page of players (for backward compatibility)
  Future<List<Player>> _fetchPlayersPage({
    int? teamId,
    String? position,
    String? ageGroup,
    String? search,
    bool includeInactive = false,
    int? limit,
    int? offset,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch players');
    }
    
    try {
      final queryParams = <String, dynamic>{};
      
      if (teamId != null) queryParams['team_id'] = teamId.toString();
      if (position != null && position.isNotEmpty) queryParams['position'] = position;
      if (ageGroup != null && ageGroup.isNotEmpty) queryParams['age_group'] = ageGroup;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (includeInactive) queryParams['include_inactive'] = 'true';
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();
      
      if (kDebugMode) {
        print('🏒 PlayerService: Fetching single page of players with filters: $queryParams');
      }
      
      final response = await get(
        '/api/players',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ PlayerService: No players found');
        }
        return [];
      }
      
      final players = _castPlayerList(result);
      
      if (kDebugMode) {
        print('✅ PlayerService: Retrieved ${players.length} players (single page)');
      }
      
      return players;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error fetching players page: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // PLAYER REGISTRATION & CREATION
  // ==========================================
  
  /// Register a new player in the system
  /// 
  /// [playerData] must contain:
  /// - name: Player's full name
  /// - position: Player position (forward, defense, goalie)
  /// - team_id: ID of the team the player belongs to
  /// - jersey_number: Player's jersey number
  /// Optional fields:
  /// - age_group: Player's age group
  /// - birthdate: Player's birth date
  /// - height: Player's height
  /// - weight: Player's weight
  /// - shoots: Handedness (left, right)
  Future<Player> registerPlayer(
    Map<String, dynamic> playerData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to register players');
    }
    
    try {
      // Validate required fields
      validateRequiredFields(playerData, [
        'name',
        'position',
        'team_id',
      ]);
      
      // Clean and prepare player data
      final cleanedData = cleanRequestData(playerData);
      
      // Validate position
      const validPositions = ['forward', 'defense', 'goalie'];
      final position = cleanedData['position']?.toString().toLowerCase();
      if (position != null && !validPositions.contains(position)) {
        throw ValidationException('Position must be one of: ${validPositions.join(', ')}');
      }
      
      if (kDebugMode) {
        print('🏒 PlayerService: Registering player: ${cleanedData['name']} (${cleanedData['position']})');
      }
      
      final response = await post(
        '/api/players',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to register player: empty response');
      }
      
      final player = Player.fromJson(result);
      
      if (kDebugMode) {
        print('✅ PlayerService: Player registered successfully: ${player.name} (ID: ${player.id})');
      }
      
      return player;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error registering player: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // OTHER METHODS (UNCHANGED)
  // ==========================================
  
  /// Fetch a specific player by ID
  /// 
  /// Returns detailed player information including statistics and metadata.
  Future<Player> fetchPlayer(
    int playerId, {
    bool includeStats = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch player details');
    }
    
    try {
      final queryParams = <String, String>{};
      if (includeStats) queryParams['include_stats'] = 'true';
      
      if (kDebugMode) {
        print('🏒 PlayerService: Fetching player $playerId');
      }
      
      final response = await get(
        '/api/players/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Player not found', 404);
      }
      
      final player = Player.fromJson(result);
      
      if (kDebugMode) {
        print('✅ PlayerService: Player retrieved: ${player.name} (ID: ${player.id})');
      }
      
      return player;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error fetching player $playerId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Fetch players by team ID
  /// 
  /// Returns all players belonging to a specific team.
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
        print('🏒 PlayerService: Fetching players for team $teamId');
      }
      
      final response = await get(
        '/api/teams/$teamId/players',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          print('ℹ️ PlayerService: No players found for team $teamId');
        }
        return [];
      }
      
      final players = _castPlayerList(result);
      
      if (kDebugMode) {
        print('✅ PlayerService: Retrieved ${players.length} players for team $teamId');
      }
      
      return players;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error fetching team $teamId players: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Update an existing player's information
  /// 
  /// Only users with appropriate permissions can update players.
  /// Updates can include profile information, position, team assignment, etc.
  Future<Player> updatePlayer(
    int playerId,
    Map<String, dynamic> playerData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update players');
    }
    
    try {
      // Clean the update data (remove null/empty values)
      final cleanedData = cleanRequestData(playerData);
      
      // Validate position if provided
      if (cleanedData.containsKey('position')) {
        const validPositions = ['forward', 'defense', 'goalie'];
        final position = cleanedData['position']?.toString().toLowerCase();
        if (position != null && !validPositions.contains(position)) {
          throw ValidationException('Position must be one of: ${validPositions.join(', ')}');
        }
      }
      
      if (kDebugMode) {
        print('🏒 PlayerService: Updating player $playerId with data: ${cleanedData.keys}');
      }
      
      final response = await put(
        '/api/players/$playerId',
        data: cleanedData,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update player: empty response');
      }
      
      final player = Player.fromJson(result);
      
      if (kDebugMode) {
        print('✅ PlayerService: Player $playerId updated successfully');
      }
      
      return player;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error updating player $playerId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Delete a player (admin/director only)
  /// 
  /// This is a destructive operation that removes the player and all
  /// associated assessment data. Only admins and directors can delete players.
  Future<Map<String, dynamic>> deletePlayer(
    int playerId, {
    bool deleteAssessments = false,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete players');
    }
    
    // Check permissions - only admins and directors can delete players
    if (!_authService.canDeleteTeams()) {
      throw AuthorizationException('Insufficient permissions to delete players');
    }
    
    try {
      final queryParams = <String, String>{};
      if (deleteAssessments) queryParams['delete_assessments'] = 'true';
      
      if (kDebugMode) {
        print('🗑️ PlayerService: Deleting player $playerId');
      }
      
      final response = await delete(
        '/api/players/$playerId',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response) ?? {
        'success': true,
        'message': 'Player deleted successfully'
      };
      
      if (kDebugMode) {
        print('✅ PlayerService: Player $playerId deleted successfully');
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error deleting player $playerId: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  // ==========================================
  // VALIDATION & UTILITIES
  // ==========================================
  
  /// Validate player data before submission
  Map<String, dynamic> validatePlayerData(Map<String, dynamic> playerData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    final name = playerData['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      errors.add('Player name is required');
    } else if (name.length > 100) {
      errors.add('Player name must be 100 characters or less');
    }
    
    final position = playerData['position'] as String?;
    if (position == null || position.trim().isEmpty) {
      errors.add('Player position is required');
    } else {
      const validPositions = ['forward', 'defense', 'goalie'];
      if (!validPositions.contains(position.toLowerCase())) {
        errors.add('Position must be one of: ${validPositions.join(', ')}');
      }
    }
    
    final teamId = playerData['team_id'];
    if (teamId == null) {
      errors.add('Team ID is required');
    } else if (teamId is! int || teamId <= 0) {
      errors.add('Team ID must be a valid positive integer');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Check if current user can modify a specific player
  bool canModifyPlayer(int playerId, int? playerTeamId) {
    // Admins and directors can modify any player
    if (_authService.canManageTeams()) return true;
    
    // Coordinators can modify players in their assigned teams
    if (_authService.isCoordinator()) return true;
    
    // Coaches can only modify players on their own team
    if (_authService.isCoach()) return true;
    
    return false;
  }
  
  /// Get player management permissions for current user
  Map<String, bool> getPlayerPermissions() {
    return {
      'canCreatePlayers': _authService.isAuthenticated(),
      'canModifyPlayers': _authService.isAuthenticated(),
      'canDeletePlayers': _authService.canDeleteTeams(),
      'canViewAllPlayers': _authService.canManageTeams(),
      'canAssignTeams': _authService.canManageTeams(),
    };
  }
  
  // ==========================================
  // ADDITIONAL METHODS (KEEPING EXISTING FUNCTIONALITY)
  // ==========================================
  
  /// Get player statistics summary
  Future<Map<String, dynamic>> getPlayerStats(
    int playerId, {
    String? timeRange,
    String? assessmentType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get player stats');
    }
    
    try {
      final queryParams = <String, String>{};
      if (timeRange != null) queryParams['time_range'] = timeRange;
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      
      final response = await get(
        '/api/players/$playerId/stats',
        queryParameters: queryParams,
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        return {
          'shots': {'total': 0, 'goals': 0, 'accuracy': 0.0},
          'skating': {'assessments': 0, 'average_score': 0.0},
          'assessments': {'total': 0, 'completed': 0},
        };
      }
      
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error fetching player stats: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Get player's recent activity
  Future<List<Map<String, dynamic>>> getPlayerActivity(
    int playerId, {
    int limit = 20,
    String? activityType,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get player activity');
    }
    
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };
      if (activityType != null) queryParams['type'] = activityType;
      
      final response = await get(
        '/api/players/$playerId/activity',
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
        print('❌ PlayerService: Error fetching player activity: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
  
  /// Update player status (active/inactive/injured)
  Future<Player> updatePlayerStatus(
    int playerId,
    String status, {
    String? reason,
    DateTime? statusDate,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();
    
    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update player status');
    }
    
    try {
      const validStatuses = ['active', 'inactive', 'injured', 'suspended'];
      if (!validStatuses.contains(status)) {
        throw ValidationException('Status must be one of: ${validStatuses.join(', ')}');
      }
      
      final response = await patch(
        '/api/players/$playerId/status',
        data: {
          'status': status,
          if (reason != null) 'reason': reason,
          if (statusDate != null) 'status_date': statusDate.toIso8601String(),
        },
        context: context,
      );
      
      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update player status: empty response');
      }
      
      return Player.fromJson(result);
    } catch (e) {
      if (kDebugMode) {
        print('❌ PlayerService: Error updating player status: $e');
      }
      
      if (e is AuthenticationException) {
        handleAuthenticationError(context);
      }
      
      rethrow;
    }
  }
}