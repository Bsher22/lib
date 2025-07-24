import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'package:hockey_shot_tracker/utils/extensions.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/common/filterable_player_list.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;

class TeamDetailsScreen extends StatefulWidget {
  const TeamDetailsScreen({Key? key}) : super(key: key);

  @override
  State<TeamDetailsScreen> createState() => _TeamDetailsScreenState();
}

class _TeamDetailsScreenState extends State<TeamDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Team? _team;
  List<Player> _players = [];
  List<User> _coaches = [];
  List<User> _coordinators = [];
  Map<String, dynamic> _teamStats = {};
  bool _isLoading = false;
  bool _isExporting = false;
  bool _isUploading = false;
  File? _logoFile;
  String? _errorMessage;
  
  final GlobalKey _teamStatsKey = GlobalKey();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _tabController.addListener(() {
      setState(() {});
    });
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      
      if (args is Team) {
        setState(() {
          _team = args;
        });
        _loadTeamData(args.id!);
      } else {
        final appState = Provider.of<AppState>(context, listen: false);
        if (appState.selectedTeam != null) {
          setState(() {
            _team = appState.selectedTeam;
          });
          _loadTeamData(appState.selectedTeam!.id!);
        } else {
          setState(() {
            _errorMessage = 'No team selected';
          });
        }
      }
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTeamData(int teamId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final players = await appState.fetchTeamPlayers(teamId);
      
      final Map<int, User> coachMap = {};
      final Map<int, User> coordinatorMap = {};
      
      for (final player in players) {
        if (player.primaryCoachId != null) {
          final coach = appState.coaches.firstWhereOrNull(
            (c) => c.id == player.primaryCoachId,
          );
          if (coach != null) {
            coachMap[coach.id!] = coach;
          }
        }
        
        if (player.coordinatorId != null) {
          final coordinator = appState.coordinators.firstWhereOrNull(
            (c) => c.id == player.coordinatorId,
          );
          if (coordinator != null) {
            coordinatorMap[coordinator.id!] = coordinator;
          }
        }
      }
      
      await _calculateTeamStats(players);
      
      if (mounted) {
        setState(() {
          _players = players;
          _coaches = coachMap.values.toList();
          _coordinators = coordinatorMap.values.toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading team data: $e';
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _calculateTeamStats(List<Player> players) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    int totalShots = 0;
    int successfulShots = 0;
    double totalPower = 0;
    double totalQuickRelease = 0;
    int powerShotCount = 0;
    int quickReleaseCount = 0;
    
    final List<Shot> allShots = [];
    
    for (final player in players) {
      if (player.id != null) {
        try {
          final playerShots = await ApiServiceFactory.shot.fetchShots(player.id!);
          allShots.addAll(playerShots);
        } catch (e) {
          print('Error fetching shots for player ${player.id}: $e');
        }
      }
    }
    
    for (final shot in allShots) {
      totalShots++;
      if (shot.success) {
        successfulShots++;
      }
      
      if (shot.power != null) {
        totalPower += shot.power!;
        powerShotCount++;
      }
      
      if (shot.quickRelease != null) {
        totalQuickRelease += shot.quickRelease!;
        quickReleaseCount++;
      }
    }
    
    final stats = {
      'totalPlayers': players.length,
      'totalShots': totalShots,
      'successfulShots': successfulShots,
      'successRate': totalShots > 0 ? successfulShots / totalShots : 0,
      'avgPower': powerShotCount > 0 ? totalPower / powerShotCount : 0,
      'avgQuickRelease': quickReleaseCount > 0 ? totalQuickRelease / quickReleaseCount : 0,
    };
    
    setState(() {
      _teamStats = stats;
    });
  }
  
  Future<void> _assignPlayerToTeam() async {
    final result = await Navigator.pushNamed(context, '/assign-player', arguments: _team);
    
    if (result == true && _team != null) {
      _loadTeamData(_team!.id!);
    }
  }
  
  Future<void> _editTeam() async {
    if (_team == null) return;
    
    final result = await Navigator.pushNamed(
      context, 
      '/team-form',
      arguments: _team,
    );
    
    if (result == true) {
      final appState = Provider.of<AppState>(context, listen: false);
      _team = appState.selectedTeam;
      if (_team != null) {
        _loadTeamData(_team!.id!);
      }
      setState(() {});
    }
  }
  
  // FIXED: Corrected uploadTeamLogo method call with proper parameters
  Future<void> _uploadLogo() async {
    if (_logoFile == null || _team == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // FIXED: Added missing teamId parameter
      final logoPath = await ApiServiceFactory.team.uploadTeamLogo(
        _team!.id!,
        _logoFile!,
      );
      
      if (logoPath != null && logoPath.isNotEmpty) {
        setState(() {
          _team = _team?.copyWith(logoPath: logoPath);
          _logoFile = null;
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo uploaded successfully')),
        );
      } else {
        setState(() {
          _isUploading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logo upload failed - no path returned'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      if (result == true && _team != null) {
        _loadTeamData(_team!.id!);
      }
    });
  }
  
  void _viewCoachDetails(User coach) {
    Navigator.pushNamed(
      context,
      '/coach-details',
      arguments: coach,
    );
  }
  
  void _viewCoordinatorDetails(User coordinator) {
    Navigator.pushNamed(
      context,
      '/coordinator-details',
      arguments: coordinator,
    );
  }
  
  Future<void> _exportTeamData() async {
    if (_team == null) return;
    
    setState(() {
      _isExporting = true;
    });
    
    try {
      final StringBuffer csvContent = StringBuffer();
      
      csvContent.writeln('Team Report: ${_team!.name}');
      csvContent.writeln('Generated: ${DateTime.now().toIso8601String()}');
      csvContent.writeln('');
      
      csvContent.writeln('Team Statistics:');
      csvContent.writeln('Total Players,${_teamStats['totalPlayers'] ?? 0}');
      csvContent.writeln('Total Shots,${_teamStats['totalShots'] ?? 0}');
      csvContent.writeln('Successful Shots,${_teamStats['successfulShots'] ?? 0}');
      csvContent.writeln('Success Rate,${(_teamStats['successRate'] ?? 0) * 100}%');
      csvContent.writeln('Avg Power,${(_teamStats['avgPower'] ?? 0).toStringAsFixed(2)} mph');
      csvContent.writeln('Avg Quick Release,${(_teamStats['avgQuickRelease'] ?? 0).toStringAsFixed(2)} sec');
      csvContent.writeln('');
      
      csvContent.writeln('Players:');
      csvContent.writeln('Name,Coach,Coordinator,Team');
      for (final player in _players) {
        csvContent.writeln('${player.name},${player.primaryCoachName ?? "None"},${player.coordinatorName ?? "None"},${player.teamName ?? "None"}');
      }
      
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/team_${_team!.name.replaceAll(' ', '_')}_report.csv');
      await file.writeAsString(csvContent.toString());
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Team Report: ${_team!.name}',
        subject: 'Hockey Shot Tracker - Team Report',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting team data: $e')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
  
  Future<void> _shareTeamStats() async {
    try {
      setState(() {
        _isExporting = true;
      });
      
      final boundary = _teamStatsKey.currentContext?.findRenderObject();
      if (boundary != null && boundary is RenderRepaintBoundary) {
        var image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        
        if (byteData == null) {
          throw Exception('Could not convert statistics to image');
        }
        
        final directory = await getTemporaryDirectory();
        final file = File('${directory.path}/${_team!.name.replaceAll(' ', '_')}_stats.png');
        await file.writeAsBytes(byteData.buffer.asUint8List());
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Team Statistics: ${_team!.name}',
          subject: 'Hockey Shot Tracker - Team Statistics',
        );
      } else {
        throw Exception('Could not find statistics section');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing statistics: $e')),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }
  
  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Delete Team?',
      message: 'Are you sure you want to delete the team "${_team!.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );
    
    if (confirmed == true && _team != null) {
      try {
        DialogService.showLoading(
          context,
          message: 'Deleting team...',
        );
        
        await appState.deleteTeam(_team!.id!);
        
        DialogService.hideLoading(context);
        
        await DialogService.showSuccess(
          context,
          title: 'Team Deleted',
          message: 'Team deleted successfully',
        );
        Navigator.of(context).pop(true);
      } catch (e) {
        DialogService.hideLoading(context);
        
        await DialogService.showError(
          context,
          title: 'Error',
          message: 'Error deleting team: $e',
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final userRole = appState.getCurrentUserRole();
    
    final canEdit = userRole == 'admin' || userRole == 'coordinator' || userRole == 'director';
    final canManagePlayers = userRole == 'admin' || userRole == 'coordinator' || userRole == 'director';
    final canDeleteTeam = userRole == 'admin';
    
    if (_team == null) {
      return AdaptiveScaffold(
        title: 'Team Details',
        backgroundColor: Colors.grey[100],
        body: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _errorMessage != null
                ? _buildErrorState()
                : _buildLoadingState();
          },
        ),
      );
    }
    
    return AdaptiveScaffold(
      title: _team!.name,
      backgroundColor: Colors.grey[100],
      actions: [
        IconButton(
          icon: _isExporting 
              ? SizedBox(
                  width: ResponsiveConfig.dimension(context, 24), 
                  height: ResponsiveConfig.dimension(context, 24), 
                  child: CircularProgressIndicator(
                    color: Colors.white, 
                    strokeWidth: ResponsiveConfig.dimension(context, 2),
                  ),
                )
              : const Icon(Icons.share),
          onPressed: _isExporting ? null : _exportTeamData,
          tooltip: 'Export Team Data',
        ),
        if (canEdit)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editTeam,
            tooltip: 'Edit Team',
          ),
        _buildMoreOptionsMenu(canDeleteTeam),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabBar(deviceType),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _buildTabBarView(deviceType, canManagePlayers),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(canManagePlayers),
    );
  }

  Widget _buildErrorState() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ResponsiveCard(
        padding: ResponsiveConfig.paddingAll(context, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_off,
              size: ResponsiveConfig.dimension(context, 64),
              color: Colors.red[400],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Team Not Found',
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
              text: 'Go Back',
              baseHeight: 48,
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              icon: Icons.arrow_back,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ResponsiveCard(
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
              'Loading team data...',
              baseFontSize: 16,
              style: TextStyle(color: Colors.blueGrey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionsMenu(bool canDeleteTeam) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'export':
            _exportTeamData();
            break;
          case 'share_stats':
            _shareTeamStats();
            break;
          case 'delete':
            if (canDeleteTeam) _showDeleteConfirmation(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 8),
              Text('Export Data'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'share_stats',
          child: Row(
            children: [
              Icon(Icons.bar_chart, size: 20),
              SizedBox(width: 8),
              Text('Share Statistics'),
            ],
          ),
        ),
        if (canDeleteTeam) ...[
          const PopupMenuDivider(),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Delete Team',
                  style: TextStyle(color: Colors.red[700]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabBar(DeviceType deviceType) {
    return Container(
      color: Colors.blueGrey[900],
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyanAccent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withOpacity(0.7),
        isScrollable: false,
        labelStyle: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 14),
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: ResponsiveConfig.fontSize(context, 14),
          fontWeight: FontWeight.normal,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Players'),
          Tab(text: 'Staff'),
        ],
      ),
    );
  }

  Widget _buildTabBarView(DeviceType deviceType, bool canManagePlayers) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildOverviewTab(deviceType),
        _buildPlayersTab(canManagePlayers),
        _buildStaffTab(),
      ],
    );
  }
  
  Widget? _buildFloatingActionButton(bool canManagePlayers) {
    if (_tabController.index == 1 && canManagePlayers) {
      return FloatingActionButton.extended(
        onPressed: _assignPlayerToTeam,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        icon: const Icon(Icons.person_add),
        label: ResponsiveText('Assign Player', baseFontSize: 14),
        tooltip: 'Assign Player',
      );
    }
    return null;
  }
  
  Widget _buildOverviewTab(DeviceType deviceType) {
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
            _buildTeamInfoCard(deviceType),
            ResponsiveSpacing(multiplier: 3),
            RepaintBoundary(
              key: _teamStatsKey,
              child: _buildTeamStatistics(deviceType),
            ),
            ResponsiveSpacing(multiplier: 3),
            if (_teamStats['totalShots'] != null && _teamStats['totalShots'] > 0)
              _buildRecentActivity(deviceType),
            ResponsiveSpacing(multiplier: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfoCard(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          if (deviceType == DeviceType.mobile && !isLandscape) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTeamLogo(),
                ResponsiveSpacing(multiplier: 2),
                _buildTeamDetails(),
              ],
            );
          } else {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTeamLogo(),
                ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                Expanded(child: _buildTeamDetails()),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTeamLogo() {
    return Container(
      width: ResponsiveConfig.dimension(context, 100),
      height: ResponsiveConfig.dimension(context, 100),
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
                  Icon(
                    Icons.sports_hockey, 
                    size: ResponsiveConfig.dimension(context, 48), 
                    color: Colors.blueGrey[400],
                  ),
              ),
            )
          : Icon(
              Icons.sports_hockey, 
              size: ResponsiveConfig.dimension(context, 48), 
              color: Colors.blueGrey[400],
            ),
    );
  }

  Widget _buildTeamDetails() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          _team!.name,
          baseFontSize: 24,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (_team!.description != null && _team!.description!.isNotEmpty) ...[
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _team!.description!,
            baseFontSize: 16,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
        ResponsiveSpacing(multiplier: 2),
        Wrap(
          spacing: ResponsiveConfig.spacing(context, 16),
          runSpacing: ResponsiveConfig.spacing(context, 8),
          children: [
            _buildOverviewStat(
              Icons.person, 
              '${_players.length}', 
              'Players'
            ),
            _buildOverviewStat(
              Icons.sports, 
              '${_coaches.length}', 
              'Coaches'
            ),
            _buildOverviewStat(
              Icons.people_alt, 
              '${_coordinators.length}', 
              'Coordinators'
            ),
          ],
        ),
        if (_team!.createdAt != null) ...[
          ResponsiveSpacing(multiplier: 2),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: ResponsiveConfig.dimension(context, 16),
                color: Colors.blueGrey[400],
              ),
              ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
              ResponsiveText(
                'Created on ${_formatDate(_team!.createdAt!)}',
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[500]),
              ),
            ],
          ),
        ],
      ],
    );
  }
  
  Widget _buildOverviewStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: ResponsiveConfig.paddingAll(context, 8),
          decoration: BoxDecoration(
            color: Colors.blueGrey[50],
            borderRadius: ResponsiveConfig.borderRadius(context, 8),
          ),
          child: Icon(
            icon,
            size: ResponsiveConfig.dimension(context, 18),
            color: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              value,
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveText(
              label,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTeamStatistics(DeviceType deviceType) {
    final totalShots = _teamStats['totalShots'] ?? 0;
    final successfulShots = _teamStats['successfulShots'] ?? 0;
    final successRate = _teamStats['successRate'] ?? 0.0;
    final avgPower = _teamStats['avgPower'] ?? 0.0;
    final avgQuickRelease = _teamStats['avgQuickRelease'] ?? 0.0;
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Team Statistics',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareTeamStats,
                tooltip: 'Share Statistics',
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1),
          Divider(color: Colors.blueGrey[100]),
          ResponsiveSpacing(multiplier: 1),
          
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              final crossAxisCount = deviceType == DeviceType.desktop ? 3 : 2;
              
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                childAspectRatio: 2.0,
                mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
                crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
                children: [
                  _buildStatCard(
                    'Total Shots', 
                    totalShots.toString(),
                    Icons.sports_hockey,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    'Successful Shots', 
                    successfulShots.toString(),
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                  _buildStatCard(
                    'Success Rate', 
                    '${(successRate * 100).toStringAsFixed(1)}%',
                    Icons.timeline,
                    Colors.orange,
                  ),
                  _buildStatCard(
                    'Avg Shot Power', 
                    '${avgPower.toStringAsFixed(1)} mph',
                    Icons.bolt,
                    Colors.red,
                  ),
                  _buildStatCard(
                    'Avg Quick Release', 
                    '${avgQuickRelease.toStringAsFixed(2)} sec',
                    Icons.timer,
                    Colors.purple,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: ResponsiveConfig.borderRadius(context, 8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: ResponsiveConfig.dimension(context, 16),
                color: color,
              ),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveText(
                  label,
                  baseFontSize: 12,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.8),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 0.5),
          ResponsiveText(
            value,
            baseFontSize: 18,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivity(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Recent Activity',
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 2),
          
          _buildActivityItem(
            'Team Practice',
            'Yesterday',
            '12 players attended the team practice session.',
            Icons.calendar_today,
            Colors.green,
          ),
          _buildActivityItem(
            'Skill Assessment',
            '3 days ago',
            'Conducted skill assessment for 8 players.',
            Icons.assessment,
            Colors.orange,
          ),
          _buildActivityItem(
            'New Coach Assigned',
            '1 week ago',
            'Coach Michael Smith joined the team.',
            Icons.sports,
            Colors.blue,
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityItem(String title, String time, String description, IconData icon, Color color) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: ResponsiveConfig.dimension(context, 36),
            height: ResponsiveConfig.dimension(context, 36),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: ResponsiveConfig.borderRadius(context, 8),
            ),
            child: Icon(
              icon,
              size: ResponsiveConfig.dimension(context, 20),
              color: color,
            ),
          ),
          ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ResponsiveText(
                        title,
                        baseFontSize: 16,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    ResponsiveText(
                      time,
                      baseFontSize: 12,
                      style: TextStyle(color: Colors.blueGrey[400]),
                    ),
                  ],
                ),
                ResponsiveSpacing(multiplier: 0.5),
                ResponsiveText(
                  description,
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayersTab(bool canManagePlayers) {
    if (_players.isEmpty) {
      return SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people,
                size: ResponsiveConfig.dimension(context, 64),
                color: Colors.grey[400],
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveText(
                'No Players in Team',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ResponsiveText(
                canManagePlayers
                    ? 'Assign players to this team to start tracking their performance'
                    : 'No players have been assigned to this team yet',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
                textAlign: TextAlign.center,
              ),
              if (canManagePlayers) ...[
                ResponsiveSpacing(multiplier: 4),
                ResponsiveButton(
                  text: 'Assign Player',
                  baseHeight: 48,
                  onPressed: _assignPlayerToTeam,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  icon: Icons.person_add,
                ),
              ],
            ],
          ),
        ),
      );
    }
    
    return FilterablePlayerList(
      players: _players,
      onPlayerTap: _viewPlayerDetails,
      onPlayerEditTap: canManagePlayers ? _editPlayer : null,
      showEditButton: canManagePlayers,
      title: 'Team Players',
    );
  }
  
  Widget _buildStaffTab() {
    if (_coaches.isEmpty && _coordinators.isEmpty) {
      return SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: ResponsiveCard(
          padding: ResponsiveConfig.paddingAll(context, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports,
                size: ResponsiveConfig.dimension(context, 64),
                color: Colors.grey[400],
              ),
              ResponsiveSpacing(multiplier: 3),
              ResponsiveText(
                'No Staff Assigned',
                baseFontSize: 20,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ResponsiveText(
                'No coaches or coordinators are currently assigned to this team',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: 1400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_coaches.isNotEmpty) ...[
              ResponsiveText(
                'Coaches (${_coaches.length})',
                baseFontSize: 18,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ...List.generate(_coaches.length, (index) {
                final coach = _coaches[index];
                return Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                  child: _buildStaffCard(coach, 'coach', _viewCoachDetails),
                );
              }),
              ResponsiveSpacing(multiplier: 3),
            ],
            
            if (_coordinators.isNotEmpty) ...[
              ResponsiveText(
                'Coordinators (${_coordinators.length})',
                baseFontSize: 18,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveSpacing(multiplier: 1.5),
              ...List.generate(_coordinators.length, (index) {
                final coordinator = _coordinators[index];
                return Padding(
                  padding: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
                  child: _buildStaffCard(coordinator, 'coordinator', _viewCoordinatorDetails),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStaffCard(User staff, String role, void Function(User) onTap) {
    Color avatarColor;
    IconData roleIcon;
    
    switch (role) {
      case 'coach':
        avatarColor = Colors.green;
        roleIcon = Icons.sports;
        break;
      case 'coordinator':
        avatarColor = Colors.blue;
        roleIcon = Icons.people_alt;
        break;
      case 'director':
        avatarColor = Colors.purple;
        roleIcon = Icons.admin_panel_settings;
        break;
      default:
        avatarColor = Colors.blueGrey;
        roleIcon = Icons.person;
    }
    
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: InkWell(
        onTap: () => onTap(staff),
        borderRadius: ResponsiveConfig.borderRadius(context, 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: ResponsiveConfig.dimension(context, 24),
              backgroundColor: avatarColor.withOpacity(0.2),
              child: ResponsiveText(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                baseFontSize: 20,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: avatarColor,
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
                    staff.name,
                    baseFontSize: 16,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveText(
                    staff.email,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.blueGrey[600]),
                  ),
                ],
              ),
            ),
            Container(
              padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: avatarColor.withOpacity(0.1),
                borderRadius: ResponsiveConfig.borderRadius(context, 16),
                border: Border.all(color: avatarColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    roleIcon,
                    size: ResponsiveConfig.dimension(context, 14),
                    color: avatarColor,
                  ),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    role[0].toUpperCase() + role.substring(1),
                    baseFontSize: 12,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: avatarColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}