// lib/utils/formatting_utils.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utilities for formatting data for display
class FormattingUtils {
  /// Format a DateTime to a readable string
  static String formatDate(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy');
    return formatter.format(date);
  }
  
  /// Format a DateTime to include time
  static String formatDateTime(DateTime date) {
    final formatter = DateFormat('MMM d, yyyy - h:mm a');
    return formatter.format(date);
  }
  
  /// Format a performance score as a percentage
  static String formatPerformanceScore(double score) {
    return '${(score * 100).round()}%';
  }
  
  /// Get color for a performance level
  static Color getPerformanceColor(double value) {
    if (value >= 0.8) return Colors.green;
    if (value >= 0.6) return Colors.lightGreen;
    if (value >= 0.4) return Colors.amber;
    if (value >= 0.2) return Colors.orange;
    return Colors.red;
  }
  
  /// Get label for a performance level
  static String getPerformanceLevelLabel(double value) {
    if (value >= 0.8) return 'Elite';
    if (value >= 0.6) return 'Advanced';
    if (value >= 0.4) return 'Intermediate';
    if (value >= 0.2) return 'Developing';
    return 'Beginner';
  }
  
  /// Format category name from camelCase or snake_case to Title Case
  static String formatCategoryName(String name) {
    // Convert camelCase or snake_case to Title Case with spaces
    final formattedName = name
        .replaceAllMapped(
            RegExp(r'([A-Z])'), (match) => ' ${match.group(0)}')
        .replaceAll('_', ' ')
        .trim()
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
    
    return formattedName;
  }
}