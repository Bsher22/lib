import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({Key? key}) : super(key: key);

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Team> _filteredTeams = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTeams();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeams() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.loadTeams();

      if (mounted) {
        setState(() {
          _isLoading = false;
          _applyFilters();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading teams: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    final appState = Provider.of<AppState>(context, listen: false);
    final allTeams = appState.teams;

    if (_searchQuery.isEmpty) {
      _filteredTeams = List.from(allTeams);
    } else {
      _filteredTeams = allTeams
          .where((team) => team.name.toLowerCase().contains(_searchQuery))
          .toList();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _onSearchChanged('');
  }

  void _viewTeamDetails(Team team) {
    final appState = Provider.of<AppState>(context, listen: false);
    appState.setSelectedTeam(team);
    Navigator.pushNamed(
      context,
      '/team-details',
      arguments: team,
    ).then((_) {
      _loadTeams();
    });
  }

  void _editTeam(Team team) {
    Navigator.pushNamed(
      context,
      '/team-form',
      arguments: team,
    ).then((result) {
      if (result == true) {
        _loadTeams();
      }
    });
  }

  void _viewTeamPlayers(Team team) {
    Navigator.pushNamed(
      context,
      '/team-players',
      arguments: team,
    ).then((_) {
      _loadTeams();
    });
  }

  void _viewTeamStats(Team team) {
    Navigator.pushNamed(
      context,
      '/team-stats',
      arguments: team,
    );
  }

  void _createNewTeam() {
    Navigator.pushNamed(context, '/team-form').then((result) {
      if (result == true) {
        _loadTeams();
      }
    });
  }

  void _exportTeams() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    final teams = appState.teams;

    final canCreateTeam = userRole == 'admin' || userRole == 'director';

    return AdaptiveScaffold(
      title: 'Teams',
      backgroundColor: Colors.grey[100],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadTeams,
          tooltip: 'Refresh',
        ),
        IconButton(
          icon: const Icon(Icons.file_download),
          onPressed: _exportTeams,
          tooltip: 'Export',
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
                  else
                    _buildTeamList(teams, canCreateTeam, deviceType),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: canCreateTeam
          ? FloatingActionButton.extended(
              onPressed: _createNewTeam,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add),
              label: ResponsiveText('Create Team', baseFontSize: 14),
              tooltip: 'Create Team',
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
            'Loading teams...',
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
        children: [
          Icon(
            Icons.error_outline,
            size: ResponsiveConfig.dimension(context, 64),
            color: Colors.red[400],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Error Loading Teams',
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _errorMessage ?? 'Unknown error occurred',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveButton(
            text: 'Try Again',
            baseHeight: 48,
            onPressed: _loadTeams,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.refresh, // Fixed: removed Icon() wrapper
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList(List<Team> teams, bool canCreateTeam, DeviceType deviceType) {
    if (teams.isEmpty) {
      return _buildEmptyState(canCreateTeam);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and filters
        _buildSearchSection(),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Header with count
        _buildTeamsHeader(),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Teams list/grid
        _filteredTeams.isEmpty
            ? _buildNoSearchResults()
            : _buildTeamsContent(deviceType),
      ],
    );
  }

  Widget _buildEmptyState(bool canCreateTeam) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group,
            size: ResponsiveConfig.dimension(context, 72),
            color: Colors.blueGrey[300],
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveText(
            'No Teams Available',
            baseFontSize: 24,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1.5),
          ResponsiveText(
            canCreateTeam
                ? 'Create a team to start tracking player performance'
                : 'No teams have been created yet',
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
          if (canCreateTeam) ...[
            ResponsiveSpacing(multiplier: 4),
            ResponsiveButton(
              text: 'Create Team',
              baseHeight: 48,
              onPressed: _createNewTeam,
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: Icons.add, // Fixed: removed Icon() wrapper
              width: ResponsiveConfig.dimension(context, 200),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Search Teams',
            baseFontSize: 16,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          ResponsiveSpacing(multiplier: 1),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search teams',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsHeader() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        children: [
          Icon(
            Icons.group,
            size: ResponsiveConfig.dimension(context, 24),
            color: Colors.blueGrey[700],
          ),
          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
          ResponsiveText(
            'Teams',
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
              '${_filteredTeams.length}',
              baseFontSize: 14,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: ResponsiveConfig.dimension(context, 64),
            color: Colors.grey[400],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'No teams match your search',
            baseFontSize: 18,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Try adjusting your search criteria',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 3),
          ResponsiveButton(
            text: 'Clear Search',
            baseHeight: 48,
            onPressed: _clearSearch,
            backgroundColor: Colors.blueGrey[100],
            foregroundColor: Colors.blueGrey[800],
            icon: Icons.clear, // Fixed: removed Icon() wrapper
          ),
        ],
      ),
    );
  }

  Widget _buildTeamsContent(DeviceType deviceType) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        // Desktop/Tablet: Grid layout for better space utilization
        if (deviceType == DeviceType.desktop || 
            (deviceType == DeviceType.tablet && isLandscape)) {
          return _buildTeamsGrid(deviceType);
        }
        
        // Mobile/Tablet Portrait: List layout
        return _buildTeamsListView();
      },
    );
  }

  Widget _buildTeamsGrid(DeviceType deviceType) {
    final crossAxisCount = deviceType == DeviceType.desktop ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredTeams.length,
      itemBuilder: (context, index) {
        return _buildTeamCard(_filteredTeams[index], isGrid: true);
      },
    );
  }

  Widget _buildTeamsListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredTeams.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
          child: _buildTeamCard(_filteredTeams[index], isGrid: false),
        );
      },
    );
  }

  Widget _buildTeamCard(Team team, {required bool isGrid}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final playersCount = team.id != null ? appState.getTeamPlayersCount(team.id!) : 0;

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: InkWell(
        onTap: () => _viewTeamDetails(team),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        child: isGrid ? _buildGridTeamContent(team, playersCount) 
                     : _buildListTeamContent(team, playersCount),
      ),
    );
  }

  Widget _buildGridTeamContent(Team team, int playersCount) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Team logo
        Container(
          width: ResponsiveConfig.dimension(context, 80),
          height: ResponsiveConfig.dimension(context, 80),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: ResponsiveConfig.borderRadius(context, 12),
          ),
          child: team.logoPath != null
              ? ClipRRect(
                  borderRadius: ResponsiveConfig.borderRadius(context, 12),
                  child: Image.network(
                    team.logoPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
                          Icons.sports_hockey,
                          size: ResponsiveConfig.dimension(context, 40),
                          color: Colors.blueGrey[400],
                        ),
                  ),
                )
              : Icon(
                  Icons.sports_hockey,
                  size: ResponsiveConfig.dimension(context, 40),
                  color: Colors.blueGrey[400],
                ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5),
        
        // Team name
        ResponsiveText(
          team.name,
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 0.5),
        
        // Description
        if (team.description != null && team.description!.isNotEmpty) ...[
          ResponsiveText(
            team.description!,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          ResponsiveSpacing(multiplier: 1),
        ],
        
        // Stats
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people,
              size: ResponsiveConfig.dimension(context, 16),
              color: Colors.blueGrey[600],
            ),
            ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
            ResponsiveText(
              '$playersCount ${playersCount == 1 ? 'player' : 'players'}',
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
        
        if (team.createdAt != null) ...[
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            'Created: ${_formatDate(team.createdAt!)}',
            baseFontSize: 10,
            style: TextStyle(color: Colors.blueGrey[500]),
            textAlign: TextAlign.center,
          ),
        ],
        
        const Spacer(),
        
        // Status badge
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
          child: ResponsiveText(
            'Active',
            baseFontSize: 12,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1),
        
        // Action buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(
                Icons.people,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onPressed: () => _viewTeamPlayers(team),
              tooltip: 'View Players',
            ),
            IconButton(
              icon: Icon(
                Icons.bar_chart,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onPressed: () => _viewTeamStats(team),
              tooltip: 'View Stats',
            ),
            IconButton(
              icon: Icon(
                Icons.edit,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onPressed: () => _editTeam(team),
              tooltip: 'Edit Team',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListTeamContent(Team team, int playersCount) {
    return Row(
      children: [
        // Team logo
        Container(
          width: ResponsiveConfig.dimension(context, 60),
          height: ResponsiveConfig.dimension(context, 60),
          decoration: BoxDecoration(
            color: Colors.blueGrey[100],
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          child: team.logoPath != null
              ? ClipRRect(
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  child: Image.network(
                    team.logoPath!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Icon(
                          Icons.sports_hockey,
                          size: ResponsiveConfig.dimension(context, 32),
                          color: Colors.blueGrey[400],
                        ),
                  ),
                )
              : Icon(
                  Icons.sports_hockey,
                  size: ResponsiveConfig.dimension(context, 32),
                  color: Colors.blueGrey[400],
                ),
        ),
        
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        
        // Team info
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ResponsiveText(
                team.name,
                baseFontSize: 16,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (team.description != null && team.description!.isNotEmpty) ...[
                ResponsiveSpacing(multiplier: 0.5),
                ResponsiveText(
                  team.description!,
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                    '$playersCount ${playersCount == 1 ? 'player' : 'players'}',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                  if (team.createdAt != null) ...[
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    ResponsiveText(
                      'Created: ${_formatDate(team.createdAt!)}',
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.blueGrey[500]),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        // Status badge
        Container(
          padding: ResponsiveConfig.paddingSymmetric(
            context,
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 16),
            border: Border.all(color: Colors.green[300]!),
          ),
          child: ResponsiveText(
            'Active',
            baseFontSize: 12,
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        
        // Action menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: ResponsiveConfig.dimension(context, 20),
          ),
          onSelected: (action) => _handleTeamAction(action, team),
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
            const PopupMenuItem(
              value: 'players',
              child: Row(
                children: [
                  Icon(Icons.people, size: 20),
                  SizedBox(width: 8),
                  Text('View Players'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 20),
                  SizedBox(width: 8),
                  Text('View Stats'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20),
                  SizedBox(width: 8),
                  Text('Edit Team'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _handleTeamAction(String action, Team team) {
    switch (action) {
      case 'view':
        _viewTeamDetails(team);
        break;
      case 'players':
        _viewTeamPlayers(team);
        break;
      case 'stats':
        _viewTeamStats(team);
        break;
      case 'edit':
        _editTeam(team);
        break;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}