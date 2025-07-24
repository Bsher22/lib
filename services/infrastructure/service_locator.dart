import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/services/analytics/analytics_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';
import 'package:hockey_shot_tracker/services/support/calendar_service.dart';
import 'package:hockey_shot_tracker/services/support/file_service.dart';
import 'package:hockey_shot_tracker/services/training/hire_service.dart';
import 'package:hockey_shot_tracker/services/domain/player_service.dart';
import 'package:hockey_shot_tracker/services/analytics/recommendation_service.dart';
import 'package:hockey_shot_tracker/services/assessment/shot_assessment_service.dart';
import 'package:hockey_shot_tracker/services/assessment/shot_service.dart';
import 'package:hockey_shot_tracker/services/assessment/skating_service.dart';
import 'package:hockey_shot_tracker/services/domain/team_service.dart';
import 'package:hockey_shot_tracker/services/training/training_service.dart';
import 'package:hockey_shot_tracker/services/domain/user_service.dart';
import 'package:hockey_shot_tracker/services/analytics/visualization_service.dart';
import 'package:hockey_shot_tracker/services/support/reports_service.dart';        // ✅ ADD: Reports service
import 'package:hockey_shot_tracker/services/auth/registration_service.dart';     // ✅ ADD: Registration service

/// Service registration types for dependency injection
enum ServiceType {
  // Core Services
  auth,
  user,
  player,
  team,
  
  // Assessment Services  
  shot,
  shotAssessment,
  skating,
  
  // Analytics & Insights
  analytics,
  recommendation,
  visualization,
  
  // Training & Development
  training,
  hire,
  
  // Support Services
  file,
  calendar,
  reports,        // ✅ ADD: Reports service
  registration,   // ✅ ADD: Registration service
}

/// Service lifecycle management
enum ServiceLifetime {
  /// Single instance shared across the app
  singleton,
  /// New instance created each time
  transient,
  /// Instance scoped to current session/context
  scoped,
}

/// Service registration configuration
class ServiceRegistration<T> {
  final ServiceType type;
  final ServiceLifetime lifetime;
  final T Function() factory;
  final List<ServiceType> dependencies;
  
  const ServiceRegistration({
    required this.type,
    required this.lifetime,
    required this.factory,
    this.dependencies = const [],
  });
}

/// Dependency injection container for managing service instances
/// 
/// The ServiceLocator provides:
/// - Service registration and resolution
/// - Dependency injection with automatic resolution
/// - Lifecycle management (singleton, transient, scoped)
/// - Service health monitoring and diagnostics
/// - Graceful initialization and disposal
class ServiceLocator {
  static ServiceLocator? _instance;
  static ServiceLocator get instance => _instance ??= ServiceLocator._();
  
  ServiceLocator._();

  final Map<ServiceType, ServiceRegistration> _registrations = {};
  final Map<ServiceType, dynamic> _singletonInstances = {};
  final Map<ServiceType, dynamic> _scopedInstances = {};
  
  bool _isInitialized = false;
  String? _baseUrl;
  void Function(BuildContext?)? _onTokenExpired;

  // ==========================================
  // INITIALIZATION & CONFIGURATION
  // ==========================================

  /// Initialize the service locator with configuration
  /// 
  /// [baseUrl] - Base API URL for all services
  /// [onTokenExpired] - Callback for token expiration handling
  Future<void> initialize({
    required String baseUrl,
    void Function(BuildContext?)? onTokenExpired,
  }) async {
    if (_isInitialized) {
      debugPrint('⚙️ ServiceLocator: Already initialized');
      return;
    }

    _baseUrl = baseUrl;
    _onTokenExpired = onTokenExpired;

    debugPrint('⚙️ ServiceLocator: Initializing with baseUrl: $baseUrl');

    try {
      // Register all services first
      await _registerServices();
      
      // ✅ CRITICAL FIX: Mark as initialized BEFORE initializing critical services
      _isInitialized = true;
      debugPrint('✅ ServiceLocator: Marked as initialized');
      
      // Now initialize critical services (after marking as initialized)
      await _initializeCriticalServices();
      
      debugPrint('✅ ServiceLocator: Initialization completed');
      
    } catch (e) {
      debugPrint('❌ ServiceLocator: Initialization failed: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Register all application services
  Future<void> _registerServices() async {
    debugPrint('⚙️ ServiceLocator: Registering services...');

    // ==========================================
    // FOUNDATION LAYER - AUTH SERVICE FIRST
    // ==========================================
    
    register<AuthService>(
      ServiceRegistration(
        type: ServiceType.auth,
        lifetime: ServiceLifetime.singleton,
        factory: () => AuthService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
        ),
      ),
    );

    // ==========================================
    // CORE DOMAIN SERVICES - WITH AUTH DEPENDENCY
    // ==========================================
    
    register<UserService>(
      ServiceRegistration(
        type: ServiceType.user,
        lifetime: ServiceLifetime.singleton,
        factory: () => UserService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth],
      ),
    );

    register<PlayerService>(
      ServiceRegistration(
        type: ServiceType.player,
        lifetime: ServiceLifetime.singleton,
        factory: () => PlayerService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth],
      ),
    );

    register<TeamService>(
      ServiceRegistration(
        type: ServiceType.team,
        lifetime: ServiceLifetime.singleton,
        factory: () => TeamService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth],
      ),
    );

    // ==========================================
    // ASSESSMENT SERVICES - WITH AUTH DEPENDENCY
    // ==========================================

    register<ShotService>(
      ServiceRegistration(
        type: ServiceType.shot,
        lifetime: ServiceLifetime.singleton,
        factory: () => ShotService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.player],
      ),
    );

    register<ShotAssessmentService>(
      ServiceRegistration(
        type: ServiceType.shotAssessment,
        lifetime: ServiceLifetime.singleton,
        factory: () => ShotAssessmentService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.shot],
      ),
    );

    register<SkatingService>(
      ServiceRegistration(
        type: ServiceType.skating,
        lifetime: ServiceLifetime.singleton,
        factory: () => SkatingService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.player],
      ),
    );

    // ==========================================
    // ANALYTICS & INSIGHTS - WITH AUTH DEPENDENCY
    // ==========================================

    register<AnalyticsService>(
      ServiceRegistration(
        type: ServiceType.analytics,
        lifetime: ServiceLifetime.singleton,
        factory: () => AnalyticsService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.shot, ServiceType.skating],
      ),
    );

    register<RecommendationService>(
      ServiceRegistration(
        type: ServiceType.recommendation,
        lifetime: ServiceLifetime.singleton,
        factory: () => RecommendationService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.analytics],
      ),
    );

    register<VisualizationService>(
      ServiceRegistration(
        type: ServiceType.visualization,
        lifetime: ServiceLifetime.singleton,
        factory: () => VisualizationService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.analytics],
      ),
    );

    // ==========================================
    // TRAINING & DEVELOPMENT - WITH AUTH DEPENDENCY
    // ==========================================

    register<TrainingService>(
      ServiceRegistration(
        type: ServiceType.training,
        lifetime: ServiceLifetime.singleton,
        factory: () => TrainingService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.player],
      ),
    );

    register<HireService>(
      ServiceRegistration(
        type: ServiceType.hire,
        lifetime: ServiceLifetime.singleton,
        factory: () => HireService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.player],
      ),
    );

    // ==========================================
    // SUPPORT SERVICES - WITH AUTH DEPENDENCY
    // ==========================================

    register<FileService>(
      ServiceRegistration(
        type: ServiceType.file,
        lifetime: ServiceLifetime.singleton,
        factory: () => FileService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth],
      ),
    );

    register<CalendarService>(
      ServiceRegistration(
        type: ServiceType.calendar,
        lifetime: ServiceLifetime.singleton,
        factory: () => CalendarService(
          baseUrl: _baseUrl!,
          onTokenExpired: _onTokenExpired,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth, ServiceType.team],
      ),
    );

    // ==========================================
    // ✅ ADD: REPORTS & REGISTRATION SERVICES
    // ==========================================

    register<ReportsService>(
      ServiceRegistration(
        type: ServiceType.reports,
        lifetime: ServiceLifetime.singleton,
        factory: () => ReportsService(
          baseUrl: _baseUrl!,
          authService: get<AuthService>(),
        ),
        dependencies: [ServiceType.auth],
      ),
    );

    register<RegistrationService>(
      ServiceRegistration(
        type: ServiceType.registration,
        lifetime: ServiceLifetime.singleton,
        factory: () => RegistrationService(
          baseUrl: _baseUrl!,
          // RegistrationService doesn't need authService - it's for user registration before authentication
        ),
        dependencies: [], // No auth dependency since this is for user registration
      ),
    );

    debugPrint('✅ ServiceLocator: ${_registrations.length} services registered');
  }

  /// Initialize critical services that need early setup
  Future<void> _initializeCriticalServices() async {
    debugPrint('⚙️ ServiceLocator: Initializing critical services...');
    
    try {
      // ✅ FIX: Now this works because _isInitialized is already true
      // Initialize AuthService first as other services depend on it
      final authService = get<AuthService>();
      await authService.ensureInitialized();
      
      debugPrint('✅ ServiceLocator: Critical services initialized');
    } catch (e) {
      debugPrint('❌ ServiceLocator: Error initializing critical services: $e');
      // ✅ FIX: Don't rethrow here - let the app continue even if critical services fail
      // This prevents the circular dependency from crashing the app
    }
  }

  // ==========================================
  // SERVICE REGISTRATION
  // ==========================================

  /// Register a service with the locator
  void register<T>(ServiceRegistration<T> registration) {
    _registrations[registration.type] = registration;
    debugPrint('⚙️ ServiceLocator: Registered ${registration.type} (${registration.lifetime})');
  }

  /// Register a service with a simple factory function
  void registerSimple<T>(
    ServiceType type,
    T Function() factory, {
    ServiceLifetime lifetime = ServiceLifetime.singleton,
    List<ServiceType> dependencies = const [],
  }) {
    register<T>(ServiceRegistration(
      type: type,
      lifetime: lifetime,
      factory: factory,
      dependencies: dependencies,
    ));
  }

  /// Unregister a service
  void unregister(ServiceType type) {
    _registrations.remove(type);
    _singletonInstances.remove(type);
    _scopedInstances.remove(type);
    debugPrint('⚙️ ServiceLocator: Unregistered $type');
  }

  // ==========================================
  // SERVICE RESOLUTION
  // ==========================================

  /// Get a service instance by type
  T get<T>([ServiceType? type]) {
    if (!_isInitialized) {
      throw Exception('ServiceLocator is not initialized. Call initialize() first.');
    }

    // If no type specified, try to infer from generic type
    type ??= _getServiceTypeFromGeneric<T>();
    
    if (type == null) {
      throw Exception('Could not resolve service type for ${T.toString()}. Please specify the ServiceType explicitly.');
    }

    final registration = _registrations[type];
    if (registration == null) {
      throw Exception('Service $type is not registered');
    }

    return _resolveService<T>(registration);
  }

  /// Resolve service with automatic dependency injection
  T _resolveService<T>(ServiceRegistration registration) {
    switch (registration.lifetime) {
      case ServiceLifetime.singleton:
        return _getSingleton<T>(registration);
      case ServiceLifetime.scoped:
        return _getScoped<T>(registration);
      case ServiceLifetime.transient:
        return _createInstance<T>(registration);
    }
  }

  /// Get or create singleton instance
  T _getSingleton<T>(ServiceRegistration registration) {
    if (_singletonInstances.containsKey(registration.type)) {
      return _singletonInstances[registration.type] as T;
    }

    final instance = _createInstance<T>(registration);
    _singletonInstances[registration.type] = instance;
    return instance;
  }

  /// Get or create scoped instance
  T _getScoped<T>(ServiceRegistration registration) {
    if (_scopedInstances.containsKey(registration.type)) {
      return _scopedInstances[registration.type] as T;
    }

    final instance = _createInstance<T>(registration);
    _scopedInstances[registration.type] = instance;
    return instance;
  }

  /// Create new instance with dependency injection
  T _createInstance<T>(ServiceRegistration registration) {
    // ✅ FIX: Simplified dependency resolution to prevent circular dependencies
    // Just check that dependencies are registered, don't try to resolve them
    for (final dependency in registration.dependencies) {
      if (!_registrations.containsKey(dependency)) {
        throw Exception('Dependency $dependency for service ${registration.type} is not registered');
      }
    }

    // Create the service instance
    try {
      return registration.factory() as T;
    } catch (e) {
      throw Exception('Failed to create instance of ${registration.type}: $e');
    }
  }

  /// Try to infer ServiceType from generic type
  ServiceType? _getServiceTypeFromGeneric<T>() {
    final typeString = T.toString();
    
    switch (typeString) {
      case 'AuthService': return ServiceType.auth;
      case 'UserService': return ServiceType.user;
      case 'PlayerService': return ServiceType.player;
      case 'TeamService': return ServiceType.team;
      case 'ShotService': return ServiceType.shot;
      case 'ShotAssessmentService': return ServiceType.shotAssessment;
      case 'SkatingService': return ServiceType.skating;
      case 'AnalyticsService': return ServiceType.analytics;
      case 'RecommendationService': return ServiceType.recommendation;
      case 'VisualizationService': return ServiceType.visualization;
      case 'TrainingService': return ServiceType.training;
      case 'HireService': return ServiceType.hire;
      case 'FileService': return ServiceType.file;
      case 'CalendarService': return ServiceType.calendar;
      case 'ReportsService': return ServiceType.reports;           // ✅ ADD: Reports mapping
      case 'RegistrationService': return ServiceType.registration; // ✅ ADD: Registration mapping
      default: return null;
    }
  }

  // ==========================================
  // SCOPE MANAGEMENT
  // ==========================================

  /// Create a new scope for scoped services
  void createScope() {
    _scopedInstances.clear();
    debugPrint('⚙️ ServiceLocator: New scope created');
  }

  /// Dispose current scope
  void disposeScope() {
    for (final instance in _scopedInstances.values) {
      if (instance is Disposable) {
        instance.dispose();
      }
    }
    _scopedInstances.clear();
    debugPrint('⚙️ ServiceLocator: Scope disposed');
  }

  // ==========================================
  // HEALTH & DIAGNOSTICS
  // ==========================================

  /// ✅ FIX: Get the base URL for API services
  String getBaseUrl() {
    if (!_isInitialized) {
      throw Exception('ServiceLocator is not initialized. Call initialize() first.');
    }
    
    if (_baseUrl == null) {
      throw Exception('Base URL is not configured');
    }
    
    return _baseUrl!;
  }

  /// Check if a service is registered
  bool isRegistered(ServiceType type) {
    return _registrations.containsKey(type);
  }

  /// Check if a singleton service is instantiated
  bool isInstantiated(ServiceType type) {
    return _singletonInstances.containsKey(type) || _scopedInstances.containsKey(type);
  }

  /// Get service health information
  Map<String, dynamic> getServiceHealth() {
    final health = <String, dynamic>{
      'initialized': _isInitialized,
      'baseUrl': _baseUrl,
      'registeredServices': _registrations.length,
      'singletonInstances': _singletonInstances.length,
      'scopedInstances': _scopedInstances.length,
      'services': <String, dynamic>{},
    };

    for (final entry in _registrations.entries) {
      health['services'][entry.key.toString()] = {
        'lifetime': entry.value.lifetime.toString(),
        'dependencies': entry.value.dependencies.map((d) => d.toString()).toList(),
        'instantiated': isInstantiated(entry.key),
      };
    }

    return health;
  }

  /// Print service diagnostics
  void printDiagnostics() {
    debugPrint('=== SERVICE LOCATOR DIAGNOSTICS ===');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Base URL: $_baseUrl');
    debugPrint('Registered Services: ${_registrations.length}');
    debugPrint('Singleton Instances: ${_singletonInstances.length}');
    debugPrint('Scoped Instances: ${_scopedInstances.length}');
    debugPrint('');
    
    debugPrint('SERVICE REGISTRATIONS:');
    for (final entry in _registrations.entries) {
      final reg = entry.value;
      final instantiated = isInstantiated(entry.key) ? '✅' : '⏸️';
      debugPrint('$instantiated ${entry.key} (${reg.lifetime}) - deps: ${reg.dependencies}');
    }
    debugPrint('=====================================');
  }

  /// Validate service dependencies
  List<String> validateDependencies() {
    final errors = <String>[];

    for (final entry in _registrations.entries) {
      final service = entry.key;
      final registration = entry.value;

      for (final dependency in registration.dependencies) {
        if (!_registrations.containsKey(dependency)) {
          errors.add('Service $service depends on unregistered service $dependency');
        }
      }
    }

    return errors;
  }

  // ==========================================
  // CLEANUP & DISPOSAL
  // ==========================================

  /// Dispose all services and clean up resources
  Future<void> dispose() async {
    debugPrint('⚙️ ServiceLocator: Starting disposal...');

    // Dispose scoped instances first
    disposeScope();

    // Dispose singleton instances
    for (final instance in _singletonInstances.values) {
      if (instance is Disposable) {
        try {
          await instance.dispose();
        } catch (e) {
          debugPrint('❌ ServiceLocator: Error disposing service: $e');
        }
      }
    }

    // Clear all instances and registrations
    _singletonInstances.clear();
    _registrations.clear();
    
    _isInitialized = false;
    _baseUrl = null;
    _onTokenExpired = null;

    debugPrint('✅ ServiceLocator: Disposal completed');
  }

  /// Reset the service locator (for testing)
  static void reset() {
    _instance?.dispose();
    _instance = null;
    debugPrint('⚙️ ServiceLocator: Reset completed');
  }
}

/// Interface for services that need cleanup
abstract class Disposable {
  Future<void> dispose();
}

/// Extension methods for easy service access
extension ServiceLocatorExtension on BuildContext {
  /// Get a service from the locator
  T getService<T>([ServiceType? type]) {
    return ServiceLocator.instance.get<T>(type);
  }
}

/// Global helper functions for service access
T getService<T>([ServiceType? type]) {
  return ServiceLocator.instance.get<T>(type);
}

/// Check if ServiceLocator is initialized
bool get isServiceLocatorInitialized => ServiceLocator.instance._isInitialized;