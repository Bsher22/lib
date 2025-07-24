// lib/screens/players/tabs/player_performance_tab.dart

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/skating.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/filter_chip_group.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/toggle_button_group.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/volume_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/power_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/shot_distribution_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/interactive_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/radar_chart_widget.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:intl/intl.dart';

enum PerformanceType { shooting, skating, combined }

class PlayerPerformanceTab extends StatefulWidget {
  final Player player;
  final Map<String, dynamic> analytics;
  final List<Shot> shots;
  final List<Skating> skatings; // NEW: Include skating data
  final List<Map<String, dynamic>> weeklyTrends;
  final Map<String, dynamic>? skatingAnalytics; // NEW: Skating analytics
  final VoidCallback? onRecordSkating; // NEW: Record skating session - REMOVED: onRecordShot
  final VoidCallback? onViewHistory;
  
  const PlayerPerformanceTab({
    Key? key,
    required this.player,
    required this.analytics,
    required this.shots,
    this.skatings = const [], // NEW
    required this.weeklyTrends,
    this.skatingAnalytics, // NEW
    // REMOVED: required this.onRecordShot,
    this.onRecordSkating, // NEW
    this.onViewHistory,
  }) : super(key: key);

  @override
  State<PlayerPerformanceTab> createState() => _PlayerPerformanceTabState();
}

class _PlayerPerformanceTabState extends State<PlayerPerformanceTab> {
  PerformanceType _currentView = PerformanceType.shooting;
  List<String> _selectedShotTypes = ['All'];
  List<String> _availableShotTypes = ['All', 'Wrist', 'Snap', 'Slap', 'Backhand'];
  List<String> _selectedSkatingTypes = ['All']; // NEW
  List<String> _availableSkatingTypes = ['All', 'Assessment', 'Practice']; // NEW
  List<Shot> _filteredShots = [];
  List<Skating> _filteredSkatings = []; // NEW
  bool _showFilters = false;

  // NEW: Assessment navigation methods
  void _navigateToShotAssessment() {
    Navigator.pushNamed(context, '/shot-assessment');
  }

  void _navigateToSkatingAssessment() {
    Navigator.pushNamed(context, '/skating-assessment');
  }
  
  @override
  void initState() {
    super.initState();
    _updateFilteredData();
  }
  
  @override
  void didUpdateWidget(PlayerPerformanceTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shots != oldWidget.shots || widget.skatings != oldWidget.skatings) {
      _updateFilteredData();
    }
  }

  void _onPerformanceTypeChanged(PerformanceType type) {
    setState(() {
      _currentView = type;
      _updateFilteredData();
    });
  }
  
  void _onShotTypeFilterChanged(String type, bool selected) {
    setState(() {
      if (type == 'All') {
        if (selected) {
          _selectedShotTypes = ['All'];
        } else {
          _selectedShotTypes = [];
        }
      } else {
        _selectedShotTypes.remove('All');
        
        if (selected) {
          _selectedShotTypes.add(type);
        } else {
          _selectedShotTypes.remove(type);
        }
        
        if (_selectedShotTypes.isEmpty) {
          _selectedShotTypes = ['All'];
        }
      }
      
      _updateFilteredData();
    });
  }

  // NEW: Handle skating type filtering
  void _onSkatingTypeFilterChanged(String type, bool selected) {
    setState(() {
      if (type == 'All') {
        if (selected) {
          _selectedSkatingTypes = ['All'];
        } else {
          _selectedSkatingTypes = [];
        }
      } else {
        _selectedSkatingTypes.remove('All');
        
        if (selected) {
          _selectedSkatingTypes.add(type);
        } else {
          _selectedSkatingTypes.remove(type);
        }
        
        if (_selectedSkatingTypes.isEmpty) {
          _selectedSkatingTypes = ['All'];
        }
      }
      
      _updateFilteredData();
    });
  }
  
  void _updateFilteredData() {
    setState(() {
      // Filter shots
      if (_selectedShotTypes.contains('All')) {
        _filteredShots = List.from(widget.shots);
      } else {
        _filteredShots = widget.shots.where((shot) => 
          _selectedShotTypes.contains(shot.type)).toList();
      }

      // NEW: Filter skating sessions
      if (_selectedSkatingTypes.contains('All')) {
        _filteredSkatings = List.from(widget.skatings);
      } else {
        _filteredSkatings = widget.skatings.where((skating) {
          if (_selectedSkatingTypes.contains('Assessment')) {
            return skating.isAssessment;
          } else if (_selectedSkatingTypes.contains('Practice')) {
            return !skating.isAssessment;
          }
          return true;
        }).toList();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final hasData = _hasAnyData();
    
    if (!hasData) {
      return _buildEmptyState(context);
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildViewSelector(), // NEW: Toggle between shooting/skating/combined
          const SizedBox(height: 16),
          _buildCompactStatsBar(),
          const SizedBox(height: 16),
          _buildFilterToggle(),
          if (_showFilters) ...[
            const SizedBox(height: 8),
            _buildFilterSection(),
            const SizedBox(height: 16),
          ],
          _buildChartsSection(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  // NEW: View selector for shooting/skating/combined
  Widget _buildViewSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance View',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 12),
            ToggleButtonGroup<PerformanceType>(
              options: const [PerformanceType.shooting, PerformanceType.skating, PerformanceType.combined],
              selectedOption: _currentView,
              onSelected: _onPerformanceTypeChanged,
              labelBuilder: (type) {
                switch (type) {
                  case PerformanceType.shooting:
                    return 'Shooting';
                  case PerformanceType.skating:
                    return 'Skating';
                  case PerformanceType.combined:
                    return 'Combined';
                }
              },
              defaultSelectedColor: Colors.blue,
              borderRadius: BorderRadius.circular(8),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasAnyData() {
    switch (_currentView) {
      case PerformanceType.shooting:
        return widget.shots.isNotEmpty;
      case PerformanceType.skating:
        return widget.skatings.isNotEmpty;
      case PerformanceType.combined:
        return widget.shots.isNotEmpty || widget.skatings.isNotEmpty;
    }
  }
  
  Widget _buildCompactStatsBar() {
    switch (_currentView) {
      case PerformanceType.shooting:
        return _buildShootingStatsBar();
      case PerformanceType.skating:
        return _buildSkatingStatsBar(); // NEW
      case PerformanceType.combined:
        return _buildCombinedStatsBar(); // NEW
    }
  }

  Widget _buildShootingStatsBar() {
    // FIXED: Use safe numeric casting
    final successRate = ((widget.analytics['overall_success_rate'] as num?)?.toDouble() ?? 0) * 100;
    final avgPower = (widget.analytics['average_power'] as num?)?.toDouble() ?? 0;
    final avgQuickRelease = (widget.analytics['average_quick_release'] as num?)?.toDouble() ?? 0;
    final totalShots = widget.analytics['total_shots'] as int? ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            _buildCompactStat(
              Icons.check_circle_outline,
              'Success Rate',
              '${successRate.toStringAsFixed(1)}%',
              ColorHelper.getSuccessRateColor(successRate / 100),
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.bolt,
              'Power',
              '${avgPower.toStringAsFixed(1)}',
              ColorHelper.getPowerColor(avgPower),
              suffix: 'mph',
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.timer,
              'Release',
              '${avgQuickRelease.toStringAsFixed(2)}',
              ColorHelper.getQuickReleaseColor(avgQuickRelease),
              suffix: 'sec',
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.sports_hockey,
              'Total',
              '$totalShots',
              Colors.blueGrey[600]!,
              suffix: 'shots',
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Skating stats bar
  Widget _buildSkatingStatsBar() {
    final skatingAnalytics = widget.skatingAnalytics ?? {};
    // FIXED: Use safe numeric casting
    final overallScore = (skatingAnalytics['overall_score'] as num?)?.toDouble() ?? 0;
    final totalSessions = skatingAnalytics['total_sessions'] as int? ?? 0;
    final assessmentCount = skatingAnalytics['assessment_count'] as int? ?? 0;
    final avgSpeed = (skatingAnalytics['average_speed'] as num?)?.toDouble() ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            _buildCompactStat(
              Icons.assessment,
              'Overall Score',
              '${overallScore.toStringAsFixed(1)}',
              _getScoreColor(overallScore),
              suffix: '/10',
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.speed,
              'Avg Speed',
              '${avgSpeed.toStringAsFixed(1)}',
              Colors.blue,
              suffix: 's',
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.check_circle,
              'Assessments',
              '$assessmentCount',
              Colors.green,
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.sports,
              'Sessions',
              '$totalSessions',
              Colors.blueGrey[600]!,
            ),
          ],
        ),
      ),
    );
  }

  // NEW: Combined stats bar
  Widget _buildCombinedStatsBar() {
    // FIXED: Use safe numeric casting
    final shotSuccessRate = ((widget.analytics['overall_success_rate'] as num?)?.toDouble() ?? 0.0) * 100;
    final skatingScore = (widget.skatingAnalytics?['overall_score'] as num?)?.toDouble() ?? 0;
    final totalShots = widget.analytics['total_shots'] as int? ?? 0;
    final totalSkatingSessions = widget.skatingAnalytics?['total_sessions'] as int? ?? 0;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Row(
          children: [
            _buildCompactStat(
              Icons.sports_hockey,
              'Shot Success',
              '${shotSuccessRate.toStringAsFixed(1)}%',
              ColorHelper.getSuccessRateColor(shotSuccessRate / 100),
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.speed,
              'Skating Score',
              '${skatingScore.toStringAsFixed(1)}',
              _getScoreColor(skatingScore),
              suffix: '/10',
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.sports_hockey,
              'Shots',
              '$totalShots',
              Colors.blue,
            ),
            _buildStatDivider(),
            _buildCompactStat(
              Icons.sports,
              'Skating',
              '$totalSkatingSessions',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.lightGreen;
    if (score >= 4.0) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildCompactStat(IconData icon, String label, String value, Color color, {String? suffix}) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blueGrey[500],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              if (suffix != null) ...[
                const SizedBox(width: 2),
                Text(
                  suffix,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
      margin: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
  
  Widget _buildFilterToggle() {
    String title;
    switch (_currentView) {
      case PerformanceType.shooting:
        title = 'Shooting Analysis';
        break;
      case PerformanceType.skating:
        title = 'Skating Analysis';
        break;
      case PerformanceType.combined:
        title = 'Combined Performance Analysis';
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        TextButton.icon(
          onPressed: () => setState(() => _showFilters = !_showFilters),
          icon: Icon(
            _showFilters ? Icons.expand_less : Icons.expand_more,
            size: 20,
          ),
          label: Text(_showFilters ? 'Hide Filters' : 'Filter'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blueGrey[600],
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_currentView == PerformanceType.shooting || _currentView == PerformanceType.combined) ...[
            Text(
              'Shot Type Filter:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 8),
            FilterChipGroup<String>(
              options: _availableShotTypes,
              selectedOptions: _selectedShotTypes,
              onSelected: _onShotTypeFilterChanged,
              labelBuilder: (option) => option,
              selectedColor: Colors.blue,
            ),
            if (_currentView == PerformanceType.combined) const SizedBox(height: 16),
          ],
          
          // NEW: Skating filters
          if (_currentView == PerformanceType.skating || _currentView == PerformanceType.combined) ...[
            Text(
              'Skating Session Filter:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 8),
            FilterChipGroup<String>(
              options: _availableSkatingTypes,
              selectedOptions: _selectedSkatingTypes,
              onSelected: _onSkatingTypeFilterChanged,
              labelBuilder: (option) => option,
              selectedColor: Colors.green,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    String title;
    String subtitle;
    Widget actionButton;

    switch (_currentView) {
      case PerformanceType.shooting:
        title = 'No Shot Data';
        subtitle = 'Take shooting assessments to see performance analytics';
        actionButton = ElevatedButton.icon(
          onPressed: _navigateToShotAssessment, // UPDATED: Navigate to assessment
          icon: const Icon(Icons.assessment),
          label: const Text('Take Shot Assessment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
      case PerformanceType.skating:
        title = 'No Skating Data';
        subtitle = 'Take skating assessments to see performance analytics';
        actionButton = ElevatedButton.icon(
          onPressed: _navigateToSkatingAssessment, // UPDATED: Navigate to assessment
          icon: const Icon(Icons.assessment),
          label: const Text('Take Skating Assessment'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        break;
      case PerformanceType.combined:
        title = 'No Performance Data';
        subtitle = 'Take assessments to see analytics';
        actionButton = Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _navigateToShotAssessment, // UPDATED: Navigate to assessment
              icon: const Icon(Icons.assessment),
              label: const Text('Shot Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _navigateToSkatingAssessment, // UPDATED: Navigate to assessment
              icon: const Icon(Icons.assessment),
              label: const Text('Skating Assessment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        );
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _currentView == PerformanceType.shooting ? Icons.sports_hockey :
            _currentView == PerformanceType.skating ? Icons.speed : Icons.analytics,
            size: 64,
            color: Colors.blueGrey[300],
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 24),
          actionButton,
        ],
      ),
    );
  }
  
  Widget _buildChartsSection() {
    switch (_currentView) {
      case PerformanceType.shooting:
        return _buildShootingCharts();
      case PerformanceType.skating:
        return _buildSkatingCharts(); // NEW
      case PerformanceType.combined:
        return _buildCombinedCharts(); // NEW
    }
  }

  Widget _buildShootingCharts() {
    if (widget.weeklyTrends.isEmpty && _filteredShots.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final chartData = _prepareChartData(widget.weeklyTrends);
    
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (chartData.isNotEmpty) ...[
                    Expanded(child: _buildSuccessRateChart(chartData)),
                    const SizedBox(width: 12),
                  ],
                  if (_filteredShots.isNotEmpty)
                    Expanded(child: _buildShotDistributionChart()),
                ],
              );
            } else {
              return Column(
                children: [
                  if (chartData.isNotEmpty) ...[
                    _buildSuccessRateChart(chartData),
                    const SizedBox(height: 12),
                  ],
                  if (_filteredShots.isNotEmpty)
                    _buildShotDistributionChart(),
                ],
              );
            }
          },
        ),
        if (chartData.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildPowerTrendChart(chartData),
        ],
      ],
    );
  }

  // NEW: Skating charts
  Widget _buildSkatingCharts() {
    if (_filteredSkatings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildSkatingProgressChart()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSkatingRadarChart()),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildSkatingProgressChart(),
                  const SizedBox(height: 12),
                  _buildSkatingRadarChart(),
                ],
              );
            }
          },
        ),
        const SizedBox(height: 12),
        _buildSkatingCategoryTrendChart(),
      ],
    );
  }

  // NEW: Combined charts
  Widget _buildCombinedCharts() {
    return Column(
      children: [
        Row(
          children: [
            if (widget.shots.isNotEmpty)
              Expanded(child: _buildShootingOverviewChart()),
            const SizedBox(width: 12),
            if (widget.skatings.isNotEmpty)
              Expanded(child: _buildSkatingOverviewChart()),
          ],
        ),
        const SizedBox(height: 12),
        _buildCombinedProgressChart(),
      ],
    );
  }

  // NEW: Skating chart widgets
  Widget _buildSkatingProgressChart() {
    return StandardCard(
      title: 'Skating Progress',
      headerIcon: Icons.trending_up,
      headerIconColor: Colors.green,
      elevation: 1,
      child: SizedBox(
        height: 180,
        child: InteractiveTrendChart(
          playerId: widget.player.id!,
          dateRange: 90,
          interval: 'week',
          metric: 'skating_overall_score',
          title: '',
          subtitle: '',
          lineColor: Colors.green,
          yAxisLabel: 'Score',
          enableZoom: false,
          valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}',
        ),
      ),
    );
  }

  Widget _buildSkatingRadarChart() {
    // Extract skating categories from recent assessments
    final recentAssessments = _filteredSkatings.where((s) => s.isAssessment).toList();
    if (recentAssessments.isEmpty) {
      return StandardCard(
        title: 'Skating Categories',
        headerIcon: Icons.radar,
        headerIconColor: Colors.purple,
        elevation: 1,
        child: const SizedBox(
          height: 180,
          child: Center(
            child: Text('No assessment data available'),
          ),
        ),
      );
    }

    final latestAssessment = recentAssessments.first;
    final categoryScores = latestAssessment.scores;
    
    return StandardCard(
      title: 'Skating Categories',
      headerIcon: Icons.radar,
      headerIconColor: Colors.purple,
      elevation: 1,
      child: SizedBox(
        height: 180,
        child: RadarChartWidget.playerSkills(
          playerSkills: Map<String, double>.from(categoryScores),
          title: '',
          subtitle: '',
          playerName: widget.player.name,
        ),
      ),
    );
  }

  Widget _buildSkatingCategoryTrendChart() {
    return StandardCard(
      title: 'Category Development',
      headerIcon: Icons.multiline_chart,
      headerIconColor: Colors.orange,
      elevation: 1,
      child: SizedBox(
        height: 180,
        child: InteractiveTrendChart(
          playerId: widget.player.id!,
          dateRange: 180,
          interval: 'month',
          metric: 'skating_categories',
          title: '',
          subtitle: '',
          lineColor: Colors.orange,
          yAxisLabel: 'Category Score',
          enableZoom: false,
          valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}',
        ),
      ),
    );
  }

  Widget _buildShootingOverviewChart() {
    return StandardCard(
      title: 'Shooting Overview',
      headerIcon: Icons.sports_hockey,
      headerIconColor: Colors.blue,
      elevation: 1,
      child: SizedBox(
        height: 120,
        child: _buildMiniSuccessRateChart(),
      ),
    );
  }

  Widget _buildSkatingOverviewChart() {
    return StandardCard(
      title: 'Skating Overview',
      headerIcon: Icons.speed,
      headerIconColor: Colors.green,
      elevation: 1,
      child: SizedBox(
        height: 120,
        child: _buildMiniSkatingChart(),
      ),
    );
  }

  Widget _buildCombinedProgressChart() {
    return StandardCard(
      title: 'Overall Development',
      headerIcon: Icons.analytics,
      headerIconColor: Colors.purple,
      elevation: 1,
      child: SizedBox(
        height: 200,
        child: InteractiveTrendChart(
          playerId: widget.player.id!,
          dateRange: 180,
          interval: 'month',
          metric: 'combined_performance',
          title: '',
          subtitle: '',
          lineColor: Colors.purple,
          yAxisLabel: 'Performance Index',
          enableZoom: true,
          valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}',
        ),
      ),
    );
  }

  // Placeholder widgets for mini charts
  Widget _buildMiniSuccessRateChart() {
    final successRate = ((widget.analytics['overall_success_rate'] as num?)?.toDouble() ?? 0) * 100;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${successRate.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const Text('Success Rate'),
        ],
      ),
    );
  }

  Widget _buildMiniSkatingChart() {
    final overallScore = (widget.skatingAnalytics?['overall_score'] as num?)?.toDouble() ?? 0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${overallScore.toStringAsFixed(1)}/10',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const Text('Overall Score'),
        ],
      ),
    );
  }
  
  Widget _buildSuccessRateChart(List<Map<String, dynamic>> chartData) {
    return StandardCard(
      title: 'Success Rate Trend',
      headerIcon: Icons.trending_up,
      headerIconColor: Colors.green,
      elevation: 1,
      child: SizedBox(
        height: 180,
        child: VolumeTrendChart(weeklyTrends: chartData),
      ),
    );
  }
  
  Widget _buildPowerTrendChart(List<Map<String, dynamic>> chartData) {
    return StandardCard(
      title: 'Power Development',
      headerIcon: Icons.bolt,
      headerIconColor: Colors.orange,
      elevation: 1,
      child: SizedBox(
        height: 180,
        child: PowerTrendChart(weeklyTrends: chartData),
      ),
    );
  }
  
  Widget _buildShotDistributionChart() {
    return StandardCard(
      title: 'Shot Types',
      headerIcon: Icons.pie_chart,
      headerIconColor: Colors.purple,
      elevation: 1,
      child: SizedBox(
        height: 300,
        child: ShotDistributionChart(filteredShots: _filteredShots),
      ),
    );
  }
  
  Widget _buildRecentActivity() {
    switch (_currentView) {
      case PerformanceType.shooting:
        return _buildRecentShotActivity();
      case PerformanceType.skating:
        return _buildRecentSkatingActivity(); // NEW
      case PerformanceType.combined:
        return _buildRecentCombinedActivity(); // NEW
    }
  }

  Widget _buildRecentShotActivity() {
    final latestShots = List<Shot>.from(_filteredShots)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final recentShots = latestShots.take(8).toList();
    
    if (recentShots.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return StandardCard(
      title: 'Recent Shot Activity',
      headerIcon: Icons.history,
      headerIconColor: Colors.blueGrey[600],
      elevation: 1,
      child: Column(
        children: [
          if (widget.onViewHistory != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onViewHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
          ...recentShots.map((shot) => _buildShotActivityItem(shot)).toList(),
        ],
      ),
    );
  }

  // NEW: Recent skating activity
  Widget _buildRecentSkatingActivity() {
    final latestSkatings = List<Skating>.from(_filteredSkatings)
      ..sort((a, b) => b.date.compareTo(a.date));
    
    final recentSkatings = latestSkatings.take(8).toList();
    
    if (recentSkatings.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return StandardCard(
      title: 'Recent Skating Activity',
      headerIcon: Icons.history,
      headerIconColor: Colors.blueGrey[600],
      elevation: 1,
      child: Column(
        children: [
          if (widget.onViewHistory != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onViewHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
          ...recentSkatings.map((skating) => _buildSkatingActivityItem(skating)).toList(),
        ],
      ),
    );
  }

  // NEW: Combined recent activity
  Widget _buildRecentCombinedActivity() {
    // Combine and sort recent shots and skating sessions
    final combinedActivities = <Map<String, dynamic>>[];
    
    for (final shot in _filteredShots) {
      combinedActivities.add({
        'type': 'shot',
        'data': shot,
        'timestamp': shot.timestamp,
      });
    }
    
    for (final skating in _filteredSkatings) {
      combinedActivities.add({
        'type': 'skating',
        'data': skating,
        'timestamp': skating.date,
      });
    }
    
    combinedActivities.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));
    final recentActivities = combinedActivities.take(8).toList();
    
    if (recentActivities.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return StandardCard(
      title: 'Recent Activity',
      headerIcon: Icons.history,
      headerIconColor: Colors.blueGrey[600],
      elevation: 1,
      child: Column(
        children: [
          if (widget.onViewHistory != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onViewHistory,
                  child: const Text('View All'),
                ),
              ],
            ),
          ...recentActivities.map((activity) {
            if (activity['type'] == 'shot') {
              return _buildShotActivityItem(activity['data'] as Shot);
            } else {
              return _buildSkatingActivityItem(activity['data'] as Skating);
            }
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildShotActivityItem(Shot shot) {
    final isSuccess = shot.success;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSuccess ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MM/dd HH:mm').format(shot.timestamp),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.sports_hockey, size: 16, color: Colors.blue),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              shot.type ?? 'Shot',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
                fontSize: 13,
              ),
            ),
          ),
          if (shot.power != null)
            Text(
              '${shot.power!.toStringAsFixed(0)}mph',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blueGrey[500],
              ),
            ),
        ],
      ),
    );
  }

  // NEW: Skating activity item
  Widget _buildSkatingActivityItem(Skating skating) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: skating.isAssessment ? Colors.blue : Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            DateFormat('MM/dd HH:mm').format(skating.date),
            style: TextStyle(
              fontSize: 12,
              color: Colors.blueGrey[500],
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 12),
          Icon(Icons.speed, size: 16, color: Colors.green),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              skating.sessionTypeDisplay,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
                fontSize: 13,
              ),
            ),
          ),
          if (skating.performanceLevel != null)
            Text(
              skating.performanceLevel!,
              style: TextStyle(
                fontSize: 11,
                color: Colors.blueGrey[500],
              ),
            ),
        ],
      ),
    );
  }
  
  List<Map<String, dynamic>> _prepareChartData(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    
    if (data.first.containsKey('weekStart')) return data;
    
    final result = <Map<String, dynamic>>[];
    
    for (var item in data) {
      final newItem = Map<String, dynamic>.from(item);
      
      if (item.containsKey('date') && item['date'] is String) {
        newItem['weekStart'] = DateTime.parse(item['date'] as String);
      } else {
        newItem['weekStart'] = DateTime.now();
      }
      
      result.add(newItem);
    }
    
    return result;
  }
}