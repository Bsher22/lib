import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/calendar_event.dart';
import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:hockey_shot_tracker/models/skating_assessment.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:intl/intl.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _dashboardData = {};
  String _selectedTimeRange = '7 days';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Load all dashboard data in parallel
      final results = await Future.wait([
        _loadSystemOverview(appState),
        _loadUpcomingEvents(appState),
        _loadRecentActivity(appState),
        _loadQuickActions(appState),
      ]);
      
      setState(() {
        _dashboardData = {
          'systemOverview': results[0],
          'upcomingEvents': results[1],
          'recentActivity': results[2],
          'quickActions': results[3],
          'lastUpdated': DateTime.now(),
        };
        _isLoading = false;
      });
    } catch (e) {
      print('Dashboard loading error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load dashboard: $e')),
        );
      }
    }
  }

  Future<Map<String, dynamic>> _loadSystemOverview(AppState appState) async {
    try {
      // Use existing AppState data
      final totalPlayers = appState.players.length;
      final totalTeams = appState.teams.length;
      final totalShots = appState.shots.length;
      final totalSkatings = appState.skatings.length;
      
      // Calculate today's activity
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      final todayShots = appState.shots.where((shot) {
        final shotDate = DateTime(shot.timestamp.year, shot.timestamp.month, shot.timestamp.day);
        return shotDate == today;
      }).length;
      
      final weeklyShots = appState.shots.where((shot) {
        return shot.timestamp.isAfter(now.subtract(const Duration(days: 7)));
      }).length;
      
      return {
        'totalPlayers': totalPlayers,
        'totalTeams': totalTeams,
        'totalShots': totalShots,
        'totalSkatings': totalSkatings,
        'todayShots': todayShots,
        'weeklyShots': weeklyShots,
        'currentUser': appState.getCurrentUser(),
        'systemHealth': 'Good',
      };
    } catch (e) {
      print('Error loading system overview: $e');
      return {
        'totalPlayers': 0,
        'totalTeams': 0,
        'totalShots': 0,
        'totalSkatings': 0,
        'todayShots': 0,
        'weeklyShots': 0,
        'currentUser': null,
        'systemHealth': 'Unknown',
      };
    }
  }

  Future<List<CalendarEvent>> _loadUpcomingEvents(AppState appState) async {
    try {
      // Use actual API method with proper date range
      final endDate = DateTime.now().add(const Duration(days: 7));
      final events = await ApiServiceFactory.calendar.fetchUpcomingEvents(limit: 5);
      return events;
    } catch (e) {
      print('Error loading upcoming events: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadRecentActivity(AppState appState) async {
    try {
      final activities = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final cutoff = now.subtract(const Duration(days: 3));
      
      // Recent shots
      final recentShots = appState.shots
          .where((shot) => shot.timestamp.isAfter(cutoff))
          .take(3)
          .toList();
      
      for (final shot in recentShots) {
        final player = appState.players.firstWhere(
          (p) => p.id == shot.playerId,
          orElse: () => Player(name: 'Unknown Player', createdAt: DateTime.now()),
        );
        
        activities.add({
          'type': 'shot',
          'title': 'Shot Recorded',
          'description': '${shot.type} shot in zone ${shot.zone}',
          'playerName': player.name,
          'playerImage': null,
          'timestamp': shot.timestamp,
          'success': shot.success,
          'icon': Icons.sports_hockey,
          'color': shot.success ? Colors.green : Colors.orange,
        });
      }
      
      // Recent skating assessments
      final recentSkatings = appState.skatings
          .where((skating) {
            final date = skating['date'] != null 
              ? DateTime.tryParse(skating['date']) 
              : null;
            return date != null && date.isAfter(cutoff);
          })
          .take(2)
          .toList();
      
      for (final skating in recentSkatings) {
        final playerId = skating['player_id'];
        final player = appState.players.firstWhere(
          (p) => p.id == playerId,
          orElse: () => Player(name: 'Unknown Player', createdAt: DateTime.now()),
        );
        
        activities.add({
          'type': 'skating',
          'title': 'Skating Assessment',
          'description': skating['assessment_type'] ?? 'Skating test completed',
          'playerName': player.name,
          'playerImage': null,
          'timestamp': DateTime.tryParse(skating['date']) ?? DateTime.now(),
          'icon': Icons.speed,
          'color': Colors.blue,
        });
      }
      
      // Sort by timestamp, most recent first
      activities.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
      
      return activities.take(5).toList();
    } catch (e) {
      print('Error loading recent activity: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadQuickActions(AppState appState) async {
    final userRole = appState.getCurrentUserRole();
    final actions = <Map<String, dynamic>>[];
    
    // Always available actions
    actions.addAll([
      {
        'title': 'Record Shots',
        'description': 'Start a training session',
        'icon': Icons.sports_hockey,
        'color': Colors.blue,
        'route': '/shot-input',
        'primary': true,
      },
      {
        'title': 'View Analytics',
        'description': 'Performance insights',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'route': '/analytics',
        'primary': false,
      },
    ]);
    
    // Role-based actions
    if (appState.canManageTeams()) {
      actions.addAll([
        {
          'title': 'Manage Teams',
          'description': 'Team administration',
          'icon': Icons.group,
          'color': Colors.green,
          'route': '/teams',
          'primary': false,
        },
        {
          'title': 'Schedule Events',
          'description': 'Calendar management',
          'icon': Icons.calendar_today,
          'color': Colors.orange,
          'route': '/calendar',
          'primary': false,
        },
      ]);
    }
    
    if (appState.isAdmin()) {
      actions.add({
        'title': 'Admin Panel',
        'description': 'System administration',
        'icon': Icons.admin_panel_settings,
        'color': Colors.red,
        'route': '/admin-panel',
        'primary': false,
      });
    }
    
    return actions;
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final currentUser = appState.getCurrentUser();
    final userRole = appState.getCurrentUserRole();

    return AdaptiveScaffold(
      title: 'HIRE Hockey Dashboard',
      backgroundColor: Colors.grey[50],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadDashboardData,
          tooltip: 'Refresh Dashboard',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) => _handleMenuAction(context, value),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(value: 'help', child: Text('Help')),
            const PopupMenuItem(value: 'logout', child: Text('Log Out')),
          ],
        ),
      ],
      body: _isLoading ? _buildLoadingView() : _buildDashboardContent(currentUser, userRole),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Loading your dashboard...',
            baseFontSize: 16,
            color: Colors.grey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(Map<String, dynamic>? currentUser, String? userRole) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: ResponsiveConfig.paddingSymmetric(
              context,
              horizontal: deviceType == DeviceType.desktop ? 32 : 16,
              vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(context, currentUser, userRole),
                  ResponsiveSpacing(multiplier: 3),
                  
                  // System Overview Cards
                  _buildSystemOverview(context, deviceType),
                  ResponsiveSpacing(multiplier: 3),
                  
                  // Main Dashboard Content
                  if (deviceType == DeviceType.desktop)
                    _buildDesktopLayout(context)
                  else
                    _buildMobileLayout(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeHeader(BuildContext context, Map<String, dynamic>? currentUser, String? userRole) {
    final userName = currentUser?['name'] ?? 'User';
    final systemOverview = _dashboardData['systemOverview'] ?? {};
    
    return ResponsiveCard(
      elevation: 2,
      baseBorderRadius: 16,
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      'Welcome back, $userName',
                      baseFontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  StatusBadge(
                    text: _formatRole(userRole ?? ''),
                    color: _getRoleColor(userRole ?? ''),
                    shape: StatusBadgeShape.pill,
                  ),
                  ResponsiveSpacing(multiplier: 0.5),
                  ResponsiveText(
                    'Last updated: ${DateFormat('h:mm a').format(_dashboardData['lastUpdated'] ?? DateTime.now())}',
                    baseFontSize: 12,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Quick system status
          Container(
            padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: ResponsiveConfig.borderRadius(context, 20),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                ResponsiveText(
                  'System Status: ${systemOverview['systemHealth'] ?? 'Good'}',
                  baseFontSize: 14,
                  color: Colors.green[700],
                  fontWeight: FontWeight.w500,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemOverview(BuildContext context, DeviceType deviceType) {
    final overview = _dashboardData['systemOverview'] ?? {};
    
    final cards = [
      _buildOverviewCard(
        context,
        'Players',
        '${overview['totalPlayers'] ?? 0}',
        Icons.people,
        Colors.blue,
        () => _navigate('/players'),
      ),
      _buildOverviewCard(
        context,
        'Teams',
        '${overview['totalTeams'] ?? 0}',
        Icons.group,
        Colors.purple,
        () => _navigate('/teams'),
      ),
      _buildOverviewCard(
        context,
        'Today\'s Shots',
        '${overview['todayShots'] ?? 0}',
        Icons.today,
        Colors.green,
        null,
      ),
      _buildOverviewCard(
        context,
        'Weekly Activity',
        '${overview['weeklyShots'] ?? 0}',
        Icons.trending_up,
        Colors.orange,
        () => _navigate('/analytics'),
      ),
    ];

    return _buildCardGrid(context, cards, deviceType);
  }

  Widget _buildOverviewCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback? onTap,
  ) {
    return ResponsiveCard(
      elevation: 3,
      baseBorderRadius: 12,
      onTap: onTap,
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: ResponsiveConfig.paddingAll(context, 12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (onTap != null)
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            value,
            baseFontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
          ResponsiveText(
            title,
            baseFontSize: 14,
            color: Colors.blueGrey[600],
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Events and Activity
        Expanded(
          flex: 2,
          child: Column(
            children: [
              _buildUpcomingEventsCard(context),
              ResponsiveSpacing(multiplier: 3),
              _buildRecentActivityCard(context),
            ],
          ),
        ),
        ResponsiveSpacing(multiplier: 4, direction: Axis.horizontal),
        
        // Right column - Quick Actions (moved up from Player Stats position)
        Expanded(
          flex: 2,
          child: _buildQuickActionsCard(context),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Column(
      children: [
        // Quick Actions moved to top (replaces Player Stats)
        _buildQuickActionsCard(context),
        ResponsiveSpacing(multiplier: 3),
        _buildUpcomingEventsCard(context),
        ResponsiveSpacing(multiplier: 3),
        _buildRecentActivityCard(context),
      ],
    );
  }

  Widget _buildUpcomingEventsCard(BuildContext context) {
    final events = _dashboardData['upcomingEvents'] ?? <CalendarEvent>[];
    
    return ResponsiveCard(
      elevation: 3,
      baseBorderRadius: 12,
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Upcoming Events',
                baseFontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              TextButton(
                onPressed: () => _navigate('/calendar'),
                child: ResponsiveText(
                  'View All',
                  baseFontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (events.isEmpty)
            _buildEmptyState(
              context,
              Icons.event_note,
              'No upcoming events',
              'Schedule practice sessions or assessments',
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: events.take(3).map((event) => 
                _buildEventItem(context, event)
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildEventItem(BuildContext context, CalendarEvent event) {
    final color = _getEventColor(event.eventType);
    final icon = _getEventIcon(event.eventType);
    final timeFormat = DateFormat('MMM d, h:mm a');
    
    return Container(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: ResponsiveConfig.paddingAll(context, 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  event.title,
                  baseFontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveText(
                  timeFormat.format(event.startTime),
                  baseFontSize: 14,
                  color: Colors.blueGrey[600],
                ),
                if (event.playerName != null)
                  ResponsiveText(
                    event.playerName!,
                    baseFontSize: 12,
                    color: Colors.blueGrey[500],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard(BuildContext context) {
    final activities = _dashboardData['recentActivity'] ?? <Map<String, dynamic>>[];
    
    return ResponsiveCard(
      elevation: 3,
      baseBorderRadius: 12,
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Recent Activity',
                baseFontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
              TextButton(
                onPressed: () => _navigate('/activity-log'),
                child: ResponsiveText(
                  'View All',
                  baseFontSize: 14,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          if (activities.isEmpty)
            _buildEmptyState(
              context,
              Icons.history,
              'No recent activity',
              'Start tracking to see activity here',
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              children: activities.map((activity) => 
                _buildActivityItem(context, activity)
              ).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(BuildContext context, Map<String, dynamic> activity) {
    final color = activity['color'] as Color;
    final icon = activity['icon'] as IconData;
    final timestamp = activity['timestamp'] as DateTime;
    
    return Container(
      margin: ResponsiveConfig.paddingOnly(context, bottom: 12),
      child: Row(
        children: [
          Container(
            padding: ResponsiveConfig.paddingAll(context, 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: ResponsiveConfig.borderRadius(context, 10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  activity['title'],
                  baseFontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[800],
                ),
                ResponsiveText(
                  activity['description'],
                  baseFontSize: 13,
                  color: Colors.blueGrey[600],
                ),
                ResponsiveText(
                  '${activity['playerName']} • ${_formatTimeAgo(timestamp)}',
                  baseFontSize: 12,
                  color: Colors.blueGrey[500],
                ),
              ],
            ),
          ),
          if (activity['success'] != null)
            Container(
              padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: activity['success'] ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                borderRadius: ResponsiveConfig.borderRadius(context, 12),
              ),
              child: ResponsiveText(
                activity['success'] ? 'Success' : 'Miss',
                baseFontSize: 10,
                fontWeight: FontWeight.w500,
                color: activity['success'] ? Colors.green[700] : Colors.orange[700],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    final actions = _dashboardData['quickActions'] ?? <Map<String, dynamic>>[];
    
    return ResponsiveCard(
      elevation: 3,
      baseBorderRadius: 12,
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Quick Actions',
            baseFontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Primary action button
          if (actions.any((action) => action['primary'] == true))
            ...[
              _buildPrimaryActionButton(
                context,
                actions.firstWhere((action) => action['primary'] == true),
              ),
              ResponsiveSpacing(multiplier: 2),
            ],
          
          // Secondary actions grid
          _buildActionGrid(
            context,
            actions.where((action) => action['primary'] != true).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActionButton(BuildContext context, Map<String, dynamic> action) {
    return ResponsiveButton(
      text: action['title'],
      onPressed: () => _navigate(action['route']),
      backgroundColor: action['color'],
      width: double.infinity,
      baseHeight: 56,
      icon: action['icon'],
    );
  }

  Widget _buildActionGrid(BuildContext context, List<Map<String, dynamic>> actions) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: actions.map((action) => _buildActionCard(context, action)).toList(),
    );
  }

  Widget _buildActionCard(BuildContext context, Map<String, dynamic> action) {
    return ResponsiveCard(
      elevation: 1,
      baseBorderRadius: 12,
      onTap: () => _navigate(action['route']),
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: ResponsiveConfig.paddingAll(context, 12),
            decoration: BoxDecoration(
              color: action['color'].withOpacity(0.15),
              borderRadius: ResponsiveConfig.borderRadius(context, 12),
            ),
            child: Icon(action['icon'], color: action['color'], size: 24),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            action['title'],
            baseFontSize: 14,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
            color: Colors.blueGrey[800],
          ),
          ResponsiveText(
            action['description'],
            baseFontSize: 11,
            textAlign: TextAlign.center,
            color: Colors.blueGrey[600],
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(BuildContext context, List<Widget> cards, DeviceType deviceType) {
    if (deviceType == DeviceType.mobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: cards[0]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(child: cards[1]),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          Row(
            children: [
              Expanded(child: cards[2]),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(child: cards[3]),
            ],
          ),
        ],
      );
    }
    
    return Row(
      children: cards
          .map((card) => Expanded(child: card))
          .expand((widget) => [
                widget,
                if (widget != cards.last)
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              ])
          .toList(),
    );
  }

  Widget _buildEmptyState(BuildContext context, IconData icon, String title, String subtitle) {
    return Center(
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey[300]),
            ResponsiveSpacing(multiplier: 1.5),
            ResponsiveText(
              title,
              baseFontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            ResponsiveText(
              subtitle,
              baseFontSize: 14,
              color: Colors.grey[500],
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return Colors.red;
      case 'director': return Colors.purple;
      case 'coordinator': return Colors.blue;
      case 'coach': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getEventColor(EventType eventType) {
    switch (eventType) {
      case EventType.workout: return Colors.blue;
      case EventType.assessment: return Colors.orange;
      case EventType.practice: return Colors.green;
      case EventType.game: return Colors.red;
      case EventType.custom: return Colors.purple;
    }
  }

  IconData _getEventIcon(EventType eventType) {
    switch (eventType) {
      case EventType.workout: return Icons.fitness_center;
      case EventType.assessment: return Icons.assessment;
      case EventType.practice: return Icons.sports;
      case EventType.game: return Icons.emoji_events;
      case EventType.custom: return Icons.event;
    }
  }

  String _formatRole(String role) {
    return role.isEmpty ? 'User' : role[0].toUpperCase() + role.substring(1);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigate(String route, {Object? arguments}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        NavigationService().pushNamed(route, arguments: arguments);
      } catch (e) {
        print('Navigation error to $route: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Navigation error: $e')),
          );
        }
      }
    });
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'settings':
        _navigate('/settings');
        break;
      case 'help':
        _navigate('/help');
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    DialogService.showConfirmation(
      context,
      title: 'Log Out',
      message: 'Are you sure you want to log out?',
      confirmLabel: 'Log Out',
      cancelLabel: 'Cancel',
    ).then((confirmed) async {
      if (confirmed == true) {
        final appState = Provider.of<AppState>(context, listen: false);
        await appState.logout();
        try {
          await NavigationService().pushNamedAndRemoveUntil('/login');
        } catch (e) {
          print('Logout navigation error: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Navigation error: $e')),
            );
          }
        }
      }
    });
  }
}