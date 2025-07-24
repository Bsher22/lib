import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamFormScreen extends StatefulWidget {
  final Team? team;
  
  const TeamFormScreen({
    Key? key,
    this.team,
  }) : super(key: key);

  @override
  State<TeamFormScreen> createState() => _TeamFormScreenState();
}

class _TeamFormScreenState extends State<TeamFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  
  File? _logoFile;
  bool _isLoading = false;
  bool _isUploading = false;
  String? _errorMessage;
  bool _formSubmitted = false;
  bool _hasUnsavedChanges = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers
    _nameController = TextEditingController(text: widget.team?.name ?? '');
    _descriptionController = TextEditingController(text: widget.team?.description ?? '');
    
    // Add listeners for form changes
    _nameController.addListener(_checkForChanges);
    _descriptionController.addListener(_checkForChanges);
  }
  
  @override
  void dispose() {
    // Remove listeners
    _nameController.removeListener(_checkForChanges);
    _descriptionController.removeListener(_checkForChanges);
    
    // Dispose controllers
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  void _checkForChanges() {
    final initialName = widget.team?.name ?? '';
    final initialDescription = widget.team?.description ?? '';
    
    final hasChanges = _nameController.text != initialName ||
                       _descriptionController.text != initialDescription ||
                       _logoFile != null;
    
    if (hasChanges != _hasUnsavedChanges) {
      setState(() {
        _hasUnsavedChanges = hasChanges;
      });
    }
  }
  
  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
      );
      
      if (pickedFile != null) {
        setState(() {
          _logoFile = File(pickedFile.path);
          _checkForChanges();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: ResponsiveText('Error selecting image: $e', baseFontSize: 14)),
      );
    }
  }
  
  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _formSubmitted = true;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Prepare team data
      final teamData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
      };
      
      bool success = false;
      Team? resultTeam;
      
      if (widget.team != null) {
        // Update existing team
        if (widget.team!.id != null) {
          final updatedTeam = await ApiServiceFactory.team.updateTeam(widget.team!.id!, teamData);
          success = updatedTeam != null;
          resultTeam = updatedTeam;
          
          if (success) {
            // Update the selected team in the app state
            appState.setSelectedTeam(updatedTeam!);
          }
        }
      } else {
        // Create new team
        final newTeam = await ApiServiceFactory.team.createTeam(teamData);
        success = newTeam != null;
        resultTeam = newTeam;
      }
      
      // Handle logo upload if a new logo was selected and we have a team ID
      if (success && _logoFile != null && resultTeam?.id != null) {
        setState(() {
          _isUploading = true;
        });
        
        try {
          final logoPath = await ApiServiceFactory.team.uploadTeamLogo(resultTeam!.id!, _logoFile!);
          if (logoPath != null) {
            // Update team with new logo path
            final updatedTeamData = {
              'name': resultTeam.name,
              'description': resultTeam.description,
              'logo_path': logoPath,
            };
            
            final updatedTeam = await ApiServiceFactory.team.updateTeam(resultTeam.id!, updatedTeamData);
            if (updatedTeam != null) {
              resultTeam = updatedTeam;
              if (widget.team != null) {
                appState.setSelectedTeam(updatedTeam);
              }
            }
          }
        } catch (e) {
          // Logo upload failed but team was saved successfully
          print('Logo upload failed: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ResponsiveText('Team saved but logo upload failed: $e', baseFontSize: 14),
              backgroundColor: Colors.orange,
            ),
          );
        } finally {
          setState(() {
            _isUploading = false;
          });
        }
      }
      
      if (success) {
        // Reload teams data
        await appState.loadTeams();
        
        if (!mounted) return;
        
        // Return to previous screen with success indicator
        Navigator.pop(context, true);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ResponsiveText(
              widget.team != null ? 'Team updated successfully' : 'Team created successfully',
              baseFontSize: 14,
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = widget.team != null 
            ? 'Failed to update team' 
            : 'Failed to create team';
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
    final isEdit = widget.team != null;
    
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
        title: isEdit ? 'Edit Team' : 'Create Team',
        backgroundColor: Colors.grey[100],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _isLoading
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
                        ResponsiveText('Saving team...', baseFontSize: 16),
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
                                maxWidth: deviceType == DeviceType.desktop ? 600 : null,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildLogoSection(deviceType),
                                  ResponsiveSpacing(multiplier: 3),
                                  _buildTeamDetailsSection(deviceType),
                                  
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

  Widget _buildLogoSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Team Logo',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 2),
          Center(
            child: GestureDetector(
              onTap: _pickLogo,
              child: Stack(
                children: [
                  // Logo preview
                  Container(
                    width: ResponsiveConfig.dimension(context, 120),
                    height: ResponsiveConfig.dimension(context, 120),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey[100],
                      borderRadius: ResponsiveConfig.borderRadius(context, 16),
                      border: Border.all(
                        color: Colors.blueGrey[300]!,
                        width: 2,
                      ),
                    ),
                    child: _logoFile != null
                        ? ClipRRect(
                            borderRadius: ResponsiveConfig.borderRadius(context, 14),
                            child: Image.file(
                              _logoFile!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : widget.team?.logoPath != null
                            ? ClipRRect(
                                borderRadius: ResponsiveConfig.borderRadius(context, 14),
                                child: Image.network(
                                  widget.team!.logoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => 
                                    Icon(
                                      Icons.sports_hockey, 
                                      size: ResponsiveConfig.iconSize(context, 48), 
                                      color: Colors.blueGrey[400],
                                    ),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.sports_hockey, 
                                    size: ResponsiveConfig.iconSize(context, 48), 
                                    color: Colors.blueGrey[400],
                                  ),
                                  ResponsiveSpacing(multiplier: 1),
                                  ResponsiveText(
                                    'Tap to add logo',
                                    baseFontSize: 12,
                                    style: TextStyle(color: Colors.blueGrey[600]),
                                  ),
                                ],
                              ),
                  ),
                  // Edit icon
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: ResponsiveConfig.paddingAll(context, 4),
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: ResponsiveConfig.iconSize(context, 16),
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  // Loading indicator during upload
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: ResponsiveConfig.borderRadius(context, 16),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: ResponsiveConfig.dimension(context, 24),
                            height: ResponsiveConfig.dimension(context, 24),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Tap logo to change image',
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDetailsSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline, 
                color: Colors.blueGrey[600], 
                size: ResponsiveConfig.iconSize(context, 20),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Team Information',
                baseFontSize: 18,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Name field
          StandardTextField(
            controller: _nameController,
            labelText: 'Team Name *',
            prefixIcon: Icons.group,
            validator: ValidationHelper.required('Please enter a team name'),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          // Description field
          StandardTextField(
            controller: _descriptionController,
            labelText: 'Description',
            prefixIcon: Icons.description,
            helperText: 'Provide a short description of the team',
            maxLines: 3,
          ),
        ],
      ),
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
          text: _isLoading
              ? (_isUploading ? 'Uploading logo...' : 'Saving team...')
              : (isEdit ? 'Save Changes' : 'Create Team'),
          onPressed: _isLoading ? null : _saveTeam,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          isLoading: _isLoading,
        ),
      ),
    );
  }
}