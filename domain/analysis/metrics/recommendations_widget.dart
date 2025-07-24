import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/analytics_constants.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class RecommendationsWidget extends StatefulWidget {
  final int playerId;
  final String? assessmentId;
  final Map<String, dynamic>? filters;
  final SkillType skillType;

  const RecommendationsWidget({
    Key? key,
    required this.playerId,
    this.assessmentId,
    this.filters,
    this.skillType = SkillType.shooting, // Default to shooting for backward compatibility
  }) : super(key: key);

  @override
  _RecommendationsWidgetState createState() => _RecommendationsWidgetState();
}

class _RecommendationsWidgetState extends State<RecommendationsWidget> {
  bool _isLoading = true;
  Map<String, dynamic>? _recommendations;
  String? _error;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    // FIXED: Use ApiConfig.baseUrl instead of hardcoded placeholder
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
    _fetchRecommendations();
  }

  @override
  void didUpdateWidget(RecommendationsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if player ID, assessment ID, or skill type changed
    if (oldWidget.playerId != widget.playerId || 
        oldWidget.assessmentId != widget.assessmentId ||
        oldWidget.skillType != widget.skillType) {
      _fetchRecommendations();
    }
  }

  @override
  void dispose() {
    // Proper cleanup
    super.dispose();
  }

  Future<void> _fetchRecommendations() async {
    if (!mounted) return;
    
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      Map<String, dynamic>? recommendations;
      
      try {
        recommendations = await _apiService.getRecommendations(
          widget.playerId,
          assessmentId: widget.assessmentId,
          context: mounted ? context : null,
        );
      } catch (e) {
        print('Error fetching recommendations from API: $e');
        // Fall back to generating local recommendations if API fails
        recommendations = _generateFallbackRecommendations();
      }

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _fetchRecommendations: $e');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Map<String, dynamic> _generateFallbackRecommendations() {
    // Generate basic recommendations based on skill type
    switch (widget.skillType) {
      case SkillType.shooting:
        return {
          'recommendations': [
            {
              'title': 'Accuracy Training',
              'description': 'Focus on target practice to improve shot precision',
              'priority': 'high',
              'type': 'drill'
            },
            {
              'title': 'Power Development',
              'description': 'Work on wrist and forearm strength for harder shots',
              'priority': 'medium',
              'type': 'fitness'
            },
            {
              'title': 'Quick Release',
              'description': 'Practice getting shots off faster',
              'priority': 'medium',
              'type': 'technique'
            }
          ],
          'overall_assessment': 'Continue working on fundamentals',
          'next_focus_areas': ['accuracy', 'power']
        };
      case SkillType.skating:
        return {
          'recommendations': [
            {
              'title': 'Edge Work',
              'description': 'Focus on tight turns and edge control',
              'priority': 'high',
              'type': 'technique'
            },
            {
              'title': 'Speed Development',
              'description': 'Work on acceleration and top speed',
              'priority': 'medium',
              'type': 'fitness'
            }
          ],
          'overall_assessment': 'Solid skating foundation',
          'next_focus_areas': ['agility', 'speed']
        };
      default:
        return {
          'recommendations': [
            {
              'title': 'General Skills',
              'description': 'Continue practicing fundamental skills',
              'priority': 'medium',
              'type': 'general'
            }
          ],
          'overall_assessment': 'Keep up the good work',
          'next_focus_areas': ['fundamentals']
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(height: 8),
                    Text(
                      'Unable to load recommendations',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                    const SizedBox(height: 4),
                    ElevatedButton(
                      onPressed: _fetchRecommendations,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_recommendations != null)
              _buildRecommendationsContent()
            else
              const Center(
                child: Text('No recommendations available'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsContent() {
    final recommendations = _recommendations!['recommendations'] as List<dynamic>? ?? [];
    final overallAssessment = _recommendations!['overall_assessment'] as String? ?? '';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overallAssessment.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Text(
              overallAssessment,
              style: TextStyle(
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        ...recommendations.map((rec) => _buildRecommendationItem(rec)).toList(),
      ],
    );
  }

  Widget _buildRecommendationItem(dynamic recommendation) {
    final recMap = recommendation as Map<String, dynamic>;
    final title = recMap['title'] as String? ?? 'Recommendation';
    final description = recMap['description'] as String? ?? '';
    final priority = recMap['priority'] as String? ?? 'medium';
    final type = recMap['type'] as String? ?? 'general';
    
    Color priorityColor;
    IconData priorityIcon;
    
    switch (priority.toLowerCase()) {
      case 'high':
        priorityColor = Colors.red;
        priorityIcon = Icons.priority_high;
        break;
      case 'low':
        priorityColor = Colors.green;
        priorityIcon = Icons.low_priority;
        break;
      default:
        priorityColor = Colors.orange;
        priorityIcon = Icons.remove;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            priorityIcon,
            color: priorityColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type.toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}