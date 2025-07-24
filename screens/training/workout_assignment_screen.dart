import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/hockey_assessment_service.dart';
import 'package:hockey_shot_tracker/services/index.dart'; // ✅ Import the ApiService from index.dart
import 'package:intl/intl.dart';

class WorkoutAssignmentScreen extends StatefulWidget {
  const WorkoutAssignmentScreen({super.key});

  @override
  State<WorkoutAssignmentScreen> createState() => _WorkoutAssignmentScreenState();
}

class _WorkoutAssignmentScreenState extends State<WorkoutAssignmentScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  
  Map<AssessmentCategory, double> _scores = {};
  WorkoutGroup? _assignedGroup;
  Map<String, dynamic> _workoutPlan = {};
  late HockeyAssessmentService _assessmentService;
  
  @override
  void initState() {
    super.initState();
    // ✅ FIX: Initialize assessment service with ApiService from index.dart
    _assessmentService = HockeyAssessmentService(ApiService.instance);
    _loadAssessment();
  }
  
  Future<void> _loadAssessment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      if (appState.selectedPlayer.isEmpty || appState.players.isEmpty) {
        setState(() {
          _errorMessage = 'No player selected. Please select a player first.';
          _isLoading = false;
        });
        return;
      }
      
      final player = appState.players.firstWhere((p) => p.name == appState.selectedPlayer);
      
      if (player.id == null) {
        setState(() {
          _errorMessage = 'Player ID is missing. Please select a different player.';
          _isLoading = false;
        });
        return;
      }
      
      // ✅ FIX: Use the updated assessment service to get player assessment
      final playerAssessment = await _assessmentService.assessPlayer(player.id!);
      
      // Extract values from the assessment
      final scores = playerAssessment['scores'] as Map<AssessmentCategory, double>;
      final workoutGroup = playerAssessment['workoutGroup'] as WorkoutGroup;
      
      // Get workout plan details
      final workoutPlan = _assessmentService.getWorkoutPlan(workoutGroup, scores);
      
      setState(() {
        _scores = scores;
        _assignedGroup = workoutGroup;
        _workoutPlan = workoutPlan;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading assessment: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final playerName = appState.selectedPlayer;
    
    return AdaptiveScaffold(
      title: 'Workout Assignment',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget(deviceType, isLandscape)
                    : _buildAssignmentContent(deviceType, isLandscape, playerName),
          );
        },
      ),
    );
  }
  
  Widget _buildErrorWidget(DeviceType deviceType, bool isLandscape) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline, 
              color: Colors.red, 
              size: ResponsiveConfig.iconSize(context, 48),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              _errorMessage!,
              baseFontSize: 16,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red[700]),
            ),
            ResponsiveSpacing(multiplier: 3),
            ResponsiveButton(
              text: 'Try Again',
              onPressed: _loadAssessment,
              baseHeight: 48,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAssignmentContent(DeviceType deviceType, bool isLandscape, String playerName) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(playerName);
          case DeviceType.tablet:
            return _buildTabletLayout(playerName, isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout(playerName);
        }
      },
    );
  }

  Widget _buildMobileLayout(String playerName) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayerHeader(playerName),
          ResponsiveSpacing(multiplier: 3),
          _buildAssessmentScores(),
          ResponsiveSpacing(multiplier: 3),
          _buildGroupAssignment(),
          ResponsiveSpacing(multiplier: 3),
          _buildWorkoutPlanDetails(),
          ResponsiveSpacing(multiplier: 4),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(String playerName, bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout(playerName);
    }

    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayerHeader(playerName),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAssessmentScores(),
                    ResponsiveSpacing(multiplier: 3),
                    _buildGroupAssignment(),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                flex: 4,
                child: _buildWorkoutPlanDetails(),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 4),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(String playerName) {
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
                _buildPlayerHeader(playerName),
                ResponsiveSpacing(multiplier: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildAssessmentScores(),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: _buildGroupAssignment(),
                    ),
                  ],
                ),
                ResponsiveSpacing(multiplier: 3),
                _buildWorkoutPlanDetails(),
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
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopSidebar() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
            text: 'Start Program',
            onPressed: _startProgram,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.play_arrow,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Share Assessment',
            onPressed: _shareAssessment,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.share,
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'Assessment Summary',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Recommended Group', HockeyAssessmentService.getWorkoutGroupName(_assignedGroup!)),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Assessment Date', DateFormat('MMM d, yyyy').format(DateTime.now())),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Focus Areas', _workoutPlan['primaryFocus'] ?? 'General'),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value) {
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
  
  Widget _buildPlayerHeader(String playerName) {
    return Row(
      children: [
        CircleAvatar(
          radius: ResponsiveConfig.dimension(context, 30),
          backgroundColor: Colors.cyanAccent,
          child: ResponsiveText(
            playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
            baseFontSize: 24,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                playerName,
                baseFontSize: 24,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
              ),
              ResponsiveText(
                'Shot Assessment Results',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveText(
                'Generated on ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blueGrey[400]),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildAssessmentScores() {
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 12,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              'Assessment Scores',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            ResponsiveSpacing(multiplier: 2),
            ...AssessmentCategory.values.map((category) {
              final score = _scores[category] ?? 0.0;
              return _buildScoreBar(category, score);
            }),
          ],
        ),
      ),
    );
  }
  
  Widget _buildScoreBar(AssessmentCategory category, double score) {
    final categoryName = HockeyAssessmentService.getCategoryName(category);
    final color = _getScoreColor(score);
    
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
                categoryName,
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              ResponsiveText(
                score.toStringAsFixed(1),
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 0.5),
          LinearProgressIndicator(
            value: score / 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: ResponsiveConfig.dimension(context, 8),
            borderRadius: ResponsiveConfig.borderRadius(context, 4),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Weak',
                baseFontSize: 10,
                style: TextStyle(color: Colors.grey[600]),
              ),
              ResponsiveText(
                'Average',
                baseFontSize: 10,
                style: TextStyle(color: Colors.grey[600]),
              ),
              ResponsiveText(
                'Strong',
                baseFontSize: 10,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Color _getScoreColor(double score) {
    // Define thresholds (moved from HockeyAssessmentMatrix to here)
    const double lowThreshold = 3.0;
    const double mediumThreshold = 6.0;
    const double highThreshold = 8.0;
    
    if (score < lowThreshold) {
      return Colors.red;
    } else if (score < mediumThreshold) {
      return Colors.orange;
    } else if (score < highThreshold) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
  
  Widget _buildGroupAssignment() {
    if (_assignedGroup == null) {
      return const SizedBox();
    }
    
    final groupName = HockeyAssessmentService.getWorkoutGroupName(_assignedGroup!);
    final groupDescription = HockeyAssessmentService.getWorkoutGroupDescription(_assignedGroup!);
    
    return ResponsiveCard(
      elevation: 2,
      backgroundColor: Colors.cyanAccent.withAlpha(26),
      baseBorderRadius: 12,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getWorkoutGroupIcon(_assignedGroup!),
                    color: Colors.blueGrey[900],
                    size: ResponsiveConfig.iconSize(context, 24),
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ResponsiveText(
                        'Recommended Workout Group',
                        baseFontSize: 14,
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                      ResponsiveText(
                        groupName,
                        baseFontSize: 20,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[900],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              groupDescription,
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[800]),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getWorkoutGroupIcon(WorkoutGroup group) {
    switch (group) {
      case WorkoutGroup.powerDevelopment:
        return Icons.flash_on;
      case WorkoutGroup.accuracyRefinement:
        return Icons.gps_fixed;
      case WorkoutGroup.quickReleaseTraining:
        return Icons.timer;
      case WorkoutGroup.balancedDevelopment:
        return Icons.balance;
      case WorkoutGroup.advancedTechnique:
        return Icons.star;
      case WorkoutGroup.gameReadiness:
        return Icons.sports_hockey;
    }
  }
  
  Widget _buildWorkoutPlanDetails() {
    if (_workoutPlan.isEmpty) {
      return const SizedBox();
    }
    
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 12,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              _workoutPlan['title'] ?? 'Workout Plan',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              _workoutPlan['description'] ?? '',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            Divider(height: ResponsiveConfig.spacing(context, 32)),
            _buildInfoRow('Duration', _workoutPlan['duration'] ?? '', Icons.calendar_today),
            _buildInfoRow('Primary Focus', _workoutPlan['primaryFocus'] ?? '', Icons.center_focus_strong),
            _buildInfoRow('Secondary Focus', _workoutPlan['secondaryFocus'] ?? '', Icons.center_focus_weak),
            _buildInfoRow('Intensity', _workoutPlan['intensity'] ?? '', Icons.speed),
            _buildInfoRow('Weekly Workouts', _workoutPlan['weeklyWorkouts']?.toString() ?? '', Icons.event),
            _buildInfoRow('Weekly Shots', _workoutPlan['weeklyShots']?.toString() ?? '', Icons.track_changes),
            Divider(height: ResponsiveConfig.spacing(context, 32)),
            _buildProgramsList('Primary Programs', _workoutPlan['primaryPrograms'] ?? []),
            ResponsiveSpacing(multiplier: 2),
            _buildProgramsList('Supplemental Programs', _workoutPlan['supplementalPrograms'] ?? []),
            ResponsiveSpacing(multiplier: 2),
            _buildZonesFocus(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: ResponsiveConfig.iconSize(context, 18),
            color: Colors.blueGrey[400],
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            flex: 2,
            child: ResponsiveText(
              '$label:',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ),
          Expanded(
            flex: 3,
            child: ResponsiveText(
              value,
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[900],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProgramsList(String title, List<dynamic> programs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          title,
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        ...programs.map((program) => Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2, horizontal: 8),
          child: Row(
            children: [
              Icon(
                Icons.check_circle,
                size: ResponsiveConfig.iconSize(context, 16),
                color: Colors.green,
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  program,
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildZonesFocus() {
    final zones = (_workoutPlan['zones'] as List<dynamic>?) ?? [];
    final shotTypes = (_workoutPlan['shotTypes'] as List<dynamic>?) ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Focus Zones & Shot Types',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            if (deviceType == DeviceType.mobile && !isLandscape) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildZonesGrid(zones),
                  ResponsiveSpacing(multiplier: 2),
                  _buildShotTypesList(shotTypes),
                ],
              );
            } else {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildZonesGrid(zones)),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(child: _buildShotTypesList(shotTypes)),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildZonesGrid(List<dynamic> zones) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Primary Zones',
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
        ResponsiveSpacing(multiplier: 1),
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey[300]!),
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
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
                final zoneNumber = _indexToZone(index);
                final isTargeted = zones.contains(zoneNumber.toString());
                
                return Container(
                  decoration: BoxDecoration(
                    color: isTargeted ? Colors.cyanAccent : Colors.grey[200],
                    borderRadius: ResponsiveConfig.borderRadius(context, 4),
                  ),
                  child: Center(
                    child: ResponsiveText(
                      zoneNumber.toString(),
                      baseFontSize: 14,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isTargeted ? Colors.black87 : Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShotTypesList(List<dynamic> shotTypes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Primary Shot Types',
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
        ResponsiveSpacing(multiplier: 1),
        ...['Wrist', 'Snap', 'Slap', 'Backhand', 'One-timer'].map((type) {
          final isIncluded = shotTypes.contains(type);
          return Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            child: Row(
              children: [
                Container(
                  width: ResponsiveConfig.dimension(context, 16),
                  height: ResponsiveConfig.dimension(context, 16),
                  decoration: BoxDecoration(
                    color: isIncluded ? Colors.cyanAccent : Colors.grey[200],
                    shape: BoxShape.circle,
                  ),
                  child: isIncluded
                      ? Icon(
                          Icons.check,
                          size: ResponsiveConfig.iconSize(context, 12),
                          color: Colors.black87,
                        )
                      : null,
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  type,
                  baseFontSize: 14,
                  style: TextStyle(
                    color: isIncluded ? Colors.blueGrey[800] : Colors.grey[400],
                    fontWeight: isIncluded ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
  
  int _indexToZone(int index) {
    // Convert index (0-8) to zone (1-9)
    final row = index ~/ 3; // 0, 1, or 2
    final col = index % 3; // 0, 1, or 2
    return (2 - row) * 3 + col + 1;
  }
  
  Widget _buildActionButtons() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        if (deviceType == DeviceType.desktop) {
          return SizedBox.shrink(); // Actions in sidebar
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Start Program',
                onPressed: _startProgram,
                baseHeight: 48,
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                icon: Icons.play_arrow,
              ),
            ),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveButton(
                text: 'Share',
                onPressed: _shareAssessment,
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

  void _startProgram() {
    // ✅ FIX: Use the new service architecture for starting workout programs
    try {
      // Implementation could use ApiServiceFactory.training.startProgram() or similar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            'Starting workout program for ${_assignedGroup != null ? HockeyAssessmentService.getWorkoutGroupName(_assignedGroup!) : 'selected group'}...',
            baseFontSize: 16,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            'Error starting program: $e',
            baseFontSize: 16,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _shareAssessment() {
    // ✅ FIX: Use the new service architecture for exporting assessments
    try {
      // Implementation could use ApiServiceFactory.reports.generateAssessmentReport() or similar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            'Exporting assessment report...',
            baseFontSize: 16,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(
            'Error exporting assessment: $e',
            baseFontSize: 16,
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}