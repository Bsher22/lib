// lib/widgets/domain/common/filterable_coach_list.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';

class FilterableCoachList extends StatefulWidget {
  final List<User> coaches;
  final void Function(User coach)? onCoachTap;
  final void Function(User coach)? onCoachEditTap;
  final bool showEditButton;
  final String emptyMessage;
  final String title;
  
  const FilterableCoachList({
    Key? key,
    required this.coaches,
    this.onCoachTap,
    this.onCoachEditTap,
    this.showEditButton = true,
    this.emptyMessage = 'No coaches found',
    this.title = 'Coaches',
  }) : super(key: key);

  @override
  State<FilterableCoachList> createState() => _FilterableCoachListState();
}

class _FilterableCoachListState extends State<FilterableCoachList> {
  List<User> _filteredCoaches = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  
  // Filters
  List<String> _selectedTeamIds = [];
  List<String> _selectedCoordinatorIds = [];
  
  // Cached data for each coach
  Map<int, List<Player>> _coachPlayers = {};
  Map<int, List<Team>> _coachTeams = {};
  
  @override
  void initState() {
    super.initState();
    _filteredCoaches = List.from(widget.coaches);
    _loadCoachDetails();
  }
  
  @override
  void didUpdateWidget(FilterableCoachList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coaches != widget.coaches) {
      _loadCoachDetails();
      _applyFilters();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load player and team information for each coach
  Future<void> _loadCoachDetails() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final allPlayers = appState.players;
    
    _coachPlayers.clear();
    _coachTeams.clear();
    
    for (final coach in widget.coaches) {
      if (coach.id == null) continue;
      
      // Get players coached by this coach
      final players = allPlayers.where((p) => p.primaryCoachId == coach.id).toList();
      _coachPlayers[coach.id!] = players;
      
      // Get unique teams these players belong to
      final teamIds = <int>{};
      for (final player in players) {
        if (player.teamId != null) {
          teamIds.add(player.teamId!);
        }
      }
      
      // Get team objects
      final teams = <Team>[];
      for (final teamId in teamIds) {
        final team = appState.teams.firstWhere(
          (t) => t.id == teamId,
          orElse: () => Team(name: 'Unknown Team', id: teamId),
        );
        teams.add(team);
      }
      
      _coachTeams[coach.id!] = teams;
    }
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }
  
  void _onTeamFilterChanged(List<String> selectedIds) {
    setState(() {
      _selectedTeamIds = selectedIds;
      _applyFilters();
    });
  }
  
  void _onCoordinatorFilterChanged(List<String> selectedIds) {
    setState(() {
      _selectedCoordinatorIds = selectedIds;
      _applyFilters();
    });
  }
  
  void _clearAllFilters() {
    setState(() {
      _selectedTeamIds = [];
      _selectedCoordinatorIds = [];
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    List<User> result = List.from(widget.coaches);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((coach) => 
        coach.name.toLowerCase().contains(_searchQuery) ||
        coach.email.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    // Apply team filter
    if (_selectedTeamIds.isNotEmpty) {
      result = result.where((coach) {
        if (coach.id == null) return false;
        
        final teams = _coachTeams[coach.id!] ?? [];
        return teams.any((team) => 
          _selectedTeamIds.contains(team.id.toString())
        );
      }).toList();
    }
    
    // Apply coordinator filter
    if (_selectedCoordinatorIds.isNotEmpty) {
      final appState = Provider.of<AppState>(context, listen: false);
      final allPlayers = appState.players;
      
      result = result.where((coach) {
        if (coach.id == null) return false;
        
        // Find players coached by this coach
        final coachPlayers = allPlayers.where((p) => p.primaryCoachId == coach.id);
        
        // Check if any of those players have a coordinator from the selected list
        return coachPlayers.any((player) => 
          player.coordinatorId != null && 
          _selectedCoordinatorIds.contains(player.coordinatorId.toString())
        );
      }).toList();
    }
    
    setState(() {
      _filteredCoaches = result;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;
    final coordinators = appState.coordinators;
    final userRole = appState.getCurrentUserRole();
    
    // Determine which filters to show based on role
    final bool showTeamFilter = teams.isNotEmpty;
    final bool showCoordinatorFilter = (userRole == 'admin' || userRole == 'director') && 
                                       coordinators.isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${_filteredCoaches.length})',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey[600],
                ),
              ),
              const Spacer(),
              if (_selectedTeamIds.isNotEmpty ||
                 _selectedCoordinatorIds.isNotEmpty ||
                 _searchQuery.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAllFilters,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blueGrey[700],
                  ),
                ),
            ],
          ),
        ),
        
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search coaches',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ),
        
        // Filters using FilterChipGroup
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Team filter
              if (showTeamFilter)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.group, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by Team',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilterChipGroup<String>(
                      options: teams.map((team) => team.id.toString()).toList(),
                      selectedOptions: _selectedTeamIds,
                      onSelected: (teamId, selected) {
                        List<String> updatedIds = List.from(_selectedTeamIds);
                        if (selected) {
                          updatedIds.add(teamId);
                        } else {
                          updatedIds.remove(teamId);
                        }
                        _onTeamFilterChanged(updatedIds);
                      },
                      labelBuilder: (teamId) {
                        final team = teams.firstWhere((t) => t.id.toString() == teamId, 
                          orElse: () => Team(name: 'Unknown'));
                        return team.name;
                      },
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                
              // Coordinator filter
              if (showCoordinatorFilter)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by Coordinator',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilterChipGroup<String>(
                      options: coordinators.map((coordinator) => coordinator.id.toString()).toList(),
                      selectedOptions: _selectedCoordinatorIds,
                      onSelected: (coordinatorId, selected) {
                        List<String> updatedIds = List.from(_selectedCoordinatorIds);
                        if (selected) {
                          updatedIds.add(coordinatorId);
                        } else {
                          updatedIds.remove(coordinatorId);
                        }
                        _onCoordinatorFilterChanged(updatedIds);
                      },
                      labelBuilder: (coordinatorId) {
                        final coordinator = coordinators.firstWhere(
                          (c) => c.id.toString() == coordinatorId, 
                          orElse: () => User(name: 'Unknown', email: '', username: '', role: 'coordinator')
                        );
                        return coordinator.name;
                      },
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Coach list
        Expanded(
          child: _filteredCoaches.isEmpty
            ? EmptyStateDisplay(
                title: widget.emptyMessage,
                icon: Icons.sports,
                iconColor: Colors.blueGrey[300],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredCoaches.length,
                itemBuilder: (context, index) {
                  final coach = _filteredCoaches[index];
                  return _buildCoachItem(context, coach);
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildCoachItem(BuildContext context, User coach) {
    // Get teams and players for this coach
    final teams = coach.id != null ? _coachTeams[coach.id!] ?? [] : [];
    final players = coach.id != null ? _coachPlayers[coach.id!] ?? [] : [];
    
    // Create subtitle with team and player counts
    final subtitle = '${players.length} ${players.length == 1 ? 'player' : 'players'} • '
                     '${teams.length} ${teams.length == 1 ? 'team' : 'teams'}';
    
    // Create actions
    final actions = widget.showEditButton && widget.onCoachEditTap != null
        ? ListItemWithActions.createCommonActions(
            onEdit: () => widget.onCoachEditTap!(coach),
            onView: widget.onCoachTap != null ? () => widget.onCoachTap!(coach) : null,
          )
        : null;
    
    // Create role badge
    final roleBadge = StatusBadge.info(
      text: 'Coach',
      icon: Icons.sports,
      size: StatusBadgeSize.small,
    );
    
    // Use StandardCard to wrap the ListItemWithActions
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      onTap: widget.onCoachTap != null ? () => widget.onCoachTap!(coach) : null,
      child: ListItemWithActions(
        title: coach.name,
        subtitle: coach.email,
        subtitle2: subtitle,
        leading: CircleAvatar(
          backgroundColor: Colors.green[200],
          child: Text(
            coach.name.isNotEmpty ? coach.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: actions,
        onTap: widget.onCoachTap != null ? () => widget.onCoachTap!(coach) : null,
        leadingSpacing: 12,
      ),
    );
  }
}