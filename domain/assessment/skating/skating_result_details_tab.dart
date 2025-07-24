// lib/widgets/domain/assessment/skating/skating_result_details_tab.dart
// PHASE 4 UPDATE: Assessment Screen Responsive Design Implementation

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingResultDetailsTab extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> results;
  final Map<String, Map<String, dynamic>> testResults;
  
  const SkatingResultDetailsTab({
    Key? key,
    required this.assessment,
    required this.results,
    required this.testResults,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    print('=== DETAILS TAB DEBUG ===');
    print('Results received: $results');
    print('Test results: $testResults');
    print('Test results keys: ${testResults.keys.toList()}');
    print('Assessment: $assessment');
    print('Assessment groups: ${(assessment['groups'] as List?)?.length ?? 0}');
    
    final groups = assessment['groups'] as List?;
    if (groups != null) {
      print('Expected tests from assessment:');
      for (var group in groups) {
        final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
        for (var test in tests) {
          final testId = (test as Map<String, dynamic>)['id'] as String;
          print('  - Expected: $testId');
          if (testResults.containsKey(testId)) {
            print('    ✅ Found in testResults: ${testResults[testId]}');
          } else {
            print('    ❌ MISSING from testResults');
          }
        }
      }
    }
    print('========================');

    final analysisData = _getAnalysisData();

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(context, analysisData);
          case DeviceType.tablet:
            return _buildTabletLayout(context, analysisData);
          case DeviceType.desktop:
            return _buildDesktopLayout(context, analysisData);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> analysisData) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
              _buildEnhancedDebugCard(context, analysisData),
            
            if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
              ResponsiveSpacing(multiplier: 2),
            
            _buildTestResultsCard(context, analysisData),
            ResponsiveSpacing(multiplier: 2),
            _buildPositionAnalysisCard(context, analysisData),
            ResponsiveSpacing(multiplier: 2),
            _buildGroupPerformanceCard(context, analysisData),
          ],
        ),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, Map<String, dynamic> analysisData) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
              _buildEnhancedDebugCard(context, analysisData),
            
            if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
              ResponsiveSpacing(multiplier: 2),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTestResultsCard(context, analysisData),
                      ResponsiveSpacing(multiplier: 2),
                      _buildGroupPerformanceCard(context, analysisData),
                    ],
                  ),
                ),
                
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                
                Expanded(
                  flex: 2,
                  child: _buildPositionAnalysisCard(context, analysisData),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> analysisData) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: 1400,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
                    _buildEnhancedDebugCard(context, analysisData),
                  
                  if (testResults.isEmpty || _getExpectedTestCount() != testResults.length)
                    ResponsiveSpacing(multiplier: 3),
                  
                  _buildTestResultsCard(context, analysisData, enhanced: true),
                  ResponsiveSpacing(multiplier: 3),
                  _buildGroupPerformanceCard(context, analysisData, enhanced: true),
                ],
              ),
            ),
          ),
        ),
        
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildDesktopSidebar(context, analysisData),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, Map<String, dynamic> analysisData) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPositionAnalysisCard(context, analysisData, compact: true),
          ResponsiveSpacing(multiplier: 2),
          _buildQuickStatsCard(context, analysisData),
          ResponsiveSpacing(multiplier: 2),
          _buildBenchmarkLegendCard(context),
          ResponsiveSpacing(multiplier: 2),
          _buildTestTipsCard(context),
        ],
      ),
    );
  }

  Widget _buildQuickStatsCard(BuildContext context, Map<String, dynamic> analysisData) {
    final scores = (analysisData['scores'] as Map<String, dynamic>?) ?? {};
    final overallScore = scores['Overall'] as double? ?? 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Stats',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildStatRow(context, 'Tests Completed', '${testResults.length}/${_getExpectedTestCount()}'),
          _buildStatRow(context, 'Overall Score', '${overallScore.toStringAsFixed(1)}/10'),
          _buildStatRow(context, 'Performance Level', _determinePerformanceLevel(overallScore)),
          _buildStatRow(context, 'Categories Tested', '${scores.keys.where((k) => k != 'Overall').length}'),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveText(
            value,
            baseFontSize: 12,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkLegendCard(BuildContext context) {
    final benchmarks = [
      {'level': 'Elite', 'color': Colors.purple, 'description': 'Top 10% performance'},
      {'level': 'Advanced', 'color': Colors.green, 'description': 'Above average'},
      {'level': 'Developing', 'color': Colors.orange, 'description': 'Average performance'},
      {'level': 'Beginner', 'color': Colors.red, 'description': 'Below average'},
    ];
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Benchmark Legend',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...benchmarks.map((benchmark) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: benchmark['color'] as Color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        benchmark['level'] as String,
                        baseFontSize: 12,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResponsiveText(
                        benchmark['description'] as String,
                        baseFontSize: 10,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildTestTipsCard(BuildContext context) {
    final tips = [
      'Lower times indicate better performance',
      'Focus on consistency across attempts',
      'Consider position-specific requirements',
      'Track improvement over time',
    ];
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: Colors.amber[700],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Test Tips',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...tips.map((tip) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: Colors.amber[700],
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    tip,
                    baseFontSize: 11,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  int _getExpectedTestCount() {
    final groups = assessment['groups'] as List?;
    if (groups == null) return 6;
    
    int count = 0;
    for (var group in groups) {
      final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
      count += tests.length;
    }
    return count;
  }

  Map<String, dynamic> _getAnalysisData() {
    print('🔍 Extracting analysis data...');
    
    if (results.containsKey('analysis') && results['analysis'] is Map<String, dynamic>) {
      print('✅ Found nested structure (API response)');
      return results['analysis'] as Map<String, dynamic>;
    } else {
      print('✅ Found flat structure (local fallback)');
      return results;
    }
  }

  Widget _buildEnhancedDebugCard(BuildContext context, Map<String, dynamic> analysisData) {
    final groups = assessment['groups'] as List?;
    final expectedTests = <String>[];
    
    if (groups != null) {
      for (var group in groups) {
        final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
        for (var test in tests) {
          expectedTests.add((test as Map<String, dynamic>)['id'] as String);
        }
      }
    }
    
    final missingTests = expectedTests.where((testId) => !testResults.containsKey(testId)).toList();
    final extraTests = testResults.keys.where((testId) => !expectedTests.contains(testId)).toList();
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bug_report,
                  color: Colors.orange[800],
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'DETAILS TAB DEBUG (Remove in Production)',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 1.5),
            
            ResponsiveText(
              'Raw results keys: ${results.keys.toList()}',
              baseFontSize: 12,
            ),
            ResponsiveText(
              'Analysis data keys: ${analysisData.keys.toList()}',
              baseFontSize: 12,
            ),
            ResponsiveText(
              'Test results count: ${testResults.length}',
              baseFontSize: 12,
            ),
            ResponsiveText(
              'Expected tests: ${expectedTests.length}',
              baseFontSize: 12,
            ),
            
            if (analysisData.containsKey('scores'))
              ResponsiveText(
                '✅ Scores found: ${analysisData['scores']}',
                baseFontSize: 12,
              )
            else
              ResponsiveText(
                '❌ No scores in analysis data',
                baseFontSize: 12,
              ),
            
            if (missingTests.isNotEmpty) ...[
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                '❌ Missing tests: ${missingTests.join(", ")}',
                baseFontSize: 12,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            if (extraTests.isNotEmpty) ...[
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                '⚠️ Extra tests: ${extraTests.join(", ")}',
                baseFontSize: 12,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Found test results:',
              baseFontSize: 12,
            ),
            ...testResults.entries.map((entry) => ResponsiveText(
              '  ✅ ${entry.key}: ${entry.value['time']}s (${_calculateBenchmarkFromTime(entry.key, (entry.value['time'] as num).toDouble())})',
              baseFontSize: 11,
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResultsCard(BuildContext context, Map<String, dynamic> analysisData, {bool enhanced = false}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Test Results',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: testResults.length < 6 ? Colors.orange[100] : Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ResponsiveText(
                  '${testResults.length}/${_getExpectedTestCount()} tests',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: testResults.length < 6 ? Colors.orange[800] : Colors.green[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (testResults.isEmpty) 
            _buildNoTestResultsMessage(context)
          else 
            _buildTestResultsTable(context, analysisData, enhanced: enhanced),
        ],
      ),
    );
  }

  Widget _buildNoTestResultsMessage(BuildContext context) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning,
            color: Colors.red[700],
            size: ResponsiveConfig.iconSize(context, 24),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'No Test Results Found',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            'Test results were not properly saved or transferred. This may be due to a data synchronization issue.',
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.red[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsTable(BuildContext context, Map<String, dynamic> analysisData, {bool enhanced = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              switch (deviceType) {
                case DeviceType.mobile:
                  return _buildMobileTableHeader(context);
                case DeviceType.tablet:
                  return _buildTabletTableHeader(context);
                case DeviceType.desktop:
                  return _buildDesktopTableHeader(context, enhanced);
              }
            },
          ),
        ),
        
        ...testResults.entries.map((entry) => 
          _buildTestResultRow(context, entry.key, entry.value, analysisData, enhanced: enhanced)
        ).toList(),
      ],
    );
  }

  Widget _buildMobileTableHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ResponsiveText(
            'Test',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            'Time',
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Rating',
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletTableHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ResponsiveText(
            'Test Name',
            baseFontSize: 15,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Category',
            baseFontSize: 15,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            'Time',
            baseFontSize: 15,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Performance',
            baseFontSize: 15,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopTableHeader(BuildContext context, bool enhanced) {
    if (!enhanced) return _buildTabletTableHeader(context);
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ResponsiveText(
            'Test Name',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Category',
            baseFontSize: 16,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            'Time (s)',
            baseFontSize: 16,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Performance Level',
            baseFontSize: 16,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            'Benchmark Range',
            baseFontSize: 16,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildTestResultRow(BuildContext context, String testId, Map<String, dynamic> result, Map<String, dynamic> analysisData, {bool enhanced = false}) {
    final test = _findTestById(testId);
    if (test == null) {
      print('Test not found for ID: $testId');
      return const SizedBox();
    }
    
    String benchmark = 'Not Rated';
    final testBenchmarks = analysisData['testBenchmarks'] as Map<String, dynamic>?;
    if (testBenchmarks != null && testBenchmarks.containsKey(testId)) {
      benchmark = testBenchmarks[testId] as String;
    } else {
      final time = (result['time'] as num).toDouble();
      benchmark = _calculateBenchmarkFromTime(testId, time);
    }
    
    print('Test $testId: time=${result['time']}, benchmark=$benchmark');
    
    Color benchmarkColor = _getBenchmarkColor(benchmark);
    
    return Container(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          switch (deviceType) {
            case DeviceType.mobile:
              return _buildMobileResultRow(context, test, result, benchmark, benchmarkColor);
            case DeviceType.tablet:
              return _buildTabletResultRow(context, test, result, benchmark, benchmarkColor);
            case DeviceType.desktop:
              return _buildDesktopResultRow(context, test, result, benchmark, benchmarkColor, enhanced);
          }
        },
      ),
    );
  }

  Widget _buildMobileResultRow(BuildContext context, Map<String, dynamic> test, Map<String, dynamic> result, String benchmark, Color benchmarkColor) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                test['title'] as String,
                baseFontSize: 14,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveText(
                test['category'] as String,
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            '${(result['time'] as num).toStringAsFixed(2)}s',
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(
              context,
              vertical: 4,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: benchmarkColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ResponsiveText(
              benchmark,
              baseFontSize: 12,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: benchmarkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletResultRow(BuildContext context, Map<String, dynamic> test, Map<String, dynamic> result, String benchmark, Color benchmarkColor) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ResponsiveText(
            test['title'] as String,
            baseFontSize: 15,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: ResponsiveText(
            test['category'] as String,
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            '${(result['time'] as num).toStringAsFixed(2)}s',
            baseFontSize: 15,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(
              context,
              vertical: 4,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: benchmarkColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ResponsiveText(
              benchmark,
              baseFontSize: 13,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: benchmarkColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopResultRow(BuildContext context, Map<String, dynamic> test, Map<String, dynamic> result, String benchmark, Color benchmarkColor, bool enhanced) {
    if (!enhanced) return _buildTabletResultRow(context, test, result, benchmark, benchmarkColor);

    final benchmarks = _getConsistentBenchmarks();
    final testBenchmark = benchmarks[test['id'] as String];
    
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                test['title'] as String,
                baseFontSize: 16,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveText(
                test['description'] as String? ?? 'Skating assessment test',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[500]),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(
              context,
              vertical: 4,
              horizontal: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: ResponsiveText(
              test['category'] as String,
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ResponsiveText(
            '${(result['time'] as num).toStringAsFixed(2)}',
            baseFontSize: 16,
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            padding: ResponsiveConfig.paddingSymmetric(
              context,
              vertical: 6,
              horizontal: 12,
            ),
            decoration: BoxDecoration(
              color: benchmarkColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: benchmarkColor.withOpacity(0.5)),
            ),
            child: ResponsiveText(
              benchmark,
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: benchmarkColor,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: testBenchmark != null ? ResponsiveText(
            '${testBenchmark['Elite']!}s - ${testBenchmark['Beginner']!}s',
            baseFontSize: 12,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey[600]),
          ) : ResponsiveText(
            'No benchmarks',
            baseFontSize: 12,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey[400]),
          ),
        ),
      ],
    );
  }

  Color _getBenchmarkColor(String benchmark) {
    switch (benchmark.toLowerCase()) {
      case 'elite':
        return Colors.purple;
      case 'advanced':
        return Colors.green;
      case 'developing':
        return Colors.orange;
      case 'beginner':
        return Colors.red;
      case 'not rated':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _calculateBenchmarkFromTime(String testId, double time) {
    final benchmarks = _getConsistentBenchmarks();
    final testBenchmark = benchmarks[testId];
    
    if (testBenchmark == null) return 'Not Rated';
    
    if (time <= testBenchmark['Elite']!) {
      return 'Elite';
    } else if (time <= testBenchmark['Advanced']!) {
      return 'Advanced';
    } else if (time <= testBenchmark['Developing']!) {
      return 'Developing';
    } else {
      return 'Beginner';
    }
  }

  Map<String, Map<String, double>> _getConsistentBenchmarks() {
    return {
      'forward_speed_test': {
        'Elite': 4.2,
        'Advanced': 4.5,
        'Developing': 4.8,
        'Beginner': 5.2,
      },
      'backward_speed_test': {
        'Elite': 5.2,
        'Advanced': 5.6,
        'Developing': 6.0,
        'Beginner': 6.5,
      },
      'agility_test': {
        'Elite': 9.0,
        'Advanced': 9.8,
        'Developing': 10.6,
        'Beginner': 11.8,
      },
      'transitions_test': {
        'Elite': 4.2,
        'Advanced': 4.6,
        'Developing': 5.0,
        'Beginner': 5.5,
      },
      'crossovers_test': {
        'Elite': 7.8,
        'Advanced': 8.5,
        'Developing': 9.3,
        'Beginner': 10.2,
      },
      'stop_start_test': {
        'Elite': 2.3,
        'Advanced': 2.5,
        'Developing': 2.8,
        'Beginner': 3.2,
      },
      'acceleration_test': {
        'Elite': 1.8,
        'Advanced': 2.0,
        'Developing': 2.2,
        'Beginner': 2.5,
      },
    };
  }
  
  Map<String, dynamic>? _findTestById(String testId) {
    final groups = assessment['groups'] as List?;
    if (groups == null) return null;
    
    for (var group in groups) {
      final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
      for (var test in tests) {
        if ((test as Map<String, dynamic>)['id'] == testId) {
          return test;
        }
      }
    }
    
    return {
      'id': testId,
      'title': _getTestDisplayName(testId),
      'category': _getTestCategory(testId),
      'description': _getTestDescription(testId),
    };
  }

  String _getTestDisplayName(String testId) {
    const testNames = {
      'forward_speed_test': 'Forward Speed Test',
      'backward_speed_test': 'Backward Speed Test',
      'agility_test': 'Agility Test',
      'transitions_test': 'Transitions Test',
      'crossovers_test': 'Crossovers Test',
      'stop_start_test': 'Stop & Start Test',
      'acceleration_test': 'Acceleration Test',
    };
    return testNames[testId] ?? testId.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  String _getTestCategory(String testId) {
    switch (testId) {
      case 'forward_speed_test':
      case 'stop_start_test':
      case 'acceleration_test':
        return 'Forward Speed';
      case 'backward_speed_test':
        return 'Backward Speed';
      case 'agility_test':
      case 'crossovers_test':
        return 'Agility';
      case 'transitions_test':
        return 'Transitions';
      default:
        return 'General';
    }
  }

  String _getTestDescription(String testId) {
    const descriptions = {
      'forward_speed_test': 'Measures forward skating speed over a set distance',
      'backward_speed_test': 'Measures backward skating speed and control',
      'agility_test': 'Tests quick direction changes and maneuverability',
      'transitions_test': 'Evaluates transitions between forward and backward skating',
      'crossovers_test': 'Assesses crossover technique and edge control',
      'stop_start_test': 'Measures acceleration and stopping ability',
      'acceleration_test': 'Measures explosive starting acceleration',
    };
    return descriptions[testId] ?? 'Skating assessment test';
  }
  
  Widget _buildPositionAnalysisCard(BuildContext context, Map<String, dynamic> analysisData, {bool compact = false}) {
    final isForward = (assessment['position'] as String? ?? 'forward') == 'forward';
    final categoryScores = analysisData['scores'] as Map<String, dynamic>? ?? {};
    final forwardScore = categoryScores['Forward Speed'] as double? ?? 
                        categoryScores['Speed'] as double? ?? 0.0;
    final backwardScore = categoryScores['Backward Speed'] as double? ?? 0.0;
    final agilityScore = categoryScores['Agility'] as double? ?? 0.0;
    final transitionsScore = categoryScores['Transitions'] as double? ?? 0.0;
    
    String positionStrength = '';
    String positionWeakness = '';
    
    if (isForward) {
      if (forwardScore > backwardScore) {
        positionStrength = 'Your forward speed is a key strength for your position, enabling effective rushes and offensive zone entries.';
      } else {
        positionStrength = 'Your backward skating mobility is strong, which is beneficial for defensive positioning and backchecking.';
      }
      
      if (forwardScore < 6.0) {
        positionWeakness = 'Building forward speed and acceleration would improve your offensive capabilities and create more scoring opportunities.';
      } else if (agilityScore < 6.0) {
        positionWeakness = 'Improving agility would enhance your ability to maneuver in tight spaces and evade defensive pressure.';
      } else {
        positionWeakness = 'Continue developing your skating versatility to maintain your competitive edge.';
      }
    } else {
      if (backwardScore > forwardScore) {
        positionStrength = 'Your backward skating is a key defenseman strength, enabling effective gap control and defensive positioning.';
      } else {
        positionStrength = 'Your forward mobility is strong, which supports offensive rushes and zone transitions.';
      }
      
      if (backwardScore < 6.0) {
        positionWeakness = 'Developing backward speed and mobility would improve your defensive coverage and gap control abilities.';
      } else if (transitionsScore < 6.0) {
        positionWeakness = 'Improving transitions would enhance your ability to quickly change directions and adapt to evolving plays.';
      } else {
        positionWeakness = 'Focus on advanced defensive skating techniques to excel at your position.';
      }
    }
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 8),
                decoration: BoxDecoration(
                  color: Colors.cyan[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isForward ? Icons.speed : Icons.shield,
                  color: Colors.cyan[700],
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  isForward ? 'Forward Analysis' : 'Defenseman Analysis',
                  baseFontSize: compact ? 16 : 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            'Position Strength:',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            positionStrength,
            baseFontSize: 13,
          ),
          
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveText(
            'Position Development:',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            positionWeakness,
            baseFontSize: 13,
          ),
          
          if (!compact) ...[
            ResponsiveSpacing(multiplier: 1.5),
            
            ResponsiveText(
              'Position Priorities:',
              baseFontSize: 14,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              isForward
                  ? 'Forwards typically prioritize: Forward Speed, Agility, then Transitions'
                  : 'Defensemen typically prioritize: Backward Speed, Transitions, then Agility',
              baseFontSize: 13,
            ),
          ],
          
          if (categoryScores.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1.5),
            ResponsiveText(
              'Your Scores:',
              baseFontSize: 14,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            if (forwardScore > 0) ResponsiveText(
              'Forward Speed: ${forwardScore.toStringAsFixed(1)}/10',
              baseFontSize: 12,
            ),
            if (backwardScore > 0) ResponsiveText(
              'Backward Speed: ${backwardScore.toStringAsFixed(1)}/10',
              baseFontSize: 12,
            ),
            if (agilityScore > 0) ResponsiveText(
              'Agility: ${agilityScore.toStringAsFixed(1)}/10',
              baseFontSize: 12,
            ),
            if (transitionsScore > 0) ResponsiveText(
              'Transitions: ${transitionsScore.toStringAsFixed(1)}/10',
              baseFontSize: 12,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildGroupPerformanceCard(BuildContext context, Map<String, dynamic> analysisData, {bool enhanced = false}) {
    final groups = assessment['groups'] as List?;
    if (groups == null || groups.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Group Performance',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // FIX: Add required crossAxisCount parameter to ResponsiveGrid
          if (enhanced)
            ResponsiveGrid(
              crossAxisCount: 2, // FIX: Added missing required parameter
              children: groups.map((group) => 
                _buildGroupPerformanceItem(context, group as Map<String, dynamic>, analysisData, enhanced: true)
              ).toList(),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: groups.map((group) => 
                _buildGroupPerformanceItem(context, group as Map<String, dynamic>, analysisData)
              ).toList(),
            ),
        ],
      ),
    );
  }
  
  Widget _buildGroupPerformanceItem(BuildContext context, Map<String, dynamic> group, Map<String, dynamic> analysisData, {bool enhanced = false}) {
    int completedTests = 0;
    final groupTests = group['tests'] as List? ?? [];
    
    for (var test in groupTests) {
      final testId = (test as Map<String, dynamic>)['id'] as String;
      if (testResults.containsKey(testId)) {
        completedTests++;
      }
    }
    
    double groupScore = 0;
    if (completedTests > 0) {
      double totalScore = 0;
      int scoreCount = 0;
      
      for (var test in groupTests) {
        final testId = (test as Map<String, dynamic>)['id'] as String;
        if (testResults.containsKey(testId)) {
          final time = (testResults[testId]!['time'] as num).toDouble();
          final benchmark = _calculateBenchmarkFromTime(testId, time);
          double testScore = 0;
          
          switch (benchmark) {
            case 'Elite':
              testScore = 9.5;
              break;
            case 'Advanced':
              testScore = 7.5;
              break;
            case 'Developing':
              testScore = 5.5;
              break;
            case 'Beginner':
              testScore = 3.5;
              break;
            default:
              testScore = 1.0;
          }
          
          totalScore += testScore;
          scoreCount++;
        }
      }
      groupScore = scoreCount > 0 ? totalScore / scoreCount : 0.0;
    }
    
    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ResponsiveText(
                group['name'] as String? ?? group['title'] as String? ?? 'Unknown Group',
                baseFontSize: enhanced ? 16 : 15,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: SkatingUtils.getScoreColor(groupScore).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ResponsiveText(
                '${groupScore.toStringAsFixed(1)}/10',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SkatingUtils.getScoreColor(groupScore),
                ),
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          '$completedTests of ${groupTests.length} tests completed',
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
        ResponsiveSpacing(multiplier: 1),
        LinearProgressIndicator(
          value: groupScore / 10,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            SkatingUtils.getScoreColor(groupScore),
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        if (enhanced) ...[
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            group['description'] as String? ?? 'Test group description',
            baseFontSize: 11,
            style: TextStyle(color: Colors.blueGrey[500]),
          ),
        ],
      ],
    );
    
    if (enhanced) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: content,
      );
    } else {
      return Padding(
        padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            content,
            ResponsiveSpacing(multiplier: 2),
            const Divider(),
          ],
        ),
      );
    }
  }

  String _determinePerformanceLevel(double score) {
    if (score >= 9.0) return 'Elite';
    if (score >= 7.5) return 'Advanced';
    if (score >= 6.0) return 'Proficient';
    if (score >= 4.5) return 'Developing';
    if (score >= 3.0) return 'Basic';
    return 'Beginner';
  }
}