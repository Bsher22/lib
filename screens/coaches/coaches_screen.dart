import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/domain/common/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';

class CoachesScreen extends StatefulWidget {
  const CoachesScreen({Key? key}) : super(key: key);

  @override
  State<CoachesScreen> createState() => _CoachesScreenState();
}

class _CoachesScreenState extends State<CoachesScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadCoaches();
  }
  
  Future<void> _loadCoaches() async {
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
        _errorMessage = 'Error loading coaches: $e';
        _isLoading = false;
      });
    }
  }
  
  void _viewCoachDetails(User coach) {
    if (coach.id == null) return;
    
    Navigator.pushNamed(
      context,
      '/coach-details',
      arguments: coach,
    );
  }
  
  void _editCoach(User coach) {
    if (coach.id == null) return;
    
    Navigator.pushNamed(
      context,
      '/coach-form',
      arguments: coach,
    ).then((result) {
      if (result == true) {
        _loadCoaches();
      }
    });
  }
  
  void _createNewCoach() {
    Navigator.pushNamed(
      context,
      '/coach-form',
    ).then((result) {
      if (result == true) {
        _loadCoaches();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    final coaches = appState.coaches;
    
    // Role-based permissions
    final canCreateCoach = userRole == 'admin' || userRole == 'director';
    final canEditCoach = userRole == 'admin' || userRole == 'director';
    
    return AdaptiveScaffold(
      title: 'Coaches',
      backgroundColor: Colors.grey[100],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadCoaches,
          tooltip: 'Refresh Coaches',
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
                  else if (coaches.isEmpty)
                    _buildEmptyState(canCreateCoach, deviceType)
                  else
                    _buildCoachesList(coaches, canEditCoach, deviceType),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: canCreateCoach
          ? FloatingActionButton.extended(
              onPressed: _createNewCoach,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: ResponsiveText('Add Coach', baseFontSize: 14),
              tooltip: 'Add Coach',
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
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            strokeWidth: ResponsiveConfig.dimension(context, 3),
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Loading coaches...',
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
            'Error Loading Coaches',
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
            onPressed: _loadCoaches,
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
            Icons.sports,
            size: ResponsiveConfig.dimension(context, 72),
            color: Colors.blueGrey[300],
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'No Coaches Available',
            baseFontSize: 24,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ResponsiveText(
            canCreate
                ? 'Add coaches to start building your training organization'
                : 'No coaches have been added to the system yet',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
          if (canCreate) ...[
            ResponsiveSpacing(multiplier: 4),
            ResponsiveButton(
              text: 'Add Coach',
              baseHeight: 48,
              onPressed: _createNewCoach,
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
  
  Widget _buildCoachesList(List<User> coaches, bool canEditCoach, DeviceType deviceType) {
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
                Icons.sports,
                size: ResponsiveConfig.dimension(context, 24),
                color: Colors.blueGrey[700],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Coaches',
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
                  '${coaches.length}',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Spacer(),
              if (deviceType != DeviceType.mobile)
                ResponsiveButton(
                  text: 'Refresh',
                  baseHeight: 36,
                  onPressed: _loadCoaches,
                  backgroundColor: Colors.blueGrey[100],
                  foregroundColor: Colors.blueGrey[800],
                  icon: Icons.refresh, // Fixed: removed Icon() wrapper
                  iconSize: 16, // Fixed: moved size to iconSize parameter
                ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Enhanced coaches list with responsive layout
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            // Desktop/Tablet: Grid layout for better space utilization
            if (deviceType == DeviceType.desktop || 
                (deviceType == DeviceType.tablet && isLandscape)) {
              return _buildCoachesGrid(coaches, canEditCoach, deviceType);
            }
            
            // Mobile/Tablet Portrait: List layout
            return _buildCoachesListView(coaches, canEditCoach);
          },
        ),
      ],
    );
  }
  
  Widget _buildCoachesGrid(List<User> coaches, bool canEditCoach, DeviceType deviceType) {
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
      itemCount: coaches.length,
      itemBuilder: (context, index) {
        return _buildCoachCard(coaches[index], canEditCoach, isGrid: true);
      },
    );
  }
  
  Widget _buildCoachesListView(List<User> coaches, bool canEditCoach) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: coaches.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
          child: _buildCoachCard(coaches[index], canEditCoach, isGrid: false),
        );
      },
    );
  }
  
  Widget _buildCoachCard(User coach, bool canEditCoach, {required bool isGrid}) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: InkWell(
        onTap: () => _viewCoachDetails(coach),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        child: isGrid ? _buildGridCoachContent(coach, canEditCoach) : _buildListCoachContent(coach, canEditCoach),
      ),
    );
  }
  
  Widget _buildGridCoachContent(User coach, bool canEditCoach) {
    final appState = Provider.of<AppState>(context, listen: false);
    final playersCount = appState.players.where((p) => p.primaryCoachId == coach.id).length;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Coach avatar
        CircleAvatar(
          backgroundColor: Colors.green[100],
          radius: ResponsiveConfig.dimension(context, 30),
          child: ResponsiveText(
            coach.name.isNotEmpty ? coach.name[0].toUpperCase() : '?',
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5),
        
        // Coach name
        ResponsiveText(
          coach.name,
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 0.5),
        
        // Email
        ResponsiveText(
          coach.email,
          baseFontSize: 12,
          style: TextStyle(color: Colors.blueGrey[600]),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 1),
        
        // Stats
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
              onPressed: () => _viewCoachDetails(coach),
              tooltip: 'View Details',
            ),
            if (canEditCoach)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: ResponsiveConfig.dimension(context, 20),
                ),
                onPressed: () => _editCoach(coach),
                tooltip: 'Edit Coach',
              ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildListCoachContent(User coach, bool canEditCoach) {
    final appState = Provider.of<AppState>(context, listen: false);
    final playersCount = appState.players.where((p) => p.primaryCoachId == coach.id).length;
    
    return Row(
      children: [
        // Coach avatar
        CircleAvatar(
          backgroundColor: Colors.green[100],
          radius: ResponsiveConfig.dimension(context, 24),
          child: ResponsiveText(
            coach.name.isNotEmpty ? coach.name[0].toUpperCase() : '?',
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
        
        // Coach info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                coach.name,
                baseFontSize: 16,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              ResponsiveText(
                coach.email,
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              ResponsiveSpacing(multiplier: 0.5),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.blueGrey[600],
                  ),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    '$playersCount players coached',
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
            color: Colors.green[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 16),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports,
                size: ResponsiveConfig.dimension(context, 14),
                color: Colors.green[700],
              ),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                'Coach',
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
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
          onSelected: (action) => _handleCoachAction(action, coach),
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
            if (canEditCoach)
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
  
  void _handleCoachAction(String action, User coach) {
    switch (action) {
      case 'view':
        _viewCoachDetails(coach);
        break;
      case 'edit':
        _editCoach(coach);
        break;
    }
  }
}