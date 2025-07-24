// widgets/skating_benchmarks_widget.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class SkatingBenchmarksWidget extends StatefulWidget {
  final int playerId;
  final String ageGroup;
  final String position;
  final String? skillLevel;  // Added skill level support
  final String? gender;      // Added gender support

  const SkatingBenchmarksWidget({
    Key? key,
    required this.playerId,
    required this.ageGroup,
    required this.position,
    this.skillLevel = 'competitive',
    this.gender,
  }) : super(key: key);

  @override
  _SkatingBenchmarksWidgetState createState() => _SkatingBenchmarksWidgetState();
}

class _SkatingBenchmarksWidgetState extends State<SkatingBenchmarksWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _playerBenchmarks = {};
  Map<String, Map<String, double>> _ageBenchmarks = {};
  Map<String, dynamic> _recommendationsPreview = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBenchmarkData();
  }

  @override
  void didUpdateWidget(SkatingBenchmarksWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if any parameters changed
    if (oldWidget.playerId != widget.playerId || 
        oldWidget.ageGroup != widget.ageGroup ||
        oldWidget.position != widget.position ||
        oldWidget.skillLevel != widget.skillLevel ||
        oldWidget.gender != widget.gender) {
      _fetchBenchmarkData();
    }
  }

  Future<void> _fetchBenchmarkData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch player's skating performance data
      final playerResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analytics/skating/${widget.playerId}/benchmarks'),
        headers: await ApiConfig.getHeaders(),
      );

      // Fetch age group benchmarks with skill level and gender considerations
      final benchmarkUrl = Uri.parse(
        '${ApiConfig.baseUrl}/api/skating/benchmarks/${widget.ageGroup}'
      ).replace(queryParameters: {
        'position': widget.position,
        'skillLevel': widget.skillLevel ?? 'competitive',
        if (widget.gender != null) 'gender': widget.gender!,
        'version': '3.0',  // Request updated benchmarks
      });
      
      final benchmarkResponse = await http.get(
        benchmarkUrl,
        headers: await ApiConfig.getHeaders(),
      );

      // Fetch recommendations preview for additional insights
      final recommendationsResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/skating/analytics/${widget.playerId}/performance-summary'),
        headers: await ApiConfig.getHeaders(),
      );

      Map<String, dynamic> playerData = {};
      Map<String, Map<String, double>> ageBenchmarks = {};
      Map<String, dynamic> recommendationsData = {};

      // Process player data
      if (playerResponse.statusCode == 200) {
        playerData = json.decode(playerResponse.body);
      }

      // Process benchmarks response
      if (benchmarkResponse.statusCode == 200) {
        final benchmarkData = json.decode(benchmarkResponse.body);
        
        if (benchmarkData.containsKey('benchmarks')) {
          final benchmarks = benchmarkData['benchmarks'] as Map<String, dynamic>;
          
          for (var testName in benchmarks.keys) {
            final testBenchmarks = benchmarks[testName] as Map<String, dynamic>;
            ageBenchmarks[testName] = SkatingUtils.convertBenchmarksToDouble(testBenchmarks);
          }
        }
      } else {
        // Use updated default benchmarks from centralized utils
        ageBenchmarks = SkatingUtils.getUpdatedBenchmarks(widget.ageGroup, widget.skillLevel, widget.gender);
      }

      // Process recommendations preview
      if (recommendationsResponse.statusCode == 200) {
        recommendationsData = json.decode(recommendationsResponse.body);
      }
      
      setState(() {
        _playerBenchmarks = playerData;
        _ageBenchmarks = ageBenchmarks;
        _recommendationsPreview = recommendationsData;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
        // Use updated default benchmarks on error
        _ageBenchmarks = SkatingUtils.getUpdatedBenchmarks(widget.ageGroup, widget.skillLevel, widget.gender);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildErrorCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Benchmarks',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        // Version info card
        _buildVersionInfoCard(),
        
        const SizedBox(height: 12),
        
        StandardCard(
          borderRadius: 12,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      color: Colors.amber[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'vs ${SkatingUtils.formatAgeGroup(widget.ageGroup)} ${SkatingUtils.formatPosition(widget.position)}s',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (widget.skillLevel != null) ...[
                      const SizedBox(width: 8),
                      StatusBadge(
                        text: SkatingUtils.formatSkillLevel(widget.skillLevel!),
                        color: Colors.blue,
                        size: StatusBadgeSize.small,
                        shape: StatusBadgeShape.pill,
                      ),
                    ],
                  ],
                ),
                
                if (widget.gender != null && _shouldShowGender()) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        widget.gender == 'male' ? Icons.male : Icons.female,
                        size: 16,
                        color: Colors.blueGrey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Gender-specific standards applied',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                ],
                
                const SizedBox(height: 16),
                if (_playerBenchmarks.isEmpty)
                  _buildNoBenchmarkData()
                else
                  ..._buildBenchmarkComparisons(),
                
                // Add recommendations preview if available
                if (_recommendationsPreview.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildRecommendationsPreview(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.upgrade, color: Colors.green[600], size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Updated v3.0 - Research-based benchmarks from 60+ studies',
              style: TextStyle(
                fontSize: 11,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return StandardCard(
      borderRadius: 12,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.warning, color: Colors.orange[600], size: 48),
            const SizedBox(height: 8),
            const Text(
              'Unable to load benchmark data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Using default research-based benchmarks',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _fetchBenchmarkData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoBenchmarkData() {
    return Column(
      children: [
        const Icon(
          Icons.analytics_outlined,
          size: 48,
          color: Colors.grey,
        ),
        const SizedBox(height: 16),
        const Text(
          'No benchmark data available',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Complete skating assessments to compare against ${SkatingUtils.formatAgeGroup(widget.ageGroup)} ${SkatingUtils.formatPosition(widget.position)} benchmarks',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        _buildBenchmarkPreview(),
      ],
    );
  }

  Widget _buildBenchmarkPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Standards:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ..._ageBenchmarks.entries.take(4).map((entry) {
          final testName = entry.key;
          final benchmarks = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    SkatingUtils.formatTestName(testName),
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Text(
                  'Elite: ${benchmarks['Elite']!.toStringAsFixed(1)}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildRecommendationsPreview() {
    final topPriority = _recommendationsPreview['top_priority_area'] as String?;
    final preview = _recommendationsPreview['recommendation_preview'] as String?;
    
    if (topPriority == null && preview == null) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.blue[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Development Focus',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (topPriority != null)
            Text(
              'Priority Area: $topPriority',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          if (preview != null) ...[
            const SizedBox(height: 4),
            Text(
              preview,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildBenchmarkComparisons() {
    final List<Widget> widgets = [];
    
    if (_playerBenchmarks.containsKey('test_performances')) {
      final testPerformances = _playerBenchmarks['test_performances'] as Map<String, dynamic>;
      
      for (var testName in testPerformances.keys) {
        final playerTime = (testPerformances[testName]['best_time'] as num?)?.toDouble();
        final playerAvgTime = (testPerformances[testName]['avg_time'] as num?)?.toDouble();
        
        if (playerTime == null || !_ageBenchmarks.containsKey(testName)) continue;
        
        final benchmarks = _ageBenchmarks[testName]!;
        final benchmarkLevel = SkatingUtils.determineUpdatedBenchmarkLevel(playerTime, benchmarks);
        final percentile = SkatingUtils.calculateUpdatedPercentile(playerTime, benchmarks);
        
        widgets.add(_buildTestBenchmark(
          testName,
          playerTime,
          playerAvgTime,
          benchmarks,
          benchmarkLevel,
          percentile,
        ));
        widgets.add(const SizedBox(height: 16));
      }
    }
    
    if (widgets.isEmpty) {
      widgets.add(_buildNoBenchmarkData());
    }
    
    return widgets;
  }

  Widget _buildTestBenchmark(
    String testName,
    double playerTime,
    double? playerAvgTime,
    Map<String, double> benchmarks,
    String benchmarkLevel,
    double percentile,
  ) {
    final color = SkatingUtils.getUpdatedBenchmarkColor(benchmarkLevel);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  SkatingUtils.formatTestName(testName),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              StatusBadge(
                text: benchmarkLevel,
                color: color,
                size: StatusBadgeSize.small,
                shape: StatusBadgeShape.pill,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Best: ${playerTime.toStringAsFixed(2)}s',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
              if (playerAvgTime != null) ...[
                const SizedBox(width: 16),
                Text(
                  'Avg: ${playerAvgTime.toStringAsFixed(2)}s',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                percentile >= 75 ? Icons.trending_up : 
                percentile >= 50 ? Icons.trending_flat : Icons.trending_down,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                '${percentile.toStringAsFixed(0)}th percentile',
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildBenchmarkBar(playerTime, benchmarks, color),
        ],
      ),
    );
  }

  Widget _buildBenchmarkBar(double playerTime, Map<String, double> benchmarks, Color playerColor) {
    // Use updated benchmark level names
    final elite = benchmarks['Elite']!;
    final advanced = benchmarks['Advanced']!;
    final developing = benchmarks['Developing']!;
    final beginner = benchmarks['Beginner']!;
    
    // Create a visual representation of where the player falls
    final maxTime = beginner * 1.2; // Extend range beyond beginner
    final playerPosition = (playerTime / maxTime).clamp(0.0, 1.0);
    
    return Column(
      children: [
        Container(
          height: 20,
          child: Stack(
            children: [
              // Background bar with benchmark sections
              Container(
                height: 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    colors: [
                      Colors.green,
                      Colors.lightGreen,
                      Colors.orange,
                      Colors.red,
                    ],
                    stops: [
                      elite / maxTime,
                      advanced / maxTime,
                      developing / maxTime,
                      beginner / maxTime,
                    ],
                  ),
                ),
              ),
              // Player position indicator
              Positioned(
                left: playerPosition * (MediaQuery.of(context).size.width - 64) - 6,
                child: Container(
                  width: 12,
                  height: 20,
                  decoration: BoxDecoration(
                    color: playerColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Elite\n${elite.toStringAsFixed(1)}s',
              style: const TextStyle(fontSize: 10, color: Colors.green),
              textAlign: TextAlign.center,
            ),
            Text(
              'Advanced\n${advanced.toStringAsFixed(1)}s',
              style: const TextStyle(fontSize: 10, color: Colors.lightGreen),
              textAlign: TextAlign.center,
            ),
            Text(
              'Developing\n${developing.toStringAsFixed(1)}s',
              style: const TextStyle(fontSize: 10, color: Colors.orange),
              textAlign: TextAlign.center,
            ),
            Text(
              'Beginner\n${beginner.toStringAsFixed(1)}s',
              style: const TextStyle(fontSize: 10, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ],
    );
  }

  bool _shouldShowGender() {
    // Show gender information for age groups 15+ where gender-specific standards apply
    return widget.gender != null && 
           (widget.ageGroup == 'youth_15_18' || widget.ageGroup == 'adult');
  }
}