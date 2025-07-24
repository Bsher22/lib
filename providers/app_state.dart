// ==========================================
// FIXED APP_STATE.DART - METHOD SIGNATURE CORRECTIONS
// These changes align AppState calls with actual service method signatures
// ==========================================

import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/utils/assessment_skating_utils.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/services/database_service.dart';
import 'package:hockey_shot_tracker/utils/extensions.dart';
import 'package:hockey_shot_tracker/providers/assessment_provider.dart';
import 'package:hockey_shot_tracker/providers/player_provider.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/player_report_screen.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:html' as html;

class AppState extends ChangeNotifier {
  // ==========================================
  // CORE STATE & PROPERTIES
  // ==========================================
  
  String selectedPlayer = '';
  List<Player> players = [];
  List<Shot> shots = [];
  List<String> selectedWorkouts = [];
  List<Map<String, dynamic>> skatings = [];
  List<CompletedWorkout> completedWorkouts = [];
  List<TrainingProgram> trainingPrograms = [];

  late AssessmentProvider assessmentProvider;
  late PlayerProvider playerProvider;

  List<Team> teams = [];
  Map<int, int> _teamPlayerCounts = {};

  Team? selectedTeam;
  List<User> coaches = [];
  List<User> coordinators = [];
  List<User> _users = [];
  
  Map<String, dynamic>? currentUser;

  bool cameraEnabled = false;

  Map<String, double> zoneSuccessRates = {};
  Map<String, double> typeSuccessRates = {};
  Map<String, Map<String, double>> zoneTypeSuccess = {};
  double overallSuccessRate = 0;
  double averagePower = 0;
  double averageQuickRelease = 0;
  double trendPercentage = 0;
  double consistencyScore = 5.0;

  bool isLoadingPlayers = false;
  bool isLoadingShots = false;
  bool isLoadingAnalytics = false;
  bool isLoadingAssessments = false;
  bool isLoadingPrograms = false;
  bool isLoadingTeams = false;
  bool isLoadingUsers = false;
  bool isLoadingAuth = false;

  TrainingProgram? currentWorkout;

  Map<String, dynamic>? performanceReport;

  String? currentAssessmentId;
  String? _currentSkatingSessionId;

  User? get currentUserObject {
    if (currentUser == null) return null;
    
    try {
      return User.fromJson(currentUser!);
    } catch (e) {
      print('Error converting currentUser map to User object: $e');
      return null;
    }
  }

  // ==========================================
  // TYPE SAFETY HELPERS
  // ==========================================

  T? safeCast<T>(dynamic value) {
    try {
      if (value is T) return value;
      return null;
    } catch (e) {
      print('Safe cast failed: $e');
      return null;
    }
  }

  String ensureString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  int ensureInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.round();
    return 0;
  }

  Map<String, dynamic> ensureMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  List<T> ensureList<T>(dynamic value, T Function(dynamic) converter) {
    if (value is List) {
      return value.map((item) {
        try {
          return converter(item);
        } catch (e) {
          print('List conversion error: $e');
          return null;
        }
      }).where((item) => item != null).cast<T>().toList();
    }
    return <T>[];
  }

  Map<String, dynamic> _safeMapFromResponse(dynamic response) {
    if (response is Map<String, dynamic>) {
      return response;
    } else if (response is Map) {
      return Map<String, dynamic>.from(response);
    } else {
      print('⚠️ Unexpected response type: ${response.runtimeType}');
      return <String, dynamic>{};
    }
  }

  // ==========================================
  // 1. CORE INITIALIZATION & AUTHENTICATION
  // ==========================================

  AppState() {
    _initializeProviders();
    loadInitialData();
    _loadCameraPreference();
    _loadCurrentUser();
  }

  void _initializeProviders() {
    final authToken = ApiServiceFactory.auth.getAuthToken();
    final baseUrl = ApiServiceFactory.getBaseUrl();
    
    assessmentProvider = AssessmentProvider(
      baseUrl: baseUrl,
      authToken: authToken,
    );
    
    playerProvider = PlayerProvider(
      baseUrl: baseUrl,
      authToken: authToken,
    );
  }

  void _handleTokenExpired(BuildContext? context) {
    print('Token expired, navigating to login screen');
    NavigationService().pushNamedAndRemoveUntil('/login');
  }

  void _updateProvidersToken() {
    String? token = ApiServiceFactory.auth.getAuthToken();
    final baseUrl = ApiServiceFactory.getBaseUrl();
    
    assessmentProvider = AssessmentProvider(
      baseUrl: baseUrl,
      authToken: token,
    );
    playerProvider = PlayerProvider(
      baseUrl: baseUrl,
      authToken: token,
    );
  }

  Future<void> _loadCameraPreference() async {
    final prefs = await SharedPreferences.getInstance();
    cameraEnabled = prefs.getBool('camera_enabled') ?? false;
    notifyListeners();
  }

  Future<void> setCameraEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camera_enabled', value);
    cameraEnabled = value;
    notifyListeners();
  }

  Future<void> _loadCurrentUser() async {
    try {
      currentUser = ApiServiceFactory.auth.getCurrentUser();
      notifyListeners();
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Map<String, dynamic>? getCurrentUser() {
    return ApiServiceFactory.auth.getCurrentUser();
  }

  bool isCoach() => ApiServiceFactory.auth.isCoach();
  bool isCoordinator() => ApiServiceFactory.auth.isCoordinator();
  bool isDirector() => ApiServiceFactory.auth.isDirector();
  bool isAdmin() => ApiServiceFactory.auth.isAdmin();
  bool canManageTeams() => ApiServiceFactory.auth.canManageTeams();
  bool canManageCoaches() => ApiServiceFactory.auth.canManageCoaches();
  bool canManageCoordinators() => ApiServiceFactory.auth.canManageCoordinators();
  bool canDeleteTeams() => ApiServiceFactory.auth.canDeleteTeams();
  String? getCurrentUserRole() => ApiServiceFactory.auth.getCurrentUserRole();

  Future<void> loadInitialData() async {
    try {
      print('🚀 AppState: loadInitialData() started');
      print('🔑 AppState: Authentication status: ${ApiServiceFactory.auth.isAuthenticated()}');
      
      final connectivity = await Connectivity().checkConnectivity();
      print('📡 AppState: Initial connectivity: $connectivity');

      isLoadingPlayers = true;
      notifyListeners();

      if (!kIsWeb) {
        try {
          players = await LocalDatabaseService.instance.getPlayers();
          print('📱 AppState: Loaded ${players.length} players from local database');
        } catch (e) {
          print('❌ AppState: Error loading from local database: $e');
          players = [];
        }
      } else {
        print('🌐 AppState: Local database not supported on web platform');
        players = [];
      }

      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          print('🔄 AppState: Starting backend sync...');
          await _syncWithBackend();
          print('✅ AppState: Backend sync completed');
          
          if (players.isNotEmpty && selectedPlayer.isEmpty) {
            selectedPlayer = players.first.name ?? '';
            await _loadSelectedPlayerData(
              loadShots: true,
              loadSkatings: false,
              loadWorkouts: true,
              shouldLoadAnalytics: true,
            );
            print('🎯 AppState: Set initial selected player: $selectedPlayer');
          }
          
        } catch (e) {
          print('❌ AppState: Backend sync failed: $e');
        }
      } else {
        print('⚠️ AppState: Skipping backend sync (no connectivity or not authenticated)');
        
        if (players.isNotEmpty && selectedPlayer.isEmpty) {
          selectedPlayer = players.first.name ?? '';
          await _loadSelectedPlayerData(
            loadShots: true,
            loadSkatings: false,
            loadWorkouts: true,
            shouldLoadAnalytics: true,
          );
        }
        
        if (connectivity != ConnectivityResult.none) {
          try {
            print('🏒 AppState: Attempting to load teams independently...');
            await loadTeams();
          } catch (e) {
            print('❌ AppState: Independent team loading failed: $e');
          }
        }
      }

      try {
        await initializeSkatingSessionSupport();
        print('✅ AppState: Skating session support initialized');
      } catch (e) {
        print('❌ AppState: Failed to initialize skating session support: $e');
      }

      isLoadingPlayers = false;
      notifyListeners();
      
      print('🏁 AppState: loadInitialData() completed');
      print('📊 AppState: Final state - Players: ${players.length}, Teams: ${teams.length}');
      
    } catch (e) {
      print('❌ AppState: Critical error in loadInitialData(): $e');
      print('📚 AppState: Stack trace: ${StackTrace.current}');
      
      isLoadingPlayers = false;
      notifyListeners();
    }
  }

  Future<void> _syncWithBackend() async {
    try {
      print('🚀 AppState: Fetching players from API...');
      final apiPlayers = await ApiServiceFactory.player.fetchAllPlayers();
      print('✅ AppState: Loaded ${apiPlayers.length} players from API');
      
      if (!kIsWeb) {
        for (var player in apiPlayers) {
          await LocalDatabaseService.instance.insertPlayer(player);
        }
      }
      
      players = apiPlayers;
      await playerProvider.fetchPlayers();
      
      try {
        print('🔄 AppState: Loading teams as part of backend sync...');
        await loadTeams();
      } catch (teamError) {
        print('⚠️ AppState: Team loading failed during sync: $teamError');
      }
      
      try {
        print('🔄 AppState: Loading users...');
        await loadUsers();
      } catch (userError) {
        print('⚠️ AppState: User loading failed during sync: $userError');
      }

      if (selectedPlayer.isNotEmpty) {
        final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
        if (player == null || player.id == null) {
          print('Selected player not found or invalid: $selectedPlayer');
          return;
        }
        await _loadShotsFromApi(player.id!);
        await _loadCompletedWorkoutsFromApi(player.id!);
        String playerId = player.id.toString();
        await playerProvider.fetchPlayerTeam(playerId);
      }
      
      try {
        print('🏋️ AppState: Loading training programs from modular API...');
        await _loadTrainingProgramsFromApi();
        print('✅ AppState: Successfully loaded ${trainingPrograms.length} training programs');
      } catch (e) {
        print('❌ AppState: Training programs loading failed: $e');
      }
      
      print('✅ AppState: Backend sync completed successfully');
      notifyListeners();
    } catch (e) {
      print('❌ AppState: Critical sync error: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    isLoadingAuth = true;
    notifyListeners();

    try {
      print('🔐 AppState: Attempting login with username: $username');
      
      await _forceCleanAllAuthState();
      
      final success = await ApiServiceFactory.auth.login(username, password);
      
      if (success) {
        print('✅ AppState: Login successful');
        
        _updateProvidersToken();
        await _loadCurrentUser();
        await _reloadAllDataAfterLogin();
        
        print('🎯 AppState: Login process completed');
        print('👤 Current user: ${currentUser?['username']}');
        print('🎭 Current role: ${currentUser?['role']}');
        
        isLoadingAuth = false;
        notifyListeners();
        return true;
        
      } else {
        print('❌ AppState: Login failed');
        isLoadingAuth = false;
        notifyListeners();
        return false;
      }
      
    } catch (e) {
      print('❌ AppState: Login error: $e');
      isLoadingAuth = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _forceCleanAllAuthState() async {
    const storage = FlutterSecureStorage();
    
    try {
      print('🧹 AppState: Force clearing authentication state...');
      
      await storage.delete(key: 'access_token');
      await storage.delete(key: 'refresh_token');
      await storage.delete(key: 'user_role');
      await storage.delete(key: 'token_expires_at');
      await storage.delete(key: 'current_user');
      await storage.deleteAll();
      
      if (kIsWeb) {
        html.window.localStorage.remove('hockey_access_token');
        html.window.localStorage.remove('hockey_refresh_token');
        html.window.localStorage.remove('hockey_user_role');
        html.window.localStorage.remove('hockey_token_expires_at');
        html.window.localStorage.clear();
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      print('✅ AppState: Force clear completed');
      
    } catch (e) {
      print('❌ AppState: Error during force clear: $e');
    }
  }

  Future<void> _reloadAllDataAfterLogin() async {
    try {
      print('🔄 AppState: Starting post-login data reload...');
      
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('❌ AppState: No connectivity for post-login reload');
        return;
      }

      if (!ApiServiceFactory.auth.isAuthenticated()) {
        print('❌ AppState: Not authenticated during reload');
        return;
      }

      isLoadingPlayers = true;
      isLoadingTeams = true;
      notifyListeners();

      try {
        print('👥 AppState: Loading players after login...');
        final apiPlayers = await ApiServiceFactory.player.fetchAllPlayers();
        players = apiPlayers;
        await playerProvider.fetchPlayers();
        print('✅ AppState: Loaded ${players.length} players');
        
        if (!kIsWeb) {
          for (var player in players) {
            await LocalDatabaseService.instance.insertPlayer(player);
          }
        }
      } catch (e) {
        print('❌ AppState: Error loading players: $e');
      }
      isLoadingPlayers = false;

      try {
        print('🏒 AppState: Loading teams after login...');
        await loadTeams();
        print('✅ AppState: Loaded ${teams.length} teams');
      } catch (e) {
        print('❌ AppState: Error loading teams: $e');
      }
      isLoadingTeams = false;

      try {
        print('👤 AppState: Loading users...');
        await loadUsers();
        print('✅ AppState: Loaded ${coaches.length} coaches and ${coordinators.length} coordinators');
      } catch (e) {
        print('❌ AppState: Error loading users: $e');
      }

      if (players.isNotEmpty && selectedPlayer.isEmpty) {
        selectedPlayer = players.first.name ?? '';
        print('🎯 AppState: Setting initial player: $selectedPlayer');
        
        await _loadSelectedPlayerData(
          loadShots: true,
          loadSkatings: false,
          loadWorkouts: true,
          shouldLoadAnalytics: true,
        );
      }

      try {
        await _loadTrainingProgramsFromApi();
        print('✅ AppState: Loaded ${trainingPrograms.length} training programs');
      } catch (e) {
        print('❌ AppState: Error loading training programs: $e');
      }

      notifyListeners();
      print('🏁 AppState: Post-login data reload completed');
      print('📊 AppState: Final state - Players: ${players.length}, Teams: ${teams.length}');
      
    } catch (e) {
      print('❌ AppState: Error in post-login reload: $e');
      isLoadingPlayers = false;
      isLoadingTeams = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    print('🔒 AppState: Logout initiated');
    
    isLoadingAuth = true;
    notifyListeners();

    try {
      await ApiServiceFactory.auth.logout();
      await _forceCleanAllAuthState();
      
      // Clear all AppState data
      currentUser = null;
      players = [];
      shots = [];
      skatings = [];
      teams = [];
      coaches = [];
      coordinators = [];
      _users = [];
      selectedPlayer = '';
      selectedTeam = null;
      
      assessmentProvider.clearCache();
      clearCurrentAssessmentId();
      clearCurrentSkatingAssessmentId();
      
      zoneSuccessRates.clear();
      typeSuccessRates.clear();
      zoneTypeSuccess.clear();
      overallSuccessRate = 0;
      averagePower = 0;
      averageQuickRelease = 0;
      trendPercentage = 0;
      consistencyScore = 5.0;
      
      print('✅ AppState: Logout completed - all state cleared');
      
    } catch (e) {
      print('❌ AppState: Logout error: $e');
    } finally {
      isLoadingAuth = false;
      notifyListeners();
    }
  }

  Future<void> ensureDataLoaded() async {
    if (!ApiServiceFactory.auth.isAuthenticated()) {
      print('❌ AppState: Not authenticated - cannot load data');
      return;
    }
    
    bool needsReload = players.isEmpty || teams.isEmpty;
    
    if (needsReload) {
      print('🔄 AppState: Data missing, triggering reload...');
      await _reloadAllDataAfterLogin();
    } else {
      print('✅ AppState: Data already loaded (Players: ${players.length}, Teams: ${teams.length})');
    }
  }

  Future<void> refreshToken(String username, String password) async {
    print('refreshToken: Manual refresh requested, logging out and logging in...');
    await logout();
    await login(username, password);
  }

  // ==========================================
  // 2. SCHEDULE/CALENDAR SECTION
  // ==========================================

  // Note: Calendar functionality would be handled primarily by the API service
  // AppState would mainly store and manage calendar-related state if needed

  // ==========================================
  // 3. ASSESSMENT SECTION
  // ==========================================

  // Shot Assessment ID management methods
  Future<void> setCurrentAssessmentId(String id) async {
    currentAssessmentId = id;
    print('Set currentAssessmentId: $id');
    notifyListeners();
  }

  void clearCurrentAssessmentId() {
    currentAssessmentId = null;
    print('Cleared currentAssessmentId');
    notifyListeners();
  }

  String? getCurrentAssessmentId() {
    return currentAssessmentId;
  }

  // ==========================================
  // SKATING SESSION MANAGEMENT
  // ==========================================

  void setCurrentSkatingAssessmentId(String sessionId) {
    _currentSkatingSessionId = sessionId;
    notifyListeners();
    
    print('✅ AppState: Set skating session ID: $sessionId');
    _persistSkatingSessionId(sessionId);
  }

  String? getCurrentSkatingAssessmentId() {
    return _currentSkatingSessionId;
  }

  void clearCurrentSkatingAssessmentId() {
    final oldSessionId = _currentSkatingSessionId;
    _currentSkatingSessionId = null;
    notifyListeners();
    
    print('✅ AppState: Cleared skating session ID: $oldSessionId');
    _clearPersistedSkatingSessionId();
  }

  bool hasActiveSkatingSession() {
    return _currentSkatingSessionId != null && _currentSkatingSessionId!.isNotEmpty;
  }

  String? getCurrentSkatingSessionDisplayId() {
    if (_currentSkatingSessionId == null || _currentSkatingSessionId!.length < 6) {
      return _currentSkatingSessionId;
    }
    return _currentSkatingSessionId!.substring(_currentSkatingSessionId!.length - 6);
  }

  static const String _skatingSessionIdKey = 'current_skating_session_id';

  Future<void> _persistSkatingSessionId(String sessionId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_skatingSessionIdKey, sessionId);
      print('💾 Persisted skating session ID: $sessionId');
    } catch (e) {
      print('❌ Failed to persist skating session ID: $e');
    }
  }

  Future<void> _clearPersistedSkatingSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_skatingSessionIdKey);
      print('🗑️ Cleared persisted skating session ID');
    } catch (e) {
      print('❌ Failed to clear persisted skating session ID: $e');
    }
  }

  Future<void> _loadPersistedSkatingSessionId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final persistedSessionId = prefs.getString(_skatingSessionIdKey);
      
      if (persistedSessionId != null && persistedSessionId.isNotEmpty) {
        _currentSkatingSessionId = persistedSessionId;
        print('📱 Restored skating session ID from storage: $persistedSessionId');
        await _validatePersistedSkatingSession(persistedSessionId);
      }
    } catch (e) {
      print('❌ Failed to load persisted skating session ID: $e');
      await _clearPersistedSkatingSessionId();
    }
  }

  Future<void> _validatePersistedSkatingSession(String sessionId) async {
    try {
      print('ℹ️ Session validation not implemented - keeping persisted session: $sessionId');
    } catch (e) {
      print('❌ Session validation failed, clearing: $e');
      clearCurrentSkatingAssessmentId();
    }
  }

  void migrateToSessionBasedApproach() {
    print('🔄 Migrating to session-based skating assessment approach');
    print('✅ Migration to session-based approach complete');
  }

  Future<void> initializeSkatingSessionSupport() async {
    print('🚀 Initializing skating session support...');
    
    try {
      await _loadPersistedSkatingSessionId();
      migrateToSessionBasedApproach();
      
      print('✅ Skating session support initialized successfully');
      
      if (hasActiveSkatingSession()) {
        print('📋 Found active session: ${getCurrentSkatingSessionDisplayId()}');
      }
      
    } catch (e) {
      print('❌ Failed to initialize skating session support: $e');
      clearCurrentSkatingAssessmentId();
    }
  }

  void checkSkatingAssessmentInProgress(BuildContext context) {
    final currentAssessmentId = getCurrentSkatingAssessmentId();
    
    if (currentAssessmentId != null) {
      DialogService.showConfirmation(
        context,
        title: 'Skating Assessment in Progress',
        message: 'A skating assessment is already in progress (ID: ${getCurrentSkatingSessionDisplayId()}). Do you want to continue it or start a new one?',
        confirmLabel: 'Continue',
        cancelLabel: 'Start New',
      ).then((confirmed) {
        if (confirmed == true) {
          Navigator.pushNamed(context, '/skating-assessment/execute');
        } else {
          clearCurrentSkatingAssessmentId();
        }
      });
    }
  }

  Future<void> loadSkatingAssessments() async {
    if (selectedPlayer.isEmpty) return;

    final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
    if (player?.id != null) {
      await _loadSkatings(player!.id!);
      String playerId = player.id.toString();
      await assessmentProvider.fetchPlayerAssessmentResults(playerId);
      await assessmentProvider.fetchPlayerTestResults(playerId);
      await assessmentProvider.fetchRecentAssessments(playerId);
      notifyListeners();
    }
  }

  Future<void> loadSkatingAssessmentsEnhanced() async {
    if (selectedPlayer.isEmpty) return;

    try {
      final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
      if (player?.id != null) {
        await _loadSkatings(player!.id!);
        
        String playerId = player.id.toString();
        await assessmentProvider.fetchPlayerAssessmentResults(playerId);
        await assessmentProvider.fetchPlayerTestResults(playerId);
        await assessmentProvider.fetchRecentAssessments(playerId);
        
        print('✅ Loaded skating assessments for ${player.name}');
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error loading skating assessments: $e');
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> loadSkatingAssessmentsBySession(String assessmentId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final response = await ApiServiceFactory.skating.getSkatingAssessmentsBySession(assessmentId);
          
          dynamic assessmentsData;
          if (response is List) {
            assessmentsData = response;
          } else if (response is Map) {
            final responseMap = response as Map;
            if (responseMap.containsKey('assessments')) {
              assessmentsData = responseMap['assessments'];
            } else {
              assessmentsData = response;
            }
          } else {
            assessmentsData = response;
          }
          
          List<Map<String, dynamic>> assessments = [];
          if (assessmentsData is List) {
            assessments = (assessmentsData as List<dynamic>).map((dynamic item) {
              if (item is Map<String, dynamic>) {
                return item;
              } else if (item is Map) {
                return Map<String, dynamic>.from(item);
              } else {
                return <String, dynamic>{'error': 'Invalid item type'};
              }
            }).toList();
          } else if (assessmentsData is Map<String, dynamic>) {
            assessments = [assessmentsData];
          } else if (assessmentsData is Map) {
            assessments = [Map<String, dynamic>.from(assessmentsData)];
          } else if (assessmentsData is String) {
            try {
              final parsed = json.decode(assessmentsData) as List<dynamic>;
              assessments = parsed.map((dynamic item) {
                if (item is Map<String, dynamic>) {
                  return item;
                } else if (item is Map) {
                  return Map<String, dynamic>.from(item);
                } else {
                  return <String, dynamic>{'error': 'Invalid item type'};
                }
              }).toList();
            } catch (e) {
              print('Error parsing string assessments: $e');
              assessments = [];
            }
          }
          
          return assessments;
        } catch (e) {
          print('Error loading skating assessments by session from API: $e');
        }
      }
      
      return skatings.where((s) => 
        s['assessment_id']?.toString() == assessmentId && 
        s['is_assessment'] == true
      ).toList();
      
    } catch (e) {
      print('Error loading skating assessments by session: $e');
      return [];
    }
  }

  Future<void> addSkating(Map<String, dynamic> skatingData) async {
    try {
      print('🏒 addSkating called with assessment_id: ${skatingData['assessment_id']}');

      final requiredFields = ['player_id', 'test_times', 'age_group', 'position'];
      final missingFields = requiredFields.where((field) => 
        !skatingData.containsKey(field) || skatingData[field] == null
      ).toList();
      
      if (missingFields.isNotEmpty) {
        throw Exception('Missing required fields: ${missingFields.join(', ')}');
      }

      final testTimes = skatingData['test_times'] as Map<String, dynamic>?;
      if (testTimes == null || testTimes.isEmpty) {
        throw Exception('No test times provided');
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final apiSkatingData = Map<String, dynamic>.from(skatingData);

          if (apiSkatingData['player_id'] is int) {
            apiSkatingData['player_id'] = apiSkatingData['player_id'].toString();
          }

          if (apiSkatingData['assessment_id'] != null) {
            apiSkatingData['assessment_id'] = apiSkatingData['assessment_id'].toString();
          }

          final ageGroup = apiSkatingData['age_group']?.toString() ?? 'youth_15_18';
          apiSkatingData['age_group'] = ageGroup;

          final position = apiSkatingData['position']?.toString()?.toLowerCase() ?? 'forward';
          if (position == 'defenseman') {
            apiSkatingData['position'] = 'defense';
          } else {
            apiSkatingData['position'] = position;
          }

          apiSkatingData['is_assessment'] = skatingData['is_assessment'] ?? true;
          apiSkatingData['assessment_type'] = skatingData['assessment_type'] ?? 'skating_assessment';
          apiSkatingData['title'] = skatingData['title'] ?? 'Skating Assessment';
          apiSkatingData['description'] = skatingData['description'] ?? 'Individual skating assessment';
          apiSkatingData['date'] = skatingData['date'] ?? DateTime.now().toIso8601String();

          print('🚀 Sending skating data to API:');
          print('  - assessment_id: ${apiSkatingData['assessment_id']}');
          print('  - age_group: ${apiSkatingData['age_group']}');
          print('  - position: ${apiSkatingData['position']}');
          print('  - player_id: ${apiSkatingData['player_id']}');
          print('  - test_times count: ${(apiSkatingData['test_times'] as Map).length}');
          
          await ApiServiceFactory.skating.saveSkating(apiSkatingData);
          print('✅ API response received');

          final skating = _createSkatingFromApiResponse(apiSkatingData, apiSkatingData);
          await _saveSkatingLocally(skating);
          
          skatings.insert(0, skating.toJson());
          print('✅ Added ${skating.assessmentType} skating assessment for player ${skating.playerId} (Assessment ID: ${skating.assessmentId})');
          
        } catch (e) {
          print('❌ API error, saving skating locally: $e');
          await _saveSkatingDataLocally(skatingData);
        }
      } else {
        print('📱 Creating skating assessment locally (offline mode)');
        await _saveSkatingDataLocally(skatingData);
      }

      notifyListeners();
    } catch (e) {
      print('❌ Error adding skating assessment: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
      throw e;
    }
  }

  Skating _createSkatingFromApiResponse(Map<String, dynamic> requestData, Map<String, dynamic> responseData) {
    return Skating(
      // ✅ FIX: Convert to int instead of String for id
      id: ensureInt(responseData['id'] ?? DateTime.now().millisecondsSinceEpoch),
      playerId: ensureInt(requestData['player_id']),
      date: DateTime.tryParse(requestData['date'] ?? '') ?? DateTime.now(),
      // ✅ FIX: Convert to Map<String, double?> for testTimes
      testTimes: _convertToDoubleMap(requestData['test_times']),
      // ✅ FIX: Convert to Map<String, double> for scores
      scores: _convertToRequiredDoubleMap(responseData['scores'] ?? responseData['benchmarks'] ?? {}),
      isAssessment: requestData['is_assessment'] ?? true,
      assessmentType: ensureString(requestData['assessment_type'] ?? 'skating_assessment'),
      title: ensureString(requestData['title'] ?? 'Skating Assessment'),
      description: ensureString(requestData['description'] ?? ''),
      assessmentId: ensureString(requestData['assessment_id']),
      ageGroup: ensureString(requestData['age_group'] ?? 'youth_15_18'),
      position: ensureString(requestData['position'] ?? 'forward'),
    );
  }

  Future<void> _saveSkatingLocally(Skating skating) async {
    if (!kIsWeb) {
      try {
        // Since insertSkating doesn't exist, use a workaround or skip
        print('💾 Skating assessment would be saved to local database: ${skating.id}');
        print('⚠️ LocalDatabaseService.insertSkating() method not implemented');
        // If you have an alternative method like insertData or saveSkating, use it here
        // await LocalDatabaseService.instance.insertData('skating', skating.toJson());
      } catch (e) {
        print('❌ Error saving skating to local database: $e');
      }
    } else {
      print('📄 Web platform - skating not saved locally');
    }
  }

  Future<void> _saveSkatingDataLocally(Map<String, dynamic> skatingData) async {
    final skating = Skating(
      id: DateTime.now().millisecondsSinceEpoch,
      playerId: ensureInt(skatingData['player_id']),
      date: DateTime.tryParse(skatingData['date'] ?? '') ?? DateTime.now(),
      // ✅ FIX: Convert to Map<String, double?> for testTimes
      testTimes: _convertToDoubleMap(skatingData['test_times']),
      // ✅ FIX: Convert to Map<String, double> for scores
      scores: _convertToRequiredDoubleMap(<String, dynamic>{}),
      isAssessment: skatingData['is_assessment'] ?? true,
      assessmentType: ensureString(skatingData['assessment_type'] ?? 'skating_assessment'),
      title: ensureString(skatingData['title'] ?? 'Skating Assessment'),
      description: ensureString(skatingData['description'] ?? ''),
      assessmentId: ensureString(skatingData['assessment_id']),
      ageGroup: ensureString(skatingData['age_group'] ?? 'youth_15_18'),
      position: ensureString(skatingData['position'] ?? 'forward'),
    );

    await _saveSkatingLocally(skating);
    skatings.insert(0, skating.toJson());
    print('✅ Created local skating assessment for player ${skating.playerId}');
  }

  // ==========================================
  // 4. ANALYTICS SECTION
  // ==========================================

  Future<void> loadAnalytics() async {
    if (selectedPlayer.isEmpty || players.isEmpty) return;

    try {
      isLoadingAnalytics = true;
      notifyListeners();

      final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
      if (player?.id == null || player!.id! <= 0) {
        print('Invalid player or playerId for analytics: ${player?.id}');
        isLoadingAnalytics = false;
        notifyListeners();
        return;
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final analytics = await ApiServiceFactory.analytics.fetchAnalytics(player.id!);
          print('Loaded analytics for playerId: ${player.id}: $analytics');
          zoneSuccessRates = Map<String, double>.from(analytics['zone_success_rates'] ?? {});
          typeSuccessRates = Map<String, double>.from(analytics['type_success_rates'] ?? {});
          overallSuccessRate = (analytics['overall_success_rate'] as num?)?.toDouble() ?? 0.0;
          averagePower = (analytics['average_power'] as num?)?.toDouble() ?? 0.0;
          averageQuickRelease = (analytics['average_quick_release'] as num?)?.toDouble() ?? 0.0;
          trendPercentage = (analytics['trend_percentage'] as num?)?.toDouble() ?? 0.0;
          consistencyScore = (analytics['consistency_score'] as num?)?.toDouble() ?? 5.0;

          if (analytics.containsKey('zone_type_success_rates')) {
            zoneTypeSuccess = {};
            final zoneTypeData = analytics['zone_type_success_rates'] as Map<String, dynamic>?;
            if (zoneTypeData != null) {
              for (var zone in zoneTypeData.keys) {
                zoneTypeSuccess[zone] = Map<String, double>.from(zoneTypeData[zone] as Map);
              }
            }
          }
        } catch (e) {
          print('Error loading analytics from API: $e');
          _calculateMetrics();
          print('Calculated local analytics after error for player: $selectedPlayer');
        }
      } else {
        _calculateMetrics();
        print('Calculated local analytics for player: $selectedPlayer');
      }
      isLoadingAnalytics = false;
      notifyListeners();
    } catch (e) {
      print('Error loading analytics for player: $e');
      _calculateMetrics();
      isLoadingAnalytics = false;
      notifyListeners();
    }
  }

  void _calculateMetrics() {
    if (shots.isEmpty) {
      zoneSuccessRates.clear();
      typeSuccessRates.clear();
      zoneTypeSuccess.clear();
      overallSuccessRate = 0;
      averagePower = 0;
      averageQuickRelease = 0;
      trendPercentage = 0;
      consistencyScore = 5.0;
      return;
    }

    final zoneCounts = <String, int>{};
    final zoneSuccess = <String, int>{};
    
    for (var shot in shots) {
      final zone = shot.zone ?? '0';
      final zoneKey = zone.startsWith('miss_') ? 'misses' : zone;
      zoneCounts[zoneKey] = (zoneCounts[zoneKey] ?? 0) + 1;
      if (shot.success) {
        zoneSuccess[zoneKey] = (zoneSuccess[zoneKey] ?? 0) + 1;
      }
    }

    zoneSuccessRates = zoneCounts.map((zone, count) {
      return MapEntry(zone, zoneSuccess[zone] != null ? zoneSuccess[zone]! / count : 0.0);
    });

    final typeCounts = <String, int>{};
    final typeSuccess = <String, int>{};
    for (var shot in shots) {
      final type = shot.type ?? 'Unknown';
      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
      if (shot.success) {
        typeSuccess[type] = (typeSuccess[type] ?? 0) + 1;
      }
    }

    typeSuccessRates = typeCounts.map((type, count) {
      return MapEntry(type, typeSuccess[type] != null ? typeSuccess[type]! / count : 0.0);
    });

    zoneTypeSuccess.clear();
    for (var shot in shots) {
      final zone = shot.zone ?? '0';
      final zoneKey = zone.startsWith('miss_') ? 'misses' : zone;
      final type = shot.type ?? '';
      
      if (!zoneTypeSuccess.containsKey(zoneKey)) {
        zoneTypeSuccess[zoneKey] = {};
      }
      if (!zoneTypeSuccess[zoneKey]!.containsKey(type)) {
        zoneTypeSuccess[zoneKey]![type] = 0;
      }
      if (shot.success) {
        zoneTypeSuccess[zoneKey]![type] = (zoneTypeSuccess[zoneKey]![type] ?? 0) + 1;
      }
    }

    overallSuccessRate = shots.where((s) => s.success).length / shots.length;

    final validPowerShots = shots.where((s) => s.power != null).toList();
    averagePower = validPowerShots.isNotEmpty
        ? validPowerShots.map((s) => s.power!).reduce((a, b) => a + b) / validPowerShots.length
        : 0;

    final validQuickReleaseShots = shots.where((s) => s.quickRelease != null).toList();
    averageQuickRelease = validQuickReleaseShots.isNotEmpty
        ? validQuickReleaseShots.map((s) => s.quickRelease!).reduce((a, b) => a + b) / validQuickReleaseShots.length
        : 0;

    if (shots.length >= 10) {
      final sortedShots = List.of(shots)..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      final midpoint = sortedShots.length ~/ 2;
      final earlierShots = sortedShots.sublist(0, midpoint);
      final recentShots = sortedShots.sublist(midpoint);

      final earlierRate = earlierShots.where((s) => s.success).length / earlierShots.length;
      final recentRate = recentShots.where((s) => s.success).length / recentShots.length;

      trendPercentage = earlierRate > 0 ? ((recentRate - earlierRate) / earlierRate) * 100 : 0;
    } else {
      trendPercentage = 0;
    }

    consistencyScore = _calculateConsistencyScore();
  }

  double _calculateConsistencyScore() {
    if (shots.isEmpty) return 5.0;
    final successRates = shots.map((s) => s.success ? 1.0 : 0.0).toList();
    if (successRates.length < 2) return 5.0;
    final mean = successRates.reduce((a, b) => a + b) / successRates.length;
    final variance = successRates.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / successRates.length;
    final stdDev = variance > 0 ? sqrt(variance) : 0.0;
    return 10.0 * (1 - stdDev);
  }

  // ==========================================
  // 5. SHOTS SECTION
  // ==========================================

  Future<void> addShot(Shot shot) async {
    try {
      print('addShot called with shot: ${shot.toJson()}');

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call addShot(Map) instead of createShot(Shot)
          final apiResponse = await ApiServiceFactory.shot.addShot(shot.toJson());
          final apiShot = Shot.fromJson(apiResponse);
          shots.insert(0, apiShot);
          print('API response received, added shot: ${apiShot.toJson()}');
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertShot(apiShot);
          }
        } catch (e) {
          print('API error, saving shot locally: $e');
          shots.insert(0, shot);
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertShot(shot);
          }
        }
      } else {
        print('No connectivity or not authenticated, saving shot locally');
        shots.insert(0, shot);
        
        if (!kIsWeb) {
          await LocalDatabaseService.instance.insertShot(shot);
        }
      }

      await loadAnalytics();
      notifyListeners();
    } catch (e) {
      print('Error adding shot: $e');
      throw e;
    }
  }

  Future<void> updateShot(Shot shot) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Check for null or empty string ID
          if (shot.id == null || shot.id.toString().isEmpty) {
            throw Exception('Shot ID is required for update');
          }
          
          // ✅ FIX: shot.id is int, not String
          final shotId = shot.id!;
          if (shotId <= 0) {
            throw Exception('Invalid shot ID: $shotId');
          }
          
          final response = await ApiServiceFactory.shot.updateShot(shotId, shot.toJson());
          final updatedShot = Shot.fromJson(response);
          
          final index = shots.indexWhere((s) => s.id == shot.id);
          if (index != -1) {
            shots[index] = updatedShot;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertShot(updatedShot);
          }
          
          print('Shot updated in API and locally');
        } catch (e) {
          print('Error updating shot in API: $e');
          
          final index = shots.indexWhere((s) => s.id == shot.id);
          if (index != -1) {
            shots[index] = shot;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertShot(shot);
          }
          
          print('Shot updated locally only due to API error');
        }
      } else {
        final index = shots.indexWhere((s) => s.id == shot.id);
        if (index != -1) {
          shots[index] = shot;
        }
        
        if (!kIsWeb) {
          await LocalDatabaseService.instance.insertShot(shot);
        }
        
        print('Shot updated locally (offline mode)');
      }

      await loadAnalytics();
      notifyListeners();
    } catch (e) {
      print('Error updating shot: $e');
      throw e;
    }
  }

  Future<void> deleteShot(String shotId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final id = int.tryParse(shotId);
          if (id == null) {
            throw Exception('Invalid shot ID: $shotId');
          }
          await ApiServiceFactory.shot.deleteShot(id);
          print('Shot deleted from API');
        } catch (e) {
          print('Error deleting shot from API: $e');
        }
      }

      shots.removeWhere((shot) => shot.id.toString() == shotId);
      
      if (!kIsWeb) {
        // Skip local deletion since deleteShot method doesn't exist in LocalDatabaseService
        print('Local shot deletion skipped - method not implemented in LocalDatabaseService');
      }

      await loadAnalytics();
      notifyListeners();
      print('Shot deleted locally');
    } catch (e) {
      print('Error deleting shot: $e');
      throw e;
    }
  }

  Future<void> _loadShotsFromApi(int playerId, {String? sourceFilter, int? workoutId, String? assessmentId}) async {
    try {
      if (playerId <= 0) {
        print('Invalid playerId for fetching shots: $playerId');
        await _loadShotsFromLocal(playerId);
        return;
      }
      final queryParams = <String, String>{};
      if (sourceFilter != null) queryParams['source'] = sourceFilter;
      if (workoutId != null) queryParams['workout_id'] = workoutId.toString();
      if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
      
      shots = await ApiServiceFactory.shot.fetchShots(playerId, queryParameters: queryParams);
      print('Loaded ${shots.length} shots from API for playerId: $playerId');
      
      if (!kIsWeb) {
        for (var shot in shots) {
          await LocalDatabaseService.instance.insertShot(shot);
        }
        print('Saved ${shots.length} shots to local database');
      } else {
        print('Skipping local shot storage on web platform');
      }
    } catch (e) {
      print('Error loading shots from API for playerId: $playerId: $e');
      throw e;
    }
  }

  Future<void> _loadShotsFromLocal(int playerId) async {
    try {
      if (!kIsWeb) {
        shots = await LocalDatabaseService.instance.getShots(playerId);
        print('Loaded ${shots.length} shots from local database for playerId: $playerId');
      } else {
        print('Local database not supported on web platform');
        shots = [];
      }
    } catch (e) {
      print('Error loading shots from local: $e');
      shots = [];
    }
  }

  Future<void> linkShotsToWorkout(List<String> shotIds, int workoutId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Convert String IDs to int list for the API call
          final intIds = shotIds.map((id) => int.tryParse(id)).where((id) => id != null).cast<int>().toList();
          
          if (intIds.isEmpty) {
            throw Exception('No valid shot IDs provided');
          }
          
          await ApiServiceFactory.shot.linkShotsToWorkout(intIds, workoutId);
          print('Linked ${shotIds.length} shots to workout $workoutId via API');
        } catch (e) {
          print('Error linking shots to workout via API: $e');
        }
      }

      for (var shotId in shotIds) {
        final shotIndex = shots.indexWhere((shot) => shot.id.toString() == shotId);
        if (shotIndex != -1) {
          shots[shotIndex] = shots[shotIndex].copyWith(workoutId: workoutId);
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.updateShot(shots[shotIndex]);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error linking shots to workout: $e');
      throw e;
    }
  }

  Future<void> unlinkShotsFromWorkout(List<String> shotIds) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Convert String IDs to int list for the API call
          final intIds = shotIds.map((id) => int.tryParse(id)).where((id) => id != null).cast<int>().toList();
          
          if (intIds.isEmpty) {
            throw Exception('No valid shot IDs provided');
          }
          
          await ApiServiceFactory.shot.unlinkShotsFromWorkout(intIds);
          print('Unlinked ${shotIds.length} shots from workout via API');
        } catch (e) {
          print('Error unlinking shots from workout via API: $e');
        }
      }

      for (var shotId in shotIds) {
        final shotIndex = shots.indexWhere((shot) => shot.id.toString() == shotId);
        if (shotIndex != -1) {
          shots[shotIndex] = shots[shotIndex].copyWith(workoutId: null);
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.updateShot(shots[shotIndex]);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error unlinking shots from workout: $e');
      throw e;
    }
  }

  // ==========================================
  // 6. TRAINING SECTION (KEY FIX AREA)
  // ==========================================

  Future<void> _loadTrainingPrograms() async {
    try {
      isLoadingPrograms = true;
      notifyListeners();

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await _loadTrainingProgramsFromApi();
        } catch (e) {
          print('Error loading training programs from API: $e');
        }
      } else {
        if (!kIsWeb) {
          trainingPrograms = await LocalDatabaseService.instance.getTrainingPrograms();
          print('Loaded ${trainingPrograms.length} training programs from local database');
        } else {
          trainingPrograms = [];
          print('No local database support on web platform');
        }
      }
      isLoadingPrograms = false;
      notifyListeners();
    } catch (e) {
      print('Error loading training programs: $e');
      trainingPrograms = [];
      isLoadingPrograms = false;
      notifyListeners();
    }
  }

  Future<void> _loadTrainingProgramsFromApi() async {
    try {
      trainingPrograms = await ApiServiceFactory.training.fetchTrainingPrograms();
      print('✅ MODERNIZED: Loaded ${trainingPrograms.length} training programs from modular API');
      
      if (!kIsWeb) {
        for (var program in trainingPrograms) {
          await LocalDatabaseService.instance.insertTrainingProgram(program);
        }
      }
    } catch (e) {
      print('Error fetching training programs from API: $e');
      
      if (!kIsWeb) {
        trainingPrograms = await LocalDatabaseService.instance.getTrainingPrograms();
        print('Loaded ${trainingPrograms.length} training programs from local database');
      } else {
        trainingPrograms = [];
      }
      throw e;
    }
  }

  Future<void> _loadCompletedWorkoutsFromApi(int playerId) async {
    try {
      completedWorkouts = await ApiServiceFactory.training.fetchCompletedWorkouts(playerId);
      print('Loaded ${completedWorkouts.length} workouts from API for playerId: $playerId');
      
      if (!kIsWeb) {
        for (var workout in completedWorkouts) {
          await LocalDatabaseService.instance.insertCompletedWorkout(workout);
        }
      }
    } catch (e) {
      print('Error fetching completed workouts from API for playerId $playerId: $e');
      
      if (!kIsWeb) {
        completedWorkouts = await LocalDatabaseService.instance.getCompletedWorkouts(playerId);
        print('Loaded ${completedWorkouts.length} workouts from local database for playerId: $playerId');
      } else {
        completedWorkouts = [];
      }
      throw e;
    }
  }

  Future<void> addCompletedWorkout(CompletedWorkout workout) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call recordCompletedWorkout(Map) instead of createCompletedWorkout(CompletedWorkout)
          final workoutData = workout.toJson();
          final response = await ApiServiceFactory.training.recordCompletedWorkout(workoutData);
          final apiWorkout = CompletedWorkout.fromJson(response);
          completedWorkouts.insert(0, apiWorkout);
          print('Workout added via API: ${apiWorkout.toJson()}');
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertCompletedWorkout(apiWorkout);
          }
        } catch (e) {
          print('Error adding workout via API: $e');
          completedWorkouts.insert(0, workout);
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertCompletedWorkout(workout);
          }
        }
      } else {
        completedWorkouts.insert(0, workout);
        
        if (!kIsWeb) {
          await LocalDatabaseService.instance.insertCompletedWorkout(workout);
        }
        
        print('Workout added locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error adding completed workout: $e');
      throw e;
    }
  }

  Future<void> updateCompletedWorkout(CompletedWorkout workout) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: workout.id is int, not String
          if (workout.id == null || workout.id.toString().isEmpty) {
            throw Exception('Workout ID is required for update');
          }
          final workoutId = workout.id!;
          if (workoutId <= 0) {
            throw Exception('Invalid workout ID: $workoutId');
          }
          
          final response = await ApiServiceFactory.training.updateCompletedWorkout(workoutId, workout.toJson());
          final updatedWorkout = CompletedWorkout.fromJson(response as Map<String, dynamic>);
          
          final index = completedWorkouts.indexWhere((w) => w.id == workout.id);
          if (index != -1) {
            completedWorkouts[index] = updatedWorkout;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertCompletedWorkout(updatedWorkout);
          }
          
          print('Workout updated via API');
        } catch (e) {
          print('Error updating workout via API: $e');
          
          final index = completedWorkouts.indexWhere((w) => w.id == workout.id);
          if (index != -1) {
            completedWorkouts[index] = workout;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertCompletedWorkout(workout);
          }
        }
      } else {
        final index = completedWorkouts.indexWhere((w) => w.id == workout.id);
        if (index != -1) {
          completedWorkouts[index] = workout;
        }
        
        if (!kIsWeb) {
          await LocalDatabaseService.instance.insertCompletedWorkout(workout);
        }
        
        print('Workout updated locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error updating completed workout: $e');
      throw e;
    }
  }

  Future<void> deleteCompletedWorkout(String workoutId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call deleteCompletedWorkout(int) instead of deleteCompletedWorkout(String)
          final id = int.tryParse(workoutId);
          if (id == null) {
            throw Exception('Invalid workout ID: $workoutId');
          }
          await ApiServiceFactory.training.deleteCompletedWorkout(id);
          print('Workout deleted from API');
        } catch (e) {
          print('Error deleting workout from API: $e');
        }
      }

      completedWorkouts.removeWhere((workout) => workout.id.toString() == workoutId);
      
      if (!kIsWeb) {
        await LocalDatabaseService.instance.deleteCompletedWorkout(workoutId);
      }

      notifyListeners();
      print('Workout deleted locally');
    } catch (e) {
      print('Error deleting completed workout: $e');
      throw e;
    }
  }

  // ==========================================
  // 7. TEAM MANAGEMENT
  // ==========================================

  Future<void> loadTeams() async {
    try {
      print('🏒 AppState: loadTeams() called');
      
      isLoadingTeams = true;
      notifyListeners();
      
      final connectivity = await Connectivity().checkConnectivity();
      print('📡 AppState: Connectivity: $connectivity');
      print('🔑 AppState: Is authenticated: ${ApiServiceFactory.auth.isAuthenticated()}');
      
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        print('🚀 AppState: Attempting to fetch teams from API...');
        
        try {
          teams = await ApiServiceFactory.team.fetchTeams();
          
          print('✅ AppState: Successfully loaded ${teams.length} teams from API');
          
          if (teams.isNotEmpty) {
            await _loadTeamPlayerCounts();
            print('👥 AppState: Team player counts loaded');
          }
          
        } catch (apiError) {
          print('❌ AppState: API error fetching teams: $apiError');
          print('⚠️ AppState: Keeping existing teams (${teams.length}) due to API error');
          rethrow;
        }
      } else {
        print('❌ AppState: Cannot load teams - no connectivity or not authenticated');
        if (connectivity == ConnectivityResult.none) {
          print('📱 AppState: No internet connection');
        } else {
          print('🔑 AppState: Not authenticated');
          teams = [];
          _teamPlayerCounts.clear();
        }
      }
      
      isLoadingTeams = false;
      notifyListeners();
      
      print('🏁 AppState: loadTeams() completed. Final teams count: ${teams.length}');
      
    } catch (e) {
      print('❌ AppState: Unexpected error in loadTeams(): $e');
      print('⚠️ AppState: Preserving existing teams (${teams.length}) due to unexpected error');
      
      isLoadingTeams = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> _loadTeamPlayerCounts() async {
    _teamPlayerCounts.clear();
    for (var team in teams) {
      if (team.id != null) {
        try {
          final teamPlayers = await ApiServiceFactory.team.fetchTeamPlayers(team.id!);
          _teamPlayerCounts[team.id!] = teamPlayers.length;
        } catch (e) {
          print('Error fetching player count for team ${team.id}: $e');
          _teamPlayerCounts[team.id!] = 0;
        }
      }
    }
  }

  void setSelectedTeam(Team? team) {
    selectedTeam = team;
    notifyListeners();
  }

  int getTeamPlayerCount(int teamId) {
    return _teamPlayerCounts[teamId] ?? 0;
  }

  Future<void> addTeam(Team team) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final teamData = team.toJson();
          final response = await ApiServiceFactory.team.createTeam(teamData);
          final apiTeam = Team.fromJson(response as Map<String, dynamic>);
          teams.insert(0, apiTeam);
          _teamPlayerCounts[apiTeam.id!] = 0;
          print('Team added via API: ${apiTeam.toJson()}');
        } catch (e) {
          print('Error adding team via API: $e');
          teams.insert(0, team);
          if (team.id != null) {
            _teamPlayerCounts[team.id!] = 0;
          }
        }
      } else {
        teams.insert(0, team);
        if (team.id != null) {
          _teamPlayerCounts[team.id!] = 0;
        }
        print('Team added locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error adding team: $e');
      throw e;
    }
  }

  Future<bool> updateTeam(Team team) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          if (team.id == null) {
            throw Exception('Team ID is required for update');
          }
          final response = await ApiServiceFactory.team.updateTeam(team.id!, team.toJson());
          final updatedTeam = Team.fromJson(response as Map<String, dynamic>);
          
          final index = teams.indexWhere((t) => t.id == team.id);
          if (index != -1) {
            teams[index] = updatedTeam;
          }
          
          print('Team updated via API');
          notifyListeners();
          return true;
        } catch (e) {
          print('Error updating team via API: $e');
          
          final index = teams.indexWhere((t) => t.id == team.id);
          if (index != -1) {
            teams[index] = team;
          }
          notifyListeners();
          return false;
        }
      } else {
        final index = teams.indexWhere((t) => t.id == team.id);
        if (index != -1) {
          teams[index] = team;
        }
        
        print('Team updated locally (offline mode)');
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error updating team: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteTeam(int teamId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await ApiServiceFactory.team.deleteTeam(teamId);
          print('Team deleted from API');
        } catch (e) {
          print('Error deleting team from API: $e');
        }
      }

      teams.removeWhere((team) => team.id == teamId);
      _teamPlayerCounts.remove(teamId);

      if (selectedTeam?.id == teamId) {
        selectedTeam = null;
      }

      notifyListeners();
      print('Team deleted locally');
    } catch (e) {
      print('Error deleting team: $e');
      throw e;
    }
  }

  // ==========================================
  // 8. USER MANAGEMENT
  // ==========================================

  Future<void> loadUsers() async {
    try {
      isLoadingUsers = true;
      notifyListeners();
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        coaches = await ApiServiceFactory.user.fetchUsersByRole('coach');
        coordinators = await ApiServiceFactory.user.fetchUsersByRole('coordinator');
      } else {
        coaches = [];
        coordinators = [];
      }
      isLoadingUsers = false;
      notifyListeners();
    } catch (e) {
      print('Error loading users: $e');
      coaches = [];
      coordinators = [];
      isLoadingUsers = false;
      notifyListeners();
    }
  }

  Future<void> addUser(User user) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call registerUser(Map) instead of createUser(User)
          final userData = user.toJson();
          final response = await ApiServiceFactory.user.registerUser(userData);
          final apiUser = User.fromJson(response);
          
          if (apiUser.role == 'coach') {
            coaches.insert(0, apiUser);
          } else if (apiUser.role == 'coordinator') {
            coordinators.insert(0, apiUser);
          }
          
          print('User added via API: ${apiUser.toJson()}');
        } catch (e) {
          print('Error adding user via API: $e');
          
          if (user.role == 'coach') {
            coaches.insert(0, user);
          } else if (user.role == 'coordinator') {
            coordinators.insert(0, user);
          }
        }
      } else {
        if (user.role == 'coach') {
          coaches.insert(0, user);
        } else if (user.role == 'coordinator') {
          coordinators.insert(0, user);
        }
        
        print('User added locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error adding user: $e');
      throw e;
    }
  }

  Future<void> updateUser(User user) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call updateUser(int, Map) instead of updateUser(User)
          if (user.id == null) {
            throw Exception('User ID is required for update');
          }
          final response = await ApiServiceFactory.user.updateUser(user.id!, user.toJson());
          final updatedUser = User.fromJson(response);
          
          _updateUserInList(updatedUser);
          
          print('User updated via API');
        } catch (e) {
          print('Error updating user via API: $e');
          _updateUserInList(user);
        }
      } else {
        _updateUserInList(user);
        print('User updated locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error updating user: $e');
      throw e;
    }
  }

  void _updateUserInList(User user) {
    final coachIndex = coaches.indexWhere((u) => u.id == user.id);
    if (coachIndex != -1) {
      coaches[coachIndex] = user;
      return;
    }
    
    final coordinatorIndex = coordinators.indexWhere((u) => u.id == user.id);
    if (coordinatorIndex != -1) {
      coordinators[coordinatorIndex] = user;
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await ApiServiceFactory.user.deleteUser(userId);
          print('User deleted from API');
        } catch (e) {
          print('Error deleting user from API: $e');
        }
      }

      coaches.removeWhere((user) => user.id == userId);
      coordinators.removeWhere((user) => user.id == userId);

      notifyListeners();
      print('User deleted locally');
    } catch (e) {
      print('Error deleting user: $e');
      throw e;
    }
  }

  // ==========================================
  // 9. PLAYER MANAGEMENT
  // ==========================================

  Future<void> loadPlayers({BuildContext? context}) async {
    try {
      isLoadingPlayers = true;
      notifyListeners();

      print("Loading players...");

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          players = await ApiServiceFactory.player.fetchAllPlayers(context: context);
          print("Loaded ${players.length} players from API");
          
          if (!kIsWeb) {
            for (var player in players) {
              await LocalDatabaseService.instance.insertPlayer(player);
            }
            print("Saved ${players.length} players to local database");
          } else {
            print("Skipping local database save on web platform");
          }
          
          await playerProvider.fetchPlayers();
        } catch (e) {
          print('Error fetching players from API: $e');
          
          if (!kIsWeb) {
            try {
              players = await LocalDatabaseService.instance.getPlayers();
              print("Loaded ${players.length} players from local database (fallback)");
            } catch (localError) {
              print('Local database also failed: $localError');
              players = [];
            }
          } else {
            print("No local fallback available on web platform");
            players = [];
          }
        }
      } else {
        if (!kIsWeb) {
          try {
            players = await LocalDatabaseService.instance.getPlayers();
            print("Loaded ${players.length} players from local database");
          } catch (e) {
            print("Local database failed: $e");
            players = [];
          }
        } else {
          print("No connectivity and no local database support on web platform");
          players = [];
        }
      }

      isLoadingPlayers = false;
      notifyListeners();
    } catch (e) {
      print('Error loading players: $e');
      isLoadingPlayers = false;
      players = [];
      notifyListeners();
    }
  }

  void setSelectedPlayer(
    String playerName, {
    bool loadShots = true,
    bool loadSkatings = false,
    bool loadWorkouts = true,
    bool shouldLoadAnalytics = true,
  }) {
    selectedPlayer = playerName;
    final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
    if (player != null && player.id != null) {
      _loadSelectedPlayerData(
        loadShots: loadShots,
        loadSkatings: loadSkatings,
        loadWorkouts: loadWorkouts,
        shouldLoadAnalytics: shouldLoadAnalytics,
      );
    }
    
    if (hasActiveSkatingSession()) {
      print('ℹ️ Keeping active skating session while switching players');
    }
    
    notifyListeners();
  }

  Future<void> _loadSelectedPlayerData({
    bool loadShots = true,
    bool loadSkatings = false,
    bool loadWorkouts = true,
    bool shouldLoadAnalytics = true,
  }) async {
    if (selectedPlayer.isEmpty) return;

    final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
    if (player == null || player.id == null) {
      print('No valid player found for name: $selectedPlayer');
      return;
    }

    try {
      if (loadShots) {
        await _loadShots(player.id!);
      }
      if (loadSkatings) {
        await _loadSkatings(player.id!);
      }
      if (loadWorkouts) {
        await _loadCompletedWorkouts(player.id!);
      }
      if (shouldLoadAnalytics && loadShots) {
        await loadAnalytics();
      }

      String playerId = player.id.toString();
      if (loadSkatings) {
        await assessmentProvider.fetchPlayerAssessmentResults(playerId);
        await assessmentProvider.fetchPlayerTestResults(playerId);
        await assessmentProvider.fetchRecentAssessments(playerId);
      }
      await playerProvider.fetchPlayerTeam(playerId);
    } catch (e) {
      print('Error loading selected player data: $e');
    }
  }

  Future<void> _loadShots(int playerId, {String? sourceFilter, int? workoutId, String? assessmentId}) async {
    if (selectedPlayer.isEmpty) return;
    isLoadingShots = true;
    notifyListeners();
    final connectivity = await Connectivity().checkConnectivity();
    try {
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await _loadShotsFromApi(playerId, sourceFilter: sourceFilter, workoutId: workoutId, assessmentId: assessmentId);
        } catch (e) {
          print('Error loading shots from API: $e');
          await _loadShotsFromLocal(playerId);
        }
      } else {
        await _loadShotsFromLocal(playerId);
      }
    } catch (e) {
      print('Error loading shots: $e');
      await _loadShotsFromLocal(playerId);
    } finally {
      isLoadingShots = false;
      notifyListeners();
    }
  }

  Future<void> _loadCompletedWorkouts(int playerId) async {
    if (selectedPlayer.isEmpty) return;

    try {
      if (playerId <= 0) {
        print('Invalid playerId for fetching completed workouts: $playerId');
        completedWorkouts = [];
        return;
      }
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await _loadCompletedWorkoutsFromApi(playerId);
        } catch (e) {
          print('Error loading completed workouts from API: $e');
        }
      } else {
        if (!kIsWeb) {
          completedWorkouts = await LocalDatabaseService.instance.getCompletedWorkouts(playerId);
          print('Loaded ${completedWorkouts.length} workouts from local database for playerId: $playerId');
        } else {
          completedWorkouts = [];
          print('No local database support on web platform');
        }
      }
    } catch (e) {
      print('Error loading completed workouts for playerId: $playerId: $e');
      completedWorkouts = [];
      notifyListeners();
    }
  }

  Future<void> _loadSkatings(int playerId) async {
    if (selectedPlayer.isEmpty) return;

    try {
      if (playerId <= 0) {
        print('Invalid playerId for fetching skatings: $playerId');
        skatings = [];
        return;
      }

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await _loadSkatingsFromApi(playerId);
        } catch (e) {
          print('Error loading skatings from API: $e');
        }
      } else {
        skatings = [];
        print('No local skating storage available - data fetched from API only');
      }
      notifyListeners();
    } catch (e) {
      print('Error loading skatings for playerId: $playerId: $e');
      skatings = [];
      notifyListeners();
    }
  }

  Future<void> _loadSkatingsFromApi(int playerId) async {
    try {
      final skatingsResponse = await ApiServiceFactory.skating.fetchSkatings(playerId);
      skatings = skatingsResponse.map((s) => s.toJson()).toList();
      print('Loaded ${skatings.length} skatings from API for playerId: $playerId');
    } catch (e) {
      print('Error fetching skatings from API for playerId: $playerId: $e');
      skatings = [];
      throw e;
    }
  }

  Future<void> addPlayer(Player player) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call registerPlayer(Map) instead of createPlayer(Player)
          final playerData = player.toJson();
          final apiPlayer = await ApiServiceFactory.player.registerPlayer(playerData);
          players.insert(0, apiPlayer);
          print('Player added via API: ${apiPlayer.toJson()}');
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertPlayer(apiPlayer);
          }
          
          await playerProvider.fetchPlayers();
        } catch (e) {
          print('Error adding player via API: $e');
          players.insert(0, player);
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertPlayer(player);
          }
        }
      } else {
        players.insert(0, player);
        
        if (!kIsWeb) {
          await LocalDatabaseService.instance.insertPlayer(player);
        }
        
        print('Player added locally (offline mode)');
      }

      notifyListeners();
    } catch (e) {
      print('Error adding player: $e');
      throw e;
    }
  }

  Future<bool> updatePlayer(int playerId, Map<String, dynamic> playerData) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final response = await ApiServiceFactory.player.updatePlayer(playerId, playerData);
          final updatedPlayer = Player.fromJson(response as Map<String, dynamic>);
          
          final index = players.indexWhere((p) => p.id == playerId);
          if (index != -1) {
            players[index] = updatedPlayer;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertPlayer(updatedPlayer);
          }
          
          await playerProvider.fetchPlayers();
          print('Player updated via API');
          notifyListeners();
          return true;
        } catch (e) {
          print('Error updating player via API: $e');
          
          final existingPlayer = players.firstWhereOrNull((p) => p.id == playerId);
          if (existingPlayer != null) {
            final updatedPlayerData = Map<String, dynamic>.from(existingPlayer.toJson())
              ..addAll(playerData);
            final updatedPlayer = Player.fromJson(updatedPlayerData);
            
            final index = players.indexWhere((p) => p.id == playerId);
            if (index != -1) {
              players[index] = updatedPlayer;
            }
            
            if (!kIsWeb) {
              await LocalDatabaseService.instance.insertPlayer(updatedPlayer);
            }
          }
          notifyListeners();
          return false;
        }
      } else {
        final existingPlayer = players.firstWhereOrNull((p) => p.id == playerId);
        if (existingPlayer != null) {
          final updatedPlayerData = Map<String, dynamic>.from(existingPlayer.toJson())
            ..addAll(playerData);
          final updatedPlayer = Player.fromJson(updatedPlayerData);
          
          final index = players.indexWhere((p) => p.id == playerId);
          if (index != -1) {
            players[index] = updatedPlayer;
          }
          
          if (!kIsWeb) {
            await LocalDatabaseService.instance.insertPlayer(updatedPlayer);
          }
        }
        
        print('Player updated locally (offline mode)');
        notifyListeners();
        return true;
      }
    } catch (e) {
      print('Error updating player: $e');
      notifyListeners();
      return false;
    }
  }

  Future<void> deletePlayer(int playerId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          await ApiServiceFactory.player.deletePlayer(playerId);
          print('Player deleted from API');
        } catch (e) {
          print('Error deleting player from API: $e');
        }
      }

      final deletedPlayer = players.firstWhereOrNull((p) => p.id == playerId);
      players.removeWhere((player) => player.id == playerId);
      
      if (!kIsWeb) {
        await LocalDatabaseService.instance.deletePlayer(playerId);
      }

      if (deletedPlayer?.name == selectedPlayer) {
        selectedPlayer = '';
        shots = [];
        skatings = [];
        completedWorkouts = [];
      }

      await playerProvider.fetchPlayers();
      notifyListeners();
      print('Player deleted locally');
    } catch (e) {
      print('Error deleting player: $e');
      throw e;
    }
  }

  Player? getPlayerById(int playerId) {
    return players.firstWhereOrNull((player) => player.id == playerId);
  }

  Player? getSelectedPlayer() {
    if (selectedPlayer.isEmpty) return null;
    return players.firstWhereOrNull((player) => player.name == selectedPlayer);
  }

  // ==========================================
  // 10. REPORTS SECTION
  // ==========================================

  Future<Map<String, dynamic>?> generatePlayerReport(int playerId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final report = await ApiServiceFactory.reports.generatePlayerReport(playerId);
          performanceReport = report;
          notifyListeners();
          return report;
        } catch (e) {
          print('Error generating player report from API: $e');
        }
      }

      final player = getPlayerById(playerId);
      if (player == null) {
        print('Player not found for report generation: $playerId');
        return null;
      }

      final localReport = _generateLocalPlayerReport(player);
      performanceReport = localReport;
      notifyListeners();
      return localReport;
    } catch (e) {
      print('Error generating player report: $e');
      return null;
    }
  }

  Map<String, dynamic> _generateLocalPlayerReport(Player player) {
    final playerShots = shots.where((shot) => shot.playerId == player.id).toList();
    final playerWorkouts = completedWorkouts.where((workout) => workout.playerId == player.id).toList();
    final playerSkatings = skatings.where((skating) => skating['player_id'] == player.id).toList();

    return {
      'player': player.toJson(),
      'shots_summary': {
        'total_shots': playerShots.length,
        'successful_shots': playerShots.where((s) => s.success).length,
        'success_rate': playerShots.isNotEmpty ? 
          playerShots.where((s) => s.success).length / playerShots.length : 0.0,
      },
      'workouts_summary': {
        'total_workouts': playerWorkouts.length,
        // Handle missing duration property by calculating estimated duration
        'total_duration': playerWorkouts.fold<int>(0, (sum, w) {
          // Since CompletedWorkout doesn't have duration, estimate based on total shots
          // Assume ~1 minute per 10 shots as a reasonable estimate
          final estimatedDuration = (w.totalShots / 10 * 60).round();
          return sum + estimatedDuration;
        }),
      },
      'skating_summary': {
        'total_assessments': playerSkatings.length,
      },
      'generated_at': DateTime.now().toIso8601String(),
      'source': 'local',
    };
  }

  // ==========================================
  // 11. UTILITY & HELPER METHODS
  // ==========================================

  static Future<void> handleLogin(BuildContext context, String username, String password) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    try {
      final success = await appState.login(username, password);
      
      if (success) {
        print('✅ Login successful, navigating to home');
        
        if (appState.players.isEmpty || appState.teams.isEmpty) {
          print('⚠️ Data seems missing after login, ensuring it loads...');
          await appState.ensureDataLoaded();
        }
        
        Navigator.pushReplacementNamed(context, '/home');
        
      } else {
        print('❌ Login failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login failed. Please check your credentials.')),
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login error: $e')),
      );
    }
  }

  void logCurrentState() {
    print('\n=== CURRENT APP STATE ===');
    print('Authenticated: ${ApiServiceFactory.auth.isAuthenticated()}');
    print('Current User: ${currentUser?['username'] ?? 'None'}');
    print('Players loaded: ${players.length}');
    print('Teams loaded: ${teams.length}');
    print('Training Programs loaded: ${trainingPrograms.length}');
    print('Coaches loaded: ${coaches.length}');
    print('Selected player: $selectedPlayer');
    print('Loading states:');
    print('  - Auth: $isLoadingAuth');
    print('  - Players: $isLoadingPlayers');
    print('  - Teams: $isLoadingTeams');
    print('  - Users: $isLoadingUsers');
    print('  - Programs: $isLoadingPrograms');
    print('========================\n');
  }

  void debugSkatingSessionState() {
    print('=== SKATING SESSION STATE DEBUG ===');
    print('Current session ID: $_currentSkatingSessionId');
    print('Has active session: ${hasActiveSkatingSession()}');
    print('Display ID: ${getCurrentSkatingSessionDisplayId()}');
    print('Selected player: $selectedPlayer');
    print('==================================');
  }

  // ==========================================
  // 12. WORKOUT SELECTION & FILTERING
  // ==========================================

  void setSelectedWorkouts(List<String> workoutIds) {
    selectedWorkouts = workoutIds;
    notifyListeners();
  }

  void addSelectedWorkout(String workoutId) {
    if (!selectedWorkouts.contains(workoutId)) {
      selectedWorkouts.add(workoutId);
      notifyListeners();
    }
  }

  void removeSelectedWorkout(String workoutId) {
    selectedWorkouts.remove(workoutId);
    notifyListeners();
  }

  void clearSelectedWorkouts() {
    selectedWorkouts.clear();
    notifyListeners();
  }

  List<Shot> getFilteredShots({String? sourceFilter, List<String>? workoutIds}) {
    var filteredShots = List<Shot>.from(shots);

    if (sourceFilter != null) {
      filteredShots = filteredShots.where((shot) => shot.source == sourceFilter).toList();
    }

    if (workoutIds != null && workoutIds.isNotEmpty) {
      filteredShots = filteredShots.where((shot) => 
        shot.workoutId != null && workoutIds.contains(shot.workoutId.toString())
      ).toList();
    }

    return filteredShots;
  }

  // ==========================================
  // 13. ASSESSMENT HELPERS
  // ==========================================

  Future<void> completeAssessment(String assessmentId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          // ✅ FIX: Call completeShotAssessment(String) instead of completeAssessment(String)
          await ApiServiceFactory.assessment.completeShotAssessment(assessmentId);
          print('Assessment completed via API: $assessmentId');
        } catch (e) {
          print('Error completing assessment via API: $e');
        }
      }

      clearCurrentAssessmentId();
      notifyListeners();
    } catch (e) {
      print('Error completing assessment: $e');
      throw e;
    }
  }

  // ==========================================
  // 14. NAVIGATION HELPERS
  // ==========================================

  void navigateToPlayerReport(BuildContext context, Player player) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlayerReportScreen(player: player),
      ),
    );
  }

  // ==========================================
  // 15. DATA SYNCHRONIZATION
  // ==========================================

  Future<void> syncDataWithServer() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity == ConnectivityResult.none) {
        print('No connectivity available for sync');
        return;
      }

      if (!ApiServiceFactory.auth.isAuthenticated()) {
        print('Not authenticated, cannot sync data');
        return;
      }

      print('Starting data synchronization...');
      
      await Future.wait([
        loadPlayers(),
        loadTeams(),
        loadUsers(),
        _loadTrainingPrograms(),
      ]);

      if (selectedPlayer.isNotEmpty) {
        final player = players.firstWhereOrNull((p) => p.name == selectedPlayer);
        if (player?.id != null) {
          await _loadSelectedPlayerData(
            loadShots: true,
            loadSkatings: true,
            loadWorkouts: true,
            shouldLoadAnalytics: true,
          );
        }
      }

      print('Data synchronization completed');
      notifyListeners();
    } catch (e) {
      print('Error during data synchronization: $e');
    }
  }

  // ==========================================
  // 16. CLEANUP AND DISPOSAL
  // ==========================================

  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }

  // ==========================================
  // 17. TYPE CONVERSION HELPERS
  // ==========================================

  Map<String, double?> _convertToDoubleMap(dynamic value) {
    if (value is Map<String, double?>) return value;
    if (value is Map<String, dynamic>) {
      return value.map((key, val) => MapEntry(key, val is num ? val.toDouble() : null));
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val is num ? val.toDouble() : null)).cast<String, double?>();
    }
    return <String, double?>{};
  }

  Map<String, double> _convertToRequiredDoubleMap(dynamic value) {
    if (value is Map<String, double>) return value;
    if (value is Map<String, dynamic>) {
      return value.map((key, val) => MapEntry(key, val is num ? val.toDouble() : 0.0));
    }
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val is num ? val.toDouble() : 0.0)).cast<String, double>();
    }
    return <String, double>{};
  }

  // ==========================================
  // 18. BACKWARDS COMPATIBILITY METHODS
  // ==========================================

  Future<List<Player>> fetchPlayers() async {
    await loadPlayers();
    return players;
  }

  Future<Player> createPlayer(Map<String, dynamic> playerData) async {
    final player = Player.fromJson(playerData);
    await addPlayer(player);
    return player;
  }

  Future<List<Player>> fetchTeamPlayers(int teamId) async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        return await ApiServiceFactory.team.fetchTeamPlayers(teamId);
      } else {
        return players.where((player) => player.teamId == teamId).toList();
      }
    } catch (e) {
      print('Error fetching team players: $e');
      return players.where((player) => player.teamId == teamId).toList();
    }
  }

  int getTeamPlayersCount(int teamId) {
    return getTeamPlayerCount(teamId);
  }

  // ✅ FIX: Fixed method signature to match calling code
  Future<bool> saveTeamSkating(
    Map<String, dynamic> skatingData, 
    int teamId, 
    String assessmentId, 
    List<int> playerIds
  ) async {
    try {
      // Add the additional parameters to the skating data
      skatingData['team_id'] = teamId;
      skatingData['assessment_id'] = assessmentId;
      skatingData['player_ids'] = playerIds;

      await addSkating(skatingData);
      return true;
    } catch (e) {
      print('Error saving team skating: $e');
      return false;
    }
  }

  dynamic get api {
    throw UnimplementedError('The api getter is deprecated. Use ApiServiceFactory instead.');
  }

  void beginWorkout(TrainingProgram program) {
    currentWorkout = program;
    notifyListeners();
    print('Started workout: ${program.name}');
  }

  Future<void> completeWorkout(Map<String, dynamic> results) async {
    try {
      if (currentWorkout == null) {
        throw Exception('No active workout to complete');
      }

      // ✅ FIX: Create CompletedWorkout with correct parameters (no duration field)
      final completedWorkout = CompletedWorkout(
        id: DateTime.now().millisecondsSinceEpoch,
        playerId: results['player_id'] ?? (getSelectedPlayer()?.id ?? 0),
        programId: currentWorkout!.id ?? 0,
        programName: currentWorkout!.name,
        dateCompleted: DateTime.now(),
        totalShots: results['total_shots'] ?? 0,
        successfulShots: results['successful_shots'] ?? 0,
        notes: results['notes'],
      );

      await addCompletedWorkout(completedWorkout);
      
      currentWorkout = null;
      notifyListeners();
      
      print('Workout completed successfully');
    } catch (e) {
      print('Error completing workout: $e');
      throw e;
    }
  }

  void cancelWorkout() {
    currentWorkout = null;
    notifyListeners();
    print('Workout cancelled');
  }

  void addWorkout(String workoutName) {
    // ✅ FIX: Create TrainingProgram with all required parameters based on actual constructor
    final program = TrainingProgram(
      id: DateTime.now().millisecondsSinceEpoch,
      name: workoutName,
      description: 'Custom workout',
      difficulty: 'intermediate',
      type: 'shooting',
      duration: '30 minutes', // String duration as per constructor
      totalShots: 50, // Required parameter
      createdAt: DateTime.now(), // Required parameter
      estimatedDuration: 30, // Optional int duration in minutes
    );

    trainingPrograms.add(program);
    notifyListeners();
    print('Added workout: $workoutName');
  }

  Future<void> reloadShotsFromApi() async {
    final player = getSelectedPlayer();
    if (player?.id != null) {
      await _loadShotsFromApi(player!.id!);
      notifyListeners();
    }
  }

  List<Player> getPlayersByTeam(int? teamId) {
    if (teamId == null) return [];
    return players.where((player) => player.teamId == teamId).toList();
  }

  Future<void> addShotFromMap(Map<String, dynamic> shotData) async {
    try {
      final shot = Shot.fromJson(shotData);
      await addShot(shot);
    } catch (e) {
      print('Error adding shot from map: $e');
      throw e;
    }
  }

  // ==========================================
  // 19. RECOMMENDATIONS SYSTEM
  // ==========================================

  Future<List<Map<String, dynamic>>> getRecommendations() async {
    try {
      final player = getSelectedPlayer();
      if (player == null) return [];

      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
        try {
          final recommendations = await ApiServiceFactory.recommendation.getRecommendations(
            player.id!, 
            context: null
          );
          
          // ✅ FIXED: Cast to List explicitly to avoid type inference issues
          if (recommendations is List) {
            // Handle List response - convert all items to proper Map format
            final List<Map<String, dynamic>> convertedList = [];
            final recommendationsList = recommendations as List; // ✅ EXPLICIT CAST
            for (final item in recommendationsList) {
              if (item is Map<String, dynamic>) {
                convertedList.add(item);
              } else if (item is Map) {
                convertedList.add(Map<String, dynamic>.from(item));
              } else {
                convertedList.add(<String, dynamic>{'error': 'Invalid recommendation format'});
              }
            }
            return convertedList;
          } else if (recommendations is Map<String, dynamic>) {
            // Handle Map<String, dynamic> response - convert to List with single item
            return [recommendations];
          } else if (recommendations is Map) {
            // Handle generic Map response - convert to List with single item
            return [Map<String, dynamic>.from(recommendations)];
          } else {
            // Handle any other type
            return [];
          }
        } catch (e) {
          print('Error fetching recommendations from API: $e');
          return _generateLocalRecommendationsList(player);
        }
      } else {
        return _generateLocalRecommendationsList(player);
      }
    } catch (e) {
      print('Error getting recommendations: $e');
      return [];
    }
  }

  List<Map<String, dynamic>> _generateLocalRecommendationsList(Player player) {
    final recommendationsList = <Map<String, dynamic>>[];
    
    if (shots.isNotEmpty) {
      final successRate = shots.where((s) => s.success).length / shots.length;
      
      if (successRate < 0.5) {
        recommendationsList.add({
          'id': 'accuracy_focus',
          'title': 'Focus on Accuracy',
          'description': 'Work on shooting accuracy with target practice drills',
          'priority': 'high',
          'type': 'improvement'
        });
      }
      
      if (averagePower < 5.0) {
        recommendationsList.add({
          'id': 'power_development',
          'title': 'Power Development',
          'description': 'Incorporate strength training to increase shot power',
          'priority': 'medium',
          'type': 'program'
        });
      }
    }

    return recommendationsList;
  }
/// Get pagination info for debugging
void logPaginationInfo() {
  print('\n=== PAGINATION STATUS ===');
  print('Total players loaded: ${players.length}');
  print('Authentication status: ${ApiServiceFactory.auth.isAuthenticated()}');
  print('Selected player: $selectedPlayer');
  print('Players by position:');
  
  final positionCounts = <String, int>{};
  for (final player in players) {
    final position = player.position ?? 'Unknown';
    positionCounts[position] = (positionCounts[position] ?? 0) + 1;
  }
  
  for (final entry in positionCounts.entries) {
    print('  - ${entry.key}: ${entry.value}');
  }
  
  print('Players by team:');
  final teamCounts = <int, int>{};
  for (final player in players) {
    final teamId = player.teamId ?? 0;
    teamCounts[teamId] = (teamCounts[teamId] ?? 0) + 1;
  }
  
  for (final entry in teamCounts.entries) {
    final teamName = teams.firstWhereOrNull((t) => t.id == entry.key)?.name ?? 'Unknown';
    print('  - Team ${entry.key} ($teamName): ${entry.value}');
  }
  
  print('========================\n');
}

/// Force reload all players with full pagination
Future<void> forceReloadAllPlayers({BuildContext? context}) async {
  try {
    print('🔄 AppState: Force reloading ALL players...');
    
    isLoadingPlayers = true;
    notifyListeners();
    
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none && ApiServiceFactory.auth.isAuthenticated()) {
      try {
        // Clear existing players first
        players.clear();
        
        // Fetch all players with pagination
        players = await ApiServiceFactory.player.fetchAllPlayers(context: context);
        print('✅ AppState: Force reload complete - ${players.length} players loaded');
        
        if (!kIsWeb) {
          // Update local database
          for (var player in players) {
            await LocalDatabaseService.instance.insertPlayer(player);
          }
        }
        
        await playerProvider.fetchPlayers();
        
        // Log pagination info for debugging
        logPaginationInfo();
        
      } catch (e) {
        print('❌ AppState: Force reload failed: $e');
        throw e;
      }
    } else {
      throw Exception('No connectivity or not authenticated');
    }
    
    isLoadingPlayers = false;
    notifyListeners();
    
  } catch (e) {
    print('❌ AppState: Error in force reload: $e');
    isLoadingPlayers = false;
    notifyListeners();
    rethrow;
  }
}
}