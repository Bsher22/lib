import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'dart:math' show pi, min, max;

class RadarChartWidget extends StatelessWidget {
  /// Map of category names to values (0-10 or 0-1 range)
  final Map<String, double> dataPoints;

  /// Optional second data set for comparison (same categories)
  final Map<String, double>? comparisonDataPoints;

  /// Title displayed above the chart
  final String title;

  /// Subtitle displayed below the title
  final String? subtitle;

  /// Primary color for the data
  final Color primaryColor;

  /// Secondary color for comparison data
  final Color secondaryColor;

  /// Maximum value represented on the chart (defaults to 10)
  final double maxValue;

  /// Labels for the legend (if comparison data is provided)
  final String? primaryLabel;
  final String? secondaryLabel;

  /// Whether to normalize values to 0-1 range
  final bool normalizeValues;

  /// Whether to use a card container
  final bool useCard;

  /// Custom padding for the card
  final EdgeInsetsGeometry padding;

  /// Whether to show values on the vertices
  final bool showValues;

  const RadarChartWidget({
    Key? key,
    required this.dataPoints,
    this.comparisonDataPoints,
    required this.title,
    this.subtitle,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.red,
    this.maxValue = 10.0,
    this.primaryLabel,
    this.secondaryLabel,
    this.normalizeValues = false,
    this.useCard = true,
    this.padding = const EdgeInsets.all(16),
    this.showValues = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort categories alphabetically for consistent ordering
    final sortedCategories = dataPoints.keys.toList()..sort();

    // Normalize values if needed
    Map<String, double> normalizedData = dataPoints;
    Map<String, double>? normalizedComparisonData = comparisonDataPoints;

    if (normalizeValues) {
      normalizedData = _normalizeValues(dataPoints);
      if (comparisonDataPoints != null) {
        normalizedComparisonData = _normalizeValues(comparisonDataPoints!);
      }
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueGrey[800],
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.0,
          child: _buildRadarChart(sortedCategories, normalizedData, normalizedComparisonData),
        ),
        if (comparisonDataPoints != null && primaryLabel != null && secondaryLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(primaryLabel!, primaryColor),
                const SizedBox(width: 24),
                _buildLegendItem(secondaryLabel!, secondaryColor),
              ],
            ),
          ),
      ],
    );

    if (useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: padding,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildRadarChart(
    List<String> categories,
    Map<String, double> normalizedData,
    Map<String, double>? normalizedComparisonData,
  ) {
    return RadarChart(
      RadarChartData(
        dataSets: [
          // Primary data set
          RadarDataSet(
            fillColor: primaryColor.withOpacity(0.2),
            borderColor: primaryColor,
            entryRadius: 1,
            borderWidth: 2,
            dataEntries: categories.map((category) {
              return RadarEntry(
                value: normalizedData[category] ?? 0,
              );
            }).toList(),
          ),
          // Optional comparison data set
          if (normalizedComparisonData != null)
            RadarDataSet(
              fillColor: secondaryColor.withOpacity(0.2),
              borderColor: secondaryColor,
              entryRadius: 1,
              borderWidth: 2,
              dataEntries: categories.map((category) {
                return RadarEntry(
                  value: normalizedComparisonData[category] ?? 0,
                );
              }).toList(),
            ),
        ],
        radarShape: RadarShape.polygon,
        radarBorderData: const BorderSide(color: Colors.black12),
        ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
        tickBorderData: const BorderSide(color: Colors.black12, width: 1),
        gridBorderData: const BorderSide(color: Colors.black12, width: 1),
        tickCount: 5,
        titleTextStyle: TextStyle(
          color: Colors.blueGrey[700],
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        titlePositionPercentageOffset: 0.1,
        radarBackgroundColor: Colors.transparent,
        borderData: FlBorderData(show: false),
        getTitle: (index, angle) {
          if (index >= 0 && index < categories.length) {
            final category = categories[index];
            final value = normalizedData[category]?.toStringAsFixed(1) ?? "0.0";
            final displayText = showValues
                ? '$category\n$value'
                : category;

            return RadarChartTitle(
              text: displayText,
              angle: angle,
            );
          }
          return const RadarChartTitle(text: '');
        },
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            border: Border.all(color: color, width: 2),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// Normalize values to 0-1 range based on the maximum value
  Map<String, double> _normalizeValues(Map<String, double> data) {
    final normalizationFactor = maxValue;
    return data.map((key, value) {
      return MapEntry(key, (value / normalizationFactor).clamp(0.0, 1.0));
    });
  }

  /// Factory method for player skill comparison
  factory RadarChartWidget.playerSkills({
    required Map<String, double> playerSkills,
    Map<String, double>? comparisonPlayerSkills,
    String title = 'Player Skills',
    String? subtitle,
    String? playerName,
    String? comparisonPlayerName,
  }) {
    return RadarChartWidget(
      dataPoints: playerSkills,
      comparisonDataPoints: comparisonPlayerSkills,
      title: title,
      subtitle: subtitle,
      primaryColor: Colors.blue,
      secondaryColor: Colors.red,
      primaryLabel: playerName ?? 'Current Player',
      secondaryLabel: comparisonPlayerName ?? 'Comparison',
      maxValue: 10.0,
      normalizeValues: true,
    );
  }

  /// Factory method for team performance visualization
  factory RadarChartWidget.teamPerformance({
    required Map<String, double> teamMetrics,
    String title = 'Team Performance',
    String? subtitle,
  }) {
    return RadarChartWidget(
      dataPoints: teamMetrics,
      title: title,
      subtitle: subtitle,
      primaryColor: Colors.green,
      maxValue: 10.0,
      normalizeValues: true,
    );
  }

  /// Factory method for position comparison
  factory RadarChartWidget.positionComparison({
    required Map<String, double> forwardMetrics,
    required Map<String, double> defenseMetrics,
    String title = 'Position Comparison',
    String? subtitle,
  }) {
    return RadarChartWidget(
      dataPoints: forwardMetrics,
      comparisonDataPoints: defenseMetrics,
      title: title,
      subtitle: subtitle,
      primaryColor: Colors.blue,
      secondaryColor: Colors.green,
      primaryLabel: 'Forwards',
      secondaryLabel: 'Defense',
      maxValue: 10.0,
      normalizeValues: true,
    );
  }
}