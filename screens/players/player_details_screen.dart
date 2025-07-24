// lib/screens/players/player_details_screen.dart - FIXED VERSION

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/services/development_plan_service.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/screens/mentorship/hire_history_screen.dart';
import 'package:intl/intl.dart';

class PlayerDetailsScreen extends StatefulWidget {
  final Player? player;

  const PlayerDetailsScreen({
    super.key,
    this.player,
  });

  @override
  State<PlayerDetailsScreen> createState() => _PlayerDetailsScreenState();
}

class _PlayerDetailsScreenState extends State<PlayerDetailsScreen>
    with SingleTickerProviderStateMixin {

  DevelopmentPlanService get _developmentPlanService {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return DevelopmentPlanService(apiService: apiService);
  }
  
  late TabController _tabController;
  Player? _currentPlayer;
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasInitialized = false; // ✅ ADD: Track initialization state
  
  // HIRE data
  DevelopmentPlanData? _developmentPlan;
  HIREScores? _hireScores;
  bool _hasHIREHistory = false;
  int _totalAssessments = 0;
  DateTime? _lastAssessmentDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // ✅ REMOVED: _initializePlayer() call from here
    // Only initialize with widget.player if available
    if (widget.player != null) {
      _currentPlayer = widget.player;
      print('✅ Using widget.player in initState: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // ✅ FIXED: Only initialize once, and handle all navigation argument extraction here
    if (!_hasInitialized) {
      _hasInitialized = true;
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializePlayer() {
    print('🎯 PlayerDetailsScreen: _initializePlayer() called');
    
    // ✅ STEP 1: Try to use the player passed directly to the widget
    if (widget.player != null) {
      _currentPlayer = widget.player;
      print('✅ Using widget.player: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
      _loadPlayerData();
      return;
    }

    // ✅ STEP 2: Try to extract from navigation arguments (NOW SAFE TO CALL)
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Player) {
      print('✅ Using navigation arguments: ${args.name} (ID: ${args.id})');
      _currentPlayer = args;
      _loadPlayerData();
      return;
    }

    // ✅ STEP 3: Try to get from AppState selectedPlayer
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedPlayer.isNotEmpty && appState.players.isNotEmpty) {
      try {
        _currentPlayer = appState.players.firstWhere(
          (p) => p.name == appState.selectedPlayer,
        );
        print('✅ Found player in AppState by name: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
        _loadPlayerData();
        return;
      } catch (e) {
        print('⚠️ Could not find player by name "${appState.selectedPlayer}" in AppState players');
      }
    }

    // ✅ STEP 4: Last resort - use first player, but log this clearly
    if (appState.players.isNotEmpty) {
      _currentPlayer = appState.players.first;
      print('⚠️ FALLBACK: Using first player from list: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
      print('⚠️ This might not be the intended player!');
      _loadPlayerData();
      return;
    }

    // ✅ STEP 5: No players available
    print('❌ No players available anywhere');
    setState(() {
      _errorMessage = 'No player data available';
      _isLoading = false;
    });
  }

  Future<void> _loadPlayerData() async {
    if (_currentPlayer?.id == null) {
      print('❌ Cannot load data: _currentPlayer or ID is null');
      setState(() {
        _errorMessage = 'Invalid player data';
        _isLoading = false;
      });
      return;
    }
    
    print('🚀 Loading data for player: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // ✅ CRITICAL FIX: Use the correct player ID consistently
      final playerId = _currentPlayer!.id!;
      
      print('📞 Calling loadPlayerDevelopmentPlan with ID: $playerId');
      
      // Load HIRE development plan
      try {
        _developmentPlan = await _developmentPlanService.loadPlayerDevelopmentPlan(playerId);
        print('✅ Development plan loaded successfully');
      } catch (e) {
        print('⚠️ Could not load development plan: $e');
        _developmentPlan = null;
      }
      
      // Load HIRE scores
      try {
        print('📞 Calling loadHIREScoresFromBackend with ID: $playerId');
        _hireScores = await _developmentPlanService.loadHIREScoresFromBackend(playerId);
        print('✅ HIRE scores loaded successfully');
      } catch (e) {
        print('⚠️ Could not load HIRE scores: $e');
        _hireScores = null;
      }
      
      // Load HIRE history summary
      try {
        print('📞 Calling loadAssessmentHistory with ID: $playerId');
        final history = await _developmentPlanService.loadAssessmentHistory(playerId);
        _hasHIREHistory = history.isNotEmpty;
        _totalAssessments = history.length;
        _lastAssessmentDate = history.isNotEmpty ? history.first.assessmentDate : null;
        print('✅ Assessment history loaded: ${history.length} assessments');
      } catch (e) {
        print('⚠️ Could not load HIRE history: $e');
        _hasHIREHistory = false;
        _totalAssessments = 0;
        _lastAssessmentDate = null;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('❌ Error loading player data for ID ${_currentPlayer!.id}: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load player data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  // ✅ ADD: Debug method to check current state
  void _debugPlayerState() {
    print('=== PLAYER DEBUG STATE ===');
    print('widget.player: ${widget.player?.name} (ID: ${widget.player?.id})');
    print('_currentPlayer: ${_currentPlayer?.name} (ID: ${_currentPlayer?.id})');
    print('_hasInitialized: $_hasInitialized');
    
    final args = ModalRoute.of(context)?.settings.arguments;
    print('Navigation args: ${args.runtimeType} - ${args is Player ? (args as Player).name : 'Not a Player'}');
    
    final appState = Provider.of<AppState>(context, listen: false);
    print('AppState selectedPlayer: "${appState.selectedPlayer}"');
    print('AppState players count: ${appState.players.length}');
    if (appState.players.isNotEmpty) {
      print('First player in AppState: ${appState.players.first.name} (ID: ${appState.players.first.id})');
    }
    print('========================');
  }

  @override
  Widget build(BuildContext context) {
    // ✅ ADD: Debug button in development
    if (_currentPlayer == null) {
      return AdaptiveScaffold(
        title: 'Player Details',
        floatingActionButton: FloatingActionButton(
          mini: true,
          onPressed: _debugPlayerState,
          child: const Icon(Icons.bug_report),
        ),
        body: const Center(
          child: Text('No player selected'),
        ),
      );
    }

    return AdaptiveScaffold(
      title: _currentPlayer!.name,
      backgroundColor: Colors.grey[50],
      actions: [
        // ✅ ADD: Debug button in development
        IconButton(
          icon: const Icon(Icons.bug_report),
          onPressed: _debugPlayerState,
          tooltip: 'Debug Player State',
        ),
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => _editPlayer(_currentPlayer!),
          tooltip: 'Edit Player',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'analytics',
              child: Row(
                children: [
                  Icon(Icons.analytics, size: 20),
                  SizedBox(width: 8),
                  Text('View Analytics'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'hire_mentorship',
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('HIRE Mentorship'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'shot_assessment',
              child: Row(
                children: [
                  Icon(Icons.sports_hockey, size: 20, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Shot Assessment'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'skating_assessment',
              child: Row(
                children: [
                  Icon(Icons.speed, size: 20, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Skating Assessment'),
                ],
              ),
            ),
          ],
        ),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return Column(
            children: [
              // Player header
              _buildPlayerHeader(deviceType),
              
              // Tab bar
              _buildTabBar(),
              
              // Tab content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildTabContent(deviceType),
              ),
            ],
          );
        },
      ),
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
            // Player avatar
            CircleAvatar(
              backgroundColor: Colors.blueGrey[100],
              radius: deviceType == DeviceType.mobile ? 40 : 50,
              child: ResponsiveText(
                _currentPlayer!.name.isNotEmpty ? _currentPlayer!.name[0].toUpperCase() : '?',
                baseFontSize: deviceType == DeviceType.mobile ? 32 : 40,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
            
            ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
            
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    _currentPlayer!.name,
                    baseFontSize: deviceType == DeviceType.mobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  
                  Row(
                    children: [
                      if (_currentPlayer!.age != null) ...[
                        Icon(Icons.cake, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        ResponsiveText(
                          'Age ${_currentPlayer!.age}',
                          baseFontSize: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (_currentPlayer!.position.isNotEmpty) ...[
                        Icon(Icons.sports_hockey, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        ResponsiveText(
                          _currentPlayer!.positionDisplay,
                          baseFontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ],
                  ),
                  
                  if (_currentPlayer!.teamName != null) ...[
                    ResponsiveSpacing(multiplier: 0.5),
                    Row(
                      children: [
                        Icon(Icons.group, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        ResponsiveText(
                          _currentPlayer!.teamName!,
                          baseFontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ],
                  
                  // ✅ ADD: Debug info in development
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'Player ID: ${_currentPlayer!.id}',
                    baseFontSize: 12,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ),
            
            // HIRE Score display (if available)
            if (_hireScores != null)
              Container(
                width: deviceType == DeviceType.mobile ? 80 : 100,
                height: deviceType == DeviceType.mobile ? 80 : 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall).withOpacity(0.1),
                  border: Border.all(
                    color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall),
                    width: 3,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ResponsiveText(
                      _hireScores!.overall.toStringAsFixed(1),
                      baseFontSize: deviceType == DeviceType.mobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall),
                    ),
                    ResponsiveText(
                      'HIRE',
                      baseFontSize: 10,
                      color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ResponsiveCard(
        elevation: 1,
        baseBorderRadius: 12,
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey[600],
          indicator: BoxDecoration(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(
              icon: Icon(Icons.person, size: 20),
              text: 'Overview',
            ),
            Tab(
              icon: Icon(Icons.analytics, size: 20),
              text: 'Performance',
            ),
            Tab(
              icon: Icon(Icons.psychology, size: 20),
              text: 'HIRE',
            ),
            Tab(
              icon: Icon(Icons.history, size: 20),
              text: 'History',
            ),
          ],
        ),
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
          Text('Loading player data...'),
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
              'Error Loading Data',
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
              onPressed: _loadPlayerData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(DeviceType deviceType) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(deviceType),
        _buildPerformanceTab(deviceType),
        _buildHIRETab(deviceType),
        _buildHistoryTab(deviceType),
      ],
    );
  }

  Widget _buildOverviewTab(DeviceType deviceType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Basic Information',
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveSpacing(multiplier: 2),
                
                _buildInfoRow('Full Name', _currentPlayer!.name),
                if (_currentPlayer!.age != null)
                  _buildInfoRow('Age', '${_currentPlayer!.age} years old'),
                if (_currentPlayer!.birthDate != null)
                  _buildInfoRow('Birth Date', DateFormat('MMMM d, yyyy').format(_currentPlayer!.birthDate!)),
                _buildInfoRow('Position', _currentPlayer!.positionDisplay),
                _buildInfoRow('Age Group', _currentPlayer!.ageGroupDisplay),
                _buildInfoRow('Skill Level', _currentPlayer!.skillLevelDisplay),
                if (_currentPlayer!.genderDisplay != null)
                  _buildInfoRow('Gender', _currentPlayer!.genderDisplay!),
                if (_currentPlayer!.jerseyNumber != null)
                  _buildInfoRow('Jersey Number', '#${_currentPlayer!.jerseyNumber}'),
                if (_currentPlayer!.height != null)
                  _buildInfoRow('Height', _currentPlayer!.heightDisplay),
                if (_currentPlayer!.weight != null)
                  _buildInfoRow('Weight', _currentPlayer!.weightDisplay),
              ],
            ),
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Contact Information
          if (_currentPlayer!.email != null || _currentPlayer!.phone != null)
            ResponsiveCard(
              elevation: 2,
              baseBorderRadius: 12,
              padding: ResponsiveConfig.paddingAll(context, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Contact Information',
                    baseFontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  
                  if (_currentPlayer!.email != null)
                    _buildInfoRow('Email', _currentPlayer!.email!),
                  if (_currentPlayer!.phone != null)
                    _buildInfoRow('Phone', _currentPlayer!.phone!),
                ],
              ),
            ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Team Information
          if (_currentPlayer!.teamName != null || _currentPlayer!.primaryCoachName != null)
            ResponsiveCard(
              elevation: 2,
              baseBorderRadius: 12,
              padding: ResponsiveConfig.paddingAll(context, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Team Information',
                    baseFontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  
                  if (_currentPlayer!.teamName != null)
                    _buildInfoRow('Team', _currentPlayer!.teamName!),
                  if (_currentPlayer!.primaryCoachName != null)
                    _buildInfoRow('Primary Coach', _currentPlayer!.primaryCoachName!),
                  if (_currentPlayer!.coordinatorName != null)
                    _buildInfoRow('Coordinator', _currentPlayer!.coordinatorName!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPerformanceTab(DeviceType deviceType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: Column(
              children: [
                ResponsiveText(
                  'Performance Analytics',
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveSpacing(multiplier: 2),
                
                ResponsiveText(
                  'Detailed performance analytics will be displayed here.',
                  baseFontSize: 14,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                ),
                
                ResponsiveSpacing(multiplier: 2),
                
                ElevatedButton.icon(
                  onPressed: () => _handleMenuAction('analytics'),
                  icon: const Icon(Icons.analytics),
                  label: const Text('View Full Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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

  Widget _buildHIRETab(DeviceType deviceType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HIRE Scores Summary
          if (_hireScores != null)
            ResponsiveCard(
              elevation: 2,
              baseBorderRadius: 12,
              padding: ResponsiveConfig.paddingAll(context, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ResponsiveText(
                    'Current HIRE Assessment',
                    baseFontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  
                  // Overall score
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall).withOpacity(0.1),
                        border: Border.all(
                          color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall),
                          width: 4,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ResponsiveText(
                            _hireScores!.overall.toStringAsFixed(1),
                            baseFontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: HockeyRatingsConfig.getColorForRating(_hireScores!.overall),
                          ),
                          ResponsiveText(
                            'Overall HIRE',
                            baseFontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  ResponsiveSpacing(multiplier: 2),
                  
                  // Component scores
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildHIREComponent('H', 'Humility/Hardwork', _hireScores!.hockey, Colors.red),
                      _buildHIREComponent('I', 'Initiative/Integrity', _hireScores!.integrity, Colors.blue),
                      _buildHIREComponent('R', 'Responsibility/Respect', _hireScores!.respect, Colors.green),
                      _buildHIREComponent('E', 'Enthusiasm', _hireScores!.excellence, Colors.orange),
                    ],
                  ),
                  
                  if (_lastAssessmentDate != null) ...[
                    ResponsiveSpacing(multiplier: 2),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: Colors.blue[700], size: 20),
                          const SizedBox(width: 8),
                          ResponsiveText(
                            'Last assessed: ${DateFormat('MMMM d, yyyy').format(_lastAssessmentDate!)}',
                            baseFontSize: 14,
                            color: Colors.blue[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            )
          else
            ResponsiveCard(
              elevation: 2,
              baseBorderRadius: 12,
              padding: ResponsiveConfig.paddingAll(context, 20),
              child: Column(
                children: [
                  const Icon(Icons.psychology_outlined, size: 64, color: Colors.grey),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    'No HIRE Assessment Available',
                    baseFontSize: 18,
                    color: Colors.grey[600],
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    'Start a mentorship session to assess this player\'s character development.',
                    baseFontSize: 14,
                    color: Colors.grey[500],
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleMenuAction('hire_mentorship'),
                  icon: const Icon(Icons.psychology),
                  label: const Text('Start Mentorship'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_hasHIREHistory) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _viewHIREHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHIREComponent(String letter, String title, double score, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
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
                baseFontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              ResponsiveText(
                score.toStringAsFixed(1),
                baseFontSize: 10,
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: ResponsiveText(
            title,
            baseFontSize: 10,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTab(DeviceType deviceType) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // HIRE History Summary
          ResponsiveCard(
            elevation: 2,
            baseBorderRadius: 12,
            padding: ResponsiveConfig.paddingAll(context, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'HIRE Development History',
                  baseFontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveSpacing(multiplier: 2),
                
                if (_hasHIREHistory) ...[
                  Row(
                    children: [
                      Expanded(
                        child: _buildHistoryStatCard(
                          'Total Assessments',
                          '$_totalAssessments',
                          Icons.assessment,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildHistoryStatCard(
                          'Last Assessment',
                          _lastAssessmentDate != null
                              ? DateFormat('MMM d').format(_lastAssessmentDate!)
                              : 'Never',
                          Icons.event,
                          Colors.green,
                        ),
                      ),
                    ],
                  ),
                  
                  ResponsiveSpacing(multiplier: 2),
                  
                  ElevatedButton.icon(
                    onPressed: _viewHIREHistory,
                    icon: const Icon(Icons.history),
                    label: const Text('View Full History'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
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
                    'Character development history will appear here after completing mentorship sessions.',
                    baseFontSize: 14,
                    color: Colors.grey[500],
                    textAlign: TextAlign.center,
                  ),
                  
                  ResponsiveSpacing(multiplier: 2),
                  
                  ElevatedButton.icon(
                    onPressed: () => _handleMenuAction('hire_mentorship'),
                    icon: const Icon(Icons.psychology),
                    label: const Text('Start First Assessment'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryStatCard(String title, String value, IconData icon, Color color) {
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

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: ResponsiveText(
              label,
              baseFontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              baseFontSize: 14,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action) {
    if (_currentPlayer == null) return;
    
    print('🎯 Menu action: $action for player: ${_currentPlayer!.name} (ID: ${_currentPlayer!.id})');
    
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedPlayer(_currentPlayer!.name);
    
    switch (action) {
      case 'analytics':
        Navigator.pushNamed(context, '/analytics', arguments: _currentPlayer);
        break;
      case 'hire_mentorship':
        Navigator.pushNamed(context, '/hire-mentorship-individual');
        break;
      case 'shot_assessment':
        Navigator.pushNamed(context, '/shot-assessment');
        break;
      case 'skating_assessment':
        Navigator.pushNamed(context, '/skating-assessment');
        break;
    }
  }

  void _editPlayer(Player player) {
    Navigator.pushNamed(context, '/edit-player', arguments: player);
  }

  void _viewHIREHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HIREHistoryScreen(player: _currentPlayer),
      ),
    );
  }
}