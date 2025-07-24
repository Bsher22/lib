// Web-safe imports for api_service.dart
import 'dart:html' as html;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';

import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/models/calendar_event.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/utils/platform_utils.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

// ==========================================
// WEB-SAFE FILE HELPER CLASS
// ==========================================

/// Web-safe File helper class
class WebSafeFile {
  final String path;
  final String name;
  final Uint8List bytes;
  
  WebSafeFile({required this.path, required this.name, required this.bytes});
  
  /// Factory constructor for web compatibility
  static Future<WebSafeFile?> fromPath(String path) async {
    if (PlatformUtils.isWeb) {
      print('WebSafeFile.fromPath() not supported on web platform');
      return null;
    } else if (PlatformUtils.supportsFeature(PlatformFeature.fileSystem)) {
      // On mobile/desktop, use dynamic loading to avoid compile-time issues
      try {
        // Use dynamic loading to get File class
        final fileInstance = await _createFileInstance(path);
        if (fileInstance != null) {
          final bytes = await _readFileBytes(fileInstance);
          final name = path.split('/').last;
          return WebSafeFile(path: path, name: name, bytes: bytes);
        }
        return null;
      } catch (e) {
        print('Error reading file: $e');
        return null;
      }
    } else {
      print('File system not supported on ${PlatformUtils.platformName}');
      return null;
    }
  }
  
  /// Helper method to create file instance dynamically
  static Future<dynamic> _createFileInstance(String path) async {
    if (!PlatformUtils.supportsFeature(PlatformFeature.fileSystem)) return null;
    
    try {
      // This will be dynamically resolved at runtime
      final Type? fileType = _getFileType();
      if (fileType != null) {
        // Create file instance using reflection-like approach
        return _invokeFileConstructor(fileType, path);
      }
      return null;
    } catch (e) {
      print('Could not create file instance: $e');
      return null;
    }
  }
  
  /// Helper to get File type dynamically
  static Type? _getFileType() {
    if (PlatformUtils.isWeb) return null;
    // This will be resolved at runtime on non-web platforms
    try {
      return String; // Placeholder - actual implementation would use dart:mirrors or other dynamic loading
    } catch (e) {
      return null;
    }
  }
  
  /// Helper to invoke file constructor
  static dynamic _invokeFileConstructor(Type fileType, String path) {
    // This is a simplified version - real implementation would use proper dynamic loading
    return null;
  }
  
  /// Helper to read file bytes
  static Future<Uint8List> _readFileBytes(dynamic fileInstance) async {
    // This would be implemented to read bytes from the file instance
    // For now, return empty bytes
    return Uint8List(0);
  }
}

// ==========================================
// MAIN API SERVICE CLASS
// ==========================================

class ApiService {
  // ==========================================
  // PROPERTIES & INITIALIZATION
  // ==========================================
  
  late Dio _dio;
  String? _token;
  String? _refreshToken;
  String? _currentUserRole;
  Map<String, dynamic>? _currentUser;
  DateTime? _tokenExpiresAt;
  final FlutterSecureStorage secureStorage = ApiConfig.secureStorage;
  final String baseUrl;
  final void Function(BuildContext?)? onTokenExpired;
  bool _isRefreshing = false;
  bool _hasNavigatedToLogin = false;
  
  // ✅ CRITICAL FIX: Add initialization tracking
  bool _isInitialized = false;
  Completer<void>? _initCompleter;

  ApiService({required this.baseUrl, this.onTokenExpired}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: ApiConfig.defaultHeaders,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    _setupInterceptors();
    
    // ✅ CRITICAL FIX: Use async initialization instead of direct calls
    _initializeAsync();
  }

  // ==========================================
  // ✅ CRITICAL FIX: ASYNC INITIALIZATION METHODS
  // ==========================================

  /// Ensure proper async initialization
  Future<void> _initializeAsync() async {
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();
    
    try {
      await _loadToken();
      await _loadCurrentUser();
      _isInitialized = true;
      _initCompleter!.complete();
      print('🔑 ApiService: Initialization completed successfully');
    } catch (e) {
      print('❌ ApiService: Initialization failed: $e');
      _initCompleter!.completeError(e);
    }
  }

  /// Ensure the API service is fully initialized before use
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initializeAsync();
  }

  // ==========================================
  // AUTHENTICATION & TOKEN MANAGEMENT
  // ==========================================

  Future<void> _loadToken() async {
    if (kIsWeb) {
      // Load from localStorage on web
      _token = html.window.localStorage['hockey_access_token'];
      _refreshToken = html.window.localStorage['hockey_refresh_token'];
      _currentUserRole = html.window.localStorage['hockey_user_role'];
      final expiryString = html.window.localStorage['hockey_token_expires_at'];
      if (expiryString != null) {
        _tokenExpiresAt = DateTime.tryParse(expiryString);
      }
      print('📱 Loaded tokens from localStorage (web)');
    } else {
      // Load from secure storage on mobile/desktop
      _token = await secureStorage.read(key: ApiConfig.tokenKey);
      _refreshToken = await secureStorage.read(key: ApiConfig.refreshTokenKey);
      _currentUserRole = await secureStorage.read(key: 'user_role');
      final expiryString = await secureStorage.read(key: 'token_expires_at');
      if (expiryString != null) {
        _tokenExpiresAt = DateTime.tryParse(expiryString);
      }
      print('📱 Loaded tokens from secure storage (mobile/desktop)');
    }
    
    print('Loaded token: ${_token?.substring(0, 20)}..., role: $_currentUserRole');
    if (_tokenExpiresAt != null) {
      print('Token expires at: $_tokenExpiresAt');
    }
  }

  Future<void> _saveToken(String token, String refreshToken, String role, {int? accessExpiresIn}) async {
    _token = token;
    _refreshToken = refreshToken;
    _currentUserRole = role;
    
    if (accessExpiresIn != null) {
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: accessExpiresIn));
    }
    
    if (kIsWeb) {
      // Use plain localStorage on web to avoid encryption
      html.window.localStorage['hockey_access_token'] = token;
      html.window.localStorage['hockey_refresh_token'] = refreshToken;
      html.window.localStorage['hockey_user_role'] = role;
      if (_tokenExpiresAt != null) {
        html.window.localStorage['hockey_token_expires_at'] = _tokenExpiresAt!.toIso8601String();
      }
      print('💾 Saved tokens to localStorage (web)');
    } else {
      // Use secure storage on mobile/desktop
      await secureStorage.write(key: ApiConfig.tokenKey, value: token);
      await secureStorage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
      await secureStorage.write(key: 'user_role', value: role);
      if (_tokenExpiresAt != null) {
        await secureStorage.write(key: 'token_expires_at', value: _tokenExpiresAt!.toIso8601String());
      }
      print('💾 Saved tokens to secure storage (mobile/desktop)');
    }
  }

  Future<void> _clearToken() async {
    if (kIsWeb) {
      // Clear from localStorage on web
      html.window.localStorage.remove('hockey_access_token');
      html.window.localStorage.remove('hockey_refresh_token');
      html.window.localStorage.remove('hockey_user_role');
      html.window.localStorage.remove('hockey_token_expires_at');
      print('🗑️ Cleared tokens from localStorage (web)');
    } else {
      // Clear from secure storage on mobile/desktop
      await secureStorage.delete(key: ApiConfig.tokenKey);
      await secureStorage.delete(key: ApiConfig.refreshTokenKey);
      await secureStorage.delete(key: 'user_role');
      await secureStorage.delete(key: 'token_expires_at');
      print('🗑️ Cleared tokens from secure storage (mobile/desktop)');
    }
    
    _token = null;
    _refreshToken = null;
    _currentUserRole = null;
    _tokenExpiresAt = null;
    _isRefreshing = false;
    _hasNavigatedToLogin = false;
    print('Cleared all tokens');
  }

  Future<void> _loadCurrentUser() async {
    final userJson = await secureStorage.read(key: ApiConfig.currentUserKey);
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
      print('Loaded current user: $_currentUser');
    }
  }

  Future<void> _saveCurrentUser(Map<String, dynamic> userData) async {
    await secureStorage.write(key: ApiConfig.currentUserKey, value: jsonEncode(userData));
    _currentUser = userData;
    print('Saved current user: $userData');
  }

  Future<void> _clearCurrentUser() async {
    await secureStorage.delete(key: ApiConfig.currentUserKey);
    _currentUser = null;
    print('Cleared current user');
  }

  bool _isTokenExpiredSoon() {
    if (_tokenExpiresAt == null) return false;
    
    final now = DateTime.now();
    final timeUntilExpiry = _tokenExpiresAt!.difference(now);
    
    return timeUntilExpiry.inSeconds <= 30;
  }

  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      int attempts = 0;
      while (_isRefreshing && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return _token != null;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      print('No refresh token available');
      await logout();
      return false;
    }

    _isRefreshing = true;
    try {
      print('Refreshing token with refresh token: ${_refreshToken!.substring(0, 20)}...');

      final response = await _dio.post(
        '/api/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_refreshToken',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('Refresh response: ${response.statusCode}, ${response.data}');

      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final tokenInfo = response.data['token_info'] as Map<String, dynamic>?;
        final accessExpiresIn = tokenInfo?['access_expires_in'] as int?;
        
        await _saveToken(
          response.data['access_token'],
          response.data['refresh_token'] ?? _refreshToken!,
          _currentUserRole ?? 'unknown',
          accessExpiresIn: accessExpiresIn,
        );
        
        print('Token refreshed successfully - new expiry: $_tokenExpiresAt');
        return true;
      } else {
        print('Token refresh failed: ${response.statusCode}, ${response.data}');
        await logout();
        return false;
      }
    } catch (e) {
      print('Token refresh error: $e');
      await logout();
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_token != null) {
            options.headers['Authorization'] = 'Bearer $_token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException e, handler) async {
          final options = e.requestOptions;
          
          if (e.response?.statusCode == 401 && !_isRefreshing) {
            print('Got 401, attempting token refresh');
            
            if (await refreshToken()) {
              try {
                final opts = Options(
                  method: options.method,
                  headers: {
                    ...options.headers,
                    'Authorization': 'Bearer $_token',
                  },
                );
                
                final response = await _dio.request(
                  options.path,
                  data: options.data,
                  queryParameters: options.queryParameters,
                  options: opts,
                );
                return handler.resolve(response);
              } catch (retryError) {
                print('Retry request failed: $retryError');
              }
            } else {
              if (!_hasNavigatedToLogin && onTokenExpired != null) {
                _hasNavigatedToLogin = true;
                BuildContext? context = options.extra['context'];
                if (context != null) {
                  onTokenExpired!(context);
                } else {
                  NavigationService().pushNamedAndRemoveUntil('/login');
                }
              }
            }
          }
          
          return handler.next(e);
        },
      ),
    );
  }

  bool isAuthenticated() => _token != null && !_isTokenExpiredSoon();

  Future<void> clearExpiredTokens() async {
    print('Clearing expired tokens from old system...');
    await _clearToken();
    await _clearCurrentUser();
  }

  Future<bool> _shouldClearOldTokens() async {
    if (_token == null) return false;
    
    try {
      final Map<String, dynamic> decodedToken = JwtDecoder.decode(_token!);
      final int expiration = decodedToken['exp'];
      final int issuedAt = decodedToken.containsKey('iat') ? decodedToken['iat'] : 0;
      
      final tokenAge = DateTime.now().millisecondsSinceEpoch ~/ 1000 - issuedAt;
      final timeUntilExpiry = expiration - DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (tokenAge < 3600 && timeUntilExpiry < 3600) {
        print('Detected old system token - will clear');
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error checking token: $e');
      return true;
    }
  }

  Future<bool> login(String username, String password) async {
    try {
      if (await _shouldClearOldTokens()) {
        await clearExpiredTokens();
      }
      
      print('Sending login request for username: $username');
      final response = await _dio.post(
        '/api/auth/login',
        data: {'username': username, 'password': password},
      );
      
      final data = response.data as Map<String, dynamic>;
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      final tokenInfo = data['token_info'] as Map<String, dynamic>?;

      if (accessToken == null || refreshToken == null || user == null) {
        throw Exception('Missing required fields in login response');
      }

      final role = user['role'] as String? ?? 'unknown';
      final accessExpiresIn = tokenInfo?['access_expires_in'] as int?;
      
      await _saveToken(accessToken, refreshToken, role, accessExpiresIn: accessExpiresIn);
      await _saveCurrentUser(user);
      
      // ✅ CRITICAL FIX: Verify token was saved and can be loaded
      await _loadToken(); // Reload to verify
      if (_token == null) {
        throw Exception('Failed to persist authentication token');
      }
      
      _isRefreshing = false;
      _hasNavigatedToLogin = false;
      
      print('✅ Login successful and token verified for user: ${user['username']} (role: $role)');
      print('🔑 Token preview: ${_token!.substring(0, 20)}...');
      
      if (_tokenExpiresAt != null) {
        print('Token will expire at: $_tokenExpiresAt');
        
        final now = DateTime.now();
        final duration = _tokenExpiresAt!.difference(now);
        print('Token duration: ${duration.inHours} hours, ${duration.inMinutes % 60} minutes');
      }
      
      return true;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception('Login failed: $e');
    }
  }

  Future<void> logout() async {
    try {
      await _clearToken();
      await _clearCurrentUser();
      print('Logged out successfully');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  Map<String, dynamic>? getCurrentUser() {
    if (_token == null || _currentUser == null) return null;
    return {
      'token': _token,
      'role': _currentUserRole,
      ..._currentUser!,
    };
  }

  String? getCurrentUserRole() => _currentUserRole;
  bool isCoach() => _currentUserRole == 'coach';
  bool isCoordinator() => _currentUserRole == 'coordinator';
  bool isDirector() => _currentUserRole == 'director';
  bool isAdmin() => _currentUserRole == 'admin';
  bool canManageTeams() => isAdmin() || isDirector() || isCoordinator();
  bool canManageCoaches() => isAdmin() || isDirector();
  bool canManageCoordinators() => isAdmin();
  bool canDeleteTeams() => isAdmin() || isDirector();
  String? getAuthToken() => _token;

  // ==========================================
  // ✅ CRITICAL FIX: IMPROVED HELPER METHODS
  // ==========================================

  /// Helper method to get auth headers with better error handling
  Map<String, String> _getAuthHeaders() {
    final token = getAuthToken();
    if (token == null) {
      print('⚠️ No authentication token available - user may need to log in');
      throw Exception('No authentication token available');
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Handle token expiration
  void _handleTokenExpired([BuildContext? context]) {
    print('🔑 ApiService: Token expired, clearing local auth state');
    
    // Clear the stored token
    clearAuthToken();
    
    // Call the token expired callback if provided
    if (onTokenExpired != null) {
      onTokenExpired!(context);
    }
  }

  /// Clear stored auth token (wrapper for _clearToken)
  Future<void> clearAuthToken() async {
    try {
      await _clearToken();
      print('🧹 ApiService: Auth token cleared');
    } catch (e) {
      print('❌ ApiService: Error clearing auth token: $e');
    }
  }

  // ==========================================
  // ✅ CRITICAL FIX: DEBUG METHODS
  // ==========================================

  /// Debug method to check authentication state
  void debugAuthState() {
    print('=== AUTH DEBUG STATE ===');
    print('Initialized: $_isInitialized');
    print('Token exists: ${_token != null}');
    print('Token preview: ${_token?.substring(0, 20) ?? 'null'}...');
    print('Refresh token exists: ${_refreshToken != null}');
    print('Is authenticated: ${isAuthenticated()}');
    print('Token expires at: $_tokenExpiresAt');
    print('Current user role: $_currentUserRole');
    print('Current user: $_currentUser');
    print('========================');
  }

  // ==========================================
  // ADDED MISSING METHODS
  // ==========================================

  // 1. Add missing getPlayerAnalytics method
  Future<Map<String, dynamic>> getPlayerAnalytics(int playerId, {BuildContext? context}) async {
    // ✅ CRITICAL FIX: Ensure initialization before API calls
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      print('❌ Not authenticated - cannot fetch player analytics');
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load player analytics: ${response.data}');
    } catch (e) {
      print('Error fetching player analytics: $e');
      
      // If it's an auth error, trigger re-login
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // 2. Add missing getPlayerSkatingAnalytics method
  Future<Map<String, dynamic>> getPlayerSkatingAnalytics(int playerId, {BuildContext? context}) async {
    // ✅ CRITICAL FIX: Ensure initialization before API calls
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      print('❌ Not authenticated - cannot fetch player skating analytics');
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/overview',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load player skating analytics: ${response.data}');
    } catch (e) {
      print('Error fetching player skating analytics: $e');
      
      // If it's an auth error, trigger re-login
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // 3. Add missing getHeaders method
  Future<Map<String, String>> getHeaders() async {
    await ensureInitialized();
    return _getAuthHeaders();
  }

  // 4. Add http getter for backward compatibility (returns Dio instance)
  Dio get http => _dio;

  // ==========================================
  // HIRE SYSTEM ENDPOINTS - UPDATED WITH CLEAN URLS
  // ==========================================

  /// Get development plan for a player
  Future<Map<String, dynamic>?> getDevelopmentPlan(int playerId) async {
    try {
      await ensureInitialized();
      
      // Add retry logic for auth failures
      return await _retryOnAuthFailure(() async {
        if (!isAuthenticated()) {
          throw Exception('Authentication required. Please log in again.');
        }
        
        debugPrint('API: Getting development plan for player $playerId');
        
        final response = await _dio.get(
          '/api/development_plans/player/$playerId',
          options: Options(headers: _getAuthHeaders()),
        );
        
        return _handleResponse(response);
      });
    } catch (e) {
      debugPrint('API Error getting development plan: $e');
      rethrow;
    }
  }

  // Add this helper method
  Future<T> _retryOnAuthFailure<T>(Future<T> Function() operation) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        return await operation();
      } catch (e) {
        if (e.toString().contains('Authentication required') && attempt < 2) {
          // Wait briefly and refresh token
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
          final refreshed = await refreshToken();
          if (!refreshed) {
            rethrow;
          }
          continue; // Retry
        }
        rethrow;
      }
    }
    throw Exception('Max retry attempts exceeded');
  }

  /// Create a new development plan
  Future<Map<String, dynamic>?> createDevelopmentPlan(
    int playerId, 
    Map<String, dynamic> planData,
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot create development plan');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Creating development plan for player $playerId');
      
      final response = await _dio.post(
        '/api/development_plans/player/$playerId', // ✅ CLEAN URL
        data: planData,
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error creating development plan: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Update an existing development plan
  Future<Map<String, dynamic>?> updateDevelopmentPlan(
    int playerId, 
    Map<String, dynamic> planData,
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot update development plan');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Updating development plan for player $playerId');
      
      final response = await _dio.put(
        '/api/development_plans/player/$playerId', // ✅ CLEAN URL
        data: planData,
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error updating development plan: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Delete a development plan
  Future<Map<String, dynamic>?> deleteDevelopmentPlan(int playerId) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot delete development plan');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Deleting development plan for player $playerId');
      
      final response = await _dio.delete(
        '/api/development_plans/player/$playerId', // ✅ CLEAN URL
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error deleting development plan: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Get mentorship notes for a player's development plan
  Future<Map<String, dynamic>?> getMentorshipNotes(int playerId, {BuildContext? context}) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch mentorship notes');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting mentorship notes for player $playerId');
      
      final response = await _dio.get(
        '/api/development_plans/player/$playerId/mentorship-notes', // ✅ CLEAN URL
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting mentorship notes: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Update mentorship notes for a player's development plan
  Future<Map<String, dynamic>?> updateMentorshipNotes(
    int playerId, 
    Map<String, dynamic> notesData,
    {BuildContext? context}
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot update mentorship notes');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Updating mentorship notes for player $playerId');
      
      final response = await _dio.patch(
        '/api/development_plans/player/$playerId/mentorship-notes', // ✅ CLEAN URL
        data: notesData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error updating mentorship notes: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get assessment history for a player
  Future<List<Map<String, dynamic>>> getAssessmentHistory(
    int playerId, {
    int? limit,
    int offset = 0,
    String? assessmentType,
    String? dateFrom,
    String? dateTo,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch assessment history');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting assessment history for player $playerId');
      
      final queryParams = <String, dynamic>{
        'offset': offset.toString(),
      };
      if (limit != null) queryParams['limit'] = limit.toString();
      if (assessmentType != null) queryParams['assessment_type'] = assessmentType;
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      
      final response = await _dio.get(
        '/api/development_plans/player/$playerId/assessment-history', // ✅ CLEAN URL
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      final result = _handleResponse(response);
      if (result != null && result['assessments'] is List) {
        return List<Map<String, dynamic>>.from(result['assessments']);
      }
      return [];
    } catch (e) {
      debugPrint('API Error getting assessment history: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Add new assessment to player's history
  Future<Map<String, dynamic>?> addAssessmentToHistory(
    int playerId,
    Map<String, dynamic> assessmentData,
    {BuildContext? context}
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot add assessment to history');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Adding assessment to history for player $playerId');
      
      final response = await _dio.post(
        '/api/development_plans/player/$playerId/assessment-history', // ✅ CLEAN URL
        data: assessmentData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error adding assessment to history: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Calculate HIRE scores from ratings
  Future<Map<String, dynamic>?> calculateHIREScores(
    int playerId, 
    Map<String, double> ratings, {
    bool saveToPlan = true,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot calculate HIRE scores');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Calculating HIRE scores for player $playerId');
      debugPrint('Ratings: ${ratings.length} provided, saveToPlan: $saveToPlan');
      
      final requestData = {
        'ratings': ratings,
        'save_to_plan': saveToPlan,
      };
      
      final response = await _dio.post(
        '/api/development_plans/player/$playerId/hire-scores', // ✅ CLEAN URL
        data: requestData,
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error calculating HIRE scores: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Get current HIRE scores for a player
  Future<Map<String, dynamic>?> getHIREScores(
    int playerId, {
    bool includeInterpretation = false,
    bool includeHistory = false,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch HIRE scores');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting HIRE scores for player $playerId');
      
      final queryParams = <String, String>{};
      if (includeInterpretation) queryParams['include_interpretation'] = 'true';
      if (includeHistory) queryParams['include_history'] = 'true';
      
      final uri = Uri.parse('$baseUrl/api/development_plans/player/$playerId/hire-scores') // ✅ CLEAN URL
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      
      final response = await _dio.getUri(
        uri,
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting HIRE scores: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Recalculate HIRE scores using current ratings
  Future<Map<String, dynamic>?> recalculateHIREScores(int playerId) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot recalculate HIRE scores');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Recalculating HIRE scores for player $playerId');
      
      final response = await _dio.post(
        '/api/development_plans/player/$playerId/hire-scores/recalculate', // ✅ CLEAN URL
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error recalculating HIRE scores: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Get all development plans (for coordinators/directors)
  Future<List<Map<String, dynamic>>> getAllDevelopmentPlans({
    int? limit,
    int offset = 0,
    String? status,
    int? teamId,
    String? ageGroup,
    String? position,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch all development plans');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting all development plans');
      
      final queryParams = <String, dynamic>{
        'offset': offset.toString(),
      };
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      if (teamId != null) queryParams['team_id'] = teamId.toString();
      if (ageGroup != null) queryParams['age_group'] = ageGroup;
      if (position != null) queryParams['position'] = position;
      
      final response = await _dio.get(
        '/api/development_plans/all', // ✅ CLEAN URL
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      final result = _handleResponse(response);
      if (result != null && result['plans'] is List) {
        return List<Map<String, dynamic>>.from(result['plans']);
      }
      return [];
    } catch (e) {
      debugPrint('API Error getting all development plans: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get development plans by team
  Future<List<Map<String, dynamic>>> getTeamDevelopmentPlans(
    int teamId, {
    String? status,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch team development plans');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting development plans for team $teamId');
      
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;
      
      final response = await _dio.get(
        '/api/development_plans/team/$teamId', // ✅ CLEAN URL
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      final result = _handleResponse(response);
      if (result != null && result['plans'] is List) {
        return List<Map<String, dynamic>>.from(result['plans']);
      }
      return [];
    } catch (e) {
      debugPrint('API Error getting team development plans: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Check API health
  Future<Map<String, dynamic>?> checkHealth() async {
    try {
      await ensureInitialized();
      
      debugPrint('API: Checking HIRE system health');
      
      final response = await _dio.get(
        '/api/development_plans/health', // ✅ CLEAN URL
        options: Options(
          headers: _getAuthHeaders(),
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error checking health: $e');
      rethrow;
    }
  }

  /// Test connection to HIRE API
  Future<bool> testConnection() async {
    try {
      final health = await checkHealth();
      return health != null && health['status'] == 'healthy';
    } catch (e) {
      debugPrint('HIRE connection test failed: $e');
      return false;
    }
  }

  /// Handle HTTP response and parse JSON
  Map<String, dynamic>? _handleResponse(Response response) {
    debugPrint('API Response: ${response.statusCode} - ${response.data?.toString().length ?? 0} bytes');
    
    // Handle different status codes
    switch (response.statusCode) {
      case 200:
      case 201:
        // Success - parse JSON
        try {
          if (response.data is Map<String, dynamic>) {
            return response.data as Map<String, dynamic>;
          } else if (response.data is String) {
            return jsonDecode(response.data) as Map<String, dynamic>;
          } else {
            return response.data as Map<String, dynamic>;
          }
        } catch (e) {
          debugPrint('Error parsing JSON response: $e');
          throw Exception('Invalid JSON response');
        }
      
      case 400:
        // Bad Request
        try {
          final errorData = response.data as Map<String, dynamic>;
          throw Exception(
            errorData['message'] ?? 'Bad request',
          );
        } catch (e) {
          throw Exception('Bad request');
        }
      
      case 401:
        // Unauthorized
        throw Exception('Unauthorized - please check credentials');
      
      case 403:
        // Forbidden
        throw Exception('Access forbidden');
      
      case 404:
        // Not Found
        return null; // Return null for not found instead of throwing
      
      case 409:
        // Conflict
        try {
          final errorData = response.data as Map<String, dynamic>;
          throw Exception(
            errorData['message'] ?? 'Conflict',
          );
        } catch (e) {
          throw Exception('Conflict');
        }
      
      case 500:
      case 502:
      case 503:
      case 504:
        // Server errors
        throw Exception('Server error - please try again later');
      
      default:
        throw Exception('Unexpected response: ${response.statusCode}');
    }
  }

  /// Calculate HIRE scores for all players on a team
  Future<Map<String, dynamic>?> calculateTeamHIREScores(int teamId) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot calculate team HIRE scores');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Calculating team HIRE scores for team $teamId');
      
      final response = await _dio.post(
        '/api/teams/$teamId/hire-scores/calculate',
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error calculating team HIRE scores: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Get API information
  Future<Map<String, dynamic>?> getApiInfo() async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch API info');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting API info');
      
      final response = await _dio.get(
        '/api/info',
        options: Options(headers: _getAuthHeaders()),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting API info: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      rethrow;
    }
  }

  /// Update development plan status (e.g., active, completed, archived)
  Future<Map<String, dynamic>?> updateDevelopmentPlanStatus(
    int playerId,
    String status, {
    String? notes,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot update development plan status');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Updating development plan status for player $playerId to $status');
      
      final requestData = {
        'status': status,
        if (notes != null) 'status_notes': notes,
      };
      
      final response = await _dio.patch(
        '/api/development_plans/player/$playerId/status',
        data: requestData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error updating development plan status: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get HIRE assessment templates for different age groups
  Future<Map<String, dynamic>?> getHIREAssessmentTemplates({
    String? ageGroup,
    String? position,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch HIRE assessment templates');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting HIRE assessment templates');
      
      final queryParams = <String, String>{};
      if (ageGroup != null) queryParams['age_group'] = ageGroup;
      if (position != null) queryParams['position'] = position;
      
      final response = await _dio.get(
        '/api/hire/assessment-templates',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting HIRE assessment templates: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get HIRE benchmarks for comparison
  Future<Map<String, dynamic>?> getHIREBenchmarks({
    String ageGroup = 'youth_15_18',
    String position = 'forward',
    String level = 'competitive',
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch HIRE benchmarks');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting HIRE benchmarks for $ageGroup $position at $level level');
      
      final queryParams = {
        'age_group': ageGroup,
        'position': position,
        'level': level,
      };
      
      final response = await _dio.get(
        '/api/hire/benchmarks',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting HIRE benchmarks: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get HIRE analytics for a player over time
  Future<Map<String, dynamic>?> getHIREAnalytics(
    int playerId, {
    String? dateFrom,
    String? dateTo,
    bool includeComparison = true,
    bool includeRecommendations = true,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch HIRE analytics');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting HIRE analytics for player $playerId');
      
      final queryParams = <String, String>{
        'include_comparison': includeComparison.toString(),
        'include_recommendations': includeRecommendations.toString(),
      };
      if (dateFrom != null) queryParams['date_from'] = dateFrom;
      if (dateTo != null) queryParams['date_to'] = dateTo;
      
      final response = await _dio.get(
        '/api/players/$playerId/hire-analytics',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting HIRE analytics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Generate HIRE development recommendations
  Future<Map<String, dynamic>?> generateHIRERecommendations(
    int playerId, {
    Map<String, double>? currentScores,
    String? focusArea,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot generate HIRE recommendations');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Generating HIRE recommendations for player $playerId');
      
      final requestData = <String, dynamic>{};
      if (currentScores != null) requestData['current_scores'] = currentScores;
      if (focusArea != null) requestData['focus_area'] = focusArea;
      
      final response = await _dio.post(
        '/api/players/$playerId/hire-recommendations',
        data: requestData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error generating HIRE recommendations: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get team HIRE overview and rankings
  Future<Map<String, dynamic>?> getTeamHIREOverview(
    int teamId, {
    bool includeIndividualScores = true,
    bool includeRankings = true,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch team HIRE overview');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting team HIRE overview for team $teamId');
      
      final queryParams = {
        'include_individual_scores': includeIndividualScores.toString(),
        'include_rankings': includeRankings.toString(),
      };
      
      final response = await _dio.get(
        '/api/teams/$teamId/hire-overview',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error getting team HIRE overview: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Export HIRE data for reporting
  Future<Map<String, dynamic>?> exportHIREData(
    int playerId, {
    String format = 'pdf',
    bool includeHistory = true,
    bool includeRecommendations = true,
    bool includeComparison = true,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot export HIRE data');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Exporting HIRE data for player $playerId in $format format');
      
      final queryParams = {
        'format': format,
        'include_history': includeHistory.toString(),
        'include_recommendations': includeRecommendations.toString(),
        'include_comparison': includeComparison.toString(),
      };
      
      final response = await _dio.get(
        '/api/players/$playerId/hire-export',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          responseType: format == 'pdf' ? ResponseType.bytes : ResponseType.json,
        ),
      );
      
      if (format == 'pdf') {
        return {
          'success': true,
          'data': response.data,
          'content_type': 'application/pdf',
        };
      } else {
        return _handleResponse(response);
      }
    } catch (e) {
      debugPrint('API Error exporting HIRE data: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Bulk update HIRE scores for multiple players
  Future<Map<String, dynamic>?> bulkUpdateHIREScores(
    List<Map<String, dynamic>> playerScores, {
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot bulk update HIRE scores');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Bulk updating HIRE scores for ${playerScores.length} players');
      
      final requestData = {
        'player_scores': playerScores,
      };
      
      final response = await _dio.post(
        '/api/hire/bulk-update',
        data: requestData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error bulk updating HIRE scores: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Get HIRE assessment schedule for a player
  Future<List<Map<String, dynamic>>> getHIREAssessmentSchedule(
    int playerId, {
    String? startDate,
    String? endDate,
    BuildContext? context,
  }) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot fetch HIRE assessment schedule');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Getting HIRE assessment schedule for player $playerId');
      
      final queryParams = <String, String>{};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      
      final response = await _dio.get(
        '/api/players/$playerId/hire-schedule',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      final result = _handleResponse(response);
      if (result != null && result['assessments'] is List) {
        return List<Map<String, dynamic>>.from(result['assessments']);
      }
      return [];
    } catch (e) {
      debugPrint('API Error getting HIRE assessment schedule: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Schedule a HIRE assessment
  Future<Map<String, dynamic>?> scheduleHIREAssessment(
    int playerId,
    Map<String, dynamic> assessmentData,
    {BuildContext? context}
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot schedule HIRE assessment');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Scheduling HIRE assessment for player $playerId');
      
      final response = await _dio.post(
        '/api/players/$playerId/hire-schedule',
        data: assessmentData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error scheduling HIRE assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Update HIRE assessment schedule
  Future<Map<String, dynamic>?> updateHIREAssessmentSchedule(
    int playerId,
    int assessmentId,
    Map<String, dynamic> updateData,
    {BuildContext? context}
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot update HIRE assessment schedule');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Updating HIRE assessment schedule $assessmentId for player $playerId');
      
      final response = await _dio.put(
        '/api/players/$playerId/hire-schedule/$assessmentId',
        data: updateData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error updating HIRE assessment schedule: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Delete HIRE assessment from schedule
  Future<Map<String, dynamic>?> deleteHIREAssessmentSchedule(
    int playerId,
    int assessmentId,
    {BuildContext? context}
  ) async {
    try {
      await ensureInitialized();
      
      if (!isAuthenticated()) {
        print('❌ Not authenticated - cannot delete HIRE assessment schedule');
        throw Exception('Authentication required. Please log in again.');
      }
      
      debugPrint('API: Deleting HIRE assessment schedule $assessmentId for player $playerId');
      
      final response = await _dio.delete(
        '/api/players/$playerId/hire-schedule/$assessmentId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      return _handleResponse(response);
    } catch (e) {
      debugPrint('API Error deleting HIRE assessment schedule: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // HIRE SYSTEM - HELPER METHODS
  // ==========================================

  /// Validate development plan data before sending to server
  Map<String, dynamic> validateDevelopmentPlan(Map<String, dynamic> planData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required fields validation
    if (planData['player_id'] == null) {
      errors.add('Player ID is required');
    }
    
    if (planData['goals'] == null || (planData['goals'] as List).isEmpty) {
      errors.add('At least one development goal is required');
    }
    
    // Optional but recommended fields
    if (planData['assessment_date'] == null) {
      warnings.add('Assessment date not specified');
    }
    
    if (planData['target_completion_date'] == null) {
      warnings.add('Target completion date not specified');
    }
    
    // Validate goals structure
    if (planData['goals'] is List) {
      final goals = planData['goals'] as List;
      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        if (goal is Map) {
          if (goal['category'] == null || goal['category'].toString().trim().isEmpty) {
            errors.add('Goal ${i + 1}: Category is required');
          }
          if (goal['description'] == null || goal['description'].toString().trim().isEmpty) {
            errors.add('Goal ${i + 1}: Description is required');
          }
          if (goal['priority'] == null) {
            warnings.add('Goal ${i + 1}: Priority not specified');
          }
        } else {
          errors.add('Goal ${i + 1}: Invalid goal structure');
        }
      }
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }

  /// Format HIRE scores for display
  Map<String, dynamic> formatHIREScoresForDisplay(Map<String, dynamic> scores) {
    final formatted = <String, dynamic>{};
    
    // Format category scores
    if (scores['categoryScores'] != null) {
      final categoryScores = scores['categoryScores'] as Map<String, dynamic>;
      formatted['categories'] = {
        'H': {
          'score': categoryScores['H'],
          'name': 'Humility / Hardwork',
          'description': 'Character foundation and work ethic',
        },
        'I': {
          'score': categoryScores['I'],
          'name': 'Initiative / Integrity',
          'description': 'Leadership and moral character',
        },
        'R': {
          'score': categoryScores['R'],
          'name': 'Responsibility / Respect',
          'description': 'Accountability and respect for others',
        },
        'E': {
          'score': categoryScores['E'],
          'name': 'Enthusiasm',
          'description': 'Passion and positive energy',
        },
      };
    }
    
    // Format overall score with interpretation
    if (scores['overallScore'] != null) {
      final overallScore = scores['overallScore'] as double;
      formatted['overall'] = {
        'score': overallScore,
        'interpretation': _getScoreInterpretation(overallScore),
        'percentile': _getScorePercentile(overallScore),
      };
    }
    
    // Add calculation timestamp
    formatted['lastUpdated'] = scores['calculatedAt'] ?? DateTime.now().toIso8601String();
    
    return formatted;
  }

  /// Get score interpretation text
  String _getScoreInterpretation(double score) {
    if (score >= 9.0) return 'Elite';
    if (score >= 8.0) return 'Strong';
    if (score >= 7.0) return 'Good';
    if (score >= 6.0) return 'Average';
    if (score >= 5.0) return 'Below Average';
    return 'Concerning';
  }

  /// Get approximate percentile for score
  int _getScorePercentile(double score) {
    // These are approximate percentiles based on normal distribution
    if (score >= 9.5) return 99;
    if (score >= 9.0) return 95;
    if (score >= 8.5) return 90;
    if (score >= 8.0) return 80;
    if (score >= 7.5) return 70;
    if (score >= 7.0) return 60;
    if (score >= 6.5) return 50;
    if (score >= 6.0) return 40;
    if (score >= 5.5) return 30;
    if (score >= 5.0) return 20;
    if (score >= 4.5) return 10;
    return 5;
  }

  /// Check if user has permission to access HIRE features
  bool canAccessHIREFeatures() {
    // Check user role and permissions
    final userRole = getCurrentUserRole();
    return userRole != null && ['coach', 'coordinator', 'director', 'admin'].contains(userRole);
  }

  /// Check if user can modify HIRE data
  bool canModifyHIREData() {
    final userRole = getCurrentUserRole();
    return userRole != null && ['coordinator', 'director', 'admin'].contains(userRole);
  }

  /// Check if user can view all development plans
  bool canViewAllDevelopmentPlans() {
    final userRole = getCurrentUserRole();
    return userRole != null && ['coordinator', 'director', 'admin'].contains(userRole);
  }

  // ==========================================
  // USER MANAGEMENT
  // ==========================================

  Future<Map<String, dynamic>> registerUser(Map<String, dynamic> userData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('Register user payload: ${jsonEncode(userData)}');
      final cleanedData = {
        'username': userData['username'],
        'password': userData['password'],
        'name': userData['name'],
        'email': userData['email'],
        'role': userData['role'] ?? 'coach',
      };
      final response = await _dio.post(
        '/api/users',
        data: cleanedData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 201) return response.data;
      throw Exception('Failed to register user: ${response.data}');
    } catch (e) {
      print('Error registering user: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUser(int userId, Map<String, dynamic> userData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.put(
        '/api/users/$userId',
        data: userData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to update user: ${response.data}');
    } catch (e) {
      print('Error updating user: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCurrentUserProfile({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/auth/me',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        await _saveCurrentUser(response.data);
        return response.data;
      }
      throw Exception('Failed to get user profile: ${response.data}');
    } catch (e) {
      print('Error fetching user profile: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<User>> fetchUsersByRole(String role, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/users/$role',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => User.fromJson(json)).toList();
      }
      throw Exception('Failed to load users: ${response.data}');
    } catch (e) {
      print('Error fetching users by role: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Delete a user by ID (admin only)
  Future<Map<String, dynamic>> deleteUser(int userId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('🗑️ ApiService: Deleting user with ID: $userId');
      print('🔍 Current user role: $_currentUserRole');
      
      final response = await _dio.delete(
        '/api/users/$userId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('📡 ApiService: Delete user response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ ApiService: User deleted successfully');
        return response.data ?? {'success': true, 'message': 'User deleted successfully'};
      } else if (response.statusCode == 401) {
        print('🔑 ApiService: 401 Unauthorized - token expired or invalid');
        throw Exception('Your session has expired. Please log in again.');
      } else if (response.statusCode == 403) {
        print('🚫 ApiService: 403 Forbidden - insufficient permissions');
        final errorMessage = response.data?['message'] ?? 'You do not have permission to delete this user';
        throw Exception(errorMessage);
      } else if (response.statusCode == 404) {
        print('🔍 ApiService: 404 Not Found - user does not exist');
        throw Exception('User not found or has already been deleted');
      } else {
        print('❌ ApiService: Unexpected status code: ${response.statusCode}');
        final errorMessage = response.data?['message'] ?? 'Failed to delete user';
        throw Exception(errorMessage);
      }
    } on DioException catch (e) {
      print('❌ ApiService: DioException in deleteUser: ${e.message}');
      
      if (e.type == DioExceptionType.connectionTimeout || 
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw Exception('Request timeout. Please try again.');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Network connection error. Please check your internet connection.');
      } else if (e.response?.statusCode == 401) {
        _handleTokenExpired(context);
        throw Exception('Your session has expired. Please log in again.');
      } else if (e.response?.statusCode == 403) {
        final errorMessage = e.response?.data?['message'] ?? 'You do not have permission to delete this user';
        throw Exception(errorMessage);
      } else if (e.response?.statusCode == 404) {
        throw Exception('User not found or has already been deleted');
      } else {
        final errorMessage = e.response?.data?['message'] ?? e.message ?? 'Failed to delete user';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('❌ ApiService: Unexpected error in deleteUser: $e');
      throw Exception('An unexpected error occurred while deleting the user');
    }
  }

  // ==========================================
  // PLAYER MANAGEMENT
  // ==========================================

  Future<Player> registerPlayer(Map<String, dynamic> playerData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/players',
        data: playerData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 201) return Player.fromJson(response.data);
      throw Exception('Failed to register player: ${response.data}');
    } catch (e) {
      print('Error registering player: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<Player>> fetchPlayers({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('Fetching players from /api/players');
      final response = await _dio.get(
        '/api/players',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      print('Players response status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => Player.fromJson(json)).toList();
      }
      throw Exception('Failed to load players: ${response.data}');
    } catch (e) {
      print('Error fetching players: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Player> updatePlayer(int playerId, Map<String, dynamic> playerData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.put(
        '/api/players/$playerId',
        data: playerData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return Player.fromJson(response.data);
      throw Exception('Failed to update player: ${playerId}');
    } catch (e) {
      print('Error updating player: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // TEAM MANAGEMENT
  // ==========================================

  Future<List<Team>> fetchTeams({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/teams',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => Team.fromJson(json)).toList();
      }
      throw Exception('Failed to load teams: ${response.data}');
    } catch (e) {
      print('Error fetching teams: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Team> fetchTeam(int teamId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/teams/$teamId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return Team.fromJson(response.data);
      throw Exception('Failed to load team: ${response.data}');
    } catch (e) {
      print('Error fetching team: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Team> createTeam(Map<String, dynamic> teamData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/teams',
        data: teamData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 201) return Team.fromJson(response.data);
      throw Exception('Failed to create team: ${response.data}');
    } catch (e) {
      print('Error creating team: $e}');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Team> updateTeam(int teamId, Map<String, dynamic> teamData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.put(
        '/api/teams/$teamId',
        data: teamData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return Team.fromJson(response.data);
      throw Exception('Failed to update team: ${response.data}');
    } catch (e) {
      print('Error updating team: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<void> deleteTeam(int teamId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.delete(
        '/api/teams/$teamId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete team: ${response.data}');
      }
    } catch (e) {
      print('Error deleting team: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<Player>> fetchTeamPlayers(int teamId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/teams/$teamId/players',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => Player.fromJson(json)).toList();
      }
      throw Exception('Failed to load team players: ${response.data}');
    } catch (e) {
      print('Error fetching team players: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // SHOT MANAGEMENT & ANALYTICS
  // ==========================================

  Future<List<Shot>> fetchShots(int playerId, {Map<String, dynamic>? queryParameters, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    print('Fetching shots for playerId: $playerId, URL: $baseUrl/api/shots/$playerId, Params: $queryParameters');
    try {
      final response = await _dio.get(
        '/api/shots/$playerId',
        queryParameters: queryParameters,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      print('Shots response status: ${response.statusCode}');
      if (response.statusCode == 200) {
        if (queryParameters?['group_by_assessments'] == 'true' && queryParameters?['source'] == 'assessment') {
          final data = response.data;
          if (data['grouped_by_assessments'] == true) {
            final assessmentGroups = data['assessment_groups'] as List;
            final shots = <Shot>[];
            for (var group in assessmentGroups) {
              final groupShots = (group['shots'] as List).map((json) => Shot.fromJson(json)).toList();
              shots.addAll(groupShots);
            }
            print('Parsed ${shots.length} shots from ${assessmentGroups.length} assessment groups for playerId: $playerId');
            return shots;
          }
        }
        final shots = (response.data as List).map((json) => Shot.fromJson(json)).toList();
        print('Parsed ${shots.length} shots for playerId: $playerId');
        return shots;
      }
      throw Exception('Failed to load shots: ${response.data['error'] ?? response.data}');
    } catch (e) {
      print('Error fetching shots: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<void> linkShotsToWorkout(List<int> shotIds, int workoutId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.put(
        '/api/shots/update-workout-link',
        data: {
          'shot_ids': shotIds,
          'workout_id': workoutId,
        },
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to link shots to workout: ${response.data}');
      }
    } catch (e) {
      print('Error linking shots to workout: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> addShot(Map<String, dynamic> shotData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      if (shotData['source'] == 'assessment' && (shotData['assessment_id'] == null || shotData['assessment_id'].toString().isEmpty)) {
        throw Exception('Assessment shots must have a valid assessment_id');
      }
      print('Adding shot: $shotData');
      final response = await _dio.post(
        '/api/shots',
        data: shotData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      print('Shot creation response: ${response.data}');
      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to add shot: ${response.data}');
    } catch (e) {
      print('Error adding shot: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<void> deleteShot(int shotId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.delete(
        '/api/shots/$shotId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        print('Deleted shot $shotId');
        return;
      }
      throw Exception('Failed to delete shot: ${response.data}');
    } catch (e) {
      print('Error deleting shot: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getShotsByAssessment(
    String assessmentId, {
    bool includeGroupIndex = false,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/shots/assessment/$assessmentId',
        queryParameters: {
          'include_group_index': includeGroupIndex.toString(),
        },
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data['shots'] as List).cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to get shots: ${response.data}');
    } catch (e) {
      print('Error getting shots by assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEnhancedBaselineResults(
    String baselineAssessmentId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final basicResults = await getShotAssessmentResults(baselineAssessmentId, context: context);
      
      final shotLevelData = await getShotsByAssessment(
        baselineAssessmentId,
        includeGroupIndex: true,
        context: context,
      );
      
      final enhancedResults = Map<String, dynamic>.from(basicResults);
      enhancedResults['shotLevelData'] = shotLevelData;
      
      return enhancedResults;
    } catch (e) {
      print('Error getting enhanced baseline results: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // SHOT ASSESSMENT MANAGEMENT
  // ==========================================

  Future<Map<String, dynamic>> createShotAssessmentWithShots({
    required Map<String, dynamic> assessmentData,
    required List<Map<String, dynamic>> shots,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      print('❌ No access token available');
      throw Exception('Authentication required. Please log in again.');
    }

    try {
      final sanitizedAssessment = Map<String, dynamic>.from(assessmentData);
      
      // ✅ CRITICAL FIX: Ensure ID is preserved and properly set
      sanitizedAssessment['id'] = sanitizedAssessment['id'] ?? 
                                  sanitizedAssessment['assessmentId'] ?? 
                                  DateTime.now().millisecondsSinceEpoch.toString();
      
      // Clean up legacy field names
      sanitizedAssessment.remove('assessmentId'); // Remove if exists to avoid confusion
      
      // Ensure player_id is set correctly
      sanitizedAssessment['player_id'] = sanitizedAssessment['player_id'] ?? sanitizedAssessment['playerId'];
      sanitizedAssessment.remove('playerId'); // Clean up
      
      // ✅ FIXED: Ensure all required fields are present
      sanitizedAssessment['assessment_type'] = sanitizedAssessment['assessment_type'] ?? 'accuracy';
      sanitizedAssessment['title'] = sanitizedAssessment['title'] ?? 'Shot Assessment';
      sanitizedAssessment['date'] = sanitizedAssessment['date'] ?? DateTime.now().toIso8601String();
      
      // Handle groups data
      if (sanitizedAssessment['assessment_config'] != null && 
          sanitizedAssessment['assessment_config']['groups'] != null) {
        // Groups are in assessment_config, keep as is
      } else if (sanitizedAssessment['groups'] != null) {
        // Move groups to assessment_config
        sanitizedAssessment['assessment_config'] = {
          'groups': sanitizedAssessment['groups']
        };
        sanitizedAssessment.remove('groups');
      }

      final sanitizedShots = shots.map((shot) {
        return {
          'player_id': shot['player_id'] ?? sanitizedAssessment['player_id'], // ✅ FIXED: Ensure player_id is set
          'zone': shot['zone'] as String? ?? '0',
          'type': shot['type'] as String? ?? 'Wrist Shot', // ✅ FIXED: Use full name
          'success': shot['success'] as bool? ?? false,
          'outcome': shot['outcome'] as String? ?? (shot['success'] as bool? ?? false ? 'Goal' : 'Miss'),
          'date': shot['date'] as String? ?? DateTime.now().toIso8601String(),
          'source': shot['source'] as String? ?? 'assessment',
          'assessment_id': sanitizedAssessment['id'], // ✅ FIXED: Use the correct ID field
          'power': shot['power'],
          'quick_release': shot['quick_release'],
          'group_index': shot['group_index'],
          'group_id': shot['group_id'],
          'intended_zone': shot['intended_zone'] as String?,
          'intended_direction': shot['intended_direction'] as String?,
        };
      }).toList();

      print('Sending request to /api/shots/batch with payload:');
      print('Assessment ID: ${sanitizedAssessment['id']}'); // ✅ ADDED: Log the actual ID being sent
      print('Assessment Type: ${sanitizedAssessment['assessment_type']}');
      print('Player ID: ${sanitizedAssessment['player_id']}');
      print('Shots count: ${sanitizedShots.length}');

      final response = await _dio.post(
        '/api/shots/batch',
        data: {
          'assessment': sanitizedAssessment,
          'shots': sanitizedShots,
          'create_assessment': true, // ✅ CORRECT: This tells backend to create assessment
        },
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      print('Response from /api/shots/batch: ${response.statusCode}');
      print('Response assessment ID: ${response.data?['assessment']?['id']}'); // ✅ ADDED: Log returned ID

      if (response.statusCode == 201) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create assessment: ${response.statusCode}, ${response.data}');
      }
    } catch (e) {
      print('Error creating assessment: $e');
      if (e is DioException && e.response != null) {
        print('Server error details: ${e.response?.statusCode}, ${e.response?.data}');
        if (e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          String errorMsg = 'Invalid request data';
          
          if (errorData is Map) {
            errorMsg = errorData['error']?['message'] ?? 
                      errorData['msg'] ?? 
                      errorData['message'] ?? 
                      errorMsg;
          }
          
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save: $errorMsg')),
            );
          }
          throw Exception('Bad request: $errorMsg');
        } else if (e.response?.statusCode == 401) {
          _handleTokenExpired(context);
          throw Exception('Authentication required. Please log in again.');
        }
      }
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<ShotAssessment> getShotAssessment(String assessmentId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/shots/assessments/$assessmentId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return ShotAssessment.fromJson(response.data);
      }
      throw Exception('Failed to get shot assessment: ${response.data}');
    } catch (e) {
      print('Error getting shot assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<ShotAssessment>> getPlayerShotAssessments(int playerId, {String? status, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('Fetching assessments for playerId: $playerId, status: $status');
      final response = await _dio.get(
        '/api/shots/assessments/player/$playerId',
        queryParameters: status != null ? {'status': status} : null,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      print('Assessments response status: ${response.statusCode}, data: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data as List;
        final assessments = data.map((json) => ShotAssessment.fromJson(json)).toList();
        print('Parsed ${assessments.length} assessments for playerId: $playerId');
        return assessments;
      }
      throw Exception('Failed to get player shot assessments: ${response.data}');
    } catch (e) {
      print('Error getting player shot assessments: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<void> completeShotAssessment(String assessmentId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('Completing assessment with ID: $assessmentId');
      final response = await _dio.put(
        '/api/shots/assessments/$assessmentId/complete',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      print('Assessment completion response: ${response.data}');
      if (response.statusCode != 200) {
        throw Exception('Failed to complete assessment: ${response.data}');
      }
    } catch (e) {
      print('Error completing assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getShotAssessmentResults(String assessmentId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/shots/assessments/$assessmentId/results',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to get shot assessment results: ${response.data}');
    } catch (e) {
      print('Error getting shot assessment results: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveShotAssessment(Map<String, dynamic> assessmentData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final shots = assessmentData['shots'] as List<dynamic>? ?? [];
      if (shots.isEmpty) {
        throw Exception('No shots provided in assessment');
      }

      final assessment = {
        'player_id': assessmentData['player_id'],
        'assessment_type': assessmentData['assessment_type'] ?? 'standard',
        'title': assessmentData['title'] ?? 'Shot Assessment',
        'description': assessmentData['description'],
        'assessment_config': assessmentData['assessment_config'] ?? {},
      };

      final response = await createShotAssessmentWithShots(
        assessmentData: assessment,
        shots: shots.map((shot) => {
              ...shot as Map<String, dynamic>,
              'player_id': assessmentData['player_id'],
              'source': 'assessment',
              'date': shot['timestamp'] ?? DateTime.now().toIso8601String(),
            }).toList(),
        context: context,
      );

      print('Saved assessment with ${shots.length} shots');
      return response;
    } catch (e) {
      print('Error saving shot assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PHASE 2: NEW SESSION-BASED SKATING API
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
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      // ✅ NORMALIZE AGE GROUP to database-compatible format
      String normalizedAgeGroup;
      switch (ageGroup.toLowerCase().trim()) {
        case 'adult':
        case 'adults':
          normalizedAgeGroup = 'adult';
          break;
        case 'youth_15_18':
        case 'youth 15-18':
        case '15-18':
        case 'youth_15_to_18':
          normalizedAgeGroup = 'youth_15_18';
          break;
        case 'youth_11_14':
        case 'youth 11-14':
        case '11-14':
        case 'youth_11_to_14':
          normalizedAgeGroup = 'youth_11_14';
          break;
        case 'youth_8_10':
        case 'youth 8-10':
        case '8-10':
        case 'youth_8_to_10':
          normalizedAgeGroup = 'youth_8_10';
          break;
        case 'unknown':
        case '':
          normalizedAgeGroup = 'youth_15_18'; // Safe fallback
          break;
        default:
          print('⚠️ Unrecognized age group: "$ageGroup", using fallback');
          normalizedAgeGroup = 'youth_15_18';
      }

      // ✅ NORMALIZE POSITION to database-compatible format
      String normalizedPosition;
      switch (position.toLowerCase().trim()) {
        case 'forward':
        case 'forwards':
        case 'f':
          normalizedPosition = 'forward';
          break;
        case 'defenseman':
        case 'defense':
        case 'defenceman':
        case 'defence':
        case 'd':
          normalizedPosition = 'defense';
          break;
        case 'goalie':
        case 'goalkeeper':
        case 'goaltender':
        case 'g':
          normalizedPosition = 'goalie';
          break;
        case 'unknown':
        case '':
          normalizedPosition = 'forward'; // Safe fallback
          break;
        default:
          print('⚠️ Unrecognized position: "$position", using fallback');
          normalizedPosition = 'forward';
      }

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
      
      print('🚀 Creating skating session: ${sessionData['assessment_id']}');
      print('   Original ageGroup: "$ageGroup" → Normalized: "$normalizedAgeGroup"');
      print('   Original position: "$position" → Normalized: "$normalizedPosition"');
      
      final response = await _dio.post(
        '/api/skating/sessions',
        data: sessionData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) {
        print('✅ Successfully created skating session');
        return response.data['session'];
      }
      throw Exception('Failed to create skating session: ${response.data}');
    } catch (e) {
      print('❌ Error creating skating session: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Gets complete session data including all tests and analytics
  /// 
  /// This is the primary endpoint for retrieving session results.
  Future<Map<String, dynamic>> getSkatingSession(String assessmentId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('📥 Fetching skating session: $assessmentId');
      
      final response = await _dio.get(
        '/api/skating/sessions/$assessmentId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        print('✅ Successfully retrieved skating session');
        return response.data['session'];
      }
      throw Exception('Failed to get skating session: ${response.data}');
    } catch (e) {
      print('❌ Error fetching skating session: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
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
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final testData = {
        'test_times': testTimes,
        'notes': notes,
        'title': title,
        'description': description,
      };
      
      print('🧪 Adding test to session: $assessmentId');
      
      final response = await _dio.post(
        '/api/skating/sessions/$assessmentId/tests',
        data: testData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) {
        print('✅ Successfully added test to session');
        return response.data['session'];
      }
      throw Exception('Failed to add test to session: ${response.data}');
    } catch (e) {
      print('❌ Error adding test to session: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
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
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final queryParams = <String, dynamic>{
        'offset': offset.toString(),
      };
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      
      print('📋 Fetching skating sessions for player: $playerId');
      
      final response = await _dio.get(
        '/api/skating/players/$playerId/sessions',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        final sessions = response.data['session']['sessions'] as List;
        print('✅ Retrieved ${sessions.length} skating sessions');
        return sessions.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to get player skating sessions: ${response.data}');
    } catch (e) {
      print('❌ Error fetching player skating sessions: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PHASE 2: LEGACY COMPATIBILITY METHODS
  // ==========================================

  @Deprecated('Use createSkatingSession() and addTestToSession() instead')
  Future<Map<String, dynamic>> createSkatingAssessment(Map<String, dynamic> skatingData, {BuildContext? context}) async {
    print('⚠️  WARNING: createSkatingAssessment() is deprecated. Use createSkatingSession() and addTestToSession() instead.');
    
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
      print('❌ Error in legacy createSkatingAssessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  @Deprecated('Use addTestToSession() instead')
  Future<Map<String, dynamic>> analyzeSkating(Map<String, dynamic> skatingData, {BuildContext? context}) async {
    print('⚠️  WARNING: analyzeSkating() is deprecated. Use addTestToSession() for full functionality.');
    
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    skatingData['save'] = false;
    
    try {
      // Legacy endpoint for analysis only
      final response = await _dio.post(
        '/api/skating/assessments',
        data: skatingData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to analyze skating: ${response.data}');
    } catch (e) {
      print('❌ Error analyzing skating: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  @Deprecated('Use createSkatingSession() and addTestToSession() instead')
  Future<Map<String, dynamic>> saveSkating(Map<String, dynamic> skatingData, {BuildContext? context}) async {
    print('⚠️  WARNING: saveSkating() is deprecated. Use createSkatingSession() and addTestToSession() instead.');
    
    // Redirect to new approach
    skatingData['save'] = true;
    return createSkatingAssessment(skatingData, context: context);
  }

  // ==========================================
  // PHASE 2: UPDATED SKATING RETRIEVAL METHODS
  // ==========================================

  /// Updated method to use new session-based backend
  Future<List<Skating>> fetchSkatings(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      // Use new session-based endpoint
      final sessions = await getPlayerSkatingSessions(playerId: playerId, context: context);
      
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
      print('❌ Error fetching skatings: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Updated method to fetch specific skating test
  Future<Skating> fetchSkating(int skatingId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/skating/assessments/detail/$skatingId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return Skating.fromJson(response.data);
      throw Exception('Failed to load skating: ${response.data}');
    } catch (e) {
      print('❌ Error fetching skating: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Updated method to get skating assessments by session ID
  Future<Map<String, dynamic>> getSkatingAssessmentsBySession(String assessmentId, {BuildContext? context}) async {
    print('ℹ️  Using new getSkatingSession() method');
    
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
      print('❌ Error fetching skating assessments by session: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PHASE 2: SIMPLIFIED SKATING ANALYTICS
  // ==========================================

  /// Simplified method to get player skating assessments
  /// 
  /// This now uses the session-based approach internally
  Future<List<Map<String, dynamic>>> getPlayerSkatingAssessments(int playerId, {Map<String, dynamic>? filters}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      // Use new session-based approach
      final sessions = await getPlayerSkatingSessions(playerId: playerId);
      
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
      print('❌ Error fetching skating assessments: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired();
      }
      
      throw Exception('Failed to load skating assessments: $e');
    }
  }

  /// Updated skating comparison method
  Future<Map<String, dynamic>> getSkatingComparison(int skatingId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/comparison/$skatingId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to get skating comparison: ${response.data}');
    } catch (e) {
      print('❌ Error fetching skating comparison: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PHASE 2: CLEAN TEAM SKATING METHODS
  // ==========================================

  /// Simplified team skating batch assessment
  Future<List<Map<String, dynamic>>> saveTeamSkating(
    Skating assessment,
    String teamName,
    List<Player> players,
    Map<String, Map<String, double>> playerTestTimes,
    {BuildContext? context}
  ) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    // Generate team session ID
    final teamSessionId = 'team_${DateTime.now().millisecondsSinceEpoch}';
    
    try {
      final List<Map<String, dynamic>> results = [];
      
      // Create individual sessions for each player
      for (final player in players) {
        // Skip players without valid IDs
        if (player.id == null) {
          print('⚠️ Skipping player ${player.name} - no valid ID');
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
          title: '${teamName} - ${assessment.title}',
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
      
      print('✅ Created ${results.length} team skating assessments');
      return results;
    } catch (e) {
      print('❌ Error saving team skating: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PHASE 2: STANDARDIZED ERROR HANDLING
  // ==========================================

  /// Standardized error handling for skating operations
  Map<String, dynamic> _handleSkatingError(dynamic error, String operation) {
    print('❌ Skating $operation failed: $error');
    
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 0;
      final message = error.response?.data?['message'] ?? 
                     error.response?.data?['error'] ?? 
                     'Unknown error occurred';
      
      return {
        'success': false,
        'error': message,
        'status_code': statusCode,
        'operation': operation,
      };
    }
    
    return {
      'success': false,
      'error': error.toString(),
      'operation': operation,
    };
  }

  // ==========================================
  // PHASE 2: MIGRATION HELPERS
  // ==========================================

  /// Shows migration guidance for developers
  static void showSkatingApiMigrationGuidance() {
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
  final session = await apiService.createSkatingSession(
    playerId: playerId,
    ageGroup: ageGroup, 
    position: position,
  );
  
  // 2. Add test results
  final updatedSession = await apiService.addTestToSession(
    assessmentId: session['assessment_id'],
    testTimes: testData,
  );

This provides better error handling, clearer data flow, and matches the backend architecture.
    ''');
  }

  // ==========================================
  // SKATING ANALYTICS METHODS
  // ==========================================

  Future<Map<String, dynamic>> fetchSkatingMetrics(
    int playerId, {
    String? timeRange,
    List<String>? testTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
    if (testTypes != null && testTypes.isNotEmpty) queryParams['test_types'] = testTypes.join(',');
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/metrics',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating metrics: ${response.data}');
    } catch (e) {
      print('Error fetching skating metrics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingTrends(
    int playerId, {
    int? days,
    List<String>? testTypes,
    String interval = 'week',
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (days != null) queryParams['days'] = days.toString();
    if (testTypes != null && testTypes.isNotEmpty) queryParams['test_types'] = testTypes.join(',');
    queryParams['interval'] = interval;
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/trends',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating trends: ${response.data}');
    } catch (e) {
      print('Error fetching skating trends: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingComparison(
    int playerId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/comparison',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating comparison: ${response.data}');
    } catch (e) {
      print('Error fetching skating comparison: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingProgress(
    int playerId, {
    String? baselineAssessmentId,
    int comparisonPeriod = 30,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (baselineAssessmentId != null) queryParams['baseline_assessment_id'] = baselineAssessmentId;
    queryParams['comparison_period'] = comparisonPeriod.toString();
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/progress',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating progress: ${response.data}');
    } catch (e) {
      print('Error fetching skating progress: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingRecommendations(
    int playerId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/recommendations',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating recommendations: ${response.data}');
    } catch (e) {
      print('Error fetching skating recommendations: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTeamSkatingAnalysis(
    int teamId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/team/$teamId/analysis',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load team skating analysis: ${response.data}');
    } catch (e) {
      print('Error fetching team skating analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingTestTypes({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/skating/test-types',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating test types: ${response.data}');
    } catch (e) {
      print('Error fetching skating test types: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingAssessmentTemplates({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/skating/assessment-templates',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating assessment templates: ${response.data}');
    } catch (e) {
      print('Error fetching skating assessment templates: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingBenchmarks({
    String ageGroup = 'youth_15_18',
    String position = 'forward',
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = {
      'age_group': ageGroup,
      'position': position,
    };
    
    try {
      final response = await _dio.get(
        '/api/skating/benchmarks',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating benchmarks: ${response.data}');
    } catch (e) {
      print('Error fetching skating benchmarks: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingCategories({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/skating/categories',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating categories: ${response.data}');
    } catch (e) {
      print('Error fetching skating categories: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingProgressTimeline(
    int playerId, {
    String? startDate,
    String? endDate,
    String? categoryFilter,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (categoryFilter != null) queryParams['category'] = categoryFilter;
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/progress-timeline',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating progress timeline: ${response.data}');
    } catch (e) {
      print('Error fetching skating progress timeline: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchSkatingMiniAssessments(
    int playerId, {
    String? baselineDate,
    String? categoryFilter,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (baselineDate != null) queryParams['baseline_date'] = baselineDate;
    if (categoryFilter != null) queryParams['category'] = categoryFilter;
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/$playerId/mini-assessments',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load skating mini-assessments: ${response.data}');
    } catch (e) {
      print('Error fetching skating mini-assessments: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createTeamSkatingBatchAssessment(
    int teamId,
    Map<String, dynamic> assessmentData, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/analytics/skating/team/$teamId/batch-assessment',
        data: assessmentData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) return response.data;
      throw Exception('Failed to create team skating batch assessment: ${response.data}');
    } catch (e) {
      print('Error creating team skating batch assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // DASHBOARD METHODS
  // ==========================================

  /// Fetch recent activity across the system for dashboard
  Future<List<Map<String, dynamic>>> fetchRecentActivity({int limit = 10, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/activity/recent',
        queryParameters: {'limit': limit.toString()},
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['activities'] ?? []);
      }
      throw Exception('Failed to load recent activity: ${response.data}');
    } catch (e) {
      print('Error fetching recent activity: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Fetch pending items for admin dashboard (optional - only if you want admin features)
  Future<List<Map<String, dynamic>>> fetchPendingItems({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/admin/pending-items',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data['items'] ?? []);
      }
      throw Exception('Failed to load pending items: ${response.data}');
    } catch (e) {
      print('Error fetching pending items: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Submit access request for new user registration
  Future<Map<String, dynamic>> submitAccessRequest(Map<String, dynamic> requestData, {BuildContext? context}) async {
    try {
      final response = await _dio.post(
        '/api/registration/request',
        data: requestData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to submit access request: ${response.data}');
    } catch (e) {
      print('Error submitting access request: $e');
      rethrow;
    }
  }

  // ==========================================
  // GENERAL ANALYTICS & METRICS
  // ==========================================

  Future<Map<String, dynamic>> fetchAnalytics(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load analytics: ${response.data}');
    } catch (e) {
      print('Error fetching analytics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchPlayerMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
    if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId/metrics',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load player metrics: ${response.data}');
    } catch (e) {
      print('Error fetching player metrics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> fetchZoneMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
    if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId/zones',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, Map<String, dynamic>> result = {};
        data.forEach((zone, stats) {
          result[zone] = Map<String, dynamic>.from(stats);
        });
        return result;
      }
      throw Exception('Failed to load zone metrics: ${response.data}');
    } catch (e) {
      print('Error fetching zone metrics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, Map<String, dynamic>>> fetchShotTypeMetrics(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (timeRange != null && timeRange != 'All time') queryParams['time_range'] = timeRange;
    if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId/shot-types',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final Map<String, Map<String, dynamic>> result = {};
        data.forEach((type, stats) {
          result[type] = Map<String, dynamic>.from(stats);
        });
        return result;
      }
      throw Exception('Failed to load shot type metrics: ${response.data}');
    } catch (e) {
      print('Error fetching shot type metrics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTrendData(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    int? days;
    if (timeRange == '7 days') days = 7;
    else if (timeRange == '30 days') days = 30;
    else if (timeRange == '90 days') days = 90;
    else if (timeRange == '365 days') days = 365;
    final queryParams = <String, String>{};
    if (days != null) queryParams['days'] = days.toString();
    if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId/trends',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final List<dynamic> timelineData = data['timeline_data'];
        return timelineData.map((item) => Map<String, dynamic>.from(item)).toList();
      }
      throw Exception('Failed to load trend data: ${response.data}');
    } catch (e) {
      print('Error fetching trend data: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchCompleteAnalysis(
    int playerId, {
    String? timeRange,
    List<String>? shotTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    int? days;
    if (timeRange == '7 days') days = 7;
    else if (timeRange == '30 days') days = 30;
    else if (timeRange == '90 days') days = 90;
    else if (timeRange == '365 days') days = 365;
    final queryParams = <String, String>{};
    if (days != null) queryParams['days'] = days.toString();
    if (shotTypes != null && shotTypes.isNotEmpty) queryParams['shot_types'] = shotTypes.join(',');
    try {
      final response = await _dio.get(
        '/api/analytics/$playerId/complete',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load complete analysis: ${response.data}');
    } catch (e) {
      print('Error fetching complete analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTeamMetrics(int teamId, {String metricType = 'all', BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (metricType != 'all') queryParams['metric_type'] = metricType;
    try {
      final response = await _dio.get(
        ApiConfig.teamMetricsEndpoint(teamId),
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load team metrics: ${response.data}');
    } catch (e) {
      print('Error fetching team metrics: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTrainingImpact(int playerId, {int dateRange = 30, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        ApiConfig.trainingImpactEndpoint(playerId),
        queryParameters: {'date_range': dateRange.toString()},
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load training impact: ${response.data}');
    } catch (e) {
      print('Error fetching training impact: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchPlayerAssessment(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/player-assessment/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to fetch player assessment: ${response.data}');
    } catch (e) {
      print('Error fetching player assessment: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      return {
        'scores': {
          'accuracy': 6.5,
          'power': 5.8,
          'quickRelease': 7.2,
          'consistency': 6.0,
          'zoneBalance': 5.5,
          'shotVariety': 6.8,
        },
        'strengths': ['quickRelease', 'shotVariety'],
        'weaknesses': ['zoneBalance', 'power'],
        'recommended_workout_group': 'balancedDevelopment',
        'most_common_zone': '5',
      };
    }
  }

  Future<Map<String, dynamic>> fetchShotPatterns(int playerId, {String? zone, String? type, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (zone != null) queryParams['zone'] = zone;
    if (type != null) queryParams['type'] = type;
    try {
      final response = await _dio.get(
        '/api/analytics/patterns/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load shot patterns: ${response.data}');
    } catch (e) {
      print('Error fetching shot patterns: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // RECOMMENDATIONS & ANALYSIS
  // ==========================================

  Future<Map<String, dynamic>> _makeRecommendationRequest({
    required String method,
    required String endpoint,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.request(
        endpoint,
        options: Options(
          method: method,
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to process recommendation request: ${response.data}');
    } catch (e) {
      print('Error processing recommendation request to $endpoint: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getShotAssessmentRecommendations(String assessmentId, {BuildContext? context}) async {
    return _makeRecommendationRequest(
      method: 'GET',
      endpoint: '/api/recommendations/shot-assessment/$assessmentId',
      context: context,
    );
  }

  Future<Map<String, dynamic>> completeAssessmentWithRecommendations(String assessmentId, {BuildContext? context}) async {
    return _makeRecommendationRequest(
      method: 'PUT',
      endpoint: '/api/recommendations/shot-assessment/$assessmentId/complete',
      context: context,
    );
  }

  Future<Map<String, dynamic>> regenerateShotRecommendations(String assessmentId, {BuildContext? context}) async {
    return _makeRecommendationRequest(
      method: 'POST',
      endpoint: '/api/recommendations/shot-assessment/$assessmentId/regenerate',
      context: context,
    );
  }

  Future<Map<String, dynamic>> getRecommendations(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
    
    try {
      // FIXED: Use the correct endpoint that matches your backend route
      final response = await _dio.get(
        '/api/recommendations/$playerId',  // Changed from /api/analytics/recommendations/
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        // Return the data directly, not nested under 'recommendations'
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get recommendations: ${response.data}');
    } catch (e) {
      print('Error getting recommendations: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAssessmentAnalysis(
    String assessmentId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/analytics/assessment-analysis/$assessmentId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get assessment analysis: ${response.data}');
    } catch (e) {
      print('Error getting assessment analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getMissPatterns(
    int playerId, {
    String? assessmentId,
    int? dateRange,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
    if (dateRange != null) queryParams['date_range'] = dateRange.toString();
    
    try {
      final response = await _dio.get(
        '/api/analytics/miss-patterns/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get miss pattern analysis: ${response.data}');
    } catch (e) {
      print('Error getting miss pattern analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPowerAnalysis(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
    
    try {
      final response = await _dio.get(
        '/api/analytics/power-analysis/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get power analysis: ${response.data}');
    } catch (e) {
      print('Error getting power analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getConsistencyAnalysis(
    int playerId, {
    String? assessmentId,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
    
    try {
      final response = await _dio.get(
        '/api/analytics/consistency-analysis/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get consistency analysis: ${response.data}');
    } catch (e) {
      print('Error getting consistency analysis: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchRecommendations(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/recommendations/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to fetch recommendations: ${response.data}');
    } catch (e) {
      print('Error fetching recommendations: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchPerformanceReport(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/reports/performance/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to fetch performance report: ${response.data}');
    } catch (e) {
      print('Error fetching performance report: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // TRAINING & WORKOUTS
  // ==========================================

  Future<Map<String, dynamic>> recordCompletedWorkout(Map<String, dynamic> workoutData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/training/completed_workouts',
        data: workoutData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 201) return response.data;
      throw Exception('Failed to record completed workout: ${response.data}');
    } catch (e) {
      print('Error recording completed workout: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<CompletedWorkout>> fetchCompletedWorkouts(int playerId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/training/completed_workouts/$playerId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => CompletedWorkout.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch completed workouts: ${response.data}');
    } catch (e) {
      print('Error fetching completed workouts: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<TrainingProgram>> fetchTrainingPrograms({BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/training/programs',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => TrainingProgram.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch training programs: ${response.data}');
    } catch (e) {
      print('Error fetching training programs: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchTrainingProgramDetails(int id, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/training/programs/$id',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to fetch training program details: ${response.data}');
    } catch (e) {
      print('Error fetching training program details: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // FILE MANAGEMENT - Updated with PlatformUtils Integration
  // ==========================================

  /// Web-safe file upload method using PlatformUtils
  Future<String> uploadFile(dynamic file, {String? prefix, String? subfolder, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    // Check if file upload is supported on current platform
    if (!PlatformUtils.supportsFeature(PlatformFeature.fileUpload)) {
      if (context != null) {
        PlatformUtils.showFeatureWarning(context, PlatformFeature.fileUpload);
      }
      throw Exception('File upload not supported on ${PlatformUtils.platformDescription}. Please use the mobile app for file uploads.');
    }
    
    // Only proceed with file upload on supported platforms
    FormData formData;
    try {
      // Check file type dynamically without compile-time dependencies
      final fileTypeName = file.runtimeType.toString();
      
      if (fileTypeName.contains('File') && PlatformUtils.canHandleFiles) {
        // Handle what appears to be a dart:io File object
        try {
          // Use dynamic property access to avoid compile-time dependencies
          final filePath = _getFilePath(file);
          if (filePath != null) {
            formData = FormData.fromMap({
              'prefix': prefix,
              'subfolder': subfolder,
              'file': await MultipartFile.fromFile(filePath),
            });
          } else {
            throw Exception('Could not extract file path');
          }
        } catch (e) {
          throw Exception('Failed to process file: $e');
        }
      } else if (file is WebSafeFile) {
        formData = FormData.fromMap({
          'prefix': prefix,
          'subfolder': subfolder,
          'file': MultipartFile.fromBytes(file.bytes, filename: file.name),
        });
      } else {
        throw Exception('Unsupported file type: $fileTypeName on ${PlatformUtils.platformName}');
      }
      
      final response = await _dio.post(
        '/api/files/upload',
        data: formData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) return response.data['file_path'];
      throw Exception('Failed to upload file: ${response.data}');
    } catch (e) {
      print('Error uploading file on ${PlatformUtils.platformName}: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  /// Web-safe team logo upload method using PlatformUtils
  Future<String?> uploadTeamLogo(dynamic logoFile, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    // Check if file upload is supported on current platform
    if (!PlatformUtils.supportsFeature(PlatformFeature.fileUpload)) {
      if (context != null) {
        PlatformUtils.showFeatureWarning(context, PlatformFeature.fileUpload);
      }
      print('Team logo upload not available on ${PlatformUtils.platformDescription}');
      return null;
    }
    
    try {
      FormData formData;
      final fileTypeName = logoFile.runtimeType.toString();
      
      if (fileTypeName.contains('File') && PlatformUtils.canHandleFiles) {
        // Handle what appears to be a dart:io File object
        try {
          final filePath = _getFilePath(logoFile);
          if (filePath != null) {
            formData = FormData.fromMap({
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
        formData = FormData.fromMap({
          'logo': MultipartFile.fromBytes(
            logoFile.bytes,
            filename: logoFile.name,
            contentType: MediaType('image', 'jpeg'),
          ),
        });
      } else {
        throw Exception('Unsupported file type: $fileTypeName on ${PlatformUtils.platformName}');
      }
      
      final response = await _dio.post(
        '/api/teams/logo',
        data: formData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 201) return response.data['logo_path'];
      throw Exception('Failed to upload team logo: ${response.data}');
    } catch (e) {
      print('Error uploading team logo on ${PlatformUtils.platformName}: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      return null;
    }
  }

  /// Helper method to extract file path dynamically
  String? _getFilePath(dynamic file) {
    if (PlatformUtils.isWeb) return null;
    
    try {
      // Use dynamic property access to get the path
      // This avoids compile-time dependencies on dart:io
      return file?.path?.toString();
    } catch (e) {
      print('Could not extract file path: $e');
      return null;
    }
  }

  /// Check if file uploads are supported on current platform
  static bool get canUploadFiles => PlatformUtils.supportsFeature(PlatformFeature.fileUpload);
  
  /// Get platform-appropriate message for file operations
  static String get fileUploadMessage => PlatformUtils.getFeatureMessage(PlatformFeature.fileUpload);
  
  /// Show file upload limitation warning
  static void showFileUploadWarning(BuildContext context) {
    PlatformUtils.showFeatureWarning(context, PlatformFeature.fileUpload);
  }

  String getFileUrl(String relativePath) => '$baseUrl/api/files/$relativePath';

  Future<void> deleteFile(String relativePath, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.delete(
        '/api/files/$relativePath',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode != 200) throw Exception('Failed to delete file: ${response.data}');
    } catch (e) {
      print('Error deleting file: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // CALENDAR MANAGEMENT
  // ==========================================

  Future<List<CalendarEvent>> fetchCalendarEvents({
    String? startDate,
    String? endDate,
    String? eventType,
    int? playerId,
    int? teamId,
    bool includeCompleted = false,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (startDate != null) queryParams['start_date'] = startDate;
    if (endDate != null) queryParams['end_date'] = endDate;
    if (eventType != null) queryParams['event_type'] = eventType;
    if (playerId != null) queryParams['player_id'] = playerId.toString();
    if (teamId != null) queryParams['team_id'] = teamId.toString();
    queryParams['include_completed'] = includeCompleted.toString();
    try {
      final response = await _dio.get(
        '/api/calendar/events',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => CalendarEvent.fromJson(json)).toList();
      }
      throw Exception('Failed to load calendar events: ${response.data}');
    } catch (e) {
      print('Error fetching calendar events: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<CalendarEvent> fetchCalendarEvent(int eventId, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/calendar/events/$eventId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return CalendarEvent.fromJson(response.data);
      }
      throw Exception('Failed to load calendar event: ${response.data}');
    } catch (e) {
      print('Error fetching calendar event: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createCalendarEvent(Map<String, dynamic> eventData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/calendar/events',
        data: eventData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 201) {
        return response.data;
      }
      throw Exception('Failed to create calendar event: ${response.data}');
    } catch (e) {
      print('Error creating calendar event: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateCalendarEvent(int eventId, Map<String, dynamic> eventData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.put(
        '/api/calendar/events/$eventId',
        data: eventData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to update calendar event: ${response.data}');
    } catch (e) {
      print('Error updating calendar event: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<void> deleteCalendarEvent(int eventId, {bool deleteRecurring = false, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{};
    if (deleteRecurring) queryParams['delete_recurring'] = 'true';
    try {
      final response = await _dio.delete(
        '/api/calendar/events/$eventId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete calendar event: ${response.data}');
      }
    } catch (e) {
      print('Error deleting calendar event: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkCalendarConflicts(Map<String, dynamic> eventData, {BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.post(
        '/api/calendar/conflicts',
        data: eventData,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to check calendar conflicts: ${response.data}');
    } catch (e) {
      print('Error checking calendar conflicts: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<List<CalendarEvent>> fetchUpcomingEvents({int limit = 10, BuildContext? context}) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{
      'limit': limit.toString(),
    };
    try {
      final response = await _dio.get(
        '/api/calendar/upcoming',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) {
        return (response.data as List).map((json) => CalendarEvent.fromJson(json)).toList();
      }
      throw Exception('Failed to load upcoming events: ${response.data}');
    } catch (e) {
      print('Error fetching upcoming events: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // VISUALIZATION DATA
  // ==========================================

  Future<Map<String, dynamic>> fetchVisualizationData(
    String dataType,
    Map<String, dynamic> parameters,
    {BuildContext? context}
  ) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    // Check if this is a skating-specific visualization
    final skatingTypes = [
      'skating_categories',
      'skating_comparison', 
      'skating_trends',
      'team_skating_overview',
      'skating_benchmarks'
    ];
    
    if (skatingTypes.contains(dataType)) {
      return fetchSkatingVisualizationData(
        dataType,
        playerId: parameters['player_id'] as int?,
        teamId: parameters['team_id'] as int?,
        dateRange: parameters['date_range'] as int? ?? 90,
        ageGroup: parameters['age_group'] as String? ?? 'youth_15_18',
        position: parameters['position'] as String? ?? 'forward',
        testTypes: parameters['test_types'] as List<String>?,
        context: context,
      );
    }
    
    // Fallback to original implementation for non-skating visualizations
    final queryParams = <String, String>{};
    parameters.forEach((key, value) {
      if (value != null) queryParams[key] = value.toString();
    });
    
    try {
      final response = await _dio.get(
        ApiConfig.visualizationEndpoint(dataType),
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load visualization data: ${response.data}');
    } catch (e) {
      print('Error fetching visualization data: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchSkatingVisualizationData(
    String chartType, {
    int? playerId,
    int? teamId,
    int dateRange = 90,
    String ageGroup = 'youth_15_18',
    String position = 'forward',
    List<String>? testTypes,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{
      'date_range': dateRange.toString(),
      'age_group': ageGroup,
      'position': position,
    };
    
    if (playerId != null) queryParams['player_id'] = playerId.toString();
    if (teamId != null) queryParams['team_id'] = teamId.toString();
    if (testTypes != null && testTypes.isNotEmpty) queryParams['test_types'] = testTypes.join(',');
    
    try {
      final response = await _dio.get(
        '/api/analytics/skating/visualization/$chartType',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) return response.data;
      throw Exception('Failed to load skating visualization data: ${response.data}');
    } catch (e) {
      print('Error fetching skating visualization data: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  // ==========================================
  // PDF GENERATION & PROGRESS REPORTS
  // ==========================================

  Future<Uint8List> generateProgressReport({
    required int playerId,
    required String baselineAssessmentId,
    List<String>? miniAssessmentIds,
    String? progressPeriod,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{
      'baseline_assessment_id': baselineAssessmentId,
    };
    
    if (miniAssessmentIds != null && miniAssessmentIds.isNotEmpty) {
      queryParams['mini_assessment_ids'] = miniAssessmentIds.join(',');
    }
    
    if (progressPeriod != null) {
      queryParams['progress_period'] = progressPeriod;
    }
    
    try {
      print('Generating progress report for player $playerId with baseline $baselineAssessmentId');
      
      final response = await _dio.get(
        '/api/analytics/progress-report/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          responseType: ResponseType.bytes,
        ),
      );
      
      print('Progress report response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Progress report generated successfully: ${response.data.length} bytes');
        return Uint8List.fromList(response.data);
      }
      throw Exception('Failed to generate progress report: ${response.statusCode}');
    } catch (e) {
      print('Error generating progress report: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProgressPreview({
    required int playerId,
    required String baselineAssessmentId,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      print('Getting progress preview for player $playerId with baseline $baselineAssessmentId');
      
      final response = await _dio.get(
        '/api/analytics/progress-preview/$playerId',
        queryParameters: {'baseline_assessment_id': baselineAssessmentId},
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
        ),
      );
      
      if (response.statusCode == 200) {
        print('Progress preview retrieved successfully');
        return response.data as Map<String, dynamic>;
      }
      throw Exception('Failed to get progress preview: ${response.data}');
    } catch (e) {
      print('Error getting progress preview: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Uint8List> generateSkatingAnalysisPDF(
    int playerId, {
    String? assessmentId,
    String timeRange = '90',
    bool includeBenchmarks = true,
    bool includeRecommendations = true,
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = <String, String>{
      'time_range': timeRange,
      'include_benchmarks': includeBenchmarks.toString(),
      'include_recommendations': includeRecommendations.toString(),
    };
    if (assessmentId != null) queryParams['assessment_id'] = assessmentId;
    
    try {
      final response = await _dio.get(
        '/api/skating/report/pdf/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
      throw Exception('Failed to generate skating analysis PDF: ${response.statusCode}');
    } catch (e) {
      print('Error generating skating analysis PDF: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Uint8List> generateSkatingAssessmentPDF(
    int assessmentId, {
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    try {
      final response = await _dio.get(
        '/api/skating/assessment/pdf/$assessmentId',
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
      throw Exception('Failed to generate skating assessment PDF: ${response.statusCode}');
    } catch (e) {
      print('Error generating skating assessment PDF: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }

  Future<Uint8List> generateSkatingProgressPDF(
    int playerId, {
    required String baselineAssessmentId,
    String comparisonPeriod = '30',
    BuildContext? context,
  }) async {
    await ensureInitialized();
    
    if (!isAuthenticated()) {
      throw Exception('Authentication required. Please log in again.');
    }
    
    final queryParams = {
      'baseline_assessment_id': baselineAssessmentId,
      'comparison_period': comparisonPeriod,
    };
    
    try {
      final response = await _dio.get(
        '/api/skating/progress-report/pdf/$playerId',
        queryParameters: queryParams,
        options: Options(
          headers: _getAuthHeaders(),
          extra: {'context': context},
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.statusCode == 200) {
        return Uint8List.fromList(response.data);
      }
      throw Exception('Failed to generate skating progress PDF: ${response.statusCode}');
    } catch (e) {
      print('Error generating skating progress PDF: $e');
      
      if (e.toString().contains('No authentication token available')) {
        _handleTokenExpired(context);
      }
      
      rethrow;
    }
  }
}

// ==========================================
// WEB COMPATIBILITY UTILITIES - Updated with PlatformUtils
// ==========================================

/// Enhanced utility class for web-safe operations and platform detection
/// Uses PlatformUtils for all platform detection logic
class WebCompatibilityHelper {
  /// Check if the current platform supports file uploads
  static bool get supportsFileUploads => PlatformUtils.supportsFeature(PlatformFeature.fileUpload);
  
  /// Check if the current platform supports camera access
  static bool get supportsCameraAccess => PlatformUtils.supportsFeature(PlatformFeature.camera);
  
  /// Check if the current platform supports local file system access
  static bool get supportsFileSystem => PlatformUtils.supportsFeature(PlatformFeature.fileSystem);
  
  /// Check if the current platform supports local database
  static bool get supportsLocalDatabase => PlatformUtils.supportsFeature(PlatformFeature.localDatabase);
  
  /// Get current platform information
  static String get currentPlatform => PlatformUtils.platformDescription;
  
  /// Get platform identifier for logging/analytics
  static String get platformIdentifier => PlatformUtils.platformIdentifier;
  
  /// Check if platform has full app functionality
  static bool get isFullySupported => PlatformUtils.isFullySupported;
  
  /// Get a user-friendly message explaining platform limitations
  static String getPlatformLimitationMessage(PlatformFeature feature) {
    return PlatformUtils.getFeatureMessage(feature);
  }
  
  /// Show a platform limitation snackbar
  static void showPlatformLimitation(BuildContext context, PlatformFeature feature) {
    PlatformUtils.showFeatureWarning(context, feature);
  }
  
  /// Get platform-specific storage information
  static String getStorageInfo() {
    if (PlatformUtils.isWeb) {
      return 'Using browser storage (localStorage/sessionStorage)';
    } else if (PlatformUtils.supportsFeature(PlatformFeature.localDatabase)) {
      return 'Using device file system and SQLite database';
    } else {
      return 'Using platform-specific storage';
    }
  }
  
  /// Check if a specific package/feature is available
  static bool isFeatureAvailable(PlatformFeature feature) {
    return PlatformUtils.supportsFeature(feature);
  }
  
  /// Get recommended alternatives for web platform
  static String? getWebAlternative(PlatformFeature feature) {
    return PlatformUtils.getAlternative(feature);
  }
  
  /// Development helper to log platform compatibility warnings
  static void logPlatformCompatibility() {
    if (kDebugMode) {
      print('=== PLATFORM COMPATIBILITY INFO ===');
      print('Platform: ${PlatformUtils.platformDescription}');
      print('Platform ID: ${PlatformUtils.platformIdentifier}');
      print('Fully Supported: ${PlatformUtils.isFullySupported}');
      print('');
      print('FEATURE SUPPORT:');
      for (final feature in PlatformFeature.values) {
        final supported = PlatformUtils.supportsFeature(feature);
        final status = supported ? '✅' : '❌';
        print('$status ${feature.displayName}');
        if (!supported) {
          final alternative = PlatformUtils.getAlternative(feature);
          if (alternative != null) {
            print('   → Alternative: $alternative');
          }
        }
      }
      print('Storage: ${getStorageInfo()}');
      print('=======================================');
    }
  }
  
  /// Get capabilities summary for the current platform
  static Map<String, dynamic> getCapabilitiesSummary() {
    return {
      'platform': PlatformUtils.platformName,
      'description': PlatformUtils.platformDescription,
      'identifier': PlatformUtils.platformIdentifier,
      'isWeb': PlatformUtils.isWeb,
      'isMobile': PlatformUtils.isMobile,
      'isDesktop': PlatformUtils.isDesktop,
      'fullySupported': PlatformUtils.isFullySupported,
      'features': {
        for (final feature in PlatformFeature.values)
          feature.name: PlatformUtils.supportsFeature(feature)
      },
      'storage': getStorageInfo(),
    };
  }
  
  /// Create a platform-aware error message
  static String createPlatformError(String operation, {String? suggestion}) {
    final base = '$operation is not supported on ${PlatformUtils.platformDescription}.';
    if (suggestion != null) {
      return '$base $suggestion';
    } else if (PlatformUtils.isWeb) {
      return '$base Please use the mobile app for full functionality.';
    } else {
      return '$base This feature is not available on your platform.';
    }
  }
  
  /// Show a comprehensive platform warning dialog
  static void showPlatformDialog(BuildContext context, PlatformFeature feature) {
    if (PlatformUtils.supportsFeature(feature)) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${feature.displayName} Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${feature.displayName} is not supported on ${PlatformUtils.platformDescription}.'),
            const SizedBox(height: 16),
            if (PlatformUtils.getAlternative(feature) != null) ...[
              const Text('Alternative:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(PlatformUtils.getAlternative(feature)!),
            ] else ...[
              const Text('For full functionality, please use the mobile app.'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// HIRE SYSTEM EXCEPTION CLASSES
// ==========================================

/// Custom exception for HIRE system-specific errors
class HireException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  const HireException(this.message, [this.statusCode, this.data]);

  @override
  String toString() {
    return 'HireException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }

  /// Check if this is a validation error
  bool get isValidationError => statusCode == 400;

  /// Check if this is an authorization error
  bool get isAuthorizationError => statusCode == 401 || statusCode == 403;

  /// Check if this is a not found error
  bool get isNotFoundError => statusCode == 404;

  /// Get user-friendly error message
  String get userMessage {
    switch (statusCode) {
      case 400:
        return 'Invalid HIRE data provided. Please check your inputs.';
      case 401:
        return 'Please log in to access HIRE features.';
      case 403:
        return 'You do not have permission to access this HIRE feature.';
      case 404:
        return 'HIRE data not found for this player.';
      case 500:
        return 'Server error while processing HIRE data. Please try again.';
      default:
        return message;
    }
  }
}

// ==========================================
// API SERVICE EXTENSIONS FOR HIRE SYSTEM
// ==========================================

/// Extension methods for ApiService to add HIRE-specific functionality
extension HireApiExtensions on ApiService {
  /// Validate HIRE ratings before sending to server
  Map<String, dynamic> validateHireRatings(Map<String, double> ratings) {
    final errors = <String>[];
    final validatedRatings = <String, double>{};

    // Define required HIRE categories and their sub-factors
    final requiredFactors = {
      // Humility factors
      'coachability': 10.0,
      'team_play': 10.0,
      'respect_for_others': 10.0,
      
      // Hardwork factors
      'work_ethic': 10.0,
      'physical_fitness': 10.0,
      'commitment': 10.0,
      
      // Initiative factors
      'leadership': 10.0,
      'goal_setting': 10.0,
      'adaptability': 10.0,
      'hockey_iq': 10.0,
      'learning_appetite': 10.0,
      'challenge_acceptance': 10.0,
      
      // Integrity factors
      'communication_skills': 10.0,
      'mental_toughness': 10.0,
      'decision_making_under_pressure': 10.0,
      
      // Responsibility factors
      'time_management': 10.0,
      'nutrition': 10.0,
      'sleep_quality': 10.0,
      
      // Respect factors (calculated from other factors)
      
      // Enthusiasm factors
      'competitiveness': 10.0,
      'passion_for_game': 10.0,
      'energy_positive_attitude': 10.0,
    };

    // Validate each rating
    for (final entry in ratings.entries) {
      final factor = entry.key;
      final rating = entry.value;

      // Check if factor is recognized
      if (!requiredFactors.containsKey(factor)) {
        errors.add('Unknown HIRE factor: $factor');
        continue;
      }

      // Check rating range (1-10)
      if (rating < 1.0 || rating > 10.0) {
        errors.add('Rating for $factor must be between 1.0 and 10.0 (got $rating)');
        continue;
      }

      validatedRatings[factor] = rating;
    }

    // Check for missing required factors
    for (final requiredFactor in requiredFactors.keys) {
      if (!validatedRatings.containsKey(requiredFactor)) {
        errors.add('Missing required HIRE factor: $requiredFactor');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'validatedRatings': validatedRatings,
      'missingFactors': requiredFactors.keys.where((f) => !validatedRatings.containsKey(f)).toList(),
    };
  }

  /// Get HIRE factor definitions and descriptions
  Map<String, dynamic> getHireFactorDefinitions() {
    return {
      'categories': {
        'H': {
          'name': 'Humility / Hardwork',
          'weight': 0.25,
          'subcategories': {
            'humility': {
              'weight': 0.5,
              'factors': {
                'coachability': {
                  'weight': 1.0,
                  'description': 'Ability to receive feedback and implement corrections',
                  'importance': 'Uncoachable players stop improving. The most coachable players often have the longest, most successful careers.',
                },
                'team_play': {
                  'weight': 0.7,
                  'humility_component': 0.7,
                  'respect_component': 0.3,
                  'description': 'Playing for the team, making the right play, unselfishness',
                  'importance': 'Hockey is the ultimate team sport. Selfish players hurt team chemistry and limit team success.',
                },
                'respect_for_others': {
                  'weight': 0.3,
                  'humility_component': 0.3,
                  'respect_component': 0.7,
                  'description': 'How they treat teammates, coaches, officials, and opponents',
                  'importance': 'Respect builds trust and team chemistry. Disrespectful players create toxic environments that hurt team performance.',
                },
              },
            },
            'hardwork': {
              'weight': 0.5,
              'factors': {
                'work_ethic': {
                  'weight': 1.0,
                  'description': 'Effort level in practice, training, and games',
                  'importance': 'Work ethic determines how much potential a player will actually reach.',
                },
                'physical_fitness': {
                  'weight': 1.0,
                  'description': 'Conditioning, strength, and overall physical preparation',
                  'importance': 'Physical fitness enables players to perform at their best throughout games and seasons.',
                },
                'commitment': {
                  'weight': 0.6,
                  'hardwork_component': 0.6,
                  'responsibility_component': 0.4,
                  'description': 'Dedication to improvement and team goals',
                  'importance': 'Commitment drives consistent effort and long-term development.',
                },
              },
            },
          },
        },
        'I': {
          'name': 'Initiative / Integrity',
          'weight': 0.30,
          'subcategories': {
            'initiative': {
              'weight': 0.6,
              'factors': {
                'leadership': {
                  'weight': 0.7,
                  'initiative_component': 0.7,
                  'responsibility_component': 0.3,
                  'description': 'Taking charge, motivating others, leading by example',
                  'importance': 'Leadership creates positive culture and drives team success.',
                },
                'goal_setting': {
                  'weight': 1.0,
                  'description': 'Setting and working toward personal and team objectives',
                  'importance': 'Goal setting provides direction and motivation for improvement.',
                },
                'adaptability': {
                  'weight': 1.0,
                  'description': 'Adjusting to new situations, systems, and challenges',
                  'importance': 'Hockey requires constant adaptation to different opponents and game situations.',
                },
                'hockey_iq': {
                  'weight': 0.8,
                  'initiative_component': 0.8,
                  'responsibility_component': 0.2,
                  'description': 'Understanding the game, reading situations, making smart decisions',
                  'importance': 'Hockey IQ allows players to maximize their physical abilities and contribute strategically.',
                },
                'learning_appetite': {
                  'weight': 0.7,
                  'initiative_component': 0.7,
                  'enthusiasm_component': 0.3,
                  'description': 'Desire to learn new skills and concepts',
                  'importance': 'Learning appetite drives continuous improvement and adaptation.',
                },
                'challenge_acceptance': {
                  'weight': 0.6,
                  'initiative_component': 0.6,
                  'enthusiasm_component': 0.4,
                  'description': 'Embracing difficult situations and higher competition',
                  'importance': 'Challenge acceptance is necessary for growth and reaching higher levels.',
                },
              },
            },
            'integrity': {
              'weight': 0.4,
              'factors': {
                'communication_skills': {
                  'weight': 1.0,
                  'description': 'Expressing ideas clearly, listening effectively, positive communication',
                  'importance': 'Communication builds understanding and team coordination.',
                },
                'mental_toughness': {
                  'weight': 1.0,
                  'description': 'Resilience under pressure, bouncing back from setbacks',
                  'importance': 'Mental toughness determines performance in crucial moments.',
                },
                'decision_making_under_pressure': {
                  'weight': 1.0,
                  'description': 'Making good choices when the stakes are high',
                  'importance': 'Pressure situations often determine game outcomes.',
                },
              },
            },
          },
        },
        'R': {
          'name': 'Responsibility / Respect',
          'weight': 0.25,
          'subcategories': {
            'responsibility': {
              'weight': 0.7,
              'factors': {
                'time_management': {
                  'weight': 1.0,
                  'description': 'Punctuality, meeting deadlines, managing priorities',
                  'importance': 'Time management shows respect for others and enables consistent preparation.',
                },
                'nutrition': {
                  'weight': 1.0,
                  'description': 'Eating habits that support performance and recovery',
                  'importance': 'Proper nutrition is essential for optimal performance and injury prevention.',
                },
                'sleep_quality': {
                  'weight': 1.0,
                  'description': 'Getting adequate, quality rest for recovery and performance',
                  'importance': 'Sleep quality directly impacts physical and mental performance.',
                },
              },
            },
            'respect': {
              'weight': 0.3,
              'description': 'Calculated from respect_for_others and team_play factors',
              'importance': 'Respect creates the foundation for positive team culture.',
            },
          },
        },
        'E': {
          'name': 'Enthusiasm',
          'weight': 0.20,
          'factors': {
            'competitiveness': {
              'weight': 1.0,
              'description': 'Drive to win, hate losing, competitive spirit',
              'importance': 'Competitiveness fuels the desire to improve and succeed.',
            },
            'passion_for_game': {
              'weight': 1.0,
              'description': 'Love for hockey, enjoyment of playing and practicing',
              'importance': 'Passion sustains motivation through challenges and setbacks.',
            },
            'energy_positive_attitude': {
              'weight': 1.0,
              'description': 'Bringing positive energy, enthusiasm, and optimism',
              'importance': 'Positive energy is contagious and lifts the entire team.',
            },
          },
        },
      },
      'ageSpecificFactors': {
        'youth_8_12': [
          'fun_enjoyment_level',
          'attention_span',
          'following_instructions',
          'sharing_teamwork',
          'equipment_care',
        ],
        'teen_13_17': [
          'academic_performance',
          'social_media_habits',
          'peer_influence_management',
          'independence',
          'substance_awareness',
          'conflict_resolution',
        ],
        'adult_18_plus': [
          'work_career_balance',
          'financial_management',
          'family_commitments',
          'career_planning',
          'stress_management',
          'long_term_vision',
        ],
      },
      'scoringGuide': {
        '9.0-10.0': 'Elite HIRE characteristics - program exemplar',
        '8.0-8.9': 'Strong HIRE traits - leadership candidate',
        '7.0-7.9': 'Good HIRE development - on positive trajectory',
        '6.0-6.9': 'Average HIRE traits - needs focused improvement',
        '5.0-5.9': 'Below average - requires significant development',
        'Below 5.0': 'Concerning - may not be good fit for program values',
      },
    };
  }

  /// Calculate HIRE scores locally (for validation/preview)
  Map<String, dynamic> calculateHireScoresLocally(Map<String, double> ratings) {
    final validation = validateHireRatings(ratings);
    if (!validation['isValid']) {
      throw HireException('Invalid HIRE ratings: ${validation['errors'].join(', ')}');
    }

    final validatedRatings = validation['validatedRatings'] as Map<String, double>;

    // Calculate subcategory scores
    final humilityScore = (
      validatedRatings['coachability']! * 1.0 +
      validatedRatings['team_play']! * 0.7 +
      validatedRatings['respect_for_others']! * 0.3
    ) / 2.3;

    final hardworkScore = (
      validatedRatings['work_ethic']! +
      validatedRatings['physical_fitness']! +
      validatedRatings['commitment']! * 0.6
    ) / 2.6;

    final initiativeScore = (
      validatedRatings['leadership']! * 0.7 +
      validatedRatings['goal_setting']! +
      validatedRatings['adaptability']! +
      validatedRatings['hockey_iq']! * 0.8 +
      validatedRatings['learning_appetite']! * 0.7 +
      validatedRatings['challenge_acceptance']! * 0.6
    ) / 5.2;

    final integrityScore = (
      validatedRatings['communication_skills']! +
      validatedRatings['mental_toughness']! +
      validatedRatings['decision_making_under_pressure']!
    ) / 3.0;

    final responsibilityScore = (
      validatedRatings['time_management']! +
      validatedRatings['nutrition']! +
      validatedRatings['sleep_quality']! +
      validatedRatings['commitment']! * 0.4 +
      validatedRatings['leadership']! * 0.3 +
      validatedRatings['hockey_iq']! * 0.2
    ) / 4.9;

    final respectScore = (
      validatedRatings['respect_for_others']! * 0.7 +
      validatedRatings['team_play']! * 0.3
    ) / 1.0;

    final enthusiasmScore = (
      validatedRatings['competitiveness']! +
      validatedRatings['passion_for_game']! +
      validatedRatings['energy_positive_attitude']! +
      validatedRatings['learning_appetite']! * 0.3 +
      validatedRatings['challenge_acceptance']! * 0.4
    ) / 4.7;

    // Calculate main category scores
    final hScore = (humilityScore * 0.5) + (hardworkScore * 0.5);
    final iScore = (initiativeScore * 0.6) + (integrityScore * 0.4);
    final rScore = (responsibilityScore * 0.7) + (respectScore * 0.3);
    final eScore = enthusiasmScore;

    // Calculate overall HIRE score
    final overallScore = (hScore * 0.25) + (iScore * 0.30) + (rScore * 0.25) + (eScore * 0.20);

    return {
      'categoryScores': {
        'H': double.parse(hScore.toStringAsFixed(1)),
        'I': double.parse(iScore.toStringAsFixed(1)),
        'R': double.parse(rScore.toStringAsFixed(1)),
        'E': double.parse(eScore.toStringAsFixed(1)),
      },
      'subcategoryScores': {
        'humility': double.parse(humilityScore.toStringAsFixed(1)),
        'hardwork': double.parse(hardworkScore.toStringAsFixed(1)),
        'initiative': double.parse(initiativeScore.toStringAsFixed(1)),
        'integrity': double.parse(integrityScore.toStringAsFixed(1)),
        'responsibility': double.parse(responsibilityScore.toStringAsFixed(1)),
        'respect': double.parse(respectScore.toStringAsFixed(1)),
        'enthusiasm': double.parse(enthusiasmScore.toStringAsFixed(1)),
      },
      'overallScore': double.parse(overallScore.toStringAsFixed(1)),
      'interpretation': _getHireInterpretation(overallScore),
      'calculatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get HIRE score interpretation
  Map<String, dynamic> _getHireInterpretation(double score) {
    if (score >= 9.0) {
      return {
        'level': 'Elite',
        'description': 'Elite HIRE characteristics - program exemplar',
        'recommendation': 'Excellent leadership candidate with exceptional character traits',
        'focusAreas': ['Mentor younger players', 'Take on leadership roles'],
      };
    } else if (score >= 8.0) {
      return {
        'level': 'Strong',
        'description': 'Strong HIRE traits - leadership candidate',
        'recommendation': 'Strong character foundation with leadership potential',
        'focusAreas': ['Develop leadership skills', 'Maintain high standards'],
      };
    } else if (score >= 7.0) {
      return {
        'level': 'Good',
        'description': 'Good HIRE development - on positive trajectory',
        'recommendation': 'Solid character development with room for growth',
        'focusAreas': ['Continue positive development', 'Focus on consistency'],
      };
    } else if (score >= 6.0) {
      return {
        'level': 'Average',
        'description': 'Average HIRE traits - needs focused improvement',
        'recommendation': 'Character development needed in specific areas',
        'focusAreas': ['Identify weak areas', 'Create development plan'],
      };
    } else if (score >= 5.0) {
      return {
        'level': 'Below Average',
        'description': 'Below average - requires significant development',
        'recommendation': 'Significant character development required',
        'focusAreas': ['Intensive character training', 'Close monitoring'],
      };
    } else {
      return {
        'level': 'Concerning',
        'description': 'Concerning - may not be good fit for program values',
        'recommendation': 'Major character concerns that need immediate attention',
        'focusAreas': ['Evaluate program fit', 'Intensive intervention'],
      };
    }
  }
}