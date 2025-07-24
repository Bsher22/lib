import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/performance_metrics_card.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/zones_analysis_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/shot_types_analysis_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/recommendations_widget.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/scatter_plot_chart.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/charts/interactive_trend_chart.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/filter_chip_group.dart';
import 'package:hockey_shot_tracker/utils/analytics_constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class ShotAnalysisScreen extends StatefulWidget {
  final Player player;

  const ShotAnalysisScreen({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  _ShotAnalysisScreenState createState() => _ShotAnalysisScreenState();
}

class _ShotAnalysisScreenState extends State<ShotAnalysisScreen> {
  String _selectedTimeRange = 'All time';
  final List<String> _selectedShotTypes = [];
  List<String> _availableShotTypes = [];
  final List<String> _timeRanges = ['All time', '7 days', '30 days', '90 days'];
  bool _isLoading = true;
  Map<String, dynamic> _filters = {};
  String? _error;
  
  // Add dialog management
  bool _isDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchAvailableShotTypes();
  }

  @override
  void dispose() {
    // Ensure any open dialogs are closed when disposing
    if (_isDialogOpen && mounted) {
      Navigator.of(context, rootNavigator: true).popUntil((route) {
        return route.isFirst || !route.willHandlePopInternally;
      });
    }
    super.dispose();
  }

  Future<void> _fetchAvailableShotTypes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/config/shot-types'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        if (mounted) {
          setState(() {
            _availableShotTypes = data.keys.toList();
            _isLoading = false;
            _updateFilters();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = 'Failed to load shot types';
            _isLoading = false;
            _availableShotTypes = ['Wrist', 'Snap', 'Slap', 'Backhand'];
            _updateFilters();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
          _availableShotTypes = ['Wrist', 'Snap', 'Slap', 'Backhand'];
          _updateFilters();
        });
      }
    }
  }

  void _updateFilters() {
    final Map<String, dynamic> filters = {};

    if (_selectedTimeRange != 'All time') {
      final days = _selectedTimeRange.split(' ')[0];
      filters['date_range'] = int.parse(days);
    }

    if (_selectedShotTypes.isNotEmpty) {
      filters['shot_types'] = _selectedShotTypes;
    }

    if (mounted) {
      setState(() {
        _filters = filters;
      });
    }
  }

  void _onTimeRangeChanged(String value) {
    if (mounted) {
      setState(() {
        _selectedTimeRange = value;
        _updateFilters();
      });
    }
  }

  void _onShotTypeSelected(String value, bool selected) {
    if (mounted) {
      setState(() {
        if (selected) {
          _selectedShotTypes.add(value);
        } else {
          _selectedShotTypes.remove(value);
        }
        _updateFilters();
      });
    }
  }

  // Safe dialog helper method
  Future<T?> _showSafeDialog<T>({
    required Widget Function(BuildContext) builder,
    bool barrierDismissible = true,
  }) async {
    if (_isDialogOpen || !mounted) return null;
    
    setState(() {
      _isDialogOpen = true;
    });

    try {
      final result = await showDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: builder,
      );
      return result;
    } finally {
      if (mounted) {
        setState(() {
          _isDialogOpen = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Shot Analysis: ${widget.player.name}',
      backgroundColor: Colors.grey[100],
      // Add proper back button handling
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          // Close any open dialogs before navigating back
          if (_isDialogOpen) {
            Navigator.of(context, rootNavigator: true).pop();
          }
          Navigator.of(context).pop();
        },
      ),
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: _buildAnalysisContent(deviceType, isLandscape),
          );
        },
      ),
    );
  }

  Widget _buildAnalysisContent(DeviceType deviceType, bool isLandscape) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout(isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout();
        }
      },
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFiltersCard(),
          ResponsiveSpacing(multiplier: 3),
          _buildPerformanceMetrics(),
          ResponsiveSpacing(multiplier: 3),
          _buildTrendChart(),
          ResponsiveSpacing(multiplier: 3),
          _buildScatterPlot(),
          ResponsiveSpacing(multiplier: 3),
          _buildShotTypesAnalysis(),
          ResponsiveSpacing(multiplier: 3),
          _buildZonesAnalysis(),
          ResponsiveSpacing(multiplier: 3),
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout();
    }

    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFiltersCard(),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPerformanceMetrics()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildTrendChart()),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildScatterPlot()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildShotTypesAnalysis()),
            ],
          ),
          ResponsiveSpacing(multiplier: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildZonesAnalysis()),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(child: _buildRecommendations()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
                _buildFiltersCard(),
                ResponsiveSpacing(multiplier: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildPerformanceMetrics()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildTrendChart()),
                  ],
                ),
                ResponsiveSpacing(multiplier: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildScatterPlot()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildShotTypesAnalysis()),
                  ],
                ),
                ResponsiveSpacing(multiplier: 3),
                _buildZonesAnalysis(),
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
            'Analysis Overview',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Player', widget.player.name),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Position', widget.player.position ?? 'Forward'),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Time Range', _selectedTimeRange),
          ResponsiveSpacing(multiplier: 2),
          _buildSummaryCard('Shot Types', _selectedShotTypes.isEmpty ? 'All' : '${_selectedShotTypes.length} selected'),
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
            text: 'Export Report',
            onPressed: () => _exportReport(),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.file_download, // Fixed: removed Icon() wrapper
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Compare Players',
            onPressed: () => _comparePlayer(),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.blueGrey[700],
            foregroundColor: Colors.white,
            icon: Icons.compare_arrows, // Fixed: removed Icon() wrapper
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'New Assessment',
            onPressed: () => Navigator.pushNamed(context, '/shot-assessment'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            icon: Icons.add_chart, // Fixed: removed Icon() wrapper
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveButton(
            text: 'Record Shots',
            onPressed: () => Navigator.pushNamed(context, '/shot-input'),
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.green[700],
            foregroundColor: Colors.white,
            icon: Icons.add_circle, // Fixed: removed Icon() wrapper
          ),
          ResponsiveSpacing(multiplier: 3),
          _buildRecommendations(),
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

  Widget _buildFiltersCard() {
    return ResponsiveCard(
      baseBorderRadius: 12,
      elevation: 2,
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              'Filters',
              baseFontSize: 16,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 2),
            Row(
              children: [
                ResponsiveText('Time Range:', baseFontSize: 14),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
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
                      child: ResponsiveText(range, baseFontSize: 14),
                    );
                  }).toList(),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText('Shot Types:', baseFontSize: 14),
            ResponsiveSpacing(multiplier: 1),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              ResponsiveText(
                'Error: $_error',
                baseFontSize: 14,
                style: const TextStyle(color: Colors.red),
              )
            else
              FilterChipGroup<String>(
                options: _availableShotTypes,
                selectedOptions: _selectedShotTypes,
                onSelected: _onShotTypeSelected,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics() {
    return PerformanceMetricsCard(
      playerId: widget.player.id!,
      filters: _filters,
      skillType: SkillType.shooting,
    );
  }

  Widget _buildTrendChart() {
    return InteractiveTrendChart.successRate(
      playerId: widget.player.id!,
      dateRange: _filters['date_range'] as int? ?? 90,
      interval: 'week',
      title: 'Success Rate Trend',
      subtitle: 'Shot success rate over time',
      enableZoom: true,
    );
  }

  Widget _buildScatterPlot() {
    return ScatterPlotChart.powerVsSuccess(
      playerId: widget.player.id!,
      dateRange: _filters['date_range'] as int? ?? 30,
      showTrendLine: true,
    );
  }

  Widget _buildShotTypesAnalysis() {
    return ShotTypesAnalysisWidget(
      playerId: widget.player.id!,
      filters: _filters,
    );
  }

  Widget _buildZonesAnalysis() {
    return ZonesAnalysisWidget(
      playerId: widget.player.id!,
      filters: _filters,
    );
  }

  Widget _buildRecommendations() {
    return RecommendationsWidget(
      playerId: widget.player.id!,
      skillType: SkillType.shooting,
      // Note: The RecommendationsWidget needs to be fixed separately
      // to use ApiConfig.baseUrl instead of 'your_base_url_here'
    );
  }

  void _exportReport() {
    // Implement export functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText(
          'Export functionality to be implemented',
          baseFontSize: 16,
        ),
      ),
    );
  }

  void _comparePlayer() {
    // Implement player comparison functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: ResponsiveText(
          'Player comparison functionality to be implemented',
          baseFontSize: 16,
        ),
      ),
    );
  }
}