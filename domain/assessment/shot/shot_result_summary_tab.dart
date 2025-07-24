// lib/widgets/domain/assessment/shot/shot_result_summary_tab.dart
// PHASE 4 UPDATE: Assessment Screen Responsive Design Implementation

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/stat_item_card.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/results_visualization.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotResultSummaryTab extends StatelessWidget {
  final Map<String, dynamic> results;
  final int playerId;

  const ShotResultSummaryTab({
    Key? key,
    required this.results,
    required this.playerId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Responsive overall score section
                _buildOverallScoreSection(context, deviceType, isLandscape),
                ResponsiveSpacing(multiplier: 3),
                
                // Category performance chart - responsive sizing
                _buildResponsiveCategoryChart(context, deviceType),
                ResponsiveSpacing(multiplier: 3),
                
                // Zone performance grid - responsive
                _buildResponsiveZoneGrid(context, deviceType),
                ResponsiveSpacing(multiplier: 3),
                
                // Progress trend chart (if available)
                if (results['assessmentHistory'] != null && (results['assessmentHistory'] as List).isNotEmpty) ...[
                  _buildProgressTrendChart(context, deviceType),
                  ResponsiveSpacing(multiplier: 3),
                ],
                
                // Recommendations section - responsive
                _buildResponsiveRecommendations(context, deviceType, isLandscape),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverallScoreSection(BuildContext context, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileOverallScore(context);
      case DeviceType.tablet:
        return _buildTabletOverallScore(context);
      case DeviceType.desktop:
        return _buildDesktopOverallScore(context);
    }
  }

  Widget _buildMobileOverallScore(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Overall Performance',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Single column layout on mobile
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatItemCard(
                label: 'Total Shots',
                value: (results['totalShots'] as int?)?.toString() ?? 'N/A',
                icon: Icons.sports_hockey,
                color: Colors.blue,
              ),
              ResponsiveSpacing(multiplier: 1),
              StatItemCard(
                label: 'Success Rate',
                value: '${(((results['overallRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: AssessmentShotUtils.getSuccessRateColor((results['overallRate'] as num?)?.toDouble() ?? 0.0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletOverallScore(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Overall Performance',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Two column layout on tablet
          Row(
            children: [
              Expanded(
                child: StatItemCard(
                  label: 'Total Shots',
                  value: (results['totalShots'] as int?)?.toString() ?? 'N/A',
                  icon: Icons.sports_hockey,
                  color: Colors.blue,
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: StatItemCard(
                  label: 'Success Rate',
                  value: '${(((results['overallRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%',
                  icon: Icons.check_circle,
                  color: AssessmentShotUtils.getSuccessRateColor((results['overallRate'] as num?)?.toDouble() ?? 0.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOverallScore(BuildContext context) {
    final categoryScores = Map<String, double>.from(results['categoryScores'] ?? {});
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main performance card
        Expanded(
          flex: 2,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Overall Performance',
                  baseFontSize: 20,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 2),
                
                Row(
                  children: [
                    Expanded(
                      child: StatItemCard(
                        label: 'Total Shots',
                        value: (results['totalShots'] as int?)?.toString() ?? 'N/A',
                        icon: Icons.sports_hockey,
                        color: Colors.blue,
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StatItemCard(
                        label: 'Success Rate',
                        value: '${(((results['overallRate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%',
                        icon: Icons.check_circle,
                        color: AssessmentShotUtils.getSuccessRateColor((results['overallRate'] as num?)?.toDouble() ?? 0.0),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        
        // Quick category scores sidebar
        Expanded(
          flex: 1,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Category Scores',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1.5),
                
                ...categoryScores.entries.take(5).map((entry) => Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        entry.key,
                        baseFontSize: 12,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                      Container(
                        padding: ResponsiveConfig.paddingSymmetric(
                          context,
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AssessmentShotUtils.getScoreColor(entry.value).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ResponsiveText(
                          entry.value.toStringAsFixed(1),
                          baseFontSize: 12,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AssessmentShotUtils.getScoreColor(entry.value),
                          ),
                        ),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveCategoryChart(BuildContext context, DeviceType deviceType) {
    return SizedBox(
      height: deviceType.responsive<double>(
        mobile: 250,
        tablet: 300,
        desktop: 350,
      ),
      child: ResultsVisualization.buildCategoryPerformanceChart(
        categoryScores: Map<String, double>.from(results['categoryScores'] ?? {}),
        previousAssessmentId: results['previousAssessmentId'] != null ? results['previousAssessmentId'].toString() : null,
        previousScores: results['previousCategoryScores'] != null
            ? Map<String, double>.from(results['previousCategoryScores'])
            : null,
      ),
    );
  }

  Widget _buildResponsiveZoneGrid(BuildContext context, DeviceType deviceType) {
    return SizedBox(
      height: deviceType.responsive<double>(
        mobile: 300,
        tablet: 400,
        desktop: 450,
      ),
      child: ResultsVisualization.buildEnhancedZoneGrid(
        zoneData: results['zoneMetrics'] != null
            ? (results['zoneMetrics'] as Map).map((k, v) => MapEntry(k, Map<String, dynamic>.from(v)))
            : {},
        zoneLabels: _getZoneLabelsMap(),
        title: 'Shot Performance by Zone',
        subtitle: 'Success rate across different target zones',
      ),
    );
  }

  Widget _buildProgressTrendChart(BuildContext context, DeviceType deviceType) {
    return SizedBox(
      height: deviceType.responsive<double>(
        mobile: 250,
        tablet: 300,
        desktop: 350,
      ),
      child: ResultsVisualization.buildProgressTrendChart(
        playerId: playerId,
        metricKey: 'overallScore',
        title: 'Assessment Progress',
        subtitle: 'Overall score progression over time',
        color: Colors.green,
        dateRange: 90,
        interval: 'week',
      ),
    );
  }

  Widget _buildResponsiveRecommendations(BuildContext context, DeviceType deviceType, bool isLandscape) {
    final List<String> recommendations = [];

    final overallRate = (results['overallRate'] as num?)?.toDouble() ?? 0.0;
    if (overallRate < 0.5) {
      recommendations.add('Increase practice time focusing on basic shot mechanics and consistency.');
    } else if (overallRate < 0.7) {
      recommendations.add('Refine shot technique with emphasis on accuracy and power control.');
    }

    final categoryScores = Map<String, double>.from(results['categoryScores'] ?? {});
    for (var entry in categoryScores.entries) {
      if (entry.value < 5.0 && entry.key != 'Overall') {
        recommendations.add('Improve ${entry.key.toLowerCase()} through targeted drills and repetition.');
      }
    }

    final zoneRates = Map<String, double>.from(results['zoneRates'] ?? {});
    if (zoneRates.isNotEmpty) {
      final weakZones = zoneRates.entries
          .where((entry) => entry.value < 0.4)
          .map((entry) => entry.key)
          .toList();

      if (weakZones.isNotEmpty) {
        recommendations.add('Focus on shooting from weaker zones: ${weakZones.join(', ')}.');
      }
    }

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Recommendations',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (recommendations.isEmpty)
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.celebration, 
                    color: Colors.green[600], 
                    size: ResponsiveConfig.iconSize(context, 24),
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(
                    child: ResponsiveText(
                      'Great performance! Continue maintaining your current training regimen.',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Responsive recommendation layout
            _buildRecommendationLayout(context, recommendations, deviceType, isLandscape),
        ],
      ),
    );
  }

  Widget _buildRecommendationLayout(BuildContext context, List<String> recommendations, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileRecommendations(context, recommendations);
      case DeviceType.tablet:
        return _buildTabletRecommendations(context, recommendations);
      case DeviceType.desktop:
        return _buildDesktopRecommendations(context, recommendations);
    }
  }

  Widget _buildMobileRecommendations(BuildContext context, List<String> recommendations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: recommendations.map((rec) => Container(
        margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
        padding: ResponsiveConfig.paddingAll(context, 12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.lightbulb,
              size: 16,
              color: Colors.orange[600],
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveText(
                rec,
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTabletRecommendations(BuildContext context, List<String> recommendations) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 12),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 12),
        childAspectRatio: 3,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        return Container(
          padding: ResponsiveConfig.paddingAll(context, 12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb,
                size: 16,
                color: Colors.orange[600],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  recommendations[index],
                  baseFontSize: 11,
                  style: TextStyle(color: Colors.blueGrey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopRecommendations(BuildContext context, List<String> recommendations) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
        childAspectRatio: 4,
      ),
      itemCount: recommendations.length,
      itemBuilder: (context, index) {
        return Container(
          padding: ResponsiveConfig.paddingAll(context, 16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.blue[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.lightbulb,
                  size: 16,
                  color: Colors.orange[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  recommendations[index],
                  baseFontSize: 12,
                  style: TextStyle(
                    color: Colors.blueGrey[700],
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, String> _getZoneLabelsMap() {
    return {
      '1': 'Top Left',
      '2': 'Top Center',
      '3': 'Top Right',
      '4': 'Mid Left',
      '5': 'Mid Center',
      '6': 'Mid Right',
      '7': 'Bottom Left',
      '8': 'Bottom Center',
      '9': 'Bottom Right',
    };
  }
}