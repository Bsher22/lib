// lib/widgets/domain/assessment/skating/skating_result_recommendations_tab.dart
// Complete Web-Compatible Version - Fixed RecommendedDrillCard usage

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/training/recommended_drill_card.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class SkatingResultRecommendationsTab extends StatefulWidget {
  final Map<String, dynamic> results;
  final int? playerId;
  final String? assessmentId;
  
  const SkatingResultRecommendationsTab({
    Key? key,
    required this.results,
    this.playerId,
    this.assessmentId,
  }) : super(key: key);

  @override
  State<SkatingResultRecommendationsTab> createState() => _SkatingResultRecommendationsTabState();
}

class _SkatingResultRecommendationsTabState extends State<SkatingResultRecommendationsTab> {
  final TextEditingController _notesController = TextEditingController();
  
  // Backend recommendation state - Fixed to List type
  List<Map<String, dynamic>> _backendRecommendations = [];
  bool _isLoadingRecommendations = false;
  String? _recommendationError;
  
  // ApiService instance
  ApiService? _apiService;
  
  @override
  void initState() {
    super.initState();
    _initializeApiService();
    _loadBackendRecommendations();
  }
  
  void _initializeApiService() {
    try {
      _apiService = ApiService(
        baseUrl: ApiConfig.baseUrl,
        onTokenExpired: (context) {
          if (context != null) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize ApiService: $e');
      setState(() {
        _recommendationError = 'API service initialization failed';
      });
    }
  }
  
  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendRecommendations() async {
    if (widget.playerId == null) {
      setState(() {
        _recommendationError = 'No player ID provided for backend recommendations';
      });
      return;
    }

    if (_apiService == null) {
      setState(() {
        _recommendationError = 'API service not available';
      });
      return;
    }

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      final response = await _apiService!.fetchSkatingRecommendations(
        widget.playerId!,
        assessmentId: widget.assessmentId,
        context: context,
      );

      setState(() {
        _backendRecommendations = response; // Now correctly assigns List
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      try {
        await _loadBackendRecommendationsAlternative();
      } catch (e2) {
        setState(() {
          _recommendationError = 'Failed to load backend recommendations: ${e.toString()}';
          _isLoadingRecommendations = false;
        });
        debugPrint('Backend recommendations failed, using local fallback: $e');
      }
    }
  }

  Future<void> _loadBackendRecommendationsAlternative() async {
    if (_apiService == null) return;

    try {
      final queryParams = <String, String>{
        'skill_level': 'competitive',
      };
      
      if (widget.assessmentId != null) {
        queryParams['assessment_id'] = widget.assessmentId!;
      }

      // Using the new web-compatible get method with queryParameters
      final response = await _apiService!.get(
        '/skating/recommendations/${widget.playerId}',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['success'] == true) {
          final recommendations = data['data']?['recommendations'] ?? data['recommendations'] ?? [];
          setState(() {
            _backendRecommendations = List<Map<String, dynamic>>.from(recommendations);
            _isLoadingRecommendations = false;
          });
        } else {
          throw Exception(data['message'] ?? 'Failed to load recommendations');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: Failed to load recommendations');
      }
    } catch (e) {
      setState(() {
        _recommendationError = 'Failed to load backend recommendations: ${e.toString()}';
        _isLoadingRecommendations = false;
      });
      rethrow;
    }
  }

  // ==========================================
  // MISSING METHODS IMPLEMENTATION
  // ==========================================

  /// Get strengths list from results data
  List<String> _getStrengthsList() {
    final strengths = <String>[];
    
    // Check backend recommendations first
    if (_backendRecommendations.isNotEmpty) {
      for (final recommendation in _backendRecommendations) {
        final backendStrengths = recommendation['strengths'] as List<dynamic>? ?? [];
        strengths.addAll(backendStrengths.cast<String>());
      }
      
      if (strengths.isNotEmpty) {
        return strengths.take(5).toList(); // Limit to top 5
      }
    }
    
    // Fallback to local analysis
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    final improvements = (widget.results['improvements'] as List<dynamic>?)?.cast<String>() ?? [];
    
    // Identify strengths based on high scores (7.0+ out of 10)
    for (final entry in scores.entries) {
      if (entry.key != 'Overall' && (entry.value as double?) != null && (entry.value as double) >= 7.0) {
        String strengthDescription = _getStrengthDescription(entry.key, entry.value as double);
        if (strengthDescription.isNotEmpty) {
          strengths.add(strengthDescription);
        }
      }
    }
    
    // Add general strengths if scores are good but not excellent
    final overallScore = (scores['Overall'] as double?) ?? 0.0;
    if (overallScore >= 6.0 && strengths.isEmpty) {
      strengths.add('Solid fundamental skating mechanics with good balance and control');
    }
    
    if (overallScore >= 5.0 && improvements.length <= 2) {
      strengths.add('Consistent skating performance across multiple test categories');
    }
    
    return strengths.take(5).toList();
  }

  /// Get improvements list from results data
  List<String> _getImprovementsList() {
    final improvements = <String>[];
    
    // Check backend recommendations first
    if (_backendRecommendations.isNotEmpty) {
      for (final recommendation in _backendRecommendations) {
        final backendImprovements = recommendation['improvements'] as List<dynamic>? ?? [];
        final priorityAreas = recommendation['priority_focus_areas'] as List<dynamic>? ?? [];
        
        improvements.addAll(backendImprovements.cast<String>());
        for (final area in priorityAreas) {
          if (area is Map && area['area'] != null) {
            improvements.add(area['area'] as String);
          }
        }
      }
      
      if (improvements.isNotEmpty) {
        return improvements.take(6).toList(); // Limit to top 6
      }
    }
    
    // Fallback to local analysis
    final localImprovements = (widget.results['improvements'] as List<dynamic>?)?.cast<String>() ?? [];
    improvements.addAll(localImprovements);
    
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    
    // Add improvements based on low scores (below 5.0)
    for (final entry in scores.entries) {
      if (entry.key != 'Overall' && (entry.value as double?) != null && (entry.value as double) < 5.0) {
        String improvementDescription = _getImprovementDescription(entry.key, entry.value as double);
        if (improvementDescription.isNotEmpty && !improvements.contains(improvementDescription)) {
          improvements.add(improvementDescription);
        }
      }
    }
    
    // Add general improvements if list is empty
    if (improvements.isEmpty) {
      improvements.addAll([
        'Continue developing fundamental skating skills',
        'Focus on consistent technique and form',
        'Build skating endurance and power',
      ]);
    }
    
    return improvements.take(6).toList();
  }

  /// Build recommended drills widget - FIXED to use factory constructor
  Widget _buildRecommendedDrills({bool enhanced = false}) {
    List<Map<String, dynamic>> drills = [];
    
    // Check backend recommendations first
    if (_backendRecommendations.isNotEmpty) {
      for (final recommendation in _backendRecommendations) {
        final backendDrills = recommendation['training_drills'] as List<dynamic>? ?? [];
        for (final drill in backendDrills) {
          if (drill is Map<String, dynamic>) {
            drills.add(drill);
          }
        }
      }
    }
    
    // Fallback to local drills
    if (drills.isEmpty) {
      drills = _getLocalDrills();
    }
    
    if (drills.isEmpty) {
      return Padding(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          children: [
            Icon(
              Icons.info_outline,
              size: ResponsiveConfig.iconSize(context, 48),
              color: Colors.grey[400],
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'No specific drills available at this time.',
              baseFontSize: 16,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Focus on fundamental skating skills and consult with your coach for personalized training recommendations.',
              baseFontSize: 14,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: drills.map((drill) => Padding(
        padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 16)),
        child: enhanced 
          ? RecommendedDrillCard.fromDrill(  // FIXED: Use factory constructor
              drill: drill,
              isExpanded: true,
            )
          : _buildSimpleDrillCard(drill),
      )).toList(),
    );
  }

  /// Build training plan widget
  Widget _buildTrainingPlan({bool enhanced = false}) {
    Map<String, dynamic> trainingPlan = {};
    
    // Check backend recommendations first
    if (_backendRecommendations.isNotEmpty) {
      for (final recommendation in _backendRecommendations) {
        final backendPlan = recommendation['training_plan'] as Map<String, dynamic>? ?? {};
        if (backendPlan.isNotEmpty) {
          trainingPlan = backendPlan;
          break;
        }
      }
    }
    
    // Fallback to local training plan
    if (trainingPlan.isEmpty) {
      trainingPlan = _getLocalTrainingPlan();
    }
    
    final intensity = trainingPlan['intensity'] as String? ?? 'Foundation Building';
    final week1Sessions = (trainingPlan['week1'] as List<dynamic>?)?.cast<String>() ?? [];
    final week2Sessions = (trainingPlan['week2'] as List<dynamic>?)?.cast<String>() ?? [];
    final week3Sessions = (trainingPlan['week3'] as List<dynamic>?)?.cast<String>() ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Intensity level
        Container(
          padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getIntensityColor(intensity).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _getIntensityColor(intensity).withOpacity(0.3)),
          ),
          child: ResponsiveText(
            intensity,
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _getIntensityColor(intensity),
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Weekly plan
        if (enhanced) ...[
          _buildEnhancedWeeklyPlan(week1Sessions, week2Sessions, week3Sessions),
        ] else ...[
          _buildSimpleWeeklyPlan(week1Sessions, week2Sessions, week3Sessions),
        ],
        
        ResponsiveSpacing(multiplier: 2),
        
        // Training tips
        Container(
          padding: ResponsiveConfig.paddingAll(context, 12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    'Training Tips',
                    baseFontSize: 14,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ],
              ),
              ResponsiveSpacing(multiplier: 1),
              ResponsiveText(
                '• Allow 48 hours rest between high-intensity sessions\n'
                '• Focus on technique quality over speed initially\n'
                '• Progress gradually and listen to your body\n'
                '• Consider working with a qualified skating coach',
                baseFontSize: 12,
                style: TextStyle(color: Colors.blue[700]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // HELPER METHODS
  // ==========================================

  String _getStrengthDescription(String category, double score) {
    final scoreDescription = score >= 9.0 ? 'exceptional' : score >= 8.0 ? 'strong' : 'good';
    
    switch (category.toLowerCase()) {
      case 'forward_speed_test':
      case 'forward speed':
        return 'Demonstrates $scoreDescription forward skating speed and acceleration';
      case 'backward_speed_test':
      case 'backward speed':
        return 'Shows $scoreDescription backward skating ability and c-cut technique';
      case 'crossover_test':
      case 'crossovers':
        return 'Exhibits $scoreDescription crossover technique and edge control';
      case 'agility_test':
      case 'agility':
        return 'Displays $scoreDescription agility and quick direction changes';
      case 'transition_test':
      case 'transitions':
        return 'Maintains $scoreDescription transition skills between forward and backward';
      default:
        return 'Shows $scoreDescription performance in ${category.toLowerCase().replaceAll('_', ' ')}';
    }
  }

  String _getImprovementDescription(String category, double score) {
    switch (category.toLowerCase()) {
      case 'forward_speed_test':
      case 'forward speed':
        return 'Work on forward skating stride mechanics and first-step acceleration';
      case 'backward_speed_test':
      case 'backward speed':
        return 'Focus on backward c-cut technique and maintaining speed while skating backward';
      case 'crossover_test':
      case 'crossovers':
        return 'Develop crossover technique, edge control, and power in tight turns';
      case 'agility_test':
      case 'agility':
        return 'Improve quick direction changes, body control, and reactive agility';
      case 'transition_test':
      case 'transitions':
        return 'Enhance transition speed and smoothness between forward and backward skating';
      default:
        return 'Focus on improving ${category.toLowerCase().replaceAll('_', ' ')} fundamentals';
    }
  }

  Widget _buildSimpleDrillCard(Map<String, dynamic> drill) {
    final name = drill['name'] as String? ?? 'Skating Drill';
    final description = drill['description'] as String? ?? 'Fundamental skating practice';
    final repetitions = drill['repetitions'] as String? ?? '3 sets';
    final keyPoints = (drill['keyPoints'] as List<dynamic>?)?.cast<String>() ?? 
                     (drill['key_points'] as List<dynamic>?)?.cast<String>() ?? [];
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            name,
            baseFontSize: 16,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            description,
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 1),
          Row(
            children: [
              Icon(Icons.repeat, size: ResponsiveConfig.iconSize(context, 16), color: Colors.green),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                repetitions,
                baseFontSize: 12,
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (keyPoints.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ...keyPoints.take(2).map((point) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 4)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: ResponsiveConfig.iconSize(context, 12), color: Colors.green),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  Expanded(
                    child: ResponsiveText(
                      point,
                      baseFontSize: 11,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleWeeklyPlan(List<String> week1, List<String> week2, List<String> week3) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildWeekSection('Week 1: Foundation', week1, Colors.blue),
        ResponsiveSpacing(multiplier: 1.5),
        _buildWeekSection('Week 2: Development', week2, Colors.orange),
        ResponsiveSpacing(multiplier: 1.5),
        _buildWeekSection('Week 3: Integration', week3, Colors.green),
      ],
    );
  }

  Widget _buildEnhancedWeeklyPlan(List<String> week1, List<String> week2, List<String> week3) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildWeekSection('Week 1', week1, Colors.blue)),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        Expanded(child: _buildWeekSection('Week 2', week2, Colors.orange)),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        Expanded(child: _buildWeekSection('Week 3', week3, Colors.green)),
      ],
    );
  }

  Widget _buildWeekSection(String title, List<String> sessions, Color color) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            title,
            baseFontSize: 14,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          ResponsiveSpacing(multiplier: 1),
          ...sessions.map((session) => Padding(
            padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 6)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.circle, size: ResponsiveConfig.iconSize(context, 6), color: color),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    session,
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[700]),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Color _getIntensityColor(String intensity) {
    switch (intensity.toLowerCase()) {
      case 'elite performance program':
        return Colors.red;
      case 'advanced development program':
        return Colors.orange;
      case 'progressive development program':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  List<Map<String, dynamic>> _getLocalDrills() {
    final improvements = (widget.results['improvements'] as List<dynamic>?)?.cast<String>() ?? [];
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    final drills = <Map<String, dynamic>>[];
    
    for (var improvement in improvements) {
      if (improvement.contains('Forward Speed') || improvement.contains('forward_speed_test')) {
        drills.add({
          'name': 'Acceleration Sprints',
          'description': 'Sprint drills focusing on first 3-5 strides acceleration with emphasis on explosive starts and proper body positioning.',
          'repetitions': '5-6 sprints',
          'frequency': '2-3x per week',
          'keyPoints': [
            'Focus on first step explosion',
            'Keep body low during acceleration',
            'Full recovery between repetitions',
            'Gradually increase sprint distance'
          ],
          'priorityLevel': 'high'
        });
      } else if (improvement.contains('Backward Speed') || improvement.contains('backward_speed_test')) {
        drills.add({
          'name': 'C-Cuts Development Series',
          'description': 'Progressive backward skating drills focusing on powerful c-cuts while maintaining proper posture and balance.',
          'repetitions': '3 sets x 30 seconds',
          'frequency': '2x per week',
          'keyPoints': [
            'Keep chest up and head high',
            'Powerful push-off with full extension',
            'Maintain proper weight distribution',
            'Focus on rhythm and timing'
          ],
          'priorityLevel': 'medium'
        });
      }
    }
    
    if (drills.length < 2) {
      drills.addAll([
        {
          'name': 'Fundamental Skating Development',
          'description': 'Comprehensive skating drill that works on multiple aspects of skating in a progressive sequence.',
          'repetitions': '15-20 minutes',
          'frequency': '2x per week',
          'keyPoints': [
            'Progressive skill building',
            'Multiple skating elements',
            'Focus on areas needing development',
            'Maintain good technique throughout'
          ],
          'priorityLevel': 'medium'
        },
      ]);
    }
    
    return drills;
  }

  Map<String, dynamic> _getLocalTrainingPlan() {
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    final overallScore = (scores['Overall'] as double?) ?? 0.0;
    
    if (overallScore >= 6.0) {
      return {
        'intensity': 'Advanced Development',
        'week1': [
          'Session 1: High-intensity speed work and power development',
          'Session 2: Advanced agility patterns and decision making',
          'Session 3: Competition-specific movement patterns',
        ],
        'week2': [
          'Session 1: Plyometric skating and explosive movements',
          'Session 2: Small-area games with skating focus',
          'Session 3: Position-specific advanced techniques',
        ],
        'week3': [
          'Session 1: Game simulation with skating emphasis',
          'Session 2: Advanced edge work and technical refinement',
          'Session 3: High-intensity conditioning and skills integration',
        ],
      };
    } else if (overallScore >= 3.0) {
      return {
        'intensity': 'Progressive Development',
        'week1': [
          'Session 1: Fundamental technique refinement',
          'Session 2: Progressive speed development',
          'Session 3: Basic agility and direction changes',
        ],
        'week2': [
          'Session 1: Stride mechanics and power development',
          'Session 2: Intermediate agility patterns',
          'Session 3: Transition work and edge control',
        ],
        'week3': [
          'Session 1: Skills integration and game application',
          'Session 2: Speed endurance and conditioning',
          'Session 3: Position-specific movement patterns',
        ],
      };
    } else {
      return {
        'intensity': 'Foundation Building',
        'week1': [
          'Session 1: Basic stride mechanics and balance',
          'Session 2: Forward and backward skating fundamentals',
          'Session 3: Basic stopping and starting techniques',
        ],
        'week2': [
          'Session 1: Edge control and basic turns',
          'Session 2: Simple direction changes and crossovers',
          'Session 3: Building confidence and ice comfort',
        ],
        'week3': [
          'Session 1: Combining basic skills in simple patterns',
          'Session 2: Introduction to game-related movements',
          'Session 3: Fun skills practice and encouragement',
        ],
      };
    }
  }

  int _getRecommendedDrillsCount() {
    if (_backendRecommendations.isNotEmpty) {
      int totalDrills = 0;
      for (final recommendation in _backendRecommendations) {
        final trainingDrills = recommendation['training_drills'] as List<dynamic>? ?? [];
        totalDrills += trainingDrills.length;
      }
      return totalDrills.clamp(2, 6);
    }
    
    final improvements = (widget.results['improvements'] as List<dynamic>?)?.cast<String>() ?? [];
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    
    int drillCount = improvements.length;
    
    final lowScores = scores.entries.where((e) => 
      e.key != 'Overall' && (e.value as double) < 4.0).length;
    
    drillCount += lowScores;
    
    return (drillCount < 2 ? 2 : drillCount).clamp(2, 6);
  }

  // ==========================================
  // MAIN BUILD METHOD AND LAYOUTS
  // ==========================================
  
  @override
  Widget build(BuildContext context) {
    if (_isLoadingRecommendations) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent[700]!),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Loading personalized skating recommendations...',
              baseFontSize: 16,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout();
          case DeviceType.tablet:
            return _buildTabletLayout();
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
          _buildResearchBasisCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildStrengthsCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildImprovementsCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildRecommendedDrillsCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildTrainingPlanCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildCoachNotesCard(),
          if (widget.playerId != null || widget.assessmentId != null) ...[
            ResponsiveSpacing(multiplier: 2),
            _buildDebugCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildResearchBasisCard(),
          ResponsiveSpacing(multiplier: 2),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStrengthsCard(),
                    ResponsiveSpacing(multiplier: 2),
                    _buildImprovementsCard(),
                    ResponsiveSpacing(multiplier: 2),
                    _buildRecommendedDrillsCard(),
                  ],
                ),
              ),
              
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              
              Expanded(
                flex: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTrainingPlanCard(),
                    ResponsiveSpacing(multiplier: 2),
                    _buildCoachNotesCard(),
                    if (widget.playerId != null || widget.assessmentId != null) ...[
                      ResponsiveSpacing(multiplier: 2),
                      _buildDebugCard(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildResearchBasisCard(),
                ResponsiveSpacing(multiplier: 3),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStrengthsCard(),
                          ResponsiveSpacing(multiplier: 3),
                          _buildImprovementsCard(),
                        ],
                      ),
                    ),
                    
                    ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
                    
                    Expanded(
                      child: _buildRecommendedDrillsCard(enhanced: true),
                    ),
                  ],
                ),
                
                ResponsiveSpacing(multiplier: 3),
                _buildTrainingPlanCard(enhanced: true),
              ],
            ),
          ),
        ),
        
        Container(
          width: ResponsiveConfig.dimension(context, 300),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  // ==========================================
  // CARD WIDGETS
  // ==========================================

  Widget _buildResearchBasisCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 20)),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'Research-Based Assessment',
                  baseFontSize: 18,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                if (_backendRecommendations.isNotEmpty) ...[
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Container(
                    padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ResponsiveText(
                      'LIVE',
                      baseFontSize: 10,
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ],
              ],
            ),
            ResponsiveSpacing(multiplier: 1.5),
            ResponsiveText(
              _backendRecommendations.isNotEmpty
                ? 'These recommendations are generated by our advanced skating analysis engine, providing comprehensive recommendations based on analysis of 2,600+ hockey players.'
                : 'These recommendations are based on a systematic review of 60+ studies with 2,600+ hockey players, providing realistic and achievable performance standards.',
              baseFontSize: 12,
            ),
            ResponsiveSpacing(multiplier: 1),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: ResponsiveConfig.iconSize(context, 16)),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    _backendRecommendations.isNotEmpty
                      ? 'Live analysis with age-appropriate benchmarks and personalized development plans'
                      : 'Benchmarks now align with international hockey development norms',
                    baseFontSize: 11,
                    style: TextStyle(color: Colors.blueGrey[700], fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
            if (_recommendationError != null) ...[
              ResponsiveSpacing(multiplier: 1),
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  Expanded(
                    child: ResponsiveText(
                      'Using local fallback analysis - $_recommendationError',
                      baseFontSize: 10,
                      style: TextStyle(color: Colors.orange[700], fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStrengthsCard() {
    final strengths = _getStrengthsList();
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Strengths',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              if (_backendRecommendations.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ResponsiveText(
                    'AI',
                    baseFontSize: 10,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (strengths.isEmpty)
            Padding(
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: ResponsiveText(
                'Complete more assessments to identify strengths',
                baseFontSize: 14,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...strengths.map((strength) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(child: ResponsiveText(strength, baseFontSize: 14)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildImprovementsCard() {
    final improvements = _getImprovementsList();
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Development Opportunities',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              if (_backendRecommendations.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ResponsiveText(
                    'AI',
                    baseFontSize: 10,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (improvements.isEmpty)
            Padding(
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: ResponsiveText(
                'Continue practicing fundamental skating skills',
                baseFontSize: 14,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            )
          else
            ...improvements.map((improvement) => Padding(
              padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.arrow_circle_up, color: Colors.orange, size: ResponsiveConfig.iconSize(context, 16)),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  Expanded(child: ResponsiveText(improvement, baseFontSize: 14)),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendedDrillsCard({bool enhanced = false}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.purple, size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Recommended Training Drills',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              if (_backendRecommendations.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ResponsiveText(
                    'AI',
                    baseFontSize: 10,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildRecommendedDrills(enhanced: enhanced),
        ],
      ),
    );
  }

  Widget _buildTrainingPlanCard({bool enhanced = false}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.indigo, size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Recommended Training Plan',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              if (_backendRecommendations.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ResponsiveText(
                    'AI',
                    baseFontSize: 10,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildTrainingPlan(enhanced: enhanced),
        ],
      ),
    );
  }

  Widget _buildCoachNotesCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blueGrey, size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Coach Notes',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Add notes about player performance and recommendations...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 12),
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDebugCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Colors.grey, size: ResponsiveConfig.iconSize(context, 16)),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'Assessment Info',
                  baseFontSize: 16,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 1.5),
            
            if (widget.playerId != null)
              ResponsiveText('Player ID: ${widget.playerId}', baseFontSize: 12),
            if (widget.assessmentId != null)
              ResponsiveText('Assessment ID: ${widget.assessmentId}', baseFontSize: 12),
            ResponsiveText('Results Keys: ${widget.results.keys.toList()}', baseFontSize: 12),
            if (_backendRecommendations.isNotEmpty)
              ResponsiveText('Backend Status: Connected', baseFontSize: 12, style: TextStyle(color: Colors.green)),
            if (_recommendationError != null)
              ResponsiveText('Backend Status: Error', baseFontSize: 12, style: TextStyle(color: Colors.red)),
            ResponsiveText('API Base URL: ${ApiConfig.baseUrl}', baseFontSize: 10, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopSidebar() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuickSummaryCard(),
          ResponsiveSpacing(multiplier: 2),
          if (_backendRecommendations.isNotEmpty) _buildBackendInsightsCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildCoachNotesCard(),
          ResponsiveSpacing(multiplier: 2),
          if (widget.playerId != null || widget.assessmentId != null) _buildDebugCard(),
          ResponsiveSpacing(multiplier: 2),
          _buildActionButtonsCard(),
        ],
      ),
    );
  }

  Widget _buildQuickSummaryCard() {
    final strengths = _getStrengthsList();
    final improvements = _getImprovementsList();
    final scores = (widget.results['scores'] as Map<String, dynamic>?) ?? {};
    final overallScore = (scores['Overall'] as double?) ?? 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _backendRecommendations.isNotEmpty ? Icons.psychology : Icons.summarize,
                color: _backendRecommendations.isNotEmpty ? Colors.purple : Colors.blueGrey,
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Quick Summary',
                baseFontSize: 16,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
              ),
              if (_backendRecommendations.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ResponsiveText(
                    'AI',
                    baseFontSize: 10,
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildSummaryRow('Overall Score', '${overallScore.toStringAsFixed(1)}/10'),
          _buildSummaryRow('Strengths', '${strengths.length} identified'),
          _buildSummaryRow('Focus Areas', '${improvements.length} areas'),
          _buildSummaryRow('Drills Recommended', '${_getRecommendedDrillsCount()}'),
          if (_backendRecommendations.isNotEmpty) ...[
            _buildSummaryRow('Analysis Version', 'v3.0 Research-Based'),
            _buildSummaryRow('Data Source', 'Backend Engine'),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ResponsiveText(label, baseFontSize: 12, style: TextStyle(color: Colors.blueGrey[600])),
          ResponsiveText(value, baseFontSize: 12, style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildBackendInsightsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: Colors.purple, size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'AI Insights',
                baseFontSize: 16,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ResponsiveText(
                  'LIVE',
                  baseFontSize: 10,
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Backend recommendations loaded successfully with ${_backendRecommendations.length} recommendation sets',
            baseFontSize: 12,
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Actions',
            baseFontSize: 16,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          SizedBox(
            width: double.infinity,
            child: ResponsiveButton(
              text: 'Export Training Plan',
              onPressed: _exportTrainingPlan,
              baseHeight: 48,
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          SizedBox(
            width: double.infinity,
            child: ResponsiveButton(
              text: 'Share Recommendations',
              onPressed: _shareRecommendations,
              baseHeight: 48,
              backgroundColor: Colors.green[600],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          SizedBox(
            width: double.infinity,
            child: ResponsiveButton(
              text: 'Save Coach Notes',
              onPressed: _saveCoachNotes,
              baseHeight: 48,
              backgroundColor: Colors.blue[600],
            ),
          ),
          if (_backendRecommendations.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            SizedBox(
              width: double.infinity,
              child: ResponsiveButton(
                text: 'Refresh AI Analysis',
                onPressed: _loadBackendRecommendations,
                baseHeight: 48,
                backgroundColor: Colors.purple[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _exportTrainingPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Training plan export functionality coming soon'), duration: Duration(seconds: 2)),
    );
  }

  void _shareRecommendations() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share recommendations functionality coming soon'), duration: Duration(seconds: 2)),
    );
  }

  void _saveCoachNotes() {
    if (_notesController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Coach notes saved successfully'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter notes before saving'), duration: Duration(seconds: 2)),
      );
    }
  }
}