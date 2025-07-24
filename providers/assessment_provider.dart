// lib/providers/assessment_provider.dart
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/assessment/assessment_results.dart';
import '../models/assessment/test_result.dart';

/// Provider for assessment-related data and operations
class AssessmentProvider with ChangeNotifier {
  final String baseUrl;
  final String? authToken;
  
  // Cache assessment data
  Map<String, AssessmentResults> _playerAssessmentResults = {};
  Map<String, List<TestResult>> _playerTestResults = {};
  Map<String, List<dynamic>> _playerRecentAssessments = {};
  
  AssessmentProvider({required this.baseUrl, this.authToken});
  
  // Getter methods
  AssessmentResults? getPlayerAssessmentResults(String playerId) {
    return _playerAssessmentResults[playerId];
  }
  
  List<TestResult> getPlayerTestResults(String playerId) {
    return _playerTestResults[playerId] ?? [];
  }
  
  List<dynamic> getPlayerRecentAssessments(String playerId, {int limit = 3}) {
    final assessments = _playerRecentAssessments[playerId] ?? [];
    return assessments.take(limit).toList();
  }
  
  // Fetch methods
  Future<AssessmentResults?> fetchPlayerAssessmentResults(String playerId) async {
    if (authToken == null) return null;
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/player/$playerId/results'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = AssessmentResults.fromJson(data);
        
        // Cache the results
        _playerAssessmentResults[playerId] = results;
        
        notifyListeners();
        return results;
      }
      return null;
    } catch (e) {
      print('Fetch player assessment results error: $e');
      return null;
    }
  }
  
  Future<List<TestResult>> fetchPlayerTestResults(String playerId) async {
    if (authToken == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/player/$playerId/test-results'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final results = data.map((item) => TestResult.fromJson(item)).toList();
        
        // Cache the results
        _playerTestResults[playerId] = results;
        
        notifyListeners();
        return results;
      }
      return [];
    } catch (e) {
      print('Fetch player test results error: $e');
      return [];
    }
  }
  
  Future<List<dynamic>> fetchRecentAssessments(String playerId, {int limit = 5}) async {
    if (authToken == null) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/analytics/player/$playerId/recent-assessments?limit=$limit'),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Cache the results
        _playerRecentAssessments[playerId] = data;
        
        notifyListeners();
        return data;
      }
      return [];
    } catch (e) {
      print('Fetch recent assessments error: $e');
      return [];
    }
  }
  
  // Method to clear cache
  void clearCache() {
    _playerAssessmentResults.clear();
    _playerTestResults.clear();
    _playerRecentAssessments.clear();
    notifyListeners();
  }
  
  // Helper method to determine if a player has assessment data
  bool hasPlayerAssessmentData(String playerId) {
    return _playerAssessmentResults.containsKey(playerId) ||
           _playerTestResults.containsKey(playerId);
  }
}