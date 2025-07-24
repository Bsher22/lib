import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class AssignPlayerToCoachScreen extends StatefulWidget {
  final User coach;
  
  const AssignPlayerToCoachScreen({
    Key? key,
    required this.coach,
  }) : super(key: key);

  @override
  State<AssignPlayerToCoachScreen> createState() => _AssignPlayerToCoachScreenState();
}

class _AssignPlayerToCoachScreenState extends State<AssignPlayerToCoachScreen> {
  bool _isLoading = false;
  bool _isAssigning = false;
  String? _errorMessage;
  List<Player> _availablePlayers = [];
  List<Player> _filteredPlayers = [];
  List<Player> _selectedPlayers = [];
  List<Team> _teams = [];
  String _searchQuery = '';
  int? _selectedTeamId;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Load all players
      final allPlayers = appState.players;
      
      // Filter out players already assigned to this coach
      final availablePlayers = allPlayers.where((p) => p.primaryCoachId != widget.coach.id).toList();
      
      // Get teams for filtering
      final teams = appState.teams;
      
      setState(() {
        _availablePlayers = availablePlayers;
        _filteredPlayers = List.from(availablePlayers);
        _teams = teams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading players: $e';
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    List<Player> result = List.from(_availablePlayers);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      result = result.where((player) => 
        player.name.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply team filter
    if (_selectedTeamId != null) {
      result = result.where((player) => player.teamId == _selectedTeamId).toList();
    }
    
    setState(() {
      _filteredPlayers = result;
    });
  }
  
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }
  
  void _onTeamFilterChanged(int? teamId) {
    setState(() {
      _selectedTeamId = teamId;
    });
    _applyFilters();
  }
  
  void _togglePlayerSelection(Player player) {
    setState(() {
      if (_selectedPlayers.any((p) => p.id == player.id)) {
        _selectedPlayers.removeWhere((p) => p.id == player.id);
      } else {
        _selectedPlayers.add(player);
      }
    });
  }
  
  Future<void> _assignPlayers() async {
    if (_selectedPlayers.isEmpty) {
      // Show warning using DialogService
      await DialogService.showInformation(
        context,
        title: 'No Players Selected',
        message: 'Please select at least one player',
      );
      return;
    }
    
    // Show confirmation dialog using DialogService
    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Assign Players to Coach?',
      message: 'This will assign ${_selectedPlayers.length} ${_selectedPlayers.length == 1 ? "player" : "players"} to ${widget.coach.name}.',
      confirmLabel: 'Assign',
      cancelLabel: 'Cancel',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isAssigning = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Update each selected player
      int successCount = 0;
      
      for (final player in _selectedPlayers) {
        if (player.id != null) {
          final playerData = {
            'primary_coach_id': widget.coach.id,
          };
          
          final success = await appState.updatePlayer(player.id!, playerData);
          if (success) {
            successCount++;
          }
        }
      }
      
      if (!mounted) return;
      
      if (successCount > 0) {
        // Show success message using DialogService
        await DialogService.showSuccess(
          context,
          title: 'Assignment Successful',
          message: 'Successfully assigned $successCount ${successCount == 1 ? "player" : "players"} to ${widget.coach.name}',
        );
        
        // Return to previous screen with success indicator
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to assign players to coach';
          _isAssigning = false;
        });
        
        // Show error message using DialogService
        await DialogService.showError(
          context,
          title: 'Assignment Failed',
          message: _errorMessage!,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error assigning players: $e';
        _isAssigning = false;
      });
      
      // Show error message using DialogService
      await DialogService.showError(
        context,
        title: 'Error',
        message: _errorMessage!,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Assign Players to ${widget.coach.name}',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return LoadingOverlay(
            isLoading: _isLoading,
            message: 'Loading players...',
            color: Colors.cyanAccent,
            child: _errorMessage != null
                ? ErrorDisplay(
                    message: 'Error Loading Players',
                    details: _errorMessage,
                    onRetry: _loadData,
                  )
                : _buildContent(deviceType, isLandscape),
          );
        },
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }
  
  Widget _buildContent(DeviceType deviceType, bool isLandscape) {
    if (_availablePlayers.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Available Players',
        description: 'All players are already assigned to this coach',
        icon: Icons.people,
        animate: true,
        showCard: true,
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search and filters
        _buildFiltersSection(deviceType, isLandscape),
        
        // Player list
        Expanded(
          child: _filteredPlayers.isEmpty
              ? Center(
                  child: ResponsiveText(
                    'No players match the current filters',
                    baseFontSize: 16,
                    style: TextStyle(color: Colors.blueGrey[400]),
                  ),
                )
              : ListView.builder(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16),
                  itemCount: _filteredPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _filteredPlayers[index];
                    final isSelected = _selectedPlayers.any((p) => p.id == player.id);
                    
                    return _buildPlayerCheckableItem(player, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(DeviceType deviceType, bool isLandscape) {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 800 : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coach info card
            _buildCoachInfoCard(),
            
            ResponsiveSpacing(multiplier: 2),
            
            // Search field
            StandardTextField(
              hintText: 'Search players',
              prefixIcon: Icons.search,
              suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                      });
                      _applyFilters();
                    },
                  )
                : null,
              onChanged: _onSearchChanged,
            ),
            
            ResponsiveSpacing(multiplier: 2),
            
            // Team filter
            if (_teams.isNotEmpty)
              StandardDropdown<int?>(
                value: _selectedTeamId,
                labelText: 'Filter by Team',
                prefixIcon: Icons.group,
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: const Text('All Teams'),
                  ),
                  ..._teams.map((team) => DropdownMenuItem<int?>(
                    value: team.id,
                    child: Text(team.name),
                  )).toList(),
                ],
                onChanged: _onTeamFilterChanged,
              ),
            
            ResponsiveSpacing(multiplier: 2),
            
            // Selection info
            AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                if (deviceType == DeviceType.mobile && !isLandscape) {
                  // Mobile Portrait: Stack vertically
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ResponsiveText(
                        'Available Players (${_filteredPlayers.length})',
                        baseFontSize: 16,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      if (_selectedPlayers.isNotEmpty) ...[
                        ResponsiveSpacing(multiplier: 1),
                        StatusBadge(
                          text: '${_selectedPlayers.length} selected',
                          color: Colors.blue[700]!,
                          size: StatusBadgeSize.small,
                          shape: StatusBadgeShape.pill,
                        ),
                      ],
                    ],
                  );
                } else {
                  // Tablet/Desktop: Side by side
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ResponsiveText(
                        'Available Players (${_filteredPlayers.length})',
                        baseFontSize: 16,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                      if (_selectedPlayers.isNotEmpty)
                        StatusBadge(
                          text: '${_selectedPlayers.length} selected',
                          color: Colors.blue[700]!,
                          size: StatusBadgeSize.small,
                          shape: StatusBadgeShape.pill,
                        ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachInfoCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveConfig.dimension(context, 24),
            backgroundColor: Colors.green[100],
            child: ResponsiveText(
              widget.coach.name.isNotEmpty 
                  ? widget.coach.name[0].toUpperCase() 
                  : '?',
              baseFontSize: 20,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  widget.coach.name,
                  baseFontSize: 16,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                ResponsiveText(
                  widget.coach.email,
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
          StatusBadge(
            text: 'Coach',
            color: Colors.green[700]!,
            size: StatusBadgeSize.small,
            shape: StatusBadgeShape.pill,
            icon: Icons.sports,
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCheckableItem(Player player, bool isSelected) {
    // Find team for this player
    final team = player.teamId != null 
        ? _teams.firstWhereOrNull((t) => t.id == player.teamId) 
        : null;
    
    return ListItemWithActions(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      padding: ResponsiveConfig.paddingAll(context, 12),
      borderRadius: ResponsiveConfig.borderRadius(context, 12),
      backgroundColor: isSelected ? Colors.blue[50] : null,
      onTap: () => _togglePlayerSelection(player),
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: isSelected,
            onChanged: (_) => _togglePlayerSelection(player),
            activeColor: Colors.blue,
          ),
          CircleAvatar(
            radius: ResponsiveConfig.dimension(context, 20),
            backgroundColor: Colors.blueGrey[200],
            child: ResponsiveText(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      title: player.name,
      subtitle: player.position,
      subtitle2: team != null ? 'Team: ${team.name}' : null,
      actions: player.coordinatorName != null
          ? [
              StatusBadge(
                text: 'Coordinator: ${player.coordinatorName}',
                color: Colors.blue[700]!,
                size: StatusBadgeSize.small,
              ),
            ]
          : null,
    );
  }
  
  Widget _buildBottomBar() {
    return Container(
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            if (deviceType == DeviceType.mobile && !isLandscape) {
              // Mobile Portrait: Stack vertically for better space usage
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatusBadge(
                    text: '${_selectedPlayers.length} selected',
                    color: Colors.blue[700]!,
                    size: StatusBadgeSize.medium,
                    shape: StatusBadgeShape.pill,
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  SizedBox(
                    width: double.infinity,
                    child: _buildAssignButton(),
                  ),
                ],
              );
            } else {
              // Tablet/Desktop: Side by side
              return Row(
                children: [
                  StatusBadge(
                    text: '${_selectedPlayers.length} selected',
                    color: Colors.blue[700]!,
                    size: StatusBadgeSize.medium,
                    shape: StatusBadgeShape.pill,
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(child: _buildAssignButton()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildAssignButton() {
    return ResponsiveButton(
      text: _isAssigning ? 'Assigning Players...' : 'Assign to ${widget.coach.name}',
      onPressed: _selectedPlayers.isEmpty || _isAssigning ? null : _assignPlayers,
      baseHeight: 48,
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black87,
      disabledBackgroundColor: Colors.blueGrey[100],
      // Remove loadingText parameter - handle loading state with text instead
    );
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