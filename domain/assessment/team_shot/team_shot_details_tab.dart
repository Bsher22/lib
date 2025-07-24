// lib/widgets/domain/assessment/team_shot/team_shot_details_tab.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/zone_heatmap_widget.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamShotDetailsTab extends StatefulWidget {
  final Map<String, dynamic> assessment; // Changed from ShotAssessment to Map
  final List<Player> players;
  final Map<String, Map<String, dynamic>> playerResults; // Changed from ShotAssessmentResults to Map

  const TeamShotDetailsTab({
    Key? key,
    required this.assessment,
    required this.players,
    required this.playerResults,
  }) : super(key: key);

  @override
  _TeamShotDetailsTabState createState() => _TeamShotDetailsTabState();
}

class _TeamShotDetailsTabState extends State<TeamShotDetailsTab> {
  List<String> _selectedPositions = [];
  List<String> _selectedGroups = [];
  List<String> _selectedTypes = [];
  String? _selectedPlayerId;

  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }

  void _initializeFilters() {
    if (widget.players.isNotEmpty) {
      _selectedPlayerId = widget.players[0].id?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
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

  // Mobile Layout: Single column with collapsible filters
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileFilters(),
          ResponsiveSpacing(multiplier: 2),
          if (_selectedPlayerId != null) _buildPlayerPerformanceCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildShotBreakdownCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildZoneHeatmapCard(),
        ],
      ),
    );
  }

  // Tablet Layout: Two-column (Filters | Content)
  Widget _buildTabletLayout() {
    return Padding(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Filters (30%)
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTabletFilters(),
                  ResponsiveSpacing(multiplier: 2),
                  if (_selectedPlayerId != null) _buildPlayerPerformanceCard(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Right Column: Analysis (70%)
          Expanded(
            flex: 7,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildShotBreakdownCard(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildZoneHeatmapCard(),
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
          // Left Sidebar: Filters & Player Info (25%)
          Container(
            width: 300,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildDesktopFilters(),
                  ResponsiveSpacing(multiplier: 2),
                  if (_selectedPlayerId != null) _buildPlayerPerformanceCard(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildDesktopPlayerQuickActions(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Main Content: Analysis (55%)
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildShotBreakdownCard(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildZoneHeatmapCard(),
                ],
              ),
            ),
          ),
          
          ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
          
          // Right Sidebar: Enhanced Analytics (20%)
          Container(
            width: 280,
            child: SingleChildScrollView(
              child: _buildDesktopAnalyticsSidebar(),
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Filters: Compact expandable design
  Widget _buildMobileFilters() {
    return ResponsiveCard(
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.filter_list, color: Colors.blueGrey[700]),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText(
              'Filters & Player Selection',
              baseFontSize: 16,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              children: [
                _buildPlayerSelector(),
                ResponsiveSpacing(multiplier: 2),
                _buildPositionFilter(),
                ResponsiveSpacing(multiplier: 2),
                _buildGroupFilter(),
                ResponsiveSpacing(multiplier: 2),
                _buildShotTypeFilter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Tablet Filters: Structured vertical layout
  Widget _buildTabletFilters() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Analysis Filters',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2.5),
          _buildPlayerSelector(),
          ResponsiveSpacing(multiplier: 2.5),
          _buildPositionFilter(),
          ResponsiveSpacing(multiplier: 2.5),
          _buildGroupFilter(),
          ResponsiveSpacing(multiplier: 2.5),
          _buildShotTypeFilter(),
        ],
      ),
    );
  }

  // Desktop Filters: Professional layout with enhanced controls
  Widget _buildDesktopFilters() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blue[700]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              ResponsiveText(
                'Performance Analysis',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          
          _buildPlayerSelector(),
          ResponsiveSpacing(multiplier: 2.5),
          
          Divider(color: Colors.grey[300]),
          ResponsiveSpacing(multiplier: 2),
          
          ResponsiveText(
            'Filter Options',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildPositionFilter(),
          ResponsiveSpacing(multiplier: 2),
          _buildGroupFilter(),
          ResponsiveSpacing(multiplier: 2),
          _buildShotTypeFilter(),
          
          ResponsiveSpacing(multiplier: 2.5),
          
          // Desktop-only: Advanced filter controls
          Row(
            children: [
              Expanded(
                child: ResponsiveButton(
                  text: 'Clear All',
                  onPressed: _clearFilters,
                  baseHeight: 48,
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.clear, size: 16),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Desktop-only: Player quick actions
  Widget _buildDesktopPlayerQuickActions() {
    if (_selectedPlayerId == null) return const SizedBox.shrink();
    
    final player = widget.players.firstWhere(
      (p) => p.id?.toString() == _selectedPlayerId,
      orElse: () => Player(
        id: int.tryParse(_selectedPlayerId!),
        name: 'Unknown',
        position: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

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
            leading: Icon(Icons.compare_arrows, color: Colors.blue[600]),
            title: ResponsiveText('Compare Performance', baseFontSize: 14),
            subtitle: ResponsiveText('vs other players', baseFontSize: 12),
            onTap: () => _comparePlayerPerformance(player),
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.trending_up, color: Colors.green[600]),
            title: ResponsiveText('View Progress', baseFontSize: 14),
            subtitle: ResponsiveText('Historical data', baseFontSize: 12),
            onTap: () => _viewPlayerProgress(player),
          ),
          
          ListTile(
            dense: true,
            leading: Icon(Icons.note_add, color: Colors.orange[600]),
            title: ResponsiveText('Add Note', baseFontSize: 14),
            subtitle: ResponsiveText('Coach observations', baseFontSize: 12),
            onTap: () => _addPlayerNote(player),
          ),
        ],
      ),
    );
  }

  // Desktop-only: Enhanced analytics sidebar
  Widget _buildDesktopAnalyticsSidebar() {
    return Column(
      children: [
        _buildStatsSummaryCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildTrendsCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildComparisonCard(),
      ],
    );
  }

  Widget _buildStatsSummaryCard() {
    if (_selectedPlayerId == null || !widget.playerResults.containsKey(_selectedPlayerId)) {
      return const SizedBox.shrink();
    }

    final results = widget.playerResults[_selectedPlayerId!]!;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
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
          ResponsiveSpacing(multiplier: 1.5),
          
          _buildQuickStat(
            'Overall Score',
            '${(results['overallScore'] as double? ?? 0.0).toStringAsFixed(1)}/10',
            AssessmentShotUtils.getScoreColor(results['overallScore'] as double? ?? 0.0),
          ),
          
          _buildQuickStat(
            'Success Rate',
            '${((results['overallRate'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%',
            Colors.blue[600]!,
          ),
          
          _buildQuickStat(
            'Total Shots',
            '${results['totalShots'] as int? ?? 0}',
            Colors.green[600]!,
          ),
          
          _buildQuickStat(
            'Best Zone',
            _getBestZone(results),
            Colors.orange[600]!,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, Color color) {
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, bottom: 8),
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
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Performance Trends',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          // Placeholder for trend visualization
          Container(
            height: ResponsiveConfig.dimension(context, 100),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.trending_up, color: Colors.grey[400], size: ResponsiveConfig.iconSize(context, 32)),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    'Trend Analysis',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  ResponsiveText(
                    'Coming Soon',
                    baseFontSize: 10,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Team Comparison',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          
          ResponsiveText(
            'Selected Player vs Team Average',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1),
          
          // Show comparison if player is selected
          if (_selectedPlayerId != null && widget.playerResults.containsKey(_selectedPlayerId))
            _buildPerformanceComparison()
          else
            Container(
              padding: ResponsiveConfig.paddingAll(context, 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              child: ResponsiveText(
                'Select a player to see comparison',
                baseFontSize: 12,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceComparison() {
    final playerResults = widget.playerResults[_selectedPlayerId!]!;
    final playerScore = playerResults['overallScore'] as double? ?? 0.0;
    
    // Calculate team average
    double teamAverage = 0.0;
    if (widget.playerResults.isNotEmpty) {
      final totalScore = widget.playerResults.values.fold<double>(
        0.0, 
        (sum, result) => sum + (result['overallScore'] as double? ?? 0.0)
      );
      teamAverage = totalScore / widget.playerResults.length;
    }
    
    final difference = playerScore - teamAverage;
    final isAboveAverage = difference > 0;
    
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              'Player Score',
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            ResponsiveText(
              playerScore.toStringAsFixed(1),
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AssessmentShotUtils.getScoreColor(playerScore),
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 0.5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ResponsiveText(
              'Team Average',
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            ResponsiveText(
              teamAverage.toStringAsFixed(1),
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1),
        Container(
          padding: ResponsiveConfig.paddingAll(context, 8),
          decoration: BoxDecoration(
            color: isAboveAverage ? Colors.green[50] : Colors.orange[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 6),
            border: Border.all(
              color: isAboveAverage ? Colors.green[200]! : Colors.orange[200]!,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isAboveAverage ? Icons.trending_up : Icons.trending_down,
                color: isAboveAverage ? Colors.green[600] : Colors.orange[600],
                size: ResponsiveConfig.iconSize(context, 16),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  '${isAboveAverage ? '+' : ''}${difference.toStringAsFixed(1)} vs team',
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAboveAverage ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Responsive Shot Breakdown Card
  Widget _buildShotBreakdownCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Shot Breakdown',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildShotBreakdownTable(),
        ],
      ),
    );
  }

  // Responsive Zone Heatmap Card
  Widget _buildZoneHeatmapCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.grid_on, color: Colors.blueGrey[700]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Zone Performance Heatmap',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildZoneHeatmap(),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Player',
          baseFontSize: 14,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlayerId,
              isExpanded: true,
              hint: ResponsiveText('Select Player', baseFontSize: 14),
              items: widget.players.map((player) {
                return DropdownMenuItem<String>(
                  value: player.id?.toString(),
                  child: ResponsiveText('${player.name} (${player.jerseyNumber?.toString() ?? "No #"})', baseFontSize: 14),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlayerId = value;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPositionFilter() {
    final positions = widget.players
        .map((p) => p.position)
        .where((position) => position != null)
        .cast<String>()
        .toSet()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Filter by Position',
          baseFontSize: 14,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        Wrap(
          spacing: ResponsiveConfig.spacing(context, 8),
          children: positions.map((position) {
            final isSelected = _selectedPositions.contains(position);
            return FilterChip(
              label: ResponsiveText(position, baseFontSize: 12),
              selected: isSelected,
              selectedColor: Colors.cyanAccent,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPositions.add(position);
                  } else {
                    _selectedPositions.remove(position);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGroupFilter() {
    final groups = (widget.assessment['groups'] as List).map((g) => g['name'] as String? ?? g['title'] as String? ?? 'Group').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Filter by Shot Group',
          baseFontSize: 14,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        Wrap(
          spacing: ResponsiveConfig.spacing(context, 8),
          children: groups.map((group) {
            final isSelected = _selectedGroups.contains(group);
            return FilterChip(
              label: ResponsiveText(group, baseFontSize: 12),
              selected: isSelected,
              selectedColor: Colors.cyanAccent,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedGroups.add(group);
                  } else {
                    _selectedGroups.remove(group);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShotTypeFilter() {
    final Set<String> typesSet = {'Wrist', 'Snap', 'Slap', 'Backhand'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Filter by Shot Type',
          baseFontSize: 14,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),
        Wrap(
          spacing: ResponsiveConfig.spacing(context, 8),
          children: typesSet.map((type) {
            final isSelected = _selectedTypes.contains(type);
            return FilterChip(
              label: ResponsiveText(type, baseFontSize: 12),
              selected: isSelected,
              selectedColor: Colors.cyanAccent,
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTypes.add(type);
                  } else {
                    _selectedTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPlayerPerformanceCard() {
    if (_selectedPlayerId == null) {
      return EmptyStateDisplay(
        title: 'Select a Player',
        description: 'Please select a player to view detailed performance.',
        icon: Icons.person,
        iconColor: Colors.blueGrey[300],
      );
    }

    final playerId = _selectedPlayerId!;
    final player = widget.players.firstWhere(
      (p) => p.id?.toString() == playerId,
      orElse: () => Player(
        id: int.tryParse(playerId),
        name: 'Unknown',
        position: 'Unknown',
        createdAt: DateTime.now(),
      ),
    );

    if (!widget.playerResults.containsKey(playerId)) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: ResponsiveConfig.borderRadius(context, 12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: ResponsiveText(
            'No assessment data available for ${player.name}',
            baseFontSize: 14,
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.blueGrey[600],
            ),
          ),
        ),
      );
    }

    final results = widget.playerResults[playerId]!;

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveConfig.dimension(context, 48),
                height: ResponsiveConfig.dimension(context, 48),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent[700],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: ResponsiveText(
                    player.jerseyNumber?.toString() ?? '',
                    baseFontSize: 18,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
                      player.name,
                      baseFontSize: 18,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveText(
                      player.position ?? 'Unknown',
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AssessmentShotUtils.getScoreColor(results['overallScore'] as double? ?? 0.0)
                      .withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 16),
                ),
                child: ResponsiveText(
                  '${(results['overallScore'] as double? ?? 0.0).toStringAsFixed(1)}/10',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssessmentShotUtils.getScoreColor(results['overallScore'] as double? ?? 0.0),
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Responsive metrics layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildPerformanceMetric('Total Shots', (results['totalShots'] as int? ?? 0).toString(), Icons.sports_hockey)),
                        Expanded(child: _buildPerformanceMetric('Success Rate', '${((results['overallRate'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%', Icons.check_circle)),
                      ],
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    Row(
                      children: [
                        Expanded(child: _buildPerformanceMetric('Best Zone', _getBestZone(results), Icons.grid_on)),
                        const Expanded(child: SizedBox()), // Empty space for alignment
                      ],
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(child: _buildPerformanceMetric('Total Shots', (results['totalShots'] as int? ?? 0).toString(), Icons.sports_hockey)),
                    Expanded(child: _buildPerformanceMetric('Success Rate', '${((results['overallRate'] as double? ?? 0.0) * 100).toStringAsFixed(1)}%', Icons.check_circle)),
                    Expanded(child: _buildPerformanceMetric('Best Zone', _getBestZone(results), Icons.grid_on)),
                  ],
                );
              }
            },
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Category scores - responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile) {
                return Column(
                  children: [
                    for (final category in (results['categoryScores'] as Map<String, dynamic>).keys)
                      if (category != 'Overall')
                        Padding(
                          padding: ResponsiveConfig.paddingOnly(context, bottom: 8),
                          child: _buildCategoryScore(category, (results['categoryScores'] as Map<String, dynamic>)[category] as double? ?? 0.0),
                        ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    for (final category in (results['categoryScores'] as Map<String, dynamic>).keys)
                      if (category != 'Overall')
                        Expanded(child: _buildCategoryScore(category, (results['categoryScores'] as Map<String, dynamic>)[category] as double? ?? 0.0)),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric(String label, String value, IconData icon) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Column(
          children: [
            Icon(
              icon,
              color: Colors.blueGrey[700],
              size: deviceType == DeviceType.mobile ? ResponsiveConfig.iconSize(context, 20) : ResponsiveConfig.iconSize(context, 24),
            ),
            ResponsiveSpacing(multiplier: deviceType == DeviceType.mobile ? 0.5 : 1),
            ResponsiveText(
              value,
              baseFontSize: deviceType == DeviceType.mobile ? 14 : 16,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveText(
              label,
              baseFontSize: deviceType == DeviceType.mobile ? 10 : 12,
              style: TextStyle(color: Colors.blueGrey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryScore(String category, double score) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ResponsiveText(
              category,
              baseFontSize: deviceType == DeviceType.mobile ? 10 : 12,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            Container(
              height: ResponsiveConfig.dimension(context, 8),
              width: deviceType == DeviceType.mobile ? ResponsiveConfig.dimension(context, 36) : ResponsiveConfig.dimension(context, 48),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: ResponsiveConfig.borderRadius(context, 4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: score / 10,
                child: Container(
                  decoration: BoxDecoration(
                    color: AssessmentShotUtils.getScoreColor(score),
                    borderRadius: ResponsiveConfig.borderRadius(context, 4),
                  ),
                ),
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              '${score.toStringAsFixed(1)}',
              baseFontSize: deviceType == DeviceType.mobile ? 10 : 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShotBreakdownTable() {
    final Map<String, Map<String, int>> shotTypeStats = {};

    // Check if selected player has data
    if (_selectedPlayerId != null && widget.playerResults.containsKey(_selectedPlayerId)) {
      final results = widget.playerResults[_selectedPlayerId!];
      
      // FIXED: Use consistent data access patterns like shot files
      final typeRates = results!['typeRates'] as Map<String, dynamic>? ?? {};
      
      for (final type in typeRates.keys) {
        final successRate = typeRates[type] as double? ?? 0.0;
        // Estimate numbers based on success rate
        final totalShots = 20; // Approximation
        final successShots = (totalShots * successRate).round();
        
        shotTypeStats[type] = {
          'total': totalShots,
          'success': successShots,
        };
      }
    }

    if (shotTypeStats.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Shot Data',
        description: 'No shots match your current filters.',
        primaryActionLabel: 'Clear Filters',
        onPrimaryAction: _clearFilters,
        icon: Icons.search_off,
        iconColor: Colors.blueGrey[300],
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Colors.grey[100]),
        dataRowHeight: ResponsiveConfig.dimension(context, 56),
        columns: [
          DataColumn(label: ResponsiveText('Shot Type', baseFontSize: 14)),
          DataColumn(label: ResponsiveText('Total', baseFontSize: 14)),
          DataColumn(label: ResponsiveText('Success', baseFontSize: 14)),
          DataColumn(label: ResponsiveText('Rate', baseFontSize: 14)),
        ],
        rows: shotTypeStats.entries.map((entry) {
          final type = entry.key;
          final total = entry.value['total'] ?? 0;
          final success = entry.value['success'] ?? 0;
          final rate = total > 0 ? (success / total * 100) : 0.0;

          return DataRow(
            cells: [
              DataCell(ResponsiveText(
                type,
                baseFontSize: 14,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )),
              DataCell(ResponsiveText('$total', baseFontSize: 14)),
              DataCell(ResponsiveText('$success', baseFontSize: 14)),
              DataCell(Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AssessmentShotUtils.getScoreColor(rate / 10).withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: ResponsiveText(
                  '${rate.toStringAsFixed(1)}%',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AssessmentShotUtils.getScoreColor(rate / 10),
                  ),
                ),
              )),
            ],
          );
        }).toList(),
      ),
    );
  }

  // FIXED: Use ZoneHeatmapWidget like shot files
  Widget _buildZoneHeatmap() {
    // Get zone rates from selected player
    Map<String, dynamic> zoneMetrics = {};
    
    if (_selectedPlayerId != null && widget.playerResults.containsKey(_selectedPlayerId)) {
      final results = widget.playerResults[_selectedPlayerId!];
      final zoneRates = Map<String, double>.from(results!['zoneRates'] as Map<String, dynamic>? ?? {});
      
      // Convert to zone metrics format expected by ZoneHeatmapWidget
      for (var zone in ['1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        final successRate = zoneRates[zone] ?? 0.0;
        // Estimate shot count based on success rate
        final estimatedShots = (successRate * 20).round(); // Approximation
        
        zoneMetrics[zone] = {
          'count': estimatedShots,
          'successRate': successRate,
        };
      }
    }

    if (zoneMetrics.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Zone Data',
        description: 'No shots match your current filters.',
        primaryActionLabel: 'Clear Filters',
        onPrimaryAction: _clearFilters,
        icon: Icons.grid_off,
        iconColor: Colors.blueGrey[300],
      );
    }

    // Calculate total shots for the widget
    int totalShots = 0;
    for (var metrics in zoneMetrics.values) {
      totalShots += (metrics['count'] as int? ?? 0);
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        final aspectRatio = deviceType == DeviceType.mobile ? 1.2 : 1.5;
        return AspectRatio(
          aspectRatio: aspectRatio,
          child: ZoneHeatmapWidget(
            zoneMetrics: zoneMetrics,
            zoneLabels: _getZoneLabelsMap(),
            totalShots: totalShots,
          ),
        );
      },
    );
  }

  // FIXED: Use consistent zone labels map like shot files
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

  void _clearFilters() {
    setState(() {
      _selectedPositions = [];
      _selectedGroups = [];
      _selectedTypes = [];
    });
  }

  String _getBestZone(Map<String, dynamic> results) {
    final zoneRates = results['zoneRates'] as Map<String, dynamic>? ?? {};
    if (zoneRates.isEmpty) return '–';
    
    return zoneRates.entries
        .reduce((a, b) => (a.value as double) > (b.value as double) ? a : b)
        .key;
  }

  // Desktop-only action methods
  void _comparePlayerPerformance(Player player) {
    // Placeholder for player comparison functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compare ${player.name} - Coming Soon')),
    );
  }

  void _viewPlayerProgress(Player player) {
    // Placeholder for player progress functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View ${player.name} Progress - Coming Soon')),
    );
  }

  void _addPlayerNote(Player player) {
    // Placeholder for adding player notes
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Add Note for ${player.name} - Coming Soon')),
    );
  }
}