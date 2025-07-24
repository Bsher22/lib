import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class AssignCoachToPlayerScreen extends StatefulWidget {
  final Player player;
  
  const AssignCoachToPlayerScreen({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  State<AssignCoachToPlayerScreen> createState() => _AssignCoachToPlayerScreenState();
}

class _AssignCoachToPlayerScreenState extends State<AssignCoachToPlayerScreen> {
  bool _isLoading = false;
  bool _isAssigning = false;
  String? _errorMessage;
  List<User> _availableCoaches = [];
  User? _selectedCoach;
  User? _currentCoach;
  
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
      
      // Load all coaches
      final allCoaches = appState.coaches;
      
      // Find current coach if any
      if (widget.player.primaryCoachId != null) {
        _currentCoach = allCoaches.firstWhereOrNull(
          (c) => c.id == widget.player.primaryCoachId,
        );
      }
      
      // Set available coaches (all coaches for selection)
      _availableCoaches = allCoaches;
      
      // Pre-select current coach if exists
      _selectedCoach = _currentCoach;
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading coaches: $e';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _assignCoach() async {
    // Show confirmation dialog
    final String action = _selectedCoach == null 
        ? 'remove the current coach from'
        : _currentCoach == null
            ? 'assign ${_selectedCoach!.name} as coach for'
            : 'change the coach for';
    
    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Update Coach Assignment?',
      message: 'This will $action ${widget.player.name}.',
      confirmLabel: 'Update',
      cancelLabel: 'Cancel',
    );
    
    if (confirmed != true) return;
    
    setState(() {
      _isAssigning = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Prepare update data
      final playerData = <String, dynamic>{
        'primary_coach_id': _selectedCoach?.id,
      };
      
      final success = await appState.updatePlayer(widget.player.id!, playerData);
      
      if (!mounted) return;
      
      if (success) {
        // Show success message
        await DialogService.showSuccess(
          context,
          title: 'Coach Assignment Updated',
          message: _selectedCoach == null
              ? 'Coach removed from ${widget.player.name}'
              : '${_selectedCoach!.name} assigned as coach for ${widget.player.name}',
        );
        
        // Return to previous screen with success indicator
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = 'Failed to update coach assignment';
          _isAssigning = false;
        });
        
        await DialogService.showError(
          context,
          title: 'Assignment Failed',
          message: _errorMessage!,
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error updating coach assignment: $e';
        _isAssigning = false;
      });
      
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
      title: 'Assign Coach - ${widget.player.name}',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return LoadingOverlay(
            isLoading: _isLoading,
            message: 'Loading coaches...',
            color: Colors.cyanAccent,
            child: _errorMessage != null
                ? ErrorDisplay(
                    message: 'Error Loading Coaches',
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
    return SingleChildScrollView(
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
            // Player info card
            _buildPlayerInfoCard(),
            
            ResponsiveSpacing(multiplier: 3),
            
            // Coach selection section
            ResponsiveText(
              'Select Coach',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              'Choose a coach to assign to this player, or select "No Coach" to remove the current assignment.',
              baseFontSize: 14,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            
            ResponsiveSpacing(multiplier: 2),
            
            if (_availableCoaches.isEmpty)
              EmptyStateDisplay(
                title: 'No Coaches Available',
                description: 'No coaches have been added to the system yet.',
                icon: Icons.sports,
                showCard: true,
              )
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // "No Coach" option
                  _buildCoachOption(null, 'No Coach Assigned'),
                  
                  ResponsiveSpacing(multiplier: 1),
                  
                  // Available coaches
                  ..._availableCoaches.map((coach) => 
                    _buildCoachOption(coach, coach.name)
                  ).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerInfoCard() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveConfig.dimension(context, 30),
            backgroundColor: Colors.blueGrey[200],
            child: ResponsiveText(
              widget.player.name.isNotEmpty 
                  ? widget.player.name[0].toUpperCase() 
                  : '?',
              baseFontSize: 24,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
                  widget.player.name,
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                if (widget.player.position != null)
                  ResponsiveText(
                    widget.player.position!,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                if (_currentCoach != null)
                  Padding(
                    padding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports, size: ResponsiveConfig.iconSize(context, 14), color: Colors.green[600]),
                        ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                        ResponsiveText(
                          'Current: ${_currentCoach!.name}',
                          baseFontSize: 12,
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          StatusBadge(
            text: 'Player',
            color: Colors.blue[700]!,
            size: StatusBadgeSize.small,
            shape: StatusBadgeShape.pill,
            icon: Icons.person,
          ),
        ],
      ),
    );
  }
  
  Widget _buildCoachOption(User? coach, String displayName) {
    final isSelected = _selectedCoach?.id == coach?.id || 
                      (_selectedCoach == null && coach == null);
    final isCurrent = _currentCoach?.id == coach?.id ||
                     (_currentCoach == null && coach == null);
    
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      child: ListItemWithActions(
        padding: ResponsiveConfig.paddingAll(context, 16),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        backgroundColor: isSelected ? Colors.blue[50] : null,
        border: isSelected
            ? Border.all(color: Colors.blue, width: 2)
            : Border.all(color: Colors.grey[300]!),
        onTap: () {
          setState(() {
            _selectedCoach = coach;
          });
        },
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<String>(
              value: coach?.id?.toString() ?? 'none',
              groupValue: _selectedCoach?.id?.toString() ?? 'none',
              onChanged: (value) {
                setState(() {
                  _selectedCoach = coach;
                });
              },
              activeColor: Colors.blue,
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            CircleAvatar(
              radius: ResponsiveConfig.dimension(context, 20),
              backgroundColor: coach != null ? Colors.green[100] : Colors.grey[300],
              child: Icon(
                coach != null ? Icons.sports : Icons.person_off,
                color: coach != null ? Colors.green[700] : Colors.grey[600],
                size: ResponsiveConfig.iconSize(context, 20),
              ),
            ),
          ],
        ),
        title: displayName,
        subtitle: coach?.email,
        actions: [
          if (isCurrent)
            StatusBadge(
              text: 'Current',
              color: Colors.green[700]!,
              size: StatusBadgeSize.small,
            ),
          if (isSelected && !isCurrent)
            StatusBadge(
              text: 'Selected',
              color: Colors.blue[700]!,
              size: StatusBadgeSize.small,
            ),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar() {
    final hasChanges = _selectedCoach?.id != _currentCoach?.id;
    
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
                    text: hasChanges ? 'Changes pending' : 'No changes',
                    color: hasChanges ? Colors.orange[700]! : Colors.grey[600]!,
                    size: StatusBadgeSize.medium,
                    shape: StatusBadgeShape.pill,
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  SizedBox(
                    width: double.infinity,
                    child: _buildUpdateButton(hasChanges),
                  ),
                ],
              );
            } else {
              // Tablet/Desktop: Side by side
              return Row(
                children: [
                  StatusBadge(
                    text: hasChanges ? 'Changes pending' : 'No changes',
                    color: hasChanges ? Colors.orange[700]! : Colors.grey[600]!,
                    size: StatusBadgeSize.medium,
                    shape: StatusBadgeShape.pill,
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Expanded(child: _buildUpdateButton(hasChanges)),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildUpdateButton(bool hasChanges) {
    return ResponsiveButton(
      text: _isAssigning ? 'Updating Assignment...' : 'Update Coach Assignment',
      onPressed: hasChanges && !_isAssigning ? _assignCoach : null,
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