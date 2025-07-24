import 'package:flutter/material.dart';

class ColorHelper {
  static Color getSuccessRateColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.lightGreen;
    if (rate >= 0.4) return Colors.yellow;
    if (rate >= 0.2) return Colors.orange;
    return Colors.red;
  }

  static String getSuccessRateDescription(double rate) {
    if (rate >= 0.8) return 'Excellent';
    if (rate >= 0.6) return 'Good';
    if (rate >= 0.4) return 'Average';
    if (rate >= 0.2) return 'Below Average';
    return 'Needs Work';
  }

  static Color getPowerColor(double power) {
    if (power >= 80) return Colors.purple;
    if (power >= 70) return Colors.blue;
    if (power >= 60) return Colors.green;
    if (power >= 50) return Colors.orange;
    return Colors.red;
  }

  static String getPowerDescription(double power) {
    if (power >= 80) return 'Elite';
    if (power >= 70) return 'Excellent';
    if (power >= 60) return 'Good';
    if (power >= 50) return 'Average';
    return 'Developing';
  }

  static Color getQuickReleaseColor(double time) {
    if (time <= 0.5) return Colors.purple;
    if (time <= 0.75) return Colors.blue;
    if (time <= 1.0) return Colors.green;
    if (time <= 1.25) return Colors.orange;
    return Colors.red;
  }

  static String getQuickReleaseDescription(double time) {
    if (time <= 0.5) return 'Elite';
    if (time <= 0.75) return 'Excellent';
    if (time <= 1.0) return 'Good';
    if (time <= 1.25) return 'Average';
    return 'Developing';
  }

  static String getVolumeDescription(int volume) {
    if (volume >= 100) return 'High volume';
    if (volume >= 50) return 'Good volume';
    if (volume >= 20) return 'Moderate volume';
    return 'Low volume';
  }
  
  // SHOT TYPE METHODS
  
  /// Returns a color for a shot type
  static Color getShotTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'wrist':
        return Colors.blue;
      case 'slap':
        return Colors.red;
      case 'snap':
        return Colors.green;
      case 'backhand':
        return Colors.purple;
      case 'one-timer':
        return Colors.orange;
      case 'deflection':
        return Colors.teal;
      default:
        return Colors.blueGrey;
    }
  }
  
  /// Returns a map of colors for all shot types
  static Map<String, Color> getShotTypeColorMap() {
    return {
      'wrist': Colors.blue,
      'slap': Colors.red,
      'snap': Colors.green,
      'backhand': Colors.purple,
      'one-timer': Colors.orange,
      'deflection': Colors.teal,
    };
  }
  
  // GENERAL PERFORMANCE METHODS
  
  /// Returns a color for a percentage value (used for zone heatmaps)
  static Color getPercentageColor(double percentage) {
    // Normalize percentage to 0-1 range if needed
    final normalizedValue = percentage > 1.0 ? percentage / 100 : percentage;
    
    if (normalizedValue < 0.2) {
      return Colors.red;
    } else if (normalizedValue < 0.4) {
      return Colors.orange;
    } else if (normalizedValue < 0.6) {
      return Colors.yellow;
    } else if (normalizedValue < 0.8) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
  
  /// Get a color for a score value (0-10)
  static Color getScoreColor(double score) {
    // Convert to percentage (0-1 range)
    return getSuccessRateColor(score / 10);
  }
  
  /// Returns a color for a generic metric based on a min/max range
  static Color getMetricColor(double value, double minValue, double maxValue) {
    // Normalize to 0-1 range
    final normalizedValue = (value - minValue) / (maxValue - minValue);
    return getSuccessRateColor(normalizedValue);
  }

  // SKATING-SPECIFIC METHODS
  
  /// Get color for skating benchmark levels
  static Color getBenchmarkLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'average':
        return Colors.orange;
      case 'below average':
        return Colors.deepOrange;
      case 'needs work':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get color for percentile rankings
  static Color getPercentileColor(double percentile) {
    if (percentile >= 90) return Colors.green;
    if (percentile >= 75) return Colors.lightGreen;
    if (percentile >= 50) return Colors.orange;
    if (percentile >= 25) return Colors.deepOrange;
    return Colors.red;
  }

  /// Get color for skating performance trends
  static Color getTrendColor(String trend) {
    switch (trend.toLowerCase()) {
      case 'excellent':
      case 'elite':
        return Colors.green;
      case 'good':
      case 'strong':
        return Colors.lightGreen;
      case 'developing':
      case 'average':
        return Colors.orange;
      case 'needs_focus':
      case 'needs work':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get color for priority levels
  static Color getPriorityColor(String priorityLevel) {
    switch (priorityLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get trend icon based on percentile
  static IconData getTrendIcon(double percentile) {
    if (percentile >= 75) return Icons.trending_up;
    if (percentile >= 50) return Icons.trending_flat;
    return Icons.trending_down;
  }

  /// Get category icon for skating categories
  static IconData getSkatingCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'speed':
      case 'forward speed':
        return Icons.keyboard_double_arrow_right;
      case 'backward speed':
        return Icons.keyboard_double_arrow_left;
      case 'agility':
        return Icons.change_circle;
      case 'transitions':
        return Icons.swap_horiz;
      case 'technique':
      case 'crossovers':
        return Icons.precision_manufacturing;
      case 'power':
      case 'stop_start':
        return Icons.flash_on;
      default:
        return Icons.speed;
    }
  }
}