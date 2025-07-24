// widgets/skating_categories_analysis_widget.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/utils/skating_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class SkatingCategoriesAnalysisWidget extends StatefulWidget {
  final int playerId;
  final String? ageGroup;
  final String? position;
  final String? skillLevel;  // Added skill level support
  final String? gender;      // Added gender support
  final Map<String, dynamic>? filters;

  const SkatingCategoriesAnalysisWidget({
    Key? key,
    required this.playerId,
    this.ageGroup,
    this.position,
    this.skillLevel = 'competitive',
    this.gender,
    this.filters,
  }) : super(key: key);

  @override
  _SkatingCategoriesAnalysisWidgetState createState() => _SkatingCategoriesAnalysisWidgetState();
}

class _SkatingCategoriesAnalysisWidgetState extends State<SkatingCategoriesAnalysisWidget> {
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _categoryMetrics = {};
  Map<String, dynamic> _recommendationsData = {};
  List<Map<String, dynamic>> _priorityAreas = [];
  String? _playerAgeCategory;
  String? _benchmarkVersion;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  @override
  void didUpdateWidget(SkatingCategoriesAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if player ID or filters changed
    if (oldWidget.playerId != widget.playerId || 
        oldWidget.filters.toString() != widget.filters.toString() ||
        oldWidget.skillLevel != widget.skillLevel ||
        oldWidget.gender != widget.gender) {
      _fetchAnalytics();
    }
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Build URL with filters if provided
      String url = '${ApiConfig.baseUrl}/api/analytics/skating/${widget.playerId}/categories';
      
      final queryParams = <String>[];
      
      // Add skill level and gender to query
      if (widget.skillLevel != null) {
        queryParams.add('skillLevel=${widget.skillLevel}');
      }
      if (widget.gender != null) {
        queryParams.add('gender=${widget.gender}');
      }
      
      // Add benchmark version
      queryParams.add('benchmarkVersion=3.0');
      
      if (widget.filters != null && widget.filters!.isNotEmpty) {
        widget.filters!.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              queryParams.add('$key=$item');
            }
          } else if (value != null) {
            queryParams.add('$key=$value');
          }
        });
      }
      
      if (queryParams.isNotEmpty) {
        url += '?' + queryParams.join('&');
      }

      // Fetch metrics from API
      final response = await http.get(
        Uri.parse(url),
        headers: await ApiConfig.getHeaders(),
      );

      // Fetch recommendations for enhanced insights
      final recommendationsUrl = Uri.parse(
        '${ApiConfig.baseUrl}/api/skating/recommendations/${widget.playerId}'
      ).replace(queryParameters: {
        if (widget.skillLevel != null) 'skillLevel': widget.skillLevel!,
        if (widget.gender != null) 'gender': widget.gender!,
        'version': '3.0',
      });
      
      final recommendationsResponse = await http.get(
        recommendationsUrl,
        headers: await ApiConfig.getHeaders(),
      );

      Map<String, Map<String, dynamic>> categoryMetrics = {};
      Map<String, dynamic> recommendationsData = {};
      List<Map<String, dynamic>> priorityAreas = [];
      String? playerAgeCategory;
      String? benchmarkVersion;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract benchmark version info
        benchmarkVersion = data['benchmark_version'] as String? ?? '3.0';
        
        // Extract category scores and assessments count
        if (data.containsKey('category_scores')) {
          final categoryScores = data['category_scores'] as Map<String, dynamic>;
          final assessmentCounts = data['assessment_counts'] as Map<String, dynamic>? ?? {};
          final averageTimes = data['average_times'] as Map<String, dynamic>? ?? {};
          final bestTimes = data['best_times'] as Map<String, dynamic>? ?? {};
          final percentileRankings = data['percentile_rankings'] as Map<String, dynamic>? ?? {};
          
          for (var category in categoryScores.keys) {
            final score = (categoryScores[category] as num?)?.toDouble() ?? 0.0;
            final count = assessmentCounts[category] as int? ?? 0;
            final avgTime = (averageTimes[category] as num?)?.toDouble() ?? 0.0;
            final bestTime = (bestTimes[category] as num?)?.toDouble() ?? 0.0;
            final percentile = (percentileRankings[category] as num?)?.toDouble() ?? 0.0;
            
            categoryMetrics[category] = {
              'score': score,
              'count': count,
              'averageTime': avgTime,
              'bestTime': bestTime,
              'percentile': percentile,
              'improvement': SkatingUtils.calculateImprovement(avgTime, bestTime),
              'trend': SkatingUtils.calculateTrend(score, percentile),
              'benchmarkLevel': SkatingUtils.getUpdatedBenchmarkLevelFromScore(score), // Use updated method
            };
          }
        }
      }

      // Process recommendations data for additional insights
      if (recommendationsResponse.statusCode == 200) {
        recommendationsData = json.decode(recommendationsResponse.body);
        
        // Extract player age category
        playerAgeCategory = recommendationsData['player_info']?['age_category'];
        
        // Extract priority focus areas
        if (recommendationsData.containsKey('priority_focus_areas')) {
          priorityAreas = List<Map<String, dynamic>>.from(
            recommendationsData['priority_focus_areas'] as List
          );
        }
      }
      
      setState(() {
        _categoryMetrics = categoryMetrics;
        _recommendationsData = recommendationsData;
        _priorityAreas = priorityAreas;
        _playerAgeCategory = playerAgeCategory;
        _benchmarkVersion = benchmarkVersion;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _error = e.toString();
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
      return Center(child: Text('Error: $_error'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Skating Categories Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        
        StandardCard(
          borderRadius: 12,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Benchmark version indicator
                _buildBenchmarkVersionIndicator(),
                
                const SizedBox(height: 12),
                
                // Player info row
                Row(
                  children: [
                    if (_playerAgeCategory != null) ...[
                      Icon(
                        Icons.person,
                        size: 16,
                        color: Colors.blueGrey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Age Group: ${SkatingUtils.formatAgeCategory(_playerAgeCategory!)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    
                    if (widget.skillLevel != null) ...[
                      const SizedBox(width: 16),
                      StatusBadge(
                        text: SkatingUtils.formatSkillLevel(widget.skillLevel!),
                        color: Colors.blue,
                        size: StatusBadgeSize.small,
                        shape: StatusBadgeShape.pill,
                      ),
                    ],
                    
                    if (widget.gender != null && _shouldShowGender()) ...[
                      const SizedBox(width: 8),
                      Icon(
                        widget.gender == 'male' ? Icons.male : Icons.female,
                        size: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Priority areas summary
                if (_priorityAreas.isNotEmpty) ...[
                  _buildPriorityAreasPreview(),
                  const SizedBox(height: 20),
                ],

                // Category breakdown
                if (_categoryMetrics.isNotEmpty) ...[
                  ..._categoryMetrics.entries.map((entry) {
                    final category = entry.key;
                    final metrics = entry.value;
                    final score = metrics['score'] as double;
                    final count = metrics['count'] as int;
                    final avgTime = metrics['averageTime'] as double;
                    final bestTime = metrics['bestTime'] as double;
                    final percentile = metrics['percentile'] as double;
                    final improvement = metrics['improvement'] as double;
                    final trend = metrics['trend'] as String;
                    final benchmarkLevel = metrics['benchmarkLevel'] as String;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  SkatingUtils.getCategoryIcon(category),
                                  size: 20,
                                  color: SkatingUtils.getUpdatedScoreColor(score), // Use updated method
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  SkatingUtils.formatCategoryName(category),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                StatusBadge(
                                  text: '$count tests',
                                  color: Colors.blueGrey[600]!,
                                  size: StatusBadgeSize.small,
                                  withBorder: false,
                                ),
                                const SizedBox(width: 8),
                                StatusBadge(
                                  text: benchmarkLevel, // Show benchmark level instead of trend
                                  color: SkatingUtils.getUpdatedBenchmarkColor(benchmarkLevel),
                                  size: StatusBadgeSize.small,
                                  shape: StatusBadgeShape.pill,
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Score: ${score.toStringAsFixed(1)}/10',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: SkatingUtils.getUpdatedScoreColor(score), // Use updated method
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (percentile > 0) ...[
                              const SizedBox(width: 8),
                              Text(
                                '${percentile.toStringAsFixed(0)}th percentile',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: SkatingUtils.getUpdatedPercentileColor(percentile), // Use updated method
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: score / 10.0,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                              SkatingUtils.getUpdatedScoreColor(score)), // Use updated method
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        if (avgTime > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Avg Time: ${avgTime.toStringAsFixed(2)}s',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey[600],
                                  ),
                                ),
                              ),
                              if (bestTime > 0)
                                Text(
                                  'Best: ${bestTime.toStringAsFixed(2)}s',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (improvement > 0) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.trending_up,
                                size: 14,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${improvement.toStringAsFixed(1)}% improvement potential',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 32),
                      ],
                    );
                  }).toList(),
                ] else
                  _buildNoDataWidget(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBenchmarkVersionIndicator() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.science, color: Colors.green[600], size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Research-based benchmarks v${_benchmarkVersion ?? "3.0"} - Realistic performance standards',
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

  Widget _buildPriorityAreasPreview() {
    final topPriorities = _priorityAreas.take(2).toList();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.priority_high,
                color: Colors.orange[600],
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Priority Development Areas',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...topPriorities.map((priority) {
            final area = priority['area'] as String;
            final priorityLevel = priority['priority_level'] as String;
            final description = priority['description'] as String;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(
                    text: priorityLevel,
                    color: _getPriorityColor(priorityLevel),
                    size: StatusBadgeSize.small,
                    shape: StatusBadgeShape.rounded,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          area,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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

  Widget _buildNoDataWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.speed,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'No skating category data available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Complete skating assessments to see category analysis',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget-specific UI color function (not moved to utils as it's UI-specific)
  Color _getPriorityColor(String priorityLevel) {
    switch (priorityLevel.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'moderate':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
  
  bool _shouldShowGender() {
    // Show gender information for age groups 15+ where gender-specific standards apply
    return widget.gender != null && 
           (widget.ageGroup == 'youth_15_18' || widget.ageGroup == 'adult');
  }
}