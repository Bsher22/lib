import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/services/analytics/analytics_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';
import 'package:hockey_shot_tracker/services/support/calendar_service.dart';
import 'package:hockey_shot_tracker/services/support/file_service.dart';
import 'package:hockey_shot_tracker/services/training/hire_service.dart';
import 'package:hockey_shot_tracker/services/domain/player_service.dart';
import 'package:hockey_shot_tracker/services/analytics/recommendation_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/service_locator.dart';
import 'package:hockey_shot_tracker/services/assessment/shot_assessment_service.dart';
import 'package:hockey_shot_tracker/services/assessment/shot_service.dart';
import 'package:hockey_shot_tracker/services/assessment/skating_service.dart';
import 'package:hockey_shot_tracker/services/domain/team_service.dart';
import 'package:hockey_shot_tracker/services/training/training_service.dart';
import 'package:hockey_shot_tracker/services/domain/user_service.dart';
import 'package:hockey_shot_tracker/services/analytics/visualization_service.dart';
import 'package:hockey_shot_tracker/services/support/reports_service.dart';
import 'package:hockey_shot_tracker/services/auth/registration_service.dart'; // ✅ ADD: Import RegistrationService

/// Central factory for accessing all application services
/// 
/// ApiServiceFactory provides:
/// - Centralized service access with consistent API
/// - Migration bridge from old ApiService to new architecture
/// - Service dependency management and validation
/// - Convenient static methods for common service operations
/// - Development utilities and debugging support
class ApiServiceFactory {
  static ApiServiceFactory? _instance;
  static ApiServiceFactory get instance => _instance ??= ApiServiceFactory._();
  
  ApiServiceFactory._();

  // ✅ FIXED: Added missing _isInitialized property
  static bool _isInitialized = false;

  // ==========================================
  // INITIALIZATION
  // ==========================================

  /// Initialize the service factory and underlying service locator
  /// 
  /// [baseUrl] - Base API URL for all services
  /// [onTokenExpired] - Callback for token expiration handling
  /// [autoInitializeServices] - Whether to initialize critical services immediately
  static Future<void> initialize({
    required String baseUrl,
    void Function(BuildContext?)? onTokenExpired,
    bool autoInitializeServices = true,
  }) async {
    if (_isInitialized) {
      debugPrint('🏭 ApiServiceFactory: Already initialized');
      return;
    }

    debugPrint('🏭 ApiServiceFactory: Initializing with baseUrl: $baseUrl');

    try {
      // ✅ FIX: Initialize the service locator first
      await ServiceLocator.instance.initialize(
        baseUrl: baseUrl,
        onTokenExpired: onTokenExpired,
      );

      // ✅ FIX: Mark as initialized AFTER ServiceLocator is ready
      _isInitialized = true;
      debugPrint('✅ ApiServiceFactory: Marked as initialized');

      if (autoInitializeServices) {
        // Validate service dependencies
        final errors = ServiceLocator.instance.validateDependencies();
        if (errors.isNotEmpty) {
          debugPrint('⚠️ ApiServiceFactory: Service dependency validation warnings:\n${errors.join('\n')}');
          // Don't throw here - just warn
        }

        // Pre-initialize critical services to catch configuration issues early
        await _preInitializeCriticalServices();
      }

      debugPrint('✅ ApiServiceFactory: Initialization completed successfully');
      
      // Print diagnostics in debug mode
      if (autoInitializeServices) {
        ServiceLocator.instance.printDiagnostics();
      }
      
    } catch (e) {
      debugPrint('❌ ApiServiceFactory: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Pre-initialize critical services to validate configuration
  static Future<void> _preInitializeCriticalServices() async {
    try {
      debugPrint('🏭 ApiServiceFactory: Pre-initializing critical services...');
      
      // ✅ FIX: Only initialize services that don't have circular dependencies
      // Test basic service resolution to catch any issues
      try {
        final authService = auth;
        debugPrint('✅ AuthService: Ready');
      } catch (e) {
        debugPrint('⚠️ AuthService: Warning - $e');
      }

      try {
        final _ = user;
        debugPrint('✅ UserService: Ready');
      } catch (e) {
        debugPrint('⚠️ UserService: Warning - $e');
      }

      try {
        final _ = player;
        debugPrint('✅ PlayerService: Ready');
      } catch (e) {
        debugPrint('⚠️ PlayerService: Warning - $e');
      }

      try {
        final _ = team;
        debugPrint('✅ TeamService: Ready');
      } catch (e) {
        debugPrint('⚠️ TeamService: Warning - $e');
      }
      
      debugPrint('✅ ApiServiceFactory: Critical services pre-initialized');
    } catch (e) {
      debugPrint('⚠️ ApiServiceFactory: Critical service pre-initialization had warnings: $e');
      // Don't rethrow - let the app continue
    }
  }

  // ==========================================
  // ✅ FIX: Added missing getBaseUrl method
  // ==========================================

  /// Get the base URL for API services
  static String getBaseUrl() {
    _ensureInitialized();
    return ServiceLocator.instance.getBaseUrl();
  }

  // ==========================================
  // SERVICE ACCESS - FOUNDATION LAYER
  // ==========================================

  /// Get AuthService instance
  static AuthService get auth {
    _ensureInitialized();
    return ServiceLocator.instance.get<AuthService>();
  }

  // ==========================================
  // SERVICE ACCESS - CORE DOMAIN SERVICES
  // ==========================================

  /// Get UserService instance
  static UserService get user {
    _ensureInitialized();
    return ServiceLocator.instance.get<UserService>();
  }

  /// Get PlayerService instance
  static PlayerService get player {
    _ensureInitialized();
    return ServiceLocator.instance.get<PlayerService>();
  }

  /// Get TeamService instance
  static TeamService get team {
    _ensureInitialized();
    return ServiceLocator.instance.get<TeamService>();
  }

  // ==========================================
  // SERVICE ACCESS - ASSESSMENT SERVICES
  // ==========================================

  /// Get ShotService instance
  static ShotService get shot {
    _ensureInitialized();
    return ServiceLocator.instance.get<ShotService>();
  }

  /// Get ShotAssessmentService instance
  static ShotAssessmentService get shotAssessment {
    _ensureInitialized();
    return ServiceLocator.instance.get<ShotAssessmentService>();
  }

  /// ✅ FIX: Add assessment service alias for backward compatibility
  static ShotAssessmentService get assessment {
    _ensureInitialized();
    return ServiceLocator.instance.get<ShotAssessmentService>();
  }

  /// Get SkatingService instance
  static SkatingService get skating {
    _ensureInitialized();
    return ServiceLocator.instance.get<SkatingService>();
  }

  // ==========================================
  // SERVICE ACCESS - ANALYTICS & INSIGHTS
  // ==========================================

  /// Get AnalyticsService instance
  static AnalyticsService get analytics {
    _ensureInitialized();
    return ServiceLocator.instance.get<AnalyticsService>();
  }

  /// Get RecommendationService instance
  static RecommendationService get recommendation {
    _ensureInitialized();
    return ServiceLocator.instance.get<RecommendationService>();
  }

  /// Get VisualizationService instance
  static VisualizationService get visualization {
    _ensureInitialized();
    return ServiceLocator.instance.get<VisualizationService>();
  }

  // ==========================================
  // SERVICE ACCESS - TRAINING & DEVELOPMENT
  // ==========================================

  /// Get TrainingService instance
  static TrainingService get training {
    _ensureInitialized();
    return ServiceLocator.instance.get<TrainingService>();
  }

  /// Get HireService instance
  static HireService get hire {
    _ensureInitialized();
    return ServiceLocator.instance.get<HireService>();
  }

  // ==========================================
  // SERVICE ACCESS - SUPPORT SERVICES
  // ==========================================

  /// Get FileService instance
  static FileService get file {
    _ensureInitialized();
    return ServiceLocator.instance.get<FileService>();
  }

  /// Get CalendarService instance
  static CalendarService get calendar {
    _ensureInitialized();
    return ServiceLocator.instance.get<CalendarService>();
  }

  /// ✅ FIX: Add ReportsService instance - with safe fallback
  static ReportsService get reports {
    _ensureInitialized();
    try {
      return ServiceLocator.instance.get<ReportsService>();
    } catch (e) {
      // If not registered in ServiceLocator, create on-demand
      debugPrint('⚠️ ReportsService not found in ServiceLocator, creating on-demand');
      try {
        return ReportsService(
          baseUrl: getBaseUrl(),
          authService: auth, // Provide required authService parameter
        );
      } catch (authError) {
        debugPrint('❌ Error creating ReportsService: $authError');
        rethrow;
      }
    }
  }

  /// ✅ FIX: Add RegistrationService instance - with correct constructor
  static RegistrationService get registration {
    _ensureInitialized();
    try {
      return ServiceLocator.instance.get<RegistrationService>();
    } catch (e) {
      // If not registered in ServiceLocator, create on-demand
      debugPrint('⚠️ RegistrationService not found in ServiceLocator, creating on-demand');
      // RegistrationService only takes baseUrl, no authService parameter needed
      return RegistrationService(baseUrl: getBaseUrl());
    }
  }

  // ==========================================
  // CONVENIENCE METHODS - AUTHENTICATION
  // ==========================================

  /// Check if user is currently authenticated
  static bool get isAuthenticated => auth.isAuthenticated();

  /// Get current user information
  static Map<String, dynamic>? get currentUser => auth.getCurrentUser();

  /// Get current user role
  static String? get currentUserRole => auth.getCurrentUserRole();

  /// Login with username and password
  static Future<bool> login(String username, String password) async {
    return await auth.login(username, password);
  }

  /// Logout current user
  static Future<void> logout() async {
    await auth.logout();
  }

  /// Check if current user has specific role
  static bool hasRole(String role) {
    return currentUserRole == role;
  }

  /// Check if current user can perform admin functions
  static bool get canManageSystem => auth.isAdmin() || auth.isDirector();

  /// Check if current user can manage teams
  static bool get canManageTeams => auth.canManageTeams();

  /// Check if current user can manage coaches
  static bool get canManageCoaches => auth.canManageCoaches();

  // ==========================================
  // CONVENIENCE METHODS - QUICK ACCESS
  // ==========================================

  /// Fetch player by ID
  static Future<dynamic> getPlayer(int playerId, {BuildContext? context}) async {
    return await player.fetchPlayer(playerId, context: context);
  }

  /// Fetch all players
  static Future<List<dynamic>> getAllPlayers({BuildContext? context}) async {
    return await player.fetchPlayers(context: context);
  }

  /// Fetch team by ID
  static Future<dynamic> getTeam(int teamId, {BuildContext? context}) async {
    return await team.fetchTeam(teamId, context: context);
  }

  /// Fetch all teams
  static Future<List<dynamic>> getAllTeams({BuildContext? context}) async {
    return await team.fetchTeams(context: context);
  }

  /// Get player analytics
  static Future<Map<String, dynamic>> getPlayerAnalytics(
    int playerId, {
    BuildContext? context,
  }) async {
    return await analytics.getPlayerAnalytics(playerId, context: context);
  }

  /// Get player recommendations
  static Future<Map<String, dynamic>> getPlayerRecommendations(
    int playerId, {
    BuildContext? context,
  }) async {
    return await recommendation.getRecommendations(playerId, context: context);
  }

  // ==========================================
  // DEVELOPMENT & DEBUGGING
  // ==========================================

  /// Get comprehensive system health information
  static Map<String, dynamic> getSystemHealth() {
    return {
      'factory': {
        'initialized': _isInitialized,
        'instance_created': _instance != null,
      },
      'serviceLocator': ServiceLocator.instance.getServiceHealth(),
      'authentication': {
        'isAuthenticated': isAuthenticated,
        'currentUser': currentUser?['username'],
        'currentRole': currentUserRole,
      },
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Print comprehensive system diagnostics
  static void printSystemDiagnostics() {
    debugPrint('🏭 ========== SYSTEM DIAGNOSTICS ==========');
    debugPrint('🏭 ApiServiceFactory initialized: $_isInitialized');
    debugPrint('🏭 Authentication status: $isAuthenticated');
    debugPrint('🏭 Current user: ${currentUser?['username'] ?? 'None'}');
    debugPrint('🏭 Current role: ${currentUserRole ?? 'None'}');
    debugPrint('🏭');
    
    ServiceLocator.instance.printDiagnostics();
    
    debugPrint('🏭 ========================================');
  }

  /// Validate all service configurations
  static List<String> validateConfiguration() {
    final errors = <String>[];

    if (!_isInitialized) {
      errors.add('ApiServiceFactory is not initialized');
      return errors;
    }

    // Validate service locator
    errors.addAll(ServiceLocator.instance.validateDependencies());

    // Test critical service access
    try {
      final _ = auth;
    } catch (e) {
      errors.add('Failed to access AuthService: $e');
    }

    try {
      final _ = user;
    } catch (e) {
      errors.add('Failed to access UserService: $e');
    }

    // ✅ FIX: Test new services with safe fallback
    try {
      final _ = reports;
    } catch (e) {
      debugPrint('⚠️ ReportsService access warning: $e');
      // Don't add to errors - this has a fallback
    }

    try {
      final _ = registration;
    } catch (e) {
      debugPrint('⚠️ RegistrationService access warning: $e');
      // Don't add to errors - this has a fallback
    }

    return errors;
  }

  /// Reset factory for testing purposes
  static void reset() {
    ServiceLocator.reset();
    _instance = null;
    _isInitialized = false;
    debugPrint('🏭 ApiServiceFactory: Reset completed');
  }

  // ==========================================
  // PRIVATE HELPERS
  // ==========================================

  /// ✅ FIXED: Added missing _ensureInitialized method
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw Exception(
        'ApiServiceFactory is not initialized. Call ApiServiceFactory.initialize() first.'
      );
    }
  }

  /// Check if factory is initialized
  static bool get isInitialized => _isInitialized;
}

// ==========================================
// ✅ FIXED: Moved Migration class OUTSIDE of ApiServiceFactory
// ==========================================

class ApiServiceFactoryMigration {
  /// Map old ApiService methods to new service methods
  static const Map<String, String> methodMapping = {
    // Authentication
    'login': 'ApiServiceFactory.login',
    'logout': 'ApiServiceFactory.logout',
    'isAuthenticated': 'ApiServiceFactory.isAuthenticated',
    'getCurrentUser': 'ApiServiceFactory.currentUser',
    'getCurrentUserRole': 'ApiServiceFactory.currentUserRole',
    
    // Users
    'registerUser': 'ApiServiceFactory.user.registerUser',
    'updateUser': 'ApiServiceFactory.user.updateUser',
    'deleteUser': 'ApiServiceFactory.user.deleteUser',
    'fetchUsersByRole': 'ApiServiceFactory.user.fetchUsersByRole',
    
    // Players
    'registerPlayer': 'ApiServiceFactory.player.registerPlayer',
    'fetchPlayers': 'ApiServiceFactory.player.fetchPlayers',
    'updatePlayer': 'ApiServiceFactory.player.updatePlayer',
    
    // Teams
    'fetchTeams': 'ApiServiceFactory.team.fetchTeams',
    'fetchTeam': 'ApiServiceFactory.team.fetchTeam',
    'createTeam': 'ApiServiceFactory.team.createTeam',
    'updateTeam': 'ApiServiceFactory.team.updateTeam',
    'deleteTeam': 'ApiServiceFactory.team.deleteTeam',
    'fetchTeamPlayers': 'ApiServiceFactory.team.fetchTeamPlayers',
    
    // Shots
    'fetchShots': 'ApiServiceFactory.shot.fetchShots',
    'addShot': 'ApiServiceFactory.shot.addShot',
    'deleteShot': 'ApiServiceFactory.shot.deleteShot',
    'linkShotsToWorkout': 'ApiServiceFactory.training.linkShotsToWorkout',
    
    // Shot Assessments
    'createShotAssessmentWithShots': 'ApiServiceFactory.shotAssessment.createShotAssessmentWithShots',
    'getShotAssessment': 'ApiServiceFactory.shotAssessment.getShotAssessment',
    'getPlayerShotAssessments': 'ApiServiceFactory.shotAssessment.getPlayerShotAssessments',
    'completeShotAssessment': 'ApiServiceFactory.shotAssessment.completeShotAssessment',
    'getShotAssessmentResults': 'ApiServiceFactory.shotAssessment.getShotAssessmentResults',
    
    // Skating
    'createSkatingSession': 'ApiServiceFactory.skating.createSkatingSession',
    'getSkatingSession': 'ApiServiceFactory.skating.getSkatingSession',
    'addTestToSession': 'ApiServiceFactory.skating.addTestToSession',
    'getPlayerSkatingSessions': 'ApiServiceFactory.skating.getPlayerSkatingSessions',
    'fetchSkatings': 'ApiServiceFactory.skating.fetchSkatings',
    
    // Analytics
    'fetchAnalytics': 'ApiServiceFactory.analytics.fetchAnalytics',
    'getPlayerAnalytics': 'ApiServiceFactory.analytics.getPlayerAnalytics',
    'getPlayerSkatingAnalytics': 'ApiServiceFactory.analytics.getPlayerSkatingAnalytics',
    'fetchPlayerMetrics': 'ApiServiceFactory.analytics.fetchPlayerMetrics',
    'fetchZoneMetrics': 'ApiServiceFactory.analytics.fetchZoneMetrics',
    'fetchTrendData': 'ApiServiceFactory.analytics.fetchTrendData',
    
    // Recommendations
    'getRecommendations': 'ApiServiceFactory.recommendation.getRecommendations',
    'fetchRecommendations': 'ApiServiceFactory.recommendation.fetchRecommendations',
    'getAssessmentAnalysis': 'ApiServiceFactory.recommendation.getAssessmentAnalysis',
    
    // Training
    'recordCompletedWorkout': 'ApiServiceFactory.training.recordCompletedWorkout',
    'fetchCompletedWorkouts': 'ApiServiceFactory.training.fetchCompletedWorkouts',
    'fetchTrainingPrograms': 'ApiServiceFactory.training.fetchTrainingPrograms',
    'fetchTrainingProgramDetails': 'ApiServiceFactory.training.fetchTrainingProgramDetails',
    'fetchTrainingImpact': 'ApiServiceFactory.training.fetchTrainingImpact',
    
    // HIRE System
    'getDevelopmentPlan': 'ApiServiceFactory.hire.getDevelopmentPlan',
    'createDevelopmentPlan': 'ApiServiceFactory.hire.createDevelopmentPlan',
    'updateDevelopmentPlan': 'ApiServiceFactory.hire.updateDevelopmentPlan',
    'deleteDevelopmentPlan': 'ApiServiceFactory.hire.deleteDevelopmentPlan',
    'calculateHIREScores': 'ApiServiceFactory.hire.calculateHIREScores',
    'getHIREScores': 'ApiServiceFactory.hire.getHIREScores',
    'getMentorshipNotes': 'ApiServiceFactory.hire.getMentorshipNotes',
    'updateMentorshipNotes': 'ApiServiceFactory.hire.updateMentorshipNotes',
    
    // Files
    'uploadFile': 'ApiServiceFactory.file.uploadFile',
    'uploadTeamLogo': 'ApiServiceFactory.file.uploadTeamLogo',
    'deleteFile': 'ApiServiceFactory.file.deleteFile',
    'getFileUrl': 'ApiServiceFactory.file.getFileUrl',
    
    // Calendar
    'fetchCalendarEvents': 'ApiServiceFactory.calendar.fetchCalendarEvents',
    'createCalendarEvent': 'ApiServiceFactory.calendar.createCalendarEvent',
    'updateCalendarEvent': 'ApiServiceFactory.calendar.updateCalendarEvent',
    'deleteCalendarEvent': 'ApiServiceFactory.calendar.deleteCalendarEvent',
    'checkCalendarConflicts': 'ApiServiceFactory.calendar.checkCalendarConflicts',
    
    // Visualization
    'fetchVisualizationData': 'ApiServiceFactory.visualization.fetchVisualizationData',
    
    // ✅ ADD: Reports
    'generatePlayerReport': 'ApiServiceFactory.reports.generatePlayerReport',
    'generateTeamReport': 'ApiServiceFactory.reports.generateTeamReport',
    'generateAssessmentReport': 'ApiServiceFactory.reports.generateAssessmentReport',
    'generateProgressReport': 'ApiServiceFactory.reports.generateProgressReport',

    // ✅ ADD: Registration
    'requestAccess': 'ApiServiceFactory.registration.requestAccess',
    'getRegistrationRequests': 'ApiServiceFactory.registration.getRegistrationRequests',
    'approveRegistration': 'ApiServiceFactory.registration.approveRegistration',
    'denyRegistration': 'ApiServiceFactory.registration.denyRegistration',
  };

  /// Print migration guide for developers
  static void printMigrationGuide() {
    debugPrint('''
🔄 API SERVICE MIGRATION GUIDE

Old Monolithic Approach:
❌ final apiService = ApiService();
❌ final players = await apiService.fetchPlayers();

New Modular Approach:
✅ final players = await ApiServiceFactory.player.fetchPlayers();
✅ OR: final players = await ApiServiceFactory.getAllPlayers();

Quick Access Patterns:
✅ ApiServiceFactory.auth.login(username, password);
✅ ApiServiceFactory.isAuthenticated;
✅ ApiServiceFactory.currentUser;
✅ ApiServiceFactory.getPlayer(playerId);
✅ ApiServiceFactory.getPlayerAnalytics(playerId);

Service-Specific Access:
✅ ApiServiceFactory.shot.addShot(shotData);
✅ ApiServiceFactory.training.recordCompletedWorkout(workoutData);
✅ ApiServiceFactory.hire.calculateHIREScores(playerId, ratings);
✅ ApiServiceFactory.file.uploadFile(file);
✅ ApiServiceFactory.reports.generatePlayerReport(playerId);
✅ ApiServiceFactory.registration.requestAccess(requestData);

Migration Benefits:
• Better code organization and maintainability
• Clearer separation of concerns
• Easier testing and mocking
• Improved type safety
• Better error handling and debugging
• Reduced coupling between features

For complete method mapping, see ApiServiceFactoryMigration.methodMapping
    ''');
  }

  /// Get new method name for old ApiService method
  static String? getNewMethodFor(String oldMethod) {
    return methodMapping[oldMethod];
  }

  /// Check if a method has been migrated
  static bool isMethodMigrated(String methodName) {
    return methodMapping.containsKey(methodName);
  }
}

/// Extension for easier service access from BuildContext
extension ApiServiceFactoryContext on BuildContext {
  /// Quick access to authentication service
  AuthService get auth => ApiServiceFactory.auth;
  
  /// Quick access to user service
  UserService get user => ApiServiceFactory.user;
  
  /// Quick access to player service
  PlayerService get player => ApiServiceFactory.player;
  
  /// Quick access to team service
  TeamService get team => ApiServiceFactory.team;
  
  /// Quick access to shot service
  ShotService get shot => ApiServiceFactory.shot;
  
  /// Quick access to analytics service
  AnalyticsService get analytics => ApiServiceFactory.analytics;
  
  /// Quick access to training service
  TrainingService get training => ApiServiceFactory.training;
  
  /// Quick access to hire service
  HireService get hire => ApiServiceFactory.hire;
  
  /// Quick access to file service
  FileService get file => ApiServiceFactory.file;
  
  /// Quick access to calendar service
  CalendarService get calendar => ApiServiceFactory.calendar;

  /// ✅ ADD: Quick access to reports service
  ReportsService get reports => ApiServiceFactory.reports;

  /// ✅ ADD: Quick access to registration service
  RegistrationService get registration => ApiServiceFactory.registration;
}

/// Global convenience functions
AuthService get authService => ApiServiceFactory.auth;
UserService get userService => ApiServiceFactory.user;
PlayerService get playerService => ApiServiceFactory.player;
TeamService get teamService => ApiServiceFactory.team;
ShotService get shotService => ApiServiceFactory.shot;
AnalyticsService get analyticsService => ApiServiceFactory.analytics;
TrainingService get trainingService => ApiServiceFactory.training;
HireService get hireService => ApiServiceFactory.hire;
FileService get fileService => ApiServiceFactory.file;
CalendarService get calendarService => ApiServiceFactory.calendar;
ReportsService get reportsService => ApiServiceFactory.reports; // ✅ ADD: Reports service convenience
RegistrationService get registrationService => ApiServiceFactory.registration; // ✅ ADD: Registration service convenience