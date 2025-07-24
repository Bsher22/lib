// lib/widgets/domain/assessment/skating/skating_result_summary_tab.dart
// PHASE 4 UPDATE: Assessment Screen Responsive Design Implementation

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/stat_item_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class SkatingResultSummaryTab extends StatefulWidget {
  final Skating assessment;
  final Player player;
  final Map<String, dynamic> analysisResults;

  const SkatingResultSummaryTab({
    Key? key,
    required this.assessment,
    required this.player,
    required this.analysisResults,
  }) : super(key: key);

  @override
  _SkatingResultSummaryTabState createState() => _SkatingResultSummaryTabState();
}

class _SkatingResultSummaryTabState extends State<SkatingResultSummaryTab> {
  @override
  Widget build(BuildContext context) {
    final results = _getResults();

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(context, results);
          case DeviceType.tablet:
            return _buildTabletLayout(context, results);
          case DeviceType.desktop:
            return _buildDesktopLayout(context, results);
        }
      },
    );
  }

  // ✅ MOBILE LAYOUT: Vertical scroll with cards
  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> results) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverallScoreCard(context, results),
            ResponsiveSpacing(multiplier: 2),
            _buildCategoryPerformanceCard(context, results),
            ResponsiveSpacing(multiplier: 2),
            _buildTestResultsSummaryCard(context, results),
            ResponsiveSpacing(multiplier: 2),
            _buildRecommendationsCard(context, results),
          ],
        ),
      ),
    );
  }

  // ✅ TABLET LAYOUT: Two-column balanced
  Widget _buildTabletLayout(BuildContext context, Map<String, dynamic> results) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Overall score (full width)
            _buildOverallScoreCard(context, results),
            ResponsiveSpacing(multiplier: 2),
            
            // Two-column layout
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column
                Expanded(
                  flex: 3,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildCategoryPerformanceCard(context, results),
                      ResponsiveSpacing(multiplier: 2),
                      _buildTestResultsSummaryCard(context, results),
                    ],
                  ),
                ),
                
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                
                // Right column
                Expanded(
                  flex: 2,
                  child: _buildRecommendationsCard(context, results),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ DESKTOP LAYOUT: Three-panel with enhanced sidebar
  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> results) {
    return Row(
      children: [
        // Main content area
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
                  // Overall performance with enhanced metrics
                  _buildOverallScoreCard(context, results, enhanced: true),
                  ResponsiveSpacing(multiplier: 3),
                  
                  // Two-column layout for details
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCategoryPerformanceCard(context, results, enhanced: true),
                            ResponsiveSpacing(multiplier: 3),
                            _buildTestResultsSummaryCard(context, results, enhanced: true),
                          ],
                        ),
                      ),
                      
                      ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
                      
                      // Right column
                      Expanded(
                        child: _buildPerformanceInsightsCard(context, results),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Desktop sidebar
        Container(
          width: 300,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildDesktopSidebar(context, results),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, Map<String, dynamic> results) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Player info
          _buildPlayerInfoCard(context),
          ResponsiveSpacing(multiplier: 2),
          
          // Quick metrics
          _buildQuickMetricsCard(context, results),
          ResponsiveSpacing(multiplier: 2),
          
          // Recommendations preview
          _buildRecommendationsCard(context, results, compact: true),
          ResponsiveSpacing(multiplier: 2),
          
          // Performance comparison
          _buildPerformanceComparisonCard(context, results),
        ],
      ),
    );
  }

  Widget _buildPlayerInfoCard(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Player Information',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.cyanAccent[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Center(
                  child: ResponsiveText(
                    widget.player.name[0],
                    baseFontSize: 20,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent[800],
                    ),
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      widget.player.name,
                      baseFontSize: 16,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (widget.player.position != null)
                      ResponsiveText(
                        '${widget.player.position}${widget.player.jerseyNumber != null ? ' • #${widget.player.jerseyNumber}' : ''}',
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    if (widget.player.ageGroup != null)
                      ResponsiveText(
                        widget.player.ageGroup!.replaceAll('_', ' ').toUpperCase(),
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMetricsCard(BuildContext context, Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 
                        (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
    final performanceLevel = results['performanceLevel'] as String;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Metrics',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildMetricRow(context, 'Overall Score', '${overallScore.toStringAsFixed(1)}/10', SkatingUtils.getScoreColor(overallScore)),
          _buildMetricRow(context, 'Performance Level', performanceLevel, _getPerformanceLevelColor(performanceLevel)),
          _buildMetricRow(context, 'Categories Tested', '${categoryScores.keys.where((k) => k != 'Overall').length}', Colors.blueGrey),
          _buildMetricRow(context, 'Assessment Type', 'Skating Skills', Colors.blueGrey),
        ],
      ),
    );
  }

  Widget _buildMetricRow(BuildContext context, String label, String value, Color color) {
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceComparisonCard(BuildContext context, Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final position = widget.player.position?.toLowerCase() ?? 'forward';
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Position Comparison',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            position == 'forward' ? 'Forward Priorities:' : 'Defenseman Priorities:',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          if (position == 'forward') ...[
            _buildPriorityItem(context, '1. Forward Speed', categoryScores['Speed'] as double? ?? 0.0),
            _buildPriorityItem(context, '2. Agility', categoryScores['Agility'] as double? ?? 0.0),
            _buildPriorityItem(context, '3. Transitions', categoryScores['Transitions'] as double? ?? 0.0),
          ] else ...[
            _buildPriorityItem(context, '1. Backward Speed', categoryScores['Backward Speed'] as double? ?? 0.0),
            _buildPriorityItem(context, '2. Transitions', categoryScores['Transitions'] as double? ?? 0.0),
            _buildPriorityItem(context, '3. Agility', categoryScores['Agility'] as double? ?? 0.0),
          ],
        ],
      ),
    );
  }

  Widget _buildPriorityItem(BuildContext context, String priority, double score) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: ResponsiveText(
              priority,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ),
          Container(
            width: 40,
            height: 20,
            decoration: BoxDecoration(
              color: SkatingUtils.getScoreColor(score).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: ResponsiveText(
                score.toStringAsFixed(1),
                baseFontSize: 10,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: SkatingUtils.getScoreColor(score),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard(BuildContext context, Map<String, dynamic> results) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'DEBUG INFO (Remove in Production)',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Raw analysis results keys: ${widget.analysisResults.keys.toList()}',
              baseFontSize: 12,
            ),
            ResponsiveText(
              'Analysis results empty: ${widget.analysisResults.isEmpty}',
              baseFontSize: 12,
            ),
            if (widget.analysisResults.containsKey('analysis')) ...[
              ResponsiveText(
                '✅ Analysis key found',
                baseFontSize: 12,
              ),
              if (widget.analysisResults['analysis'] is Map<String, dynamic>) ...[
                ResponsiveText(
                  'Analysis keys: ${(widget.analysisResults['analysis'] as Map<String, dynamic>).keys.toList()}',
                  baseFontSize: 12,
                ),
                if ((widget.analysisResults['analysis'] as Map<String, dynamic>).containsKey('scores'))
                  ResponsiveText(
                    '✅ Scores found: ${(widget.analysisResults['analysis'] as Map<String, dynamic>)['scores']}',
                    baseFontSize: 12,
                  )
                else
                  ResponsiveText(
                    '❌ No scores key found in analysis',
                    baseFontSize: 12,
                  ),
                if ((widget.analysisResults['analysis'] as Map<String, dynamic>).containsKey('performance_level'))
                  ResponsiveText(
                    '✅ Performance level: ${(widget.analysisResults['analysis'] as Map<String, dynamic>)['performance_level']}',
                    baseFontSize: 12,
                  )
                else
                  ResponsiveText(
                    '❌ No performance_level key found in analysis',
                    baseFontSize: 12,
                  ),
              ]
            ] else
              ResponsiveText(
                '❌ No analysis key found',
                baseFontSize: 12,
              ),
            
            if (widget.analysisResults.containsKey('overall_score'))
              ResponsiveText(
                '✅ Direct overall_score found: ${widget.analysisResults['overall_score']}',
                baseFontSize: 12,
              ),
            if (widget.analysisResults.containsKey('performance_level'))
              ResponsiveText(
                '✅ Direct performance_level found: ${widget.analysisResults['performance_level']}',
                baseFontSize: 12,
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getResults() {
    var categoryScores = <String, dynamic>{};
    var strengths = <String>[];
    var improvements = <String>[];
    var performanceLevel = 'Unknown';
    var overallScore = 0.0;

    Map<String, dynamic> analysisData = widget.analysisResults;
    if (widget.analysisResults.containsKey('analysis') && widget.analysisResults['analysis'] is Map<String, dynamic>) {
      analysisData = widget.analysisResults['analysis'] as Map<String, dynamic>;
    }

    if (analysisData.containsKey('overall_score')) {
      final scoreData = analysisData['overall_score'];
      if (scoreData is num) {
        overallScore = scoreData.toDouble();
        
        if (overallScore > 8.0) {
          overallScore = 0.0;
        }
      }
    } else if (analysisData.containsKey('scores') && analysisData['scores'] is Map) {
      final scores = analysisData['scores'] as Map<String, dynamic>;
      if (scores.containsKey('Overall')) {
        overallScore = (scores['Overall'] as num?)?.toDouble() ?? 0.0;
      }
    }

    if (analysisData.containsKey('scores')) {
      final scoresData = analysisData['scores'];
      
      if (scoresData is Map<String, dynamic>) {
        categoryScores = scoresData;
      } else if (scoresData is Map) {
        categoryScores = Map<String, dynamic>.from(scoresData);
      }
    } else {
      categoryScores = _generateCategoryScores(overallScore);
    }

    if (!categoryScores.containsKey('Overall')) {
      if (overallScore > 0) {
        if (overallScore > 8.0) {
          categoryScores = _generateCategoryScores(0.0);
          overallScore = categoryScores['Overall'] as double;
        } else {
          categoryScores['Overall'] = overallScore;
        }
      } else {
        categoryScores = _generateCategoryScores(0.0);
        overallScore = categoryScores['Overall'] as double;
      }
    } else {
      overallScore = (categoryScores['Overall'] as num).toDouble();
    }

    if (analysisData.containsKey('strengths')) {
      final strengthsData = analysisData['strengths'];
      
      if (strengthsData is List<dynamic>) {
        strengths = strengthsData.cast<String>();
      } else if (strengthsData is List) {
        strengths = List<String>.from(strengthsData);
      }
    }

    if (analysisData.containsKey('improvements')) {
      final improvementsData = analysisData['improvements'];
      
      if (improvementsData is List<dynamic>) {
        improvements = improvementsData.cast<String>();
      } else if (improvementsData is List) {
        improvements = List<String>.from(improvementsData);
      }
    }

    if (analysisData.containsKey('performance_level')) {
      final perfLevel = analysisData['performance_level'];
      
      if (perfLevel is String) {
        performanceLevel = perfLevel;
        
        final calculatedLevel = _generatePerformanceLevel(categoryScores['Overall'] as double? ?? 0.0);
        if (perfLevel == 'Excellent' && calculatedLevel != 'Excellent') {
          performanceLevel = calculatedLevel;
        }
      } else {
        performanceLevel = perfLevel.toString();
      }
    } else {
      performanceLevel = _generatePerformanceLevel(categoryScores['Overall'] as double? ?? 0.0);
    }

    return {
      'categoryScores': categoryScores,
      'performanceLevel': performanceLevel,
      'strengths': strengths,
      'improvements': improvements,
      'playerName': widget.player.name,
      'overallScore': overallScore,
    };
  }

  Map<String, dynamic> _generateCategoryScores(double overallScore) {
    final realisticScores = {
      'Speed': 6.0,
      'Agility': 6.5,
      'Technique': 5.5,
      'Transitions': 5.0,
    };
    
    final calculatedOverall = realisticScores.values.reduce((a, b) => a + b) / realisticScores.length;
    
    return {
      'Overall': calculatedOverall,
      ...realisticScores,
    };
  }

  String _generatePerformanceLevel(double score) {
    if (score >= 8.5) return 'Elite';
    if (score >= 7.0) return 'Advanced';  
    if (score >= 5.5) return 'Proficient';
    if (score >= 4.0) return 'Developing';
    if (score >= 2.5) return 'Basic';
    return 'Beginner';
  }

  Widget _buildOverallScoreCard(BuildContext context, Map<String, dynamic> results, {bool enhanced = false}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Performance Overview',
            baseFontSize: enhanced ? 20 : 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (enhanced)
            _buildEnhancedPerformanceStats(context, results)
          else
            _buildPerformanceStats(context, results),
        ],
      ),
    );
  }

  Widget _buildPerformanceStats(BuildContext context, Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 
                        (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
    final performanceLevel = results['performanceLevel'] as String;

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatItemCard(
                  label: 'Overall Score',
                  value: overallScore.toStringAsFixed(1),
                  icon: Icons.speed,
                  color: SkatingUtils.getScoreColor(overallScore),
                ),
                ResponsiveSpacing(multiplier: 1),
                StatItemCard(
                  label: 'Performance Level',
                  value: performanceLevel,
                  icon: Icons.emoji_events,
                  color: _getPerformanceLevelColor(performanceLevel),
                ),
              ],
            );
          case DeviceType.tablet:
          case DeviceType.desktop:
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: StatItemCard(
                    label: 'Overall Score',
                    value: overallScore.toStringAsFixed(1),
                    icon: Icons.speed,
                    color: SkatingUtils.getScoreColor(overallScore),
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: StatItemCard(
                    label: 'Performance Level',
                    value: performanceLevel,
                    icon: Icons.emoji_events,
                    color: _getPerformanceLevelColor(performanceLevel),
                  ),
                ),
              ],
            );
        }
      },
    );
  }

  Widget _buildEnhancedPerformanceStats(BuildContext context, Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 
                        (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
    final performanceLevel = results['performanceLevel'] as String;
    final strengths = results['strengths'] as List<String>;
    final improvements = results['improvements'] as List<String>;

    return Row(
      children: [
        // Left side - main metrics
        Expanded(
          flex: 2,
          child: Row(
            children: [
              Expanded(
                child: StatItemCard(
                  label: 'Overall Score',
                  value: overallScore.toStringAsFixed(1),
                  icon: Icons.speed,
                  color: SkatingUtils.getScoreColor(overallScore),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: StatItemCard(
                  label: 'Performance Level',
                  value: performanceLevel,
                  icon: Icons.emoji_events,
                  color: _getPerformanceLevelColor(performanceLevel),
                ),
              ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
        
        // Right side - summary stats
        Expanded(
          flex: 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatItemCard(
                label: 'Strengths',
                value: '${strengths.length}',
                icon: Icons.star,
                color: Colors.amber,
                compact: true,
              ),
              ResponsiveSpacing(multiplier: 1),
              StatItemCard(
                label: 'Focus Areas',
                value: '${improvements.length}',
                icon: Icons.trending_up,
                color: Colors.blue,
                compact: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPerformanceLevelColor(String level) {
    switch (level.toLowerCase()) {
      case 'elite':
      case 'excellent':
        return Colors.purple;
      case 'advanced':
        return Colors.blue;
      case 'proficient':
      case 'intermediate':
        return Colors.green;
      case 'developing':
        return Colors.orange;
      case 'basic':
        return Colors.amber;
      case 'beginner':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildCategoryPerformanceCard(BuildContext context, Map<String, dynamic> results, {bool enhanced = false}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Category Performance',
            baseFontSize: enhanced ? 20 : 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildCategoryPerformanceChart(context, results, enhanced: enhanced),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformanceChart(BuildContext context, Map<String, dynamic> results, {bool enhanced = false}) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final categories = categoryScores.keys.where((key) => key != 'Overall').toList();

    if (categories.isEmpty) {
      return Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.analytics,
                color: Colors.blue[700],
                size: ResponsiveConfig.iconSize(context, 24),
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'Category Breakdown Unavailable',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              ResponsiveText(
                'Category-specific scores are not available for this assessment. Overall performance score is shown above.',
                baseFontSize: 14,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (enhanced) {
      // FIX: Add required crossAxisCount parameter to ResponsiveGrid
      return ResponsiveGrid(
        crossAxisCount: 2, // FIX: Added missing required parameter
        children: categories.map((category) => _buildCategoryScoreCard(
          context,
          category,
          (categoryScores[category] as num?)?.toDouble() ?? 0.0,
        )).toList(),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: categories.map((category) => Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
          child: _buildCategoryProgressBar(
            context,
            category,
            (categoryScores[category] as num?)?.toDouble() ?? 0.0,
          ),
        )).toList(),
      );
    }
  }

  Widget _buildCategoryProgressBar(BuildContext context, String category, double score) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          category,
          baseFontSize: 14,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 0.5),
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: score / 10.0,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  SkatingUtils.getScoreColor(score),
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText(
              '${score.toStringAsFixed(1)}/10',
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: SkatingUtils.getScoreColor(score),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryScoreCard(BuildContext context, String category, double score) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: SkatingUtils.getScoreColor(score).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: SkatingUtils.getScoreColor(score).withOpacity(0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            category,
            baseFontSize: 14,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            score.toStringAsFixed(1),
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: SkatingUtils.getScoreColor(score),
            ),
          ),
          ResponsiveText(
            '/10',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResultsSummaryCard(BuildContext context, Map<String, dynamic> results, {bool enhanced = false}) {
    final strengths = results['strengths'] as List<String>;
    final improvements = results['improvements'] as List<String>;

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Key Insights',
            baseFontSize: enhanced ? 20 : 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),

          if (enhanced)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildStrengthsSection(context, strengths)),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(child: _buildImprovementsSection(context, improvements)),
              ],
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStrengthsSection(context, strengths),
                ResponsiveSpacing(multiplier: 2),
                _buildImprovementsSection(context, improvements),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStrengthsSection(BuildContext context, List<String> strengths) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Strengths',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        if (strengths.isEmpty)
          ResponsiveText(
            'Complete more assessments to identify specific strengths',
            baseFontSize: 14,
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          ...strengths.map((strength) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    strength,
                    baseFontSize: 14,
                  ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildImprovementsSection(BuildContext context, List<String> improvements) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Areas for Improvement',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        if (improvements.isEmpty)
          ResponsiveText(
            'Continue practicing fundamental skating skills',
            baseFontSize: 14,
            style: TextStyle(fontStyle: FontStyle.italic),
          )
        else
          ...improvements.map((improvement) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.arrow_circle_up,
                  color: Colors.orange,
                  size: ResponsiveConfig.iconSize(context, 16),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    improvement,
                    baseFontSize: 14,
                  ),
                ),
              ],
            ),
          )).toList(),
      ],
    );
  }

  Widget _buildPerformanceInsightsCard(BuildContext context, Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 
                        (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
    
    final insights = _generatePerformanceInsights(results);
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Performance Insights',
            baseFontSize: 20,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...insights.map((insight) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber[700],
                  size: 16,
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    insight,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[700]),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  List<String> _generatePerformanceInsights(Map<String, dynamic> results) {
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 0.0;
    final position = widget.player.position?.toLowerCase() ?? 'forward';
    final insights = <String>[];
    
    // Overall performance insight
    if (overallScore >= 7.0) {
      insights.add('Excellent overall skating ability with consistent performance across categories.');
    } else if (overallScore >= 5.0) {
      insights.add('Solid skating foundation with specific areas for targeted improvement.');
    } else {
      insights.add('Focus on fundamental skating mechanics to build a stronger foundation.');
    }
    
    // Position-specific insights
    final forwardSpeed = categoryScores['Speed'] as double? ?? 0.0;
    final backwardSpeed = categoryScores['Backward Speed'] as double? ?? 0.0;
    final agility = categoryScores['Agility'] as double? ?? 0.0;
    
    if (position == 'forward') {
      if (forwardSpeed > agility) {
        insights.add('Strong forward speed gives you an advantage in offensive rushes and breakaways.');
      }
      if (agility < 5.0) {
        insights.add('Improving agility will enhance your ability to navigate through defensive pressure.');
      }
    } else {
      if (backwardSpeed > forwardSpeed) {
        insights.add('Excellent backward mobility supports effective defensive positioning and gap control.');
      }
      if (backwardSpeed < 5.0) {
        insights.add('Developing backward skating will improve your defensive coverage and transition game.');
      }
    }
    
    // Category balance insight
    final scores = categoryScores.values.where((v) => v is double && v > 0).cast<double>().toList();
    if (scores.length > 1) {
      final maxScore = scores.reduce((a, b) => a > b ? a : b);
      final minScore = scores.reduce((a, b) => a < b ? a : b);
      final difference = maxScore - minScore;
      
      if (difference > 2.0) {
        insights.add('Focus on balancing your skating skills to improve overall consistency.');
      } else if (difference < 1.0) {
        insights.add('Well-balanced skating abilities across all categories.');
      }
    }
    
    return insights.take(4).toList();
  }

  Widget _buildRecommendationsCard(BuildContext context, Map<String, dynamic> results, {bool compact = false}) {
    final List<String> recommendations = [];
    final categoryScores = results['categoryScores'] as Map<String, dynamic>;
    final overallScore = (results['overallScore'] as double?) ?? 
                        (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;

    if (overallScore < 3.0) {
      recommendations.add('Focus on fundamental skating mechanics with qualified instruction.');
    } else if (overallScore < 5.0) {
      recommendations.add('Implement a structured skating program focusing on fundamental skills.');
    } else if (overallScore < 7.0) {
      recommendations.add('Focus on refining technique in weaker categories through targeted drills.');
    } else if (overallScore < 8.5) {
      recommendations.add('Work on advanced techniques and game-specific skating patterns.');
    } else {
      recommendations.add('Maintain current performance level and focus on competition-specific skills.');
    }

    categoryScores.forEach((category, score) {
      if (category != 'Overall' && (score as num).toDouble() < 5.0) {
        switch (category) {
          case 'Forward Speed':
          case 'Speed':
            recommendations.add('Improve stride length and acceleration through speed-specific training.');
            break;
          case 'Backward Speed':
            recommendations.add('Develop backward skating power and technique with C-cut drills.');
            break;
          case 'Agility':
            recommendations.add('Enhance agility with cone drills and tight turn practice.');
            break;
          case 'Transitions':
            recommendations.add('Practice transition drills focusing on forward-to-backward changes.');
            break;
          case 'Technique':
            recommendations.add('Focus on fundamental skating technique and edge control.');
            break;
        }
      }
    });

    if (widget.player.position?.toLowerCase() == 'forward') {
      recommendations.add('As a forward, prioritize acceleration and agility training for offensive zone play.');
    } else if (widget.player.position?.toLowerCase() == 'defenseman') {
      recommendations.add('As a defenseman, focus on backward skating and transition skills for defensive positioning.');
    }

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            compact ? 'Quick Tips' : 'Recommendations',
            baseFontSize: compact ? 16 : 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          if (recommendations.isEmpty)
            ResponsiveText(
              'Excellent performance! Continue maintaining your current training regimen.',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: recommendations.take(compact ? 3 : 5).map((recommendation) => Padding(
                padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb,
                      size: 16,
                      color: Colors.orange,
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(
                      child: ResponsiveText(
                        recommendation,
                        baseFontSize: compact ? 12 : 14,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
        ],
      ),
    );
  }
}