import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/player_analytics_service.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/toggle_button_group.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/interactive_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/radar_chart_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/scatter_plot_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/performance_metrics_card.dart';
import 'package:hockey_shot_tracker/utils/analytics_constants.dart';

enum AnalyticsType { shooting, skating, combined }

class PlayerAnalyticsTab extends StatefulWidget {
  final Player player;
  final PlayerAnalyticsService analyticsService;

  const PlayerAnalyticsTab({
    Key? key,
    required this.player,
    required this.analyticsService,
  }) : super(key: key);

  @override
  State<PlayerAnalyticsTab> createState() => _PlayerAnalyticsTabState();
}

class _PlayerAnalyticsTabState extends State<PlayerAnalyticsTab> {
  AnalyticsType _currentAnalyticsType = AnalyticsType.shooting;
  String _selectedTimeRange = '90 days';
  
  // Shooting analytics data
  Map<String, dynamic> _shootingAnalyticsData = {};
  List<Map<String, dynamic>> _shootingTrendData = [];
  
  // NEW: Skating analytics data
  Map<String, dynamic> _skatingAnalyticsData = {};
  Map<String, dynamic> _skatingTrendData = {};
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playerId = widget.player.id;
      if (playerId == null) {
        throw Exception('Player ID is null');
      }

      final dateRange = _selectedTimeRange == '7 days'
          ? 7
          : _selectedTimeRange == '30 days'
              ? 30
              : _selectedTimeRange == '90 days'
                  ? 90
                  : 365;

      // Fetch shooting analytics
      final shootingAnalytics = await widget.analyticsService.fetchAnalytics(playerId);
      final shootingTrendData = await widget.analyticsService.fetchTrendData(
        playerId,
        dateRange: dateRange,
      );

      // NEW: Fetch skating analytics
      final skatingAnalytics = await widget.analyticsService.fetchSkatingAnalytics(playerId);
      final skatingTrendData = await widget.analyticsService.fetchSkatingTrendData(
        playerId,
        filters: {
          'days': dateRange,
          'interval': 'week',
        },
      );

      setState(() {
        _shootingAnalyticsData = shootingAnalytics;
        _shootingTrendData = shootingTrendData;
        _skatingAnalyticsData = skatingAnalytics;
        _skatingTrendData = skatingTrendData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading analytics: $e')),
      );
    }
  }

  void _onTimeRangeChanged(String range) {
    setState(() {
      _selectedTimeRange = range;
    });
    _fetchAnalytics();
  }

  void _onAnalyticsTypeChanged(AnalyticsType type) {
    setState(() {
      _currentAnalyticsType = type;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsTypeSelector(),
          const SizedBox(height: 16),
          _buildTimeRangeSelector(),
          const SizedBox(height: 16),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTypeSelector() {
    return StandardCard(
      title: 'Analytics View',
      headerIcon: Icons.analytics,
      child: ToggleButtonGroup<AnalyticsType>(
        options: const [AnalyticsType.shooting, AnalyticsType.skating, AnalyticsType.combined],
        selectedOption: _currentAnalyticsType,
        onSelected: _onAnalyticsTypeChanged,
        labelBuilder: (type) {
          switch (type) {
            case AnalyticsType.shooting:
              return 'Shooting';
            case AnalyticsType.skating:
              return 'Skating';
            case AnalyticsType.combined:
              return 'Combined';
          }
        },
        defaultSelectedColor: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return ToggleButtonGroup<String>(
      options: const ['7 days', '30 days', '90 days', '365 days'],
      selectedOption: _selectedTimeRange,
      onSelected: _onTimeRangeChanged,
      labelBuilder: (option) => option,
      defaultSelectedColor: Colors.blue,
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildContent() {
    switch (_currentAnalyticsType) {
      case AnalyticsType.shooting:
        return _buildShootingAnalytics();
      case AnalyticsType.skating:
        return _buildSkatingAnalytics();
      case AnalyticsType.combined:
        return _buildCombinedAnalytics();
    }
  }

  Widget _buildShootingAnalytics() {
    if (_shootingAnalyticsData.isEmpty) {
      return _buildEmptyState('shooting');
    }

    return Column(
      children: [
        _buildShootingSummaryCard(),
        const SizedBox(height: 16),
        _buildShootingTrendChart(),
        const SizedBox(height: 16),
        _buildShootingScatterPlot(),
        const SizedBox(height: 16),
        _buildShootingStrengthsWeaknesses(),
      ],
    );
  }

  Widget _buildSkatingAnalytics() {
    if (_skatingAnalyticsData.isEmpty) {
      return _buildEmptyState('skating');
    }

    return Column(
      children: [
        _buildSkatingSummaryCard(),
        const SizedBox(height: 16),
        _buildSkatingRadarChart(),
        const SizedBox(height: 16),
        _buildSkatingTrendChart(),
        const SizedBox(height: 16),
        _buildSkatingCategoriesAnalysis(),
        const SizedBox(height: 16),
        _buildSkatingStrengthsWeaknesses(),
      ],
    );
  }

  Widget _buildCombinedAnalytics() {
    final hasShootingData = _shootingAnalyticsData.isNotEmpty;
    final hasSkatingData = _skatingAnalyticsData.isNotEmpty;

    if (!hasShootingData && !hasSkatingData) {
      return _buildEmptyState('combined');
    }

    return Column(
      children: [
        _buildCombinedOverviewCard(),
        const SizedBox(height: 16),
        if (hasShootingData && hasSkatingData) ...[
          _buildPerformanceComparisonChart(),
          const SizedBox(height: 16),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasShootingData)
              Expanded(child: _buildShootingMiniSummary()),
            if (hasShootingData && hasSkatingData) const SizedBox(width: 16),
            if (hasSkatingData)
              Expanded(child: _buildSkatingMiniSummary()),
          ],
        ),
        const SizedBox(height: 16),
        _buildCombinedStrengthsWeaknesses(),
      ],
    );
  }

  Widget _buildShootingSummaryCard() {
    return StandardCard(
      title: 'Shooting Performance Summary',
      headerIcon: Icons.sports_hockey,
      child: Column(
        children: [
          _buildSummaryRow('Total Shots', _shootingAnalyticsData['total_shots']?.toString() ?? '0'),
          _buildSummaryRow('Successful Shots', _shootingAnalyticsData['successful_shots']?.toString() ?? '0'),
          _buildSummaryRow(
            'Success Rate',
            '${(((_shootingAnalyticsData['overall_success_rate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%',
          ),
          _buildSummaryRow(
            'Average Power',
            _shootingAnalyticsData['average_power'] != null
                ? '${(_shootingAnalyticsData['average_power'] as num?)?.toDouble()?.toStringAsFixed(1) ?? 'N/A'} mph'
                : 'N/A',
          ),
          _buildSummaryRow(
            'Average Quick Release',
            _shootingAnalyticsData['average_quick_release'] != null
                ? '${(_shootingAnalyticsData['average_quick_release'] as num?)?.toDouble()?.toStringAsFixed(2) ?? 'N/A'} sec'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildSkatingSummaryCard() {
    return StandardCard(
      title: 'Skating Performance Summary',
      headerIcon: Icons.speed,
      child: Column(
        children: [
          _buildSummaryRow('Total Sessions', _skatingAnalyticsData['total_sessions']?.toString() ?? '0'),
          _buildSummaryRow('Assessments', _skatingAnalyticsData['assessment_count']?.toString() ?? '0'),
          _buildSummaryRow(
            'Overall Score',
            '${(_skatingAnalyticsData['overall_score'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'}/10',
          ),
          _buildSummaryRow(
            'Performance Level',
            _skatingAnalyticsData['performance_level']?.toString() ?? 'N/A',
          ),
          _buildSummaryRow(
            'Average Speed',
            _skatingAnalyticsData['average_speed'] != null
                ? '${(_skatingAnalyticsData['average_speed'] as num?)?.toDouble()?.toStringAsFixed(2) ?? 'N/A'} sec'
                : 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedOverviewCard() {
    // FIXED: Use safe numeric casting
    final shootingScore = (_shootingAnalyticsData['overall_success_rate'] as num?)?.toDouble() ?? 0.0;
    final skatingScore = (_skatingAnalyticsData['overall_score'] as num?)?.toDouble() ?? 0.0;
    final combinedScore = (shootingScore * 100 + skatingScore * 10) / 2; // Normalize and average
    
    return StandardCard(
      title: 'Combined Performance Overview',
      headerIcon: Icons.analytics,
      child: Column(
        children: [
          _buildSummaryRow(
            'Combined Performance Score',
            '${combinedScore.toStringAsFixed(1)}/100',
          ),
          _buildSummaryRow(
            'Shooting Success Rate',
            '${(shootingScore * 100).toStringAsFixed(1)}%',
          ),
          _buildSummaryRow(
            'Skating Overall Score',
            '${skatingScore.toStringAsFixed(1)}/10',
          ),
          _buildSummaryRow(
            'Total Training Sessions',
            '${(_shootingAnalyticsData['total_shots'] as int? ?? 0) + (_skatingAnalyticsData['total_sessions'] as int? ?? 0)}',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blueGrey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShootingTrendChart() {
    if (_shootingTrendData.isEmpty) {
      return const SizedBox.shrink();
    }

    return StandardCard(
      title: 'Shooting Success Rate Trend',
      headerIcon: Icons.trending_up,
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            barGroups: _shootingTrendData.asMap().entries.map((entry) {
              final index = entry.key;
              final datum = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: (datum['success_rate'] as num?)?.toDouble() ?? 0.0,
                    color: Colors.blue,
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index >= 0 && index < _shootingTrendData.length) {
                      return Text(
                        _shootingTrendData[index]['date'] ?? '',
                        style: const TextStyle(fontSize: 10),
                        textAlign: TextAlign.center,
                      );
                    }
                    return const Text('');
                  },
                  reservedSize: 40,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: const FlGridData(show: false),
          ),
        ),
      ),
    );
  }

  Widget _buildShootingScatterPlot() {
    return StandardCard(
      title: 'Power vs Success Rate',
      headerIcon: Icons.scatter_plot,
      child: SizedBox(
        height: 200,
        child: ScatterPlotChart.powerVsSuccess(
          playerId: widget.player.id!,
          dateRange: _selectedTimeRange == '7 days' ? 7 :
                    _selectedTimeRange == '30 days' ? 30 :
                    _selectedTimeRange == '90 days' ? 90 : 365,
          showTrendLine: true,
        ),
      ),
    );
  }

  Widget _buildSkatingTrendChart() {
    return StandardCard(
      title: 'Skating Progress Trend',
      headerIcon: Icons.trending_up,
      child: SizedBox(
        height: 200,
        child: InteractiveTrendChart(
          playerId: widget.player.id!,
          dateRange: _selectedTimeRange == '7 days' ? 7 :
                    _selectedTimeRange == '30 days' ? 30 :
                    _selectedTimeRange == '90 days' ? 90 : 365,
          interval: 'week',
          metric: 'skating_overall_score',
          title: '',
          subtitle: '',
          lineColor: Colors.green,
          yAxisLabel: 'Score',
          enableZoom: true,
          valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}',
        ),
      ),
    );
  }

  Widget _buildSkatingRadarChart() {
    final categoryScores = _skatingAnalyticsData['category_scores'] as Map<String, dynamic>? ?? {};
    
    if (categoryScores.isEmpty) {
      return StandardCard(
        title: 'Skating Categories',
        headerIcon: Icons.radar,
        child: const SizedBox(
          height: 200,
          child: Center(
            child: Text('No category data available'),
          ),
        ),
      );
    }

    return StandardCard(
      title: 'Skating Categories Performance',
      headerIcon: Icons.radar,
      child: SizedBox(
        height: 300,
        child: RadarChartWidget.playerSkills(
          playerSkills: Map<String, double>.from(categoryScores),
          title: '',
          subtitle: '',
          playerName: widget.player.name,
        ),
      ),
    );
  }

  Widget _buildSkatingCategoriesAnalysis() {
    final categoryScores = _skatingAnalyticsData['category_scores'] as Map<String, dynamic>? ?? {};
    
    if (categoryScores.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedCategories = categoryScores.entries.toList()
      ..sort((a, b) => (b.value as double).compareTo(a.value as double));

    return StandardCard(
      title: 'Skating Categories Breakdown',
      headerIcon: Icons.category,
      child: Column(
        children: sortedCategories.map((entry) {
          final category = entry.key;
          final score = (entry.value as num).toDouble(); // FIXED: Safe casting
          final percentage = (score / 10) * 100; // Convert to percentage
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${score.toStringAsFixed(1)}/10',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getCategoryColor(score),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _getCategoryColor(double score) {
    if (score >= 8.0) return Colors.green;
    if (score >= 6.0) return Colors.lightGreen;
    if (score >= 4.0) return Colors.orange;
    return Colors.red;
  }

  Widget _buildPerformanceComparisonChart() {
    // FIXED: Use safe numeric casting
    final shootingScore = (_shootingAnalyticsData['overall_success_rate'] as num?)?.toDouble() ?? 0.0;
    final skatingScore = (_skatingAnalyticsData['overall_score'] as num?)?.toDouble() ?? 0.0;
    
    return StandardCard(
      title: 'Performance Comparison',
      headerIcon: Icons.compare_arrows,
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Shooting',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircularProgressIndicator(
                    value: shootingScore,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    strokeWidth: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(shootingScore * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Skating',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CircularProgressIndicator(
                    value: skatingScore / 10,
                    backgroundColor: Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                    strokeWidth: 8,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${skatingScore.toStringAsFixed(1)}/10',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShootingMiniSummary() {
    return StandardCard(
      title: 'Shooting Summary',
      headerIcon: Icons.sports_hockey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Shots: ${_shootingAnalyticsData['total_shots'] ?? 0}'),
          Text('Success Rate: ${(((_shootingAnalyticsData['overall_success_rate'] as num?)?.toDouble() ?? 0.0) * 100).toStringAsFixed(1)}%'),
          if (_shootingAnalyticsData['average_power'] != null)
            Text('Avg Power: ${(_shootingAnalyticsData['average_power'] as num?)?.toDouble()?.toStringAsFixed(1) ?? 'N/A'} mph'),
        ],
      ),
    );
  }

  Widget _buildSkatingMiniSummary() {
    return StandardCard(
      title: 'Skating Summary',
      headerIcon: Icons.speed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Sessions: ${_skatingAnalyticsData['total_sessions'] ?? 0}'),
          Text('Overall Score: ${(_skatingAnalyticsData['overall_score'] as num?)?.toDouble()?.toStringAsFixed(1) ?? '0.0'}/10'),
          Text('Performance: ${_skatingAnalyticsData['performance_level'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildShootingStrengthsWeaknesses() {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.player.id != null
          ? widget.analyticsService.fetchPlayerAssessment(widget.player.id!)
          : Future.value({}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const StandardCard(
            title: 'Shooting Assessment',
            headerIcon: Icons.assessment,
            child: Text('Unable to load shooting assessment'),
          );
        }

        return _buildStrengthsWeaknessesCard(
          'Shooting Strengths & Areas for Improvement',
          Icons.sports_hockey,
          snapshot.data!,
        );
      },
    );
  }

  Widget _buildSkatingStrengthsWeaknesses() {
    return FutureBuilder<Map<String, dynamic>>(
      future: widget.player.id != null
          ? widget.analyticsService.fetchPlayerSkatingAssessment(widget.player.id!)
          : Future.value({}),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const StandardCard(
            title: 'Skating Assessment',
            headerIcon: Icons.speed,
            child: Text('Unable to load skating assessment'),
          );
        }

        return _buildStrengthsWeaknessesCard(
          'Skating Strengths & Areas for Improvement',
          Icons.speed,
          snapshot.data!,
        );
      },
    );
  }

  Widget _buildCombinedStrengthsWeaknesses() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: widget.player.id != null
          ? Future.wait([
              widget.analyticsService.fetchPlayerAssessment(widget.player.id!),
              widget.analyticsService.fetchPlayerSkatingAssessment(widget.player.id!),
            ])
          : Future.value([{}, {}]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const StandardCard(
            title: 'Combined Assessment',
            headerIcon: Icons.assessment,
            child: Text('Unable to load assessment data'),
          );
        }

        final shootingAssessment = snapshot.data!.isNotEmpty ? snapshot.data![0] : <String, dynamic>{};
        final skatingAssessmentRaw = snapshot.data!.length > 1 ? snapshot.data![1] : <String, dynamic>{};
        
        // FIXED: Convert Map<dynamic, dynamic> to Map<String, dynamic>
        final skatingAssessment = Map<String, dynamic>.from(skatingAssessmentRaw);

        return _buildCombinedStrengthsWeaknessesCard(shootingAssessment, skatingAssessment);
      },
    );
  }

  Widget _buildStrengthsWeaknessesCard(String title, IconData icon, Map<String, dynamic> assessment) {
    final strengthsRaw = assessment['strengths'] as List? ?? [];
    final weaknessesRaw = assessment['weaknesses'] as List? ?? [];
    
    final strengths = strengthsRaw.map((item) {
      if (item is String) {
        return item;
      } else if (item is Map<String, dynamic>) {
        return item['description'] as String? ?? 
               item['text'] as String? ?? 
               item['name'] as String? ?? 
               item.toString();
      } else {
        return item.toString();
      }
    }).toList();
    
    final weaknesses = weaknessesRaw.map((item) {
      if (item is String) {
        return item;
      } else if (item is Map<String, dynamic>) {
        return item['description'] as String? ?? 
               item['text'] as String? ?? 
               item['name'] as String? ?? 
               item.toString();
      } else {
        return item.toString();
      }
    }).toList();

    return StandardCard(
      title: title,
      headerIcon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (strengths.isNotEmpty) ...[
            Text(
              'Strengths',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.green[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          s,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],
          
          if (weaknesses.isNotEmpty) ...[
            Text(
              'Areas for Improvement',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 8),
            ...weaknesses.map((w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange[700],
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          w,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          
          if (strengths.isEmpty && weaknesses.isEmpty) ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      Icons.assessment_outlined,
                      size: 48,
                      color: Colors.blueGrey[300],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No assessment data available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCombinedStrengthsWeaknessesCard(
    Map<String, dynamic> shootingAssessment,
    Map<String, dynamic> skatingAssessment,
  ) {
    return StandardCard(
      title: 'Combined Assessment - Strengths & Areas for Improvement',
      headerIcon: Icons.assessment,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              labelColor: Colors.blueGrey[800],
              unselectedLabelColor: Colors.blueGrey[500],
              indicatorColor: Colors.blue,
              tabs: const [
                Tab(
                  icon: Icon(Icons.sports_hockey),
                  text: 'Shooting',
                ),
                Tab(
                  icon: Icon(Icons.speed),
                  text: 'Skating',
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: TabBarView(
                children: [
                  _buildAssessmentContent(shootingAssessment),
                  _buildAssessmentContent(skatingAssessment),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentContent(Map<String, dynamic> assessment) {
    if (assessment.isEmpty) {
      return const Center(
        child: Text('No assessment data available'),
      );
    }

    final strengthsRaw = assessment['strengths'] as List? ?? [];
    final weaknessesRaw = assessment['weaknesses'] as List? ?? [];
    
    final strengths = strengthsRaw.map((item) => item.toString()).toList();
    final weaknesses = weaknessesRaw.map((item) => item.toString()).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (strengths.isNotEmpty) ...[
            Text(
              'Strengths',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            ...strengths.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $s', style: TextStyle(color: Colors.green[600])),
                )),
            const SizedBox(height: 12),
          ],
          if (weaknesses.isNotEmpty) ...[
            Text(
              'Areas for Improvement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.orange[700],
              ),
            ),
            ...weaknesses.map((w) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $w', style: TextStyle(color: Colors.orange[600])),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    String title;
    String subtitle;
    IconData icon;

    switch (type) {
      case 'shooting':
        title = 'No Shooting Analytics Available';
        subtitle = 'Record shots to view analytics';
        icon = Icons.sports_hockey;
        break;
      case 'skating':
        title = 'No Skating Analytics Available';
        subtitle = 'Complete skating assessments to view analytics';
        icon = Icons.speed;
        break;
      case 'combined':
        title = 'No Analytics Available';
        subtitle = 'Record shots and complete skating assessments to view analytics';
        icon = Icons.analytics;
        break;
      default:
        title = 'No Analytics Available';
        subtitle = 'Start training to view analytics';
        icon = Icons.analytics;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
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
        ],
      ),
    );
  }
}