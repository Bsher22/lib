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
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';

class AssignPlayerScreen extends StatefulWidget {
  const AssignPlayerScreen({super.key});

  @override
  State<AssignPlayerScreen> createState() => _AssignPlayerScreenState();
}

class _AssignPlayerScreenState extends State<AssignPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  Team? _team;
  List<Player> _availablePlayers = [];
  List<User> _coaches = [];

  Player? _selectedExistingPlayer;
  User? _selectedCoach;

  bool _isCreatingNew = false;
  bool _isLoading = false;
  bool _isLoadingPlayers = false;
  bool _isLoadingCoaches = false;
  String? _errorMessage;
  bool _assignSuccess = false;

  @override
  void initState() {
    super.initState();

    // Delay until the widget is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;

      if (args is Team) {
        setState(() {
          _team = args;
        });
        _loadAvailablePlayers();
        _loadCoaches();
      } else {
        setState(() {
          _errorMessage = 'No team selected';
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailablePlayers() async {
    setState(() {
      _isLoadingPlayers = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Get all players and filter out those already in the team
      final allPlayers = await appState.fetchPlayers();
      _availablePlayers = allPlayers.where((p) => p.teamId != _team!.id).toList();

      if (mounted) {
        setState(() {
          _isLoadingPlayers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading available players: $e';
          _isLoadingPlayers = false;
        });
      }
    }
  }

  Future<void> _loadCoaches() async {
    setState(() {
      _isLoadingCoaches = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      _coaches = await ApiServiceFactory.user.fetchUsersByRole('coach');

      if (mounted) {
        setState(() {
          _isLoadingCoaches = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading coaches: $e';
          _isLoadingCoaches = false;
        });
      }
    }
  }

  Future<void> _assignPlayer() async {
    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog using DialogService
    final confirmed = await DialogService.showConfirmation(
      context,
      title: _isCreatingNew ? 'Create & Assign Player?' : 'Assign Player?',
      message: _isCreatingNew
          ? 'This will create a new player and assign them to ${_team!.name}.'
          : 'This will assign ${_selectedExistingPlayer!.name} to ${_team!.name}.',
      confirmLabel: 'Proceed',
      cancelLabel: 'Cancel',
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _assignSuccess = false;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      if (_isCreatingNew) {
        // Create a new player and assign to team
        final playerData = {
          'name': _nameController.text.trim(),
          'team_id': _team!.id,
          'primary_coach_id': _selectedCoach?.id,
        };

        // Check if current user is a coordinator
        if (appState.isCoordinator()) {
          // Set current user as coordinator
          final currentUser = appState.getCurrentUser();
          if (currentUser != null && currentUser.containsKey('id')) {
            playerData['coordinator_id'] = currentUser['id'];
          }
        }

        final player = await appState.createPlayer(playerData);

        if (player != null) {
          setState(() {
            _assignSuccess = true;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to create player';
          });
        }
      } else if (_selectedExistingPlayer != null) {
        // Update existing player's team
        final playerData = {
          'team_id': _team!.id,
        };

        // Only update coach if one is selected
        if (_selectedCoach != null) {
          playerData['primary_coach_id'] = _selectedCoach!.id;
        }

        final success = await appState.updatePlayer(
          _selectedExistingPlayer!.id!,
          playerData,
        );

        if (success) {
          setState(() {
            _assignSuccess = true;
          });
        } else {
          setState(() {
            _errorMessage = 'Failed to assign player to team';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Please select a player or create a new one';
        });
      }

      // Complete the method with finalizing code
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (_assignSuccess) {
          // Show success message using DialogService
          await DialogService.showSuccess(
            context,
            title: 'Assignment Successful',
            message: _isCreatingNew
                ? 'Player created and assigned to team'
                : 'Player assigned to team successfully',
          );

          // Return success to previous screen
          Navigator.pop(context, true);
        } else if (_errorMessage != null) {
          // Show error message using DialogService
          await DialogService.showError(
            context,
            title: 'Error',
            message: _errorMessage!,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error assigning player: $e';
          _isLoading = false;
        });

        // Show error message using DialogService
        await DialogService.showError(
          context,
          title: 'Error',
          message: _errorMessage!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_team == null) {
      return AdaptiveScaffold(
        title: 'Assign Player',
        backgroundColor: Colors.grey[100],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return ErrorDisplay(
              message: 'No Team Selected',
              details: 'Please select a team first to assign players',
              onAlternativeAction: () => Navigator.pop(context),
              alternativeActionLabel: 'Go Back',
              showCard: true,
            );
          },
        ),
      );
    }

    return AdaptiveScaffold(
      title: 'Assign Player to ${_team!.name}',
      backgroundColor: Colors.grey[100],
      body: (_isLoadingPlayers || _isLoadingCoaches)
          ? AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                return LoadingOverlay.simple(
                  message: 'Loading data...',
                  color: Colors.cyanAccent,
                );
              },
            )
          : _errorMessage != null && !_isCreatingNew && _selectedExistingPlayer == null
              ? AdaptiveLayout(
                  builder: (deviceType, isLandscape) {
                    return ErrorDisplay(
                      message: 'Error Loading Data',
                      details: _errorMessage,
                      onRetry: () {
                        _loadAvailablePlayers();
                        _loadCoaches();
                      },
                      showCard: true,
                    );
                  },
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return LoadingOverlay(
          isLoading: _isLoading,
          message: _isCreatingNew
              ? 'Creating and assigning player...'
              : 'Assigning player to team...',
          color: Colors.cyanAccent,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 800 : null,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team card
                    _buildTeamCard(),
                    ResponsiveSpacing(multiplier: 2),

                    // Tab selection
                    _buildTabSelection(deviceType),
                    ResponsiveSpacing(multiplier: 3),

                    // Content based on selection
                    _isCreatingNew ? _buildNewPlayerForm() : _buildExistingPlayerSelection(),

                    // Error message
                    if (_errorMessage != null && !_isLoading) ...[
                      ResponsiveSpacing(multiplier: 2),
                      ResponsiveText(
                        _errorMessage!,
                        baseFontSize: 14,
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],

                    ResponsiveSpacing(multiplier: 3),

                    // Assign button
                    Center(
                      child: ResponsiveButton(
                        text: _isCreatingNew ? 'Create & Assign Player' : 'Assign Player to Team',
                        onPressed: _isLoading ? null : _assignPlayer,
                        baseHeight: 48,
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black87,
                        padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 32, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamCard() {
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      padding: ResponsiveConfig.paddingAll(context, 16),
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
            child: _team!.logoPath != null
                ? ClipRRect(
                    borderRadius: ResponsiveConfig.borderRadius(context, 8),
                    child: Image.network(
                      _team!.logoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.sports_hockey, size: ResponsiveConfig.iconSize(context, 32), color: Colors.blueGrey[400]),
                    ),
                  )
                : Icon(Icons.sports_hockey, size: ResponsiveConfig.iconSize(context, 32), color: Colors.blueGrey[400]),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          // Team details
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  _team!.name,
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                if (_team!.description != null && _team!.description!.isNotEmpty)
                  Padding(
                    padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
                    child: ResponsiveText(
                      _team!.description!,
                      baseFontSize: 14,
                      style: TextStyle(color: Colors.blueGrey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelection(DeviceType deviceType) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Row(
          children: [
            Expanded(
              child: ResponsiveButton(
                text: 'Existing Player',
                onPressed: () {
                  setState(() {
                    _isCreatingNew = false;
                    _nameController.clear();
                  });
                },
                baseHeight: 40,
                backgroundColor: !_isCreatingNew ? Colors.cyanAccent : Colors.grey[200],
                foregroundColor: !_isCreatingNew ? Colors.black87 : Colors.grey[700],
                // Use borderRadius double value instead of BorderRadius object
                borderRadius: 8.0, // Left side radius
                elevation: !_isCreatingNew ? 2 : 0,
              ),
            ),
            Expanded(
              child: ResponsiveButton(
                text: 'New Player',
                onPressed: () {
                  setState(() {
                    _isCreatingNew = true;
                    _selectedExistingPlayer = null;
                  });
                },
                baseHeight: 40,
                backgroundColor: _isCreatingNew ? Colors.cyanAccent : Colors.grey[200],
                foregroundColor: _isCreatingNew ? Colors.black87 : Colors.grey[700],
                // Use borderRadius double value instead of BorderRadius object
                borderRadius: 8.0, // Right side radius
                elevation: _isCreatingNew ? 2 : 0,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNewPlayerForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Create New Player',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),

        // Player name field
        StandardTextField(
          controller: _nameController,
          labelText: 'Player Name *',
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a player name';
            }
            return null;
          },
        ),
        ResponsiveSpacing(multiplier: 2),

        // Coach selection
        ResponsiveText(
          'Assign Coach (Optional)',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),

        // Coach dropdown
        if (_coaches.isEmpty)
          EmptyStateDisplay(
            title: 'No Coaches Available',
            description: 'No coaches have been added to the system yet.',
            icon: Icons.sports,
            iconSize: ResponsiveConfig.iconSize(context, 36),
            showCard: true,
          )
        else
          StandardDropdown<User?>(
            value: _selectedCoach,
            labelText: 'Select Coach',
            prefixIcon: Icons.sports,
            items: [
              DropdownMenuItem<User?>(
                value: null,
                child: const Text('No Coach'),
              ),
              ..._coaches.map((coach) => DropdownMenuItem<User?>(
                    value: coach,
                    child: Text(coach.name),
                  )).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCoach = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildExistingPlayerSelection() {
    if (_availablePlayers.isEmpty) {
      return EmptyStateDisplay(
        title: 'No Available Players',
        description: 'All players are already assigned to teams. Create a new player instead.',
        icon: Icons.people_alt,
        primaryActionLabel: 'Create New Player',
        onPrimaryAction: () {
          setState(() {
            _isCreatingNew = true;
          });
        },
        showCard: true,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Select Existing Player',
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),

        // Player selection
        Container(
          height: ResponsiveConfig.dimension(context, 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey[300]!),
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          child: ListView.builder(
            padding: ResponsiveConfig.paddingAll(context, 4),
            itemCount: _availablePlayers.length,
            itemBuilder: (context, index) {
              final player = _availablePlayers[index];
              final isSelected = _selectedExistingPlayer?.id == player.id;

              return ListItemWithActions(
                margin: ResponsiveConfig.paddingAll(context, 4),
                padding: ResponsiveConfig.paddingAll(context, 12),
                backgroundColor: isSelected ? Colors.cyanAccent.withOpacity(0.2) : null,
                border: isSelected
                    ? Border.all(color: Colors.cyanAccent, width: 2)
                    : Border.all(color: Colors.transparent),
                onTap: () {
                  setState(() {
                    _selectedExistingPlayer = player;
                  });
                },
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<int>(
                      value: player.id ?? -1,
                      groupValue: _selectedExistingPlayer?.id ?? -2,
                      onChanged: (value) {
                        setState(() {
                          _selectedExistingPlayer = player;
                        });
                      },
                      activeColor: Colors.cyanAccent,
                    ),
                    CircleAvatar(
                      radius: ResponsiveConfig.dimension(context, 20),
                      backgroundColor: Colors.blueGrey[200],
                      child: ResponsiveText(
                        player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                        baseFontSize: 16,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                title: player.name,
                subtitle: player.position,
                actions: player.teamName != null
                    ? [
                        StatusBadge(
                          text: player.teamName!,
                          color: Colors.blue[700]!,
                          size: StatusBadgeSize.small,
                        ),
                      ]
                    : null,
              );
            },
          ),
        ),

        ResponsiveSpacing(multiplier: 3),

        // Coach assignment
        ResponsiveText(
          'Assign Coach (Optional)',
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1),

        // Coach dropdown
        if (_coaches.isEmpty)
          EmptyStateDisplay(
            title: 'No Coaches Available',
            description: 'No coaches have been added to the system yet.',
            icon: Icons.sports,
            iconSize: ResponsiveConfig.iconSize(context, 36),
            showCard: true,
          )
        else
          StandardDropdown<User?>(
            value: _selectedCoach,
            labelText: 'Select Coach',
            prefixIcon: Icons.sports,
            items: [
              DropdownMenuItem<User?>(
                value: null,
                child: const Text('No Coach'),
              ),
              ..._coaches.map((coach) => DropdownMenuItem<User?>(
                    value: coach,
                    child: Text(coach.name),
                  )).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCoach = value;
              });
            },
            helperText: _selectedExistingPlayer?.primaryCoachName != null
                ? 'Current coach: ${_selectedExistingPlayer!.primaryCoachName}'
                : 'Player has no coach assigned',
          ),
      ],
    );
  }
}