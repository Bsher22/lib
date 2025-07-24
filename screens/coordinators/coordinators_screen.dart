import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/common/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';

class CoordinatorsScreen extends StatefulWidget {
  const CoordinatorsScreen({Key? key}) : super(key: key);

  @override
  State<CoordinatorsScreen> createState() => _CoordinatorsScreenState();
}

class _CoordinatorsScreenState extends State<CoordinatorsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCoordinators();
  }
  
  Future<void> _loadCoordinators() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadUsers();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading coordinators: $e';
        _isLoading = false;
      });
    }
  }
  
  void _viewCoordinatorDetails(User coordinator) {
    if (coordinator.id == null) return;
    
    Navigator.pushNamed(
      context,
      '/coordinator-details',
      arguments: coordinator,
    );
  }
  
  void _editCoordinator(User coordinator) {
    if (coordinator.id == null) return;
    
    Navigator.pushNamed(
      context,
      '/coordinator-form',
      arguments: coordinator,
    ).then((result) {
      if (result == true) {
        _loadCoordinators();
      }
    });
  }
  
  void _createNewCoordinator() {
    Navigator.pushNamed(
      context,
      '/coordinator-form',
    ).then((result) {
      if (result == true) {
        _loadCoordinators();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    final coordinators = appState.coordinators;
    
    // Only admins and directors can manage coordinators
    final canManageCoordinators = userRole == 'admin' || userRole == 'director';
    
    return AdaptiveScaffold(
      title: 'Coordinators',
      backgroundColor: Colors.grey[100],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadCoordinators,
          tooltip: 'Refresh Coordinators',
        ),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    _buildLoadingState(deviceType)
                  else if (_errorMessage != null)
                    _buildErrorState(deviceType)
                  else if (coordinators.isEmpty)
                    _buildEmptyState(canManageCoordinators, deviceType)
                  else
                    _buildCoordinatorsList(coordinators, canManageCoordinators, deviceType),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: canManageCoordinators
          ? FloatingActionButton.extended(
              onPressed: _createNewCoordinator,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: ResponsiveText('Add Coordinator', baseFontSize: 14),
              tooltip: 'Add Coordinator',
            )
          : null,
    );
  }
  
  Widget _buildLoadingState(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            strokeWidth: ResponsiveConfig.dimension(context, 3),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Loading coordinators...',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveConfig.dimension(context, 64),
            color: Colors.red[300],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Error Loading Coordinators',
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _errorMessage ?? 'An unknown error occurred',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveButton(
            text: 'Try Again',
            baseHeight: 48,
            onPressed: _loadCoordinators,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.refresh, // Fixed: removed Icon() wrapper
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState(bool canCreate, DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt,
            size: ResponsiveConfig.dimension(context, 72),
            color: Colors.blueGrey[300],
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'No Coordinators Available',
            baseFontSize: 24,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ResponsiveText(
            canCreate
                ? 'Add coordinators to help manage teams and coaches'
                : 'No coordinators have been added to the system yet',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
          if (canCreate) ...[
            ResponsiveSpacing(multiplier: 4),
            ResponsiveButton(
              text: 'Add Coordinator',
              baseHeight: 48,
              onPressed: _createNewCoordinator,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: Icons.add, // Fixed: removed Icon() wrapper
              width: deviceType == DeviceType.mobile 
                  ? double.infinity 
                  : ResponsiveConfig.dimension(context, 200),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCoordinatorsList(List<User> coordinators, bool canManageCoordinators, DeviceType deviceType) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count
        ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: Row(
            children: [
              Icon(
                Icons.people_alt,
                size: ResponsiveConfig.dimension(context, 24),
                color: Colors.blueGrey[700],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Coordinators',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Container(
                padding: ResponsiveConfig.paddingSymmetric(
                  context,
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                ),
                child: ResponsiveText(
                  '${coordinators.length}',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (deviceType != DeviceType.mobile)
                ResponsiveButton(
                  text: 'Refresh',
                  baseHeight: 36,
                  onPressed: _loadCoordinators,
                  backgroundColor: Colors.blueGrey[100],
                  foregroundColor: Colors.blueGrey[800],
                  icon: Icons.refresh, // Fixed: removed Icon() wrapper
                  iconSize: 16, // Fixed: moved size to iconSize parameter
                ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Enhanced coordinators list with responsive layout
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            // Desktop/Tablet: Grid layout for better space utilization
            if (deviceType == DeviceType.desktop || 
                (deviceType == DeviceType.tablet && isLandscape)) {
              return _buildCoordinatorsGrid(coordinators, canManageCoordinators, deviceType);
            }
            
            // Mobile/Tablet Portrait: List layout
            return _buildCoordinatorsListView(coordinators, canManageCoordinators);
          },
        ),
      ],
    );
  }
  
  Widget _buildCoordinatorsGrid(List<User> coordinators, bool canManageCoordinators, DeviceType deviceType) {
    final crossAxisCount = deviceType == DeviceType.desktop ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
        childAspectRatio: 1.2,
      ),
      itemCount: coordinators.length,
      itemBuilder: (context, index) {
        return _buildCoordinatorCard(coordinators[index], canManageCoordinators, isGrid: true);
      },
    );
  }
  
  Widget _buildCoordinatorsListView(List<User> coordinators, bool canManageCoordinators) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coordinators.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
          child: _buildCoordinatorCard(coordinators[index], canManageCoordinators, isGrid: false),
        );
      },
    );
  }
  
  Widget _buildCoordinatorCard(User coordinator, bool canManageCoordinators, {required bool isGrid}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: InkWell(
        onTap: () => _viewCoordinatorDetails(coordinator),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        child: isGrid ? _buildGridCoordinatorContent(coordinator, canManageCoordinators) 
                     : _buildListCoordinatorContent(coordinator, canManageCoordinators),
      ),
    );
  }
  
  Widget _buildGridCoordinatorContent(User coordinator, bool canManageCoordinators) {
    final appState = Provider.of<AppState>(context, listen: false);
    final playersCount = appState.players.where((p) => p.coordinatorId == coordinator.id).length;
    final teamsCount = appState.teams.where((t) => 
        appState.players.any((p) => p.teamId == t.id && p.coordinatorId == coordinator.id)).length;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Coordinator avatar
        CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: ResponsiveConfig.dimension(context, 30),
          child: ResponsiveText(
            coordinator.name.isNotEmpty ? coordinator.name[0].toUpperCase() : '?',
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5),
        
        // Coordinator name
        ResponsiveText(
          coordinator.name,
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 0.5),
        
        // Email
        ResponsiveText(
          coordinator.email,
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 1),
        
        // Stats
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group,
                  size: ResponsiveConfig.dimension(context, 14),
                  color: Colors.blueGrey[600],
                ),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                ResponsiveText(
                  '$teamsCount teams',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
            ResponsiveSpacing(multiplier: 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.people,
                  size: ResponsiveConfig.dimension(context, 14),
                  color: Colors.blueGrey[600],
                ),
                ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                ResponsiveText(
                  '$playersCount players',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ],
        ),
        
        const Spacer(),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.visibility,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onPressed: () => _viewCoordinatorDetails(coordinator),
              tooltip: 'View Details',
            ),
            if (canManageCoordinators)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: ResponsiveConfig.dimension(context, 20),
                ),
                onPressed: () => _editCoordinator(coordinator),
                tooltip: 'Edit Coordinator',
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildListCoordinatorContent(User coordinator, bool canManageCoordinators) {
    final appState = Provider.of<AppState>(context, listen: false);
    final playersCount = appState.players.where((p) => p.coordinatorId == coordinator.id).length;
    final teamsCount = appState.teams.where((t) => 
        appState.players.any((p) => p.teamId == t.id && p.coordinatorId == coordinator.id)).length;
    
    return Row(
      children: [
        // Coordinator avatar
        CircleAvatar(
          backgroundColor: Colors.blue[100],
          radius: ResponsiveConfig.dimension(context, 24),
          child: ResponsiveText(
            coordinator.name.isNotEmpty ? coordinator.name[0].toUpperCase() : '?',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
        
        // Coordinator info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                coordinator.name,
                baseFontSize: 16,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              ResponsiveText(
                coordinator.email,
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.blueGrey[600],
                  ),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    '$teamsCount teams',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                  ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                  Icon(
                    Icons.people,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.blueGrey[600],
                  ),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    '$playersCount players',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Role badge
        Container(
          padding: ResponsiveConfig.paddingSymmetric(
            context,
            horizontal: 12,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 16),
            border: Border.all(color: Colors.blue[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.people_alt,
                size: ResponsiveConfig.dimension(context, 14),
                color: Colors.blue[700],
              ),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                'Coordinator',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        
        // Action menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: ResponsiveConfig.dimension(context, 20),
          ),
          onSelected: (action) => _handleCoordinatorAction(action, coordinator),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 8),
                  Text('View Details'),
                ],
              ),
            ),
            if (canManageCoordinators)
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
  
  void _handleCoordinatorAction(String action, User coordinator) {
    switch (action) {
      case 'view':
        _viewCoordinatorDetails(coordinator);
        break;
      case 'edit':
        _editCoordinator(coordinator);
        break;
    }
  }
}