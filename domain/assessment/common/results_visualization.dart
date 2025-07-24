import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/interactive_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/radar_chart_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/visualization/distribution_display.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';

/// Visualization components for assessment results
class ResultsVisualization {
  /// Creates an interactive trend chart for player progress over time
  static Widget buildProgressTrendChart({
    required int playerId,
    required String metricKey,
    required String title,
    String? subtitle,
    Color color = Colors.blue,
    bool isPercentage = false,
    int dateRange = 90,
    String interval = 'week',
  }) {
    if (isPercentage) {
      return InteractiveTrendChart.successRate(
        playerId: playerId,
        dateRange: dateRange,
        interval: interval,
        title: title,
        subtitle: subtitle,
        enableZoom: true,
      );
    } else {
      return InteractiveTrendChart(
        playerId: playerId,
        dateRange: dateRange,
        interval: interval,
        metric: metricKey,
        title: title,
        subtitle: subtitle,
        lineColor: color,
        enableZoom: true,
        isPercentage: isPercentage,
      );
    }
  }
  
  /// Creates a radar chart comparing current assessment with previous or benchmark
  static Widget buildComparisonRadarChart({
    required Map<String, double> currentScores,
    required Map<String, double>? previousScores,
    required String title,
    String? subtitle,
    String currentLabel = 'Current',
    String previousLabel = 'Previous',
  }) {
    return RadarChartWidget(
      dataPoints: currentScores,
      comparisonDataPoints: previousScores,
      title: title,
      subtitle: subtitle,
      primaryColor: Colors.blue,
      secondaryColor: Colors.grey,
      primaryLabel: currentLabel,
      secondaryLabel: previousLabel,
      maxValue: 10.0,
      normalizeValues: true,
    );
  }
  
  /// Creates a zone performance grid with enhanced interactivity
  static Widget buildEnhancedZoneGrid({
    required Map<String, Map<String, dynamic>> zoneData,
    required Map<String, String> zoneLabels,
    required String title,
    String? subtitle,
  }) {
    return DistributionDisplay.zoneGrid(
      title: title,
      subtitle: subtitle,
      zoneData: zoneData,
      zoneLabels: zoneLabels,
      countKey: 'count',
      successRateKey: 'successRate',
    );
  }
  
  /// Creates a category performance chart
  static Widget buildCategoryPerformanceChart({
    required Map<String, double> categoryScores,
    String? previousAssessmentId,
    Map<String, double>? previousScores,
  }) {
    // If we have previous scores, use a radar chart for comparison
    if (previousScores != null) {
      return buildComparisonRadarChart(
        currentScores: categoryScores,
        previousScores: previousScores,
        title: 'Category Performance',
        subtitle: 'Comparison with previous assessment',
        currentLabel: 'Current Assessment',
        previousLabel: 'Previous Assessment',
      );
    }
    
    // Otherwise, use a standard distribution display
    final chartData = <String, Map<String, dynamic>>{};
    
    // Create color generator function for compatibility
    Color Function(String, dynamic)? colorGeneratorFunc = (key, value) {
      return ColorHelper.getScoreColor((value as num).toDouble() / 10);
    };
    
    for (var entry in categoryScores.entries) {
      if (entry.key != 'Overall') {
        chartData[entry.key] = {
          'score': entry.value,
          'label': entry.key,
          'color': ColorHelper.getScoreColor(entry.value / 10),
        };
      }
    }
    
    return DistributionDisplay.barChart(
      title: 'Category Performance',
      data: chartData,
      countKey: 'score',
      labelKey: 'label',
      // Pass color generator function
      colorMap: chartData.map((key, value) => MapEntry(key, value['color'] as Color)),
    );
  }
}