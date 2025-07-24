// lib/services/foundation/auth_service.dart

import 'dart:html' as html;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:dio/dio.dart'; // ✅ ADD THIS IMPORT

import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// Service responsible for authentication, token management, and session handling
/// 
/// This service provides:
/// - Login/logout functionality with secure token storage
/// - Automatic token refresh and validation
/// - Cross-platform token storage (web localStorage vs mobile secure storage)
/// - User role and permission management
/// - Session state management and validation
class AuthService extends BaseApiService {
  // ==========================================
  // PROPERTIES & STATE
  // ==========================================
  
  String? _token;
  String? _refreshToken;
  String? _currentUserRole;
  Map<String, dynamic>? _currentUser;
  DateTime? _tokenExpiresAt;
  
  bool _isRefreshing = false;
  bool _hasNavigatedToLogin = false;
  bool _isInitialized = false;
  Completer<void>? _initCompleter;
  
  final FlutterSecureStorage _secureStorage = ApiConfig.secureStorage;
  
  // ==========================================
  // INITIALIZATION
  // ==========================================
  
  AuthService({required super.baseUrl, super.onTokenExpired}) {
    _initializeAsync();
  }
  
  /// Ensure the service is fully initialized before use
  Future<void> ensureInitialized() async {
    if (_isInitialized) return;
    await _initializeAsync();
  }
  
  Future<void> _initializeAsync() async {
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();
    
    try {
      await _loadToken();
      await _loadCurrentUser();
      _isInitialized = true;
      _initCompleter!.complete();
      
      if (kDebugMode) {
        print('🔑 AuthService: Initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Initialization failed: $e');
      }
      _initCompleter!.completeError(e);
    }
  }
  
  // ==========================================
  // BASE API SERVICE IMPLEMENTATION
  // ==========================================
  
  @override
  Future<Map<String, String>> getAuthHeaders() async {
    await ensureInitialized();
    
    if (_token == null) {
      if (kDebugMode) {
        print('⚠️ AuthService: No authentication token available');
      }
      return {};
    }
    
    // Check if token needs refresh
    if (_isTokenExpiredSoon() && !_isRefreshing) {
      final refreshed = await refreshToken();
      if (!refreshed) {
        return {};
      }
    }
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }
  
  @override
  bool isAuthenticated() {
    return _token != null && !_isTokenExpiredSoon();
  }
  
  @override
  void handleAuthenticationError(BuildContext? context) {
    if (kDebugMode) {
      print('🔑 AuthService: Handling authentication error');
    }
    
    if (!_hasNavigatedToLogin && onTokenExpired != null) {
      _hasNavigatedToLogin = true;
      onTokenExpired!(context);
    } else {
      NavigationService().pushNamedAndRemoveUntil('/login');
    }
  }
  
  // ==========================================
  // TOKEN STORAGE & MANAGEMENT
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
      
      if (kDebugMode) {
        print('📱 AuthService: Loaded tokens from localStorage (web)');
      }
    } else {
      // Load from secure storage on mobile/desktop
      _token = await _secureStorage.read(key: ApiConfig.tokenKey);
      _refreshToken = await _secureStorage.read(key: ApiConfig.refreshTokenKey);
      _currentUserRole = await _secureStorage.read(key: 'user_role');
      final expiryString = await _secureStorage.read(key: 'token_expires_at');
      if (expiryString != null) {
        _tokenExpiresAt = DateTime.tryParse(expiryString);
      }
      
      if (kDebugMode) {
        print('📱 AuthService: Loaded tokens from secure storage (mobile/desktop)');
      }
    }
    
    if (kDebugMode && _token != null) {
      print('🔑 AuthService: Token loaded: ${_token!.substring(0, 20)}..., role: $_currentUserRole');
      if (_tokenExpiresAt != null) {
        print('🕒 AuthService: Token expires at: $_tokenExpiresAt');
      }
    }
  }
  
  Future<void> _saveToken(
    String token, 
    String refreshToken, 
    String role, {
    int? accessExpiresIn
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    _currentUserRole = role;
    
    if (accessExpiresIn != null) {
      _tokenExpiresAt = DateTime.now().add(Duration(seconds: accessExpiresIn));
    }
    
    if (kIsWeb) {
      // Use localStorage on web
      html.window.localStorage['hockey_access_token'] = token;
      html.window.localStorage['hockey_refresh_token'] = refreshToken;
      html.window.localStorage['hockey_user_role'] = role;
      if (_tokenExpiresAt != null) {
        html.window.localStorage['hockey_token_expires_at'] = _tokenExpiresAt!.toIso8601String();
      }
      
      if (kDebugMode) {
        print('💾 AuthService: Saved tokens to localStorage (web)');
      }
    } else {
      // Use secure storage on mobile/desktop
      await _secureStorage.write(key: ApiConfig.tokenKey, value: token);
      await _secureStorage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
      await _secureStorage.write(key: 'user_role', value: role);
      if (_tokenExpiresAt != null) {
        await _secureStorage.write(key: 'token_expires_at', value: _tokenExpiresAt!.toIso8601String());
      }
      
      if (kDebugMode) {
        print('💾 AuthService: Saved tokens to secure storage (mobile/desktop)');
      }
    }
  }
  
  Future<void> _clearToken() async {
    if (kIsWeb) {
      // Clear from localStorage on web
      html.window.localStorage.remove('hockey_access_token');
      html.window.localStorage.remove('hockey_refresh_token');
      html.window.localStorage.remove('hockey_user_role');
      html.window.localStorage.remove('hockey_token_expires_at');
      
      if (kDebugMode) {
        print('🗑️ AuthService: Cleared tokens from localStorage (web)');
      }
    } else {
      // Clear from secure storage on mobile/desktop
      await _secureStorage.delete(key: ApiConfig.tokenKey);
      await _secureStorage.delete(key: ApiConfig.refreshTokenKey);
      await _secureStorage.delete(key: 'user_role');
      await _secureStorage.delete(key: 'token_expires_at');
      
      if (kDebugMode) {
        print('🗑️ AuthService: Cleared tokens from secure storage (mobile/desktop)');
      }
    }
    
    _token = null;
    _refreshToken = null;
    _currentUserRole = null;
    _tokenExpiresAt = null;
    _isRefreshing = false;
    _hasNavigatedToLogin = false;
    
    if (kDebugMode) {
      print('🧹 AuthService: Cleared all token state');
    }
  }
  
  // ==========================================
  // USER DATA MANAGEMENT
  // ==========================================
  
  Future<void> _loadCurrentUser() async {
    final userJson = await _secureStorage.read(key: ApiConfig.currentUserKey);
    if (userJson != null) {
      _currentUser = jsonDecode(userJson);
      
      if (kDebugMode) {
        print('👤 AuthService: Loaded current user: ${_currentUser?['username']}');
      }
    }
  }
  
  Future<void> _saveCurrentUser(Map<String, dynamic> userData) async {
    await _secureStorage.write(key: ApiConfig.currentUserKey, value: jsonEncode(userData));
    _currentUser = userData;
    
    if (kDebugMode) {
      print('👤 AuthService: Saved current user: ${userData['username']}');
    }
  }
  
  Future<void> _clearCurrentUser() async {
    await _secureStorage.delete(key: ApiConfig.currentUserKey);
    _currentUser = null;
    
    if (kDebugMode) {
      print('👤 AuthService: Cleared current user');
    }
  }
  
  // ==========================================
  // TOKEN VALIDATION & REFRESH
  // ==========================================
  
  bool _isTokenExpiredSoon() {
    if (_tokenExpiresAt == null) return false;
    
    final now = DateTime.now();
    final timeUntilExpiry = _tokenExpiresAt!.difference(now);
    
    return timeUntilExpiry.inSeconds <= 30; // Refresh if expiring within 30 seconds
  }
  
  Future<bool> refreshToken() async {
    if (_isRefreshing) {
      // Wait for existing refresh to complete
      int attempts = 0;
      while (_isRefreshing && attempts < 30) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      return _token != null;
    }
    
    if (_refreshToken == null || _refreshToken!.isEmpty) {
      if (kDebugMode) {
        print('❌ AuthService: No refresh token available');
      }
      await logout();
      return false;
    }
    
    _isRefreshing = true;
    
    try {
      if (kDebugMode) {
        print('🔄 AuthService: Refreshing token...');
      }
      
      final response = await post(
        '/api/auth/refresh',
        options: Options(
          headers: {
            'Authorization': 'Bearer $_refreshToken',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      
      if (response.statusCode == 200 && response.data['access_token'] != null) {
        final tokenInfo = response.data['token_info'] as Map<String, dynamic>?;
        final accessExpiresIn = tokenInfo?['access_expires_in'] as int?;
        
        await _saveToken(
          response.data['access_token'],
          response.data['refresh_token'] ?? _refreshToken!,
          _currentUserRole ?? 'unknown',
          accessExpiresIn: accessExpiresIn,
        );
        
        if (kDebugMode) {
          print('✅ AuthService: Token refreshed successfully');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ AuthService: Token refresh failed: ${response.statusCode}');
        }
        await logout();
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Token refresh error: $e');
      }
      await logout();
      return false;
    } finally {
      _isRefreshing = false;
    }
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
        if (kDebugMode) {
          print('⚠️ AuthService: Detected old system token - will clear');
        }
        return true;
      }
      
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Error checking token: $e');
      }
      return true;
    }
  }
  
  // ==========================================
  // AUTHENTICATION OPERATIONS
  // ==========================================
  
  Future<bool> login(String username, String password) async {
    try {
      // Clear old tokens if necessary
      if (await _shouldClearOldTokens()) {
        await clearExpiredTokens();
      }
      
      if (kDebugMode) {
        print('🔐 AuthService: Sending login request for username: $username');
      }
      
      final response = await post(
        '/api/auth/login',
        data: {
          'username': username,
          'password': password,
        },
      );
      
      final data = handleResponse(response);
      if (data == null) {
        throw AuthenticationException('Login failed: Invalid response');
      }
      
      final accessToken = data['access_token'] as String?;
      final refreshToken = data['refresh_token'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      final tokenInfo = data['token_info'] as Map<String, dynamic>?;
      
      if (accessToken == null || refreshToken == null || user == null) {
        throw AuthenticationException('Missing required fields in login response');
      }
      
      final role = user['role'] as String? ?? 'unknown';
      final accessExpiresIn = tokenInfo?['access_expires_in'] as int?;
      
      // Save tokens and user data
      await _saveToken(accessToken, refreshToken, role, accessExpiresIn: accessExpiresIn);
      await _saveCurrentUser(user);
      
      // Verify token was saved correctly
      await _loadToken();
      if (_token == null) {
        throw AuthenticationException('Failed to persist authentication token');
      }
      
      // Reset state flags
      _isRefreshing = false;
      _hasNavigatedToLogin = false;
      
      if (kDebugMode) {
        print('✅ AuthService: Login successful for user: ${user['username']} (role: $role)');
        print('🔑 AuthService: Token preview: ${_token!.substring(0, 20)}...');
        
        if (_tokenExpiresAt != null) {
          final now = DateTime.now();
          final duration = _tokenExpiresAt!.difference(now);
          print('⏰ AuthService: Token expires in ${duration.inHours}h ${duration.inMinutes % 60}m');
        }
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Login error: $e');
      }
      rethrow;
    }
  }
  
  Future<void> logout() async {
    try {
      await _clearToken();
      await _clearCurrentUser();
      
      if (kDebugMode) {
        print('✅ AuthService: Logout completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ AuthService: Logout error: $e');
      }
    }
  }
  
  Future<void> clearExpiredTokens() async {
    if (kDebugMode) {
      print('🧹 AuthService: Clearing expired tokens from old system...');
    }
    await _clearToken();
    await _clearCurrentUser();
  }
  
  // ==========================================
  // USER & ROLE MANAGEMENT
  // ==========================================
  
  /// Get current user data with token information
  Map<String, dynamic>? getCurrentUser() {
    if (_token == null || _currentUser == null) return null;
    
    return {
      'token': _token,
      'role': _currentUserRole,
      ..._currentUser!,
    };
  }
  
  /// Get current user role
  String? getCurrentUserRole() => _currentUserRole;
  
  /// Get authentication token
  String? getAuthToken() => _token;
  
  // ==========================================
  // PERMISSION CHECKING
  // ==========================================
  
  /// Check if current user is a coach
  bool isCoach() => _currentUserRole == 'coach';
  
  /// Check if current user is a coordinator
  bool isCoordinator() => _currentUserRole == 'coordinator';
  
  /// Check if current user is a director
  bool isDirector() => _currentUserRole == 'director';
  
  /// Check if current user is an admin
  bool isAdmin() => _currentUserRole == 'admin';
  
  /// Check if current user can manage teams
  bool canManageTeams() => isAdmin() || isDirector() || isCoordinator();
  
  /// Check if current user can manage coaches
  bool canManageCoaches() => isAdmin() || isDirector();
  
  /// Check if current user can manage coordinators
  bool canManageCoordinators() => isAdmin();
  
  /// Check if current user can delete teams
  bool canDeleteTeams() => isAdmin() || isDirector();
  
  /// Check if user has specific permission
  bool hasPermission(String permission) {
    switch (permission) {
      case 'manage_teams':
        return canManageTeams();
      case 'manage_coaches':
        return canManageCoaches();
      case 'manage_coordinators':
        return canManageCoordinators();
      case 'delete_teams':
        return canDeleteTeams();
      case 'view_analytics':
        return true; // All authenticated users can view analytics
      case 'manage_hire':
        return isCoordinator() || isDirector() || isAdmin();
      default:
        return false;
    }
  }
  
  // ==========================================
  // DEBUG & UTILITY METHODS
  // ==========================================
  
  /// Debug method to check authentication state
  void debugAuthState() {
    if (!kDebugMode) return;
    
    print('=== AUTH SERVICE DEBUG STATE ===');
    print('Initialized: $_isInitialized');
    print('Token exists: ${_token != null}');
    print('Token preview: ${_token?.substring(0, 20) ?? 'null'}...');
    print('Refresh token exists: ${_refreshToken != null}');
    print('Is authenticated: ${isAuthenticated()}');
    print('Token expires at: $_tokenExpiresAt');
    print('Current user role: $_currentUserRole');
    print('Current user: ${_currentUser?['username'] ?? 'null'}');
    print('Is refreshing: $_isRefreshing');
    print('Has navigated to login: $_hasNavigatedToLogin');
    print('================================');
  }
  
  /// Get authentication status summary
  Map<String, dynamic> getAuthStatus() {
    return {
      'isInitialized': _isInitialized,
      'isAuthenticated': isAuthenticated(),
      'hasToken': _token != null,
      'hasRefreshToken': _refreshToken != null,
      'userRole': _currentUserRole,
      'userName': _currentUser?['username'],
      'tokenExpiresAt': _tokenExpiresAt?.toIso8601String(),
      'isRefreshing': _isRefreshing,
    };
  }
}