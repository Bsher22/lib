// lib/widgets/domain/assessment/shot/shot_result_details_tab.dart
// PHASE 4 UPDATE: Assessment Screen Responsive Design Implementation

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/zone_heatmap_widget.dart';
import 'package:intl/intl.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotResultDetailsTab extends StatelessWidget {
  final Map<String, dynamic> assessment;
  final Map<String, dynamic> results;
  final Map<int, List<Map<String, dynamic>>> shotResults;

  const ShotResultDetailsTab({
    Key? key,
    required this.assessment,
    required this.results,
    required this.shotResults,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final zoneMetrics = _computeZoneMetrics();
    final zoneLabels = _getZoneLabels();
    final totalShots = _calculateTotalShots();

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
                // Responsive heatmap section
                _buildHeatmapSection(context, zoneMetrics, zoneLabels, totalShots, deviceType, isLandscape),
                ResponsiveSpacing(multiplier: 2),
                
                // Responsive group details section
                _buildGroupDetailsSection(context, deviceType, isLandscape),
                ResponsiveSpacing(multiplier: 2),
                
                // Responsive shot details section
                _buildShotDetailsSection(context, deviceType, isLandscape),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeatmapSection(BuildContext context, Map<String, Map<String, dynamic>> zoneMetrics, Map<String, String> zoneLabels, int totalShots, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileHeatmap(context, zoneMetrics, zoneLabels, totalShots);
      case DeviceType.tablet:
        return _buildTabletHeatmap(context, zoneMetrics, zoneLabels, totalShots);
      case DeviceType.desktop:
        return _buildDesktopHeatmap(context, zoneMetrics, zoneLabels, totalShots);
    }
  }

  Widget _buildMobileHeatmap(BuildContext context, Map<String, Map<String, dynamic>> zoneMetrics, Map<String, String> zoneLabels, int totalShots) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Placement Heatmap',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          Center(
            child: SizedBox(
              height: 250,
              child: ZoneHeatmapWidget(
                zoneMetrics: zoneMetrics,
                zoneLabels: zoneLabels,
                totalShots: totalShots,
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.blue[900]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'Success Rate: Low to High',
                  baseFontSize: 12,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletHeatmap(BuildContext context, Map<String, Map<String, dynamic>> zoneMetrics, Map<String, String> zoneLabels, int totalShots) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Placement Heatmap',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 300,
                  child: ZoneHeatmapWidget(
                    zoneMetrics: zoneMetrics,
                    zoneLabels: zoneLabels,
                    totalShots: totalShots,
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                flex: 1,
                child: _buildHeatmapStats(context, zoneMetrics, totalShots),
              ),
            ],
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 16,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[100]!, Colors.blue[900]!],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'Success Rate: Low to High',
                  baseFontSize: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopHeatmap(BuildContext context, Map<String, Map<String, dynamic>> zoneMetrics, Map<String, String> zoneLabels, int totalShots) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Shot Placement Heatmap',
                  baseFontSize: 20,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 2),
                
                SizedBox(
                  height: 350,
                  child: ZoneHeatmapWidget(
                    zoneMetrics: zoneMetrics,
                    zoneLabels: zoneLabels,
                    totalShots: totalShots,
                  ),
                ),
                
                ResponsiveSpacing(multiplier: 2),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 16,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[100]!, Colors.blue[900]!],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    ResponsiveText(
                      'Success Rate: Low to High',
                      baseFontSize: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        
        Expanded(
          flex: 1,
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Zone Statistics',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveSpacing(multiplier: 2),
                
                _buildHeatmapStats(context, zoneMetrics, totalShots),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapStats(BuildContext context, Map<String, Map<String, dynamic>> zoneMetrics, int totalShots) {
    final sortedZones = zoneMetrics.entries.toList()
      ..sort((a, b) => (b.value['count'] as int).compareTo(a.value['count'] as int));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...sortedZones.take(5).map((entry) {
          final zone = entry.key;
          final count = entry.value['count'] as int;
          final successRate = entry.value['successRate'] as double;
          
          return Container(
            margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            padding: ResponsiveConfig.paddingAll(context, 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Zone $zone',
                      baseFontSize: 12,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveText(
                      _getZoneLabels()[zone] ?? '',
                      baseFontSize: 10,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ResponsiveText(
                      '$count shots',
                      baseFontSize: 11,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                    ResponsiveText(
                      '${(successRate * 100).toStringAsFixed(0)}%',
                      baseFontSize: 11,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AssessmentShotUtils.getSuccessRateColor(successRate),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        
        if (sortedZones.length > 5)
          ResponsiveText(
            '+ ${sortedZones.length - 5} more zones',
            baseFontSize: 10,
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildGroupDetailsSection(BuildContext context, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileGroupDetails(context);
      case DeviceType.tablet:
        return _buildTabletGroupDetails(context);
      case DeviceType.desktop:
        return _buildDesktopGroupDetails(context);
    }
  }

  Widget _buildMobileGroupDetails(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Group Details',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Vertical stack on mobile
          for (int i = 0; i < (assessment['groups'] as List? ?? []).length; i++)
            if (shotResults.containsKey(i) && shotResults[i]!.isNotEmpty)
              _buildGroupCard(context, i),
        ],
      ),
    );
  }

  Widget _buildTabletGroupDetails(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Group Details',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Two-column grid on tablet
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: ResponsiveConfig.spacing(context, 12),
              mainAxisSpacing: ResponsiveConfig.spacing(context, 12),
              childAspectRatio: 2.5,
            ),
            itemCount: (assessment['groups'] as List? ?? []).where((group) {
              final index = (assessment['groups'] as List).indexOf(group);
              return shotResults.containsKey(index) && shotResults[index]!.isNotEmpty;
            }).length,
            itemBuilder: (context, index) {
              final validGroups = <int>[];
              for (int i = 0; i < (assessment['groups'] as List? ?? []).length; i++) {
                if (shotResults.containsKey(i) && shotResults[i]!.isNotEmpty) {
                  validGroups.add(i);
                }
              }
              return _buildGroupCard(context, validGroups[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopGroupDetails(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Shot Group Details',
            baseFontSize: 20,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Three-column grid on desktop
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
              mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
              childAspectRatio: 2.2,
            ),
            itemCount: (assessment['groups'] as List? ?? []).where((group) {
              final index = (assessment['groups'] as List).indexOf(group);
              return shotResults.containsKey(index) && shotResults[index]!.isNotEmpty;
            }).length,
            itemBuilder: (context, index) {
              final validGroups = <int>[];
              for (int i = 0; i < (assessment['groups'] as List? ?? []).length; i++) {
                if (shotResults.containsKey(i) && shotResults[i]!.isNotEmpty) {
                  validGroups.add(i);
                }
              }
              return _buildGroupCard(context, validGroups[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, int groupIndex) {
    final group = (assessment['groups'] as List? ?? [])[groupIndex];
    final groupShots = shotResults[groupIndex]!;
    final successRate = (groupShots.where((s) => s['success'] == true).length / groupShots.length * 100);

    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveConfig.dimension(context, 20),
                height: ResponsiveConfig.dimension(context, 20),
                decoration: const BoxDecoration(
                  color: Colors.cyanAccent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ResponsiveText(
                    '${groupIndex + 1}',
                    baseFontSize: 11,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  group['name'] as String? ?? 'Group ${groupIndex + 1}',
                  baseFontSize: 14,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Attempts: ${groupShots.length}/${group['shots'] ?? 'N/A'}',
                    baseFontSize: 12,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'Location: ${group['location'] as String? ?? 'Unknown'}',
                    baseFontSize: 11,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AssessmentShotUtils.getSuccessRateColor(successRate / 100).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ResponsiveText(
                  '${successRate.toStringAsFixed(0)}%',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssessmentShotUtils.getSuccessRateColor(successRate / 100),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShotDetailsSection(BuildContext context, DeviceType deviceType, bool isLandscape) {
    final shotLog = _getShotLogEntries();
    
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
                'Shot Details',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveText(
                'Total: ${_calculateTotalShots()} shots',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive shot details table
          _buildShotDetailsTable(context, shotLog, deviceType, isLandscape),
        ],
      ),
    );
  }

  Widget _buildShotDetailsTable(BuildContext context, List<Map<String, dynamic>> shotLog, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileShotTable(context, shotLog);
      case DeviceType.tablet:
        return _buildTabletShotTable(context, shotLog);
      case DeviceType.desktop:
        return _buildDesktopShotTable(context, shotLog);
    }
  }

  Widget _buildMobileShotTable(BuildContext context, List<Map<String, dynamic>> shotLog) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: shotLog.take(10).map((shot) => Container(
        margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
        padding: ResponsiveConfig.paddingAll(context, 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    '${shot['shot']['type']} - Zone ${shot['shot']['zone']}',
                    baseFontSize: 12,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveText(
                    (assessment['groups'] as List? ?? [])[shot['groupIndex']]['name'] as String? ?? 'Group ${shot['groupIndex'] + 1}',
                    baseFontSize: 10,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            ResponsiveText(
              shot['shot']['outcome'] as String? ?? 'Unknown',
              baseFontSize: 11,
              style: TextStyle(
                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTabletShotTable(BuildContext context, List<Map<String, dynamic>> shotLog) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: ResponsiveText('Group', baseFontSize: 12, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Type', baseFontSize: 12, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: ResponsiveText('Zone', baseFontSize: 12, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Result', baseFontSize: 12, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          // Table rows
          Expanded(
            child: ListView.builder(
              itemCount: shotLog.length,
              itemBuilder: (context, index) {
                final shot = shotLog[index];
                return Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          (assessment['groups'] as List? ?? [])[shot['groupIndex']]['name'] as String? ?? 'Group ${shot['groupIndex'] + 1}',
                          baseFontSize: 11,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          shot['shot']['type'] as String? ?? 'Unknown',
                          baseFontSize: 11,
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ResponsiveText(
                          shot['shot']['zone'] as String? ?? '0',
                          baseFontSize: 11,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                            ResponsiveText(
                              shot['shot']['outcome'] as String? ?? 'Unknown',
                              baseFontSize: 11,
                              style: TextStyle(
                                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopShotTable(BuildContext context, List<Map<String, dynamic>> shotLog) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced header
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!, width: 2)),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: ResponsiveText('Group', baseFontSize: 14, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Shot Type', baseFontSize: 14, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Zone & Location', baseFontSize: 14, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: ResponsiveText('Result', baseFontSize: 14, style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 1, child: ResponsiveText('Time', baseFontSize: 14, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          
          // Enhanced table rows
          Expanded(
            child: ListView.builder(
              itemCount: shotLog.length,
              itemBuilder: (context, index) {
                final shot = shotLog[index];
                return Container(
                  padding: ResponsiveConfig.paddingSymmetric(
                    context,
                    vertical: 12,
                    horizontal: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                    color: index % 2 == 0 ? Colors.white : Colors.grey[50],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          (assessment['groups'] as List? ?? [])[shot['groupIndex']]['name'] as String? ?? 'Group ${shot['groupIndex'] + 1}',
                          baseFontSize: 12,
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: ResponsiveText(
                          shot['shot']['type'] as String? ?? 'Unknown',
                          baseFontSize: 12,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              'Zone ${shot['shot']['zone'] as String? ?? '0'}',
                              baseFontSize: 12,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            ResponsiveText(
                              _getZoneLabel(shot['shot']['zone'] as String? ?? '0'),
                              baseFontSize: 10,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                            ResponsiveText(
                              shot['shot']['outcome'] as String? ?? 'Unknown',
                              baseFontSize: 12,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: shot['shot']['success'] == true ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: ResponsiveText(
                          _formatTime(shot['shot']['timestamp'] as String?),
                          baseFontSize: 10,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '--:--';
    try {
      final date = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return '--:--';
    }
  }

  // Keep all existing business logic methods unchanged
  int _calculateTotalShots() {
    int total = 0;
    for (var groupShots in shotResults.values) {
      total += groupShots.length;
    }
    return total;
  }

  Map<String, Map<String, dynamic>> _computeZoneMetrics() {
    final zoneMetrics = <String, Map<String, dynamic>>{};
    for (var zone in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) {
      zoneMetrics[zone] = {
        'count': 0,
        'successRate': (results['zoneRates'] as Map<String, dynamic>?)?[zone] ?? 0.0,
      };
    }

    for (var groupShots in shotResults.values) {
      for (var shot in groupShots) {
        final zone = shot['zone'] as String? ?? '0';
        if (zoneMetrics.containsKey(zone)) {
          zoneMetrics[zone]!['count'] = (zoneMetrics[zone]!['count'] as int) + 1;
        }
      }
    }

    return zoneMetrics;
  }

  Map<String, String> _getZoneLabels() {
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

  List<Map<String, dynamic>> _getShotLogEntries() {
    List<Map<String, dynamic>> entries = [];
    for (int groupIndex = 0; groupIndex < (assessment['groups'] as List? ?? []).length; groupIndex++) {
      if (shotResults.containsKey(groupIndex)) {
        for (var shot in shotResults[groupIndex]!) {
          entries.add({
            'groupIndex': groupIndex,
            'shot': shot,
          });
        }
      }
    }

    entries.sort((a, b) {
      final aTime = a['shot']['timestamp'] as String? ?? DateTime.now().toIso8601String();
      final bTime = b['shot']['timestamp'] as String? ?? DateTime.now().toIso8601String();
      return DateTime.parse(bTime).compareTo(DateTime.parse(aTime));
    });

    return entries;
  }

  String _getZoneLabel(String zone) {
    return _getZoneLabels()[zone] ?? 'Unknown';
  }
}