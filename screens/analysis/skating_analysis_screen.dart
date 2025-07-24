import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/performance_metrics_card.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/recommendations_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/skating_categories_analysis_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/skating_benchmarks_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/scatter_plot_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/interactive_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/radar_chart_widget.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/filter_chip_group.dart';
import 'package:hockey_shot_tracker/utils/analytics_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class SkatingAnalysisScreen extends StatefulWidget {
  final Player player;

  const SkatingAnalysisScreen({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  _SkatingAnalysisScreenState createState() => _SkatingAnalysisScreenState();
}

class _SkatingAnalysisScreenState extends State<SkatingAnalysisScreen> {
  String _selectedTimeRange = '3 Months';
  final List<String> _selectedTestTypes = [];
  List<String> _availableTestTypes = [];
  final List<String> _timeRanges = ['All time', '7 days', '30 days', '90 days', '1 year'];
  bool _isLoading = true;
  Map<String, dynamic> _filters = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAvailableTestTypes();
  }

  Future<void> _fetchAvailableTestTypes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch available skating test types from API or use defaults
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/skating/test-types'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        setState(() {
          _availableTestTypes = List<String>.from(data['test_types'] ?? []);
          _isLoading = false;
          _updateFilters();
        });
      } else {
        setState(() {
          _error = 'Failed to load test types';
          _isLoading = false;

          // Use default test types if API fails
          _availableTestTypes = [
            'Forward Sprint',
            'Backward Sprint', 
            'Lateral Agility',
            'Transition Test',
            'Stop & Start',
            'Figure 8'
          ];
          _updateFilters();
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;

        // Use default test types if API fails
        _availableTestTypes = [
          'Forward Sprint',
          'Backward Sprint',
          'Lateral Agility', 
          'Transition Test',
          'Stop & Start',
          'Figure 8'
        ];
        _updateFilters();
      });
    }
  }

  void _updateFilters() {
    final Map<String, dynamic> filters = {};

    // Add time range filter
    if (_selectedTimeRange != 'All time') {
      final days = _selectedTimeRange.split(' ')[0];
      filters['date_range'] = int.parse(days);
    }

    // Add test types filter
    if (_selectedTestTypes.isNotEmpty) {
      filters['test_types'] = _selectedTestTypes;
    }

    setState(() {
      _filters = filters;
    });
  }

  void _onTimeRangeChanged(String value) {
    setState(() {
      _selectedTimeRange = value;
      _updateFilters();
    });
  }

  void _onTestTypeSelected(String value, bool selected) {
    setState(() {
      if (selected) {
        _selectedTestTypes.add(value);
      } else {
        _selectedTestTypes.remove(value);
      }
      _updateFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Skating Analysis: ${widget.player.name}'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Time Range:'),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _selectedTimeRange,
                          onChanged: (value) {
                            if (value != null) {
                              _onTimeRangeChanged(value);
                            }
                          },
                          items: _timeRanges.map((range) {
                            return DropdownMenuItem<String>(
                              value: range,
                              child: Text(range),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Test Types:'),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Text('Error: $_error', style: const TextStyle(color: Colors.red))
                    else
                      FilterChipGroup<String>(
                        options: _availableTestTypes,
                        selectedOptions: _selectedTestTypes,
                        onSelected: _onTestTypeSelected,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Performance Metrics - REUSING EXISTING WIDGET
            PerformanceMetricsCard(
              playerId: widget.player.id!,
              filters: _filters,
              skillType: SkillType.skating,
            ),
            const SizedBox(height: 24),

            // Skating Categories Radar Chart
            RadarChartWidget.playerSkills(
              playerSkills: {
                'Forward Speed': 7.5,
                'Backward Speed': 6.2,
                'Agility': 8.1,
                'Transitions': 6.8,
                'Acceleration': 7.3,
                'Balance': 7.0,
              },
              title: 'Skating Category Performance',
              subtitle: 'Current assessment scores across skating categories',
              playerName: widget.player.name,
            ),
            const SizedBox(height: 24),

            // Speed Trend Over Time - REUSING EXISTING WIDGET
            InteractiveTrendChart(
              playerId: widget.player.id!,
              dateRange: _filters['date_range'] as int? ?? 90,
              interval: 'week',
              metric: 'avg_speed',
              title: 'Speed Performance Trend',
              subtitle: 'Average speed across all tests over time',
              lineColor: Colors.blue,
              yAxisLabel: 'Speed Score',
              enableZoom: true,
              valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}',
            ),
            const SizedBox(height: 24),

            // Agility vs Speed Correlation - REUSING EXISTING WIDGET
            ScatterPlotChart(
              dataType: 'agility_vs_speed',
              parameters: {
                'player_id': widget.player.id!,
                'date_range': _filters['date_range'] ?? 90,
              },
              title: 'Agility vs Speed Correlation',
              subtitle: 'Relationship between agility test scores and speed metrics',
              xAxisLabel: 'Speed Score',
              yAxisLabel: 'Agility Score',
              showTrendLine: true,
              trendLineColor: Colors.green.withOpacity(0.6),
            ),
            const SizedBox(height: 24),

            // Skating Categories Analysis - SPORT-SPECIFIC WIDGET
            SkatingCategoriesAnalysisWidget(
              playerId: widget.player.id!,
              filters: _filters,
            ),
            const SizedBox(height: 24),

            // Benchmarking Against Age Group - SPORT-SPECIFIC WIDGET
            SkatingBenchmarksWidget(
              playerId: widget.player.id!,
              ageGroup: widget.player.ageGroup ?? 'U18',
              position: widget.player.position ?? 'Forward',
            ),
            const SizedBox(height: 24),

            // Assessment History Trend - REUSING EXISTING WIDGET
            InteractiveTrendChart(
              playerId: widget.player.id!,
              dateRange: 365, // Show full year for assessment history
              interval: 'month',
              metric: 'overall_score',
              title: 'Overall Skating Assessment Progress',
              subtitle: 'Month-over-month improvement in skating assessments',
              lineColor: Colors.purple,
              yAxisLabel: 'Overall Score',
              enableZoom: true,
              valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}/10',
            ),
            const SizedBox(height: 24),

            // Skating Recommendations - REUSING EXISTING WIDGET
            RecommendationsWidget(
              playerId: widget.player.id!,
              skillType: SkillType.skating,
            ),
          ],
        ),
      ),
    );
  }
}