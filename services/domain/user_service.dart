// lib/services/domain/user_service.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/services/base_api_service.dart';
import 'package:hockey_shot_tracker/services/foundation/auth_service.dart';

/// Service responsible for user CRUD operations and profile management.
///
/// This service provides:
/// - User registration and profile management
/// - User data retrieval and updates
/// - User deletion (admin only)
/// - Role-based user filtering
/// - Current user profile operations
class UserService extends BaseApiService {
  // ==========================================
  // DEPENDENCIES
  // ==========================================

  final AuthService _authService;

  UserService({
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
  // CASTING HELPER METHODS
  // ==========================================

  /// Safely casts API response to a list of [User] objects.
  static List<User> _castUserList(dynamic userList) {
    if (userList is List) {
      return userList
          .map((json) => User.fromJson(json as Map<String, dynamic>))
          .toList();
    } else if (userList is Map && userList.containsKey('users')) {
      final list = userList['users'];
      if (list is List) {
        return list
            .map((json) => User.fromJson(json as Map<String, dynamic>))
            .toList();
      }
    }
    if (kDebugMode) {
      debugPrint('⚠️ UserService: Unexpected userList type: ${userList.runtimeType}');
    }
    return <User>[];
  }

  // ==========================================
  // USER REGISTRATION & CREATION
  // ==========================================

  /// Registers a new user in the system.
  ///
  /// [userData] must contain:
  /// - username: Unique username for the user
  /// - password: User's password
  /// - name: Full name of the user
  /// - email: User's email address
  /// - role: User role (coach, coordinator, director, admin)
  ///
  /// Throws [AuthenticationException] if not authenticated.
  /// Throws [ApiException] if the registration fails.
  Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> userData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to register users');
    }

    try {
      // Validate required fields
      validateRequiredFields(userData, [
        'username',
        'password',
        'name',
        'email',
      ]);

      // Clean and prepare user data
      final cleanedData = cleanRequestData({
        'username': userData['username'],
        'password': userData['password'],
        'name': userData['name'],
        'email': userData['email'],
        'role': userData['role'] ?? 'coach', // Default role
      });

      if (kDebugMode) {
        debugPrint(
            '👤 UserService: Registering user: ${cleanedData['username']} (${cleanedData['role']})');
      }

      final response = await post(
        '/api/users',
        data: cleanedData,
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to register user: empty response');
      }

      if (kDebugMode) {
        debugPrint('✅ UserService: User registered successfully: ${result['username']}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error registering user: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  // ==========================================
  // USER PROFILE MANAGEMENT
  // ==========================================

  /// Updates an existing user's information.
  ///
  /// Only users with appropriate permissions can update other users.
  /// Users can always update their own profile.
  Future<Map<String, dynamic>> updateUser(
    int userId,
    Map<String, dynamic> userData, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update users');
    }

    try {
      // Clean the update data (remove null/empty values)
      final cleanedData = cleanRequestData(userData);

      if (kDebugMode) {
        debugPrint('👤 UserService: Updating user $userId with data: ${cleanedData.keys}');
      }

      final response = await put(
        '/api/users/$userId',
        data: cleanedData,
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update user: empty response');
      }

      if (kDebugMode) {
        debugPrint('✅ UserService: User $userId updated successfully');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error updating user $userId: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  /// Retrieves the current user's profile information.
  ///
  /// This endpoint returns fresh data from the server and updates
  /// the cached user information in [AuthService].
  Future<Map<String, dynamic>> getCurrentUserProfile({
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get user profile');
    }

    try {
      if (kDebugMode) {
        debugPrint('👤 UserService: Fetching current user profile');
      }

      final response = await get(
        '/api/auth/me',
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to get user profile: empty response');
      }

      if (kDebugMode) {
        debugPrint('✅ UserService: Current user profile retrieved: ${result['username']}');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error fetching current user profile: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  // ==========================================
  // USER RETRIEVAL & FILTERING
  // ==========================================

  /// Fetches users by their role.
  ///
  /// Available roles: coach, coordinator, director, admin.
  /// Only users with appropriate permissions can fetch user lists.
  Future<List<User>> fetchUsersByRole(
    String role, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch users');
    }

    try {
      if (kDebugMode) {
        debugPrint('👥 UserService: Fetching users with role: $role');
      }

      final response = await get(
        '/api/users/$role',
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        if (kDebugMode) {
          debugPrint('ℹ️ UserService: No users found with role: $role');
        }
        return [];
      }

      final users = _castUserList(result);

      if (kDebugMode) {
        debugPrint('✅ UserService: Retrieved ${users.length} users with role: $role');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error fetching users by role $role: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  /// Fetches all users (admin only).
  ///
  /// Returns a list of all users in the system.
  /// Only admins and directors have permission for this operation.
  Future<List<User>> fetchAllUsers({
    int? limit,
    int offset = 0,
    String? search,
    String? roleFilter,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to fetch all users');
    }

    // Check permissions
    if (!_authService.canManageCoordinators()) {
      throw AuthorizationException('Insufficient permissions to view all users');
    }

    try {
      final queryParams = <String, dynamic>{
        'offset': offset.toString(),
      };

      if (limit != null) queryParams['limit'] = limit.toString();
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (roleFilter != null && roleFilter.isNotEmpty) queryParams['role'] = roleFilter;

      if (kDebugMode) {
        debugPrint('👥 UserService: Fetching all users with filters: $queryParams');
      }

      final response = await get(
        '/api/users',
        queryParameters: queryParams,
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        return [];
      }

      final users = _castUserList(result);

      if (kDebugMode) {
        debugPrint('✅ UserService: Retrieved ${users.length} total users');
      }

      return users;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error fetching all users: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  // ==========================================
  // USER DELETION
  // ==========================================

  /// Deletes a user by ID (admin/director only).
  ///
  /// This is a destructive operation that permanently removes the user
  /// and all associated data. Only admins and directors can delete users.
  Future<Map<String, dynamic>> deleteUser(
    int userId, {
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to delete users');
    }

    // Check permissions - only admins and directors can delete users
    if (!_authService.canManageCoaches()) {
      throw AuthorizationException('Insufficient permissions to delete users');
    }

    try {
      if (kDebugMode) {
        debugPrint('🗑️ UserService: Deleting user with ID: $userId');
        debugPrint('🔍 UserService: Current user role: ${_authService.getCurrentUserRole()}');
      }

      final response = await delete(
        '/api/users/$userId',
        context: context,
      );

      if (kDebugMode) {
        debugPrint('📡 UserService: Delete user response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final result = handleResponse(response) ?? {
          'success': true,
          'message': 'User deleted successfully'
        };

        if (kDebugMode) {
          debugPrint('✅ UserService: User $userId deleted successfully');
        }

        return result;
      } else {
        throw ApiException(
          'Failed to delete user: ${response.statusCode}',
          response.statusCode,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error deleting user $userId: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  // ==========================================
  // USER VALIDATION & UTILITIES
  // ==========================================

  /// Validates user data before submission.
  ///
  /// Returns a map with validation results and any errors found.
  Map<String, dynamic> validateUserData(Map<String, dynamic> userData) {
    final errors = <String>[];
    final warnings = <String>[];

    // Required field validation
    final username = userData['username'] as String?;
    if (username == null || username.trim().isEmpty) {
      errors.add('Username is required');
    } else if (username.length < 3) {
      errors.add('Username must be at least 3 characters');
    } else if (username.length > 50) {
      errors.add('Username must be 50 characters or less');
    }

    final name = userData['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      errors.add('Name is required');
    } else if (name.length > 100) {
      errors.add('Name must be 100 characters or less');
    }

    final email = userData['email'] as String?;
    if (email == null || email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(email)) {
      errors.add('Invalid email format');
    }

    // Password validation (only for new users or password changes)
    final password = userData['password'] as String?;
    if (password != null) {
      if (password.length < 6) {
        errors.add('Password must be at least 6 characters');
      } else if (password.length > 128) {
        errors.add('Password must be 128 characters or less');
      }
    }

    // Role validation
    final role = userData['role'] as String?;
    if (role != null) {
      const validRoles = ['coach', 'coordinator', 'director', 'admin'];
      if (!validRoles.contains(role)) {
        errors.add('Invalid role. Must be one of: ${validRoles.join(', ')}');
      }
    }

    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }

  /// Validates email format using a regular expression.
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  /// Checks if the current user can modify another user.
  bool canModifyUser(int targetUserId) {
    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return false;

    // Users can always modify themselves
    if (currentUser['id'] == targetUserId) return true;

    // Admins can modify anyone
    if (_authService.isAdmin()) return true;

    // Directors can modify coaches and coordinators
    if (_authService.isDirector()) return true;

    // Coordinators can modify coaches
    if (_authService.isCoordinator()) return true;

    return false;
  }

  /// Returns a summary of the current user's permissions.
  Map<String, bool> getUserPermissions() {
    return {
      'canRegisterUsers': _authService.canManageCoaches(),
      'canModifyUsers': _authService.canManageCoaches(),
      'canDeleteUsers': _authService.canManageCoaches(),
      'canViewAllUsers': _authService.canManageCoordinators(),
      'canManageRoles': _authService.isAdmin(),
    };
  }

  // ==========================================
  // USER STATUS & ACTIVITY
  // ==========================================

  /// Retrieves a user's activity summary.
  ///
  /// Returns recent activity and statistics for a user over the specified [days].
  Future<Map<String, dynamic>> getUserActivity(
    int userId, {
    int days = 30,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to get user activity');
    }

    try {
      final response = await get(
        '/api/users/$userId/activity',
        queryParameters: {'days': days.toString()},
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        return {
          'activities': [],
          'summary': {
            'totalActivities': 0,
            'lastActive': null,
          }
        };
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error fetching user activity: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }

  /// Updates a user's status (active/inactive).
  Future<Map<String, dynamic>> updateUserStatus(
    int userId,
    String status, {
    String? reason,
    BuildContext? context,
  }) async {
    await _authService.ensureInitialized();

    if (!isAuthenticated()) {
      throw AuthenticationException('Authentication required to update user status');
    }

    if (!_authService.canManageCoaches()) {
      throw AuthorizationException('Insufficient permissions to update user status');
    }

    try {
      final response = await patch(
        '/api/users/$userId/status',
        data: {
          'status': status,
          if (reason != null) 'reason': reason,
        },
        context: context,
      );

      final result = handleResponse(response);
      if (result == null) {
        throw ApiException('Failed to update user status: empty response');
      }

      return result;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ UserService: Error updating user status: $e');
      }

      if (e is AuthenticationException && context != null) {
        handleAuthenticationError(context);
      }

      rethrow;
    }
  }
}