import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/pdf_report_service.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_shot/team_shot_setup_view.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_shot/team_shot_execution_view.dart';
import 'package:hockey_shot_tracker/widgets/core/state/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// Main screen that coordinates between setup and execution
/// This shows how to properly integrate the grid-based execution view
class TeamShotAssessmentScreen extends StatefulWidget {
  const TeamShotAssessmentScreen({Key? key}) : super(key: key);

  @override
  _TeamShotAssessmentScreenState createState() => _TeamShotAssessmentScreenState();
}

class _TeamShotAssessmentScreenState extends State<TeamShotAssessmentScreen> {
  // Assessment phase management
  AssessmentPhase _currentPhase = AssessmentPhase.setup;
  bool _isLoading = false;

  Map<String, dynamic>? _assessment;
  List<Player> _selectedPlayers = [];
  Map<String, Map<int, List<Map<String, dynamic>>>> _playerShotResults = {};

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Team Shot Assessment',
      backgroundColor: Colors.grey[100],
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: _getLoadingMessage(),
        color: Colors.cyanAccent,
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return Column(
              children: [
                _buildPhaseIndicator(deviceType),
                Expanded(child: _buildPhaseContent(deviceType, isLandscape)),
              ],
            );
          },
        ),
      ),
    );
  }

  String _getLoadingMessage() {
    switch (_currentPhase) {
      case AssessmentPhase.setup:
        return 'Preparing assessment...';
      case AssessmentPhase.execution:
        return 'Processing shot data...';
      case AssessmentPhase.results:
        return 'Generating results...';
    }
  }

  Widget _buildPhaseIndicator(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 12),
      margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: AssessmentPhase.values.asMap().entries.map((entry) {
          final phase = entry.value;
          final index = entry.key;
          final isActive = phase == _currentPhase;
          final isCompleted = _getPhaseIndex(phase) < _getPhaseIndex(_currentPhase);
          
          return Row(
            children: [
              _buildPhaseStep(phase, isActive, isCompleted, deviceType),
              if (index < AssessmentPhase.values.length - 1)
                Container(
                  width: ResponsiveConfig.dimension(context, 40),
                  height: 2,
                  margin: ResponsiveConfig.paddingSymmetric(context, horizontal: 8),
                  color: isCompleted ? Colors.green : Colors.grey[300],
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPhaseStep(AssessmentPhase phase, bool isActive, bool isCompleted, DeviceType deviceType) {
    final stepSize = ResponsiveConfig.dimension(context, 32);
    
    return Column(
      children: [
        Container(
          width: stepSize,
          height: stepSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.green : (isActive ? Colors.cyanAccent : Colors.grey[300]),
          ),
          child: Center(
            child: isCompleted
              ? Icon(Icons.check, color: Colors.white, size: ResponsiveConfig.iconSize(context, 16))
              : ResponsiveText(
                  '${_getPhaseIndex(phase) + 1}',
                  baseFontSize: 14,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black87 : Colors.grey[600],
                  ),
                ),
          ),
        ),
        ResponsiveSpacing(multiplier: 0.5),
        ResponsiveText(
          _getPhaseTitle(phase),
          baseFontSize: 12,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.blueGrey[800] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPhaseContent(DeviceType deviceType, bool isLandscape) {
    switch (_currentPhase) {
      case AssessmentPhase.setup:
        return _buildSetupPhase(deviceType, isLandscape);
      case AssessmentPhase.execution:
        return _buildExecutionPhase(deviceType, isLandscape);
      case AssessmentPhase.results:
        return _buildResultsPhase(deviceType, isLandscape);
    }
  }

  Widget _buildSetupPhase(DeviceType deviceType, bool isLandscape) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: ConstrainedBox(
        constraints: ResponsiveConfig.constraints(
          context,
          maxWidth: deviceType == DeviceType.desktop ? 800 : null,
        ),
        child: TeamShotSetupView(
          onStart: _startAssessment,
        ),
      ),
    );
  }

  Widget _buildExecutionPhase(DeviceType deviceType, bool isLandscape) {
    if (_assessment == null || _selectedPlayers.isEmpty) {
      return Center(
        child: ResponsiveText(
          'Assessment data not available',
          baseFontSize: 16,
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return TeamShotExecutionView(
      assessment: _assessment!,
      players: _selectedPlayers,
      playerShotResults: _playerShotResults,
      onAddResult: _addShotResult,
      onComplete: _completeAssessment,
    );
  }

  Widget _buildResultsPhase(DeviceType deviceType, bool isLandscape) {
    if (deviceType == DeviceType.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _buildMainResultsContent(),
          ),
          Container(
            width: ResponsiveConfig.dimension(context, 320),
            child: _buildResultsSidebar(),
          ),
        ],
      );
    } else {
      return _buildMainResultsContent();
    }
  }

  Widget _buildMainResultsContent() {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          ResponsiveSpacing(multiplier: 3),
          _buildSummaryStats(),
          ResponsiveSpacing(multiplier: 3),
          _buildPlayerResults(),
          ResponsiveSpacing(multiplier: 3),
          _buildGroupSummaries(),
          ResponsiveSpacing(multiplier: 4),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    final totalShots = _calculateTotalShots();
    final successfulShots = _calculateSuccessfulShots();
    final overallSuccessRate = totalShots > 0 ? (successfulShots / totalShots * 100) : 0.0;

    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 20),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events,
            size: ResponsiveConfig.iconSize(context, 64),
            color: Colors.amber,
          ),
          ResponsiveSpacing(multiplier: 2),
          ResponsiveText(
            'Assessment Complete!',
            baseFontSize: 24,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            _assessment?['title'] ?? 'Team Assessment',
            baseFontSize: 18,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildOverallSuccessIndicator(overallSuccessRate),
        ],
      ),
    );
  }

  Widget _buildOverallSuccessIndicator(double successRate) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up,
            color: _getSuccessRateColor(successRate),
            size: ResponsiveConfig.iconSize(context, 32),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Column(
            children: [
              ResponsiveText(
                '${successRate.toStringAsFixed(1)}%',
                baseFontSize: 28,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getSuccessRateColor(successRate),
                ),
              ),
              ResponsiveText(
                'Team Success Rate',
                baseFontSize: 14,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    final totalShots = _calculateTotalShots();
    final successfulShots = _calculateSuccessfulShots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Summary Statistics',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            final statsPerRow = deviceType.responsive<int>(
              mobile: isLandscape ? 4 : 2,
              tablet: 4,
              desktop: 4,
            );
            
            return Wrap(
              spacing: ResponsiveConfig.spacing(context, 12),
              runSpacing: ResponsiveConfig.spacing(context, 12),
              children: _getStatistics().map((stat) => SizedBox(
                width: _calculateStatCardWidth(context, statsPerRow),
                child: _buildStatCard(stat['label'], stat['value'], stat['icon'], stat['color']),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  double _calculateStatCardWidth(BuildContext context, int statsPerRow) {
    final screenWidth = MediaQuery.of(context).size.width;
    final totalPadding = ResponsiveConfig.spacing(context, 32);
    final totalSpacing = ResponsiveConfig.spacing(context, 12) * (statsPerRow - 1);
    return (screenWidth - totalPadding - totalSpacing) / statsPerRow;
  }

  List<Map<String, dynamic>> _getStatistics() {
    return [
      {
        'label': 'Team',
        'value': _assessment?['teamName'] ?? 'Unknown',
        'icon': Icons.group,
        'color': Colors.blue,
      },
      {
        'label': 'Players',
        'value': '${_selectedPlayers.length}',
        'icon': Icons.people,
        'color': Colors.green,
      },
      {
        'label': 'Total Shots',
        'value': '${_calculateTotalShots()}',
        'icon': Icons.sports_hockey,
        'color': Colors.purple,
      },
      {
        'label': 'Success Rate',
        'value': '${(_calculateTotalShots() > 0 ? (_calculateSuccessfulShots() / _calculateTotalShots() * 100) : 0.0).toStringAsFixed(1)}%',
        'icon': Icons.trending_up,
        'color': _getSuccessRateColor(_calculateTotalShots() > 0 ? (_calculateSuccessfulShots() / _calculateTotalShots() * 100) : 0.0),
      },
    ];
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        children: [
          Icon(icon, size: ResponsiveConfig.iconSize(context, 32), color: color),
          ResponsiveSpacing(multiplier: 1),
          ResponsiveText(
            value,
            baseFontSize: 20,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          ResponsiveText(
            label,
            baseFontSize: 12,
            style: TextStyle(color: Colors.blueGrey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Player Results',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            if (deviceType == DeviceType.mobile && !isLandscape) {
              // Mobile Portrait: List layout
              return Column(
                children: _selectedPlayers.map((player) => _buildPlayerCard(player)).toList(),
              );
            } else {
              // Tablet/Desktop: Grid layout
              final columnsCount = deviceType == DeviceType.desktop ? 2 : 1;
              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columnsCount,
                  childAspectRatio: 3.0,
                  crossAxisSpacing: ResponsiveConfig.spacing(context, 16),
                  mainAxisSpacing: ResponsiveConfig.spacing(context, 16),
                ),
                itemCount: _selectedPlayers.length,
                itemBuilder: (context, index) => _buildPlayerCard(_selectedPlayers[index]),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Player player) {
    final playerId = player.id.toString();
    final playerResults = _playerShotResults[playerId] ?? {};

    int playerTotalShots = 0;
    int playerSuccessfulShots = 0;

    for (var groupResults in playerResults.values) {
      for (var shot in groupResults) {
        playerTotalShots++;
        if (shot['success'] == true) {
          playerSuccessfulShots++;
        }
      }
    }

    final playerSuccessRate = playerTotalShots > 0
        ? (playerSuccessfulShots / playerTotalShots * 100)
        : 0.0;

    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        children: [
          CircleAvatar(
            radius: ResponsiveConfig.dimension(context, 20),
            backgroundColor: Colors.blueGrey[200],
            child: ResponsiveText(
              player.jerseyNumber?.toString() ?? '?',
              baseFontSize: 14,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  player.name,
                  baseFontSize: 16,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  player.position ?? 'Unknown Position',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ResponsiveText(
                '$playerSuccessfulShots/$playerTotalShots',
                baseFontSize: 16,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveText(
                '${playerSuccessRate.toStringAsFixed(1)}%',
                baseFontSize: 14,
                style: TextStyle(
                  color: _getSuccessRateColor(playerSuccessRate),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
          ResponsiveButton(
            text: 'PDF',
            onPressed: () => _exportSinglePlayerPDF(player),
            baseHeight: 36,
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
            prefix: Icon(Icons.download, size: ResponsiveConfig.iconSize(context, 16), color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupSummaries() {
    final groups = _assessment?['groups'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Assessment Groups',
          baseFontSize: 20,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        ResponsiveSpacing(multiplier: 2),
        ...groups.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final group = entry.value as Map<String, dynamic>;
          return _buildGroupSummaryCard(groupIndex, group);
        }).toList(),
      ],
    );
  }

  Widget _buildGroupSummaryCard(int groupIndex, Map<String, dynamic> group) {
    int groupTotalShots = 0;
    int groupSuccessfulShots = 0;

    for (var playerResults in _playerShotResults.values) {
      final groupResults = playerResults[groupIndex] ?? [];
      for (var shot in groupResults) {
        groupTotalShots++;
        if (shot['success'] == true) {
          groupSuccessfulShots++;
        }
      }
    }

    final groupSuccessRate = groupTotalShots > 0
        ? (groupSuccessfulShots / groupTotalShots * 100)
        : 0.0;

    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Row(
        children: [
          Container(
            width: ResponsiveConfig.dimension(context, 40),
            height: ResponsiveConfig.dimension(context, 40),
            decoration: BoxDecoration(
              color: Colors.cyanAccent[700],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: ResponsiveText(
                '${groupIndex + 1}',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  group['name'] as String? ?? group['title'] as String? ?? 'Group ${groupIndex + 1}',
                  baseFontSize: 16,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveText(
                  group['location'] as String? ?? 'Location not specified',
                  baseFontSize: 12,
                  style: TextStyle(color: Colors.blueGrey[600]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ResponsiveText(
                '$groupSuccessfulShots/$groupTotalShots',
                baseFontSize: 16,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ResponsiveText(
                '${groupSuccessRate.toStringAsFixed(1)}%',
                baseFontSize: 14,
                style: TextStyle(
                  color: _getSuccessRateColor(groupSuccessRate),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        if (deviceType == DeviceType.mobile && !isLandscape) {
          // Mobile Portrait: Stack vertically
          return Column(
            children: [
              ResponsiveButton(
                text: 'Export All Results',
                onPressed: _exportResults,
                baseHeight: 48,
                width: double.infinity,
                backgroundColor: Colors.blueGrey[700],
                foregroundColor: Colors.white,
                prefix: Icon(Icons.download, color: Colors.white),
              ),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveButton(
                text: 'New Assessment',
                onPressed: _resetAssessment,
                baseHeight: 48,
                width: double.infinity,
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black87,
                prefix: Icon(Icons.refresh, color: Colors.black87),
              ),
            ],
          );
        } else {
          // Tablet/Desktop: Side by side
          return Row(
            children: [
              Expanded(
                child: ResponsiveButton(
                  text: 'Export All Results',
                  onPressed: _exportResults,
                  baseHeight: 48,
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  prefix: Icon(Icons.download, color: Colors.white),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: ResponsiveButton(
                  text: 'New Assessment',
                  onPressed: _resetAssessment,
                  baseHeight: 48,
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  prefix: Icon(Icons.refresh, color: Colors.black87),
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildResultsSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SingleChildScrollView(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ResponsiveText(
              'Quick Actions',
              baseFontSize: 18,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            ResponsiveSpacing(multiplier: 3),
            ResponsiveButton(
              text: 'Share Results',
              onPressed: _shareResults,
              baseHeight: 48,
              width: double.infinity,
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
              prefix: Icon(Icons.share, color: Colors.white),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveButton(
              text: 'Export PDFs',
              onPressed: _exportResults,
              baseHeight: 48,
              width: double.infinity,
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              prefix: Icon(Icons.picture_as_pdf, color: Colors.white),
            ),
            ResponsiveSpacing(multiplier: 4),
            _buildAssessmentInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentInfo() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResponsiveText(
            'Assessment Info',
            baseFontSize: 14,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildInfoRow('Team', _assessment?['teamName'] ?? 'Unknown'),
          _buildInfoRow('Type', _assessment?['type'] ?? 'Team Assessment'),
          _buildInfoRow('Players', '${_selectedPlayers.length}'),
          _buildInfoRow('Total Shots', '${_calculateTotalShots()}'),
          _buildInfoRow('Date', DateTime.now().toString().split(' ')[0]),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: ResponsiveConfig.paddingSymmetric(context, vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: ResponsiveConfig.dimension(context, 70),
            child: ResponsiveText(
              '$label:',
              baseFontSize: 12,
              style: TextStyle(
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ResponsiveText(
              value,
              baseFontSize: 12,
              style: TextStyle(color: Colors.blue[800]),
            ),
          ),
        ],
      ),
    );
  }

  void _startAssessment(Map<String, dynamic> assessment, List<Player> players) {
    print('TeamShotAssessmentScreen - Starting assessment');
    print('Assessment: $assessment');
    print('Players: ${players.map((p) => p.name).toList()}');

    setState(() {
      _assessment = assessment;
      _selectedPlayers = players;
      _currentPhase = AssessmentPhase.execution;

      // Initialize player shot results
      _playerShotResults = {};
      for (var player in players) {
        _playerShotResults[player.id.toString()] = {};
      }
    });
  }

  void _addShotResult(String playerId, int groupIndex, Map<String, dynamic> shotData) {
    setState(() {
      _playerShotResults[playerId] ??= {};
      _playerShotResults[playerId]![groupIndex] ??= [];
      _playerShotResults[playerId]![groupIndex]!.add(shotData);
    });

    print('Added shot result for player $playerId, group $groupIndex: $shotData');
  }

  void _completeAssessment() async {
    setState(() {
      _isLoading = true;
    });

    // Save assessment to backend
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      for (var player in _selectedPlayers) {
        final playerId = player.id.toString();
        final playerResults = _playerShotResults[playerId] ?? {};
        final shots = playerResults.values.expand((group) => group).toList();

        if (shots.isNotEmpty) {
          final assessmentData = {
            'player_id': playerId,
            'assessment_type': _assessment?['type'] ?? 'team',
            'title': _assessment?['title'] ?? 'Team Shot Assessment',
            'description': _assessment?['description'] ?? 'Team assessment for ${player.name}',
            'shots': shots.map((shot) => {
                  ...shot,
                  'player_id': playerId,
                  'timestamp': shot['timestamp'] ?? DateTime.now().toIso8601String(),
                }).toList(),
          };

          await apiService.saveShotAssessment(assessmentData, context: context);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _currentPhase = AssessmentPhase.results;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _getSuccessRateColor(double rate) {
    if (rate >= 80) return Colors.green;
    if (rate >= 60) return Colors.lightGreen;
    if (rate >= 40) return Colors.orange;
    if (rate >= 20) return Colors.deepOrange;
    return Colors.red;
  }

  int _calculateTotalShots() {
    int total = 0;
    for (var playerResults in _playerShotResults.values) {
      for (var groupResults in playerResults.values) {
        total += groupResults.length;
      }
    }
    return total;
  }

  int _calculateSuccessfulShots() {
    int successful = 0;
    for (var playerResults in _playerShotResults.values) {
      for (var groupResults in playerResults.values) {
        for (var shot in groupResults) {
          if (shot['success'] == true) {
            successful++;
          }
        }
      }
    }
    return successful;
  }

  void _shareResults() {
    // Use the same export functionality but with sharing focus
    _exportResults();
  }

  void _exportSinglePlayerPDF(Player player) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final playerId = player.id.toString();
      final playerResults = _playerShotResults[playerId] ?? {};

      // Convert data for PDF generation
      final playerAssessment = _createPlayerAssessmentData(player, playerResults);
      final playerShotResults = _convertToShotResultsFormat(playerResults);

      // Generate PDF
      final pdfData = await PdfReportService.generateShotAssessmentPDF(
        player: player,
        assessment: playerAssessment,
        results: _calculatePlayerResults(playerResults),
        shotResults: playerShotResults,
      );

      final fileName = 'shot_assessment_${player.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Share/Download PDF
      await PdfReportService.sharePDF(pdfData, fileName);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF for ${player.name} ready for download/sharing!'),
          backgroundColor: Colors.green[700],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF for ${player.name}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _exportResults() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final List<Map<String, dynamic>> generatedPDFs = [];

      // Generate PDF for each player
      for (final player in _selectedPlayers) {
        final playerId = player.id.toString();
        final playerResults = _playerShotResults[playerId] ?? {};

        // Convert team assessment data to format expected by PDF service
        final playerAssessment = _createPlayerAssessmentData(player, playerResults);
        final playerShotResults = _convertToShotResultsFormat(playerResults);

        // Generate PDF
        final pdfData = await PdfReportService.generateShotAssessmentPDF(
          player: player,
          assessment: playerAssessment,
          results: _calculatePlayerResults(playerResults),
          shotResults: playerShotResults,
        );

        generatedPDFs.add({
          'player': player,
          'pdfData': pdfData,
          'fileName': 'shot_assessment_${player.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf',
        });
      }

      // Show download options
      _showPDFDownloadOptions(generatedPDFs);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDFs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _createPlayerAssessmentData(Player player, Map<int, List<Map<String, dynamic>>> playerResults) {
    return {
      'type': _assessment?['type'] ?? 'Team Assessment',
      'title': 'Individual Shot Assessment - ${player.name}',
      'description': 'Results from team assessment: ${_assessment?['title'] ?? 'Assessment'}',
      'date': _assessment?['timestamp'] ?? DateTime.now().toIso8601String(),
      'teamName': _assessment?['teamName'] ?? 'Team',
      'groups': _assessment?['groups'] ?? [],
    };
  }

  Map<int, List<Map<String, dynamic>>> _convertToShotResultsFormat(Map<int, List<Map<String, dynamic>>> playerResults) {
    // The format is already correct for the PDF service
    return playerResults;
  }

  Map<String, dynamic> _calculatePlayerResults(Map<int, List<Map<String, dynamic>>> playerResults) {
    int totalShots = 0;
    int successfulShots = 0;
    Map<String, int> zoneSuccesses = {};
    Map<String, int> zoneAttempts = {};
    Map<String, int> typeSuccesses = {};
    Map<String, int> typeAttempts = {};
    List<String> strengths = [];
    List<String> improvements = [];

    // Calculate statistics
    for (var groupResults in playerResults.values) {
      for (var shot in groupResults) {
        totalShots++;
        final isSuccess = shot['success'] == true;
        final zone = shot['zone'] as String? ?? 'Unknown';
        final type = shot['type'] as String? ?? 'Unknown';

        if (isSuccess) successfulShots++;

        // Zone stats
        zoneAttempts[zone] = (zoneAttempts[zone] ?? 0) + 1;
        if (isSuccess) {
          zoneSuccesses[zone] = (zoneSuccesses[zone] ?? 0) + 1;
        }

        // Type stats
        typeAttempts[type] = (typeAttempts[type] ?? 0) + 1;
        if (isSuccess) {
          typeSuccesses[type] = (typeSuccesses[type] ?? 0) + 1;
        }
      }
    }

    // Calculate zone rates
    Map<String, double> zoneRates = {};
    for (var zone in zoneAttempts.keys) {
      final attempts = zoneAttempts[zone] ?? 0;
      if (attempts > 0) {
        zoneRates[zone] = (zoneSuccesses[zone] ?? 0) / attempts;
      } else {
        zoneRates[zone] = 0.0;
      }
    }

    // Calculate type rates
    Map<String, double> typeRates = {};
    for (var type in typeAttempts.keys) {
      final attempts = typeAttempts[type] ?? 0;
      if (attempts > 0) {
        typeRates[type] = (typeSuccesses[type] ?? 0) / attempts;
      } else {
        typeRates[type] = 0.0;
      }
    }

    // Generate strengths and improvements
    final overallRate = totalShots > 0 ? successfulShots / totalShots : 0.0;

    // Find best performing zones/types for strengths
    zoneRates.forEach((zone, rate) {
      if (rate >= 0.7) {
        strengths.add('Excellent accuracy in zone $zone (${(rate * 100).toStringAsFixed(0)}%)');
      }
    });

    typeRates.forEach((type, rate) {
      if (rate >= 0.7) {
        strengths.add('Strong $type shooting (${(rate * 100).toStringAsFixed(0)}% success rate)');
      }
    });

    // Find areas for improvement
    zoneRates.forEach((zone, rate) {
      if (rate < 0.4) {
        improvements.add('Practice shots targeting zone $zone');
      }
    });

    typeRates.forEach((type, rate) {
      if (rate < 0.4) {
        improvements.add('Work on $type technique and accuracy');
      }
    });

    // Add general improvements if none specific
    if (improvements.isEmpty) {
      if (overallRate < 0.6) {
        improvements.add('Focus on shot accuracy and consistency');
        improvements.add('Practice shooting from various positions');
      }
    }

    if (strengths.isEmpty) {
      strengths.add('Completed full team assessment');
      if (overallRate >= 0.5) {
        strengths.add('Demonstrates solid shooting fundamentals');
      }
    }

    return {
      'totalShots': totalShots,
      'overallScore': overallRate * 10, // Convert to 0-10 scale
      'overallRate': overallRate,
      'categoryScores': {
        'Accuracy': overallRate * 10,
        'Consistency': _calculateConsistency(playerResults) * 10,
        'Zone Coverage': (zoneRates.length / 9) * 10, // Based on zones hit
      },
      'zoneRates': zoneRates,
      'typeRates': typeRates,
      'strengths': strengths,
      'improvements': improvements,
    };
  }

  double _calculateConsistency(Map<int, List<Map<String, dynamic>>> playerResults) {
    List<double> groupRates = [];

    for (var groupResults in playerResults.values) {
      if (groupResults.isNotEmpty) {
        final successCount = groupResults.where((shot) => shot['success'] == true).length;
        groupRates.add(successCount / groupResults.length);
      }
    }

    if (groupRates.isEmpty) return 0.0;

    // Calculate standard deviation (lower = more consistent)
    final mean = groupRates.reduce((a, b) => a + b) / groupRates.length;
    final variance = groupRates.map((rate) => (rate - mean) * (rate - mean)).reduce((a, b) => a + b) / groupRates.length;
    final stdDev = variance <= 0 ? 0.0 : 1.0 - (variance.clamp(0.0, 1.0)); // Invert so higher = more consistent

    return stdDev;
  }

  void _showPDFDownloadOptions(List<Map<String, dynamic>> generatedPDFs) {
    showDialog(
      context: context,
      builder: (context) => AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.download, color: Colors.green),
                ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
                ResponsiveText('Player Assessment PDFs', baseFontSize: 18),
              ],
            ),
            content: SizedBox(
              width: deviceType.responsive<double>(
                mobile: double.maxFinite,
                tablet: 500,
                desktop: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    'Generated ${generatedPDFs.length} individual assessment reports',
                    baseFontSize: 16,
                    style: TextStyle(color: Colors.blueGrey[700]),
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  Container(
                    constraints: BoxConstraints(maxHeight: ResponsiveConfig.dimension(context, 300)),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: generatedPDFs.length,
                      itemBuilder: (context, index) {
                        final pdfInfo = generatedPDFs[index];
                        final player = pdfInfo['player'] as Player;

                        return ResponsiveCard(
                          margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: ResponsiveText(
                                player.jerseyNumber?.toString() ?? '?',
                                baseFontSize: 14,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                            title: ResponsiveText(player.name, baseFontSize: 14),
                            subtitle: ResponsiveText('${player.position ?? 'Player'} • Individual Assessment Report', baseFontSize: 12),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: () => _sharePDF(pdfInfo),
                                  tooltip: 'Share PDF',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadPDF(pdfInfo),
                                  tooltip: 'Download PDF',
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: ResponsiveText('Close', baseFontSize: 14),
              ),
              ResponsiveButton(
                text: 'Share All',
                onPressed: () => _shareAllPDFs(generatedPDFs),
                baseHeight: 40,
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                prefix: Icon(Icons.share, color: Colors.white),
              ),
            ],
          );
        },
      ),
    );
  }

  void _sharePDF(Map<String, dynamic> pdfInfo) {
    PdfReportService.sharePDF(
      pdfInfo['pdfData'],
      pdfInfo['fileName'],
    );
  }

  void _downloadPDF(Map<String, dynamic> pdfInfo) {
    // For now, use the share functionality which allows saving
    _sharePDF(pdfInfo);
  }

  void _shareAllPDFs(List<Map<String, dynamic>> generatedPDFs) {
    // Share each PDF individually
    for (final pdfInfo in generatedPDFs) {
      _sharePDF(pdfInfo);
    }

    Navigator.of(context).pop(); // Close dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${generatedPDFs.length} assessment reports...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _resetAssessment() {
    setState(() {
      _currentPhase = AssessmentPhase.setup;
      _assessment = null;
      _selectedPlayers = [];
      _playerShotResults = {};
    });
  }

  // Helper methods
  int _getPhaseIndex(AssessmentPhase phase) {
    return AssessmentPhase.values.indexOf(phase);
  }

  String _getPhaseTitle(AssessmentPhase phase) {
    switch (phase) {
      case AssessmentPhase.setup:
        return 'Setup';
      case AssessmentPhase.execution:
        return 'Execute';
      case AssessmentPhase.results:
        return 'Results';
    }
  }
}

// Assessment phase enum
enum AssessmentPhase { setup, execution, results }