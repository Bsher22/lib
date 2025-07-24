// lib/providers/player_provider.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/player.dart';
import '../models/team.dart';

/// Provider for player-related data and operations
class PlayerProvider with ChangeNotifier {
  final String baseUrl;
  final String? authToken;
  
  List<Player> _players = [];
  Map<String, Team> _playerTeams = {};
  
  PlayerProvider({required this.baseUrl, this.authToken});
  
  // Getters
  List<Player> get players => _players;
  
  Player? getPlayer(String id) {
    try {
      return _players.firstWhere((player) => player.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Team? getPlayerTeam(String playerId) {
    return _playerTeams[playerId];
  }
  
  // Filter players
  List<Player> filterPlayers({
    String? searchQuery,
    String? teamId,
    String? coachId,
    String? coordinatorId,
  }) {
    return _players.where((player) {
      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!player.name.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Apply team filter
      if (teamId != null && teamId.isNotEmpty) {
        if (player.teamId != teamId) {
          return false;
        }
      }
      
      // Apply coach filter
      if (coachId != null && coachId.isNotEmpty) {
        if (player.primaryCoachId != coachId) {
          return false;
        }
      }
      
      // Apply coordinator filter
      if (coordinatorId != null && coordinatorId.isNotEmpty) {
        if (player.coordinatorId != coordinatorId) {
          return false;
        }
      }
      
      return true;
    }).toList();
  }
  
  // Fetch all players
  Future<void> fetchPlayers() async {
    if (authToken == null) return;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/players'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _players = data.map((json) => Player.fromJson(json)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Fetch players error: $e');
    }
  }
  
  // Fetch player's team
  Future<Team?> fetchPlayerTeam(String playerId) async {
    if (authToken == null) return null;
    
    final player = getPlayer(playerId);
    if (player == null || player.teamId == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teams/${player.teamId}'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final team = Team.fromJson(data);
        
        // Cache the team
        _playerTeams[playerId] = team;
        
        notifyListeners();
        return team;
      }
      return null;
    } catch (e) {
      print('Fetch player team error: $e');
      return null;
    }
  }
}