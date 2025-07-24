import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/filters/filter_panel.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:provider/provider.dart';

class FilterablePlayerList extends StatefulWidget {
  final List<Player> players;
  final void Function(Player player)? onPlayerTap;
  final void Function(Player player)? onPlayerEditTap;
  final bool showEditButton;
  final String emptyMessage;
  final String title;

  const FilterablePlayerList({
    Key? key,
    required this.players,
    this.onPlayerTap,
    this.onPlayerEditTap,
    this.showEditButton = true,
    this.emptyMessage = 'No players found',
    this.title = 'Players',
  }) : super(key: key);

  @override
  State<FilterablePlayerList> createState() => _FilterablePlayerListState();
}

class _FilterablePlayerListState extends State<FilterablePlayerList> {
  List<Player> _filteredPlayers = [];
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  // Filters
  List<String> _selectedTeamIds = [];
  List<String> _selectedCoachIds = [];
  List<String> _selectedCoordinatorIds = [];

  @override
  void initState() {
    super.initState();
    _filteredPlayers = List.from(widget.players);
  }

  @override
  void didUpdateWidget(FilterablePlayerList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.players != widget.players) {
      _applyFilters();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  void _onCoachFilterChanged(List<String> selectedIds) {
    setState(() {
      _selectedCoachIds = selectedIds;
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
      _selectedCoachIds = [];
      _selectedCoordinatorIds = [];
      _searchQuery = '';
      _searchController.clear();
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Player> result = List.from(widget.players);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((player) =>
          player.name.toLowerCase().contains(_searchQuery)
      ).toList();
    }

    // Apply team filter
    if (_selectedTeamIds.isNotEmpty) {
      result = result.where((player) =>
          player.teamId != null && _selectedTeamIds.contains(player.teamId.toString())
      ).toList();
    }

    // Apply coach filter
    if (_selectedCoachIds.isNotEmpty) {
      result = result.where((player) =>
          player.primaryCoachId != null &&
          _selectedCoachIds.contains(player.primaryCoachId.toString())
      ).toList();
    }

    // Apply coordinator filter
    if (_selectedCoordinatorIds.isNotEmpty) {
      result = result.where((player) =>
          player.coordinatorId != null &&
          _selectedCoordinatorIds.contains(player.coordinatorId.toString())
      ).toList();
    }

    setState(() {
      _filteredPlayers = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final teams = appState.teams;
    final coaches = appState.coaches;
    final coordinators = appState.coordinators;
    final userRole = appState.getCurrentUserRole();

    // Determine which filters to show based on role
    final bool showTeamFilter = userRole != 'coach';
    final bool showCoachFilter = userRole != 'coach';
    final bool showCoordinatorFilter = userRole == 'admin' || userRole == 'director';

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
                '(${_filteredPlayers.length})',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.blueGrey[600],
                ),
              ),
              const Spacer(),
              if (_selectedTeamIds.isNotEmpty ||
                  _selectedCoachIds.isNotEmpty ||
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
              hintText: 'Search players',
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

        // Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              // Team filter
              if (showTeamFilter && teams.isNotEmpty)
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

              // Coach filter
              if (showCoachFilter && coaches.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.sports, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by Coach',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blueGrey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilterChipGroup<String>(
                      options: coaches.map((coach) => coach.id.toString()).toList(),
                      selectedOptions: _selectedCoachIds,
                      onSelected: (coachId, selected) {
                        List<String> updatedIds = List.from(_selectedCoachIds);
                        if (selected) {
                          updatedIds.add(coachId);
                        } else {
                          updatedIds.remove(coachId);
                        }
                        _onCoachFilterChanged(updatedIds);
                      },
                      labelBuilder: (coachId) {
                        final coach = coaches.firstWhere((c) => c.id.toString() == coachId,
                            orElse: () => User(name: 'Unknown', email: '', username: '', role: 'coach'));
                        return coach.name;
                      },
                      selectedColor: Colors.cyanAccent,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),

              // Coordinator filter
              if (showCoordinatorFilter && coordinators.isNotEmpty)
                FilterPanel(
                  title: 'Filter by Coordinator',
                  leading: const Icon(Icons.people_alt, size: 20),
                  options: coordinators.map((coordinator) => FilterOption(
                    id: coordinator.id.toString(),
                    label: coordinator.name,
                    isSelected: _selectedCoordinatorIds.contains(coordinator.id.toString()),
                  )).toList(),
                  onFilterChanged: _onCoordinatorFilterChanged,
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Player list
        Expanded(
          child: _filteredPlayers.isEmpty
              ? EmptyStateDisplay(
                  title: widget.emptyMessage,
                  icon: Icons.person_off,
                  iconColor: Colors.blueGrey[300],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _filteredPlayers[index];
                    return _buildPlayerCard(context, player);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(BuildContext context, Player player) {
    final appState = Provider.of<AppState>(context, listen: false);
    final team = player.teamId != null
        ? appState.teams.firstWhere(
            (t) => t.id == player.teamId,
            orElse: () => Team(name: 'Unknown Team')
          )
        : null;

    // Build actions list
    final actions = <Widget>[];

    // Add status badge
    actions.add(
      StatusBadge.success(
        text: 'Active',
        size: StatusBadgeSize.small,
      ),
    );

    // Add edit button if needed
    if (widget.showEditButton && widget.onPlayerEditTap != null) {
      actions.add(
        ListItemWithActions.createIconAction(
          icon: Icons.edit,
          tooltip: 'Edit Player',
          onPressed: () => widget.onPlayerEditTap!(player),
        ),
      );
    }

    // Build subtitles
    String? subtitle = player.position;
    String? subtitle2;

    if (team != null) {
      subtitle2 = "Team: ${team.name}";
    }

    if (player.primaryCoachName != null) {
      subtitle2 = subtitle2 != null
          ? "$subtitle2 • Coach: ${player.primaryCoachName}"
          : "Coach: ${player.primaryCoachName}";
    }

    // Use ListItemWithActions
    return ListItemWithActions(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blueGrey[300],
        child: Text(
          player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      title: player.name,
      subtitle: subtitle,
      subtitle2: subtitle2,
      actions: actions,
      onTap: widget.onPlayerTap != null ? () => widget.onPlayerTap!(player) : null,
      showDivider: true,
      margin: const EdgeInsets.only(bottom: 8),
    );
  }
}