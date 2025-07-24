import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/navigation_service.dart';
import 'package:hockey_shot_tracker/widgets/core/list/index.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';

class PlayersScreen extends StatefulWidget {
  const PlayersScreen({super.key});

  @override
  State<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends State<PlayersScreen> {
  String _searchQuery = '';
  String? _selectedTeamId;
  String _selectedFilterType = 'all'; // 'all', 'shooting', 'skating', 'performance'
  List<Player> _filteredPlayers = [];
  bool _isLoading = true;
  String? _errorMessage;
  
  // Player analytics cache for performance filtering
  Map<int, Map<String, dynamic>> _playerAnalytics = {};
  bool _isLoadingAnalytics = false;
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('PlayersScreen: initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPlayers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    print('PlayersScreen: dispose called');
    super.dispose();
  }

  Future<void> _loadPlayers() async {
    print('PlayersScreen: _loadPlayers started');
    if (!mounted) return;

    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      print('PlayersScreen: Got appState, loading players...');

      await appState.loadPlayers();
      if (!mounted) return;
      
      print('PlayersScreen: Players loaded, count: ${appState.players.length}');

      await appState.loadTeams();
      if (!mounted) return;
      
      print('PlayersScreen: Teams loaded, count: ${appState.teams.length}');

      // Set default player if none selected
      if (appState.selectedPlayer == null && appState.players.isNotEmpty) {
        appState.setSelectedPlayer(appState.players.first.name);
        print('PlayersScreen: Set default player: ${appState.players.first.name}');
      }

      if (mounted) {
        _filterPlayers();
        print('PlayersScreen: Filtering complete, filtered count: ${_filteredPlayers.length}');
        
        // Load analytics for performance-based filtering
        _loadPlayerAnalytics();
      }
    } catch (e) {
      print('PlayersScreen: Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load players. Please check your permissions or try again.';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading players: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                if (mounted) {
                  _loadPlayers();
                }
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Load player analytics for enhanced filtering and display
  Future<void> _loadPlayerAnalytics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingAnalytics = true;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      for (final player in appState.players) {
        if (player.id != null && mounted) {
          try {
            // Load both shooting and skating analytics
            final shootingAnalytics = await ApiServiceFactory.analytics.getPlayerAnalytics(player.id!, context: context);
            final skatingAnalytics = await ApiServiceFactory.analytics.getPlayerSkatingAnalytics(player.id!, context: context);
            
            if (mounted) {
              _playerAnalytics[player.id!] = {
                'shooting': shootingAnalytics,
                'skating': skatingAnalytics,
                'last_updated': DateTime.now(),
              };
            }
          } catch (e) {
            print('Error loading analytics for player ${player.name}: $e');
            // Continue loading other players even if one fails
          }
        }
      }
      
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
        _filterPlayers(); // Re-filter with analytics data
      }
    } catch (e) {
      print('Error loading player analytics: $e');
      if (mounted) {
        setState(() {
          _isLoadingAnalytics = false;
        });
      }
    }
  }

  void _filterPlayers() {
    if (!mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    setState(() {
      _filteredPlayers = appState.players.where((player) {
        // Search query filter
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          if (!(player.name.toLowerCase().contains(query))) {
            return false;
          }
        }

        // Team filter
        if (_selectedTeamId != null && _selectedTeamId!.isNotEmpty) {
          final teamId = int.tryParse(_selectedTeamId!);
          if (player.teamId != teamId) {
            return false;
          }
        }

        // Performance-based filters
        if (_selectedFilterType != 'all' && player.id != null) {
          final analytics = _playerAnalytics[player.id!];
          if (analytics == null) return true; // Show all if no analytics yet

          switch (_selectedFilterType) {
            case 'shooting':
              // Show players with recent shooting activity
              final shootingData = analytics['shooting'] as Map<String, dynamic>? ?? {};
              final totalShots = shootingData['total_shots'] as int? ?? 0;
              return totalShots > 0;
              
            case 'skating':
              // Show players with recent skating activity
              final skatingData = analytics['skating'] as Map<String, dynamic>? ?? {};
              final totalSessions = skatingData['total_sessions'] as int? ?? 0;
              return totalSessions > 0;
              
            case 'performance':
              // Show players with both shooting and skating data
              final shootingData = analytics['shooting'] as Map<String, dynamic>? ?? {};
              final skatingData = analytics['skating'] as Map<String, dynamic>? ?? {};
              final hasShootingData = (shootingData['total_shots'] as int? ?? 0) > 0;
              final hasSkatingData = (skatingData['total_sessions'] as int? ?? 0) > 0;
              return hasShootingData && hasSkatingData;
          }
        }

        return true;
      }).toList();

      // Enhanced sorting with analytics
      _filteredPlayers.sort((a, b) {
        if (_selectedFilterType == 'performance' && a.id != null && b.id != null) {
          final aAnalytics = _playerAnalytics[a.id!];
          final bAnalytics = _playerAnalytics[b.id!];
          
          if (aAnalytics != null && bAnalytics != null) {
            // Sort by combined performance score
            final aShootingRate = (aAnalytics['shooting']?['overall_success_rate'] as double? ?? 0.0);
            final aSkatingScore = (aAnalytics['skating']?['overall_score'] as double? ?? 0.0) / 10;
            final aCombinedScore = (aShootingRate + aSkatingScore) / 2;
            
            final bShootingRate = (bAnalytics['shooting']?['overall_success_rate'] as double? ?? 0.0);
            final bSkatingScore = (bAnalytics['skating']?['overall_score'] as double? ?? 0.0) / 10;
            final bCombinedScore = (bShootingRate + bSkatingScore) / 2;
            
            return bCombinedScore.compareTo(aCombinedScore); // Descending order
          }
        }
        
        return a.name.compareTo(b.name); // Default alphabetical sort
      });
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterPlayers();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _selectedTeamId = null;
      _selectedFilterType = 'all';
    });
    _searchController.clear();
    _filterPlayers();
  }

  @override
  Widget build(BuildContext context) {
    print('PlayersScreen: build called, isLoading: $_isLoading, error: $_errorMessage');

    return AdaptiveScaffold(
      title: 'Players',
      backgroundColor: Colors.grey[100],
      actions: [
        // Analytics loading indicator
        if (_isLoadingAnalytics)
          Container(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: SizedBox(
              width: ResponsiveConfig.dimension(context, 20),
              height: ResponsiveConfig.dimension(context, 20),
              child: CircularProgressIndicator(
                strokeWidth: ResponsiveConfig.dimension(context, 2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            if (mounted) {
              _loadPlayers();
            }
          },
          tooltip: 'Refresh Players',
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
                  if (_errorMessage != null)
                    _buildErrorState(deviceType)
                  else if (_isLoading)
                    _buildLoadingState(deviceType)
                  else ...[
                    _buildSearchAndFilters(deviceType),
                    ResponsiveSpacing(multiplier: 2),
                    _buildPlayersList(deviceType),
                  ],
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPlayer,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.person_add),
        label: ResponsiveText('Add Player', baseFontSize: 14),
      ),
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
            'Loading players...',
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
            'Failed to Load Players',
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
            text: 'Retry',
            baseHeight: 48,
            onPressed: () {
              if (mounted) {
                _loadPlayers();
              }
            },
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            icon: Icons.refresh, // Fixed: removed Icon() wrapper
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search players...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              contentPadding: ResponsiveConfig.paddingSymmetric(
                context,
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          
          ResponsiveSpacing(multiplier: 2),
          
          // Filter controls - responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile portrait: Stack filters vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTeamFilter(),
                    ResponsiveSpacing(multiplier: 2),
                    _buildActivityFilter(),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side filters
                return Row(
                  children: [
                    Expanded(child: _buildTeamFilter()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildActivityFilter()),
                  ],
                );
              }
            },
          ),
          
          // Active filters display
          if (_searchQuery.isNotEmpty || _selectedTeamId != null || _selectedFilterType != 'all') ...[
            ResponsiveSpacing(multiplier: 1.5),
            _buildActiveFilters(),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamFilter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Filter by Team:',
          baseFontSize: 14,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        ResponsiveSpacing(multiplier: 1),
        Consumer<AppState>(
          builder: (context, appState, child) {
            final teams = appState.teams;
            return DropdownButtonFormField<String>(
              value: _selectedTeamId,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: ResponsiveConfig.borderRadius(context, 8),
                ),
                contentPadding: ResponsiveConfig.paddingSymmetric(
                  context,
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              hint: ResponsiveText('All Teams', baseFontSize: 14),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: ResponsiveText('All Teams', baseFontSize: 14),
                ),
                ...teams.map((team) => DropdownMenuItem<String>(
                      value: team.id.toString(),
                      child: ResponsiveText(
                        team.name ?? 'Unnamed Team',
                        baseFontSize: 14,
                      ),
                    )),
              ],
              onChanged: (value) {
                if (mounted) {
                  setState(() {
                    _selectedTeamId = value;
                  });
                  _filterPlayers();
                }
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildActivityFilter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Filter by Activity:',
          baseFontSize: 14,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        ResponsiveSpacing(multiplier: 1),
        DropdownButtonFormField<String>(
          value: _selectedFilterType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
            ),
            contentPadding: ResponsiveConfig.paddingSymmetric(
              context,
              horizontal: 12,
              vertical: 8,
            ),
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'all',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people, size: ResponsiveConfig.dimension(context, 16)),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  ResponsiveText('All Players', baseFontSize: 14),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'shooting',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sports_hockey,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.blue,
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  ResponsiveText('With Shooting Data', baseFontSize: 14),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'skating',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.speed,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.green,
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  ResponsiveText('With Skating Data', baseFontSize: 14),
                ],
              ),
            ),
            DropdownMenuItem<String>(
              value: 'performance',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.analytics,
                    size: ResponsiveConfig.dimension(context, 16),
                    color: Colors.purple,
                  ),
                  ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                  ResponsiveText('Top Performers', baseFontSize: 14),
                ],
              ),
            ),
          ],
          onChanged: (value) {
            if (mounted && value != null) {
              setState(() {
                _selectedFilterType = value;
              });
              _filterPlayers();
            }
          },
        ),
      ],
    );
  }

  Widget _buildActiveFilters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ResponsiveText(
              'Active Filters:',
              baseFontSize: 12,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[700],
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearFilters,
              child: ResponsiveText(
                'Clear All',
                baseFontSize: 12,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1),
        Wrap(
          spacing: ResponsiveConfig.spacing(context, 8),
          runSpacing: ResponsiveConfig.spacing(context, 4),
          children: [
            if (_searchQuery.isNotEmpty)
              _buildFilterChip('Search: "$_searchQuery"', () {
                _searchController.clear();
                _onSearchChanged('');
              }),
            if (_selectedTeamId != null)
              Consumer<AppState>(
                builder: (context, appState, child) {
                  final team = appState.teams.firstWhere(
                    (t) => t.id.toString() == _selectedTeamId,
                    orElse: () => Team(id: -1, name: 'Unknown'),
                  );
                  return _buildFilterChip('Team: ${team.name}', () {
                    setState(() {
                      _selectedTeamId = null;
                    });
                    _filterPlayers();
                  });
                },
              ),
            if (_selectedFilterType != 'all')
              _buildFilterChip(_getFilterTypeDisplayName(_selectedFilterType), () {
                setState(() {
                  _selectedFilterType = 'all';
                });
                _filterPlayers();
              }),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Chip(
      label: ResponsiveText(label, baseFontSize: 12),
      onDeleted: onDeleted,
      deleteIcon: Icon(
        Icons.close,
        size: ResponsiveConfig.dimension(context, 18),
      ),
      backgroundColor: Colors.blue[50],
      deleteIconColor: Colors.blue[700],
      side: BorderSide(color: Colors.blue[200]!),
    );
  }

  String _getFilterTypeDisplayName(String filterType) {
    switch (filterType) {
      case 'shooting':
        return 'With Shooting Data';
      case 'skating':
        return 'With Skating Data';
      case 'performance':
        return 'Top Performers';
      default:
        return 'All Players';
    }
  }

  Widget _buildPlayersList(DeviceType deviceType) {
    if (_filteredPlayers.isEmpty) {
      return _buildEmptyPlayersList();
    }

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
                Icons.people,
                size: ResponsiveConfig.dimension(context, 24),
                color: Colors.blueGrey[700],
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Players',
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
                  '${_filteredPlayers.length}',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        ResponsiveSpacing(multiplier: 2),
        
        // Players layout - responsive grid/list
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            // Desktop/Tablet: Grid layout for better space utilization
            if (deviceType == DeviceType.desktop || 
                (deviceType == DeviceType.tablet && isLandscape)) {
              return _buildPlayersGrid(deviceType);
            }
            
            // Mobile/Tablet Portrait: List layout
            return _buildPlayersListView();
          },
        ),
      ],
    );
  }

  Widget _buildEmptyPlayersList() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: ResponsiveConfig.dimension(context, 64),
            color: Colors.grey[400],
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            _searchQuery.isNotEmpty || _selectedTeamId != null || _selectedFilterType != 'all'
                ? 'No players match your filters'
                : 'No players found',
            baseFontSize: 18,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            'Add your first player to get started',
            baseFontSize: 14,
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersGrid(DeviceType deviceType) {
    final crossAxisCount = deviceType == DeviceType.desktop ? 3 : 2;
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
        mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        return _buildPlayerCard(_filteredPlayers[index], isGrid: true);
      },
    );
  }

  Widget _buildPlayersListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
          child: _buildPlayerCard(_filteredPlayers[index], isGrid: false),
        );
      },
    );
  }

  Widget _buildPlayerCard(Player player, {required bool isGrid}) {
    final appState = Provider.of<AppState>(context, listen: false);
    final team = appState.teams.firstWhere(
      (t) => t.id == player.teamId,
      orElse: () => Team(id: -1, name: 'No Team'),
    );

    final analytics = player.id != null ? _playerAnalytics[player.id!] : null;
    final shootingData = analytics?['shooting'] as Map<String, dynamic>? ?? {};
    final skatingData = analytics?['skating'] as Map<String, dynamic>? ?? {};

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: InkWell(
        onTap: () => _viewPlayerDetails(player),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        child: isGrid ? _buildGridPlayerContent(player, team, shootingData, skatingData) 
                     : _buildListPlayerContent(player, team, shootingData, skatingData),
      ),
    );
  }

  Widget _buildGridPlayerContent(Player player, Team team, Map<String, dynamic> shootingData, Map<String, dynamic> skatingData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Player avatar
        CircleAvatar(
          backgroundColor: Colors.blueGrey[100],
          radius: ResponsiveConfig.dimension(context, 30),
          child: ResponsiveText(
            player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
            ),
          ),
        ),
        
        ResponsiveSpacing(multiplier: 1.5),
        
        // Player name
        ResponsiveText(
          player.name,
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        
        ResponsiveSpacing(multiplier: 0.5),
        
        // Team info
        if (team.name != 'No Team') ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.group,
                size: ResponsiveConfig.dimension(context, 14),
                color: Colors.grey[600],
              ),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                team.name ?? 'Unknown Team',
                baseFontSize: 12,
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 0.5),
        ],
        
        // Position
        if (player.position != null) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_hockey,
                size: ResponsiveConfig.dimension(context, 14),
                color: Colors.grey[600],
              ),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                player.position!,
                baseFontSize: 12,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
        ],
        
        // Performance indicators
        if ((shootingData['total_shots'] as int? ?? 0) > 0 || (skatingData['total_sessions'] as int? ?? 0) > 0) ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((shootingData['total_shots'] as int? ?? 0) > 0)
                _buildPerformanceIndicator(
                  Icons.sports_hockey,
                  Colors.blue,
                  '${((shootingData['overall_success_rate'] as double? ?? 0) * 100).toStringAsFixed(0)}%',
                  'Shot Success',
                ),
              if ((skatingData['total_sessions'] as int? ?? 0) > 0) ...[
                ResponsiveSpacing(multiplier: 0.5),
                _buildPerformanceIndicator(
                  Icons.speed,
                  Colors.green,
                  '${(skatingData['overall_score'] as double? ?? 0).toStringAsFixed(1)}',
                  'Skating Score',
                ),
              ],
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
        ],
        
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
              onPressed: () => _viewPlayerDetails(player),
              tooltip: 'View Details',
            ),
            IconButton(
              icon: Icon(
                Icons.analytics,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onPressed: () => _handlePlayerAction('analytics', player),
              tooltip: 'Analytics',
            ),
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: ResponsiveConfig.dimension(context, 20),
              ),
              onSelected: (action) => _handlePlayerAction(action, player),
              itemBuilder: (context) => _buildPlayerMenuItems(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildListPlayerContent(Player player, Team team, Map<String, dynamic> shootingData, Map<String, dynamic> skatingData) {
    return Row(
      children: [
        // Player avatar and basic info
        Expanded(
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueGrey[100],
                radius: ResponsiveConfig.dimension(context, 24),
                child: ResponsiveText(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  baseFontSize: 18,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[700],
                  ),
                ),
              ),
              ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ResponsiveText(
                      player.name,
                      baseFontSize: 16,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    if (team.name != 'No Team') ...[
                      Row(
                        children: [
                          Icon(
                            Icons.group,
                            size: ResponsiveConfig.dimension(context, 14),
                            color: Colors.grey[600],
                          ),
                          ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                          ResponsiveText(
                            team.name ?? 'Unknown Team',
                            baseFontSize: 12,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                    if (player.position != null) ...[
                      ResponsiveSpacing(multiplier: 0.25),
                      Row(
                        children: [
                          Icon(
                            Icons.sports_hockey,
                            size: ResponsiveConfig.dimension(context, 14),
                            color: Colors.grey[600],
                          ),
                          ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                          ResponsiveText(
                            player.position!,
                            baseFontSize: 12,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Performance indicators
        if ((shootingData['total_shots'] as int? ?? 0) > 0 || (skatingData['total_sessions'] as int? ?? 0) > 0) ...[
          ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Shooting indicator
              if ((shootingData['total_shots'] as int? ?? 0) > 0) ...[
                _buildPerformanceIndicator(
                  Icons.sports_hockey,
                  Colors.blue,
                  '${((shootingData['overall_success_rate'] as double? ?? 0) * 100).toStringAsFixed(0)}%',
                  'Shot Success',
                ),
                ResponsiveSpacing(multiplier: 0.5),
              ],
              
              // Skating indicator
              if ((skatingData['total_sessions'] as int? ?? 0) > 0) ...[
                _buildPerformanceIndicator(
                  Icons.speed,
                  Colors.green,
                  '${(skatingData['overall_score'] as double? ?? 0).toStringAsFixed(1)}',
                  'Skating Score',
                ),
              ],
            ],
          ),
        ],
        
        // Action menu
        PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            size: ResponsiveConfig.dimension(context, 20),
          ),
          onSelected: (action) => _handlePlayerAction(action, player),
          itemBuilder: (context) => _buildPlayerMenuItems(),
        ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildPlayerMenuItems() {
    return [
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
        value: 'edit',
        child: Row(
          children: [
            Icon(Icons.edit, size: 20),
            SizedBox(width: 8),
            Text('Edit'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'analytics',
        child: Row(
          children: [
            Icon(Icons.bar_chart, size: 20),
            SizedBox(width: 8),
            Text('Analytics'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'shot-assessment',
        child: Row(
          children: [
            Icon(Icons.sports_hockey, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text('Shot Assessment'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'skating-assessment',
        child: Row(
          children: [
            Icon(Icons.speed, size: 20, color: Colors.green),
            SizedBox(width: 8),
            Text('Skating Assessment'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem(
        value: 'shot-analysis',
        child: Row(
          children: [
            Icon(Icons.analytics, size: 20, color: Colors.blue),
            SizedBox(width: 8),
            Text('Shot Analysis'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'skating-analysis',
        child: Row(
          children: [
            Icon(Icons.analytics, size: 20, color: Colors.green),
            SizedBox(width: 8),
            Text('Skating Analysis'),
          ],
        ),
      ),
    ];
  }

  // Performance indicator widget
  Widget _buildPerformanceIndicator(IconData icon, Color color, String value, String label) {
    return Container(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: ResponsiveConfig.dimension(context, 14),
            color: color,
          ),
          ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ResponsiveText(
                value,
                baseFontSize: 12,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              ResponsiveText(
                label,
                baseFontSize: 10,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handlePlayerAction(String action, Player player) {
    if (!mounted) return;
    
    try {
      print('PlayersScreen: Handling action: $action for player: ${player.name}');
      final appState = Provider.of<AppState>(context, listen: false);
      
      switch (action) {
        case 'view':
          _viewPlayerDetails(player);
          break;
        case 'edit':
          _editPlayer(player);
          break;
        case 'analytics':
          appState.setSelectedPlayer(player.name);
          _viewPlayerAnalytics(player);
          break;
        case 'shot-assessment':
          appState.setSelectedPlayer(player.name);
          _startShotAssessment(player);
          break;
        case 'skating-assessment':
          appState.setSelectedPlayer(player.name);
          _startSkatingAssessment(player);
          break;
        case 'shot-analysis':
          appState.setSelectedPlayer(player.name);
          _viewShotAnalysis(player);
          break;
        case 'skating-analysis':
          appState.setSelectedPlayer(player.name);
          _viewSkatingAnalysis(player);
          break;
      }
    } catch (e) {
      print('PlayersScreen: Error handling action $action: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _viewPlayerDetails(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to player details for: ${player.name}');
    NavigationService().pushNamed('/player-details', arguments: player);
  }

  void _editPlayer(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to edit player for: ${player.name}');
    NavigationService().pushNamed('/edit-player', arguments: player);
  }

  void _viewPlayerAnalytics(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to analytics for: ${player.name}');
    NavigationService().pushNamed('/analytics', arguments: player);
  }

  void _startShotAssessment(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to shot assessment for: ${player.name}');
    NavigationService().pushNamed('/shot-assessment');
  }

  void _startSkatingAssessment(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to skating assessment for: ${player.name}');
    NavigationService().pushNamed('/skating-assessment');
  }

  void _viewShotAnalysis(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to shot analysis for: ${player.name}');
    NavigationService().pushNamed('/shot-analysis', arguments: player);
  }

  void _viewSkatingAnalysis(Player player) {
    if (!mounted) return;
    print('PlayersScreen: Navigating to skating analysis for: ${player.name}');
    NavigationService().pushNamed('/skating-analysis', arguments: player);
  }

  void _addPlayer() {
    if (!mounted) return;
    print('PlayersScreen: Navigating to add player');
    NavigationService().pushNamed('/player-registration');
  }
}