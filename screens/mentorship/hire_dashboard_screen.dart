// lib/screens/mentorship/hire_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/development_plan_service.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/screens/mentorship/hire_mentorship_screen.dart';
import 'package:intl/intl.dart';

class HIREDashboardScreen extends StatefulWidget {
  const HIREDashboardScreen({super.key});

  @override
  State<HIREDashboardScreen> createState() => _HIREDashboardScreenState();
}

class _HIREDashboardScreenState extends State<HIREDashboardScreen> {
  
  DevelopmentPlanService get _developmentPlanService {
    final apiService = Provider.of<ApiService>(context, listen: false);
    return DevelopmentPlanService(apiService: apiService);
}
  
  // State management
  bool _isLoading = true;
  String? _errorMessage;
  List<Player> _assignedPlayers = [];
  Map<int, HIREDashboardPlayerData> _playerHIREData = {};
  
  // Filters
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'hire_score', 'last_session', 'needs_attention'
  bool _showOnlyNeedsAttention = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================================
  // DATA LOADING
  // ============================================================================

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final currentUser = appState.currentUser; // This is Map<String, dynamic>?
      
      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      // Load players based on user role
      await appState.loadPlayers();
      
      // Filter players based on role permissions
      _assignedPlayers = _getPlayersForUser(appState.players, currentUser); // FIXED: Pass Map directly
      
      // Load HIRE data for each player
      await _loadPlayerHIREData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load HIRE dashboard: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  List<Player> _getPlayersForUser(List<Player> allPlayers, Map<String, dynamic> user) { // FIXED: Accept Map instead of User
    switch (user['role']) { // FIXED: Access role from Map
      case 'admin':
      case 'director':
        // Admin and directors see all players
        return allPlayers;
        
      case 'coordinator':
        // Coordinators see players they're assigned to
        return allPlayers.where((player) => player.coordinatorId == user['id']).toList();
        
      case 'coach':
        // Coaches see players they're assigned to
        return allPlayers.where((player) => player.primaryCoachId == user['id']).toList();
        
      default:
        return [];
    }
  }

  Future<void> _loadPlayerHIREData() async {
    final futures = _assignedPlayers.map((player) async {
      if (player.id == null) return;
      
      try {
        // Load development plan and HIRE scores
        final developmentPlan = await _developmentPlanService.loadPlayerDevelopmentPlan(player.id!);
        HIREScores? hireScores;
        
        if (developmentPlan != null) {
          try {
            hireScores = await _developmentPlanService.loadHIREScoresFromBackend(player.id!);
          } catch (e) {
            debugPrint('Could not load HIRE scores for ${player.name}: $e');
          }
        }
        
        if (mounted) {
          setState(() {
            _playerHIREData[player.id!] = HIREDashboardPlayerData(
              player: player,
              developmentPlan: developmentPlan,
              hireScores: hireScores,
              lastSessionDate: developmentPlan?.scoresCalculatedAt ?? developmentPlan?.assessmentDate,
              needsAttention: _calculateNeedsAttention(developmentPlan, hireScores),
            );
          });
        }
      } catch (e) {
        debugPrint('Error loading HIRE data for ${player.name}: $e');
      }
    });

    await Future.wait(futures);
  }

  bool _calculateNeedsAttention(DevelopmentPlanData? plan, HIREScores? scores) {
    if (plan == null) return true; // No plan = needs attention
    
    // Check if scores are missing or low
    if (scores == null) return true;
    if (scores.overall < 6.0) return true;
    
    // Check if last session was more than 30 days ago
    final lastSession = plan.scoresCalculatedAt ?? plan.assessmentDate;
    if (DateTime.now().difference(lastSession).inDays > 30) return true;
    
    // Check if plan needs recalculation
    if (plan.needsRecalculation) return true;
    
    return false;
  }

  // ============================================================================
  // FILTERING AND SORTING
  // ============================================================================

  List<HIREDashboardPlayerData> _getFilteredAndSortedPlayers() {
    var filtered = _playerHIREData.values.where((data) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!data.player.name.toLowerCase().contains(query)) {
          return false;
        }
      }
      
      // Needs attention filter
      if (_showOnlyNeedsAttention && !data.needsAttention) {
        return false;
      }
      
      return true;
    }).toList();

    // Sort players
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'hire_score':
          final aScore = a.hireScores?.overall ?? 0.0;
          final bScore = b.hireScores?.overall ?? 0.0;
          return bScore.compareTo(aScore); // Descending
          
        case 'last_session':
          final aDate = a.lastSessionDate ?? DateTime(2020);
          final bDate = b.lastSessionDate ?? DateTime(2020);
          return bDate.compareTo(aDate); // Most recent first
          
        case 'needs_attention':
          if (a.needsAttention && !b.needsAttention) return -1;
          if (!a.needsAttention && b.needsAttention) return 1;
          return a.player.name.compareTo(b.player.name);
          
        default: // 'name'
          return a.player.name.compareTo(b.player.name);
      }
    });

    return filtered;
  }

  // ============================================================================
  // UI BUILDING
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'HIRE Mentorship Dashboard',
      backgroundColor: Colors.grey[50],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh Dashboard',
        ),
        Consumer<AppState>(
          builder: (context, appState, child) {
            if (appState.canManageCoaches()) {
              return IconButton(
                icon: const Icon(Icons.settings),
                onPressed: _showDashboardSettings,
                tooltip: 'Dashboard Settings',
              );
            }
            return const SizedBox.shrink();
          },
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

          if (_assignedPlayers.isEmpty) {
            return _buildEmptyState();
          }

          return _buildDashboardContent(deviceType, isLandscape);
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
          Text('Loading HIRE dashboard...'),
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
              'Error Loading Dashboard',
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
              onPressed: _loadDashboardData,
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
            const Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Players Assigned',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'You don\'t have any players assigned for HIRE mentorship',
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

  Widget _buildDashboardContent(DeviceType deviceType, bool isLandscape) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _buildDashboardHeader(deviceType),
        ),
        SliverToBoxAdapter(
          child: _buildFiltersAndSearch(deviceType),
        ),
        SliverToBoxAdapter(
          child: _buildQuickStats(),
        ),
        _buildPlayerCards(deviceType),
      ],
    );
  }

  Widget _buildDashboardHeader(DeviceType deviceType) {
    final user = Provider.of<AppState>(context, listen: false).currentUser; // Map<String, dynamic>?
    
    return Container(
      padding: const EdgeInsets.all(16),
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
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.15),
                    borderRadius: ResponsiveConfig.borderRadius(context, 12),
                  ),
                  child: const Icon(
                    Icons.dashboard,
                    color: Colors.blue,
                    size: 32,
                  ),
                ),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'HIRE Mentorship Dashboard',
                        baseFontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      ResponsiveSpacing(multiplier: 0.5),
                      ResponsiveText(
                        'Welcome back, ${user?['name'] ?? 'Coach'}! Track and mentor your players\' character development.', // FIXED: Access name from Map
                        baseFontSize: 16,
                        color: Colors.blueGrey[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            if (deviceType == DeviceType.desktop) ...[
              ResponsiveSpacing(multiplier: 2),
              Container(
                padding: ResponsiveConfig.paddingAll(context, 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: ResponsiveText(
                  'Click on any player card to start a mentorship session. Use filters to focus on players who need attention.',
                  baseFontSize: 14,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersAndSearch(DeviceType deviceType) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ResponsiveCard(
        elevation: 1,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          children: [
            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search players...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            
            ResponsiveSpacing(multiplier: 2),
            
            // Filters row
            AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                if (deviceType == DeviceType.mobile && !isLandscape) {
                  return Column(
                    children: [
                      _buildSortDropdown(),
                      ResponsiveSpacing(multiplier: 1),
                      _buildNeedsAttentionFilter(),
                    ],
                  );
                }
                
                return Row(
                  children: [
                    Expanded(child: _buildSortDropdown()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    _buildNeedsAttentionFilter(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortDropdown() {
    return DropdownButtonFormField<String>(
      value: _sortBy,
      decoration: InputDecoration(
        labelText: 'Sort by',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: const [
        DropdownMenuItem(value: 'name', child: Text('Name (A-Z)')),
        DropdownMenuItem(value: 'hire_score', child: Text('HIRE Score (High-Low)')),
        DropdownMenuItem(value: 'last_session', child: Text('Last Session (Recent)')),
        DropdownMenuItem(value: 'needs_attention', child: Text('Needs Attention')),
      ],
      onChanged: (value) => setState(() => _sortBy = value ?? 'name'),
    );
  }

  Widget _buildNeedsAttentionFilter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _showOnlyNeedsAttention,
          onChanged: (value) => setState(() => _showOnlyNeedsAttention = value ?? false),
        ),
        ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
        ResponsiveText(
          'Needs Attention Only',
          baseFontSize: 14,
          color: Colors.blueGrey[700],
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    final filteredPlayers = _getFilteredAndSortedPlayers();
    final needsAttentionCount = filteredPlayers.where((p) => p.needsAttention).length;
    final hasScoresCount = filteredPlayers.where((p) => p.hireScores != null).length;
    final avgScore = hasScoresCount > 0
        ? filteredPlayers
            .where((p) => p.hireScores != null)
            .map((p) => p.hireScores!.overall)
            .reduce((a, b) => a + b) / hasScoresCount
        : 0.0;

    return Container(
      margin: const EdgeInsets.all(16),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (deviceType == DeviceType.mobile && !isLandscape) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Total Players', '${filteredPlayers.length}', Icons.people, Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Needs Attention', '$needsAttentionCount', Icons.warning, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('With Scores', '$hasScoresCount', Icons.assessment, Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildStatCard('Avg HIRE Score', avgScore.toStringAsFixed(1), Icons.trending_up, Colors.purple)),
                  ],
                ),
              ],
            );
          }
          
          return Row(
            children: [
              Expanded(child: _buildStatCard('Total Players', '${filteredPlayers.length}', Icons.people, Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Needs Attention', '$needsAttentionCount', Icons.warning, Colors.orange)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('With Scores', '$hasScoresCount', Icons.assessment, Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Avg HIRE Score', avgScore.toStringAsFixed(1), Icons.trending_up, Colors.purple)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return ResponsiveCard(
      elevation: 1,
      baseBorderRadius: 8,
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            value,
            baseFontSize: 20,
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

  Widget _buildPlayerCards(DeviceType deviceType) {
    final filteredPlayers = _getFilteredAndSortedPlayers();
    
    if (filteredPlayers.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          margin: const EdgeInsets.all(16),
          child: ResponsiveCard(
            padding: ResponsiveConfig.paddingAll(context, 32),
            child: Column(
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                ResponsiveSpacing(multiplier: 2),
                ResponsiveText(
                  'No players match your filters',
                  baseFontSize: 18,
                  color: Colors.grey[600],
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Determine grid layout based on device type
    int crossAxisCount;
    double childAspectRatio;
    
    switch (deviceType) {
      case DeviceType.desktop:
        crossAxisCount = 4;
        childAspectRatio = 0.85;
        break;
      case DeviceType.tablet:
        crossAxisCount = 3;
        childAspectRatio = 0.8;
        break;
      case DeviceType.mobile:
        crossAxisCount = 2;
        childAspectRatio = 0.75;
        break;
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildPlayerCard(filteredPlayers[index], deviceType),
          childCount: filteredPlayers.length,
        ),
      ),
    );
  }

  Widget _buildPlayerCard(HIREDashboardPlayerData playerData, DeviceType deviceType) {
    final player = playerData.player;
    final hireScores = playerData.hireScores;
    final lastSession = playerData.lastSessionDate;
    final needsAttention = playerData.needsAttention;

    return ResponsiveCard(
      elevation: needsAttention ? 3 : 2,
      baseBorderRadius: 12,
      borderColor: needsAttention ? Colors.orange : null,
      borderWidth: needsAttention ? 2 : 0,
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: InkWell(
        onTap: () => _startMentorshipSession(player),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Header with avatar and attention indicator
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blueGrey[100],
                  radius: deviceType == DeviceType.mobile ? 20 : 24,
                  child: ResponsiveText(
                    player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                    baseFontSize: deviceType == DeviceType.mobile ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
                const Spacer(),
                if (needsAttention)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
            
            ResponsiveSpacing(multiplier: 1),
            
            // Player name
            ResponsiveText(
              player.name,
              baseFontSize: deviceType == DeviceType.mobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            
            ResponsiveSpacing(multiplier: 1),
            
            // HIRE Score Circle
            Container(
              width: deviceType == DeviceType.mobile ? 60 : 80,
              height: deviceType == DeviceType.mobile ? 60 : 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hireScores != null 
                    ? HockeyRatingsConfig.getColorForRating(hireScores.overall).withOpacity(0.1)
                    : Colors.grey[200],
                border: Border.all(
                  color: hireScores != null 
                      ? HockeyRatingsConfig.getColorForRating(hireScores.overall)
                      : Colors.grey[400]!,
                  width: 3,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hireScores != null) ...[
                    ResponsiveText(
                      hireScores.overall.toStringAsFixed(1),
                      baseFontSize: deviceType == DeviceType.mobile ? 16 : 20,
                      fontWeight: FontWeight.bold,
                      color: HockeyRatingsConfig.getColorForRating(hireScores.overall),
                    ),
                    ResponsiveText(
                      'HIRE',
                      baseFontSize: deviceType == DeviceType.mobile ? 8 : 10,
                      color: HockeyRatingsConfig.getColorForRating(hireScores.overall),
                    ),
                  ] else ...[
                    Icon(
                      Icons.assessment_outlined,
                      color: Colors.grey[400],
                      size: deviceType == DeviceType.mobile ? 24 : 32,
                    ),
                    ResponsiveText(
                      'No Score',
                      baseFontSize: 8,
                      color: Colors.grey[600],
                    ),
                  ],
                ],
              ),
            ),
            
            ResponsiveSpacing(multiplier: 1),
            
            // Last session date
            Column(
              children: [
                ResponsiveText(
                  'Last Session:',
                  baseFontSize: 10,
                  color: Colors.grey[600],
                ),
                ResponsiveText(
                  lastSession != null
                      ? DateFormat('MMM d').format(lastSession)
                      : 'Never',
                  baseFontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _getSessionDateColor(lastSession),
                ),
              ],
            ),
            
            ResponsiveSpacing(multiplier: 1),
            
            // Action button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _startMentorshipSession(player),
                style: ElevatedButton.styleFrom(
                  backgroundColor: needsAttention ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: ResponsiveText(
                  needsAttention ? 'Needs Review' : 'Start Session',
                  baseFontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSessionDateColor(DateTime? lastSession) {
    if (lastSession == null) return Colors.red;
    
    final daysSince = DateTime.now().difference(lastSession).inDays;
    if (daysSince <= 7) return Colors.green;
    if (daysSince <= 30) return Colors.orange;
    return Colors.red;
  }

  // ============================================================================
  // ACTIONS
  // ============================================================================

  void _startMentorshipSession(Player player) {
    // Set the selected player and navigate to individual mentorship screen
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedPlayer(player.name);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const HIREMentorshipScreen(),
      ),
    );
  }

  void _showDashboardSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dashboard Settings'),
        content: const Text('Dashboard configuration options will be available in a future update.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class HIREDashboardPlayerData {
  final Player player;
  final DevelopmentPlanData? developmentPlan;
  final HIREScores? hireScores;
  final DateTime? lastSessionDate;
  final bool needsAttention;

  const HIREDashboardPlayerData({
    required this.player,
    this.developmentPlan,
    this.hireScores,
    this.lastSessionDate,
    required this.needsAttention,
  });
}