import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/common/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';

class CoordinatorDetailsScreen extends StatefulWidget {
  const CoordinatorDetailsScreen({Key? key}) : super(key: key);

  @override
  State<CoordinatorDetailsScreen> createState() => _CoordinatorDetailsScreenState();
}

class _CoordinatorDetailsScreenState extends State<CoordinatorDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _coordinator;
  List<Player> _players = [];
  List<Team> _teams = [];
  List<User> _coaches = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Add tab change listener
    _tabController.addListener(() {
      setState(() {}); // Rebuild to update floating action button
    });
    
    // Delay until the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is User) {
        setState(() {
          _coordinator = args;
        });
        _loadCoordinatorData(args);
      } else {
        setState(() {
          _errorMessage = 'No coordinator selected';
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCoordinatorData(User coordinator) async {
    if (coordinator.id == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final allPlayers = appState.players;
      
      // Get players coordinated by this coordinator
      final players = allPlayers.where((p) => p.coordinatorId == coordinator.id).toList();
      
      // Get unique teams these players belong to
      final teamIds = <int?>{};
      for (final player in players) {
        if (player.teamId != null) {
          teamIds.add(player.teamId);
        }
      }
      
      // Get team objects
      final teams = <Team>[];
      for (final teamId in teamIds) {
        if (teamId != null) {
          final team = appState.teams.firstWhereOrNull(
            (t) => t.id == teamId,
          );
          if (team != null) {
            teams.add(team);
          } else {
            teams.add(Team(name: 'Unknown Team', id: teamId));
          }
        }
      }
      
      // Get coaches for this coordinator's players
      final coachIds = <int?>{};
      for (final player in players) {
        if (player.primaryCoachId != null) {
          coachIds.add(player.primaryCoachId);
        }
      }
      
      // Get coach objects
      final coaches = <User>[];
      for (final coachId in coachIds) {
        if (coachId != null) {
          final coach = appState.coaches.firstWhereOrNull(
            (c) => c.id == coachId,
          );
          if (coach != null) {
            coaches.add(coach);
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _players = players;
          _teams = teams;
          _coaches = coaches;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading coordinator data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _assignPlayerToCoordinator() async {
    if (_coordinator == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/assign-player-to-coordinator',
      arguments: _coordinator,
    );
    
    if (result == true) {
      _loadCoordinatorData(_coordinator!);
    }
  }
  
  Future<void> _assignTeamToCoordinator() async {
    if (_coordinator == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/assign-team',
      arguments: _coordinator,
    );
    
    if (result == true) {
      _loadCoordinatorData(_coordinator!);
    }
  }
  
  Future<void> _assignCoachToTeam() async {
    if (_coordinator == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/assign-coach',
      arguments: _coordinator,
    );
    
    if (result == true) {
      _loadCoordinatorData(_coordinator!);
    }
  }
  
  Future<void> _editCoordinator() async {
    if (_coordinator == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/coordinator-form',
      arguments: _coordinator,
    );
    
    if (result == true) {
      // Reload coordinator data
      final appState = Provider.of<AppState>(context, listen: false);
      final updatedCoordinator = appState.coordinators.firstWhereOrNull(
        (c) => c.id == _coordinator!.id,
      ) ?? _coordinator!;
      
      setState(() {
        _coordinator = updatedCoordinator;
      });
      
      _loadCoordinatorData(updatedCoordinator);
    }
  }
  
  Future<void> _deleteCoordinator() async {
    if (_coordinator == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: ResponsiveText(
            'Delete Coordinator',
            baseFontSize: 18,
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Are you sure you want to delete this coordinator?',
                  baseFontSize: 16,
                ),
                ResponsiveSpacing(multiplier: 1.5),
                ResponsiveCard(
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  backgroundColor: Colors.grey[100],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        _coordinator!.name,
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResponsiveText(
                        _coordinator!.email,
                        baseFontSize: 14,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1.5),
                if (_players.isNotEmpty || _teams.isNotEmpty)
                  ResponsiveCard(
                    padding: ResponsiveConfig.paddingAll(context, 12),
                    backgroundColor: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.warning, color: Colors.orange[700], size: 20),
                            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                            ResponsiveText(
                              'Warning',
                              baseFontSize: 14,
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ResponsiveSpacing(multiplier: 1),
                        if (_teams.isNotEmpty)
                          ResponsiveText(
                            '• ${_teams.length} team(s) will need to be reassigned to another coordinator',
                            baseFontSize: 14,
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                        if (_players.isNotEmpty)
                          ResponsiveText(
                            '• ${_players.length} player(s) will need to be reassigned to another coordinator',
                            baseFontSize: 14,
                            style: TextStyle(color: Colors.orange[700]),
                          ),
                      ],
                    ),
                  ),
                ResponsiveSpacing(multiplier: 1.5),
                ResponsiveText(
                  'This action cannot be undone.',
                  baseFontSize: 14,
                  style: TextStyle(
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: ResponsiveText('Cancel', baseFontSize: 14),
            ),
            ResponsiveButton(
              text: 'Delete',
              baseHeight: 36,
              onPressed: () => Navigator.of(context).pop(true),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ],
        );
      },
    );
    
    if (confirmed != true) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.deleteUser(_coordinator!.id!);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              'Coordinator ${_coordinator!.name} deleted successfully',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to coordinators list
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              'Error deleting coordinator: $e',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _viewPlayerDetails(Player player) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedPlayer(player.name);
    Navigator.pushNamed(context, '/analytics');
  }
  
  void _editPlayer(Player player) {
    Navigator.pushNamed(
      context,
      '/edit-player',
      arguments: player,
    ).then((result) {
      if (result == true && _coordinator != null) {
        _loadCoordinatorData(_coordinator!);
      }
    });
  }
  
  void _viewTeamDetails(Team team) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedTeam(team);
    Navigator.pushNamed(context, '/team-details');
  }
  
  void _viewCoachDetails(User coach) {
    Navigator.pushNamed(
      context,
      '/coach-details',
      arguments: coach,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    
    // Role-based permissions
    final canEditCoordinator = userRole == 'admin' || userRole == 'director';
    final canDeleteCoordinator = userRole == 'admin'; // Only admin can delete
    final canAssignPlayers = userRole == 'admin' || userRole == 'director' || 
                            (userRole == 'coordinator' && 
                             _coordinator?.id == appState.currentUser?['id']);
    
    if (_coordinator == null) {
      return AdaptiveScaffold(
        title: 'Coordinator Details',
        backgroundColor: Colors.grey[100],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _errorMessage != null
                ? _buildErrorState()
                : _buildLoadingState();
          },
        ),
      );
    }
    
    return AdaptiveScaffold(
      title: _coordinator!.name,
      backgroundColor: Colors.grey[100],
      actions: [
        if (canEditCoordinator)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCoordinator,
            tooltip: 'Edit Coordinator',
          ),
        if (canDeleteCoordinator)
          _buildDeleteMenu(),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabBar(deviceType),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildTabBarView(deviceType, canAssignPlayers),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(canAssignPlayers),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ResponsiveCard(
        padding: ResponsiveConfig.paddingAll(context, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveConfig.dimension(context, 64),
              color: Colors.red[400],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Coordinator Not Found',
              baseFontSize: 20,
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              _errorMessage ?? 'Unknown error occurred',
              baseFontSize: 14,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 3),
            ResponsiveButton(
              text: 'Go Back',
              baseHeight: 48,
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.arrow_back),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ResponsiveCard(
        padding: ResponsiveConfig.paddingAll(context, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
              strokeWidth: ResponsiveConfig.dimension(context, 3),
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Loading coordinator data...',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteMenu() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'delete') {
          _deleteCoordinator();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red[700], size: 20),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Delete Coordinator',
                baseFontSize: 14,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }

  Widget _buildTabBar(DeviceType deviceType) {
    return Container(
      color: Colors.blueGrey[900],
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyanAccent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        labelStyle: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 14),
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 14),
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Profile'),
          Tab(text: 'Teams'),
          Tab(text: 'Players'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(DeviceType deviceType, bool canAssignPlayers) {
    return TabBarView(
      controller: _tabController,
      children: [
        // Profile tab
        _buildProfileTab(deviceType),
        
        // Teams tab
        _buildTeamsTab(canAssignPlayers, deviceType),
        
        // Players tab
        _buildPlayersTab(canAssignPlayers, deviceType),
      ],
    );
  }
  
  Widget? _buildFloatingActionButton(bool canAssign) {
    if (!canAssign) return null;
    
    switch (_tabController.index) {
      case 1: // Teams tab
        return FloatingActionButton.extended(
          onPressed: _assignTeamToCoordinator,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          icon: const Icon(Icons.group_add),
          label: ResponsiveText('Assign Team', baseFontSize: 14),
          tooltip: 'Assign Team',
        );
      case 2: // Players tab
        return FloatingActionButton.extended(
          onPressed: _assignPlayerToCoordinator,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          icon: const Icon(Icons.person_add),
          label: ResponsiveText('Assign Player', baseFontSize: 14),
          tooltip: 'Assign Player',
        );
      default:
        return null;
    }
  }
  
  Widget _buildProfileTab(DeviceType deviceType) {
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
            // Coordinator profile card
            _buildCoordinatorProfileCard(deviceType),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Coordination summary
            _buildCoordinationSummary(deviceType),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Coaches section
            if (_coaches.isNotEmpty) _buildCoachesSection(deviceType),
          ],
        ),
      ),
    );
  }

  Widget _buildCoordinatorProfileCard(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (deviceType == DeviceType.mobile && !isLandscape) {
            // Mobile portrait: Stack vertically
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCoordinatorAvatar(),
                ResponsiveSpacing(multiplier: 2),
                _buildCoordinatorDetails(),
              ],
            );
          } else {
            // Tablet/Desktop: Side by side
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoordinatorAvatar(),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(child: _buildCoordinatorDetails()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCoordinatorAvatar() {
    return CircleAvatar(
      radius: ResponsiveConfig.dimension(context, 40),
      backgroundColor: Colors.blue[200],
      child: ResponsiveText(
        _coordinator!.name.isNotEmpty ? _coordinator!.name[0].toUpperCase() : '?',
        baseFontSize: 32,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCoordinatorDetails() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          _coordinator!.name,
          baseFontSize: 24,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1),
        Row(
          children: [
            Icon(
              Icons.email,
              size: ResponsiveConfig.dimension(context, 16),
              color: Colors.blueGrey[400],
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText(
              _coordinator!.email,
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 0.5),
        Row(
          children: [
            Icon(
              Icons.person,
              size: ResponsiveConfig.dimension(context, 16),
              color: Colors.blueGrey[400],
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            ResponsiveText(
              'Username: ${_coordinator!.username}',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
        if (_coordinator!.createdAt != null) ...[
          ResponsiveSpacing(multiplier: 0.5),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: ResponsiveConfig.dimension(context, 16),
                color: Colors.blueGrey[400],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Member since ${_formatDate(_coordinator!.createdAt!)}',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildCoordinationSummary(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Coordination Summary',
            baseFontSize: 18,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 2),
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile: Single column
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildSummaryStat(Icons.group, '${_teams.length}', 'Teams', Colors.blue),
                    ResponsiveSpacing(multiplier: 2),
                    _buildSummaryStat(Icons.person, '${_players.length}', 'Players', Colors.blue),
                    ResponsiveSpacing(multiplier: 2),
                    _buildSummaryStat(Icons.sports, '${_coaches.length}', 'Coaches', Colors.blue),
                  ],
                );
              } else {
                // Tablet/Desktop: Row layout
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(Icons.group, '${_teams.length}', 'Teams', Colors.blue),
                    _buildSummaryStat(Icons.person, '${_players.length}', 'Players', Colors.blue),
                    _buildSummaryStat(Icons.sports, '${_coaches.length}', 'Coaches', Colors.blue),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryStat(IconData icon, String value, String label, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveConfig.dimension(context, 32),
          color: color,
        ),
        ResponsiveSpacing(multiplier: 1),
        ResponsiveText(
          value,
          baseFontSize: 24,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveText(
          label,
          baseFontSize: 14,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
      ],
    );
  }
  
  Widget _buildCoachesSection(DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Coaches',
          baseFontSize: 18,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _coaches.length,
          itemBuilder: (context, index) {
            final coach = _coaches[index];
            
            // Count players under this coach
            final coachPlayers = _players.where((p) => p.primaryCoachId == coach.id).length;
            
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: ResponsiveCard(
                padding: ResponsiveConfig.paddingAll(context, 12),
                child: InkWell(
                  onTap: () => _viewCoachDetails(coach),
                  borderRadius: ResponsiveConfig.borderRadius(context, 10),
                  child: Row(
                    children: [
                      // Coach avatar
                      CircleAvatar(
                        radius: ResponsiveConfig.dimension(context, 24),
                        backgroundColor: Colors.green[100],
                        child: ResponsiveText(
                          coach.name.isNotEmpty ? coach.name[0].toUpperCase() : '?',
                          baseFontSize: 20,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      // Coach info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              coach.name,
                              baseFontSize: 16,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ResponsiveText(
                              coach.email,
                              baseFontSize: 14,
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                            ResponsiveSpacing(multiplier: 0.5),
                            ResponsiveText(
                              '$coachPlayers players coached',
                              baseFontSize: 14,
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Coach badge
                      Container(
                        padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: ResponsiveConfig.borderRadius(context, 16),
                          border: Border.all(color: Colors.green[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports,
                              size: ResponsiveConfig.dimension(context, 14),
                              color: Colors.green[700],
                            ),
                            ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                            ResponsiveText(
                              'Coach',
                              baseFontSize: 12,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  Widget _buildTeamsTab(bool canAssign, DeviceType deviceType) {
    if (_teams.isEmpty) {
      return SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: ResponsiveConfig.dimension(context, 64),
                color: Colors.blueGrey[300],
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveText(
                'No Teams Assigned',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ResponsiveText(
                canAssign
                    ? 'Assign teams to this coordinator'
                    : 'No teams have been assigned to this coordinator yet',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
                textAlign: TextAlign.center,
              ),
              if (canAssign) ...[
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Assign Team',
                  baseHeight: 48,
                  onPressed: _assignTeamToCoordinator,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: const Icon(Icons.group_add),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _teams.length,
          itemBuilder: (context, index) {
            final team = _teams[index];
            
            // Count players in this team
            final teamPlayers = _players.where((p) => p.teamId == team.id).length;
            
            // Count coaches in this team
            final teamCoaches = _players
                .where((p) => p.teamId == team.id && p.primaryCoachId != null)
                .map((p) => p.primaryCoachId)
                .toSet()
                .length;
            
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: ResponsiveCard(
                padding: ResponsiveConfig.paddingAll(context, 12),
                child: InkWell(
                  onTap: () => _viewTeamDetails(team),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                  child: Row(
                    children: [
                      // Team logo
                      Container(
                        width: ResponsiveConfig.dimension(context, 60),
                        height: ResponsiveConfig.dimension(context, 60),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[100],
                          borderRadius: ResponsiveConfig.borderRadius(context, 8),
                        ),
                        child: team.logoPath != null
                            ? ClipRRect(
                                borderRadius: ResponsiveConfig.borderRadius(context, 8),
                                child: Image.network(
                                  team.logoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    Icon(
                                      Icons.sports_hockey, 
                                      size: ResponsiveConfig.dimension(context, 30), 
                                      color: Colors.blueGrey[400],
                                    ),
                                ),
                              )
                            : Icon(
                                Icons.sports_hockey, 
                                size: ResponsiveConfig.dimension(context, 30), 
                                color: Colors.blueGrey[400],
                              ),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      // Team info
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ResponsiveText(
                              team.name,
                              baseFontSize: 18,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (team.description != null && team.description!.isNotEmpty) ...[
                              ResponsiveSpacing(multiplier: 0.5),
                              ResponsiveText(
                                team.description!,
                                baseFontSize: 14,
                                style: TextStyle(color: Colors.blueGrey[600]),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            ResponsiveSpacing(multiplier: 1),
                            Row(
                              children: [
                                _buildTeamStat(Icons.person, '$teamPlayers players'),
                                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                                _buildTeamStat(Icons.sports, '$teamCoaches coaches'),
                              ],
                            ),
                          ],
                        ),
                      ),
                      // View details arrow
                      Icon(
                        Icons.arrow_forward_ios,
                        size: ResponsiveConfig.dimension(context, 16),
                        color: Colors.blueGrey[400],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildTeamStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveConfig.dimension(context, 16),
          color: Colors.blueGrey[400],
        ),
        ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
        ResponsiveText(
          label,
          baseFontSize: 14,
          style: TextStyle(color: Colors.blueGrey[600]),
        ),
      ],
    );
  }
  
  Widget _buildPlayersTab(bool canAssign, DeviceType deviceType) {
    if (_players.isEmpty) {
      return SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: ResponsiveConfig.dimension(context, 64),
                color: Colors.blueGrey[300],
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveText(
                'No Players Assigned',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ResponsiveText(
                canAssign
                    ? 'Assign players to this coordinator'
                    : 'No players have been assigned to this coordinator yet',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
                textAlign: TextAlign.center,
              ),
              if (canAssign) ...[
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Assign Player',
                  baseHeight: 48,
                  onPressed: _assignPlayerToCoordinator,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: const Icon(Icons.person_add),
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    // Use our custom player card widget for the player list
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
        ),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _players.length,
          itemBuilder: (context, index) {
            final player = _players[index];
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: PlayerCard(
                player: player,
                onTap: () => _viewPlayerDetails(player),
                onEditTap: () => _editPlayer(player),
                onViewStats: () => _viewPlayerDetails(player),
                showTeam: true,
                showCoach: true,
                showCoordinator: false, // No need to show coordinator since this is the coordinator's view
              ),
            );
          },
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Extension method for firstWhereOrNull
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test) {
    for (var element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}