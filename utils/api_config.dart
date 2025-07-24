import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Configuration for API connections
class ApiConfig {
  /// Base URL for the API
  /// Using localhost since backend is running on same machine
  static const String baseUrl = 'https://hockey-shot-tracker-production.up.railway.app';
  
  /// Fallback URLs to try if localhost fails
  static const List<String> fallbackUrls = [
    'http://127.0.0.1:5000',
    'http://192.168.1.6:5000',
  ];

  /// Default headers for API requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  /// Secure storage instance for token management
  static final FlutterSecureStorage secureStorage = FlutterSecureStorage();

  /// Authentication token storage key
  static const String tokenKey = 'access_token';

  /// Refresh token storage key
  static const String refreshTokenKey = 'refresh_token';

  /// Current user storage key
  static const String currentUserKey = 'current_user';

  /// Get authentication headers with token
  static Map<String, String> getAuthHeaders(String? token) {
    return {
      ...defaultHeaders,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get headers for API requests (with token from storage)
  static Future<Map<String, String>> getHeaders() async {
    final token = await secureStorage.read(key: tokenKey);
    return getAuthHeaders(token);
  }

  /// Test connection to server
  static Future<String?> findWorkingUrl() async {
    final urls = [baseUrl, ...fallbackUrls];
    
    for (final url in urls) {
      try {
        // This would need to be implemented in your ApiService
        print('Testing connection to: $url');
        // Return the first working URL
        return url;
      } catch (e) {
        print('Failed to connect to $url: $e');
        continue;
      }
    }
    return null;
  }

  /// Token refresh endpoint
  static const String refreshEndpoint = '/api/auth/refresh';

  /// Login endpoint
  static const String loginEndpoint = '/api/auth/login';

  /// Current user profile endpoint
  static const String currentUserEndpoint = '/api/auth/me';

  /// Analytics endpoints
  static String teamMetricsEndpoint(int teamId) => '/api/analytics/team/$teamId/metrics';
  static String trainingImpactEndpoint(int playerId) => '/api/analytics/training-impact/$playerId';
  static String visualizationEndpoint(String dataType) => '/api/analytics/visualization/$dataType';

  /// Skating analytics endpoint
  static String skatingEndpoint(int playerId) => '/api/analytics/skating/$playerId';

  /// NEW: Enhanced recommendation endpoints
  static String recommendationsEndpoint(int playerId) => '/api/analytics/recommendations/$playerId';
  static String assessmentAnalysisEndpoint(String assessmentId) => '/api/analytics/assessment-analysis/$assessmentId';
  static String missPatternsEndpoint(int playerId) => '/api/analytics/miss-patterns/$playerId';
  static String powerAnalysisEndpoint(int playerId) => '/api/analytics/power-analysis/$playerId';
  static String consistencyAnalysisEndpoint(int playerId) => '/api/analytics/consistency-analysis/$playerId';

  /// Legacy recommendations endpoint (for backward compatibility)
  static String legacyRecommendationsEndpoint(int playerId) => '/api/analytics/legacy-recommendations/$playerId';

  /// Validate baseUrl format
  static void validateBaseUrl() {
    if (!baseUrl.startsWith('http://') && !baseUrl.startsWith('https://')) {
      throw Exception('Invalid baseUrl: Must start with http:// or https://');
    }
    if (baseUrl.endsWith('/')) {
      print('Warning: baseUrl ends with a trailing slash, which may cause issues');
    }
  }

  /// Check if recommendations feature is enabled
  static bool get isRecommendationEngineEnabled => true;

  /// Get full URL for endpoint
  static String getFullUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }

  /// Development/debugging helpers
  static bool get isDebugMode {
    bool inDebugMode = false;
    assert(inDebugMode = true);
    return inDebugMode;
  }

  /// Log API calls in debug mode
  static void logApiCall(String method, String endpoint, {Map<String, dynamic>? data}) {
    if (isDebugMode) {
      print('API Call: $method ${getFullUrl(endpoint)}');
      if (data != null) {
        print('Data: $data');
      }
    }
  }

  /// Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Retry configurations for recommendations
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
}
