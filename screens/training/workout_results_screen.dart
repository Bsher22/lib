import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/index.dart';
import 'package:intl/intl.dart';

class WorkoutResultsScreen extends StatelessWidget {
  final Map<String, dynamic> results;

  const WorkoutResultsScreen({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    final workout = results['workout'] as CompletedWorkout;
    final shots = results['shots'] as List<Shot>;
    final time = results['time'] as int;
    final successRate = results['success_rate'] as double;

    final dateStr = DateFormat('MMMM d, yyyy').format(workout.dateCompleted);

    return AdaptiveScaffold(
      title: 'Workout Results',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: _buildResultsContent(context, deviceType, isLandscape, workout, shots, time, successRate, dateStr),
          );
        },
      ),
    );
  }

  Widget _buildResultsContent(BuildContext context, DeviceType deviceType, bool isLandscape, CompletedWorkout workout, List<Shot> shots, int time, double successRate, String dateStr) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(context, workout, shots, time, successRate, dateStr);
          case DeviceType.tablet:
            return _buildTabletLayout(context, workout, shots, time, successRate, dateStr, isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout(context, workout, shots, time, successRate, dateStr);
        }
      },
    );
  }

  Widget _buildMobileLayout(BuildContext context, CompletedWorkout workout, List<Shot> shots, int time, double successRate, String dateStr) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompletionHeader(context, workout, dateStr),
          ResponsiveSpacing(multiplier: 3),
          _buildSummaryCards(context, workout, successRate, time),
          ResponsiveSpacing(multiplier: 3),
          _buildShotTypeBreakdown(context, shots),
          ResponsiveSpacing(multiplier: 3),
          _buildZoneBreakdown(context, shots),
          ResponsiveSpacing(multiplier: 4),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context, CompletedWorkout workout, List<Shot> shots, int time, double successRate, String dateStr, bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout(context, workout, shots, time, successRate, dateStr);
    }

    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompletionHeader(context, workout, dateStr),
          ResponsiveSpacing(multiplier: 3),
          _buildSummaryCards(context, workout, successRate, time),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildShotTypeBreakdown(context, shots)),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildZoneBreakdown(context, shots)),
            ],
          ),
          ResponsiveSpacing(multiplier: 4),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, CompletedWorkout workout, List<Shot> shots, int time, double successRate, String dateStr) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCompletionHeader(context, workout, dateStr),
                ResponsiveSpacing(multiplier: 3),
                _buildSummaryCards(context, workout, successRate, time),
                ResponsiveSpacing(multiplier: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildShotTypeBreakdown(context, shots)),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildZoneBreakdown(context, shots)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 320,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildDesktopSidebar(context, workout, shots, time, successRate),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar(BuildContext context, CompletedWorkout workout, List<Shot> shots, int time, double successRate) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Workout Summary',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard(context, 'Program', workout.programName ?? 'Training Session'),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard(context, 'Duration', _formatTime(time)),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard(context, 'Success Rate', '${(successRate * 100).toStringAsFixed(1)}%'),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Home',
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.home,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Share Results',
            onPressed: () => _showShareOptions(context),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.share,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'New Workout',
            onPressed: () => Navigator.pushNamed(context, '/training-programs'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            icon: Icons.fitness_center,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String label, String value) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            value,
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionHeader(BuildContext context, CompletedWorkout workout, String dateStr) {
    return ResponsiveCard(
      baseBorderRadius: 16,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(52),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: ResponsiveConfig.iconSize(context, 32),
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        'Workout Completed!',
                        baseFontSize: 24,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                      ResponsiveText(
                        workout.programName ?? 'Training Session',
                        baseFontSize: 16,
                        style: TextStyle(color: Colors.blueGrey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Completed on $dateStr',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(BuildContext context, CompletedWorkout workout, double successRate, int time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Workout Summary',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            if (deviceType == DeviceType.mobile && !isLandscape) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.sports_hockey,
                          '${workout.totalShots}',
                          'Total Shots',
                          Colors.blue,
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.check_circle,
                          '${workout.successfulShots}',
                          'Successful',
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.bar_chart,
                          '${(successRate * 100).toStringAsFixed(1)}%',
                          'Success Rate',
                          Colors.purple,
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          Icons.timer,
                          _formatTime(time),
                          'Duration',
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.sports_hockey,
                      '${workout.totalShots}',
                      'Total Shots',
                      Colors.blue,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.check_circle,
                      '${workout.successfulShots}',
                      'Successful',
                      Colors.green,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.bar_chart,
                      '${(successRate * 100).toStringAsFixed(1)}%',
                      'Success Rate',
                      Colors.purple,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      Icons.timer,
                      _formatTime(time),
                      'Duration',
                      Colors.orange,
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, IconData icon, String value, String label, Color color) {
    return ResponsiveCard(
      baseBorderRadius: 12,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: ResponsiveConfig.paddingAll(context, 12),
              decoration: BoxDecoration(
                color: color.withAlpha(52),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: ResponsiveConfig.iconSize(context, 24),
              ),
            ),
            ResponsiveSpacing(multiplier: 1.5),
            ResponsiveText(
              value,
              baseFontSize: 24,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              label,
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShotTypeBreakdown(BuildContext context, List<Shot> shots) {
    // Group shots by type
    final shotTypes = <String, Map<String, dynamic>>{};

    for (final shot in shots) {
      final type = shot.type ?? "Unknown";
      if (!shotTypes.containsKey(type)) {
        shotTypes[type] = {
          'total': 0,
          'success': 0,
        };
      }
      shotTypes[type]!['total'] = shotTypes[type]!['total'] + 1;
      if (shot.success) {
        shotTypes[type]!['success'] = shotTypes[type]!['success'] + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Shots Breakdown',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        ResponsiveCard(
          baseBorderRadius: 12,
          child: Padding(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: shotTypes.entries.map((entry) {
                final type = entry.key;
                final total = entry.value['total'] as int;
                final success = entry.value['success'] as int;
                final rate = total > 0 ? success / total : 0.0;

                return Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ResponsiveText(
                            type,
                            baseFontSize: 16,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[800],
                            ),
                          ),
                          ResponsiveText(
                            '$success/$total (${(rate * 100).toStringAsFixed(1)}%)',
                            baseFontSize: 14,
                            style: TextStyle(color: Colors.blueGrey[700]),
                          ),
                        ],
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      LinearProgressIndicator(
                        value: rate,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(_getSuccessColor(rate)),
                        minHeight: ResponsiveConfig.dimension(context, 8),
                        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 4)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneBreakdown(BuildContext context, List<Shot> shots) {
    // Group shots by zone
    final zones = <String, Map<String, dynamic>>{};

    for (final shot in shots) {
      final zone = shot.zone ?? "0"; // Use zone with fallback to "0"
      if (!zones.containsKey(zone)) {
        zones[zone] = {
          'total': 0,
          'success': 0,
        };
      }
      zones[zone]!['total'] = zones[zone]!['total'] + 1;
      if (shot.success) {
        zones[zone]!['success'] = zones[zone]!['success'] + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Zone Performance',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[900],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        ResponsiveCard(
          baseBorderRadius: 12,
          child: Padding(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blueGrey[300]!),
                      borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      padding: ResponsiveConfig.paddingAll(context, 4),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, index) {
                        // Convert index to zone (1-9)
                        final row = index ~/ 3; // 0, 1, or 2
                        final col = index % 3; // 0, 1, or 2
                        final zoneNumber = (2 - row) * 3 + col + 1;
                        final zone = zoneNumber.toString();

                        final zoneData = zones[zone];
                        final hasShots = zoneData != null && zoneData['total'] > 0;
                        final total = hasShots ? zoneData['total'] as int : 0;
                        final success = hasShots ? zoneData['success'] as int : 0;
                        final rate = total > 0 ? success / total : 0.0;

                        return Container(
                          decoration: BoxDecoration(
                            color: hasShots ? _getSuccessColor(rate).withAlpha(52) : Colors.grey[200],
                            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ResponsiveText(
                                zone,
                                baseFontSize: 16,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: hasShots ? Colors.blueGrey[800] : Colors.grey[400],
                                ),
                              ),
                              if (hasShots) ...[
                                ResponsiveSpacing(multiplier: 0.5),
                                ResponsiveText(
                                  '$success/$total',
                                  baseFontSize: 12,
                                  style: TextStyle(color: Colors.blueGrey[700]),
                                ),
                                ResponsiveText(
                                  '${(rate * 100).toStringAsFixed(0)}%',
                                  baseFontSize: 12,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getSuccessColor(rate),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        if (deviceType == DeviceType.desktop) {
          return SizedBox.shrink(); // Actions in sidebar
        }

        return Row(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Home',
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (route) => false,
                ),
                baseHeight: 48,
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                icon: Icons.home,
              ),
            ),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveButton(
                text: 'Share',
                onPressed: () => _showShareOptions(context),
                baseHeight: 48,
                backgroundColor: Colors.blueGrey[100],
                foregroundColor: Colors.blueGrey[700],
                icon: Icons.share,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showShareOptions(BuildContext context) async {
    final workout = results['workout'] as CompletedWorkout;
    
    // Use DialogService.showSelection to show share options
    final selectedOption = await DialogService.showSelection<String>(
      context,
      title: 'Share Workout Results',
      message: 'Choose how to share your results:',
      options: ['CSV Report', 'PDF Report', 'Results Summary', 'Share Screenshot'],
      itemBuilder: (context, option) {
        IconData icon;
        switch (option) {
          case 'CSV Report':
            icon = Icons.table_chart;
            break;
          case 'PDF Report':
            icon = Icons.picture_as_pdf;
            break;
          case 'Results Summary':
            icon = Icons.summarize;
            break;
          case 'Share Screenshot':
            icon = Icons.photo_camera;
            break;
          default:
            icon = Icons.share;
        }
        
        return Row(
          children: [
            Icon(icon, color: Colors.blueGrey[700], size: ResponsiveConfig.iconSize(context, 20)),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            ResponsiveText(
              option,
              baseFontSize: 16,
            ),
          ],
        );
      },
    );
    
    if (selectedOption == null) return;
    
    // First show loading dialog
    DialogService.showLoading(
      context,
      message: 'Preparing ${selectedOption.toLowerCase()}...',
      color: Colors.cyanAccent[700],
    );
    
    try {
      // Simulate processing time
      await Future.delayed(const Duration(seconds: 2));
      
      // Hide loading dialog
      DialogService.hideLoading(context);
      
      // Show success message based on selection
      switch (selectedOption) {
        case 'CSV Report':
          await _shareCSVReport(context);
          break;
        case 'PDF Report':
          await _sharePDFReport(context);
          break;
        case 'Results Summary':
          await _shareResultsSummary(context);
          break;
        case 'Share Screenshot':
          await _shareScreenshot(context);
          break;
      }
    } catch (e) {
      // Hide loading dialog
      DialogService.hideLoading(context);
      
      // Show error message
      await DialogService.showError(
        context,
        title: 'Sharing Failed',
        message: 'Error sharing workout results: $e',
      );
    }
  }

  Future<void> _shareCSVReport(BuildContext context) async {
    // Implement CSV sharing logic
    // ...
    
    // Show success message
    await DialogService.showSuccess(
      context,
      title: 'CSV Report Generated',
      message: 'Your workout CSV report has been generated and is ready to share.',
    );
  }

  Future<void> _sharePDFReport(BuildContext context) async {
    // Implement PDF sharing logic
    // ...
    
    // Show success message
    await DialogService.showSuccess(
      context,
      title: 'PDF Report Generated',
      message: 'Your workout PDF report has been generated and is ready to share.',
    );
  }

  Future<void> _shareResultsSummary(BuildContext context) async {
    final workout = results['workout'] as CompletedWorkout;
    final successRate = results['success_rate'] as double;
    final time = results['time'] as int;
    
    // Prepare summary text
    final summary = '''
Workout: ${workout.programName}
Date: ${DateFormat('MMMM d, yyyy').format(workout.dateCompleted)}
Total Shots: ${workout.totalShots}
Success Rate: ${(successRate * 100).toStringAsFixed(1)}%
Duration: ${_formatTime(time)}

Shared from Hockey Shot Tracker App
''';
    
    // Show preview dialog before sharing
    final confirmed = await DialogService.showCustom<bool>(
      context,
      content: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Results Summary',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 2),
            Container(
              padding: ResponsiveConfig.paddingAll(context, 12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ResponsiveText(summary, baseFontSize: 14),
            ),
            ResponsiveSpacing(multiplier: 3),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: ResponsiveText('Cancel', baseFontSize: 14),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveButton(
                  text: 'Share',
                  onPressed: () => Navigator.of(context).pop(true),
                  baseHeight: 40,
                  backgroundColor: Colors.cyanAccent[700],
                  foregroundColor: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
    
    if (confirmed == true) {
      // Implement sharing logic using Share.share()
      // ...
      
      // Show confirmation
      await DialogService.showInformation(
        context,
        title: 'Summary Shared',
        message: 'Your workout summary has been shared.',
      );
    }
  }

  Future<void> _shareScreenshot(BuildContext context) async {
    // Implement screenshot sharing logic
    // ...
    
    // Show camera permission dialog if needed
    final hasPermission = await DialogService.showConfirmation(
      context,
      title: 'Camera Permission',
      message: 'Hockey Shot Tracker needs permission to capture screenshots. Allow?',
      confirmLabel: 'Allow',
      cancelLabel: 'Deny',
    );
    
    if (hasPermission != true) {
      await DialogService.showInformation(
        context,
        title: 'Permission Denied',
        message: 'Cannot capture screenshot without permission.',
      );
      return;
    }
    
    // Continue with screenshot logic
    // ...
    
    // Show success message
    await DialogService.showSuccess(
      context,
      title: 'Screenshot Shared',
      message: 'Your workout screenshot has been shared.',
    );
  }

  String _formatTime(int seconds) {
    return TimeFormatter.formatMMSS(Duration(seconds: seconds));
  }

  Color _getSuccessColor(double rate) {
    if (rate < 0.33) {
      return Colors.red;
    } else if (rate < 0.67) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}