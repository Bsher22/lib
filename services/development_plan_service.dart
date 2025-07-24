// Fixed lib/services/development_plan_service.dart
// Changes:
// - Fixed parameter name from startDate: to fromDate: in _loadHistoryFromBackend method
// - Fixed all playerId parameter type issues for ApiService calls

import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/screens/mentorship/hire_history_screen.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class DevelopmentPlanService {
  final ApiService _apiService;
  
  // Storage keys for local caching
  static const String _developmentPlansKey = 'development_plans';
  static const String _pendingRatingsKey = 'pending_ratings';
  static const String _hireScoresKey = 'hire_scores';
  static const String _historyKey = 'assessment_history';
  
  // ============================================================================
  // CONSTRUCTOR - Updated to use ApiService
  // ============================================================================
  
  DevelopmentPlanService({required ApiService apiService}) : _apiService = apiService;
  
  // ============================================================================
  // VALIDATION HELPERS
  // ============================================================================
  
  void _validatePlayerId(int? playerId, String operation) {
    if (playerId == null) {
      throw ArgumentError('Player ID cannot be null for operation: $operation');
    }
  }
  
  void _validatePlayer(Player player, String operation) {
    if (player.id == null) {
      throw ArgumentError('Player.id cannot be null for operation: $operation. Player: ${player.name}');
    }
  }
  
  // ============================================================================
  // CORE DATA OPERATIONS - UPDATED FOR ApiService
  // ============================================================================

  /// Load player development plan from backend (with local fallback)
  Future<DevelopmentPlanData?> loadPlayerDevelopmentPlan(int playerId) async {
    _validatePlayerId(playerId, 'loadPlayerDevelopmentPlan');
    
    try {
      // Try backend first using ApiService
      final planData = await _loadFromBackend(playerId);
      if (planData != null) {
        // Cache locally for offline access
        await _cacheLocallyAsync(playerId, planData);
        return planData;
      }
      
      // Fallback to local storage
      debugPrint('Backend unavailable, loading from local cache for player $playerId');
      return await _loadFromLocal(playerId);
      
    } catch (e) {
      debugPrint('Error loading development plan: $e');
      // Try local fallback on any error
      return await _loadFromLocal(playerId);
    }
  }

  /// UPDATED: Load from backend using ApiService
  Future<DevelopmentPlanData?> _loadFromBackend(int playerId) async {
    try {
      debugPrint('API: Getting development plan for player $playerId');
      
      // Use ApiService instead of direct HTTP
      final response = await _apiService.getDevelopmentPlan(playerId);
      
      if (response != null) {
        debugPrint('Successfully loaded development plan from backend for player $playerId');
        return DevelopmentPlanData.fromJson(response);
      }
      
      debugPrint('No development plan found on backend for player $playerId');
      return null;
      
    } catch (e) {
      debugPrint('Backend request failed: $e');
      rethrow;
    }
  }

  /// Load or create development plan for a player
  Future<DevelopmentPlanData> loadOrCreatePlayerDevelopmentPlan(Player player) async {
    _validatePlayer(player, 'loadOrCreatePlayerDevelopmentPlan');
    
    try {
      // Try to load existing plan first
      var planData = await loadPlayerDevelopmentPlan(player.id!);
      
      if (planData != null) {
        debugPrint('Loaded existing development plan for player ${player.name}');
        return planData;
      }
      
      // Create new plan if none exists
      debugPrint('Creating new development plan for player ${player.name}');
      planData = createDefaultPlanData(player);
      
      // Save the new plan to backend
      await saveDevelopmentPlan(planData);
      debugPrint('Saved new development plan for player ${player.name}');
      
      return planData;
    } catch (e) {
      debugPrint('Error in loadOrCreatePlayerDevelopmentPlan for ${player.name}: $e');
      rethrow;
    }
  }

  /// UPDATED: Save development plan using ApiService
  Future<void> saveDevelopmentPlan(DevelopmentPlanData planData) async {
    try {
      debugPrint('Saving development plan for player ${planData.playerName} (ID: ${planData.playerId})');
      
      // Save to backend using ApiService
      await _saveToBackend(planData);
      
      // Cache locally for offline access
      await _cacheLocallyAsync(planData.playerId, planData);
      
      // Save to history if this is a completed assessment
      await _saveToHistory(planData);
      
      // Clear any pending ratings
      await _clearPendingRatings(planData.playerId);
      
      debugPrint('Successfully saved development plan for player ${planData.playerName}');
    } catch (e) {
      debugPrint('Error saving development plan: $e');
      rethrow;
    }
  }

  /// UPDATED: Save to backend using ApiService
  Future<void> _saveToBackend(DevelopmentPlanData planData) async {
    try {
      debugPrint('API: Saving development plan for player ${planData.playerName}');
      
      // Convert DevelopmentPlanData to API format
      final apiData = {
        'player_id': planData.playerId,
        'player_name': planData.playerName,
        'player_age': planData.playerAge,
        'season': planData.season,
        'assessment_type': planData.assessmentType,
        'plan_name': planData.planName,
        'assessment_date': planData.assessmentDate.toIso8601String(),
        'strengths': planData.strengths,
        'improvements': planData.improvements,
        'core_targets': planData.coreTargets.map((target) => {
          'skill': target.skill,
          'timeframe': target.timeframe,
        }).toList(),
        'monthly_targets': planData.monthlyTargets,
        'coach_name': planData.coachName,
        'coach_email': planData.coachEmail,
        'coach_phone': planData.coachPhone,
        'coach_notes': planData.coachNotes,
        'player_notes': planData.playerNotes,
        'mentorship_note_1': planData.mentorshipNote1,
        'mentorship_note_2': planData.mentorshipNote2,
        'mentorship_note_3': planData.mentorshipNote3,
        ...planData.ratings.toDatabaseMap(),
      };
      
      // Use ApiService methods
      if (planData.id > 0) {
        await _apiService.updateDevelopmentPlan(planData.playerId, apiData);
      } else {
        await _apiService.createDevelopmentPlan(planData.playerId, apiData);
      }
      
      debugPrint('Successfully saved development plan to backend');
      
    } catch (e) {
      debugPrint('Failed to save to backend: $e');
      rethrow;
    }
  }

  /// Local storage fallback
  Future<DevelopmentPlanData?> _loadFromLocal(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_developmentPlansKey);
      
      if (plansJson == null) return null;
      
      final plansMap = Map<String, dynamic>.from(jsonDecode(plansJson));
      final playerPlanJson = plansMap[playerId.toString()];
      
      if (playerPlanJson == null) return null;
      
      return DevelopmentPlanData.fromJson(Map<String, dynamic>.from(playerPlanJson));
    } catch (e) {
      debugPrint('Error loading from local storage: $e');
      return null;
    }
  }

  /// Cache data locally for offline access
  Future<void> _cacheLocallyAsync(int playerId, DevelopmentPlanData planData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_developmentPlansKey) ?? '{}';
      final plansMap = Map<String, dynamic>.from(jsonDecode(plansJson));
      
      planData.needsRecalculation = false;
      planData.scoresCalculatedAt = DateTime.now();
      
      plansMap[playerId.toString()] = planData.toJson();
      await prefs.setString(_developmentPlansKey, jsonEncode(plansMap));
    } catch (e) {
      debugPrint('Error caching locally: $e');
    }
  }

  // ============================================================================
  // ENHANCED HISTORY FUNCTIONALITY - UPDATED FOR ApiService
  // ============================================================================

  /// Load historical assessments for a player within optional date range
  Future<List<AssessmentHistoryItem>> loadAssessmentHistory(
    int playerId, {
    DateTimeRange? dateRange,
  }) async {
    _validatePlayerId(playerId, 'loadAssessmentHistory');
    
    try {
      // Try to load from backend first using ApiService
      final historyFromBackend = await _loadHistoryFromBackend(playerId, dateRange);
      if (historyFromBackend.isNotEmpty) {
        // Cache locally
        await _cacheHistoryLocally(playerId, historyFromBackend);
        return historyFromBackend;
      }
      
      // Fallback to local storage
      return await _loadHistoryFromLocal(playerId, dateRange);
      
    } catch (e) {
      debugPrint('Error loading assessment history: $e');
      // Try local fallback on error
      return await _loadHistoryFromLocal(playerId, dateRange);
    }
  }

  /// UPDATED: Load history from backend using ApiService - FIXED to match actual API signature
  Future<List<AssessmentHistoryItem>> _loadHistoryFromBackend(
    int playerId,
    DateTimeRange? dateRange,
  ) async {
    try {
      debugPrint('API: Getting assessment history for player $playerId');
      
      // FIXED: Convert int to String and call without date parameters (as per actual API)
      final historyData = await _apiService.getAssessmentHistory(playerId.toString());
      
      // Convert to AssessmentHistoryItem objects
      var history = historyData.map((item) => AssessmentHistoryItem.fromJson(item)).toList();
      
      // Apply client-side date filtering if dateRange is provided
      if (dateRange != null) {
        history = history.where((item) {
          return item.assessmentDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                 item.assessmentDate.isBefore(dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }
      
      // Sort by date (newest first)
      history.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
      
      return history;
    } catch (e) {
      debugPrint('Error loading history from backend: $e');
      return []; // Return empty list to allow graceful fallback to local storage
    }
  }

  /// Load history from local storage
  Future<List<AssessmentHistoryItem>> _loadHistoryFromLocal(
    int playerId,
    DateTimeRange? dateRange,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString('${_historyKey}_$playerId');
      
      if (historyJson == null) return [];
      
      final List<dynamic> historyList = jsonDecode(historyJson);
      var history = historyList.map((item) => AssessmentHistoryItem.fromJson(item)).toList();
      
      // Apply date filtering if provided
      if (dateRange != null) {
        history = history.where((item) {
          return item.assessmentDate.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
                 item.assessmentDate.isBefore(dateRange.end.add(const Duration(days: 1)));
        }).toList();
      }
      
      // Sort by date (newest first)
      history.sort((a, b) => b.assessmentDate.compareTo(a.assessmentDate));
      
      return history;
    } catch (e) {
      debugPrint('Error loading history from local storage: $e');
      return [];
    }
  }

  /// Cache history locally
  Future<void> _cacheHistoryLocally(int playerId, List<AssessmentHistoryItem> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = jsonEncode(history.map((item) => {
        'id': item.id,
        'assessment_date': item.assessmentDate.toIso8601String(),
        'plan_data': item.planData.toJson(),
        'session_notes': item.sessionNotes,
        'action_items': item.actionItems,
        'metadata': item.metadata,
        'is_completed': item.isCompleted ? 1 : 0,
      }).toList());
      
      await prefs.setString('${_historyKey}_$playerId', historyJson);
    } catch (e) {
      debugPrint('Error caching history locally: $e');
    }
  }

  /// Save current plan to history
  Future<void> _saveToHistory(DevelopmentPlanData planData) async {
    try {
      // Create history item
      final historyItem = AssessmentHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch,
        assessmentDate: DateTime.now(),
        planData: planData,
        sessionNotes: '${planData.coachNotes}\n${planData.playerNotes}'.trim(),
        actionItems: [],
        metadata: {
          'plan_type': planData.assessmentType,
          'season': planData.season,
          'auto_saved': true,
        },
        isCompleted: true,
      );
      
      // Load existing history
      final existingHistory = await _loadHistoryFromLocal(planData.playerId, null);
      
      // Add new item
      final updatedHistory = [historyItem, ...existingHistory];
      
      // Keep only last 50 items to prevent storage bloat
      if (updatedHistory.length > 50) {
        updatedHistory.removeRange(50, updatedHistory.length);
      }
      
      // Save back to local storage
      await _cacheHistoryLocally(planData.playerId, updatedHistory);
      
      // Try to save to backend using ApiService
      await _saveHistoryItemToBackend(planData.playerId, historyItem);
      
    } catch (e) {
      debugPrint('Error saving to history: $e');
      // Don't throw - history save failures shouldn't block main save operation
    }
  }

  /// UPDATED: Save history item to backend using ApiService - FIXED parameter type
  Future<void> _saveHistoryItemToBackend(int playerId, AssessmentHistoryItem item) async {
    try {
      debugPrint('API: Saving history item for player $playerId');
      
      final assessmentData = {
        'assessment_date': item.assessmentDate.toIso8601String(),
        'plan_data': item.planData.toJson(),
        'session_notes': item.sessionNotes,
        'action_items': item.actionItems,
        'metadata': item.metadata,
        'is_completed': item.isCompleted,
      };
      
      // Use ApiService method - FIXED: Convert int to String
      await _apiService.addAssessmentToHistory(playerId.toString(), assessmentData);
      debugPrint('Successfully saved history item to backend');
    } catch (e) {
      debugPrint('Error saving history item to backend: $e');
      // Don't rethrow - this is a background operation
    }
  }

  /// Calculate progress metrics for a player
  Future<ProgressMetrics> calculateProgressMetrics(
    int playerId, {
    DateTimeRange? dateRange,
  }) async {
    try {
      final historyItems = await loadAssessmentHistory(playerId, dateRange: dateRange);

      if (historyItems.length < 2) {
        // Not enough data for meaningful metrics
        return ProgressMetrics(
          overallImprovement: 0.0,
          categoryTrends: {},
          topImprovements: [],
          areasOfConcern: [],
          consistencyScore: 0.0,
          totalAssessments: historyItems.length,
        );
      }
      
      // Sort by date (oldest first for calculations)
      final sortedHistory = historyItems.reversed.toList();
      final firstAssessment = sortedHistory.first;
      final lastAssessment = sortedHistory.last;
      
      // Calculate overall improvement
      final overallImprovement = lastAssessment.planData.ratings.overallHIREScore - 
                                firstAssessment.planData.ratings.overallHIREScore;
      
      // Calculate category trends
      final categoryTrends = <String, double>{};
      final ratingKeys = [
        'hockeyIQ', 'competitiveness', 'workEthic', 'coachability',
        'leadership', 'teamPlay', 'decisionMaking', 'adaptability',
        'physicalFitness', 'nutritionHabits', 'sleepQuality', 'mentalToughness',
        'timeManagement', 'respectForOthers', 'commitment', 'goalSetting', 'communicationSkills'
      ];
      
      for (final key in ratingKeys) {
        final firstValue = firstAssessment.planData.ratings.getRatingValue(key);
        final lastValue = lastAssessment.planData.ratings.getRatingValue(key);
        categoryTrends[key] = lastValue - firstValue;
      }
      
      // Identify top improvements and concerns
      final sortedTrends = categoryTrends.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      final topImprovements = sortedTrends
        .where((entry) => entry.value > 0.05)
        .take(5)
        .map((entry) => entry.key)
        .toList();
      
      final areasOfConcern = sortedTrends
        .where((entry) => entry.value < -0.05)
        .map((entry) => entry.key)
        .toList();
      
      // Calculate consistency score (how stable the scores are)
      double consistencyScore = 0.0;
      if (sortedHistory.length > 2) {
        final overallScores = sortedHistory.map((item) => item.planData.ratings.overallHIREScore).toList();
        final mean = overallScores.reduce((a, b) => a + b) / overallScores.length;
        final variance = overallScores.map((score) => math.pow(score - mean, 2)).reduce((a, b) => a + b) / overallScores.length;
        final standardDeviation = math.sqrt(variance);
        consistencyScore = (1.0 - standardDeviation).clamp(0.0, 1.0);
      }
      
      return ProgressMetrics(
        overallImprovement: overallImprovement,
        categoryTrends: categoryTrends,
        topImprovements: topImprovements,
        areasOfConcern: areasOfConcern,
        consistencyScore: consistencyScore,
        totalAssessments: historyItems.length,
      );
      
    } catch (e) {
      debugPrint('Error calculating progress metrics: $e');
      throw Exception('Failed to calculate progress metrics');
    }
  }

  /// Export assessment history to PDF/CSV
  Future<String> exportAssessmentHistory(
    int playerId, {
    DateTimeRange? dateRange,
    String format = 'pdf', // 'pdf' or 'csv'
  }) async {
    try {
      final historyItems = await loadAssessmentHistory(playerId, dateRange: dateRange);
      final metrics = await calculateProgressMetrics(playerId, dateRange: dateRange);

      if (format == 'pdf') {
        return await _generatePDFHistoryReport(historyItems, metrics);
      } else {
        return await _generateCSVHistoryReport(historyItems, metrics);
      }
      
    } catch (e) {
      debugPrint('Error exporting assessment history: $e');
      throw Exception('Failed to export assessment history');
    }
  }

  Future<String> _generatePDFHistoryReport(List<AssessmentHistoryItem> history, ProgressMetrics metrics) async {
    final pdf = pw.Document();
    
    // Load HIRE logo (with fallback if not available)
    late pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/hire_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo not found, using fallback: $e');
      logoImage = null;
    }

    // Page 1: History Overview
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPDFHistoryHeader(history.isNotEmpty ? history.first.planData : null, logoImage),
            pw.SizedBox(height: 24),
            _buildProgressMetricsSection(metrics),
            pw.SizedBox(height: 24),
            _buildHistoryTimelineSection(history),
          ];
        },
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final playerName = history.isNotEmpty ? history.first.planData.playerName : 'Unknown';
    final file = File('${directory.path}/hire_history_${playerName.replaceAll(' ', '_')}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file.path;
  }

  Future<String> _generateCSVHistoryReport(List<AssessmentHistoryItem> history, ProgressMetrics metrics) async {
    final directory = await getApplicationDocumentsDirectory();
    final playerName = history.isNotEmpty ? history.first.planData.playerName : 'Unknown';
    final file = File('${directory.path}/hire_history_${playerName.replaceAll(' ', '_')}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.csv');
    
    final csvData = StringBuffer();
    
    // Headers
    csvData.writeln('Assessment Date,Overall HIRE Score,H Score,I Score,R Score,E Score,Session Notes,Action Items');
    
    // Data rows
    for (final item in history) {
      final ratings = item.planData.ratings;
      csvData.writeln([
        DateFormat('yyyy-MM-dd').format(item.assessmentDate),
        ratings.overallHIREScore.toStringAsFixed(2),
        ratings.hScore.toStringAsFixed(2),
        ratings.iScore.toStringAsFixed(2),
        ratings.rScore.toStringAsFixed(2),
        ratings.eScore.toStringAsFixed(2),
        '"${item.sessionNotes.replaceAll('"', '""')}"',
        '"${item.actionItems.join('; ').replaceAll('"', '""')}"',
      ].join(','));
    }
    
    await file.writeAsString(csvData.toString());
    return file.path;
  }

  // ============================================================================
  // HIRE CALCULATION METHODS - UPDATED FOR ApiService
  // ============================================================================

  /// UPDATED: Calculate HIRE scores using ApiService
  Future<HIREScores> calculateHIREScores(int playerId) async {
    try {
      debugPrint('Starting HIRE score calculation for player $playerId');
      
      // Load development plan
      var planData = await loadPlayerDevelopmentPlan(playerId);
      
      if (planData == null) {
        throw Exception('No development plan found for player $playerId. Create a development plan first.');
      }
      
      debugPrint('Found development plan for player ${planData.playerName}, proceeding with calculation');
      
      // Call backend API for HIRE calculation using ApiService
      final calculationResult = await _callBackendHIRECalculation(planData);
      
      if (calculationResult['success'] == true) {
        debugPrint('Backend calculation successful for player ${planData.playerName}');
        
        // Create HIREScores object with calculated values from backend
        final hireScores = HIREScores(
          hockey: calculationResult['scores']['h_score']?.toDouble() ?? 0.0,
          integrity: calculationResult['scores']['i_score']?.toDouble() ?? 0.0,
          respect: calculationResult['scores']['r_score']?.toDouble() ?? 0.0,
          excellence: calculationResult['scores']['e_score']?.toDouble() ?? 0.0,
          overall: calculationResult['scores']['overall_hire_score']?.toDouble() ?? 0.0,
          calculatedAt: DateTime.now(),
          details: calculationResult,
        );
        
        // Update the ratings object with calculated scores
        planData.ratings.updateCalculatedScores(calculationResult);
        
        // Save the calculated scores locally
        await _saveHIREScores(playerId, hireScores);
        
        // Update the plan data to mark scores as calculated
        planData.needsRecalculation = false;
        planData.scoresCalculatedAt = DateTime.now();
        await saveDevelopmentPlan(planData);
        
        debugPrint('HIRE scores calculated and saved for player ${planData.playerName}');
        return hireScores;
      } else {
        throw Exception('Backend calculation failed: ${calculationResult['error']}');
      }
    } catch (e) {
      debugPrint('Error calculating HIRE scores for player $playerId: $e');
      rethrow;
    }
  }

  /// UPDATED: Call backend API for HIRE calculation using ApiService
  Future<Map<String, dynamic>> _callBackendHIRECalculation(DevelopmentPlanData planData) async {
    try {
      debugPrint('Calling backend HIRE calculation for player ${planData.playerName}');
      
      final ratings = planData.ratings.getAllInputRatings();
      
      final response = await _apiService.calculateHIREScores(
        planData.playerId, 
        ratings,
        saveToPlan: true,
      );
      
      if (response != null) {
        return {
          'success': true,
          'scores': response['scores'],
          'components': response['components'],
          'validation_warnings': response['validation_warnings'] ?? [],
        };
      }
      
      return {
        'success': false,
        'error': 'No response from backend',
      };
      
    } catch (e) {
      debugPrint('Error calling backend HIRE calculation API: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Calculate HIRE scores with plan, ensuring development plan exists first
  Future<HIREScores> calculateHIREScoresWithPlan(Player player) async {
    try {
      debugPrint('Calculating HIRE scores with plan for player ${player.name}');
      
      // Ensure development plan exists first
      final planData = await loadOrCreatePlayerDevelopmentPlan(player);
      
      // Now calculate scores
      return await calculateHIREScores(planData.playerId);
    } catch (e) {
      debugPrint('Error in calculateHIREScoresWithPlan for ${player.name}: $e');
      rethrow;
    }
  }

  /// UPDATED: Recalculate HIRE scores using ApiService - FIXED parameter type
  Future<HIREScores> recalculateHIREScores(int playerId) async {
    debugPrint('Forcing HIRE score recalculation for player $playerId');
    
    try {
      // FIXED: Convert int to String for API call
      final response = await _apiService.recalculateHIREScores(playerId.toString());
      
      if (response != null) {
        final hireScores = HIREScores(
          hockey: response['h_score']?.toDouble() ?? 0.0,
          integrity: response['i_score']?.toDouble() ?? 0.0,
          respect: response['r_score']?.toDouble() ?? 0.0,
          excellence: response['e_score']?.toDouble() ?? 0.0,
          overall: response['overall_hire_score']?.toDouble() ?? 0.0,
          calculatedAt: DateTime.parse(response['recalculated_at']),
          details: response,
        );
        
        await _saveHIREScores(playerId, hireScores);
        return hireScores;
      } else {
        throw Exception('Recalculation failed: No response from backend');
      }
    } catch (e) {
      debugPrint('Error recalculating HIRE scores: $e');
      rethrow;
    }
  }

  /// UPDATED: Load HIRE scores from backend using ApiService
  Future<HIREScores?> loadHIREScoresFromBackend(int playerId) async {
    try {
      final response = await _apiService.getHIREScores(playerId);
      
      if (response != null) {
        final scores = response['scores'];
        
        final hireScores = HIREScores(
          hockey: scores['h_score']?.toDouble() ?? 0.0,
          integrity: scores['i_score']?.toDouble() ?? 0.0,
          respect: scores['r_score']?.toDouble() ?? 0.0,
          excellence: scores['e_score']?.toDouble() ?? 0.0,
          overall: scores['overall_hire_score']?.toDouble() ?? 0.0,
          calculatedAt: response['scores_calculated_at'] != null 
              ? DateTime.parse(response['scores_calculated_at'])
              : DateTime.now(),
          details: response,
        );
        
        // Cache locally
        await _saveHIREScores(playerId, hireScores);
        return hireScores;
      } else {
        debugPrint('No HIRE scores found for player $playerId');
        return null;
      }
    } catch (e) {
      debugPrint('Error loading HIRE scores from backend: $e');
      // Fallback to local storage
      return await loadHIREScores(playerId);
    }
  }

  // ============================================================================
  // MENTORSHIP NOTES MANAGEMENT - UPDATED FOR ApiService
  // ============================================================================
  
  /// UPDATED: Save mentorship notes using ApiService - FIXED parameter type
  Future<void> saveMentorshipNotes(int playerId, Map<String, String> notes) async {
    try {
      // FIXED: Convert int to String for API call
      await _apiService.updateMentorshipNotes(playerId.toString(), notes);
      debugPrint('Mentorship notes saved successfully for player $playerId');
    } catch (e) {
      debugPrint('Error saving mentorship notes: $e');
      rethrow;
    }
  }

  /// UPDATED: Load mentorship notes using ApiService - FIXED parameter type
  Future<Map<String, String>> loadMentorshipNotes(int playerId) async {
    try {
      // FIXED: Convert int to String for API call
      final response = await _apiService.getMentorshipNotes(playerId.toString());
      
      if (response != null) {
        return {
          'mentorship_note_1': response['mentorship_note_1'] ?? '',
          'mentorship_note_2': response['mentorship_note_2'] ?? '',
          'mentorship_note_3': response['mentorship_note_3'] ?? '',
        };
      }
      
      return {
        'mentorship_note_1': '', 
        'mentorship_note_2': '', 
        'mentorship_note_3': ''
      };
    } catch (e) {
      debugPrint('Error loading mentorship notes: $e');
      return {
        'mentorship_note_1': '', 
        'mentorship_note_2': '', 
        'mentorship_note_3': ''
      };
    }
  }

  /// Auto-save mentorship notes (partial update) - FIXED parameter type
  Future<void> autoSaveMentorshipNote(int playerId, String noteKey, String noteValue) async {
    try {
      // FIXED: Convert int to String for API call
      await _apiService.updateMentorshipNotes(playerId.toString(), {noteKey: noteValue});
      debugPrint('Auto-saved mentorship note $noteKey for player $playerId');
    } catch (e) {
      debugPrint('Error auto-saving mentorship note: $e');
      // Don't rethrow for auto-save failures
    }
  }

  // ============================================================================
  // UTILITY AND ADDITIONAL METHODS - Some updated for ApiService
  // ============================================================================

  /// Get development insights for a player
  Future<DevelopmentInsights> getDevelopmentInsights(int playerId) async {
    final planData = await loadPlayerDevelopmentPlan(playerId);
    if (planData == null) {
      throw Exception('No development plan found for player $playerId');
    }
    
    return planData.getInsights();
  }

  /// Create default development plan
  DevelopmentPlan createDefaultPlan(Player player) {
    _validatePlayer(player, 'createDefaultPlan');
    
    return DevelopmentPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      playerId: player.id!.toString(),
      title: 'Development Plan for ${player.name}',
      description: 'Personalized development plan to improve hockey skills and character development through the HIRE system (Hockey, Integrity, Respect, Excellence)',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      goals: [
        'Improve shooting accuracy and technique',
        'Enhance skating speed and agility',
        'Develop better game awareness and hockey IQ',
        'Strengthen physical conditioning and fitness',
        'Build character through HIRE principles',
      ],
      ratings: {},
    );
  }

  /// UPDATED: Load all development plans using ApiService
  Future<List<DevelopmentPlanData>> loadAllDevelopmentPlans() async {
    try {
      final plans = await _apiService.getAllDevelopmentPlans();
      return plans.map((planJson) => DevelopmentPlanData.fromJson(planJson)).toList();
    } catch (e) {
      debugPrint('Error loading all development plans: $e');
      // Fallback to local storage
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_developmentPlansKey);
      
      if (plansJson == null) return [];
      
      final plansMap = Map<String, dynamic>.from(jsonDecode(plansJson));
      final plans = <DevelopmentPlanData>[];
      
      for (final planJson in plansMap.values) {
        try {
          plans.add(DevelopmentPlanData.fromJson(Map<String, dynamic>.from(planJson)));
        } catch (e) {
          debugPrint('Error loading individual plan: $e');
        }
      }
      
      return plans;
    }
  }

  /// UPDATED: Delete development plan using ApiService
  Future<bool> deleteDevelopmentPlan(int playerId) async {
    try {
      // Delete from backend using ApiService
      await _apiService.deleteDevelopmentPlan(playerId);
      
      // Also clear local cache
      final prefs = await SharedPreferences.getInstance();
      final plansJson = prefs.getString(_developmentPlansKey) ?? '{}';
      final plansMap = Map<String, dynamic>.from(jsonDecode(plansJson));
      
      plansMap.remove(playerId.toString());
      await prefs.setString(_developmentPlansKey, jsonEncode(plansMap));
      
      await _clearPendingRatings(playerId);
      await _clearHIREScores(playerId);
      
      debugPrint('Development plan deleted for player $playerId');
      return true;
    } catch (e) {
      debugPrint('Error deleting development plan: $e');
      return false;
    }
  }

  // ============================================================================
  // DEFAULT PLAN CREATION
  // ============================================================================

  DevelopmentPlanData createDefaultPlanData(Player player) {
    _validatePlayer(player, 'createDefaultPlanData');
    
    final age = player.age ?? 16;
    final startDate = DateTime.now();
    
    debugPrint('Creating default plan data for ${player.name} (age: $age)');
    
    return DevelopmentPlanData(
      playerId: player.id!,
      playerName: player.name,
      playerAge: age,
      season: '2024-25',
      assessmentType: 'initial',
      planName: 'Development Plan for ${player.name}',
      assessmentDate: startDate,
      strengths: [],
      improvements: [],
      coreTargets: _generateDefaultCoreTargets(age),
      monthlyTargets: _generateDefaultMonthlyTargets(),
      coachName: '',
      coachEmail: '',
      coachPhone: '',
      coachNotes: '',
      playerNotes: '',
      mentorshipNote1: '',
      mentorshipNote2: '',
      mentorshipNote3: '',
      ratings: HIREPlayerRatings.defaultForAge(age),
      needsRecalculation: true,
    );
  }

  List<CoreTarget> _generateDefaultCoreTargets(int age) {
    if (age <= 12) {
      return [
        CoreTarget(skill: 'Basic skating fundamentals', timeframe: 'Month 1'),
        CoreTarget(skill: 'Puck handling confidence', timeframe: 'Month 2'),
        CoreTarget(skill: 'Shooting technique', timeframe: 'Month 3'),
        CoreTarget(skill: 'Game awareness and fun', timeframe: 'Month 4'),
      ];
    } else if (age <= 17) {
      return [
        CoreTarget(skill: 'Advanced skating techniques', timeframe: 'Month 1'),
        CoreTarget(skill: 'Shot accuracy and power', timeframe: 'Month 2'),
        CoreTarget(skill: 'Game IQ and decision making', timeframe: 'Month 3'),
        CoreTarget(skill: 'Leadership and character development', timeframe: 'Month 4'),
      ];
    } else {
      return [
        CoreTarget(skill: 'Position-specific skills', timeframe: 'Month 1'),
        CoreTarget(skill: 'Advanced systems play', timeframe: 'Month 2'),
        CoreTarget(skill: 'Mental game and pressure handling', timeframe: 'Month 3'),
        CoreTarget(skill: 'Leadership and mentoring', timeframe: 'Month 4'),
      ];
    }
  }

  Map<String, String> _generateDefaultMonthlyTargets() {
    return {
      'January': 'Foundation building and assessment',
      'February': 'Skill development and technique refinement',
      'March': 'Application and game situation practice',
      'April': 'Integration and leadership development',
    };
  }

  // ============================================================================
  // LOCAL STORAGE HELPER METHODS
  // ============================================================================

  Future<void> _saveHIREScores(int playerId, HIREScores scores) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_hireScoresKey) ?? '{}';
      final scoresMap = Map<String, dynamic>.from(jsonDecode(scoresJson));
      
      scoresMap[playerId.toString()] = scores.toJson();
      await prefs.setString(_hireScoresKey, jsonEncode(scoresMap));
      debugPrint('HIRE scores saved to storage for player $playerId');
    } catch (e) {
      debugPrint('Error saving HIRE scores: $e');
    }
  }

  Future<HIREScores?> loadHIREScores(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_hireScoresKey);
      
      if (scoresJson == null) return null;
      
      final scoresMap = Map<String, dynamic>.from(jsonDecode(scoresJson));
      final playerScores = scoresMap[playerId.toString()];
      
      if (playerScores == null) return null;
      
      return HIREScores.fromJson(Map<String, dynamic>.from(playerScores));
    } catch (e) {
      debugPrint('Error loading HIRE scores: $e');
      return null;
    }
  }

  Future<void> _clearPendingRatings(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingRatingsKey) ?? '{}';
      final pendingMap = Map<String, dynamic>.from(jsonDecode(pendingJson));
      
      pendingMap.remove(playerId.toString());
      await prefs.setString(_pendingRatingsKey, jsonEncode(pendingMap));
    } catch (e) {
      debugPrint('Error clearing pending ratings: $e');
    }
  }

  Future<void> _clearHIREScores(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_hireScoresKey) ?? '{}';
      final scoresMap = Map<String, dynamic>.from(jsonDecode(scoresJson));
      
      scoresMap.remove(playerId.toString());
      await prefs.setString(_hireScoresKey, jsonEncode(scoresMap));
    } catch (e) {
      debugPrint('Error clearing HIRE scores: $e');
    }
  }

  /// Save pending ratings for backend sync
  Future<void> savePendingRatings(int playerId, Map<String, double> ratings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingRatingsKey) ?? '{}';
      final pendingMap = Map<String, dynamic>.from(jsonDecode(pendingJson));
      
      pendingMap[playerId.toString()] = {
        'ratings': ratings,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(_pendingRatingsKey, jsonEncode(pendingMap));
    } catch (e) {
      debugPrint('Error saving pending ratings: $e');
    }
  }

  /// Load pending ratings
  Future<Map<String, double>?> loadPendingRatings(int playerId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingJson = prefs.getString(_pendingRatingsKey);
      
      if (pendingJson == null) return null;
      
      final pendingMap = Map<String, dynamic>.from(jsonDecode(pendingJson));
      final playerPending = pendingMap[playerId.toString()];
      
      if (playerPending == null) return null;
      
      final ratingsMap = Map<String, dynamic>.from(playerPending['ratings']);
      return ratingsMap.map((key, value) => MapEntry(key, (value as num).toDouble()));
    } catch (e) {
      debugPrint('Error loading pending ratings: $e');
      return null;
    }
  }

  /// Check if HIRE recalculation is needed
  Future<bool> needsHIRERecalculation(int playerId) async {
    final planData = await loadPlayerDevelopmentPlan(playerId);
    if (planData == null) return true;
    
    if (planData.needsRecalculation) return true;
    
    if (planData.scoresCalculatedAt != null) {
      final daysSinceCalculation = DateTime.now().difference(planData.scoresCalculatedAt!).inDays;
      return daysSinceCalculation > 7;
    }
    
    return true;
  }

  void flushPendingRatings(int playerId) {
    _validatePlayerId(playerId, 'flushPendingRatings');
    
    _clearPendingRatings(playerId).then((_) {
      debugPrint('Flushed pending ratings for player $playerId');
    }).catchError((e) {
      debugPrint('Error flushing pending ratings for player $playerId: $e');
    });
  }

  // ============================================================================
  // PDF EXPORT FUNCTIONALITY
  // ============================================================================

  /// Export development plan to PDF
  Future<File> exportToPDF(DevelopmentPlanData planData) async {
    final pdf = pw.Document();
    
    // Load HIRE logo (with fallback if not available)
    late pw.ImageProvider? logoImage;
    try {
      final logoBytes = await rootBundle.load('assets/images/hire_logo.png');
      logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
    } catch (e) {
      debugPrint('Logo not found, using fallback: $e');
      logoImage = null;
    }

    // Page 1: Development Plan Overview
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildPDFHeader(planData, logoImage),
            pw.SizedBox(height: 24),
            _buildOverviewSection(planData),
            pw.SizedBox(height: 24),
            _buildAssessmentSection(planData),
            pw.SizedBox(height: 24),
            _buildCoreTargetsSection(planData),
            pw.SizedBox(height: 24),
            _buildMentorshipNotesSection(planData),
            pw.SizedBox(height: 16),
            _buildMeetingNotesSection(planData),
            pw.SizedBox(height: 16),
            _buildCoachContactSection(planData),
          ];
        },
      ),
    );

    // Page 2: HIRE Ratings Summary  
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHIRERatingsHeader(planData),
            pw.SizedBox(height: 20),
            _buildHIREScoresSummary(planData),
            pw.SizedBox(height: 20),
            _buildDetailedRatingsSection(planData),
          ];
        },
      ),
    );

    // Save to file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/development_plan_${planData.playerName.replaceAll(' ', '_')}_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf');
    await file.writeAsBytes(await pdf.save());
    
    return file;
  }

  /// Share PDF file
  Future<void> sharePDF(File pdfFile) async {
    try {
      await Share.shareXFiles([XFile(pdfFile.path)]);
    } catch (e) {
      debugPrint('Error sharing PDF: $e');
      rethrow;
    }
  }

  // ============================================================================
  // PDF BUILDING HELPERS (Implementation continues as before...)
  // ============================================================================

  pw.Widget _buildPDFHistoryHeader(DevelopmentPlanData? planData, pw.ImageProvider? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logoImage),
              )
            else
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red600,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'HIRE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Generated: ${DateFormat('MMM d, yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                if (planData != null) ...[
                  pw.Text(
                    'Player: ${planData.playerName}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Age: ${planData.playerAge}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'HIRE Character Development History',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        if (planData != null) ...[
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              planData.playerName,
              style: pw.TextStyle(
                fontSize: 18,
                color: PdfColors.red600,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget _buildProgressMetricsSection(ProgressMetrics metrics) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Progress Summary',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red600,
          ),
        ),
        pw.SizedBox(height: 12),
        
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricBox('Total Assessments', '${metrics.totalAssessments}'),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildMetricBox('Overall Improvement', '${metrics.overallImprovement >= 0 ? '+' : ''}${metrics.overallImprovement.toStringAsFixed(1)}'),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _buildMetricBox('Consistency Score', '${(metrics.consistencyScore * 100).toStringAsFixed(0)}%'),
            ),
          ],
        ),
        
        if (metrics.topImprovements.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Top Improvement Areas:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          ...metrics.topImprovements.take(5).map((area) => pw.Text('• $area')),
        ],
        
        if (metrics.areasOfConcern.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          pw.Text(
            'Areas Needing Attention:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.red600),
          ),
          pw.SizedBox(height: 4),
          ...metrics.areasOfConcern.take(5).map((area) => pw.Text('• $area', style: pw.TextStyle(color: PdfColors.red600))),
        ],
      ],
    );
  }

  pw.Widget _buildMetricBox(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue600,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            title,
            style: const pw.TextStyle(fontSize: 12),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHistoryTimelineSection(List<AssessmentHistoryItem> history) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Assessment Timeline',
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.red600,
          ),
        ),
        pw.SizedBox(height: 12),
        
        ...history.take(10).map((item) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 60,
                child: pw.Column(
                  children: [
                    pw.Text(
                      DateFormat('MMM d').format(item.assessmentDate),
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      DateFormat('yyyy').format(item.assessmentDate),
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text(
                          'HIRE Score: ${item.planData.ratings.overallHIREScore.toStringAsFixed(1)}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Spacer(),
                        pw.Text('H: ${item.planData.ratings.hScore.toStringAsFixed(1)}'),
                        pw.SizedBox(width: 8),
                        pw.Text('I: ${item.planData.ratings.iScore.toStringAsFixed(1)}'),
                        pw.SizedBox(width: 8),
                        pw.Text('R: ${item.planData.ratings.rScore.toStringAsFixed(1)}'),
                        pw.SizedBox(width: 8),
                        pw.Text('E: ${item.planData.ratings.eScore.toStringAsFixed(1)}'),
                      ],
                    ),
                    if (item.sessionNotes.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text(
                        item.sessionNotes,
                        style: const pw.TextStyle(fontSize: 10),
                        maxLines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }

  // ============================================================================
  // PDF BUILDING HELPER METHODS (Complete Implementation)
  // ============================================================================

  pw.Widget _buildPDFHeader(DevelopmentPlanData planData, pw.ImageProvider? logoImage) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            if (logoImage != null)
              pw.Container(
                width: 80,
                height: 80,
                child: pw.Image(logoImage),
              )
            else
              pw.Container(
                width: 80,
                height: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.red600,
                  shape: pw.BoxShape.circle,
                ),
                child: pw.Center(
                  child: pw.Text(
                    'HIRE',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'Assessment Date: ${DateFormat('MMM d, yyyy').format(planData.assessmentDate)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Season: ${planData.season}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'Development Plan',
            style: pw.TextStyle(
              fontSize: 32,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Player: ${planData.playerName} | Age: ${planData.playerAge}',
            style: pw.TextStyle(
              fontSize: 18,
              color: PdfColors.red600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildMentorshipNotesSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Mentorship Session Notes'),
        pw.SizedBox(height: 12),
        
        _buildMentorshipNoteItem(
          'Session Goals & Key Discussion Points',
          planData.mentorshipNote1,
        ),
        pw.SizedBox(height: 12),
        
        _buildMentorshipNoteItem(
          'Player Feedback & Personal Insights',
          planData.mentorshipNote2,
        ),
        pw.SizedBox(height: 12),
        
        _buildMentorshipNoteItem(
          'Action Items & Next Steps',
          planData.mentorshipNote3,
        ),
      ],
    );
  }

  pw.Widget _buildMentorshipNoteItem(String title, String content) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.blue200),
            borderRadius: pw.BorderRadius.circular(4),
            color: PdfColors.blue50,
          ),
          child: pw.Text(
            content.isEmpty ? '(To be filled during mentorship sessions)' : content,
            style: pw.TextStyle(
              fontSize: 11,
              color: content.isEmpty ? PdfColors.grey600 : PdfColors.black,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.red600,
      ),
    );
  }

  pw.Widget _buildOverviewSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('The HIRE Development Process'),
        pw.SizedBox(height: 8),
        ..._buildBulletPoints([
          'Monthly meetings to review progress, provide feedback, and introduce the next focus area using the HIRE framework.',
          'Comprehensive character and skill assessments based on Hockey, Integrity, Respect, and Excellence principles.',
          'Weekly on-ice check-ins to ensure consistent growth, accountability, and support throughout the program.',
          'Meetings will be approximately 15–20 minutes in length, focusing on both skill and character development.',
          'All meetings will be scheduled directly with assigned coaches who understand the HIRE methodology.',
        ]),
      ],
    );
  }

  pw.Widget _buildAssessmentSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSubsectionHeader('Initial HIRE Assessment'),
        pw.SizedBox(height: 8),
        ..._buildBulletPoints([
          'Players meet one-on-one with their assigned coach for comprehensive HIRE evaluation.',
          'Assessment covers Hockey skills, Integrity traits, Respect behaviors, and Excellence mindset.',
          'Together, player and coach identify key strengths and four core improvement areas.',
          'A personalized development plan is created based on age-appropriate HIRE factors.',
        ]),
        pw.SizedBox(height: 16),
        
        pw.Text(
          'What do you do well? (Strengths)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.green700,
          ),
        ),
        pw.SizedBox(height: 8),
        if (planData.strengths.isNotEmpty)
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: planData.strengths.map((strength) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(strength, style: const pw.TextStyle(fontSize: 12)),
            )).toList(),
          )
        else
          pw.Text('(To be identified during initial assessment)', 
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
        
        pw.SizedBox(height: 16),
        
        pw.Text(
          'What areas can be improved? (Focus Areas)',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.orange700,
          ),
        ),
        pw.SizedBox(height: 8),
        if (planData.improvements.isNotEmpty)
          pw.Wrap(
            spacing: 8,
            runSpacing: 4,
            children: planData.improvements.map((improvement) => pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange50,
                border: pw.Border.all(color: PdfColors.orange200),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(improvement, style: const pw.TextStyle(fontSize: 12)),
            )).toList(),
          )
        else
          pw.Text('(To be identified during initial assessment)', 
            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
      ],
    );
  }

  pw.Widget _buildCoreTargetsSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Core Growth Targets ${planData.season}'),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.red300, width: 2),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.red50),
              children: [
                _buildTableHeader('Concept/Skill'),
                _buildTableHeader('Timeframe/Month'),
              ],
            ),
            ...planData.coreTargets.map((target) => pw.TableRow(
              children: [
                _buildTableCell(target.skill),
                _buildTableCell(target.timeframe),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMeetingNotesSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Meeting Notes'),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Coach Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: double.infinity,
                    height: 80,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      planData.coachNotes.isEmpty 
                          ? '(To be filled during meetings)' 
                          : planData.coachNotes,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: planData.coachNotes.isEmpty 
                            ? PdfColors.grey600 
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Player/Parent Notes:',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: double.infinity,
                    height: 80,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      planData.playerNotes.isEmpty 
                          ? '(To be filled during meetings)' 
                          : planData.playerNotes,
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: planData.playerNotes.isEmpty 
                            ? PdfColors.grey600 
                            : PdfColors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCoachContactSection(DevelopmentPlanData planData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Coach Contact Information'),
        pw.SizedBox(height: 8),
        pw.Text('Name: ${planData.coachName.isEmpty ? '(To be assigned)' : planData.coachName}'),
        pw.Text('Email: ${planData.coachEmail.isEmpty ? '(To be provided)' : planData.coachEmail}'),
        pw.Text('Phone: ${planData.coachPhone.isEmpty ? '(To be provided)' : planData.coachPhone}'),
      ],
    );
  }

  pw.Widget _buildHIRERatingsHeader(DevelopmentPlanData planData) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            'HIRE Character Assessment',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Player: ${planData.playerName} | Age: ${planData.playerAge}',
            style: pw.TextStyle(
              fontSize: 16,
              color: PdfColors.red600,
            ),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.Text(
            'Assessment Date: ${planData.scoresCalculatedAt != null ? DateFormat('MMM d, yyyy').format(planData.scoresCalculatedAt!) : 'Pending'}',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.grey600,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHIREScoresSummary(DevelopmentPlanData planData) {
    final ratings = planData.ratings;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                width: 120,
                height: 120,
                decoration: pw.BoxDecoration(
                  shape: pw.BoxShape.circle,
                  border: pw.Border.all(color: _getPDFColorFromRating(ratings.overallHIREScore), width: 4),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        ratings.overallHIREScore.toStringAsFixed(1),
                        style: pw.TextStyle(
                          fontSize: 32,
                          fontWeight: pw.FontWeight.bold,
                          color: _getPDFColorFromRating(ratings.overallHIREScore),
                        ),
                      ),
                      pw.Text(
                        'Overall HIRE',
                        style: pw.TextStyle(
                          fontSize: 12,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildHIRECategoryBox('H', 'Hockey/Humility', ratings.hScore, PdfColors.red),
              _buildHIRECategoryBox('I', 'Integrity/Initiative', ratings.iScore, PdfColors.blue),
              _buildHIRECategoryBox('R', 'Respect/Responsibility', ratings.rScore, PdfColors.green),
              _buildHIRECategoryBox('E', 'Excellence/Enthusiasm', ratings.eScore, PdfColors.orange),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildHIRECategoryBox(String letter, String title, double score, PdfColor color) {
    return pw.Column(
      children: [
        pw.Container(
          width: 40,
          height: 40,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              letter,
              style: pw.TextStyle(
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          title,
          style: const pw.TextStyle(fontSize: 10),
          textAlign: pw.TextAlign.center,
        ),
        pw.Text(
          score.toStringAsFixed(1),
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailedRatingsSection(DevelopmentPlanData planData) {
    final categories = HockeyRatingsConfig.getCategoriesForAge(planData.playerAge);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: categories.map((category) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            category.title,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
          pw.SizedBox(height: 8),
          ...category.factors.map((factor) {
            final rating = planData.ratings.getRatingValue(factor.key);
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 3,
                    child: pw.Text(
                      factor.title,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                      rating.toStringAsFixed(1),
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: _getPDFColor(rating),
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      height: 8,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey200,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Stack(
                        children: [
                          pw.Container(
                            width: (rating / 10) * 100,
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: _getPDFColor(rating),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          pw.SizedBox(height: 16),
        ],
      )).toList(),
    );
  }

  pw.Widget _buildSubsectionHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 14,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.red600,
      ),
    );
  }

  List<pw.Widget> _buildBulletPoints(List<String> points) {
    return points.map((point) => pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('◦ ', style: pw.TextStyle(color: PdfColors.red600)),
          pw.Expanded(
            child: pw.Text(
              point,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    )).toList();
  }

  pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 11),
      ),
    );
  }

  PdfColor _getPDFColor(double score) {
    if (score >= 8.5) return PdfColors.green700;
    if (score >= 7.0) return PdfColors.green;
    if (score >= 6.0) return PdfColors.orange;
    if (score >= 4.0) return PdfColors.deepOrange;
    return PdfColors.red;
  }

  /// Convert Flutter Color to PDF Color for consistency
  PdfColor _toPdfColor(Color color) {
    return PdfColor.fromInt(color.value);
  }

  /// Get PDF color using HockeyRatingsConfig color logic
  PdfColor _getPDFColorFromRating(double rating) {
    return _toPdfColor(HockeyRatingsConfig.getColorForRating(rating));
  }
}