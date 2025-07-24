import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:provider/provider.dart';

class PlayerListScreen extends StatefulWidget {
  const PlayerListScreen({Key? key}) : super(key: key);

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }
  
  Future<void> _loadPlayers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadInitialData();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading players: $e';
          _isLoading = false;
        });
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
      if (result == true) {
        _loadPlayers();
      }
    });
  }
  
  void _addNewPlayer() {
    Navigator.pushNamed(context, '/player-registration').then((result) {
      if (result == true) {
        _loadPlayers();
      }
    });
  }
  
  void _assignPlayer(Player player) {
    Navigator.pushNamed(
      context,
      '/assign-player-detail',
      arguments: player,
    ).then((result) {
      if (result == true) {
        _loadPlayers();
      }
    });
  }
  
  void _viewPlayerStats(Player player) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedPlayer(player.name);
    Navigator.pushNamed(context, '/analytics');
  }
  
  void _deletePlayer(Player player) async {
    // Use DialogService for delete confirmation
    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Delete Player',
      message: 'Are you sure you want to delete ${player.name}? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    
    if (confirmed != true) return;
    
    // Show loading dialog
    DialogService.showLoading(
      context,
      message: 'Deleting player...',
      color: Colors.red[700],
    );
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final success = await appState.deletePlayer(player.id!);
      
      // Dismiss loading dialog
      DialogService.hideLoading(context);
      
      if (success) {
        // Show success message
        await DialogService.showSuccess(
          context,
          title: 'Player Deleted',
          message: '${player.name} has been deleted successfully',
        );
        
        // Reload the player list
        _loadPlayers();
      } else {
        // Show error message
        await DialogService.showError(
          context,
          title: 'Deletion Failed',
          message: 'Failed to delete player. Please try again.',
        );
      }
    } catch (e) {
      // Dismiss loading dialog if still showing
      DialogService.hideLoading(context);
      
      // Show error message
      await DialogService.showError(
        context,
        title: 'Error',
        message: 'Error deleting player: $e',
      );
    }
  }
  
  void _exportPlayerData() async {
    // Use DialogService to get export format selection
    final exportFormat = await DialogService.showSelection<String>(
      context,
      title: 'Export Players',
      message: 'Choose export format:',
      options: ['CSV', 'PDF', 'Excel'],
      itemBuilder: (context, format) {
        IconData icon;
        switch (format) {
          case 'CSV':
            icon = Icons.insert_drive_file;
            break;
          case 'PDF':
            icon = Icons.picture_as_pdf;
            break;
          case 'Excel':
            icon = Icons.table_chart;
            break;
          default:
            icon = Icons.file_present;
        }
        
        return Row(
          children: [
            Icon(icon),
            const SizedBox(width: 16),
            Text(format),
          ],
        );
      },
    );
    
    if (exportFormat == null) return;
    
    // Show loading dialog
    DialogService.showLoading(
      context,
      message: 'Preparing export...',
    );
    
    try {
      // Simulate export process
      await Future.delayed(const Duration(seconds: 2));
      
      // Dismiss loading dialog
      DialogService.hideLoading(context);
      
      // Show success message
      await DialogService.showSuccess(
        context,
        title: 'Export Complete',
        message: 'Player data exported successfully as $exportFormat.',
      );
    } catch (e) {
      // Dismiss loading dialog
      DialogService.hideLoading(context);
      
      // Show error message
      await DialogService.showError(
        context,
        title: 'Export Failed',
        message: 'Error exporting player data: $e',
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    final players = appState.players;
    
    // Role-based permissions
    final canAddPlayer = userRole == 'admin' || userRole == 'director' || userRole == 'coordinator';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Players',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Open search or filter panel
              // This is already handled in the FilterablePlayerList
            },
            tooltip: 'Search',
          ),
          
          // Export button
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportPlayerData,
            tooltip: 'Export',
          ),
          
          // More options
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  // Open filter panel
                  break;
                case 'export':
                  _exportPlayerData();
                  break;
                case 'sort':
                  // Sort players
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter',
                child: ListTile(
                  leading: Icon(Icons.filter_list),
                  title: Text('Filter'),
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_download),
                  title: Text('Export'),
                ),
              ),
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Sort'),
                ),
              ),
            ],
          ),
        ],
      ),
      // Using LoadingOverlay widget
      body: LoadingOverlay(
        isLoading: _isLoading,
        color: Colors.cyanAccent,
        fullScreen: true,
        child: _errorMessage != null
            ? ErrorDisplay(
                message: 'Error Loading Players',
                details: _errorMessage,
                onRetry: _loadPlayers,
              )
            : players.isEmpty
                ? EmptyStateDisplay(
                    title: 'No Players Available',
                    description: canAddPlayer
                        ? 'Add players to start tracking their performance'
                        : 'No players have been assigned to you yet',
                    icon: Icons.people,
                    primaryActionLabel: canAddPlayer ? 'Add Player' : null,
                    onPrimaryAction: canAddPlayer ? _addNewPlayer : null,
                  )
                : _buildPlayerList(players),
      ),
      floatingActionButton: canAddPlayer
          ? FloatingActionButton(
              onPressed: _addNewPlayer,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.person_add),
              tooltip: 'Add Player',
            )
          : null,
    );
  }
  
  Widget _buildPlayerList(List<Player> players) {
    // Use ListView.builder directly with ListItemWithActions
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        return _buildPlayerListItem(player);
      },
    );
  }
  
  Widget _buildPlayerListItem(Player player) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userRole = appState.getCurrentUserRole() ?? '';
    
    // Determine if the current user can edit this player
    final canEdit = userRole == 'admin' || 
                    userRole == 'director' || 
                    (userRole == 'coordinator' && player.coordinatorId == appState.currentUser?['id']) ||
                    (userRole == 'coach' && player.primaryCoachId == appState.currentUser?['id']);
    
    // Look up team info if showing team
    final team = player.teamId != null 
        ? appState.teams.firstWhereOrNull(
            (t) => t.id == player.teamId, 
            orElse: () => null,
          ) 
        : null;
    
    // Build the actions for this player
    final actions = <Widget>[];
    
    // Add status badge
    actions.add(
      StatusBadge.success(
        text: 'Active',
        size: StatusBadgeSize.small,
      ),
    );
    
    // Add action buttons
    if (canEdit) {
      actions.add(
        ListItemWithActions.createIconAction(
          icon: Icons.bar_chart,
          tooltip: 'View Stats',
          onPressed: () => _viewPlayerStats(player),
        ),
      );
      
      actions.add(
        ListItemWithActions.createIconAction(
          icon: Icons.edit,
          tooltip: 'Edit Player',
          onPressed: () => _editPlayer(player),
        ),
      );
      
      actions.add(
        ListItemWithActions.createIconAction(
          icon: Icons.assignment_ind,
          tooltip: 'Assign Player',
          onPressed: () => _assignPlayer(player),
        ),
      );
    }
    
    // Create the subtitles
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
    
    if (player.coordinatorName != null) {
      subtitle2 = subtitle2 != null 
          ? "$subtitle2 • Coordinator: ${player.coordinatorName}"
          : "Coordinator: ${player.coordinatorName}";
    }
    
    // Build context menu actions
    final contextMenuActions = <PopupMenuItem<String>>[
      PopupMenuItem(
        value: 'view',
        child: ListTile(
          leading: Icon(Icons.visibility, color: Colors.blueGrey[700]),
          title: const Text('View Details'),
        ),
      ),
      if (canEdit) ...[
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit, color: Colors.blueGrey[700]),
            title: const Text('Edit Player'),
          ),
        ),
        PopupMenuItem(
          value: 'assign',
          child: ListTile(
            leading: Icon(Icons.assignment_ind, color: Colors.blueGrey[700]),
            title: const Text('Assign Player'),
          ),
        ),
        PopupMenuItem(
          value: 'stats',
          child: ListTile(
            leading: Icon(Icons.bar_chart, color: Colors.blueGrey[700]),
            title: const Text('View Stats'),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(Icons.delete, color: Colors.red[700]),
            title: const Text('Delete Player'),
          ),
        ),
      ],
    ];
    
    // Use ListItemWithActions for the player list item with context menu
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: PopupMenuButton<String>(
        onSelected: (value) {
          switch (value) {
            case 'view':
              _viewPlayerDetails(player);
              break;
            case 'edit':
              _editPlayer(player);
              break;
            case 'assign':
              _assignPlayer(player);
              break;
            case 'stats':
              _viewPlayerStats(player);
              break;
            case 'delete':
              _deletePlayer(player);
              break;
          }
        },
        itemBuilder: (context) => contextMenuActions,
        child: ListItemWithActions(
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
          onTap: () => _viewPlayerDetails(player),
          padding: const EdgeInsets.all(12),
          borderRadius: 12,
          showDivider: false,
        ),
      ),
    );
  }
}

// Extension method for firstWhereOrNull
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test, {E Function()? orElse}) {
    for (var element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) {
      return orElse();
    }
    return null;
  }
}