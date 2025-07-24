// lib/screens/mentorship/hire_mentorship_screen.dart
// HIRE Mentorship Screen - CLEANED UP VERSION with single slider interface

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/development_plan_service.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/hire_rating_widgets.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class HIREMentorshipScreen extends StatefulWidget {
  const HIREMentorshipScreen({super.key});

  @override
  State<HIREMentorshipScreen> createState() => _HIREMentorshipScreenState();
}

class _HIREMentorshipScreenState extends State<HIREMentorshipScreen> {
  
  DevelopmentPlanService get _developmentPlanService {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return DevelopmentPlanService(apiService: apiService);
}
  
  // State management
  Player? _selectedPlayer;
  DevelopmentPlanData? _developmentPlan;
  bool _isLoading = false;
  bool _isCalculating = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _calculationError;
  
  // Debouncing for rating updates
  Timer? _debounceTimer;
  final Map<String, double> _pendingRatings = {};
  
  // UI controllers
  final ScrollController _scrollController = ScrollController();
  
  // Text controllers for coach notes
  late TextEditingController _sessionNotesController;
  late TextEditingController _actionItemsController;
  late TextEditingController _observationsController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeScreen();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.dispose();
    _disposeControllers();
    
    if (_pendingRatings.isNotEmpty && _selectedPlayer?.id != null) {
      try {
        _developmentPlanService.flushPendingRatings(_selectedPlayer!.id!);
      } catch (e) {
        debugPrint('Error flushing pending ratings during disposal: $e');
      }
    }
    
    super.dispose();
  }

  // ============================================================================
  // TEXT CONTROLLER MANAGEMENT
  // ============================================================================

  void _initializeControllers() {
    _sessionNotesController = TextEditingController();
    _actionItemsController = TextEditingController();
    _observationsController = TextEditingController();
    
    _sessionNotesController.addListener(_onNotesChanged);
    _actionItemsController.addListener(_onNotesChanged);
    _observationsController.addListener(_onNotesChanged);
  }

  void _disposeControllers() {
    _sessionNotesController.dispose();
    _actionItemsController.dispose();
    _observationsController.dispose();
  }

  void _updateControllersWithPlanData() {
    if (_developmentPlan == null) return;
    
    _sessionNotesController.text = _developmentPlan!.meetingNotes.coachNotes;
    _actionItemsController.text = _developmentPlan!.meetingNotes.playerNotes;
    _observationsController.text = _developmentPlan!.coachContact.name;
  }

  void _onNotesChanged() {
    if (_developmentPlan == null) return;
    
    _developmentPlan!.meetingNotes.coachNotes = _sessionNotesController.text;
    _developmentPlan!.meetingNotes.playerNotes = _actionItemsController.text;
    _developmentPlan!.coachContact.name = _observationsController.text;
  }

  // ============================================================================
  // INITIALIZATION & DATA LOADING
  // ============================================================================

  void _initializeScreen() {
    final appState = Provider.of<AppState>(context, listen: false);
    
    if (appState.selectedPlayer.isNotEmpty) {
      final player = appState.players.firstWhere(
        (p) => p.name == appState.selectedPlayer,
        orElse: () => appState.players.isNotEmpty ? appState.players.first : Player(name: 'Unknown', createdAt: DateTime.now()),
      );
      
      setState(() {
        _selectedPlayer = player;
      });
      
      if (player.id != null) {
        _loadDevelopmentPlan(player.id!);
      } else {
        setState(() {
          _errorMessage = 'Invalid player selected';
        });
      }
    } else if (appState.players.isNotEmpty) {
      final firstPlayer = appState.players.first;
      setState(() {
        _selectedPlayer = firstPlayer;
      });
      
      if (firstPlayer.id != null) {
        _loadDevelopmentPlan(firstPlayer.id!);
      }
    } else {
      setState(() {
        _errorMessage = 'No players available. Please add players first.';
      });
    }
  }

  Future<void> _loadDevelopmentPlan(int playerId) async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final plan = await _developmentPlanService.loadPlayerDevelopmentPlan(playerId);
      
      if (!mounted) return;
      
      if (plan != null) {
        setState(() {
          _developmentPlan = plan;
          _isLoading = false;
        });
        _updateControllersWithPlanData();
      } else {
        // Create default plan if none exists
        final defaultPlan = _developmentPlanService.createDefaultPlanData(_selectedPlayer!);
        _initializeDefaultRatings(defaultPlan);
        
        // IMPORTANT: Save the default plan to database immediately
        await _developmentPlanService.saveDevelopmentPlan(defaultPlan);
        
        setState(() {
          _developmentPlan = defaultPlan;
          _isLoading = false;
        });
        _updateControllersWithPlanData();
        
        debugPrint('Created and saved default development plan for ${_selectedPlayer!.name}');
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load development plan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ============================================================================
  // PLAYER SELECTION
  // ============================================================================

  void _onPlayerChanged(Player? player) {
    if (player == null || player.id == _selectedPlayer?.id) return;
    
    setState(() {
      _selectedPlayer = player;
      _developmentPlan = null;
      _pendingRatings.clear();
    });
    
    _sessionNotesController.clear();
    _actionItemsController.clear();
    _observationsController.clear();
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedPlayer(player.name);
    
    if (player.id != null) {
      _loadDevelopmentPlan(player.id!);
    }
  }

  // ============================================================================
  // RATING UPDATES WITH REAL-TIME HIRE CALCULATION
  // ============================================================================

  double _getRatingValue(String key) {
    if (_developmentPlan?.ratings == null) return 5.0;
    
    try {
      final value = _developmentPlan!.ratings.getRatingValue(key);
      if (value == null) return 5.0;
      
      final doubleValue = value.toDouble();
      
      if (doubleValue >= 0.0 && doubleValue <= 1.0) {
        return (doubleValue * 9.0 + 1.0).clamp(1.0, 10.0);
      }
      
      return doubleValue.clamp(1.0, 10.0);
    } catch (e) {
      return 5.0;
    }
  }

  void _setRatingValue(String key, double value) {
    if (_developmentPlan == null || _selectedPlayer?.id == null) return;
    
    final clampedValue = value.clamp(1.0, 10.0);
    final normalizedValue = ((clampedValue - 1.0) / 9.0).clamp(0.0, 1.0);
    
    setState(() {
      _developmentPlan!.ratings.setRatingValue(key, normalizedValue);
      _developmentPlan!.needsRecalculation = true;
    });
    
    _pendingRatings[key] = normalizedValue;
    
    // Real-time HIRE score calculation
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _calculateHIREScoresRealTime();
    });
  }

  Future<void> _calculateHIREScoresRealTime() async {
    if (_developmentPlan == null || _selectedPlayer?.id == null) return;
    
    setState(() {
      _isCalculating = true;
      _calculationError = null;
    });

    try {
      if (_pendingRatings.isNotEmpty) {
        await _developmentPlanService.savePendingRatings(_selectedPlayer!.id!, Map<String, double>.from(_pendingRatings));
      }
      
      final result = await _developmentPlanService.calculateHIREScores(_selectedPlayer!.id!);
      
      if (!mounted) return;
      
      setState(() {
        _developmentPlan!.ratings.hScore = result.hockey;
        _developmentPlan!.ratings.iScore = result.integrity;
        _developmentPlan!.ratings.rScore = result.respect;
        _developmentPlan!.ratings.eScore = result.excellence;
        _developmentPlan!.ratings.overallHIREScore = result.overall;
        
        _developmentPlan!.needsRecalculation = false;
        _developmentPlan!.scoresCalculatedAt = result.calculatedAt;
        _isCalculating = false;
      });
      
      _pendingRatings.clear();
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _calculationError = 'Failed to calculate HIRE scores: ${e.toString()}';
        _isCalculating = false;
      });
    }
  }

  void _initializeDefaultRatings(DevelopmentPlanData plan) {
    final ratingKeys = [
      'hockeyIQ', 'competitiveness', 'workEthic', 'coachability', 'leadership', 'teamPlay', 'decisionMaking', 'adaptability',
      'physicalFitness', 'nutritionHabits', 'sleepQuality', 'mentalToughness', 'timeManagement', 'respectForOthers', 'commitment', 'goalSetting', 'communicationSkills',
    ];
    
    if (_selectedPlayer != null) {
      final age = _selectedPlayer!.age ?? 16;
      final ageGroup = AgeGroup.fromAge(age);
      final ageCategories = HockeyRatingsConfig.getCategoriesForAge(age);
      final ageSpecificCategory = ageCategories.firstWhere(
        (cat) => cat.ageGroup == ageGroup,
        orElse: () => ageCategories.last,
      );
      
      ratingKeys.addAll(ageSpecificCategory.factors.map((f) => f.key));
    }
    
    for (final key in ratingKeys) {
      try {
        final currentValue = plan.ratings.getRatingValue(key);
        
        if (currentValue == null) {
          plan.ratings.setRatingValue(key, 4.0 / 9.0); // 5.0 on UI scale
        }
      } catch (e) {
        try {
          plan.ratings.setRatingValue(key, 4.0 / 9.0);
        } catch (setError) {
          debugPrint('Could not set default rating for $key: $setError');
        }
      }
    }
  }

  Future<void> _saveDevelopmentPlan() async {
    if (_developmentPlan == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _developmentPlanService.saveDevelopmentPlan(_developmentPlan!);
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      _showSuccessSnackBar('Development plan saved successfully');
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to save development plan: ${e.toString()}';
        _isSaving = false;
      });
      
      _showErrorSnackBar('Failed to save development plan');
    }
  }

  // ============================================================================
  // UI BUILDING
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'HIRE Character Assessment',
      backgroundColor: Colors.grey[50],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _selectedPlayer?.id != null ? () => _loadDevelopmentPlan(_selectedPlayer!.id!) : null,
          tooltip: 'Refresh Data',
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

          if (_selectedPlayer == null || _developmentPlan == null) {
            return _buildEmptyState();
          }

          return _buildMentorshipContent(deviceType, isLandscape);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveDevelopmentPlan,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        icon: _isSaving 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
        label: ResponsiveText(_isSaving ? 'Saving...' : 'Save Assessment', baseFontSize: 14),
        tooltip: 'Save HIRE Assessment',
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
          Text('Loading HIRE assessment...'),
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
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error Loading HIRE Assessment',
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
              onPressed: _initializeScreen,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Player Selected',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select a player to begin HIRE character assessment',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/players'),
              icon: const Icon(Icons.people),
              label: const Text('Manage Players'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMentorshipContent(DeviceType deviceType, bool isLandscape) {
    if (deviceType == DeviceType.desktop) {
      return _buildDesktopLayout();
    } else if (deviceType == DeviceType.tablet) {
      return _buildTabletLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildPlayerSelector()),
        SliverToBoxAdapter(child: _buildHIREScoreDisplay()),
        SliverToBoxAdapter(child: _buildRatingSliders()),
        SliverToBoxAdapter(child: _buildCoachNotesSection()),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildPlayerSelector()),
              SliverToBoxAdapter(child: _buildRatingSliders()),
              SliverToBoxAdapter(child: _buildCoachNotesSection()),
            ],
          ),
        ),
        Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildPlayerSelector()),
                SliverToBoxAdapter(child: _buildRatingSliders()),
                SliverToBoxAdapter(child: _buildCoachNotesSection()),
              ],
            ),
          ),
        ),
        Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          child: _buildSidebar(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: Colors.blue, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HIRE Character Assessment',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rate player attributes to calculate real-time HIRE scores',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isCalculating)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Calculating HIRE scores...',
                    style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          if (_calculationError != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _calculationError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _calculateHIREScoresRealTime,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                ResponsiveText(
                  'Select Player for Assessment',
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 1),
            Consumer<AppState>(
              builder: (context, appState, child) {
                if (appState.players.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No players available', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              const Text('Please add players first to begin assessments', style: TextStyle(fontSize: 12)),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pushNamed(context, '/players'),
                                icon: const Icon(Icons.add),
                                label: const Text('Add Players'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return DropdownButtonFormField<Player>(
                  value: _selectedPlayer,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    prefixIcon: const Icon(Icons.person, size: 20),
                  ),
                  items: appState.players.map((player) {
                    return DropdownMenuItem<Player>(
                      value: player,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.withOpacity(0.1),
                            child: Text(
                              player.name.isNotEmpty ? player.name[0].toUpperCase() : 'P',
                              style: const TextStyle(color: Colors.blue, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(player.name, style: const TextStyle(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                                if (player.age != null)
                                  Text('Age: ${player.age}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: _onPlayerChanged,
                  hint: const Text('Choose a player to assess'),
                );
              },
            ),
            if (_selectedPlayer != null) ...[
              ResponsiveSpacing(multiplier: 1),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Now assessing: ${_selectedPlayer!.name}',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHIREScoreDisplay() {
    if (_developmentPlan == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 20),
        child: Column(
          children: [
            ResponsiveText(
              'HIRE Scores',
              baseFontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
            if (_selectedPlayer != null)
              Chip(
                label: Text('Age ${_selectedPlayer!.age ?? 16}'),
                backgroundColor: Colors.blue.withOpacity(0.1),
              ),
            ResponsiveSpacing(multiplier: 2),
            
            // HIRE Score Circles with breakdown - VERTICAL layout
            Column(
              children: [
                _buildHIRECircleWithBreakdown('H', _developmentPlan!.ratings.hScore, 'Humility/Hardwork', Colors.red),
                const SizedBox(height: 12),
                _buildHIRECircleWithBreakdown('I', _developmentPlan!.ratings.iScore, 'Initiative/Integrity', Colors.blue),
                const SizedBox(height: 12),
                _buildHIRECircleWithBreakdown('R', _developmentPlan!.ratings.rScore, 'Responsibility/Respect', Colors.green),
                const SizedBox(height: 12),
                _buildHIRECircleWithBreakdown('E', _developmentPlan!.ratings.eScore, 'Enthusiasm', Colors.orange),
              ],
            ),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Overall HIRE Score at bottom
            Column(
              children: [
                ResponsiveText(
                  'Overall Score',
                  baseFontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[600],
                ),
                ResponsiveSpacing(multiplier: 1),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: HockeyRatingsConfig.getColorForRating(_developmentPlan!.ratings.overallHIREScore).withOpacity(0.1),
                    border: Border.all(
                      color: HockeyRatingsConfig.getColorForRating(_developmentPlan!.ratings.overallHIREScore),
                      width: 4,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ResponsiveText(
                        _developmentPlan!.ratings.overallHIREScore.toStringAsFixed(1),
                        baseFontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: HockeyRatingsConfig.getColorForRating(_developmentPlan!.ratings.overallHIREScore),
                      ),
                      ResponsiveText(
                        'HIRE',
                        baseFontSize: 12,
                        color: HockeyRatingsConfig.getColorForRating(_developmentPlan!.ratings.overallHIREScore),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHIRECircleWithBreakdown(String letter, double score, String title, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
              border: Border.all(color: color, width: 3),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ResponsiveText(
                  letter,
                  baseFontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                ResponsiveText(
                  score.toStringAsFixed(1),
                  baseFontSize: 12,
                  color: color,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  title,
                  baseFontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
                const SizedBox(height: 4),
                // Component breakdown for this HIRE category
                if (letter == 'H') ...[
                  _buildComponentItem('Humility', score, color),
                  _buildComponentItem('Hardwork', score, color),
                ] else if (letter == 'I') ...[
                  _buildComponentItem('Initiative', score, color),
                  _buildComponentItem('Integrity', score, color),
                ] else if (letter == 'R') ...[
                  _buildComponentItem('Responsibility', score, color),
                  _buildComponentItem('Respect', score, color),
                ] else if (letter == 'E') ...[
                  _buildComponentItem('Enthusiasm', score, color),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentItem(String title, double score, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSliders() {
    if (_developmentPlan == null || _selectedPlayer == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Use screen width to determine layout instead of device type detection
          // Stack vertically if screen width is less than 900px
          final shouldStack = constraints.maxWidth < 900;
          
          if (shouldStack) {
            return Column(
              children: [
                _buildRatingCategorySection(
                  'Hockey Skills Assessment',
                  Icons.sports_hockey,
                  Colors.red,
                  [
                    _buildRatingSlider('Hockey IQ', 'hockeyIQ'),
                    _buildRatingSlider('Competitiveness', 'competitiveness'),
                    _buildRatingSlider('Work Ethic', 'workEthic'),
                    _buildRatingSlider('Coachability', 'coachability'),
                    _buildRatingSlider('Leadership', 'leadership'),
                    _buildRatingSlider('Team Play', 'teamPlay'),
                    _buildRatingSlider('Decision Making', 'decisionMaking'),
                    _buildRatingSlider('Adaptability', 'adaptability'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildRatingCategorySection(
                  'Off-Ice Life Factors',
                  Icons.fitness_center,
                  Colors.green,
                  [
                    _buildRatingSlider('Physical Fitness', 'physicalFitness'),
                    _buildRatingSlider('Nutrition Habits', 'nutritionHabits'),
                    _buildRatingSlider('Sleep Quality', 'sleepQuality'),
                    _buildRatingSlider('Mental Toughness', 'mentalToughness'),
                    _buildRatingSlider('Time Management', 'timeManagement'),
                    _buildRatingSlider('Respect for Others', 'respectForOthers'),
                    _buildRatingSlider('Commitment', 'commitment'),
                    _buildRatingSlider('Goal Setting', 'goalSetting'),
                    _buildRatingSlider('Communication Skills', 'communicationSkills'),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                _buildAgeSpecificRatingSection(),
              ],
            );
          }
          
          // On wider screens, show sections side by side with equal width
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hockey Skills Section
              Expanded(
                child: _buildRatingCategorySection(
                  'Hockey Skills',
                  Icons.sports_hockey,
                  Colors.red,
                  [
                    _buildRatingSlider('Hockey IQ', 'hockeyIQ'),
                    _buildRatingSlider('Competitiveness', 'competitiveness'),
                    _buildRatingSlider('Work Ethic', 'workEthic'),
                    _buildRatingSlider('Coachability', 'coachability'),
                    _buildRatingSlider('Leadership', 'leadership'),
                    _buildRatingSlider('Team Play', 'teamPlay'),
                    _buildRatingSlider('Decision Making', 'decisionMaking'),
                    _buildRatingSlider('Adaptability', 'adaptability'),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Off-Ice Life Factors Section
              Expanded(
                child: _buildRatingCategorySection(
                  'Off-Ice Factors',
                  Icons.fitness_center,
                  Colors.green,
                  [
                    _buildRatingSlider('Physical Fitness', 'physicalFitness'),
                    _buildRatingSlider('Nutrition Habits', 'nutritionHabits'),
                    _buildRatingSlider('Sleep Quality', 'sleepQuality'),
                    _buildRatingSlider('Mental Toughness', 'mentalToughness'),
                    _buildRatingSlider('Time Management', 'timeManagement'),
                    _buildRatingSlider('Respect for Others', 'respectForOthers'),
                    _buildRatingSlider('Commitment', 'commitment'),
                    _buildRatingSlider('Goal Setting', 'goalSetting'),
                    _buildRatingSlider('Communication Skills', 'communicationSkills'),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Age-Specific Factors Section
              Expanded(
                child: _buildAgeSpecificRatingSection(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRatingSlider(String title, String key) {
    final currentValue = _getRatingValue(key);
    final ratingFactor = HockeyRatingsConfig.getFactor(key);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: HockeyRatingsConfig.getColorForRating(currentValue).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currentValue.toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: HockeyRatingsConfig.getColorForRating(currentValue),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Always show help icon - use config data when available
              IconButton(
                onPressed: () => _showRatingInfoFromConfig(context, title, key, ratingFactor),
                icon: Icon(Icons.help_outline, size: 18, color: Colors.blue[600]),
                tooltip: 'View rating scale & tips',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            ),
            child: Slider(
              value: currentValue,
              min: 1.0,
              max: 10.0,
              divisions: 90,
              activeColor: HockeyRatingsConfig.getColorForRating(currentValue),
              inactiveColor: Colors.grey[300],
              onChanged: (value) => _setRatingValue(key, value),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Poor (1)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              Text('Excellent (10)', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeSpecificRatingSection() {
    if (_selectedPlayer == null) return const SizedBox.shrink();
    
    final age = _selectedPlayer!.age ?? 16;
    final ageGroup = AgeGroup.fromAge(age);
    final ageCategories = HockeyRatingsConfig.getCategoriesForAge(age);
    
    final ageSpecificCategory = ageCategories.firstWhere(
      (cat) => cat.ageGroup == ageGroup,
      orElse: () => ageCategories.last,
    );

    String sectionTitle;
    IconData sectionIcon;
    Color sectionColor;

    switch (ageGroup) {
      case AgeGroup.youth:
        sectionTitle = 'Youth Factors';
        sectionIcon = Icons.child_friendly;
        sectionColor = Colors.purple;
        break;
      case AgeGroup.teen:
        sectionTitle = 'Teen Factors';
        sectionIcon = Icons.school;
        sectionColor = Colors.indigo;
        break;
      case AgeGroup.adult:
        sectionTitle = 'Adult Factors';
        sectionIcon = Icons.work;
        sectionColor = Colors.teal;
        break;
    }

    return _buildRatingCategorySection(
      sectionTitle,
      sectionIcon,
      sectionColor,
      ageSpecificCategory.factors.map((factor) => 
        _buildRatingSlider(factor.title, factor.key)
      ).toList(),
    );
  }

  Widget _buildRatingCategorySection(String title, IconData icon, Color color, List<Widget> sliders) {
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 12,
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  title,
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              // Section info button
              IconButton(
                onPressed: () => _showSectionInfo(context, title, color),
                icon: Icon(
                  Icons.help_outline,
                  color: color.withOpacity(0.8),
                  size: 20,
                ),
                tooltip: 'About this section',
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ...sliders,
        ],
      ),
    );
  }

  Widget _buildCoachNotesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 2,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.blue, size: 24),
                ),
                ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                Expanded(
                  child: ResponsiveText(
                    'Session Notes',
                    baseFontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 2),
            
            _buildNoteBox(
              controller: _sessionNotesController,
              title: 'Session Notes',
              hintText: 'Record your observations from this mentorship session...',
              maxLines: 4,
            ),
            
            ResponsiveSpacing(multiplier: 1.5),
            
            _buildNoteBox(
              controller: _actionItemsController,
              title: 'Action Items',
              hintText: 'List specific action items for the player...',
              maxLines: 3,
            ),
            
            ResponsiveSpacing(multiplier: 1.5),
            
            _buildNoteBox(
              controller: _observationsController,
              title: 'Character Observations',
              hintText: 'Note character development observations...',
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBox({
    required TextEditingController controller,
    required String title,
    required String hintText,
    int maxLines = 4,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[50],
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.grey[500]),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSidebar() {
    if (_developmentPlan == null || _selectedPlayer == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        _buildHIREScoreDisplay(),
        const SizedBox(height: 16),
        
        // Development focus for teens
        if (_selectedPlayer!.age != null && _selectedPlayer!.age! >= 13 && _selectedPlayer!.age! <= 17)
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    ResponsiveText(
                      'Teen Development Focus',
                      baseFontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ResponsiveText(
                  'Developing independence, handling peer pressure, and balancing multiple priorities while maintaining hockey excellence.',
                  baseFontSize: 12,
                  color: Colors.grey[700],
                ),
                const SizedBox(height: 12),
                ResponsiveText(
                  'Key Focus Areas:',
                  baseFontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
                const SizedBox(height: 4),
                ResponsiveText(
                  '• Academic performance balance\n• Social influences management\n• Independence development\n• Character decision making',
                  baseFontSize: 11,
                  color: Colors.grey[600],
                ),
              ],
            ),
          ),
      ],
    );
  }

  // ============================================================================
  // INFORMATION DIALOGS
  // ============================================================================

  // Updated to properly use hockey_ratings_config.dart data
  void _showRatingInfoFromConfig(BuildContext context, String title, String key, dynamic ratingFactor) {
    if (ratingFactor == null) {
      // Show simple dialog if no config data available
      _showBasicRatingInfo(context, title);
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.blue, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ratingFactor.title,
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Description
              Text(
                ratingFactor.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              
              // Why it matters section
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Why This Matters:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ratingFactor.whyItMatters,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              Text(
                'Detailed Rating Scale (1-10):',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 12),
              
              // Use detailed scale descriptions from config
              ...ratingFactor.scaleDescriptions.map((scale) => 
                _buildConfigRatingScaleItem(
                  scale.value.toString(), 
                  scale.label, 
                  scale.description, 
                  HockeyRatingsConfig.getColorForRating(scale.value.toDouble())
                )
              ),
              
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: Colors.amber[700], size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Assessment Tips:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• Consider recent observations and consistent patterns\n• Compare to peers of similar age and experience\n• Focus on character and effort, not just results\n• Use the specific descriptions above as your guide\n• Be honest and constructive in your assessment',
                      style: TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              
              // Show data source indicator
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    'Data from hockey_ratings_config.dart',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // Fallback for when no config data is available
  void _showBasicRatingInfo(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.info_outline, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Rate this attribute based on your observations and the player\'s consistent demonstration of this quality.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Text(
              'Standard Rating Scale (1-10):',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 12),
            
            // Standard rating scale
            _buildRatingScaleItem('1-2', 'Poor', 'Significant concerns, needs major improvement', Colors.red),
            _buildRatingScaleItem('3-4', 'Below Average', 'Some concerns, needs focused development', Colors.orange),
            _buildRatingScaleItem('5-6', 'Average', 'Meets expectations, room for growth', Colors.amber),
            _buildRatingScaleItem('7-8', 'Good', 'Above expectations, strong performance', Colors.lightGreen),
            _buildRatingScaleItem('9-10', 'Excellent', 'Outstanding, role model level', Colors.green),
            
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.warning, size: 14, color: Colors.orange),
                const SizedBox(width: 6),
                Text(
                  'No specific config data available for this rating',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRatingScaleItem(String value, String level, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingScaleItem(String range, String level, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              range,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show section information - Enhanced with config awareness
  void _showSectionInfo(BuildContext context, String sectionTitle, Color color) {
    String description;
    List<String> keyPoints;
    String assessmentGuidance;
    
    // Note: The config file doesn't have section-level info, so using hardcoded fallbacks
    // but now properly integrated with the rating factor system
    
    if (sectionTitle.contains('Hockey Skills')) {
      description = 'Core hockey skills and mental attributes that directly impact game performance. These factors determine how well a player can execute on the ice and work within a team environment.';
      keyPoints = [
        'Technical skills like skating, shooting, and passing',
        'Mental aspects like hockey IQ and decision making', 
        'Character traits like work ethic and coachability',
        'Team dynamics like leadership and collaboration'
      ];
      assessmentGuidance = 'Focus on consistent demonstration during practices and games. Consider both natural ability and effort to improve. Each rating has detailed descriptions in the hockey_ratings_config.dart.';
    } else if (sectionTitle.contains('Off-Ice')) {
      description = 'Personal habits and lifestyle choices that support hockey development. These factors significantly impact on-ice performance and long-term development.';
      keyPoints = [
        'Physical preparation and fitness commitment',
        'Mental toughness and character development',
        'Life skills like time management and communication',
        'Personal responsibility and commitment to growth'
      ];
      assessmentGuidance = 'Observe patterns over time. These traits often show up in how players handle challenges and maintain consistency. Use the detailed scale descriptions for each factor.';
    } else if (sectionTitle.contains('Youth')) {
      description = 'Special factors crucial for young players (ages 8-12). At this age, fun, fundamentals, and family support are most important for long-term development.';
      keyPoints = [
        'Enjoyment and love of the game',
        'Basic listening and following instructions',
        'Sharing and teamwork fundamentals',
        'Support from family and coaches'
      ];
      assessmentGuidance = 'Emphasize effort and attitude over results. Look for signs of engagement and willingness to try. Each factor has age-appropriate descriptions.';
    } else if (sectionTitle.contains('Teen')) {
      description = 'Critical factors during teenage years (ages 13-17) when players face unique challenges and opportunities for character growth.';
      keyPoints = [
        'Academic performance and balance',
        'Social influences and peer pressure management',
        'Independence and responsibility development',
        'Character choices and decision making'
      ];
      assessmentGuidance = 'Consider the complexity of teen life. Look for growth in maturity and decision-making over time. Use teen-specific rating descriptions.';
    } else if (sectionTitle.contains('Adult')) {
      description = 'Life balance factors for adult players (ages 18+) who must integrate hockey with career and family responsibilities.';
      keyPoints = [
        'Work-life-hockey balance management',
        'Financial planning and responsibility',
        'Family support and commitment',
        'Long-term vision and leadership'
      ];
      assessmentGuidance = 'Focus on how well they manage competing priorities while maintaining commitment to hockey excellence. Adult factors have specific contextual descriptions.';
    } else {
      description = 'This section contains important factors for player development and character assessment.';
      keyPoints = [];
      assessmentGuidance = 'Rate based on consistent observations and demonstrated behaviors. Click the help icon next to each rating for detailed descriptions.';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.info_outline, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                sectionTitle,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (keyPoints.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Key Areas:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...keyPoints.map((point) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '• ',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          point,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assessment, color: color, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Assessment Guidance:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      assessmentGuidance,
                      style: const TextStyle(fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
              
              // Reference to detailed config data
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Each rating factor has detailed 1-10 scale descriptions. Click the help icon (?) next to any slider for specific guidance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}