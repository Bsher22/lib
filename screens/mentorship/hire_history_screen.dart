// lib/screens/mentorship/hire_history_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/development_plan_service.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/widgets/core/visualization/configurable_trend_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class HIREHistoryScreen extends StatefulWidget {
  final Player? player; // If null, will use selected player from app state

  const HIREHistoryScreen({
    super.key,
    this.player,
  });

  @override
  State<HIREHistoryScreen> createState() => _HIREHistoryScreenState();
}

class _HIREHistoryScreenState extends State<HIREHistoryScreen> {
  
  DevelopmentPlanService get _developmentPlanService {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return DevelopmentPlanService(apiService: apiService);
}
  
  // State management
  Player? _selectedPlayer;
  bool _isLoading = true;
  String? _errorMessage;
  List<AssessmentHistoryItem> _historyItems = [];
  ProgressMetrics? _progressMetrics;
  
  // Filters
  DateTimeRange? _dateRange;
  String _selectedView = 'timeline'; // 'timeline', 'trends', 'notes', 'comparison'
  
  // Chart data
  List<Map<String, dynamic>> _chartData = [];

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    _selectedPlayer = widget.player;
    
    if (_selectedPlayer == null) {
      final appState = Provider.of<AppState>(context, listen: false);
      if (appState.selectedPlayer.isNotEmpty) {
        _selectedPlayer = appState.players.firstWhere(
          (p) => p.name == appState.selectedPlayer,
          orElse: () => appState.players.isNotEmpty ? appState.players.first : Player(name: 'Unknown', createdAt: DateTime.now()), // FIXED: Return non-null Player
        );
      }
    }
    
    if (_selectedPlayer?.id != null) {
      _loadHistoryData();
    } else {
      setState(() {
        _errorMessage = 'No player selected for HIRE history';
        _isLoading = false;
      });
    }
  }

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  Future<void> _loadHistoryData() async {
    if (_selectedPlayer?.id == null || !mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load assessment history
      _historyItems = await _developmentPlanService.loadAssessmentHistory(
        _selectedPlayer!.id!,
        dateRange: _dateRange,
      );
      
      // Calculate progress metrics
      _progressMetrics = await _developmentPlanService.calculateProgressMetrics(
        _selectedPlayer!.id!,
        dateRange: _dateRange,
      );
      
      // Prepare chart data
      _prepareChartData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('Error loading HIRE history: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load HIRE history: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _prepareChartData() {
    _chartData = _historyItems.map((item) => {
      'date': item.assessmentDate,
      'overall_score': item.planData.ratings.overallHIREScore,
      'h_score': item.planData.ratings.hScore,
      'i_score': item.planData.ratings.iScore,
      'r_score': item.planData.ratings.rScore,
      'e_score': item.planData.ratings.eScore,
      'weekStart': item.assessmentDate, // For chart compatibility
    }).toList();
    
    // Sort by date
    _chartData.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
  }

  // ============================================================================
  // UI BUILDING
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'HIRE History${_selectedPlayer != null ? ' - ${_selectedPlayer!.name}' : ''}',
      backgroundColor: Colors.grey[50],
      actions: [
        IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: _showDateRangeFilter,
          tooltip: 'Filter by Date Range',
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _exportHistory,
          tooltip: 'Export History',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadHistoryData,
          tooltip: 'Refresh',
        ),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (_isLoading) {
            return _buildLoadingState();
          }

          if (_errorMessage != null) {
            return _buildErrorState();
          }

          if (_selectedPlayer == null) {
            return _buildNoPlayerState();
          }

          return _buildHistoryContent(deviceType, isLandscape);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading HIRE history...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading History',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistoryData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlayerState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_search,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Player Selected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Please select a player to view their HIRE history',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/players'),
              icon: const Icon(Icons.people),
              label: const Text('Select Player'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryContent(DeviceType deviceType, bool isLandscape) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildPlayerHeader(deviceType),
        ),
        SliverToBoxAdapter(
          child: _buildViewSelector(),
        ),
        SliverToBoxAdapter(
          child: _buildProgressSummary(),
        ),
        SliverToBoxAdapter(
          child: _buildMainContent(deviceType, isLandscape),
        ),
      ],
    );
  }

  Widget _buildPlayerHeader(DeviceType deviceType) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blueGrey[100],
              radius: deviceType == DeviceType.mobile ? 30 : 40,
              child: ResponsiveText(
                _selectedPlayer!.name.isNotEmpty ? _selectedPlayer!.name[0].toUpperCase() : '?',
                baseFontSize: deviceType == DeviceType.mobile ? 24 : 32,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    _selectedPlayer!.name,
                    baseFontSize: deviceType == DeviceType.mobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'HIRE Character Development History',
                    baseFontSize: 16,
                    color: Colors.blueGrey[600],
                  ),
                  if (_dateRange != null) ...[
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      'Filtered: ${DateFormat('MMM d, yyyy').format(_dateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_dateRange!.end)}',
                      baseFontSize: 12,
                      color: Colors.blue[700],
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
            if (_dateRange != null)
              IconButton(
                onPressed: () {
                  setState(() => _dateRange = null);
                  _loadHistoryData();
                },
                icon: const Icon(Icons.clear),
                tooltip: 'Clear Date Filter',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ResponsiveCard(
        elevation: 1,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 8),
        child: Row(
          children: [
            _buildViewTab('timeline', 'Timeline', Icons.timeline),
            _buildViewTab('trends', 'Trends', Icons.trending_up),
            _buildViewTab('notes', 'Notes', Icons.note),
            _buildViewTab('comparison', 'Compare', Icons.compare_arrows),
          ],
        ),
      ),
    );
  }

  Widget _buildViewTab(String value, String label, IconData icon) {
    final isSelected = _selectedView == value;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedView = value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(height: 4),
              ResponsiveText(
                label,
                baseFontSize: 12,
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSummary() {
    if (_progressMetrics == null || _historyItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Progress Summary',
              baseFontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
            ResponsiveSpacing(multiplier: 2),
            
            AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                if (deviceType == DeviceType.mobile && !isLandscape) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildProgressStatCard('Total Assessments', '${_progressMetrics!.totalAssessments}', Icons.assessment, Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildProgressStatCard('Overall Improvement', '${_progressMetrics!.overallImprovement >= 0 ? '+' : ''}${_progressMetrics!.overallImprovement.toStringAsFixed(1)}', Icons.trending_up, _progressMetrics!.overallImprovement >= 0 ? Colors.green : Colors.red)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildProgressStatCard('Consistency', '${(_progressMetrics!.consistencyScore * 100).toStringAsFixed(0)}%', Icons.timeline, Colors.purple)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildProgressStatCard('Top Areas', '${_progressMetrics!.topImprovements.length}', Icons.emoji_events, Colors.orange)),
                        ],
                      ),
                    ],
                  );
                }
                
                return Row(
                  children: [
                    Expanded(child: _buildProgressStatCard('Total Assessments', '${_progressMetrics!.totalAssessments}', Icons.assessment, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProgressStatCard('Overall Improvement', '${_progressMetrics!.overallImprovement >= 0 ? '+' : ''}${_progressMetrics!.overallImprovement.toStringAsFixed(1)}', Icons.trending_up, _progressMetrics!.overallImprovement >= 0 ? Colors.green : Colors.red)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProgressStatCard('Consistency', '${(_progressMetrics!.consistencyScore * 100).toStringAsFixed(0)}%', Icons.timeline, Colors.purple)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildProgressStatCard('Top Areas', '${_progressMetrics!.topImprovements.length}', Icons.emoji_events, Colors.orange)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          ResponsiveText(
            value,
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ResponsiveText(
            title,
            baseFontSize: 12,
            color: Colors.grey[600],
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(DeviceType deviceType, bool isLandscape) {
    if (_historyItems.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            children: [
              const Icon(Icons.history, size: 64, color: Colors.grey),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'No HIRE History Available',
                baseFontSize: 18,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                'Start a mentorship session to begin tracking ${_selectedPlayer!.name}\'s character development.',
                baseFontSize: 14,
                color: Colors.grey[500],
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedView) {
      case 'trends':
        return _buildTrendsView(deviceType);
      case 'notes':
        return _buildNotesView(deviceType);
      case 'comparison':
        return _buildComparisonView(deviceType);
      default: // 'timeline'
        return _buildTimelineView(deviceType);
    }
  }

  Widget _buildTimelineView(DeviceType deviceType) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Assessment Timeline',
                  baseFontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveSpacing(multiplier: 2),
                
                // Overall progress chart
                if (_chartData.isNotEmpty)
                  ConfigurableTrendChart.metric(
                    trendData: _chartData,
                    metricKey: 'overall_score',
                    title: 'Overall HIRE Score Progression',
                    color: Colors.blue,
                    yAxisLabel: 'HIRE Score',
                  ),
              ],
            ),
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Timeline items
          ..._historyItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isLast = index == _historyItems.length - 1;
            
            return _buildTimelineItem(item, isLast, deviceType);
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(AssessmentHistoryItem item, bool isLast, DeviceType deviceType) {
    final overallScore = item.planData.ratings.overallHIREScore;
    final scoreColor = HockeyRatingsConfig.getColorForRating(overallScore);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ResponsiveCard(
        elevation: 1,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline indicator
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: scoreColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: ResponsiveText(
                      overallScore.toStringAsFixed(1),
                      baseFontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 40,
                    color: Colors.grey[300],
                    margin: const EdgeInsets.symmetric(vertical: 8),
                  ),
              ],
            ),
            
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ResponsiveText(
                          DateFormat('MMMM d, yyyy').format(item.assessmentDate),
                          baseFontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: scoreColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: scoreColor.withOpacity(0.3)),
                        ),
                        child: ResponsiveText(
                          'HIRE: ${overallScore.toStringAsFixed(1)}',
                          baseFontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                    ],
                  ),
                  
                  ResponsiveSpacing(multiplier: 1),
                  
                  // HIRE component scores
                  Row(
                    children: [
                      _buildMiniScore('H', item.planData.ratings.hScore, Colors.red),
                      const SizedBox(width: 8),
                      _buildMiniScore('I', item.planData.ratings.iScore, Colors.blue),
                      const SizedBox(width: 8),
                      _buildMiniScore('R', item.planData.ratings.rScore, Colors.green),
                      const SizedBox(width: 8),
                      _buildMiniScore('E', item.planData.ratings.eScore, Colors.orange),
                    ],
                  ),
                  
                  if (item.sessionNotes.isNotEmpty) ...[
                    ResponsiveSpacing(multiplier: 1),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: ResponsiveText(
                        item.sessionNotes,
                        baseFontSize: 14,
                        color: Colors.blueGrey[700],
                      ),
                    ),
                  ],
                  
                  if (item.actionItems.isNotEmpty) ...[
                    ResponsiveSpacing(multiplier: 1),
                    ResponsiveText(
                      'Action Items:',
                      baseFontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[700],
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ...item.actionItems.map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ResponsiveText(
                            '• ',
                            baseFontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                          Expanded(
                            child: ResponsiveText(
                              action,
                              baseFontSize: 12,
                              color: Colors.blueGrey[600],
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniScore(String letter, double score, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ResponsiveText(
            letter,
            baseFontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          ResponsiveText(
            score.toStringAsFixed(1),
            baseFontSize: 8,
            color: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendsView(DeviceType deviceType) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall trend
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: ConfigurableTrendChart.metric(
              trendData: _chartData,
              metricKey: 'overall_score',
              title: 'Overall HIRE Score Trend',
              color: Colors.blue,
              yAxisLabel: 'HIRE Score',
            ),
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Component trends
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'HIRE Component Trends',
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveSpacing(multiplier: 2),
                
                AdaptiveLayout(
                  builder: (deviceType, isLandscape) {
                    if (deviceType == DeviceType.mobile && !isLandscape) {
                      return Column(
                        children: [
                          ConfigurableTrendChart.metric(
                            trendData: _chartData,
                            metricKey: 'h_score',
                            title: 'Humility/Hardwork',
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          ConfigurableTrendChart.metric(
                            trendData: _chartData,
                            metricKey: 'i_score',
                            title: 'Initiative/Integrity',
                            color: Colors.blue,
                          ),
                          const SizedBox(height: 16),
                          ConfigurableTrendChart.metric(
                            trendData: _chartData,
                            metricKey: 'r_score',
                            title: 'Responsibility/Respect',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 16),
                          ConfigurableTrendChart.metric(
                            trendData: _chartData,
                            metricKey: 'e_score',
                            title: 'Enthusiasm',
                            color: Colors.orange,
                          ),
                        ],
                      );
                    }
                    
                    return Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ConfigurableTrendChart.metric(
                                trendData: _chartData,
                                metricKey: 'h_score',
                                title: 'Humility/Hardwork',
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ConfigurableTrendChart.metric(
                                trendData: _chartData,
                                metricKey: 'i_score',
                                title: 'Initiative/Integrity',
                                color: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ConfigurableTrendChart.metric(
                                trendData: _chartData,
                                metricKey: 'r_score',
                                title: 'Responsibility/Respect',
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ConfigurableTrendChart.metric(
                                trendData: _chartData,
                                metricKey: 'e_score',
                                title: 'Enthusiasm',
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesView(DeviceType deviceType) {
    final itemsWithNotes = _historyItems.where((item) => item.sessionNotes.isNotEmpty || item.actionItems.isNotEmpty).toList();
    
    if (itemsWithNotes.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            children: [
              const Icon(Icons.note_outlined, size: 64, color: Colors.grey),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'No Session Notes Available',
                baseFontSize: 18,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: itemsWithNotes.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.event_note, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    ResponsiveText(
                      DateFormat('MMMM d, yyyy').format(item.assessmentDate),
                      baseFontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: HockeyRatingsConfig.getColorForRating(item.planData.ratings.overallHIREScore).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ResponsiveText(
                        'HIRE: ${item.planData.ratings.overallHIREScore.toStringAsFixed(1)}',
                        baseFontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: HockeyRatingsConfig.getColorForRating(item.planData.ratings.overallHIREScore),
                      ),
                    ),
                  ],
                ),
                
                if (item.sessionNotes.isNotEmpty) ...[
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    'Session Notes',
                    baseFontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ResponsiveText(
                      item.sessionNotes,
                      baseFontSize: 14,
                      color: Colors.blueGrey[700],
                    ),
                  ),
                ],
                
                if (item.actionItems.isNotEmpty) ...[
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    'Action Items',
                    baseFontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ...item.actionItems.map((action) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_box_outline_blank, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ResponsiveText(
                            action,
                            baseFontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ],
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildComparisonView(DeviceType deviceType) {
    if (_historyItems.length < 2) {
      return Container(
        margin: const EdgeInsets.all(16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            children: [
              const Icon(Icons.compare_arrows, size: 64, color: Colors.grey),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'Need at least 2 assessments to compare',
                baseFontSize: 18,
                color: Colors.grey[600],
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final firstAssessment = _historyItems.last; // Oldest
    final lastAssessment = _historyItems.first; // Newest

    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'First vs Latest Assessment Comparison',
              baseFontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
            ResponsiveSpacing(multiplier: 2),
            
            // Date comparison
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ResponsiveText(
                        'First Assessment',
                        baseFontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      ResponsiveText(
                        DateFormat('MMM d, yyyy').format(firstAssessment.assessmentDate),
                        baseFontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                Expanded(
                  child: Column(
                    children: [
                      ResponsiveText(
                        'Latest Assessment',
                        baseFontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                      ResponsiveText(
                        DateFormat('MMM d, yyyy').format(lastAssessment.assessmentDate),
                        baseFontSize: 16,
                        color: Colors.blueGrey[800],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            ResponsiveSpacing(multiplier: 3),
            
            // HIRE scores comparison
            _buildScoreComparison('Overall HIRE', firstAssessment.planData.ratings.overallHIREScore, lastAssessment.planData.ratings.overallHIREScore),
            _buildScoreComparison('Humility/Hardwork', firstAssessment.planData.ratings.hScore, lastAssessment.planData.ratings.hScore),
            _buildScoreComparison('Initiative/Integrity', firstAssessment.planData.ratings.iScore, lastAssessment.planData.ratings.iScore),
            _buildScoreComparison('Responsibility/Respect', firstAssessment.planData.ratings.rScore, lastAssessment.planData.ratings.rScore),
            _buildScoreComparison('Enthusiasm', firstAssessment.planData.ratings.eScore, lastAssessment.planData.ratings.eScore),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreComparison(String label, double firstScore, double lastScore) {
    final improvement = lastScore - firstScore;
    final improvementColor = improvement >= 0 ? Colors.green : Colors.red;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ResponsiveText(
              label,
              baseFontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey[700],
            ),
          ),
          Expanded(
            child: ResponsiveText(
              firstScore.toStringAsFixed(1),
              baseFontSize: 16,
              fontWeight: FontWeight.bold,
              color: HockeyRatingsConfig.getColorForRating(firstScore),
              textAlign: TextAlign.center,
            ),
          ),
          Icon(Icons.arrow_forward, color: Colors.grey[400], size: 16),
          Expanded(
            child: ResponsiveText(
              lastScore.toStringAsFixed(1),
              baseFontSize: 16,
              fontWeight: FontWeight.bold,
              color: HockeyRatingsConfig.getColorForRating(lastScore),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  improvement >= 0 ? Icons.trending_up : Icons.trending_down,
                  color: improvementColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                ResponsiveText(
                  '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}',
                  baseFontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: improvementColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _showDateRangeFilter() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _dateRange) {
      setState(() {
        _dateRange = picked;
      });
      _loadHistoryData();
    }
  }

  void _exportHistory() async {
    if (_selectedPlayer?.id == null) return;
    
    try {
      final result = await _developmentPlanService.exportAssessmentHistory(
        _selectedPlayer!.id!,
        dateRange: _dateRange,
        format: 'pdf',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('History exported successfully: $result'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class AssessmentHistoryItem {
  final int id;
  final DateTime assessmentDate;
  final DevelopmentPlanData planData;
  final String sessionNotes;
  final List<String> actionItems;
  final Map<String, dynamic> metadata;
  final bool isCompleted;

  const AssessmentHistoryItem({
    required this.id,
    required this.assessmentDate,
    required this.planData,
    this.sessionNotes = '',
    this.actionItems = const [],
    this.metadata = const {},
    this.isCompleted = true,
  });

  factory AssessmentHistoryItem.fromJson(Map<String, dynamic> json) {
    return AssessmentHistoryItem(
      id: json['id'],
      assessmentDate: DateTime.parse(json['assessment_date']),
      planData: DevelopmentPlanData.fromJson(json['plan_data']),
      sessionNotes: json['session_notes'] ?? '',
      actionItems: List<String>.from(json['action_items'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      isCompleted: json['is_completed'] == 1,
    );
  }
}

class ProgressMetrics {
  final double overallImprovement;
  final Map<String, double> categoryTrends;
  final List<String> topImprovements;
  final List<String> areasOfConcern;
  final double consistencyScore;
  final int totalAssessments;

  const ProgressMetrics({
    required this.overallImprovement,
    required this.categoryTrends,
    required this.topImprovements,
    required this.areasOfConcern,
    required this.consistencyScore,
    required this.totalAssessments,
  });
}