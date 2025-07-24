// lib/services/base/base_api_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// Base class for all API services providing common HTTP functionality
/// 
/// This abstract class provides:
/// - Dio HTTP client setup and configuration
/// - Common HTTP methods (get, post, put, delete, patch)
/// - Standardized error handling and custom exceptions
/// - Response parsing and validation
/// - Request/response logging in debug mode
abstract class BaseApiService {
  // ==========================================
  // PROPERTIES & INITIALIZATION
  // ==========================================
  
  late final Dio _dio;
  final String baseUrl;
  final void Function(BuildContext?)? onTokenExpired;
  
  BaseApiService({
    required this.baseUrl,
    this.onTokenExpired,
  }) {
    _setupDio();
  }
  
  /// Get the Dio instance for custom requests
  Dio get dio => _dio;
  
  // ==========================================
  // DIO SETUP & CONFIGURATION
  // ==========================================
  
  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      headers: ApiConfig.defaultHeaders,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));
    
    _setupInterceptors();
  }
  
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add authentication headers if available
          final authHeaders = await getAuthHeaders();
          if (authHeaders.isNotEmpty) {
            options.headers.addAll(authHeaders);
          }
          
          if (kDebugMode) {
            print('🌐 ${options.method.toUpperCase()} ${options.path}');
            if (options.queryParameters.isNotEmpty) {
              print('📋 Query: ${options.queryParameters}');
            }
            if (options.data != null) {
              print('📤 Data: ${_truncateData(options.data)}');
            }
          }
          
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('✅ ${response.statusCode} ${response.requestOptions.path}');
            print('📥 Response: ${_truncateData(response.data)}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print('❌ ${error.requestOptions.path}: ${error.message}');
            if (error.response?.data != null) {
              print('📥 Error Data: ${error.response?.data}');
            }
          }
          
          // Handle authentication errors globally
          if (error.response?.statusCode == 401) {
            _handleAuthenticationError(error, handler);
            return;
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  // ==========================================
  // ABSTRACT METHODS (must be implemented by subclasses)
  // ==========================================
  
  /// Get authentication headers for requests
  /// Each service can implement its own auth logic
  Future<Map<String, String>> getAuthHeaders();
  
  /// Check if the service is authenticated
  bool isAuthenticated();
  
  /// Handle authentication errors (token expired, etc.)
  void handleAuthenticationError(BuildContext? context);
  
  // ==========================================
  // COMMON HTTP METHODS
  // ==========================================
  
  /// Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    BuildContext? context,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: _mergeOptions(options, context),
      );
    } catch (e) {
      throw _handleException(e, 'GET $path');
    }
  }
  
  /// Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    BuildContext? context,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, context),
      );
    } catch (e) {
      throw _handleException(e, 'POST $path');
    }
  }
  
  /// Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    BuildContext? context,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, context),
      );
    } catch (e) {
      throw _handleException(e, 'PUT $path');
    }
  }
  
  /// Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    BuildContext? context,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, context),
      );
    } catch (e) {
      throw _handleException(e, 'DELETE $path');
    }
  }
  
  /// Generic PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    BuildContext? context,
  }) async {
    try {
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(options, context),
      );
    } catch (e) {
      throw _handleException(e, 'PATCH $path');
    }
  }
  
  // ==========================================
  // RESPONSE HANDLING & PARSING
  // ==========================================
  
  /// Parse JSON response safely
  Map<String, dynamic>? parseJsonResponse(Response response) {
    try {
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      } else if (response.data is String) {
        return jsonDecode(response.data) as Map<String, dynamic>;
      } else {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing JSON response: $e');
      }
      throw ApiException('Invalid JSON response', response.statusCode);
    }
  }
  
  /// Handle HTTP response with proper status code checking
  Map<String, dynamic>? handleResponse(Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return parseJsonResponse(response);
      
      case 400:
        final errorData = parseJsonResponse(response);
        throw ApiException(
          errorData?['message'] ?? 'Bad request',
          400,
          errorData,
        );
      
      case 401:
        throw AuthenticationException('Unauthorized - please check credentials');
      
      case 403:
        throw AuthorizationException('Access forbidden');
      
      case 404:
        return null; // Return null for not found instead of throwing
      
      case 409:
        final errorData = parseJsonResponse(response);
        throw ConflictException(
          errorData?['message'] ?? 'Conflict',
          errorData,
        );
      
      case 500:
      case 502:
      case 503:
      case 504:
        throw ServerException('Server error - please try again later');
      
      default:
        throw ApiException('Unexpected response: ${response.statusCode}');
    }
  }
  
  // ==========================================
  // ERROR HANDLING
  // ==========================================
  
  void _handleAuthenticationError(DioException error, ErrorInterceptorHandler handler) {
    final context = error.requestOptions.extra['context'] as BuildContext?;
    handleAuthenticationError(context);
    handler.next(error);
  }
  
  Exception _handleException(dynamic error, String operation) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return TimeoutException('Request timeout for $operation');
        
        case DioExceptionType.connectionError:
          return NetworkException('Network connection error for $operation');
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 0;
          final message = error.response?.data?['message'] ?? 
                         error.response?.data?['error'] ?? 
                         'HTTP $statusCode error';
          return ApiException(message, statusCode, error.response?.data);
        
        default:
          return ApiException('Request failed: ${error.message}');
      }
    }
    
    return ApiException('Unexpected error in $operation: $error');
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  Options _mergeOptions(Options? options, BuildContext? context) {
    final baseOptions = Options(
      extra: {'context': context},
    );
    
    if (options == null) return baseOptions;
    
    return options.copyWith(
      extra: {...baseOptions.extra!, ...?options.extra},
    );
  }
  
  String _truncateData(dynamic data, {int maxLength = 200}) {
    if (data == null) return 'null';
    
    final dataStr = data.toString();
    if (dataStr.length <= maxLength) return dataStr;
    
    return '${dataStr.substring(0, maxLength)}... (truncated)';
  }
  
  /// Validate required fields in request data
  void validateRequiredFields(Map<String, dynamic> data, List<String> requiredFields) {
    final missing = <String>[];
    
    for (final field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        missing.add(field);
      }
    }
    
    if (missing.isNotEmpty) {
      throw ValidationException('Missing required fields: ${missing.join(', ')}');
    }
  }
  
  /// Clean and validate data before sending
  Map<String, dynamic> cleanRequestData(Map<String, dynamic> data) {
    final cleaned = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value != null) {
        // Convert empty strings to null for optional fields
        if (value is String && value.trim().isEmpty) {
          cleaned[key] = null;
        } else {
          cleaned[key] = value;
        }
      }
    });
    
    return cleaned;
  }
}

// ==========================================
// CUSTOM EXCEPTION CLASSES
// ==========================================

/// Base API exception class
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;
  
  const ApiException(this.message, [this.statusCode, this.data]);
  
  @override
  String toString() {
    return 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
  }
  
  /// Get user-friendly error message
  String get userMessage {
    switch (statusCode) {
      case 400:
        return 'Invalid request data. Please check your inputs.';
      case 401:
        return 'Please log in to continue.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 409:
        return 'This action conflicts with existing data.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return message;
    }
  }
}

/// Authentication-specific exception
class AuthenticationException extends ApiException {
  const AuthenticationException(String message) : super(message, 401);
}

/// Authorization-specific exception  
class AuthorizationException extends ApiException {
  const AuthorizationException(String message) : super(message, 403);
}

/// Validation-specific exception
class ValidationException extends ApiException {
  const ValidationException(String message) : super(message, 400);
}

/// Conflict-specific exception
class ConflictException extends ApiException {
  const ConflictException(String message, [Map<String, dynamic>? data]) 
      : super(message, 409, data);
}

/// Network-specific exception
class NetworkException extends ApiException {
  const NetworkException(String message) : super(message);
}

/// Timeout-specific exception
class TimeoutException extends ApiException {
  const TimeoutException(String message) : super(message);
}

/// Server error exception
class ServerException extends ApiException {
  const ServerException(String message) : super(message, 500);
}