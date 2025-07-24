// lib/utils/validation_helper.dart
import 'package:flutter/material.dart';

/// A utility class that provides common form validation functions
class ValidationHelper {
  /// Validates if a field has a value
  static FormFieldValidator<String> required(String errorMessage) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return errorMessage;
      }
      return null;
    };
  }

  /// Validates if a string is a valid email address
  static FormFieldValidator<String> email([String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty if email is optional
      }
      
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return errorMessage ?? 'Please enter a valid email address';
      }
      return null;
    };
  }

  /// Validates if a string is a valid phone number (basic validation)
  static FormFieldValidator<String> phone([String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty if phone is optional
      }
      
      // Simple validation - could be more sophisticated in a real app
      if (value.length < 10) {
        return errorMessage ?? 'Please enter a valid phone number';
      }
      return null;
    };
  }

  /// Validates if a number is within a specified range
  static FormFieldValidator<String> numberRange(double min, double max, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty for optional fields
      }
      
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      
      if (number < min || number > max) {
        return errorMessage ?? 'Value must be between $min and $max';
      }
      
      return null;
    };
  }

  /// Validates if a number is greater than a minimum value
  static FormFieldValidator<String> minValue(double min, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty for optional fields
      }
      
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      
      if (number < min) {
        return errorMessage ?? 'Value must be at least $min';
      }
      
      return null;
    };
  }

  /// Validates if a number is less than a maximum value
  static FormFieldValidator<String> maxValue(double max, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty for optional fields
      }
      
      final number = double.tryParse(value);
      if (number == null) {
        return 'Please enter a valid number';
      }
      
      if (number > max) {
        return errorMessage ?? 'Value must be less than $max';
      }
      
      return null;
    };
  }

  /// Validates if a string has a minimum length
  static FormFieldValidator<String> minLength(int length, [String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return null; // Allow empty for optional fields
      }
      
      if (value.length < length) {
        return errorMessage ?? 'Must be at least $length characters';
      }
      
      return null;
    };
  }

  /// Combines multiple validators into a single validator
  static FormFieldValidator<String> compose(List<FormFieldValidator<String>> validators) {
    return (value) {
      for (final validator in validators) {
        final result = validator(value);
        if (result != null) {
          return result;
        }
      }
      return null;
    };
  }

  /// Validates a password for common strength requirements
  static FormFieldValidator<String> password([String? errorMessage]) {
    return (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter a password';
      }
      
      if (value.length < 8) {
        return 'Password must be at least 8 characters';
      }
      
      bool hasUppercase = value.contains(RegExp(r'[A-Z]'));
      bool hasDigits = value.contains(RegExp(r'[0-9]'));
      bool hasSpecialChars = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      
      if (!hasUppercase || !hasDigits || !hasSpecialChars) {
        return errorMessage ?? 'Password must contain uppercase, digits, and special characters';
      }
      
      return null;
    };
  }
}