// widgets/assessment/common/benchmark_display_widget.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';

/// A reusable widget for displaying performance benchmarks
class BenchmarkDisplayWidget extends StatelessWidget {
  /// Map of benchmark names to time values
  final Map<String, double> benchmarks;
  
  /// Optional size for the benchmark circles
  final double circleSize;
  
  /// Optional text style for the benchmark labels
  final TextStyle? labelStyle;
  
  /// Optional text style for the benchmark values
  final TextStyle? valueStyle;
  
  /// Optional mapping of benchmark names to custom colors
  final Map<String, Color>? benchmarkColors;
  
  const BenchmarkDisplayWidget({
    Key? key,
    required this.benchmarks,
    this.circleSize = 48,
    this.labelStyle,
    this.valueStyle,
    this.benchmarkColors,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Default benchmark colors
    final defaultColors = {
      'Excellent': Colors.green,
      'Good': Colors.lightGreen,
      'Average': Colors.orange,
      'Below Average': Colors.red,
    };
    
    // Use custom colors if provided, otherwise use defaults
    final effectiveColors = benchmarkColors ?? defaultColors;
    
    return StandardCard(
      borderRadius: 12,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Benchmarks',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: benchmarks.entries.map((entry) {
                final color = effectiveColors[entry.key] ?? Colors.grey;
                return _buildBenchmarkItem(entry.key, entry.value, color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBenchmarkItem(String label, double value, Color color) {
    return Column(
      children: [
        Container(
          width: circleSize,
          height: circleSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: valueStyle ?? TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        StatusBadge(
          text: label,
          color: color,
          size: StatusBadgeSize.small,
          shape: StatusBadgeShape.pill,
        ),
      ],
    );
  }
}