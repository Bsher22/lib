// lib/screens/assessments/assessments_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class AssessmentsScreen extends StatelessWidget {
  const AssessmentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Assessments',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 1200 : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  _buildHeader(context),
                  ResponsiveSpacing(multiplier: 3),

                  // Individual Assessments Section
                  _buildSectionHeader(context, 'Individual Assessments', Icons.person),
                  ResponsiveSpacing(multiplier: 2),
                  _buildIndividualAssessments(context, deviceType),
                  ResponsiveSpacing(multiplier: 4),

                  // Team Assessments Section
                  _buildSectionHeader(context, 'Team Assessments', Icons.group),
                  ResponsiveSpacing(multiplier: 2),
                  _buildTeamAssessments(context, deviceType),
                  ResponsiveSpacing(multiplier: 4),

                  // Recent Assessments Section
                  _buildSectionHeader(context, 'Recent Assessments', Icons.history),
                  ResponsiveSpacing(multiplier: 2),
                  _buildRecentAssessments(context, deviceType),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: Icon(
                  Icons.assessment,
                  size: ResponsiveConfig.iconSize(context, 32),
                  color: Colors.blue[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Hockey Assessments',
                      baseFontSize: 28,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      'Evaluate player performance with standardized testing protocols',
                      baseFontSize: 16,
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

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: ResponsiveConfig.iconSize(context, 24),
          color: Colors.blueGrey[700],
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveText(
          title,
          baseFontSize: 22,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildIndividualAssessments(BuildContext context, DeviceType deviceType) {
    final assessments = [
      {
        'title': 'Shot Assessment',
        'subtitle': 'Individual shooting accuracy and power evaluation',
        'icon': Icons.sports_hockey,
        'color': Colors.red,
        'route': '/shot-assessment-setup',
        'description': 'Comprehensive shooting assessment with zone targeting, accuracy measurement, and power analysis',
        'duration': '30-45 min',
        'features': ['Zone targeting', 'Shot accuracy', 'Power measurement', 'Quick release timing'],
      },
      {
        'title': 'Skating Assessment',
        'subtitle': 'Speed, agility, and skating fundamentals',
        'icon': Icons.speed,
        'color': Colors.green,
        'route': '/skating-assessment-setup',
        'description': 'Complete skating evaluation including speed tests, agility drills, and technique analysis',
        'duration': '20-30 min',
        'features': ['Forward/backward speed', 'Lateral movement', 'Transitions', 'Agility drills'],
      },
    ];

    return _buildAssessmentGrid(context, deviceType, assessments);
  }

  Widget _buildTeamAssessments(BuildContext context, DeviceType deviceType) {
    final assessments = [
      {
        'title': 'Team Shot Assessment',
        'subtitle': 'Group shooting evaluation and comparison',
        'icon': Icons.group,
        'color': Colors.blue,
        'route': '/team-shot-assessment-setup',
        'description': 'Assess multiple players simultaneously with team-wide shooting metrics and analysis',
        'duration': '45-60 min',
        'features': ['Multi-player tracking', 'Team statistics', 'Player comparison', 'Group performance'],
      },
      {
        'title': 'Team Skating Assessment',
        'subtitle': 'Team-wide skating performance evaluation',
        'icon': Icons.groups,
        'color': Colors.purple,
        'route': '/team-skating-assessment-setup',
        'description': 'Comprehensive team skating assessment with comparative analysis and team metrics',
        'duration': '40-55 min',
        'features': ['Team averages', 'Performance ranking', 'Group testing', 'Comparative analysis'],
      },
    ];

    return _buildAssessmentGrid(context, deviceType, assessments);
  }

  Widget _buildAssessmentGrid(BuildContext context, DeviceType deviceType, List<Map<String, dynamic>> assessments) {
    final columns = deviceType.responsive<int>(
      mobile: 1,
      tablet: 2,
      desktop: 2,
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
        childAspectRatio: deviceType == DeviceType.mobile ? 1.1 : 1.3,
      ),
      itemCount: assessments.length,
      itemBuilder: (context, index) {
        final assessment = assessments[index];
        return _buildAssessmentCard(context, assessment, deviceType);
      },
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Map<String, dynamic> assessment, DeviceType deviceType) {
    final color = assessment['color'] as MaterialColor;
    
    return ResponsiveCard(
      onTap: () => _navigateToAssessment(context, assessment['route'] as String),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and basic info
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 12)),
                topRight: Radius.circular(ResponsiveConfig.borderRadiusValue(context, 12)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: ResponsiveConfig.borderRadius(context, 10),
                  ),
                  child: Icon(
                    assessment['icon'] as IconData,
                    size: ResponsiveConfig.iconSize(context, 28),
                    color: color.shade700,
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        assessment['title'] as String,
                        baseFontSize: 18,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        assessment['duration'] as String,
                        baseFontSize: 12,
                        style: TextStyle(
                          color: color.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: Padding(
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    assessment['subtitle'] as String,
                    baseFontSize: 14,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    assessment['description'] as String,
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[600]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ResponsiveSpacing(multiplier: 1.5),
                  
                  // Features list
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            'Features:',
                            baseFontSize: 11,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                          ResponsiveSpacing(multiplier: 0.5),
                          ...(assessment['features'] as List<String>).map((feature) => 
                            Padding(
                              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 1),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: ResponsiveConfig.iconSize(context, 12),
                                    color: color.shade600,
                                  ),
                                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                                  Expanded(
                                    child: ResponsiveText(
                                      feature,
                                      baseFontSize: 10,
                                      style: TextStyle(color: Colors.blueGrey[600]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action button
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ResponsiveButton(
              text: 'Setup Assessment',
              onPressed: () => _navigateToAssessment(context, assessment['route'] as String),
              baseHeight: 44,
              width: double.infinity,
              backgroundColor: color.shade600,
              foregroundColor: Colors.white,
              icon: Icons.settings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessments(BuildContext context, DeviceType deviceType) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        // Mock recent assessments - replace with real data from appState
        final recentAssessments = [
          {
            'title': 'Shot Assessment - John Smith',
            'type': 'Individual Shot',
            'date': '2 hours ago',
            'status': 'Completed',
            'accuracy': '78%',
            'icon': Icons.sports_hockey,
            'color': Colors.red,
          },
          {
            'title': 'Team Skating - Alpha Squad',
            'type': 'Team Skating',
            'date': '1 day ago',
            'status': 'In Progress',
            'completion': '85%',
            'icon': Icons.groups,
            'color': Colors.purple,
          },
          {
            'title': 'Skating Assessment - Sarah Johnson',
            'type': 'Individual Skating',
            'date': '3 days ago',
            'status': 'Completed',
            'score': '8.4/10',
            'icon': Icons.speed,
            'color': Colors.green,
          },
        ];

        if (recentAssessments.isEmpty) {
          return _buildEmptyRecentAssessments(context);
        }

        return Column(
          children: recentAssessments.map((assessment) => 
            _buildRecentAssessmentCard(context, assessment, deviceType)
          ).toList(),
        );
      },
    );
  }

  Widget _buildEmptyRecentAssessments(BuildContext context) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        children: [
          Icon(
            Icons.assessment_outlined,
            size: ResponsiveConfig.iconSize(context, 64),
            color: Colors.grey[400],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'No assessments yet',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Start your first assessment using the options above',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAssessmentCard(BuildContext context, Map<String, dynamic> assessment, DeviceType deviceType) {
    final color = assessment['color'] as MaterialColor;
    
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      child: ListTile(
        contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
        leading: Container(
          padding: ResponsiveConfig.paddingAll(context, 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          child: Icon(
            assessment['icon'] as IconData,
            size: ResponsiveConfig.iconSize(context, 24),
            color: color.shade600,
          ),
        ),
        title: ResponsiveText(
          assessment['title'] as String,
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[800],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              assessment['type'] as String,
              baseFontSize: 13,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            ResponsiveText(
              assessment['date'] as String,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[500]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: assessment['status'] == 'Completed' 
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
                borderRadius: ResponsiveConfig.borderRadius(context, 12),
              ),
              child: ResponsiveText(
                assessment['status'] as String,
                baseFontSize: 11,
                style: TextStyle(
                  color: assessment['status'] == 'Completed' 
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (assessment.containsKey('accuracy'))
              ResponsiveText(
                assessment['accuracy'] as String,
                baseFontSize: 12,
                style: TextStyle(
                  color: color.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (assessment.containsKey('score'))
              ResponsiveText(
                assessment['score'] as String,
                baseFontSize: 12,
                style: TextStyle(
                  color: color.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (assessment.containsKey('completion'))
              ResponsiveText(
                assessment['completion'] as String,
                baseFontSize: 12,
                style: TextStyle(
                  color: color.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        onTap: () => _viewAssessmentDetails(context, assessment),
      ),
    );
  }

  void _navigateToAssessment(BuildContext context, String route) {
    // For setup screens, we only need to check if players exist in the system
    // Player selection will be handled within the setup screen itself
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (appState.players.isEmpty) {
      _showNoPlayersDialog(context);
      return;
    }
    
    // Navigate directly to setup screen - no need to check for selected player
    Navigator.pushNamed(context, route);
  }

  void _showNoPlayersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.people_outline, color: Colors.orange),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText('No Players Available', baseFontSize: 18),
          ],
        ),
        content: ResponsiveText(
          'You need to add players to the system before setting up an assessment.',
          baseFontSize: 16,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText('Cancel', baseFontSize: 14),
          ),
          ResponsiveButton(
            text: 'Add Player',
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/players');
            },
            baseHeight: 40,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
          ),
        ],
      ),
    );
  }

  void _viewAssessmentDetails(BuildContext context, Map<String, dynamic> assessment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('Assessment Details', baseFontSize: 18),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              assessment['title'] as String,
              baseFontSize: 16,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText('Type: ${assessment['type']}', baseFontSize: 14),
            ResponsiveText('Date: ${assessment['date']}', baseFontSize: 14),
            ResponsiveText('Status: ${assessment['status']}', baseFontSize: 14),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: ResponsiveText('Close', baseFontSize: 14),
          ),
        ],
      ),
    );
  }
}