import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/common/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';

class CoachDetailsScreen extends StatefulWidget {
  const CoachDetailsScreen({Key? key}) : super(key: key);

  @override
  State<CoachDetailsScreen> createState() => _CoachDetailsScreenState();
}

class _CoachDetailsScreenState extends State<CoachDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  User? _coach;
  List<Player> _players = [];
  List<Team> _teams = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Delay until the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is User) {
        setState(() {
          _coach = args;
        });
        _loadCoachData(args);
      } else {
        setState(() {
          _errorMessage = 'No coach selected';
        });
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCoachData(User coach) async {
    if (coach.id == null) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final allPlayers = appState.players;
      
      // Get players coached by this coach
      final players = allPlayers.where((p) => p.primaryCoachId == coach.id).toList();
      
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
          final team = appState.teams.firstWhere(
            (t) => t.id == teamId,
            orElse: () => Team(name: 'Unknown Team', id: teamId),
          );
          teams.add(team);
        }
      }
      
      if (mounted) {
        setState(() {
          _players = players;
          _teams = teams;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading coach data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _assignPlayerToCoach() async {
    if (_coach == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/assign-player-to-coach',
      arguments: _coach,
    );
    
    if (result == true) {
      _loadCoachData(_coach!);
    }
  }
  
  Future<void> _editCoach() async {
    if (_coach == null) return;
    
    final result = await Navigator.pushNamed(
      context,
      '/coach-form',
      arguments: _coach,
    );
    
    if (result == true) {
      // Reload coach data
      final appState = Provider.of<AppState>(context, listen: false);
      final updatedCoach = appState.coaches.firstWhere(
        (c) => c.id == _coach!.id,
        orElse: () => _coach!,
      );
      
      setState(() {
        _coach = updatedCoach;
      });
      
      _loadCoachData(updatedCoach);
    }
  }
  
  Future<void> _deleteCoach() async {
    if (_coach == null) return;
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: ResponsiveText(
            'Delete Coach',
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
                  'Are you sure you want to delete this coach?',
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
                        _coach!.name,
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ResponsiveText(
                        _coach!.email,
                        baseFontSize: 14,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                ResponsiveSpacing(multiplier: 1.5),
                if (_players.isNotEmpty)
                  ResponsiveCard(
                    padding: ResponsiveConfig.paddingAll(context, 12),
                    backgroundColor: Colors.orange[50],
                    border: Border.all(color: Colors.orange[200]!),
                    child: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange[700], size: 20),
                        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                        Expanded(
                          child: ResponsiveText(
                            'This coach has ${_players.length} assigned player(s). They will need to be reassigned to another coach.',
                            baseFontSize: 14,
                            style: TextStyle(color: Colors.orange[700]),
                          ),
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
      await appState.deleteUser(_coach!.id!);
      
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              'Coach ${_coach!.name} deleted successfully',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to coaches list
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
              'Error deleting coach: $e',
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
      if (result == true && _coach != null) {
        _loadCoachData(_coach!);
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    
    // Role-based permissions
    final canEditCoach = userRole == 'admin' || userRole == 'director';
    final canDeleteCoach = userRole == 'admin'; // Only admin can delete
    final canAssignPlayers = userRole == 'admin' || userRole == 'director' || 
                             (userRole == 'coordinator' && 
                              _players.any((p) => p.coordinatorId == appState.currentUser?['id']));
    
    if (_coach == null) {
      return AdaptiveScaffold(
        title: 'Coach Details',
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
      title: _coach!.name,
      backgroundColor: Colors.grey[100],
      actions: [
        if (canEditCoach)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editCoach,
            tooltip: 'Edit Coach',
          ),
        if (canDeleteCoach)
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
      floatingActionButton: canAssignPlayers && _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: _assignPlayerToCoach,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.person_add),
              label: ResponsiveText('Assign Player', baseFontSize: 14),
              tooltip: 'Assign Player',
            )
          : null,
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
              'Coach Not Found',
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
              icon: Icons.arrow_back, // Fixed: removed Icon() wrapper
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
              'Loading coach data...',
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
          _deleteCoach();
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
                'Delete Coach',
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
        
        // Players tab
        _buildPlayersTab(canAssignPlayers, deviceType),
      ],
    );
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
            // Coach profile card
            _buildCoachProfileCard(deviceType),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Coaching summary
            _buildCoachingSummary(deviceType),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Teams section
            if (_teams.isNotEmpty) _buildTeamsSection(deviceType),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachProfileCard(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (deviceType == DeviceType.mobile && !isLandscape) {
            // Mobile portrait: Stack vertically
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildCoachAvatar(),
                ResponsiveSpacing(multiplier: 2),
                _buildCoachDetails(),
              ],
            );
          } else {
            // Tablet/Desktop: Side by side
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCoachAvatar(),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(child: _buildCoachDetails()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildCoachAvatar() {
    return CircleAvatar(
      radius: ResponsiveConfig.dimension(context, 40),
      backgroundColor: Colors.green[200],
      child: ResponsiveText(
        _coach!.name.isNotEmpty ? _coach!.name[0].toUpperCase() : '?',
        baseFontSize: 32,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCoachDetails() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          _coach!.name,
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
              _coach!.email,
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
              'Username: ${_coach!.username}',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
        if (_coach!.createdAt != null) ...[
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
                'Member since ${_formatDate(_coach!.createdAt!)}',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildCoachingSummary(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Coaching Summary',
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
                    _buildSummaryStat(Icons.person, '${_players.length}', 'Players'),
                    ResponsiveSpacing(multiplier: 2),
                    _buildSummaryStat(Icons.group, '${_teams.length}', 'Teams'),
                    ResponsiveSpacing(multiplier: 2),
                    _buildSummaryStat(Icons.sports_hockey, '${_players.length * 15}', 'Sessions'),
                  ],
                );
              } else {
                // Tablet/Desktop: Row layout
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(Icons.person, '${_players.length}', 'Players'),
                    _buildSummaryStat(Icons.group, '${_teams.length}', 'Teams'),
                    _buildSummaryStat(Icons.sports_hockey, '${_players.length * 15}', 'Sessions'),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSummaryStat(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: ResponsiveConfig.dimension(context, 32),
          color: Colors.green,
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
  
  Widget _buildTeamsSection(DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Teams',
          baseFontSize: 18,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1.5),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _teams.length,
          itemBuilder: (context, index) {
            final team = _teams[index];
            final teamPlayers = _players.where((p) => p.teamId == team.id).toList();
            
            return Padding(
              padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
              child: ResponsiveCard(
                padding: ResponsiveConfig.paddingAll(context, 12),
                child: InkWell(
                  onTap: () {
                    // Navigate to team details
                    final appState = Provider.of<AppState>(context, listen: false);
                    appState.setSelectedTeam(team);
                    Navigator.pushNamed(context, '/team-details');
                  },
                  borderRadius: ResponsiveConfig.borderRadius(context, 10),
                  child: Row(
                    children: [
                      // Team icon or logo
                      Container(
                        width: ResponsiveConfig.dimension(context, 48),
                        height: ResponsiveConfig.dimension(context, 48),
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
                                      size: ResponsiveConfig.dimension(context, 24), 
                                      color: Colors.blueGrey[400],
                                    ),
                                ),
                              )
                            : Icon(
                                Icons.group, 
                                size: ResponsiveConfig.dimension(context, 24), 
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
                              baseFontSize: 16,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            ResponsiveSpacing(multiplier: 0.5),
                            ResponsiveText(
                              '${teamPlayers.length} players coached',
                              baseFontSize: 14,
                              style: TextStyle(color: Colors.blueGrey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Arrow
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
      ],
    );
  }
  
  Widget _buildPlayersTab(bool canAssignPlayers, DeviceType deviceType) {
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
                canAssignPlayers
                    ? 'Assign players to this coach to start tracking their performance'
                    : 'No players have been assigned to this coach yet',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
                textAlign: TextAlign.center,
              ),
              if (canAssignPlayers) ...[
                ResponsiveSpacing(multiplier: 3),
                ResponsiveButton(
                  text: 'Assign Player',
                  baseHeight: 48,
                  onPressed: _assignPlayerToCoach,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: Icons.person_add, // Fixed: removed Icon() wrapper
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    // Use the FilterablePlayerList widget
    return FilterablePlayerList(
      players: _players,
      onPlayerTap: _viewPlayerDetails,
      onPlayerEditTap: canAssignPlayers ? _editPlayer : null,
      showEditButton: canAssignPlayers,
      title: 'Coached Players',
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