// lib/widgets/domain/assessment/team_shot/team_shot_recommendations_tab.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/training/recommended_drill_card.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// Displays the recommendations tab for team shot assessment results with responsive design
class TeamShotRecommendationsTab extends StatefulWidget {
  final String teamName;
  final Map<String, Map<String, dynamic>> playerResults; // Changed from ShotAssessmentResults to Map
  final Map<String, dynamic> teamAverages;
  
  const TeamShotRecommendationsTab({
    Key? key,
    required this.teamName,
    required this.playerResults,
    required this.teamAverages,
  }) : super(key: key);

  @override
  _TeamShotRecommendationsTabState createState() => _TeamShotRecommendationsTabState();
}

class _TeamShotRecommendationsTabState extends State<TeamShotRecommendationsTab> {
  // Backend integration like shot files
  bool _isLoadingRecommendations = false;
  Map<String, dynamic>? _backendRecommendations;
  String? _recommendationError;
  late ApiService _apiService;
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
    _loadBackendRecommendations();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Load backend recommendations like shot files
  Future<void> _loadBackendRecommendations() async {
    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      // For team recommendations, we need to aggregate from all players
      final List<int> playerIds = [];
      for (var result in widget.playerResults.values) {
        final playerId = result['playerId'] as int?;
        if (playerId != null) {
          playerIds.add(playerId);
        }
      }

      if (playerIds.isNotEmpty) {
        // Get team-wide recommendations
        final recommendations = await _apiService.getTeamRecommendations(
          playerIds: playerIds,
          teamName: widget.teamName,
          context: context,
        );

        setState(() {
          _backendRecommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      } else {
        throw Exception('No valid player IDs found for team recommendations');
      }
    } catch (e) {
      print('Error loading backend team recommendations: $e');
      setState(() {
        _recommendationError = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.playerResults.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Recommendations Available',
        description: 'There are no assessment results to generate recommendations from.',
        icon: Icons.lightbulb_outline,
        iconColor: Colors.amber,
      );
    }
    
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout();
          case DeviceType.desktop:
            return _buildDesktopLayout();
        }
      },
    );
  }

  // Mobile Layout: Single column scrollable
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Backend recommendations section
          if (_backendRecommendations != null)
            _buildBackendRecommendations()
          else if (_isLoadingRecommendations)
            _buildLoadingState()
          else if (_recommendationError != null)
            _buildErrorState()
          else
            _buildFallbackRecommendations(),

          ResponsiveSpacing(multiplier: 3),

          // Coach notes section
          _buildCoachNotesCard(),
        ],
      ),
    );
  }

  // Tablet Layout: Two-column (Main Content | Quick Actions)
  Widget _buildTabletLayout() {
    return Padding(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content (70%)
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_backendRecommendations != null)
                    _buildBackendRecommendations()
                  else if (_isLoadingRecommendations)
                    _buildLoadingState()
                  else if (_recommendationError != null)
                    _buildErrorState()
                  else
                    _buildFallbackRecommendations(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Side panel (30%)
          Container(
            width: 280,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCoachNotesCard(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildTabletQuickActions(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop Layout: Three-section with enhanced sidebar
  Widget _buildDesktopLayout() {
    return Padding(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Sidebar: Quick overview (20%)
          Container(
            width: 250,
            child: SingleChildScrollView(
              child: _buildDesktopOverviewSidebar(),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Main content (60%)
          Expanded(
            flex: 6,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  if (_backendRecommendations != null)
                    _buildBackendRecommendations()
                  else if (_isLoadingRecommendations)
                    _buildLoadingState()
                  else if (_recommendationError != null)
                    _buildErrorState()
                  else
                    _buildFallbackRecommendations(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Right Sidebar: Actions & notes (20%)
          Container(
            width: 280,
            child: SingleChildScrollView(
              child: _buildDesktopActionsSidebar(),
            ),
          ),
        ],
      ),
    );
  }

  // Desktop overview sidebar
  Widget _buildDesktopOverviewSidebar() {
    return Column(
      children: [
        _buildTeamOverviewCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildPriorityAreasQuickView(),
        ResponsiveSpacing(multiplier: 2),
        _buildRecommendationProgress(),
      ],
    );
  }

  Widget _buildTeamOverviewCard() {
    final overallScore = (widget.teamAverages['overallScore'] as num?)?.toDouble() ?? 
                         (widget.teamAverages['overall_success_rate'] as num?)?.toDouble() ?? 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.blue[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Overview',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveText(
            widget.teamName,
            baseFontSize: 18,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Overall Score',
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AssessmentShotUtils.getScoreColor(overallScore).withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: ResponsiveText(
                  '${overallScore.toStringAsFixed(1)}/10',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssessmentShotUtils.getScoreColor(overallScore),
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Players',
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveText(
                '${widget.playerResults.length}',
                baseFontSize: 14,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityAreasQuickView() {
    // Find the lowest scoring categories for quick view
    final Map<String, double> categories = Map.from(widget.teamAverages);
    categories.remove('overallScore');
    
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final topIssues = sortedCategories.take(3).toList();
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.priority_high, color: Colors.red[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Priority Areas',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ...topIssues.map((entry) {
            final score = entry.value;
            return Container(
              margin: ResponsiveConfig.paddingOnly(context, bottom: 8),
              padding: ResponsiveConfig.paddingAll(context, 8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: ResponsiveConfig.borderRadius(context, 6),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ResponsiveText(
                      entry.key,
                      baseFontSize: 12,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  ResponsiveText(
                    '${score.toStringAsFixed(1)}',
                    baseFontSize: 12,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AssessmentShotUtils.getScoreColor(score),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationProgress() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.green[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Progress Tracking',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveText(
            'Recommendation Status',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          
          LinearProgressIndicator(
            value: _backendRecommendations != null ? 1.0 : 0.3,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _backendRecommendations != null ? Colors.green[600]! : Colors.orange[600]!,
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveText(
            _backendRecommendations != null 
              ? 'AI recommendations loaded'
              : _isLoadingRecommendations 
                ? 'Loading AI insights...'
                : 'Using basic recommendations',
            baseFontSize: 10,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  // Desktop actions sidebar
  Widget _buildDesktopActionsSidebar() {
    return Column(
      children: [
        _buildCoachNotesCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildDesktopQuickActions(),
        ResponsiveSpacing(multiplier: 2),
        _buildExportOptionsCard(),
      ],
    );
  }

  Widget _buildDesktopQuickActions() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.refresh, color: Colors.blue[600]),
            title: ResponsiveText('Refresh Recommendations', baseFontSize: 14),
            subtitle: ResponsiveText('Get latest AI insights', baseFontSize: 12),
            onTap: _loadBackendRecommendations,
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.print, color: Colors.green[600]),
            title: ResponsiveText('Print Recommendations', baseFontSize: 14),
            subtitle: ResponsiveText('Coach reference sheet', baseFontSize: 12),
            onTap: _printRecommendations,
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.share, color: Colors.orange[600]),
            title: ResponsiveText('Share with Team', baseFontSize: 14),
            subtitle: ResponsiveText('Send to players', baseFontSize: 12),
            onTap: _shareWithTeam,
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.schedule, color: Colors.purple[600]),
            title: ResponsiveText('Schedule Follow-up', baseFontSize: 14),
            subtitle: ResponsiveText('Track progress', baseFontSize: 12),
            onTap: _scheduleFollowUp,
          ),
        ],
      ),
    );
  }

  Widget _buildExportOptionsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Export Options',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveButton(
            text: 'Export PDF',
            onPressed: _exportToPDF,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.picture_as_pdf, size: 16),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveButton(
            text: 'Export Excel',
            onPressed: _exportToExcel,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.table_chart, size: 16),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveButton(
            text: 'Training Plan',
            onPressed: _createTrainingPlan,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.fitness_center, size: 16),
          ),
        ],
      ),
    );
  }

  // Tablet quick actions
  Widget _buildTabletQuickActions() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Actions',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveButton(
            text: 'Refresh',
            onPressed: _loadBackendRecommendations,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.refresh, size: 16),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          ResponsiveButton(
            text: 'Export',
            onPressed: _exportToPDF,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.download, size: 16),
          ),
        ],
      ),
    );
  }

  // Loading state like shot files
  Widget _buildLoadingState() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Analyzing team performance data...',
              baseFontSize: 16,
              style: TextStyle(color: Colors.grey[600]),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Generating personalized team recommendations',
              baseFontSize: 14,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // Error state like shot files
  Widget _buildErrorState() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: ResponsiveConfig.iconSize(context, 48)),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Unable to Load Advanced Recommendations',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Showing basic team recommendations based on results',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Retry',
            onPressed: _loadBackendRecommendations,
            baseHeight: 48,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icon(Icons.refresh),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildFallbackRecommendations(),
        ],
      ),
    );
  }

  // Backend recommendations like shot files
  Widget _buildBackendRecommendations() {
    final recommendations = _backendRecommendations!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 24)),
            ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'AI-Powered Team Analysis & Recommendations',
                    baseFontSize: 18,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  ResponsiveText(
                    'Professional coaching insights based on team performance data',
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 2),

        // Team Priority Focus Areas
        if (recommendations['team_priority_areas'] != null)
          _buildTeamPriorityAreas(recommendations['team_priority_areas']),

        // Player-Specific Recommendations
        if (recommendations['player_specific'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildPlayerSpecificRecommendations(recommendations['player_specific']),
        ],

        // Team Training Drills
        if (recommendations['team_drills'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTeamTrainingDrills(recommendations['team_drills']),
        ],

        // Formation and Strategy
        if (recommendations['formation_strategy'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildFormationStrategy(recommendations['formation_strategy']),
        ],

        // Timeline Expectations
        if (recommendations['timeline_expectations'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTimelineExpectations(recommendations['timeline_expectations']),
        ],
      ],
    );
  }

  Widget _buildTeamPriorityAreas(List<dynamic> areas) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: Colors.red[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Priority Focus Areas',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive layout for priority areas
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Column(
                  children: areas.map((area) => Container(
                    margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
                    child: _buildTeamPriorityCard(area),
                  )).toList(),
                );
              } else if (deviceType == DeviceType.tablet) {
                return Wrap(
                  spacing: ResponsiveConfig.spacing(context, 12),
                  runSpacing: ResponsiveConfig.spacing(context, 12),
                  children: areas.map((area) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 100) / 2,
                    child: _buildTeamPriorityCard(area),
                  )).toList(),
                );
              } else {
                return Column(
                  children: areas.map((area) => _buildTeamPriorityCard(area)).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPriorityCard(Map<String, dynamic> area) {
    final priority = area['priority_level'] as String? ?? 'Medium';
    final affectedPlayers = (area['affected_players'] as List?)?.cast<String>() ?? [];
    
    final priorityColor = _getPriorityColor(priority);
    
    return Container(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        color: priorityColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  area['area'] as String? ?? 'Focus Area',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: ResponsiveText(
                  priority.toUpperCase(),
                  baseFontSize: 10,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            area['description'] as String? ?? '',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (affectedPlayers.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Affected Players: ${affectedPlayers.join(', ')}',
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlayerSpecificRecommendations(Map<String, dynamic> playerRecs) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Player-Specific Recommendations',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive grid for player recommendations
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Column(
                  children: playerRecs.entries.map((entry) => Container(
                    margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
                    child: _buildPlayerCard(entry.key, entry.value),
                  )).toList(),
                );
              } else if (deviceType == DeviceType.tablet) {
                return Wrap(
                  spacing: ResponsiveConfig.spacing(context, 12),
                  runSpacing: ResponsiveConfig.spacing(context, 12),
                  children: playerRecs.entries.map((entry) => SizedBox(
                    width: (MediaQuery.of(context).size.width - 100) / 2,
                    child: _buildPlayerCard(entry.key, entry.value),
                  )).toList(),
                );
              } else {
                return Column(
                  children: playerRecs.entries.map((entry) => _buildPlayerCard(entry.key, entry.value)).toList(),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(String playerName, Map<String, dynamic> rec) {
    final improvements = (rec['improvements'] as List?)?.cast<String>() ?? [];
    
    return Container(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            playerName,
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            rec['focus_area'] as String? ?? '',
            baseFontSize: 13,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          if (improvements.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ...improvements.map((improvement) => Padding(
              padding: ResponsiveConfig.paddingOnly(context, bottom: 2),
              child: ResponsiveText(
                '• $improvement',
                baseFontSize: 12,
                style: TextStyle(color: Colors.grey[700]),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamTrainingDrills(List<dynamic> drills) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.purple[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Recommended Team Training Drills',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Use RecommendedDrillCard like shot files - responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              return Column(
                children: drills.map((drill) => Container(
                  margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
                  child: RecommendedDrillCard(
                    name: drill['name'] as String? ?? 'Team Training Drill',
                    description: drill['description'] as String? ?? '',
                    repetitions: drill['repetitions'] as String? ?? 'As needed',
                    frequency: drill['frequency'] as String? ?? 'Regular',
                    keyPoints: (drill['key_points'] as List?)?.cast<String>() ?? [],
                  ),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFormationStrategy(Map<String, dynamic> strategy) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_hockey, color: Colors.teal[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Formation & Strategy Recommendations',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive strategy sections
          if (strategy['power_play'] != null)
            _buildStrategySection('Power Play', strategy['power_play'], Icons.flash_on),
          if (strategy['penalty_kill'] != null)
            _buildStrategySection('Penalty Kill', strategy['penalty_kill'], Icons.shield),
          if (strategy['even_strength'] != null)
            _buildStrategySection('Even Strength', strategy['even_strength'], Icons.balance),
        ],
      ),
    );
  }

  Widget _buildStrategySection(String title, Map<String, dynamic> section, IconData icon) {
    return Container(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        color: Colors.teal[50],
        border: Border.all(color: Colors.teal[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal[700], size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                title,
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            section['recommendation'] as String? ?? '',
            baseFontSize: 13,
            style: TextStyle(color: Colors.teal[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineExpectations(Map<String, dynamic> timeline) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline, color: Colors.green[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Development Timeline',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive timeline phases
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Column(
                  children: [
                    _buildTimelinePhase('Immediate (1-2 weeks)', timeline['immediate_improvements'], Colors.red[600]!),
                    ResponsiveSpacing(multiplier: 1.5),
                    _buildTimelinePhase('Short Term (4-8 weeks)', timeline['short_term_goals'], Colors.orange[600]!),
                    ResponsiveSpacing(multiplier: 1.5),
                    _buildTimelinePhase('Long Term (3-8 months)', timeline['long_term_development'], Colors.green[600]!),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildTimelinePhase('Immediate (1-2 weeks)', timeline['immediate_improvements'], Colors.red[600]!)),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(child: _buildTimelinePhase('Short Term (4-8 weeks)', timeline['short_term_goals'], Colors.orange[600]!)),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    Expanded(child: _buildTimelinePhase('Long Term (3-8 months)', timeline['long_term_development'], Colors.green[600]!)),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(String title, Map<String, dynamic>? phase, Color color) {
    if (phase == null) return SizedBox.shrink();
    
    final changes = (phase['expected_changes'] as List?)?.cast<String>() ?? [];
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            baseFontSize: 13,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            phase['timeframe'] as String? ?? '',
            baseFontSize: 11,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (changes.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ...changes.take(3).map((change) => Padding(
              padding: ResponsiveConfig.paddingOnly(context, bottom: 2),
              child: ResponsiveText(
                '• $change',
                baseFontSize: 10,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  // Fallback recommendations like shot files but for teams
  Widget _buildFallbackRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team overview
        _buildOverviewCard(),
        ResponsiveSpacing(multiplier: 3),
        
        // Area recommendations
        _buildSectionTitle('Focus Areas'),
        ResponsiveSpacing(multiplier: 2),
        _buildFocusAreas(),
        ResponsiveSpacing(multiplier: 3),
        
        // Individual recommendations
        _buildSectionTitle('Player-Specific Recommendations'),
        ResponsiveSpacing(multiplier: 2),
        _buildPlayerRecommendations(),
        ResponsiveSpacing(multiplier: 3),
        
        // Practice recommendations
        _buildSectionTitle('Recommended Practice Drills'),
        ResponsiveSpacing(multiplier: 2),
        _buildPracticeDrills(),
      ],
    );
  }

  Widget _buildCoachNotesCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Coach Notes',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Add notes about team performance and recommendations...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return ResponsiveText(
      title,
      baseFontSize: 18,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.blueGrey[800],
      ),
    );
  }
  
  Widget _buildOverviewCard() {
    final overallScore = (widget.teamAverages['overallScore'] as num?)?.toDouble() ?? 
                         (widget.teamAverages['overall_success_rate'] as num?)?.toDouble() ?? 0.0;
    final performanceLevel = _getTeamPerformanceLevel(overallScore);
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Team Overview',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AssessmentShotUtils.getScoreColor(overallScore).withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 16),
                ),
                child: ResponsiveText(
                  '${overallScore.toStringAsFixed(1)}/10',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssessmentShotUtils.getScoreColor(overallScore),
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Overall Performance Level: $performanceLevel',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[600],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            _getOverallRecommendation(overallScore),
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFocusAreas() {
    // Find the lowest scoring categories
    final Map<String, double> categories = Map.from(widget.teamAverages);
    categories.remove('overallScore');
    
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Take the lowest 2 categories
    final focusAreas = sortedCategories.take(2).toList();
    
    return Column(
      children: focusAreas.map((entry) {
        final category = entry.key;
        final score = entry.value;
        final recommendation = _getCategoryRecommendation(category, score);
        
        return ResponsiveCard(
          margin: ResponsiveConfig.paddingOnly(context, bottom: 16),
          padding: ResponsiveConfig.paddingAll(context, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: AssessmentShotUtils.getScoreColor(score),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      ResponsiveText(
                        category,
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AssessmentShotUtils.getScoreColor(score).withOpacity(0.2),
                      borderRadius: ResponsiveConfig.borderRadius(context, 16),
                    ),
                    child: ResponsiveText(
                      '${score.toStringAsFixed(1)}/10',
                      baseFontSize: 14,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AssessmentShotUtils.getScoreColor(score),
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                recommendation,
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildPlayerRecommendations() {
    // Sort players by overall score (ascending)
    final sortedPlayers = widget.playerResults.entries.toList()
      ..sort((a, b) => 
        (a.value['overallScore'] as num? ?? 0.0).compareTo(b.value['overallScore'] as num? ?? 0.0)
      );
    
    // Take the lowest 3 players
    final focusPlayers = sortedPlayers.take(3).toList();
    
    return Column(
      children: focusPlayers.map((entry) {
        final results = entry.value;
        final playerName = results['playerName'] as String? ?? 'Unknown Player';
        final score = results['overallScore'] as double? ?? 0.0;
        
        // Find lowest category
        String lowestCategory = '';
        double lowestScore = 10.0;
        
        final categoryScores = results['categoryScores'] as Map<String, dynamic>?;
        if (categoryScores != null) {
          for (final categoryEntry in categoryScores.entries) {
            if (categoryEntry.key != 'Overall' && 
                (lowestCategory.isEmpty || categoryEntry.value < lowestScore)) {
              lowestCategory = categoryEntry.key;
              lowestScore = categoryEntry.value as double? ?? 0.0;
            }
          }
        }
        
        return ResponsiveCard(
          margin: ResponsiveConfig.paddingOnly(context, bottom: 16),
          padding: ResponsiveConfig.paddingAll(context, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ResponsiveText(
                    playerName,
                    baseFontSize: 16,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AssessmentShotUtils.getScoreColor(score).withOpacity(0.2),
                      borderRadius: ResponsiveConfig.borderRadius(context, 16),
                    ),
                    child: ResponsiveText(
                      '${score.toStringAsFixed(1)}/10',
                      baseFontSize: 14,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AssessmentShotUtils.getScoreColor(score),
                      ),
                    ),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'Focus Area: $lowestCategory (${lowestScore.toStringAsFixed(1)}/10)',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[600],
                ),
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                _getPlayerRecommendation(playerName, lowestCategory, lowestScore),
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildPracticeDrills() {
    // Generate drills based on team's weakest areas
    final Map<String, double> categories = Map.from(widget.teamAverages);
    categories.remove('overallScore');
    
    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Take the lowest 2 categories for drill recommendations
    final focusAreas = sortedCategories.take(2).map((e) => e.key).toList();
    
    final drills = _getDrillsForCategories(focusAreas);
    
    return Column(
      children: drills.map((drill) => _buildDrillCard(drill)).toList(),
    );
  }
  
  Widget _buildDrillCard(Map<String, String> drill) {
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 16),
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveConfig.dimension(context, 40),
                height: ResponsiveConfig.dimension(context, 40),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                ),
                child: Center(
                  child: Icon(
                    Icons.sports_hockey,
                    color: Colors.orange[700],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  drill['name']!,
                  baseFontSize: 16,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: ResponsiveConfig.borderRadius(context, 16),
                ),
                child: ResponsiveText(
                  drill['duration']!,
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blue[700]),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            drill['objective']!,
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            drill['description']!,
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Setup: ${drill['setup']!}',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  // Helper methods (same as original, no changes needed)
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red[700]!;
      case 'high': return Colors.orange[700]!;
      case 'medium':
      case 'moderate': return Colors.yellow[700]!;
      default: return Colors.green[700]!;
    }
  }
  
  String _getTeamPerformanceLevel(double score) {
    if (score >= 8.5) return 'Elite';
    if (score >= 7.5) return 'Excellent';
    if (score >= 6.5) return 'Good';
    if (score >= 5.5) return 'Average';
    if (score >= 4.5) return 'Fair';
    if (score >= 3.5) return 'Needs Improvement';
    return 'Developing';
  }
  
  String _getOverallRecommendation(double score) {
    if (score >= 8.5) {
      return 'The team demonstrates elite shooting performance. Focus on maintaining this high level through consistent practice and introducing advanced techniques to further refine skills.';
    } else if (score >= 7.5) {
      return 'The team shows excellent shooting capability. Continue developing consistency across all players and introduce more situational shooting practice to handle game scenarios.';
    } else if (score >= 6.5) {
      return 'The team has good shooting fundamentals. Work on enhancing technique and accuracy while introducing more challenging shooting drills to elevate performance.';
    } else if (score >= 5.5) {
      return 'The team shows average shooting performance. Focus on improving technique and accuracy through consistent practice and individual skill development.';
    } else if (score >= 4.5) {
      return 'The team needs improvement in shooting fundamentals. Prioritize basic shooting technique, stance, and grip to build a solid foundation.';
    } else {
      return 'The team requires significant development in shooting skills. Focus on establishing proper fundamentals through structured practice sessions and individual coaching.';
    }
  }
  
  String _getCategoryRecommendation(String category, double score) {
    switch (category) {
      case 'Accuracy':
        if (score < 5.0) {
          return 'Team accuracy needs fundamental improvement. Implement target-specific drills, emphasize proper stick handling, and focus on consistent shooting form. Dedicate 15-20 minutes of each practice to shooting accuracy drills.';
        } else if (score < 7.0) {
          return 'Team shows moderate accuracy. Work on enhancing precision through varied target drills, shooting under pressure, and shooting while in motion. Have players track their accuracy rates to promote improvement.';
        } else {
          return 'Team demonstrates good accuracy. Refine skills with advanced drills that combine movement, quick release, and target precision. Consider adding defensive pressure to simulate game conditions.';
        }
        
      case 'Technique':
        if (score < 5.0) {
          return 'Team shooting technique needs significant improvement. Focus on proper stance, weight transfer, and follow-through. Consider individual technique sessions and video analysis to identify specific areas for improvement.';
        } else if (score < 7.0) {
          return 'Team has adequate shooting technique but requires refinement. Work on consistent execution, proper wrist action, and follow-through. Incorporate technique drills that build muscle memory through repetition.';
        } else {
          return 'Team shows strong technical foundation. Focus on maintaining proper technique under pressure and at game speed. Incorporate advanced shooting mechanics and situational shooting scenarios.';
        }
        
      case 'Power':
        if (score < 5.0) {
          return 'Team shooting power needs development. Implement strength training focused on core, arms, and wrists. Practice proper weight transfer and follow-through to generate more power in shots.';
        } else if (score < 7.0) {
          return 'Team demonstrates moderate shooting power. Enhance power through specific exercises targeting shot mechanics and follow-through. Work on generating power from different shooting positions and stances.';
        } else {
          return 'Team shows good shooting power. Focus on maintaining power while improving accuracy and quickness. Introduce drills that combine power with precision under game-like conditions.';
        }
        
      case 'Consistency':
        if (score < 5.0) {
          return 'Team shooting consistency needs significant improvement. Implement structured repetition drills with gradual progression in difficulty. Track performance to identify and address patterns of inconsistency.';
        } else if (score < 7.0) {
          return 'Team shows moderate consistency. Work on maintaining technique and accuracy across different game scenarios. Introduce varied drills that require consistent execution under changing conditions.';
        } else {
          return 'Team demonstrates good consistency. Focus on maintaining performance levels even under fatigue and pressure. Implement competitive drills that test mental focus and technical execution.';
        }
        
      default:
        return 'Focus on improving overall shooting performance through targeted practice and individual skill development.';
    }
  }
  
  String _getPlayerRecommendation(String playerName, String category, double score) {
    final String baseRecommendation = 'For $playerName, focus on improving $category (${score.toStringAsFixed(1)}/10). ';
    
    switch (category.toLowerCase()) {
      case 'accuracy':
        if (score < 5.0) {
          return baseRecommendation + 'Implement daily target practice with gradual difficulty progression. Work on proper stance and aim techniques, focusing on consistency of shot placement.';
        } else if (score < 7.0) {
          return baseRecommendation + 'Practice varied target drills with increased distance and smaller targets. Work on maintaining accuracy while adding movement and speed to shooting exercises.';
        } else {
          return baseRecommendation + 'Focus on precision shooting from different angles and positions. Add defensive pressure during practice to simulate game conditions while maintaining accuracy.';
        }
        
      case 'technique':
        if (score < 5.0) {
          return baseRecommendation + 'Work on fundamentals of shooting technique including stance, grip, and proper weight transfer. Consider video analysis to identify specific technical issues to address.';
        } else if (score < 7.0) {
          return baseRecommendation + 'Refine shooting mechanics focusing on follow-through and stick positioning. Practice technique drills that build muscle memory through controlled repetition.';
        } else {
          return baseRecommendation + 'Focus on maintaining proper technique at game speed and under pressure. Work on quick transitions between skating and shooting while maintaining form.';
        }
        
      case 'power':
        if (score < 5.0) {
          return baseRecommendation + 'Implement specific strength training for wrists, arms, and core. Practice weight transfer and follow-through techniques to generate more power in shots.';
        } else if (score < 7.0) {
          return baseRecommendation + 'Work on generating power from different shooting positions and stances. Focus on proper body mechanics to maximize force transfer to the puck.';
        } else {
          return baseRecommendation + 'Refine power shooting techniques while maintaining accuracy. Practice powerful shots under game-like conditions with defenders present.';
        }
        
      case 'consistency':
        if (score < 5.0) {
          return baseRecommendation + 'Focus on repetitive shooting drills to build muscle memory. Track shot outcomes to identify patterns and areas for improvement in consistency.';
        } else if (score < 7.0) {
          return baseRecommendation + 'Practice maintaining shooting form and accuracy across different scenarios and levels of fatigue. Implement progressive drills that increase in difficulty.';
        } else {
          return baseRecommendation + 'Work on mental focus during shooting drills, particularly under pressure and fatigue. Introduce competitive elements to test consistency in challenging situations.';
        }
        
      default:
        return baseRecommendation + 'Work with coaches on developing a personalized improvement plan targeting specific shooting skills.';
    }
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Accuracy':
        return Icons.gps_fixed;
      case 'Technique':
        return Icons.sports_hockey;
      case 'Power':
        return Icons.flash_on;
      case 'Consistency':
        return Icons.repeat;
      default:
        return Icons.analytics;
    }
  }
  
  List<Map<String, String>> _getDrillsForCategories(List<String> categories) {
    final Map<String, List<Map<String, String>>> categoryDrills = {
      'Accuracy': [
        {
          'name': 'Team Corner Target Challenge',
          'duration': '20 mins',
          'objective': 'Improve team shooting accuracy to specific net zones',
          'description': 'Players rotate through stations shooting at targets placed in each corner of the net, with team competition elements.',
          'setup': 'Place targets in all four corners of the net. Set up 4 stations with players rotating every 5 minutes.'
        },
        {
          'name': 'Team Precision Passing and Shooting',
          'duration': '25 mins',
          'objective': 'Enhance team accuracy through coordinated passing and shooting',
          'description': 'Players work in groups of 3-4, making precise passes before taking shots at specific targets in the net.',
          'setup': 'Set up multiple passing lanes and marked shooting positions with targets. Groups rotate stations.'
        },
      ],
      'Technique': [
        {
          'name': 'Team Form Focus Shooting',
          'duration': '25 mins',
          'objective': 'Develop proper shooting technique across the team',
          'description': 'Team-wide shooting drill with emphasis on stance, weight transfer, and follow-through. Peer coaching encouraged.',
          'setup': 'Set up multiple shooting stations with mirrors when possible. Assign shooting partners for feedback.'
        },
        {
          'name': 'Team Technical Progression Series',
          'duration': '30 mins',
          'objective': 'Build team shooting technique through progressive difficulty',
          'description': 'Team works through coordinated shooting drills that progress in technical difficulty, with group feedback.',
          'setup': 'Create 5-6 stations with different technical focus areas. Teams of 3-4 players spend 5 minutes at each station.'
        },
      ],
      'Power': [
        {
          'name': 'Team Power Shot Development',
          'duration': '20 mins',
          'objective': 'Increase shooting power across the team',
          'description': 'Team-focused drill for generating maximum power in shots through proper weight transfer and follow-through.',
          'setup': 'Multiple shooting lanes with power measurement if available. Teams compete for highest power readings.'
        },
        {
          'name': 'Team Dynamic Power Shooting',
          'duration': '25 mins',
          'objective': 'Develop team shooting power while in motion',
          'description': 'Team practices powerful shots while skating in formation, focusing on maintaining balance and generating force.',
          'setup': 'Create multiple courses where teams skate through patterns before taking power shots from designated areas.'
        },
      ],
      'Consistency': [
        {
          'name': 'Team Repetition Challenge',
          'duration': '25 mins',
          'objective': 'Build team consistency through high-volume repetition',
          'description': 'Team takes high volume of shots from the same positions, focusing on consistent technique and team success rates.',
          'setup': 'Multiple shooting areas with team tracking of success rates. Set team goals for improvement.'
        },
        {
          'name': 'Team Fatigue Resistance Shooting',
          'duration': '30 mins',
          'objective': 'Maintain team shooting consistency while fatigued',
          'description': 'Team performs conditioning exercises between shooting sequences to simulate game fatigue conditions.',
          'setup': 'Alternate between team conditioning intervals and coordinated shooting sequences of 5-10 shots per player.'
        },
      ],
    };
    
    final drills = <Map<String, String>>[];
    
    // Add two drills for each focus category
    for (final category in categories) {
      if (categoryDrills.containsKey(category)) {
        drills.addAll(categoryDrills[category]!);
      }
    }
    
    // If we don't have enough drills, add from other categories
    if (drills.length < 3) {
      for (final category in categoryDrills.keys) {
        if (!categories.contains(category)) {
          drills.add(categoryDrills[category]![0]);
          if (drills.length >= 3) break;
        }
      }
    }
    
    return drills;
  }

  // Desktop-only action methods
  void _printRecommendations() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print recommendations - Coming Soon')),
    );
  }

  void _shareWithTeam() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share with team - Coming Soon')),
    );
  }

  void _scheduleFollowUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule follow-up - Coming Soon')),
    );
  }

  void _exportToPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to PDF - Coming Soon')),
    );
  }

  void _exportToExcel() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export to Excel - Coming Soon')),
    );
  }

  void _createTrainingPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create training plan - Coming Soon')),
    );
  }
}