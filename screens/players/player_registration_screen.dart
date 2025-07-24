import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/validation_helper.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:intl/intl.dart';


class PlayerRegistrationScreen extends StatefulWidget {
  final Player? player; // null = register, non-null = edit
  
  const PlayerRegistrationScreen({super.key, this.player});

  @override
  State<PlayerRegistrationScreen> createState() => _PlayerRegistrationScreenState();
}

class _PlayerRegistrationScreenState extends State<PlayerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  bool _submitSuccess = false;
  
  // Check if we're in edit mode
  bool get _isEditMode => widget.player != null;

  // Required Fields Controllers
  final _nameController = TextEditingController();

  // Optional Fields Controllers
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _preferredPositionController = TextEditingController();

  // Dropdown selections
  int? _selectedTeamId;
  int? _selectedCoachId;
  int? _selectedCoordinatorId;
  String? _selectedAgeGroup;
  String? _selectedPosition;

  // Data lists
  List<Team> _teams = [];
  List<User> _coaches = [];
  List<User> _coordinators = [];
  bool _isLoadingData = false;

  // Age group options
  final Map<String, String> _ageGroups = {
    'youth_8_10': 'Youth 8-10',
    'youth_11_12': 'Youth 11-12',
    'youth_13_14': 'Youth 13-14',
    'youth_15_18': 'Youth 15-18',
    'junior': 'Junior',
    'adult': 'Adult',
  };

  // Position options
  final Map<String, String> _positions = {
    'forward': 'Forward',
    'defense': 'Defense',
    'goalie': 'Goalie',
  };

  @override
  void initState() {
    super.initState();
    
    // Pre-populate fields if we're in edit mode
    if (_isEditMode) {
      _populateFieldsFromPlayer();
    }
    
    // Defer loading form data until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFormData();
    });
  }

  void _populateFieldsFromPlayer() {
    final player = widget.player!;
    
    print('Populating fields for player: ${player.name}');
    print('Player ageGroup: "${player.ageGroup}"');
    print('Player position: "${player.position}"');
    
    // Populate text controllers
    _nameController.text = player.name;
    _emailController.text = player.email ?? '';
    _phoneController.text = player.phone ?? '';
    _heightController.text = player.height?.toString() ?? '';
    _weightController.text = player.weight?.toString() ?? '';
    _jerseyNumberController.text = player.jerseyNumber?.toString() ?? '';
    _preferredPositionController.text = player.preferredPosition ?? '';
    
    // Format and populate birth date
    if (player.birthDate != null) {
      _birthDateController.text = DateFormat('MM/dd/yyyy').format(player.birthDate!);
    }
    
    // Set dropdown selections with validation
    _selectedTeamId = player.teamId;
    _selectedCoachId = player.primaryCoachId;
    _selectedCoordinatorId = player.coordinatorId;
    
    // Handle age group with validation
    if (player.ageGroup != null && _ageGroups.containsKey(player.ageGroup)) {
      _selectedAgeGroup = player.ageGroup;
    } else {
      print('Warning: Age group "${player.ageGroup}" not found in options, setting to null');
      _selectedAgeGroup = null;
    }
    
    // Handle position with validation  
    if (player.position != null && _positions.containsKey(player.position)) {
      _selectedPosition = player.position;
    } else {
      print('Warning: Position "${player.position}" not found in options, setting to null');
      _selectedPosition = null;
    }
    
    print('Selected ageGroup: "$_selectedAgeGroup"');
    print('Selected position: "$_selectedPosition"');
    print('Available age groups: ${_ageGroups.keys.toList()}');
    print('Available positions: ${_positions.keys.toList()}');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _jerseyNumberController.dispose();
    _preferredPositionController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() {
      _isLoadingData = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Load teams, coaches, and coordinators in parallel
      await Future.wait([
        appState.loadTeams(),
        appState.loadUsers(),
      ]);

      setState(() {
        _teams = appState.teams;
        _coaches = appState.coaches;
        _coordinators = appState.coordinators;
      });
    } catch (e) {
      print('Error loading form data: $e');
      // Continue with empty lists - form will still work
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _submitSuccess = false;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);

      // Build player data map
      final playerData = <String, dynamic>{
        // Required fields
        'name': _nameController.text.trim(),
      };

      // Add creation timestamp only for new registrations
      if (!_isEditMode) {
        playerData['created_at'] = DateTime.now().toIso8601String();
      }

      // Add optional fields if they have values
      if (_emailController.text.trim().isNotEmpty) {
        playerData['email'] = _emailController.text.trim();
      }
      if (_phoneController.text.trim().isNotEmpty) {
        playerData['phone'] = _phoneController.text.trim();
      }
      if (_birthDateController.text.trim().isNotEmpty) {
        try {
          final birthDate = DateFormat('MM/dd/yyyy').parse(_birthDateController.text.trim());
          playerData['birth_date'] = birthDate.toIso8601String();
        } catch (e) {
          throw Exception('Invalid birth date format');
        }
      }
      if (_heightController.text.trim().isNotEmpty) {
        playerData['height'] = int.tryParse(_heightController.text.trim());
      }
      if (_weightController.text.trim().isNotEmpty) {
        playerData['weight'] = int.tryParse(_weightController.text.trim());
      }
      if (_jerseyNumberController.text.trim().isNotEmpty) {
        playerData['jersey_number'] = int.tryParse(_jerseyNumberController.text.trim());
      }
      if (_preferredPositionController.text.trim().isNotEmpty) {
        playerData['preferred_position'] = _preferredPositionController.text.trim();
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
      if (_selectedAgeGroup != null) {
        playerData['age_group'] = _selectedAgeGroup;
      }
      if (_selectedPosition != null) {
        playerData['position'] = _selectedPosition;
      }

      print('${_isEditMode ? 'Updating' : 'Registering'} player with data: $playerData');

      // Call appropriate API method
      if (_isEditMode) {
        print('Calling updatePlayer API with playerId: ${widget.player!.id}');
        await ApiServiceFactory.player.updatePlayer(widget.player!.id!, playerData, context: context);
      } else {
        print('Calling registerPlayer API');
        await ApiServiceFactory.player.registerPlayer(playerData, context: context);
      }
      
      // Refresh players list
      await appState.loadPlayers();
      
      _submitSuccess = true;
    } catch (e) {
      _errorMessage = 'Failed to ${_isEditMode ? 'update' : 'register'} player: $e';
      print('${_isEditMode ? 'Update' : 'Registration'} error: $_errorMessage');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }

    if (!mounted) return;

    if (_submitSuccess) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText('Player ${_isEditMode ? 'updated' : 'registered'} successfully!', baseFontSize: 14),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: ResponsiveText(_errorMessage!, baseFontSize: 14),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: _isEditMode ? 'Edit Player' : 'Register New Player',
      backgroundColor: Colors.grey[100],
      body: _isLoadingData
          ? AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                return Center(
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
                );
              },
            )
          : AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                return Form(
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
                                _buildRequiredSection(deviceType),
                                ResponsiveSpacing(multiplier: 4),
                                _buildOptionalSection(deviceType),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _buildSubmitButton(),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildRequiredSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, color: Colors.red[400], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Required Information',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          if (!_isEditMode) ...[
            ResponsiveSpacing(multiplier: 0.5),
            ResponsiveText(
              'Fields marked with * are required',
              baseFontSize: 12,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          ResponsiveSpacing(multiplier: 2),
          StandardTextField(
            controller: _nameController,
            labelText: 'Player Name *',
            hintText: 'Enter the player\'s full name',
            prefixIcon: Icons.person,
            textCapitalization: TextCapitalization.words,
            validator: ValidationHelper.required('Player name is required'),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionalSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, color: Colors.blueGrey[600], size: ResponsiveConfig.iconSize(context, 20)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Optional Information',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _isEditMode 
                ? 'Update any additional information as needed'
                : 'Fill out any additional information you have available',
            baseFontSize: 14,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 3),
          
          // Personal Information
          _buildSectionHeader('Personal Information', Icons.person_outline, deviceType),
          ResponsiveSpacing(multiplier: 1.5),
          _buildPersonalInfoFields(deviceType),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Team and Position Information  
          _buildSectionHeader('Team & Position Information', Icons.sports_hockey, deviceType),
          ResponsiveSpacing(multiplier: 1.5),
          _buildTeamPositionFields(deviceType),
          
          ResponsiveSpacing(multiplier: 3),
          
          // Staff Assignment
          _buildSectionHeader('Staff Assignment', Icons.supervisor_account, deviceType),
          ResponsiveSpacing(multiplier: 1.5),
          _buildStaffAssignmentFields(deviceType),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoFields(DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardTextField(
          controller: _emailController,
          labelText: 'Email Address',
          hintText: 'player@example.com',
          prefixIcon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: ValidationHelper.email(),
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardTextField(
          controller: _phoneController,
          labelText: 'Phone Number',
          hintText: '(555) 123-4567',
          prefixIcon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: ValidationHelper.phone(),
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardDatePicker(
          controller: _birthDateController,
          labelText: 'Birth Date',
          hintText: 'Select birth date',
          prefixIcon: Icons.cake,
          lastDate: DateTime.now(),
          firstDate: DateTime(1990),
        ),
        ResponsiveSpacing(multiplier: 2),
        
        // Height and Weight - Responsive layout
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
                    hintText: 'e.g., 72',
                    prefixIcon: Icons.height,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: ValidationHelper.numberRange(30, 100, 'Height must be between 30-100 inches'),
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  StandardTextField(
                    controller: _weightController,
                    labelText: 'Weight (lbs)',
                    hintText: 'e.g., 180',
                    prefixIcon: Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: ValidationHelper.numberRange(50, 500, 'Weight must be between 50-500 lbs'),
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
                      hintText: 'e.g., 72',
                      prefixIcon: Icons.height,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: ValidationHelper.numberRange(30, 100, 'Height must be between 30-100 inches'),
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(
                    child: StandardTextField(
                      controller: _weightController,
                      labelText: 'Weight (lbs)',
                      hintText: 'e.g., 180',
                      prefixIcon: Icons.monitor_weight,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: ValidationHelper.numberRange(50, 500, 'Weight must be between 50-500 lbs'),
                    ),
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTeamPositionFields(DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardDropdown<int>(
          value: _selectedTeamId,
          labelText: 'Team',
          prefixIcon: Icons.group,
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No Team'),
            ),
            ..._teams.map((team) => DropdownMenuItem<int>(
              value: team.id,
              child: Text(team.name ?? 'Unnamed Team'),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedTeamId = value;
            });
          },
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardDropdown<String>(
          value: _selectedAgeGroup,
          labelText: 'Age Group',
          prefixIcon: Icons.cake,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select Age Group'),
            ),
            ..._ageGroups.entries.map((entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedAgeGroup = value;
            });
          },
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardDropdown<String>(
          value: _selectedPosition,
          labelText: 'Primary Position',
          prefixIcon: Icons.sports,
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Select Position'),
            ),
            ..._positions.entries.map((entry) => DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedPosition = value;
            });
          },
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardTextField(
          controller: _preferredPositionController,
          labelText: 'Preferred Position (specific)',
          hintText: 'e.g., Left Wing, Center, Right Defense',
          prefixIcon: Icons.star_border,
          textCapitalization: TextCapitalization.words,
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardTextField(
          controller: _jerseyNumberController,
          labelText: 'Jersey Number',
          hintText: 'e.g., 99',
          prefixIcon: Icons.tag,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: ValidationHelper.numberRange(1, 99, 'Jersey number must be between 1-99'),
        ),
      ],
    );
  }

  Widget _buildStaffAssignmentFields(DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        StandardDropdown<int>(
          value: _selectedCoachId,
          labelText: 'Primary Coach',
          prefixIcon: Icons.sports,
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No Coach Assigned'),
            ),
            ..._coaches.map((coach) => DropdownMenuItem<int>(
              value: coach.id,
              child: Text(coach.name ?? coach.username),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCoachId = value;
            });
          },
        ),
        ResponsiveSpacing(multiplier: 2),
        StandardDropdown<int>(
          value: _selectedCoordinatorId,
          labelText: 'Coordinator',
          prefixIcon: Icons.manage_accounts,
          items: [
            const DropdownMenuItem<int>(
              value: null,
              child: Text('No Coordinator Assigned'),
            ),
            ..._coordinators.map((coordinator) => DropdownMenuItem<int>(
              value: coordinator.id,
              child: Text(coordinator.name ?? coordinator.username),
            )),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCoordinatorId = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, DeviceType deviceType) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blueGrey[700], size: ResponsiveConfig.iconSize(context, 20)),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveText(
          title,
          baseFontSize: 16,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.blueGrey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
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
      child: ResponsiveButton(
        // 🔄 FIXED: Removed loadingText parameter - using conditional text instead
        text: _isLoading 
            ? '${_isEditMode ? 'Updating' : 'Registering'} Player...'
            : _isEditMode ? 'Update Player' : 'Register Player',
        onPressed: _isLoading ? null : _submitForm,
        baseHeight: 48,
        width: double.infinity,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        isLoading: _isLoading,
      ),
    );
  }
}