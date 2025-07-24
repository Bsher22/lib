import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:hockey_shot_tracker/utils/analytics_constants.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';

class PerformanceMetricsCard extends StatefulWidget {
  final int playerId;
  final Map<String, dynamic>? filters;
  final SkillType skillType;

  const PerformanceMetricsCard({
    Key? key,
    required this.playerId,
    this.filters,
    this.skillType = SkillType.shooting, // Default to shooting for backward compatibility
  }) : super(key: key);

  @override
  _PerformanceMetricsCardState createState() => _PerformanceMetricsCardState();
}

class _PerformanceMetricsCardState extends State<PerformanceMetricsCard> {
  bool _isLoading = true;
  Map<String, dynamic> _playerMetrics = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchMetrics();
  }

  @override
  void didUpdateWidget(PerformanceMetricsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if player ID, filters, or skill type changed
    if (oldWidget.playerId != widget.playerId || 
        oldWidget.filters.toString() != widget.filters.toString() ||
        oldWidget.skillType != widget.skillType) {
      _fetchMetrics();
    }
  }

  Future<void> _fetchMetrics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Build URL with filters if provided
      String baseUrl = widget.skillType == SkillType.shooting
          ? '${ApiConfig.baseUrl}/api/analytics/${widget.playerId}'
          : '${ApiConfig.baseUrl}/api/analytics/skating/${widget.playerId}/metrics';
      
      if (widget.filters != null && widget.filters!.isNotEmpty) {
        final queryParams = [];
        
        widget.filters!.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              queryParams.add('$key=$item');
            }
          } else if (value != null) {
            queryParams.add('$key=$value');
          }
        });
        
        if (queryParams.isNotEmpty) {
          baseUrl += '?' + queryParams.join('&');
        }
      }

      // Fetch metrics from API
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          _playerMetrics = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load metrics';
          _isLoading = false;
        });
      }
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
          widget.skillType == SkillType.shooting 
              ? 'Performance Metrics'
              : 'Skating Performance Metrics',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        widget.skillType == SkillType.shooting
            ? _buildShotMetrics()
            : _buildSkatingMetrics(),
      ],
    );
  }

  Widget _buildShotMetrics() {
    // Extract shot metrics from API response
    final successRate = _playerMetrics['overall_success_rate'] as double? ?? 0.0;
    final avgPower = _playerMetrics['average_power'] as double? ?? 0.0;
    final avgQuickRelease = _playerMetrics['average_quick_release'] as double? ?? 0.0;
    final totalShots = _playerMetrics['total_shots'] as int? ?? 0;

    // Check if all metrics are 0 (indicating no data)
    if (successRate == 0.0 && avgPower == 0.0 && avgQuickRelease == 0.0 && totalShots == 0) {
      return const Center(
        child: Text(
          'No performance metrics available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          'Success Rate',
          '${(successRate * 100).toStringAsFixed(1)}%',
          Icons.check_circle_outline,
          ColorHelper.getSuccessRateColor(successRate),
          ColorHelper.getSuccessRateDescription(successRate),
        ),
        _buildMetricCard(
          'Total Shots',
          totalShots.toString(),
          Icons.sports_hockey,
          Colors.blue,
          ColorHelper.getVolumeDescription(totalShots),
        ),
        _buildMetricCard(
          'Shot Power',
          '${avgPower.toStringAsFixed(1)} mph',
          Icons.bolt,
          ColorHelper.getPowerColor(avgPower),
          ColorHelper.getPowerDescription(avgPower),
        ),
        _buildMetricCard(
          'Quick Release',
          '${avgQuickRelease.toStringAsFixed(2)} sec',
          Icons.timer,
          ColorHelper.getQuickReleaseColor(avgQuickRelease),
          ColorHelper.getQuickReleaseDescription(avgQuickRelease),
        ),
      ],
    );
  }

  Widget _buildSkatingMetrics() {
    // Extract skating metrics from API response
    final overallScore = (_playerMetrics['overall_score'] as num?)?.toDouble() ?? 0.0;
    final totalAssessments = _playerMetrics['total_assessments'] as int? ?? 0;
    final avgForwardSpeed = (_playerMetrics['avg_forward_speed'] as num?)?.toDouble() ?? 0.0;
    final avgBackwardSpeed = (_playerMetrics['avg_backward_speed'] as num?)?.toDouble() ?? 0.0;
    final avgAgility = (_playerMetrics['avg_agility'] as num?)?.toDouble() ?? 0.0;
    final avgTransitions = (_playerMetrics['avg_transitions'] as num?)?.toDouble() ?? 0.0;

    // Check if all metrics are 0 (indicating no data)
    if (overallScore == 0.0 && totalAssessments == 0) {
      return const Center(
        child: Text(
          'No skating metrics available',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildMetricCard(
          'Overall Score',
          '${overallScore.toStringAsFixed(1)}/10',
          Icons.trending_up,
          ColorHelper.getScoreColor(overallScore),
          _getScoreDescription(overallScore),
        ),
        _buildMetricCard(
          'Assessments',
          totalAssessments.toString(),
          Icons.assignment,
          Colors.blue,
          _getAssessmentVolumeDescription(totalAssessments),
        ),
        _buildMetricCard(
          'Forward Speed',
          '${avgForwardSpeed.toStringAsFixed(1)}/10',
          Icons.keyboard_double_arrow_right,
          ColorHelper.getScoreColor(avgForwardSpeed),
          _getScoreDescription(avgForwardSpeed),
        ),
        _buildMetricCard(
          'Agility',
          '${avgAgility.toStringAsFixed(1)}/10',
          Icons.change_circle,
          ColorHelper.getScoreColor(avgAgility),
          _getScoreDescription(avgAgility),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color, String description) {
    return StandardCard(
      elevation: 2,
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 4),
              StatusBadge(
                text: description,
                color: color,
                size: StatusBadgeSize.small,
                shape: StatusBadgeShape.pill,
                withBorder: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getScoreDescription(double score) {
    if (score >= 8.0) return 'Elite';
    if (score >= 6.5) return 'Advanced';
    if (score >= 5.0) return 'Intermediate';
    if (score >= 3.5) return 'Developing';
    return 'Beginner';
  }

  String _getAssessmentVolumeDescription(int count) {
    if (count >= 20) return 'High volume';
    if (count >= 10) return 'Good volume';
    if (count >= 5) return 'Moderate volume';
    return 'Low volume';
  }
}