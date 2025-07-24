// lib/services/auth/registration_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for handling user registration requests and access management
/// 
/// This service provides:
/// - User access request submission
/// - Registration request management (admin functions)
/// - Request approval/denial workflow
/// - Registration status tracking
class RegistrationService {
  final String baseUrl;
  
  RegistrationService({required this.baseUrl});
  
  // ==========================================
  // USER ACCESS REQUESTS
  // ==========================================
  
  /// Submit a request for access to the system
  /// 
  /// [requestData] should contain:
  /// - name: Full name of the requester
  /// - email: Email address
  /// - organization: Organization/team name
  /// - role: Requested role (coach, coordinator, etc.)
  /// - reason: Reason for access request
  /// - phone: Optional phone number
  Future<Map<String, dynamic>> requestAccess(Map<String, dynamic> requestData) async {
    try {
      if (kDebugMode) {
        print('📝 RegistrationService: Submitting access request for ${requestData['email']}');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/registration/request'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ RegistrationService: Access request submitted successfully');
        }
        
        return result;
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception('Registration request failed: ${errorBody['message'] ?? 'Unknown error'} (${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error submitting access request: $e');
      }
      rethrow;
    }
  }
  
  // ==========================================
  // ADMIN FUNCTIONS - REQUEST MANAGEMENT
  // ==========================================
  
  /// Get all pending registration requests (admin only)
  Future<List<Map<String, dynamic>>> getRegistrationRequests({
    String status = 'pending',
    int? limit,
    int offset = 0,
  }) async {
    try {
      final queryParams = <String, String>{
        'status': status,
        'offset': offset.toString(),
      };
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final uri = Uri.parse('$baseUrl/api/registration/requests').replace(queryParameters: queryParams);
      
      if (kDebugMode) {
        print('📋 RegistrationService: Fetching registration requests (status: $status)');
      }
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final requests = data is List ? data : (data['requests'] as List? ?? []);
        
        if (kDebugMode) {
          print('✅ RegistrationService: Retrieved ${requests.length} registration requests');
        }
        
        return requests.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch registration requests: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error fetching registration requests: $e');
      }
      rethrow;
    }
  }
  
  /// Approve a registration request (admin only)
  Future<Map<String, dynamic>> approveRegistration(
    int requestId, {
    String? assignedRole,
    String? welcomeMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (kDebugMode) {
        print('✅ RegistrationService: Approving registration request $requestId');
      }
      
      final requestData = {
        'status': 'approved',
        if (assignedRole != null) 'assigned_role': assignedRole,
        if (welcomeMessage != null) 'welcome_message': welcomeMessage,
        if (additionalData != null) ...additionalData,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/registration/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ RegistrationService: Registration request $requestId approved successfully');
        }
        
        return result;
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception('Failed to approve registration: ${errorBody['message'] ?? 'Unknown error'} (${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error approving registration: $e');
      }
      rethrow;
    }
  }
  
  /// Deny a registration request (admin only)
  Future<Map<String, dynamic>> denyRegistration(
    int requestId, {
    String? reason,
    String? message,
  }) async {
    try {
      if (kDebugMode) {
        print('❌ RegistrationService: Denying registration request $requestId');
      }
      
      final requestData = {
        'status': 'denied',
        if (reason != null) 'denial_reason': reason,
        if (message != null) 'denial_message': message,
      };
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/registration/requests/$requestId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestData),
      );
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        
        if (kDebugMode) {
          print('✅ RegistrationService: Registration request $requestId denied successfully');
        }
        
        return result;
      } else {
        final errorBody = response.body.isNotEmpty ? json.decode(response.body) : {};
        throw Exception('Failed to deny registration: ${errorBody['message'] ?? 'Unknown error'} (${response.statusCode})');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error denying registration: $e');
      }
      rethrow;
    }
  }
  
  /// Get details of a specific registration request
  Future<Map<String, dynamic>> getRegistrationRequest(int requestId) async {
    try {
      if (kDebugMode) {
        print('📋 RegistrationService: Fetching registration request $requestId');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/registration/requests/$requestId'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('Registration request not found');
      } else {
        throw Exception('Failed to fetch registration request: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error fetching registration request: $e');
      }
      rethrow;
    }
  }
  
  // ==========================================
  // STATUS TRACKING
  // ==========================================
  
  /// Check the status of a registration request by email
  Future<Map<String, dynamic>?> checkRequestStatus(String email) async {
    try {
      if (kDebugMode) {
        print('🔍 RegistrationService: Checking request status for $email');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/registration/status').replace(
          queryParameters: {'email': email}
        ),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        // No request found for this email
        return null;
      } else {
        throw Exception('Failed to check request status: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error checking request status: $e');
      }
      rethrow;
    }
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  /// Validate registration request data
  Map<String, dynamic> validateRegistrationData(Map<String, dynamic> requestData) {
    final errors = <String>[];
    final warnings = <String>[];
    
    // Required field validation
    final name = requestData['name'] as String?;
    if (name == null || name.trim().isEmpty) {
      errors.add('Name is required');
    } else if (name.length > 100) {
      errors.add('Name must be 100 characters or less');
    }
    
    final email = requestData['email'] as String?;
    if (email == null || email.trim().isEmpty) {
      errors.add('Email is required');
    } else if (!_isValidEmail(email)) {
      errors.add('Invalid email format');
    }
    
    final organization = requestData['organization'] as String?;
    if (organization == null || organization.trim().isEmpty) {
      errors.add('Organization is required');
    } else if (organization.length > 100) {
      errors.add('Organization name must be 100 characters or less');
    }
    
    final role = requestData['role'] as String?;
    if (role == null || role.trim().isEmpty) {
      errors.add('Requested role is required');
    } else {
      const validRoles = ['coach', 'coordinator', 'director'];
      if (!validRoles.contains(role.toLowerCase())) {
        warnings.add('Role should be one of: ${validRoles.join(', ')}');
      }
    }
    
    final reason = requestData['reason'] as String?;
    if (reason == null || reason.trim().isEmpty) {
      errors.add('Reason for access is required');
    } else if (reason.length > 500) {
      errors.add('Reason must be 500 characters or less');
    }
    
    // Optional field validation
    final phone = requestData['phone'] as String?;
    if (phone != null && phone.isNotEmpty && !_isValidPhone(phone)) {
      warnings.add('Phone number format may be invalid');
    }
    
    return {
      'isValid': errors.isEmpty,
      'errors': errors,
      'warnings': warnings,
      'hasWarnings': warnings.isNotEmpty,
    };
  }
  
  /// Simple email validation
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }
  
  /// Simple phone validation
  bool _isValidPhone(String phone) {
    // Basic phone validation - allows various formats
    return RegExp(r'^[\+]?[0-9\s\-\(\)]{10,}$').hasMatch(phone);
  }
  
  /// Get service health status
  Future<Map<String, dynamic>> getServiceHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/registration/health'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'status': 'error',
          'message': 'Health check failed',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Health check failed: $e');
      }
      
      return {
        'status': 'error',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }
  
  /// Get registration statistics (admin only)
  Future<Map<String, dynamic>> getRegistrationStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/registration/stats'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch registration statistics: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ RegistrationService: Error fetching registration stats: $e');
      }
      rethrow;
    }
  }
  
  // ==========================================
  // CONVENIENCE METHODS
  // ==========================================
  
  /// Submit a coach registration request with pre-filled role
  Future<Map<String, dynamic>> requestCoachAccess({
    required String name,
    required String email,
    required String organization,
    required String reason,
    String? phone,
  }) async {
    return await requestAccess({
      'name': name,
      'email': email,
      'organization': organization,
      'role': 'coach',
      'reason': reason,
      if (phone != null) 'phone': phone,
    });
  }
  
  /// Submit a coordinator registration request with pre-filled role
  Future<Map<String, dynamic>> requestCoordinatorAccess({
    required String name,
    required String email,
    required String organization,
    required String reason,
    String? phone,
  }) async {
    return await requestAccess({
      'name': name,
      'email': email,
      'organization': organization,
      'role': 'coordinator',
      'reason': reason,
      if (phone != null) 'phone': phone,
    });
  }
  
  /// Bulk approve multiple registration requests
  Future<List<Map<String, dynamic>>> bulkApproveRequests(
    List<int> requestIds, {
    String? defaultRole,
    String? welcomeMessage,
  }) async {
    final results = <Map<String, dynamic>>[];
    
    for (final requestId in requestIds) {
      try {
        final result = await approveRegistration(
          requestId,
          assignedRole: defaultRole,
          welcomeMessage: welcomeMessage,
        );
        results.add(result);
      } catch (e) {
        results.add({
          'request_id': requestId,
          'success': false,
          'error': e.toString(),
        });
      }
    }
    
    return results;
  }
}