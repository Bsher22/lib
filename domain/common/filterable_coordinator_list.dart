// lib/widgets/domain/common/filterable_coordinator_list.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';

class FilterableCoordinatorList extends StatefulWidget {
  final List<User> coordinators;
  final void Function(User coordinator)? onCoordinatorTap;
  final void Function(User coordinator)? onCoordinatorEditTap;
  final bool showEditButton;
  final String emptyMessage;
  final String title;
  
  const FilterableCoordinatorList({
    Key? key,
    required this.coordinators,
    this.onCoordinatorTap,
    this.onCoordinatorEditTap,
    this.showEditButton = true,
    this.emptyMessage = 'No coordinators found',
    this.title = 'Coordinators',
  }) : super(key: key);

  @override
  State<FilterableCoordinatorList> createState() => _FilterableCoordinatorListState();
}

class _FilterableCoordinatorListState extends State<FilterableCoordinatorList> {
  List<User> _filteredCoordinators = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  
  // Filters
  List<String> _selectedTeamIds = [];
  
  // Cached data for each coordinator
  Map<int, List<Player>> _coordinatorPlayers = {};
  Map<int, List<Team>> _coordinatorTeams = {};
  Map<int, List<User>> _coordinatorCoaches = {};
  
  @override
  void initState() {
    super.initState();
    _filteredCoordinators = List.from(widget.coordinators);
    _loadCoordinatorDetails();
  }
  
  @override
  void didUpdateWidget(FilterableCoordinatorList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.coordinators != widget.coordinators) {
      _loadCoordinatorDetails();
      _applyFilters();
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Load player, team, and coach information for each coordinator
  Future<void> _loadCoordinatorDetails() async {
    final appState = Provider.of<AppState>(context, listen: false);
    final allPlayers = appState.players;
    final allCoaches = appState.coaches;
    
    _coordinatorPlayers.clear();
    _coordinatorTeams.clear();
    _coordinatorCoaches.clear();
    
    for (final coordinator in widget.coordinators) {
      if (coordinator.id == null) continue;
      
      // Get players coordinated by this coordinator
      final players = allPlayers.where((p) => p.coordinatorId == coordinator.id).toList();
      _coordinatorPlayers[coordinator.id!] = players;
      
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
      
      _coordinatorTeams[coordinator.id!] = teams;
      
      // Get coaches for this coordinator's players
      final coachIds = <int>{};
      for (final player in players) {
        if (player.primaryCoachId != null) {
          coachIds.add(player.primaryCoachId!);
        }
      }
      
      // Get coach objects
      final coaches = <User>[];
      for (final coachId in coachIds) {
        final coach = allCoaches.firstWhere(
          (c) => c.id == coachId,
          orElse: () => User(
            id: coachId,
            username: 'unknown',
            name: 'Unknown Coach',
            email: 'unknown@example.com',
            role: 'coach',
          ),
        );
        coaches.add(coach);
      }
      
      _coordinatorCoaches[coordinator.id!] = coaches;
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
  
  void _clearAllFilters() {
    setState(() {
      _selectedTeamIds = [];
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }
  
  void _applyFilters() {
    List<User> result = List.from(widget.coordinators);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((coordinator) => 
        coordinator.name.toLowerCase().contains(_searchQuery) ||
        coordinator.email.toLowerCase().contains(_searchQuery)
      ).toList();
    }
    
    // Apply team filter
    if (_selectedTeamIds.isNotEmpty) {
      result = result.where((coordinator) {
        if (coordinator.id == null) return false;
        
        final teams = _coordinatorTeams[coordinator.id!] ?? [];
        return teams.any((team) => 
          _selectedTeamIds.contains(team.id.toString())
        );
      }).toList();
    }
    
    setState(() {
      _filteredCoordinators = result;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;
    
    final bool showTeamFilter = teams.isNotEmpty;
    
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
                '(${_filteredCoordinators.length})',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey[600],
                ),
              ),
              const Spacer(),
              if (_selectedTeamIds.isNotEmpty || _searchQuery.isNotEmpty)
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
              hintText: 'Search coordinators',
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
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Coordinator list
        Expanded(
          child: _filteredCoordinators.isEmpty
            ? EmptyStateDisplay(
                title: widget.emptyMessage,
                icon: Icons.people,
                iconColor: Colors.blueGrey[300],
              )
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _filteredCoordinators.length,
                itemBuilder: (context, index) {
                  final coordinator = _filteredCoordinators[index];
                  return _buildCoordinatorItem(context, coordinator);
                },
              ),
        ),
      ],
    );
  }
  
  Widget _buildCoordinatorItem(BuildContext context, User coordinator) {
    // Get teams, players and coaches for this coordinator
    final teams = coordinator.id != null ? _coordinatorTeams[coordinator.id!] ?? [] : [];
    final players = coordinator.id != null ? _coordinatorPlayers[coordinator.id!] ?? [] : [];
    final coaches = coordinator.id != null ? _coordinatorCoaches[coordinator.id!] ?? [] : [];
    
    // Create stats string for subtitle
    final subtitle = '${players.length} ${players.length == 1 ? 'player' : 'players'} • '
                    '${teams.length} ${teams.length == 1 ? 'team' : 'teams'} • '
                    '${coaches.length} ${coaches.length == 1 ? 'coach' : 'coaches'}';
    
    // Create actions
    final actions = widget.showEditButton && widget.onCoordinatorEditTap != null
        ? ListItemWithActions.createCommonActions(
            onEdit: () => widget.onCoordinatorEditTap!(coordinator),
            onView: widget.onCoordinatorTap != null ? () => widget.onCoordinatorTap!(coordinator) : null,
          )
        : null;
    
    // Role badge
    final roleBadge = StatusBadge.fromStatus(
      'coordinator', 
      size: StatusBadgeSize.small,
      shape: StatusBadgeShape.pill,
    );
    
    // Use StandardCard with ListItemWithActions
    return StandardCard(
      margin: const EdgeInsets.only(bottom: 12),
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      onTap: widget.onCoordinatorTap != null ? () => widget.onCoordinatorTap!(coordinator) : null,
      child: ListItemWithActions(
        title: coordinator.name,
        subtitle: coordinator.email,
        subtitle2: subtitle,
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue[200],
          child: Text(
            coordinator.name.isNotEmpty ? coordinator.name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: actions,
        onTap: widget.onCoordinatorTap != null ? () => widget.onCoordinatorTap!(coordinator) : null,
      ),
    );
  }
}