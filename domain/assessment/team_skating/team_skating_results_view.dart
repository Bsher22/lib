// lib/widgets/domain/assessment/team_skating/team_skating_results_view.dart
// PHASE 4: Updated with full responsiveness following established patterns
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as Math;
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_results_display.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_skating/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/stat_item_card.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamSkatingResultsView extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final int teamId;
  final String teamName;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final Map<String, Map<String, Map<String, dynamic>>> playerTestResults;

  const TeamSkatingResultsView({
    Key? key,
    required this.assessment,
    required this.teamId,
    required this.teamName,
    required this.onReset,
    required this.onSave,
    required this.playerTestResults,
  }) : super(key: key);

  @override
  _TeamSkatingResultsViewState createState() => _TeamSkatingResultsViewState();
}

class _TeamSkatingResultsViewState extends State<TeamSkatingResultsView> {
  bool _isLoading = true;
  Map<String, double> _teamMetrics = {};
  List<Player> _players = [];
  Map<String, Map<String, dynamic>> _playerResults = {};
  String? _error;

  ApiService get _apiService {
    final appState = Provider.of<AppState>(context, listen: false);
    return appState.api;
  }

  @override
  void initState() {
    super.initState();
    _processTeamResults();
  }

  Map<String, Map<String, dynamic>> _processPlayerTestResults() {
    final Map<String, Map<String, dynamic>> results = {};

    for (var playerEntry in widget.playerTestResults.entries) {
      final playerId = playerEntry.key;
      final playerTests = playerEntry.value;

      if (playerTests.isNotEmpty) {
        String playerName = 'Unknown Player';
        try {
          final player = _players.firstWhere((p) => p.id.toString() == playerId);
          playerName = player.name;
        } catch (e) {
          playerName = 'Player $playerId';
        }

        final categoryScores = _calculateCategoryScoresFromTests(playerTests);
        
        results[playerId] = {
          'playerName': playerName,
          'categoryScores': categoryScores,
          'performanceLevel': _determinePerformanceLevel(categoryScores),
          'strengths': _extractStrengths(categoryScores),
          'improvements': _extractImprovements(categoryScores),
        };
      }
    }

    return results;
  }

  Map<String, double> _calculateCategoryScoresFromTests(Map<String, Map<String, dynamic>> playerTests) {
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (var testResult in playerTests.values) {
      final testId = testResult['testId'] as String?;
      final time = (testResult['time'] as num?)?.toDouble();
      
      if (testId != null && time != null && time > 0) {
        final category = _getTestCategory(testId);
        final score = _convertTimeToScore(testId, time);
        
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + score;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    final categoryScores = <String, double>{};
    for (var category in categoryTotals.keys) {
      final count = categoryCounts[category] ?? 1;
      categoryScores[category] = categoryTotals[category]! / count;
    }

    if (categoryScores.isNotEmpty) {
      final overall = categoryScores.values.reduce((a, b) => a + b) / categoryScores.length;
      categoryScores['Overall'] = overall;
    } else {
      categoryScores['Overall'] = 0.0;
    }

    return categoryScores;
  }

  Map<String, double> _calculateTeamMetricsFromIndividuals(Map<String, Map<String, dynamic>> playerResults) {
    final teamMetrics = <String, double>{};
    final categoryTotals = <String, double>{};
    final categoryCounts = <String, int>{};

    for (var result in playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, double>? ?? {};
      
      for (var entry in categoryScores.entries) {
        final category = entry.key;
        final score = entry.value;
        
        categoryTotals[category] = (categoryTotals[category] ?? 0.0) + score;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }
    }

    for (var category in categoryTotals.keys) {
      final count = categoryCounts[category] ?? 1;
      final average = categoryTotals[category]! / count;
      teamMetrics['skating_$category'] = average;
    }

    return teamMetrics;
  }

  String _getTestCategory(String testId) {
    switch (testId) {
      case 'forward_speed_test':
      case 'stop_start_test':
      case 'acceleration_test':
        return 'Speed';
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

  double _convertTimeToScore(String testId, double time) {
    final benchmarks = _getBenchmarksForTest(testId);
    
    if (benchmarks.isEmpty) return 5.0;
    
    if (time <= benchmarks['Elite']!) {
      return 9.0 + (benchmarks['Elite']! - time) * 0.5;
    } else if (time <= benchmarks['Advanced']!) {
      return 7.0 + (benchmarks['Advanced']! - time) / (benchmarks['Advanced']! - benchmarks['Elite']!) * 2.0;
    } else if (time <= benchmarks['Developing']!) {
      return 5.0 + (benchmarks['Developing']! - time) / (benchmarks['Developing']! - benchmarks['Advanced']!) * 2.0;
    } else if (time <= benchmarks['Beginner']!) {
      return 3.0 + (benchmarks['Beginner']! - time) / (benchmarks['Beginner']! - benchmarks['Developing']!) * 2.0;
    } else {
      return Math.max(1.0, 3.0 - (time - benchmarks['Beginner']!) * 0.1);
    }
  }

  Map<String, double> _getBenchmarksForTest(String testId) {
    const benchmarkData = {
      'forward_speed_test': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2},
      'backward_speed_test': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5},
      'agility_test': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8},
      'transitions_test': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5},
      'crossovers_test': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2},
      'stop_start_test': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2},
      'acceleration_test': {'Elite': 1.8, 'Advanced': 2.0, 'Developing': 2.2, 'Beginner': 2.5},
    };
    
    return benchmarkData[testId] ?? {};
  }

  Future<void> _processTeamResults() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final appState = Provider.of<AppState>(context, listen: false);
      final teamPlayers = await appState.fetchTeamPlayers(widget.teamId);

      final processedResults = _processPlayerTestResults();
      final calculatedMetrics = _calculateTeamMetricsFromIndividuals(processedResults);

      setState(() {
        _players = teamPlayers;
        _playerResults = processedResults;
        _teamMetrics = calculatedMetrics;
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Error processing team results: $e');
      setState(() {
        _error = 'Failed to process team results: $e';
        _isLoading = false;
      });
    }
  }

  String _determinePerformanceLevel(Map<String, double> categoryScores) {
    final overallScore = categoryScores['Overall'] ?? 0.0;
    
    if (overallScore >= 8.5) return 'Elite';
    if (overallScore >= 7.0) return 'Advanced';
    if (overallScore >= 5.5) return 'Proficient';
    if (overallScore >= 4.0) return 'Developing';
    if (overallScore >= 2.5) return 'Basic';
    return 'Beginner';
  }

  List<String> _extractStrengths(Map<String, double> categoryScores) {
    final strengths = <String>[];
    
    final sortedScores = categoryScores.entries
        .where((e) => e.key != 'Overall')
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    for (var entry in sortedScores.take(2)) {
      if (entry.value >= 6.0) {
        strengths.add('Strong ${entry.key} performance');
      }
    }
    
    return strengths;
  }

  List<String> _extractImprovements(Map<String, double> categoryScores) {
    final improvements = <String>[];
    
    final sortedScores = categoryScores.entries
        .where((e) => e.key != 'Overall')
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (var entry in sortedScores.take(2)) {
      if (entry.value < 5.0) {
        improvements.add('Focus on ${entry.key} development');
      }
    }
    
    return improvements;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText('Loading team results...', baseFontSize: 16),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, size: ResponsiveConfig.iconSize(context, 64), color: Colors.red[700]),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(_error!, baseFontSize: 16, style: TextStyle(color: Colors.red[700])),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Retry',
              onPressed: _processTeamResults,
              baseHeight: 48,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      );
    }

    final teamScore = _calculateTeamOverallScore();

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(teamScore);
          case DeviceType.tablet:
            return _buildTabletLayout(teamScore);
          case DeviceType.desktop:
            return _buildDesktopLayout(teamScore);
        }
      },
    );
  }

  // 📱 MOBILE LAYOUT: Tabbed interface with team overview
  Widget _buildMobileLayout(double teamScore) {
    return AssessmentResultsDisplay(
      title: '${widget.assessment['title'] as String? ?? 'Skating Assessment'} - Team Results',
      subjectName: widget.teamName,
      subjectType: 'team',
      overallScore: teamScore,
      performanceLevel: _getTeamPerformanceLevel(teamScore),
      scoreColorProvider: SkatingUtils.getScoreColor,
      headerContent: _buildMobileHeaderContent(teamScore),
      tabs: [
        AssessmentResultTab(
          label: 'Summary',
          contentBuilder: (context) => TeamSkatingSummaryTab(
            teamName: widget.teamName,
            players: _players,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Details',
          contentBuilder: (context) => TeamSkatingDetailsTab(
            assessment: widget.assessment,
            players: _players,
            playerResults: _playerResults,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Recommendations',
          contentBuilder: (context) => TeamSkatingRecommendationsTab(
            teamName: widget.teamName,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
          ),
        ),
      ],
      onReset: widget.onReset,
      onSave: widget.onSave,
    );
  }

  // 📱 TABLET LAYOUT: Enhanced layout with sidebar preview
  Widget _buildTabletLayout(double teamScore) {
    return AssessmentResultsDisplay(
      title: '${widget.assessment['title'] as String? ?? 'Skating Assessment'} - Team Results',
      subjectName: widget.teamName,
      subjectType: 'team',
      overallScore: teamScore,
      performanceLevel: _getTeamPerformanceLevel(teamScore),
      scoreColorProvider: SkatingUtils.getScoreColor,
      headerContent: _buildTabletHeaderContent(teamScore),
      tabs: [
        AssessmentResultTab(
          label: 'Summary',
          contentBuilder: (context) => TeamSkatingSummaryTab(
            teamName: widget.teamName,
            players: _players,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Details',
          contentBuilder: (context) => TeamSkatingDetailsTab(
            assessment: widget.assessment,
            players: _players,
            playerResults: _playerResults,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Recommendations',
          contentBuilder: (context) => TeamSkatingRecommendationsTab(
            teamName: widget.teamName,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
          ),
        ),
      ],
      onReset: widget.onReset,
      onSave: widget.onSave,
    );
  }

  // 🖥️ DESKTOP LAYOUT: Main results + comprehensive action sidebar
  Widget _buildDesktopLayout(double teamScore) {
    return AssessmentResultsDisplay(
      title: '${widget.assessment['title'] as String? ?? 'Skating Assessment'} - Team Results',
      subjectName: widget.teamName,
      subjectType: 'team',
      overallScore: teamScore,
      performanceLevel: _getTeamPerformanceLevel(teamScore),
      scoreColorProvider: SkatingUtils.getScoreColor,
      headerContent: _buildDesktopHeaderContent(teamScore),
      tabs: [
        AssessmentResultTab(
          label: 'Summary',
          contentBuilder: (context) => TeamSkatingSummaryTab(
            teamName: widget.teamName,
            players: _players,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Details',
          contentBuilder: (context) => TeamSkatingDetailsTab(
            assessment: widget.assessment,
            players: _players,
            playerResults: _playerResults,
            playerTestResults: widget.playerTestResults,
          ),
        ),
        AssessmentResultTab(
          label: 'Recommendations',
          contentBuilder: (context) => TeamSkatingRecommendationsTab(
            teamName: widget.teamName,
            playerResults: _playerResults,
            teamAverages: _teamMetrics,
          ),
        ),
      ],
      onReset: widget.onReset,
      onSave: widget.onSave,
      sidebarContent: _buildTeamActionSidebar(teamScore),
    );
  }

  // RESPONSIVE HEADER CONTENT
  Widget _buildMobileHeaderContent(double teamScore) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatItemCard(
              label: 'Players',
              value: '${_players.length}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            StatItemCard(
              label: 'Avg Score',
              value: teamScore.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.amber,
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1.5),
        _buildPositionBreakdown(),
      ],
    );
  }

  Widget _buildTabletHeaderContent(double teamScore) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatItemCard(
              label: 'Players',
              value: '${_players.length}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            StatItemCard(
              label: 'Average Score',
              value: teamScore.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.amber,
            ),
            StatItemCard(
              label: 'Position',
              value: (widget.assessment['position'] as String? ?? 'Mixed').toUpperCase(),
              icon: Icons.sports_hockey,
              color: Colors.purple,
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 2),
        Row(
          children: [
            Expanded(child: _buildPositionBreakdown()),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(child: _buildQuickInsights(teamScore)),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopHeaderContent(double teamScore) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatItemCard(
              label: 'Players',
              value: '${_players.length}',
              icon: Icons.people,
              color: Colors.blue,
            ),
            StatItemCard(
              label: 'Average Score',
              value: teamScore.toStringAsFixed(1),
              icon: Icons.star,
              color: Colors.amber,
            ),
            StatItemCard(
              label: 'Position',
              value: (widget.assessment['position'] as String? ?? 'Mixed').toUpperCase(),
              icon: Icons.sports_hockey,
              color: Colors.purple,
            ),
            StatItemCard(
              label: 'Performance',
              value: _getTeamPerformanceLevel(teamScore),
              icon: Icons.trending_up,
              color: SkatingUtils.getScoreColor(teamScore),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 2.5),
        Row(
          children: [
            Expanded(child: _buildPositionBreakdown()),
            ResponsiveSpacing(multiplier: 2.5, direction: Axis.horizontal),
            Expanded(child: _buildQuickInsights(teamScore)),
            ResponsiveSpacing(multiplier: 2.5, direction: Axis.horizontal),
            Expanded(child: _buildTeamProgress()),
          ],
        ),
      ],
    );
  }

  Widget _buildPositionBreakdown() {
    final positionCounts = <String, int>{};
    for (var player in _players) {
      final position = player.position ?? 'Unknown';
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.groups, color: Colors.blue[600], size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
              ResponsiveText(
                'Team Composition',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          Wrap(
            spacing: ResponsiveConfig.spacing(context, 8),
            runSpacing: ResponsiveConfig.spacing(context, 4),
            children: positionCounts.entries.map((entry) {
              return Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
                ),
                child: ResponsiveText(
                  '${entry.key}: ${entry.value}',
                  baseFontSize: 10,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.blue[800],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInsights(double teamScore) {
    String insight;
    Color insightColor;
    IconData insightIcon;

    if (teamScore >= 8.0) {
      insight = 'Elite team performance across all skating skills';
      insightColor = Colors.green;
      insightIcon = Icons.emoji_events;
    } else if (teamScore >= 6.0) {
      insight = 'Strong team with opportunities for refinement';
      insightColor = Colors.blue;
      insightIcon = Icons.trending_up;
    } else if (teamScore >= 4.0) {
      insight = 'Developing team requiring focused training';
      insightColor = Colors.orange;
      insightIcon = Icons.school;
    } else {
      insight = 'Foundation building needed for team development';
      insightColor = Colors.red;
      insightIcon = Icons.foundation;
    }

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: insightColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        border: Border.all(color: insightColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(insightIcon, color: insightColor, size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Insight',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: insightColor,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            insight,
            baseFontSize: 11,
            style: TextStyle(
              color: insightColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamProgress() {
    final totalTests = _calculateTotalExpectedTests();
    final completedTests = _calculateCompletedTests();
    final progressPercent = totalTests > 0 ? (completedTests / totalTests) * 100 : 0;

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_turned_in, color: Colors.green[600], size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
              ResponsiveText(
                'Assessment Progress',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            '$completedTests of $totalTests tests completed',
            baseFontSize: 11,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          ResponsiveSpacing(multiplier: 0.75),
          LinearProgressIndicator(
            value: progressPercent / 100,
            backgroundColor: Colors.green[100],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
            minHeight: ResponsiveConfig.dimension(context, 6),
            borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 3)),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            '${progressPercent.toStringAsFixed(0)}% Complete',
            baseFontSize: 10,
            style: TextStyle(
              color: Colors.green[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // DESKTOP SIDEBAR
  Widget _buildTeamActionSidebar(double teamScore) {
    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBulkExportOptions(),
            ResponsiveSpacing(multiplier: 3),
            _buildSkaterComparisons(),
            ResponsiveSpacing(multiplier: 3),
            _buildNextStepsPanel(),
            ResponsiveSpacing(multiplier: 3),
            _buildSkatingInsights(teamScore),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkExportOptions() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.file_download, color: Colors.blue[600]),
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
          
          _buildActionButton(
            'Team Report (PDF)',
            Icons.picture_as_pdf,
            Colors.red,
            () => _exportTeamReport(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildActionButton(
            'Individual Cards',
            Icons.credit_card,
            Colors.green,
            () => _exportIndividualCards(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildActionButton(
            'Data Export (CSV)',
            Icons.table_chart,
            Colors.orange,
            () => _exportData(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkaterComparisons() {
    // Get top and bottom performers
    final sortedPlayers = _playerResults.entries.toList()
      ..sort((a, b) {
        final aScore = (a.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double? ?? 0.0;
        final bScore = (b.value['categoryScores'] as Map<String, dynamic>?)?['Overall'] as double? ?? 0.0;
        return bScore.compareTo(aScore);
      });

    final topPerformer = sortedPlayers.isNotEmpty ? sortedPlayers.first : null;
    final needsAttention = sortedPlayers.isNotEmpty ? sortedPlayers.last : null;

    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.compare, color: Colors.purple[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Comparisons',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (topPerformer != null) ...[
            _buildComparisonItem(
              'Top Performer',
              topPerformer.value['playerName'] as String,
              '${((topPerformer.value['categoryScores'] as Map<String, dynamic>)['Overall'] as double).toStringAsFixed(1)}/10',
              Colors.green,
              Icons.star,
            ),
            ResponsiveSpacing(multiplier: 1.5),
          ],
          
          if (needsAttention != null) ...[
            _buildComparisonItem(
              'Needs Focus',
              needsAttention.value['playerName'] as String,
              '${((needsAttention.value['categoryScores'] as Map<String, dynamic>)['Overall'] as double).toStringAsFixed(1)}/10',
              Colors.orange,
              Icons.trending_up,
            ),
            ResponsiveSpacing(multiplier: 1.5),
          ],
          
          _buildActionButton(
            'Detailed Comparison',
            Icons.analytics,
            Colors.purple,
            () => _showDetailedComparison(),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, String name, String score, Color color, IconData icon) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 8)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: ResponsiveConfig.iconSize(context, 16)),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  label,
                  baseFontSize: 10,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                ResponsiveText(
                  name,
                  baseFontSize: 12,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          ResponsiveText(
            score,
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

  Widget _buildNextStepsPanel() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.next_plan, color: Colors.indigo[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Next Steps',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildActionButton(
            'Schedule Re-assessment',
            Icons.calendar_today,
            Colors.indigo,
            () => _scheduleReassessment(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildActionButton(
            'Create Training Plan',
            Icons.fitness_center,
            Colors.green,
            () => _createTrainingPlan(),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildActionButton(
            'Share with Coaches',
            Icons.share,
            Colors.blue,
            () => _shareWithCoaches(),
          ),
        ],
      ),
    );
  }

  Widget _buildSkatingInsights(double teamScore) {
    final insights = _generateTeamInsights(teamScore);
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(ResponsiveConfig.dimension(context, 12)),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.amber[600]),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'AI Insights',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          ...insights.map((insight) => Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: ResponsiveConfig.dimension(context, 4),
                  height: ResponsiveConfig.dimension(context, 4),
                  margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber[600],
                    shape: BoxShape.circle,
                  ),
                ),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    insight,
                    baseFontSize: 12,
                    style: TextStyle(
                      color: Colors.blueGrey[700],
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ResponsiveButton(
        text: label,
        onPressed: onPressed,
        baseHeight: 40,
        backgroundColor: color,
        foregroundColor: Colors.white,
        icon: icon,
      ),
    );
  }

  // HELPER METHODS
  double _calculateTeamOverallScore() {
    if (_teamMetrics.containsKey('skating_Overall')) {
      return _teamMetrics['skating_Overall']!;
    }

    double totalScore = 0;
    int count = 0;

    for (var result in _playerResults.values) {
      final categoryScores = result['categoryScores'] as Map<String, dynamic>?;
      if (categoryScores != null && categoryScores.containsKey('Overall')) {
        totalScore += (categoryScores['Overall'] as num).toDouble();
        count++;
      }
    }

    return count > 0 ? totalScore / count : 0;
  }

  String _getTeamPerformanceLevel(double score) {
    if (score >= 8.5) return 'Elite';
    if (score >= 7.0) return 'Advanced';
    if (score >= 5.5) return 'Proficient';
    if (score >= 4.0) return 'Developing';
    if (score >= 2.5) return 'Basic';
    return 'Beginner';
  }

  int _calculateTotalExpectedTests() {
    int total = 0;
    final groups = widget.assessment['groups'] as List?;
    if (groups != null) {
      for (var group in groups) {
        final tests = (group as Map<String, dynamic>)['tests'] as List? ?? [];
        total += tests.length * _players.length;
      }
    }
    return total;
  }

  int _calculateCompletedTests() {
    int total = 0;
    for (var playerResults in widget.playerTestResults.values) {
      total += playerResults.length;
    }
    return total;
  }

  List<String> _generateTeamInsights(double teamScore) {
    final insights = <String>[];
    
    // Performance level insight
    if (teamScore >= 8.0) {
      insights.add('Exceptional team performance indicates excellent coaching and player development programs.');
    } else if (teamScore >= 6.0) {
      insights.add('Strong foundation with specific areas identified for targeted improvement.');
    } else {
      insights.add('Significant development opportunity through focused skill-building programs.');
    }
    
    // Team composition insight
    final positionCounts = <String, int>{};
    for (var player in _players) {
      final position = player.position ?? 'Unknown';
      positionCounts[position] = (positionCounts[position] ?? 0) + 1;
    }
    
    if (positionCounts.length > 1) {
      insights.add('Diverse position mix allows for comprehensive team development strategies.');
    }
    
    // Progress insight
    final progressPercent = (_calculateCompletedTests() / _calculateTotalExpectedTests()) * 100;
    if (progressPercent >= 90) {
      insights.add('Comprehensive assessment data provides reliable foundation for training recommendations.');
    }
    
    return insights;
  }

  // ACTION METHODS
  void _exportTeamReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Team report export feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _exportIndividualCards() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Individual cards export feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _exportData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Data export feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showDetailedComparison() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Detailed comparison feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.purple,
      ),
    );
  }

  void _scheduleReassessment() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Schedule re-assessment feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  void _createTrainingPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Training plan creation feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _shareWithCoaches() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText('Share with coaches feature coming soon!', baseFontSize: 14),
        backgroundColor: Colors.blue,
      ),
    );
  }
}