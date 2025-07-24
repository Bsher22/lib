// lib/widgets/domain/assessment/shot/shot_result_recommendations_tab.dart
// PHASE 4 UPDATE: Assessment Screen Responsive Design Implementation

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/widgets/domain/training/recommended_drill_card.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotResultRecommendationsTab extends StatefulWidget {
  final Map<String, dynamic> results;
  final int? playerId;
  final String? assessmentId;

  const ShotResultRecommendationsTab({
    Key? key,
    required this.results,
    this.playerId,
    this.assessmentId,
  }) : super(key: key);

  @override
  _ShotResultRecommendationsTabState createState() => _ShotResultRecommendationsTabState();
}

class _ShotResultRecommendationsTabState extends State<ShotResultRecommendationsTab> {
  final TextEditingController _notesController = TextEditingController();
  bool _isLoadingRecommendations = false;
  Map<String, dynamic>? _backendRecommendations;
  String? _recommendationError;
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
    _loadBackendRecommendations();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadBackendRecommendations() async {
    if (widget.playerId == null) return;

    setState(() {
      _isLoadingRecommendations = true;
      _recommendationError = null;
    });

    try {
      final recommendations = await _apiService.getRecommendations(
        widget.playerId!,
        assessmentId: widget.assessmentId,
        context: context,
      );

      setState(() {
        _backendRecommendations = recommendations;
        _isLoadingRecommendations = false;
      });
    } catch (e) {
      print('Error loading backend recommendations: $e');
      setState(() {
        _recommendationError = e.toString();
        _isLoadingRecommendations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Backend recommendations section
                if (_backendRecommendations != null)
                  _buildBackendRecommendations(deviceType, isLandscape)
                else if (_isLoadingRecommendations)
                  _buildLoadingState()
                else if (_recommendationError != null)
                  _buildErrorState()
                else
                  _buildFallbackRecommendations(deviceType, isLandscape),

                ResponsiveSpacing(multiplier: 2),

                // Coach notes section - responsive
                _buildCoachNotesSection(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoachNotesSection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note, 
                color: Colors.blueGrey, 
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Coach Notes',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              return TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  hintText: 'Add notes about player performance and recommendations...',
                  border: OutlineInputBorder(
                    borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  ),
                  contentPadding: ResponsiveConfig.paddingAll(context, 12),
                ),
                maxLines: deviceType.responsive<int>(
                  mobile: 3,
                  tablet: 4,
                  desktop: 5,
                ),
                style: TextStyle(fontSize: ResponsiveConfig.fontSize(context, 12)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            ResponsiveSpacing(multiplier: 1.5),
            ResponsiveText(
              'Analyzing performance data...',
              baseFontSize: 14,
              style: TextStyle(color: Colors.grey[600]),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Generating personalized recommendations',
              baseFontSize: 12,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_rounded, 
            color: Colors.orange, 
            size: ResponsiveConfig.iconSize(context, 40),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Unable to Load Advanced Recommendations',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            'Showing basic recommendations based on results',
            baseFontSize: 12,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ResponsiveButton(
            text: 'Retry',
            onPressed: _loadBackendRecommendations,
            baseHeight: 40,
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.refresh,
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildFallbackRecommendations(DeviceType.mobile, false),
        ],
      ),
    );
  }

  Widget _buildBackendRecommendations(DeviceType deviceType, bool isLandscape) {
    final recommendations = _backendRecommendations!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Responsive Header
        ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: Row(
            children: [
              Icon(
                Icons.psychology, 
                color: Colors.blue[700], 
                size: ResponsiveConfig.iconSize(context, 24),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'AI-Powered Analysis & Recommendations',
                      baseFontSize: 18,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                    ResponsiveText(
                      'Professional coaching insights based on your performance data',
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),

        // Responsive layout for recommendations
        _buildRecommendationsLayout(recommendations, deviceType, isLandscape),
      ],
    );
  }

  Widget _buildRecommendationsLayout(Map<String, dynamic> recommendations, DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileRecommendationsLayout(recommendations);
      case DeviceType.tablet:
        return _buildTabletRecommendationsLayout(recommendations);
      case DeviceType.desktop:
        return _buildDesktopRecommendationsLayout(recommendations);
    }
  }

  Widget _buildMobileRecommendationsLayout(Map<String, dynamic> recommendations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (recommendations['priority_focus_areas'] != null)
          _buildPriorityFocusAreas(recommendations['priority_focus_areas']),
        
        if (recommendations['mechanical_recommendations'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildMechanicalRecommendations(recommendations['mechanical_recommendations']),
        ],

        if (recommendations['training_drills'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTrainingDrills(recommendations['training_drills']),
        ],

        if (recommendations['timeline_expectations'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTimelineExpectations(recommendations['timeline_expectations']),
        ],
      ],
    );
  }

  Widget _buildTabletRecommendationsLayout(Map<String, dynamic> recommendations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row - Priority and Mechanical side by side
        if (recommendations['priority_focus_areas'] != null || 
            recommendations['mechanical_recommendations'] != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (recommendations['priority_focus_areas'] != null)
                Expanded(
                  child: _buildPriorityFocusAreas(recommendations['priority_focus_areas']),
                ),
              if (recommendations['priority_focus_areas'] != null && 
                  recommendations['mechanical_recommendations'] != null)
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              if (recommendations['mechanical_recommendations'] != null)
                Expanded(
                  child: _buildMechanicalRecommendations(recommendations['mechanical_recommendations']),
                ),
            ],
          ),

        // Training drills full width
        if (recommendations['training_drills'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTrainingDrills(recommendations['training_drills']),
        ],

        // Timeline full width
        if (recommendations['timeline_expectations'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTimelineExpectations(recommendations['timeline_expectations']),
        ],
      ],
    );
  }

  Widget _buildDesktopRecommendationsLayout(Map<String, dynamic> recommendations) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Three-column layout for desktop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recommendations['priority_focus_areas'] != null)
              Expanded(
                child: _buildPriorityFocusAreas(recommendations['priority_focus_areas']),
              ),
            if (recommendations['priority_focus_areas'] != null)
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            
            if (recommendations['mechanical_recommendations'] != null)
              Expanded(
                child: _buildMechanicalRecommendations(recommendations['mechanical_recommendations']),
              ),
            if (recommendations['mechanical_recommendations'] != null)
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            
            if (recommendations['training_drills'] != null)
              Expanded(
                child: _buildTrainingDrills(recommendations['training_drills']),
              ),
          ],
        ),

        // Timeline full width on desktop too
        if (recommendations['timeline_expectations'] != null) ...[
          ResponsiveSpacing(multiplier: 2),
          _buildTimelineExpectations(recommendations['timeline_expectations']),
        ],
      ],
    );
  }

  Widget _buildPriorityFocusAreas(List<dynamic> areas) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.flag, 
                color: Colors.red[600], 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Priority Focus Areas',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ...areas.map((area) => _buildPriorityFocusCard(area)).toList(),
        ],
      ),
    );
  }

  Widget _buildPriorityFocusCard(Map<String, dynamic> area) {
    final priority = area['priority_level'] as String? ?? 'Medium';
    final score = (area['score'] as num?)?.toDouble() ?? 0.5;
    final immediateActions = (area['immediate_actions'] as List?)?.cast<String>() ?? [];
    
    final priorityColor = _getPriorityColor(priority);
    
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
        color: priorityColor.withOpacity(0.05),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ResponsiveText(
                  area['area'] as String? ?? 'Focus Area',
                  baseFontSize: 13,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(
                  context,
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ResponsiveText(
                  priority.toUpperCase(),
                  baseFontSize: 8,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 0.75),
          ResponsiveText(
            area['description'] as String? ?? '',
            baseFontSize: 11,
            style: TextStyle(color: Colors.grey[700]),
          ),
          if (immediateActions.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 0.75),
            ResponsiveText(
              'Immediate Actions:',
              baseFontSize: 10,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            ...immediateActions.map((action) => Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 1),
              child: ResponsiveText(
                '• $action',
                baseFontSize: 9,
                style: TextStyle(color: Colors.blue[600]),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildMechanicalRecommendations(List<dynamic> recommendations) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.build, 
                color: Colors.orange[600], 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Mechanical Improvements',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ...recommendations.map((rec) => _buildMechanicalCard(rec)).toList(),
        ],
      ),
    );
  }

  Widget _buildMechanicalCard(Map<String, dynamic> rec) {
    final techniques = (rec['specific_techniques'] as List?)?.cast<String>() ?? [];
    
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            rec['issue'] as String? ?? 'Improvement Area',
            baseFontSize: 13,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            rec['primary_fix'] as String? ?? '',
            baseFontSize: 11,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.green[700],
            ),
          ),
          if (techniques.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 0.75),
            ResponsiveText(
              'Techniques:',
              baseFontSize: 10,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            ...techniques.map((technique) => Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 1),
              child: ResponsiveText(
                '• $technique',
                baseFontSize: 9,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildTrainingDrills(List<dynamic> drills) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center, 
                color: Colors.purple[600], 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Recommended Training Drills',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          // Responsive drill layout
          Column(
            mainAxisSize: MainAxisSize.min,
            children: drills.map((drill) => Container(
              margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
              child: RecommendedDrillCard(
                name: drill['name'] as String? ?? 'Training Drill',
                description: drill['description'] as String? ?? '',
                repetitions: drill['repetitions'] as String? ?? 'As needed',
                frequency: drill['frequency'] as String? ?? 'Regular',
                keyPoints: (drill['key_points'] as List?)?.cast<String>() ?? [],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineExpectations(Map<String, dynamic> timeline) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline, 
                color: Colors.green[600], 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Development Timeline',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          // Responsive timeline layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              switch (deviceType) {
                case DeviceType.mobile:
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTimelinePhase(
                        'Immediate (1-2 weeks)',
                        timeline['immediate_improvements'],
                        Colors.red[600]!,
                      ),
                      ResponsiveSpacing(multiplier: 1),
                      _buildTimelinePhase(
                        'Short Term (4-8 weeks)',
                        timeline['short_term_goals'],
                        Colors.orange[600]!,
                      ),
                      ResponsiveSpacing(multiplier: 1),
                      _buildTimelinePhase(
                        'Long Term (3-8 months)',
                        timeline['long_term_development'],
                        Colors.green[600]!,
                      ),
                    ],
                  );
                case DeviceType.tablet:
                case DeviceType.desktop:
                  return Row(
                    children: [
                      Expanded(
                        child: _buildTimelinePhase(
                          'Immediate (1-2 weeks)',
                          timeline['immediate_improvements'],
                          Colors.red[600]!,
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Expanded(
                        child: _buildTimelinePhase(
                          'Short Term (4-8 weeks)',
                          timeline['short_term_goals'],
                          Colors.orange[600]!,
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                      Expanded(
                        child: _buildTimelinePhase(
                          'Long Term (3-8 months)',
                          timeline['long_term_development'],
                          Colors.green[600]!,
                        ),
                      ),
                    ],
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimelinePhase(String title, Map<String, dynamic>? phase, Color color) {
    if (phase == null) return SizedBox.shrink();
    
    final changes = (phase['expected_changes'] as List?)?.cast<String>() ?? [];
    
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            title,
            baseFontSize: 12,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            phase['timeframe'] as String? ?? '',
            baseFontSize: 10,
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (changes.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 0.75),
            // Show different number of items based on screen size
            ...changes.take(4).map((change) => Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 1),
              child: ResponsiveText(
                '• $change',
                baseFontSize: 9,
                style: TextStyle(color: Colors.grey[700]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFallbackRecommendations(DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileFallbackLayout();
      case DeviceType.tablet:
        return _buildTabletFallbackLayout();
      case DeviceType.desktop:
        return _buildDesktopFallbackLayout();
    }
  }

  Widget _buildMobileFallbackLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildFallbackStrengthsCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildFallbackImprovementsCard(),
        ResponsiveSpacing(multiplier: 2),
        _buildFallbackDrillsCard(),
      ],
    );
  }

  Widget _buildTabletFallbackLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildFallbackStrengthsCard()),
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            Expanded(child: _buildFallbackImprovementsCard()),
          ],
        ),
        ResponsiveSpacing(multiplier: 2),
        _buildFallbackDrillsCard(),
      ],
    );
  }

  Widget _buildDesktopFallbackLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFallbackStrengthsCard()),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(child: _buildFallbackImprovementsCard()),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(child: _buildFallbackDrillsCard()),
      ],
    );
  }

  Widget _buildFallbackStrengthsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star, 
                color: Colors.amber, 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Strengths',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var strength in (widget.results['strengths'] as List? ?? []))
                Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle, 
                        color: Colors.green, 
                        size: ResponsiveConfig.iconSize(context, 14),
                      ),
                      ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          strength as String,
                          baseFontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackImprovementsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up, 
                color: Colors.blue, 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Areas for Improvement',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var improvement in (widget.results['improvements'] as List? ?? []))
                Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.arrow_circle_up, 
                        color: Colors.orange, 
                        size: ResponsiveConfig.iconSize(context, 14),
                      ),
                      ResponsiveSpacing(multiplier: 0.75, direction: Axis.horizontal),
                      Expanded(
                        child: ResponsiveText(
                          improvement as String,
                          baseFontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackDrillsCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.fitness_center, 
                color: Colors.purple, 
                size: ResponsiveConfig.iconSize(context, 18),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  'Recommended Training Drills',
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          _buildFallbackDrills(),
        ],
      ),
    );
  }

  Widget _buildFallbackDrills() {
    final improvements = widget.results['improvements'] as List? ?? [];
    final drills = <Map<String, String>>[];

    for (var improvement in improvements) {
      final improv = improvement as String;
      if (improv.contains('Wrist shot')) {
        drills.add({
          'name': 'Wrist Shot Improvement Drill',
          'description': 'Quick release wrist shots with focus on accuracy. 50 shots, alternating between high and low corners.'
        });
      } else if (improv.contains('Snap shot')) {
        drills.add({
          'name': 'Snap Shot Development Series',
          'description': 'Practice snap shots from various angles, focusing on quick release. 40 shots, starting with stationary, then adding movement.'
        });
      } else if (improv.contains('Slap shot')) {
        drills.add({
          'name': 'Power Slap Shot Training',
          'description': 'Focus on proper weight transfer and follow-through. 30 shots from point position, aiming for specific zones.'
        });
      } else if (improv.contains('Backhand')) {
        drills.add({
          'name': 'Backhand Shooting Circuit',
          'description': 'Develop backhand accuracy and power from in close. 25 shots with emphasis on lifting the puck.'
        });
      } else if (improv.contains('Top')) {
        drills.add({
          'name': 'High Zone Targeting Practice',
          'description': 'Focus on top shelf shots with all shot types. 30 shots from various angles, all targeting top corners.'
        });
      } else if (improv.contains('Bottom')) {
        drills.add({
          'name': 'Low Zone Accuracy Training',
          'description': 'Practice shooting low with purpose. 30 shots while moving, focusing on quick release to bottom corners.'
        });
      } else if (improv.contains('Quick Release')) {
        drills.add({
          'name': 'Rapid Release Drill',
          'description': 'Pass-to-shot drills emphasizing minimizing time between reception and release. 40 shots from various positions.'
        });
      } else if (improv.contains('Accuracy')) {
        drills.add({
          'name': 'Target Practice Progression',
          'description': 'Start with large targets and progressively reduce size as accuracy improves. 60 shots across all zones.'
        });
      } else {
        drills.add({
          'name': 'Comprehensive Shooting Circuit',
          'description': 'Work through all shot types and target zones with equal focus. 50 shots with emphasis on form and technique.'
        });
      }
    }

    if (drills.length > 3) {
      drills.removeRange(3, drills.length);
    }

    if (drills.length < 3) {
      drills.add({
        'name': 'Game Situation Shooting',
        'description': 'Practice shots from realistic game scenarios with defensive pressure to simulate game conditions.'
      });
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var drill in drills)
          Padding(
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
            child: RecommendedDrillCard(
              name: drill['name']!,
              description: drill['description']!,
            ),
          ),
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red[700]!;
      case 'high': return Colors.orange[700]!;
      case 'medium':
      case 'moderate': return Colors.yellow[700]!;
      default: return Colors.green[700]!;
    }
  }
}