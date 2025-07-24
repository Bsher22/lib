// lib/widgets/domain/assessment/team_skating/team_skating_details_tab.dart
// REFACTORED: Updated with full responsive system integration following established patterns
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/player_performance_card.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/test_results_table.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// Responsive details tab for team skating assessment results
class TeamSkatingDetailsTab extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final List<Player> players;
  final Map<String, Map<String, dynamic>> playerTestResults;
  final Map<String, Map<String, dynamic>> playerResults;
  
  const TeamSkatingDetailsTab({
    Key? key,
    required this.assessment,
    required this.players,
    required this.playerTestResults,
    required this.playerResults,
  }) : super(key: key);

  @override
  _TeamSkatingDetailsTabState createState() => _TeamSkatingDetailsTabState();
}

class _TeamSkatingDetailsTabState extends State<TeamSkatingDetailsTab> {
  // Filter settings
  String _selectedGroup = 'All Groups';
  String _selectedCategory = 'All Categories';
  String? _selectedPlayerId;
  
  @override
  void initState() {
    super.initState();
    _initializeFilters();
  }
  
  void _initializeFilters() {
    if (widget.players.isNotEmpty) {
      _selectedPlayerId = widget.players[0].id.toString();
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

  // 📱 MOBILE LAYOUT: Vertical scrolling with essential filters
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileFilters(),
          ResponsiveSpacing(multiplier: 2),
          
          if (_selectedPlayerId != null) ...[
            _buildPlayerPerformanceCard(),
            ResponsiveSpacing(multiplier: 2),
          ],
          _buildMobileTestResults(),
          ResponsiveSpacing(multiplier: 2),
          _buildMobileGroupSummary(),
        ],
      ),
    );
  }

  // 📱 TABLET LAYOUT: Two-column with enhanced filtering
  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabletFilters(),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (_selectedPlayerId != null) ...[
                      _buildPlayerPerformanceCard(),
                      ResponsiveSpacing(multiplier: 3),
                    ],
                    _buildTestResultsTable(),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  children: [
                    _buildGroupPerformanceBreakdown(),
                    ResponsiveSpacing(multiplier: 3),
                    _buildPlayerComparison(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🖥️ DESKTOP LAYOUT: Three-column comprehensive view
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDesktopFilters(),
          ResponsiveSpacing(multiplier: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    if (_selectedPlayerId != null) ...[
                      _buildPlayerPerformanceCard(),
                      ResponsiveSpacing(multiplier: 3),
                    ],
                    _buildTestResultsTable(),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  children: [
                    _buildGroupPerformanceBreakdown(),
                    ResponsiveSpacing(multiplier: 3),
                    _buildPlayerComparison(),
                  ],
                ),
              ),
              ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  children: [
                    _buildAdvancedAnalytics(),
                    ResponsiveSpacing(multiplier: 3),
                    _buildExportOptions(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // MOBILE COMPONENTS
  Widget _buildMobileFilters() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Filter Results',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildPlayerSelector(),
          ResponsiveSpacing(multiplier: 2),
          Row(
            children: [
              Expanded(child: _buildGroupSelector()),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(child: _buildCategorySelector()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTestResults() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Test Results',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildTestResultsTable(),
        ],
      ),
    );
  }

  Widget _buildMobileGroupSummary() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Group Performance',
            baseFontSize: 16,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildGroupPerformanceBreakdown(),
        ],
      ),
    );
  }

  // TABLET COMPONENTS
  Widget _buildTabletFilters() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Advanced Filtering',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          Row(
            children: [
              Expanded(flex: 2, child: _buildPlayerSelector()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildGroupSelector()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildCategorySelector()),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildFilterSummary(),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    final playerName = _selectedPlayerId != null 
        ? widget.players.firstWhere((p) => p.id.toString() == _selectedPlayerId).name
        : 'All Players';

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, color: Colors.blue[600], size: ResponsiveConfig.iconSize(context, 20)),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              'Viewing: $playerName • $_selectedGroup • $_selectedCategory',
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[800],
              ),
            ),
          ),
          ResponsiveButton(
            text: 'Reset',
            onPressed: _resetFilters,
            baseHeight: 32,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.blue[600],
          ),
        ],
      ),
    );
  }

  // DESKTOP COMPONENTS
  Widget _buildDesktopFilters() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Advanced Analysis Filters',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const Spacer(),
              _buildQuickFilterChips(),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          Row(
            children: [
              Expanded(flex: 2, child: _buildPlayerSelector()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildGroupSelector()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildCategorySelector()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              _buildApplyFiltersButton(),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildFilterSummary(),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChips() {
    return Wrap(
      spacing: ResponsiveConfig.spacing(context, 8),
      children: [
        _buildQuickFilterChip('Top Performers', Icons.star, () => _applyQuickFilter('top')),
        _buildQuickFilterChip('Needs Focus', Icons.trending_down, () => _applyQuickFilter('bottom')),
        _buildQuickFilterChip('Complete Data', Icons.check_circle, () => _applyQuickFilter('complete')),
      ],
    );
  }

  Widget _buildQuickFilterChip(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue[100],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 16)),
          border: Border.all(color: Colors.blue[300]!),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: ResponsiveConfig.iconSize(context, 14), color: Colors.blue[700]),
            ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
            ResponsiveText(
              label,
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApplyFiltersButton() {
    return ResponsiveButton(
      text: 'Apply',
      onPressed: () {
        setState(() {
          // Trigger rebuild with current filters
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Filters applied successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      baseHeight: 48,
      backgroundColor: Colors.blue[600],
      foregroundColor: Colors.white,
    );
  }

  Widget _buildAdvancedAnalytics() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics, color: Colors.purple[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Advanced Analytics',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildAnalyticItem(
            'Data Completeness',
            '${_calculateDataCompleteness().toStringAsFixed(0)}%',
            Icons.data_usage,
            Colors.blue,
          ),
          _buildAnalyticItem(
            'Performance Variance',
            _calculatePerformanceVariance().toStringAsFixed(1),
            Icons.show_chart,
            Colors.orange,
          ),
          _buildAnalyticItem(
            'Team Consistency',
            _calculateTeamConsistency(),
            Icons.balance,
            Colors.green,
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildAnalyticsActions(),
        ],
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: ResponsiveConfig.iconSize(context, 16), color: color),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: ResponsiveText(
              label,
              baseFontSize: 13,
              style: TextStyle(color: Colors.blueGrey[700]),
            ),
          ),
          ResponsiveText(
            value,
            baseFontSize: 13,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsActions() {
    return Column(
      children: [
        ResponsiveButton(
          text: 'Generate Report',
          onPressed: _generateAnalyticsReport,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.purple[600],
          foregroundColor: Colors.white,
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveButton(
          text: 'Export Data',
          onPressed: _exportAnalytics,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.purple[600],
          borderColor: Colors.purple[600],
        ),
      ],
    );
  }

  Widget _buildExportOptions() {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: Colors.green[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Export Options',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildExportButton(
            'Player Data (CSV)',
            Icons.table_chart,
            Colors.green,
            () => _exportPlayerData(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildExportButton(
            'Test Results (PDF)',
            Icons.picture_as_pdf,
            Colors.red,
            () => _exportTestResults(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildExportButton(
            'Analysis Report',
            Icons.analytics,
            Colors.blue,
            () => _exportAnalysisReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildExportButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ResponsiveButton(
      text: label,
      onPressed: onPressed,
      baseHeight: 48,
      width: double.infinity,
      backgroundColor: color,
      foregroundColor: Colors.white,
    );
  }

  // SHARED COMPONENTS
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
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedPlayerId,
              isExpanded: true,
              hint: ResponsiveText('Select Player', baseFontSize: 14),
              items: widget.players.map((player) {
                return DropdownMenuItem<String>(
                  value: player.id.toString(),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.blue[100],
                        child: ResponsiveText(
                          player.jerseyNumber?.toString() ?? '?',
                          baseFontSize: 10,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          '${player.name}${player.jerseyNumber != null ? ' (#${player.jerseyNumber})' : ''}',
                          baseFontSize: 14,
                        ),
                      ),
                    ],
                  ),
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
  
  Widget _buildGroupSelector() {
    final List<String> groups = ['All Groups'];
    final assessmentGroups = widget.assessment['groups'] as List?;
    
    if (assessmentGroups != null) {
      for (var group in assessmentGroups) {
        final groupMap = group as Map<String, dynamic>;
        final groupName = groupMap['name'] as String? ?? groupMap['title'] as String? ?? 'Unknown Group';
        groups.add(groupName);
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Group',
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
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedGroup,
              isExpanded: true,
              items: groups.map((group) {
                return DropdownMenuItem<String>(
                  value: group,
                  child: ResponsiveText(group, baseFontSize: 14),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedGroup = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategorySelector() {
    final Set<String> categories = {'All Categories'};
    final assessmentGroups = widget.assessment['groups'] as List?;
    
    if (assessmentGroups != null) {
      for (var group in assessmentGroups) {
        final groupMap = group as Map<String, dynamic>;
        final tests = groupMap['tests'] as List?;
        
        if (tests != null) {
          for (var test in tests) {
            final testMap = test as Map<String, dynamic>;
            final category = testMap['category'] as String?;
            if (category != null) {
              categories.add(category);
            }
          }
        }
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Category',
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
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: categories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: ResponsiveText(category, baseFontSize: 14),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerPerformanceCard() {
    if (_selectedPlayerId == null) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: ResponsiveText(
            'Please select a player to view performance details',
            baseFontSize: 14,
            style: const TextStyle(fontStyle: FontStyle.italic),
          ),
        ),
      );
    }
    
    final playerId = _selectedPlayerId!;
    final playerIndex = widget.players.indexWhere((p) => p.id.toString() == playerId);
    
    if (playerIndex == -1) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: ResponsiveText(
            'Player not found',
            baseFontSize: 14,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.red,
            ),
          ),
        ),
      );
    }
    
    final player = widget.players[playerIndex];
    
    if (!widget.playerResults.containsKey(playerId)) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.info, color: Colors.orange[700], size: ResponsiveConfig.iconSize(context, 32)),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'No assessment data available for ${player.name}',
                baseFontSize: 14,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[800],
                ),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              ResponsiveText(
                'This player may not have completed the assessment yet.',
                baseFontSize: 12,
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final results = widget.playerResults[playerId]!;
    
    final categoryScores = results['categoryScores'] as Map<String, dynamic>?;
    final safeScores = <String, double>{};
    
    if (categoryScores != null) {
      categoryScores.forEach((key, value) {
        if (value is num) {
          safeScores[key] = value.toDouble();
        }
      });
    }
    
    final performanceLevel = results['performanceLevel'] as String? ?? 'Unknown';
    final completedTests = widget.playerTestResults[playerId]?.length ?? 0;
    
    return PlayerPerformanceCard(
      player: player,
      categoryScores: safeScores,
      performanceLevel: performanceLevel,
      completedTests: completedTests,
      totalTests: _getTotalTestCount(),
      onTap: () => _showPlayerDetailsDialog(player),
    );
  }
  
  Widget _buildTestResultsTable() {
    final playerId = _selectedPlayerId;
    if (playerId == null) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.blue[700]),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveText(
                'Please select a player to view test results',
                baseFontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (!widget.playerTestResults.containsKey(playerId)) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: ResponsiveText(
                'No test results available for this player',
                baseFontSize: 14,
              ),
            ),
          ],
        ),
      );
    }
    
    final playerResults = widget.playerTestResults[playerId]!;
    
    final List<Map<String, dynamic>> filteredResults = [];
    final assessmentGroups = widget.assessment['groups'] as List?;
    
    if (assessmentGroups != null) {
      for (var groupIndex = 0; groupIndex < assessmentGroups.length; groupIndex++) {
        final group = assessmentGroups[groupIndex] as Map<String, dynamic>;
        final groupName = group['name'] as String? ?? group['title'] as String? ?? 'Unknown Group';
        
        if (_selectedGroup != 'All Groups' && groupName != _selectedGroup) {
          continue;
        }
        
        final tests = group['tests'] as List?;
        if (tests != null) {
          for (var test in tests) {
            final testMap = test as Map<String, dynamic>;
            final testCategory = testMap['category'] as String?;
            
            if (_selectedCategory != 'All Categories' && testCategory != _selectedCategory) {
              continue;
            }
            
            final testId = testMap['id'] as String?;
            if (testId != null && playerResults.containsKey(testId)) {
              filteredResults.add({
                'group': group,
                'test': testMap,
                'result': playerResults[testId]!,
              });
            }
          }
        }
      }
    }
    
    if (filteredResults.isEmpty) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, color: Colors.grey[500], size: ResponsiveConfig.iconSize(context, 32)),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'No results found for the selected filters',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'Try adjusting your filter selections',
              baseFontSize: 12,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }
    
    return TestResultsTable(
      testResults: filteredResults,
      emptyMessage: 'No results found for the selected filters',
      onRowTap: (data) => _showTestDetailsDialog(data),
    );
  }
  
  Widget _buildGroupPerformanceBreakdown() {
    final assessmentGroups = widget.assessment['groups'] as List?;
    if (assessmentGroups == null) {
      return Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: ResponsiveText('No group data available', baseFontSize: 14),
      );
    }

    return Column(
      children: assessmentGroups.map((group) {
        return _buildGroupPerformance(group as Map<String, dynamic>);
      }).toList(),
    );
  }

  Widget _buildGroupPerformance(Map<String, dynamic> group) {
    double totalScore = 0;
    int count = 0;
    
    final groupTests = group['tests'] as List? ?? [];
    final groupName = group['name'] as String? ?? group['title'] as String? ?? 'Unknown Group';
    
    for (var playerId in widget.playerTestResults.keys) {
      final playerResults = widget.playerTestResults[playerId]!;
      
      for (var test in groupTests) {
        final testMap = test as Map<String, dynamic>;
        final testId = testMap['id'] as String?;
        
        if (testId != null && playerResults.containsKey(testId)) {
          final category = testMap['category'] as String? ?? 'Unknown';
          
          if (widget.playerResults.containsKey(playerId)) {
            final playerAnalytics = widget.playerResults[playerId]!;
            final categoryScores = playerAnalytics['categoryScores'] as Map<String, dynamic>?;
            
            if (categoryScores != null && categoryScores.containsKey(category)) {
              final categoryScore = categoryScores[category];
              if (categoryScore is num) {
                totalScore += categoryScore.toDouble();
                count++;
              }
            }
          }
        }
      }
    }
    
    double groupScore = count > 0 ? totalScore / count : 0;
    
    int completedTests = 0;
    int totalExpectedTests = groupTests.length * widget.players.length;
    
    for (var playerId in widget.playerTestResults.keys) {
      final playerResults = widget.playerTestResults[playerId]!;
      for (var test in groupTests) {
        final testMap = test as Map<String, dynamic>;
        final testId = testMap['id'] as String?;
        if (testId != null && playerResults.containsKey(testId)) {
          completedTests++;
        }
      }
    }
    
    return Padding(
      padding: ResponsiveConfig.paddingOnly(context, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  groupName,
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SkatingUtils.getScoreColor(groupScore).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 16)),
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
            '$completedTests of $totalExpectedTests tests completed',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1),
          LinearProgressIndicator(
            value: groupScore / 10,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              SkatingUtils.getScoreColor(groupScore),
            ),
            minHeight: ResponsiveConfig.dimension(context, 8),
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 4)),
          ),
          ResponsiveSpacing(multiplier: 2),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildPlayerComparison() {
    final sortedPlayers = widget.playerResults.entries.toList()
      ..sort((a, b) {
        final aScores = a.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final bScores = b.value['categoryScores'] as Map<String, dynamic>? ?? {};
        final aScore = (aScores['Overall'] as num?)?.toDouble() ?? 0.0;
        final bScore = (bScores['Overall'] as num?)?.toDouble() ?? 0.0;
        return bScore.compareTo(aScore);
      });

    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows, color: Colors.blue[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Player Comparison',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          Container(
            constraints: BoxConstraints(maxHeight: ResponsiveConfig.dimension(context, 300)),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: sortedPlayers.length,
              itemBuilder: (context, index) {
                final entry = sortedPlayers[index];
                final playerName = entry.value['playerName'] as String? ?? 'Unknown';
                final categoryScores = entry.value['categoryScores'] as Map<String, dynamic>? ?? {};
                final score = (categoryScores['Overall'] as num?)?.toDouble() ?? 0.0;
                
                return Container(
                  margin: ResponsiveConfig.paddingOnly(context, bottom: 8),
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: BoxDecoration(
                    color: index < 3 ? Colors.amber[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                    border: Border.all(
                      color: index < 3 ? Colors.amber[200]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: ResponsiveConfig.dimension(context, 24),
                        height: ResponsiveConfig.dimension(context, 24),
                        decoration: BoxDecoration(
                          color: index < 3 ? Colors.amber[600] : Colors.grey[400],
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: ResponsiveText(
                            '${index + 1}',
                            baseFontSize: 12,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          playerName,
                          baseFontSize: 13,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SkatingUtils.getScoreColor(score).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
                        ),
                        child: ResponsiveText(
                          score.toStringAsFixed(1),
                          baseFontSize: 12,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: SkatingUtils.getScoreColor(score),
                          ),
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

  // HELPER METHODS
  int _getTotalTestCount() {
    int total = 0;
    final assessmentGroups = widget.assessment['groups'] as List?;
    
    if (assessmentGroups != null) {
      for (var group in assessmentGroups) {
        final groupMap = group as Map<String, dynamic>;
        final tests = groupMap['tests'] as List? ?? [];
        total += tests.length;
      }
    }
    
    return total;
  }

  double _calculateDataCompleteness() {
    int totalExpected = widget.players.length * _getTotalTestCount();
    int totalCompleted = 0;
    
    for (var playerResults in widget.playerTestResults.values) {
      totalCompleted += playerResults.length;
    }
    
    return totalExpected > 0 ? (totalCompleted / totalExpected) * 100 : 0;
  }

  double _calculatePerformanceVariance() {
    final scores = <double>[];
    
    for (var result in widget.playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>? ?? {};
      final score = (categoryScores['Overall'] as num?)?.toDouble();
      if (score != null) scores.add(score);
    }
    
    if (scores.length < 2) return 0;
    
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / scores.length;
    
    return variance;
  }

  String _calculateTeamConsistency() {
    final variance = _calculatePerformanceVariance();
    
    if (variance < 1.0) return 'Excellent';
    if (variance < 2.0) return 'Good';
    if (variance < 3.0) return 'Average';
    return 'Needs Work';
  }

  void _resetFilters() {
    setState(() {
      _selectedGroup = 'All Groups';
      _selectedCategory = 'All Categories';
      if (widget.players.isNotEmpty) {
        _selectedPlayerId = widget.players[0].id.toString();
      }
    });
  }

  void _applyQuickFilter(String filterType) {
    switch (filterType) {
      case 'top':
        // Find top performer
        var topPlayer = widget.playerResults.entries.fold<MapEntry<String, Map<String, dynamic>>?>(
          null,
          (prev, curr) {
            final currScore = (curr.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double? ?? 0.0;
            final prevScore = prev != null ? ((prev.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double?) ?? 0.0 : 0.0;
            return currScore > prevScore ? curr : prev;
          },
        );
        if (topPlayer != null) {
          setState(() {
            _selectedPlayerId = topPlayer.key;
          });
        }
        break;
      case 'bottom':
        // Find bottom performer
        var bottomPlayer = widget.playerResults.entries.fold<MapEntry<String, Map<String, dynamic>>?>(
          null,
          (prev, curr) {
            final currScore = (curr.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double? ?? 10.0;
            final prevScore = prev != null ? ((prev.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double?) ?? 10.0 : 10.0;
            return currScore < prevScore ? curr : prev;
          },
        );
        if (bottomPlayer != null) {
          setState(() {
            _selectedPlayerId = bottomPlayer.key;
          });
        }
        break;
      case 'complete':
        // Find player with complete data
        for (var playerId in widget.playerTestResults.keys) {
          final playerResults = widget.playerTestResults[playerId]!;
          if (playerResults.length >= _getTotalTestCount()) {
            setState(() {
              _selectedPlayerId = playerId;
            });
            break;
          }
        }
        break;
    }
  }

  void _generateAnalyticsReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics report generation feature coming soon!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _exportAnalytics() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analytics export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportPlayerData() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Player data export feature coming soon!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportTestResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Test results export feature coming soon!'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _exportAnalysisReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Analysis report export feature coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }
  
  void _showPlayerDetailsDialog(Player player) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('${player.name} Details', baseFontSize: 18),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText('Jersey Number: ${player.jerseyNumber ?? "Not assigned"}', baseFontSize: 14),
              ResponsiveText('Position: ${player.position ?? "Unknown"}', baseFontSize: 14),
              ResponsiveText('Age Group: ${player.ageGroup ?? "Not specified"}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText('Assessment Performance:', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 1),
              
              if (widget.playerResults.containsKey(player.id.toString())) ...[
                Builder(
                  builder: (context) {
                    final results = widget.playerResults[player.id.toString()]!;
                    final categoryScores = results['categoryScores'] as Map<String, dynamic>? ?? {};
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: categoryScores.entries.map((entry) {
                        final score = (entry.value as num?)?.toDouble() ?? 0.0;
                        return Padding(
                          padding: ResponsiveConfig.paddingOnly(context, bottom: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ResponsiveText(entry.key, baseFontSize: 14),
                              ResponsiveText(
                                score.toStringAsFixed(1),
                                baseFontSize: 14,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: SkatingUtils.getScoreColor(score),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ] else
                ResponsiveText('No assessment data available', baseFontSize: 14),
            ],
          ),
        ),
        actions: [
          ResponsiveButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            baseHeight: 48,
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
  
  void _showTestDetailsDialog(Map<String, dynamic> testData) {
    final test = testData['test'] as Map<String, dynamic>;
    final result = testData['result'] as Map<String, dynamic>;
    final group = testData['group'] as Map<String, dynamic>;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText(test['title'] as String? ?? 'Test Details', baseFontSize: 18),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText('Group: ${group['name'] ?? group['title'] ?? "Unknown"}', baseFontSize: 14),
              ResponsiveText('Category: ${test['category'] ?? "Unknown"}', baseFontSize: 14),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText('Result:', baseFontSize: 14),
              ResponsiveText('Time: ${result['time'] ?? "Not recorded"} seconds', baseFontSize: 14),
              if (result['notes'] != null && (result['notes'] as String).isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText('Notes: ${result['notes']}', baseFontSize: 14),
              ],
              if (result['timestamp'] != null) ...[
                ResponsiveSpacing(multiplier: 1),
                ResponsiveText('Recorded: ${DateTime.tryParse(result['timestamp'])?.toString() ?? result['timestamp']}', baseFontSize: 14),
              ],
            ],
          ),
        ),
        actions: [
          ResponsiveButton(
            text: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            baseHeight: 48,
            backgroundColor: Colors.grey[600],
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}