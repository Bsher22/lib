// widgets/assessment/common/test_results_table.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/skating.dart';

/// A widget that displays a filterable table of skating test results
class TestResultsTable extends StatelessWidget {
  /// List of test results to display
  /// Each map contains:
  /// - 'group': Map<String, dynamic> with group data
  /// - 'test': Map<String, dynamic> with test data
  /// - 'result': Map<String, dynamic> with result data
  final List<Map<String, dynamic>> testResults;
  
  /// Message to display when there are no results
  final String emptyMessage;
  
  /// Optional custom styling for the table header
  final TextStyle? headerStyle;
  
  /// Optional callback when a row is tapped
  final Function(Map<String, dynamic>)? onRowTap;
  
  const TestResultsTable({
    Key? key,
    required this.testResults,
    this.emptyMessage = 'No test results available',
    this.headerStyle,
    this.onRowTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (testResults.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueGrey[600],
          ),
        ),
      );
    }
    
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Test',
                  style: headerStyle ?? TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Group',
                  style: headerStyle ?? TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Time',
                  textAlign: TextAlign.center,
                  style: headerStyle ?? TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Benchmark',
                  textAlign: TextAlign.center,
                  style: headerStyle ?? TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Table rows
        for (var index = 0; index < testResults.length; index++)
          _buildTestResultRow(
            testResults[index], 
            index, 
            onTap: onRowTap != null 
                ? () => onRowTap!(testResults[index]) 
                : null
          ),
      ],
    );
  }
  
  Widget _buildTestResultRow(Map<String, dynamic> data, int index, {VoidCallback? onTap}) {
    final group = data['group'] as Map<String, dynamic>;
    final test = data['test'] as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>;
    
    // Extract required data
    final groupName = group['name'] as String? ?? 'Unknown Group';
    final testTitle = test['title'] as String? ?? 'Unknown Test';
    final testCategory = test['category'] as String? ?? 'Uncategorized';
    final benchmarks = test['benchmarks'] as Map<String, dynamic>? ?? {};
    final time = result['time'] as double? ?? 0.0;
    
    // Find benchmark for this time
    String benchmark = 'Not Rated';
    Color benchmarkColor = Colors.grey;
    
    final excellentTime = benchmarks['Excellent'] as double? ?? 0.0;
    final goodTime = benchmarks['Good'] as double? ?? 0.0;
    final averageTime = benchmarks['Average'] as double? ?? 0.0;
    
    if (excellentTime > 0 && time <= excellentTime) {
      benchmark = 'Excellent';
      benchmarkColor = Colors.green;
    } else if (goodTime > 0 && time <= goodTime) {
      benchmark = 'Good';
      benchmarkColor = Colors.lightGreen;
    } else if (averageTime > 0 && time <= averageTime) {
      benchmark = 'Average';
      benchmarkColor = Colors.orange;
    } else {
      benchmark = 'Below Average';
      benchmarkColor = Colors.red;
    }
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: index % 2 == 0 ? Colors.white : Colors.grey[50],
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    testTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    testCategory,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                groupName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.blueGrey[700],
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                '${time.toStringAsFixed(2)}s',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                decoration: BoxDecoration(
                  color: benchmarkColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  benchmark,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: benchmarkColor,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}