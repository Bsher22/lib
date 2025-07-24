import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/utils/validation_helper.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class PlayerFormScreen extends StatefulWidget {
  final Player? player;
  
  const PlayerFormScreen({
    Key? key,
    this.player,
  }) : super(key: key);

  @override
  State<PlayerFormScreen> createState() => _PlayerFormScreenState();
}

class _PlayerFormScreenState extends State<PlayerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _jerseyNumberController;
  late final TextEditingController _preferredPositionController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _birthDateController;
  DateTime? _selectedBirthDate;
  
  int? _selectedTeamId;
  int? _selectedCoachId;
  int? _selectedCoordinatorId;
  
  List<Team> _teams = [];
  List<User> _coaches = [];
  List<User> _coordinators = [];
  
  bool _isLoading = false;
  bool _isInitialDataLoading = true;
  String? _errorMessage;
  bool _formSubmitted = false;
  bool _hasUnsavedChanges = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.player?.name ?? '');
    _emailController = TextEditingController(text: widget.player?.email ?? '');
    _phoneController = TextEditingController(text: widget.player?.phone ?? '');
    _jerseyNumberController = TextEditingController(
      text: widget.player?.jerseyNumber != null 
          ? widget.player!.jerseyNumber.toString() 
          : ''
    );
    _preferredPositionController = TextEditingController(text: widget.player?.preferredPosition ?? '');
    _heightController = TextEditingController(
      text: widget.player?.height != null 
          ? widget.player!.height.toString() 
          : ''
    );
    _weightController = TextEditingController(
      text: widget.player?.weight != null 
          ? widget.player!.weight.toString() 
          : ''
    );
    
    // Initialize birth date
    _selectedBirthDate = widget.player?.birthDate;
    _birthDateController = TextEditingController(
      text: _selectedBirthDate != null 
          ? DateFormat('MM/dd/yyyy').format(_selectedBirthDate!) 
          : ''
    );
    
    // Initialize selections
    _selectedTeamId = widget.player?.teamId;
    _selectedCoachId = widget.player?.primaryCoachId;
    _selectedCoordinatorId = widget.player?.coordinatorId;
    
    // Add listeners for form changes
    _nameController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _jerseyNumberController.addListener(_onFormChanged);
    _preferredPositionController.addListener(_onFormChanged);
    _heightController.addListener(_onFormChanged);
    _weightController.addListener(_onFormChanged);
    _birthDateController.addListener(_onFormChanged);
    
    // Load initial data (teams, coaches, coordinators)
    _loadInitialData();
  }
  
  @override
  void dispose() {
    // Remove listeners
    _nameController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _phoneController.removeListener(_onFormChanged);
    _jerseyNumberController.removeListener(_onFormChanged);
    _preferredPositionController.removeListener(_onFormChanged);
    _heightController.removeListener(_onFormChanged);
    _weightController.removeListener(_onFormChanged);
    _birthDateController.removeListener(_onFormChanged);
    
    // Dispose controllers
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _jerseyNumberController.dispose();
    _preferredPositionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _birthDateController.dispose();
    super.dispose();
  }
  
  Future<void> _loadInitialData() async {
    setState(() {
      _isInitialDataLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Load teams, coaches, and coordinators
      if (appState.teams.isEmpty) {
        await appState.loadTeams();
      }
      
      if (appState.coaches.isEmpty) {
        await appState.api.fetchUsersByRole('coach');
      }
      
      if (appState.coordinators.isEmpty) {
        await appState.api.fetchUsersByRole('coordinator');
      }
      
      setState(() {
        _teams = appState.teams;
        _coaches = appState.coaches;
        _coordinators = appState.coordinators;
        _isInitialDataLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading initial data: $e';
        _isInitialDataLoading = false;
      });
    }
  }
  
  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedBirthDate = date;
      _birthDateController.text = DateFormat('MM/dd/yyyy').format(date);
      _onFormChanged();
    });
  }
  
  void _onFormChanged() {
    // Compare the current values to the initial values to determine if there are changes
    final hasChanges = _nameController.text != (widget.player?.name ?? '') ||
                       _emailController.text != (widget.player?.email ?? '') ||
                       _phoneController.text != (widget.player?.phone ?? '') ||
                       _jerseyNumberController.text != (widget.player?.jerseyNumber?.toString() ?? '') ||
                       _preferredPositionController.text != (widget.player?.preferredPosition ?? '') ||
                       _heightController.text != (widget.player?.height?.toString() ?? '') ||
                       _weightController.text != (widget.player?.weight?.toString() ?? '') ||
                       _selectedBirthDate != widget.player?.birthDate ||
                       _selectedTeamId != widget.player?.teamId ||
                       _selectedCoachId != widget.player?.primaryCoachId ||
                       _selectedCoordinatorId != widget.player?.coordinatorId;
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }
  
  Future<void> _savePlayer() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _formSubmitted = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Prepare player data
      final playerData = {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'preferred_position': _preferredPositionController.text.trim(),
      };
      
      // Add optional fields if they have values
      if (_jerseyNumberController.text.isNotEmpty) {
        playerData['jersey_number'] = int.parse(_jerseyNumberController.text);
      }
      
      if (_heightController.text.isNotEmpty) {
        playerData['height'] = double.parse(_heightController.text);
      }
      
      if (_weightController.text.isNotEmpty) {
        playerData['weight'] = double.parse(_weightController.text);
      }
      
      if (_selectedBirthDate != null) {
        playerData['birth_date'] = _selectedBirthDate!.toIso8601String();
      }
      
      if (_selectedTeamId != null) {
        playerData['team_id'] = _selectedTeamId;
      }
      
      if (_selectedCoachId != null) {
        playerData['primary_coach_id'] = _selectedCoachId;
      }
      
      if (_selectedCoordinatorId != null) {
        playerData['coordinator_id'] = _selectedCoordinatorId;
      }
      
      bool success = false;
      
      if (widget.player != null) {
        // Update existing player
        if (widget.player!.id != null) {
          final updatedPlayer = await appState.updatePlayer(widget.player!.id!, playerData);
          success = updatedPlayer;
        }
      } else {
        // Create new player
        final newPlayer = await appState.createPlayer(playerData);
        success = newPlayer != null;
      }
      
      if (success) {
        // Reload players data
        await appState.loadPlayers();
        
        if (!mounted) return;
        
        // Return to previous screen with success indicator
        Navigator.pop(context, true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              widget.player != null 
                ? 'Player updated successfully' 
                : 'Player created successfully',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.player != null 
            ? 'Failed to update player' 
            : 'Failed to create player';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isEdit = widget.player != null;
    
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (didPop || !_hasUnsavedChanges) {
          return;
        }
        
        final result = await DialogService.showUnsavedChanges(context);
        if (result == true) {
          Navigator.of(context).pop();
        }
      },
      child: AdaptiveScaffold(
        title: isEdit ? 'Edit Player' : 'Add Player',
        backgroundColor: Colors.grey[100],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _isInitialDataLoading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: ResponsiveConfig.dimension(context, 32),
                          height: ResponsiveConfig.dimension(context, 32),
                          child: const CircularProgressIndicator(color: Colors.cyanAccent),
                        ),
                        ResponsiveSpacing(multiplier: 2),
                        ResponsiveText('Loading form data...', baseFontSize: 16),
                      ],
                    ),
                  )
                : _isLoading
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: ResponsiveConfig.dimension(context, 32),
                              height: ResponsiveConfig.dimension(context, 32),
                              child: const CircularProgressIndicator(color: Colors.cyanAccent),
                            ),
                            ResponsiveSpacing(multiplier: 2),
                            ResponsiveText('Saving player...', baseFontSize: 16),
                          ],
                        ),
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
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
                                      _buildPlayerAvatarSection(),
                                      ResponsiveSpacing(multiplier: 3),
                                      _buildBasicInformationSection(deviceType),
                                      ResponsiveSpacing(multiplier: 3),
                                      _buildHockeyInformationSection(deviceType),
                                      ResponsiveSpacing(multiplier: 3),
                                      _buildAssignmentsSection(deviceType),
                                      
                                      // Error message
                                      if (_errorMessage != null && _formSubmitted) ...[
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            _buildActionBar(isEdit),
                          ],
                        ),
                      );
          },
        ),
      ),
    );
  }

  Widget _buildPlayerAvatarSection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Center(
        child: CircleAvatar(
          radius: ResponsiveConfig.dimension(context, 50),
          backgroundColor: Colors.blueGrey[200],
          child: Icon(
            Icons.person,
            size: ResponsiveConfig.iconSize(context, 60),
            color: Colors.blueGrey[50],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInformationSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Basic Information', Icons.person_outline),
          ResponsiveSpacing(multiplier: 2),
          
          // Name field
          StandardTextField(
            controller: _nameController,
            labelText: 'Full Name *',
            prefixIcon: Icons.person,
            validator: ValidationHelper.required('Please enter a name'),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Email and Phone - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardTextField(
                      controller: _emailController,
                      labelText: 'Email Address',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidationHelper.email(),
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardTextField(
                      controller: _phoneController,
                      labelText: 'Phone Number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: ValidationHelper.phone(),
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardTextField(
                        controller: _emailController,
                        labelText: 'Email Address',
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: ValidationHelper.email(),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardTextField(
                        controller: _phoneController,
                        labelText: 'Phone Number',
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: ValidationHelper.phone(),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Birth date field
          StandardDatePicker(
            controller: _birthDateController,
            labelText: 'Birth Date',
            prefixIcon: Icons.calendar_today,
            initialDate: _selectedBirthDate,
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            onDateSelected: _onDateSelected,
          ),
        ],
      ),
    );
  }

  Widget _buildHockeyInformationSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Hockey Information', Icons.sports_hockey),
          ResponsiveSpacing(multiplier: 2),
          
          // Jersey number and preferred position - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardTextField(
                      controller: _jerseyNumberController,
                      labelText: 'Jersey Number',
                      prefixIcon: Icons.tag,
                      keyboardType: TextInputType.number,
                      validator: ValidationHelper.compose([
                        ValidationHelper.numberRange(0, 99, 'Please enter a valid jersey number (0-99)'),
                      ]),
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardTextField(
                      controller: _preferredPositionController,
                      labelText: 'Preferred Position',
                      prefixIcon: Icons.sports_hockey,
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardTextField(
                        controller: _jerseyNumberController,
                        labelText: 'Jersey Number',
                        prefixIcon: Icons.tag,
                        keyboardType: TextInputType.number,
                        validator: ValidationHelper.compose([
                          ValidationHelper.numberRange(0, 99, 'Please enter a valid jersey number (0-99)'),
                        ]),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardTextField(
                        controller: _preferredPositionController,
                        labelText: 'Preferred Position',
                        prefixIcon: Icons.sports_hockey,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Height and weight - Always side by side when space permits
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardTextField(
                      controller: _heightController,
                      labelText: 'Height (inches)',
                      prefixIcon: Icons.height,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: ValidationHelper.minValue(0, 'Invalid height'),
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardTextField(
                      controller: _weightController,
                      labelText: 'Weight (lbs)',
                      prefixIcon: Icons.monitor_weight,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: ValidationHelper.minValue(0, 'Invalid weight'),
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardTextField(
                        controller: _heightController,
                        labelText: 'Height (inches)',
                        prefixIcon: Icons.height,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: ValidationHelper.minValue(0, 'Invalid height'),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardTextField(
                        controller: _weightController,
                        labelText: 'Weight (lbs)',
                        prefixIcon: Icons.monitor_weight,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: ValidationHelper.minValue(0, 'Invalid weight'),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Assignments', Icons.people_alt),
          ResponsiveSpacing(multiplier: 2),
          
          // Team dropdown
          StandardDropdown<int?>(
            value: _selectedTeamId,
            labelText: 'Team',
            prefixIcon: Icons.group,
            items: [
              StandardDropdown.nullItem<int>('No Team Assigned'),
              ..._teams.map((team) => DropdownMenuItem<int?>(
                value: team.id,
                child: Text(team.name),
              )).toList(),
            ],
            onChanged: (value) {
              setState(() {
                _selectedTeamId = value;
                _onFormChanged();
              });
            },
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Coach and Coordinator - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardDropdown<int?>(
                      value: _selectedCoachId,
                      labelText: 'Primary Coach',
                      prefixIcon: Icons.sports,
                      items: [
                        StandardDropdown.nullItem<int>('No Coach Assigned'),
                        ..._coaches.map((coach) => DropdownMenuItem<int?>(
                          value: coach.id,
                          child: Text(coach.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCoachId = value;
                          _onFormChanged();
                        });
                      },
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardDropdown<int?>(
                      value: _selectedCoordinatorId,
                      labelText: 'Coordinator',
                      prefixIcon: Icons.people_alt,
                      items: [
                        StandardDropdown.nullItem<int>('No Coordinator Assigned'),
                        ..._coordinators.map((coordinator) => DropdownMenuItem<int?>(
                          value: coordinator.id,
                          child: Text(coordinator.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCoordinatorId = value;
                          _onFormChanged();
                        });
                      },
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardDropdown<int?>(
                        value: _selectedCoachId,
                        labelText: 'Primary Coach',
                        prefixIcon: Icons.sports,
                        items: [
                          StandardDropdown.nullItem<int>('No Coach Assigned'),
                          ..._coaches.map((coach) => DropdownMenuItem<int?>(
                            value: coach.id,
                            child: Text(coach.name),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCoachId = value;
                            _onFormChanged();
                          });
                        },
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardDropdown<int?>(
                        value: _selectedCoordinatorId,
                        labelText: 'Coordinator',
                        prefixIcon: Icons.people_alt,
                        items: [
                          StandardDropdown.nullItem<int>('No Coordinator Assigned'),
                          ..._coordinators.map((coordinator) => DropdownMenuItem<int?>(
                            value: coordinator.id,
                            child: Text(coordinator.name),
                          )).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCoordinatorId = value;
                            _onFormChanged();
                          });
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon, 
          color: Colors.blueGrey[700], 
          size: ResponsiveConfig.iconSize(context, 20),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveText(
          title,
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(bool isEdit) {
    return Container(
      width: double.infinity,
      padding: ResponsiveConfig.paddingAll(context, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: ResponsiveButton(
          text: isEdit ? 'Save Changes' : 'Create Player',
          onPressed: _isLoading ? null : _savePlayer,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          isLoading: _isLoading,
          loadingText: isEdit ? 'Updating player...' : 'Creating player...',
        ),
      ),
    );
  }
}