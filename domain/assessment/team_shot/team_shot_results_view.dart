// lib/widgets/domain/assessment/team_shot/team_shot_results_view.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_results_display.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_shot/team_shot_summary_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_shot/team_shot_details_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/team_shot/team_shot_recommendations_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/analysis/metrics/stat_item_card.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';

/// A unified results view for team shot assessments with responsive design
class TeamShotResultsView extends StatefulWidget {
  final Map<String, dynamic> assessment; // Changed from ShotAssessment to Map
  final int teamId;
  final String teamName;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final Map<String, Map<int, List<Map<String, dynamic>>>> playerShotResults; // Changed from ShotResult to Map
  
  const TeamShotResultsView({
    Key? key,
    required this.assessment,
    required this.teamId,
    required this.teamName,
    required this.onReset,
    required this.onSave,
    required this.playerShotResults,
  }) : super(key: key);

  @override
  _TeamShotResultsViewState createState() => _TeamShotResultsViewState();
}

class _TeamShotResultsViewState extends State<TeamShotResultsView> {
  bool _isLoading = true;
  bool _isGeneratingProgressReport = false;
  Map<String, dynamic> _teamMetrics = {};
  List<Player> _players = [];
  Map<String, Map<String, dynamic>> _playerResults = {}; // Changed from ShotAssessmentResults to Map
  String? _error;
  
  // Progress report state (like shot files)
  List<ShotAssessment> _availableAssessments = [];
  ShotAssessment? _selectedBaseline;
  List<ShotAssessment> _selectedMiniAssessments = [];
  late ApiService _apiService;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(baseUrl: ApiConfig.baseUrl);
    _fetchTeamMetrics();
    _loadAvailableAssessments(); // Like shot files
  }

  Future<void> _fetchTeamMetrics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch team metrics from API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analytics/team/${widget.teamId}/metrics?metric_type=shot'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Fetch players
        final playersResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/teams/${widget.teamId}/players'),
          headers: await ApiConfig.getHeaders(),
        );
        
        if (playersResponse.statusCode == 200) {
          final playersData = json.decode(playersResponse.body);
          final List<Player> players = [];
          
          for (var playerData in playersData['players']) {
            players.add(Player.fromJson(playerData));
          }
          
          setState(() {
            _teamMetrics = data['team_averages'];
            _playerResults = _convertPlayerResults(data['player_results']); // Fixed to use shot file pattern
            _players = players;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load team players';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load team metrics';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      
      // Enhanced error handling like shot files
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading team metrics: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Convert API response to Map objects using shot file pattern
  Map<String, Map<String, dynamic>> _convertPlayerResults(Map<String, dynamic> apiResults) {
    final Map<String, Map<String, dynamic>> results = {};
    
    for (var entry in apiResults.entries) {
      final playerId = entry.key;
      final playerData = entry.value as Map<String, dynamic>;
      
      if (playerData.containsKey('shot_analytics')) {
        final analytics = playerData['shot_analytics'] as Map<String, dynamic>;
        final playerName = playerData['player_name'] as String;
        
        // Use AssessmentShotUtils.createResultsFromAnalytics like shot files
        results[playerId] = AssessmentShotUtils.createResultsFromAnalytics(
          analytics, 
          playerName: playerName,
        );
        
        // Add additional fields
        results[playerId]!['position'] = playerData['position'];
        results[playerId]!['zoneMetrics'] = analytics['zone_metrics'] ?? {};
        results[playerId]!['shotTypeMetrics'] = analytics['shot_type_metrics'] ?? {};
        results[playerId]!['totalShots'] = analytics['total_shots'] ?? 0;
      }
    }
    
    return results;
  }

  // Load available assessments for progress reports (like shot files)
  Future<void> _loadAvailableAssessments() async {
    try {
      // For team assessments, we need to get assessments for all players
      List<ShotAssessment> allAssessments = [];
      
      for (var player in _players) {
        if (player.id != null) {
          final assessments = await _apiService.getPlayerShotAssessments(
            player.id!, 
            status: 'completed', 
            context: context
          );
          allAssessments.addAll(assessments);
        }
      }
      
      setState(() {
        _availableAssessments = allAssessments;
      });
    } catch (e) {
      print('Error loading available assessments: $e');
      // Don't throw error, just log it as this is optional functionality
    }
  }

  // Generate progress report functionality (like shot files)
  Future<void> _generateProgressReport() async {
    if (_selectedBaseline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a baseline assessment first')),
      );
      return;
    }

    setState(() {
      _isGeneratingProgressReport = true;
    });

    try {
      // Generate progress period description
      final baselineDate = _selectedBaseline!.date;
      final currentDate = DateTime.now();
      final daysDiff = currentDate.difference(baselineDate).inDays;
      final progressPeriod = daysDiff <= 7 
          ? '$daysDiff-day progress' 
          : daysDiff <= 30 
              ? '${(daysDiff / 7).round()}-week progress'
              : '${(daysDiff / 30).round()}-month progress';

      // Call backend API to generate team progress report
      final response = await _apiService.generateTeamProgressReport(
        teamId: widget.teamId,
        baselineAssessmentId: _selectedBaseline!.id,
        miniAssessmentIds: _selectedMiniAssessments.map((a) => a.id).toList(),
        progressPeriod: progressPeriod,
        context: context,
      );

      // Handle the PDF response
      await _handleProgressReportPDF(response);

    } catch (error) {
      print('Error generating team progress report: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate progress report: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGeneratingProgressReport = false;
        });
      }
    }
  }

  // Handle progress report PDF (like shot files)
  Future<void> _handleProgressReportPDF(dynamic pdfData) async {
    try {
      Uint8List pdfBytes;
      
      // Handle different response types
      if (pdfData is Uint8List) {
        pdfBytes = pdfData;
      } else if (pdfData is List<int>) {
        pdfBytes = Uint8List.fromList(pdfData);
      } else {
        throw Exception('Invalid PDF data format');
      }

      // Save to temporary file and share
      final tempDir = await getTemporaryDirectory();
      final fileName = 'team_progress_report_${widget.teamName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles([XFile(file.path)], text: 'Team Hockey Progress Report');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team progress report generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      print('Error handling progress report PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing progress report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Show progress report dialog (like shot files)
  void _showProgressReportDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: ResponsiveText('Generate Team Progress Report', baseFontSize: 18),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ResponsiveText(
                  'Select a baseline assessment to compare against:',
                  baseFontSize: 14,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                
                // Baseline assessment selector
                Container(
                  padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: ResponsiveConfig.borderRadius(context, 8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<ShotAssessment>(
                      value: _selectedBaseline,
                      hint: ResponsiveText('Select baseline team assessment', baseFontSize: 14),
                      isExpanded: true,
                      items: _availableAssessments.map((assessment) {
                        return DropdownMenuItem<ShotAssessment>(
                          value: assessment,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ResponsiveText(
                                '${assessment.title} - ${widget.teamName}',
                                baseFontSize: 14,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              ResponsiveText(
                                'Date: ${assessment.date.toString().split(' ')[0]}',
                                baseFontSize: 12,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (assessment) {
                        setDialogState(() {
                          _selectedBaseline = assessment;
                          _selectedMiniAssessments.clear(); // Reset mini-assessments
                        });
                      },
                    ),
                  ),
                ),
                
                ResponsiveSpacing(multiplier: 2),
                
                if (_selectedBaseline != null) ...[
                  ResponsiveText(
                    'Team mini-assessments to include (optional):',
                    baseFontSize: 14,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: ResponsiveConfig.borderRadius(context, 8),
                    ),
                    child: ListView(
                      children: _availableAssessments
                          .where((a) => a.date.isAfter(_selectedBaseline!.date) && a.id != widget.assessment['assessmentId'])
                          .map((assessment) {
                        final isSelected = _selectedMiniAssessments.contains(assessment);
                        return CheckboxListTile(
                          title: ResponsiveText('${assessment.title} - ${widget.teamName}', baseFontSize: 14),
                          subtitle: ResponsiveText('Date: ${assessment.date.toString().split(' ')[0]}', baseFontSize: 12),
                          value: isSelected,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                _selectedMiniAssessments.add(assessment);
                              } else {
                                _selectedMiniAssessments.remove(assessment);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
                
                ResponsiveSpacing(multiplier: 2),
                Container(
                  padding: ResponsiveConfig.paddingAll(context, 12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: ResponsiveConfig.borderRadius(context, 8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 16)),
                          ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                          ResponsiveText(
                            'Team Progress Report Features:',
                            baseFontSize: 12,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      ResponsiveSpacing(multiplier: 1),
                      ResponsiveText(
                        '• Team-wide performance analysis\n'
                        '• Individual player improvements\n'
                        '• Group-specific progress tracking\n'
                        '• Coaching recommendations\n'
                        '• Professional PDF report',
                        baseFontSize: 11,
                        style: TextStyle(color: Colors.blue[800]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: ResponsiveText('Cancel', baseFontSize: 14),
            ),
            ResponsiveButton(
              text: 'Generate Report',
              onPressed: _selectedBaseline != null
                  ? () {
                      Navigator.pop(context);
                      _generateProgressReport();
                    }
                  : null,
              baseHeight: 48,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: ResponsiveConfig.iconSize(context, 64),
              color: Colors.red[300],
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveText(
              'Error Loading Team Results',
              baseFontSize: 20,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              _error!,
              baseFontSize: 14,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            ResponsiveSpacing(multiplier: 2),
            ResponsiveButton(
              text: 'Retry',
              onPressed: _fetchTeamMetrics,
              baseHeight: 48,
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
      );
    }

    final teamScore = _teamMetrics.containsKey('overall_success_rate') 
        ? (_teamMetrics['overall_success_rate'] as num).toDouble() * 10
        : 0.0;
    
    return Scaffold(
      body: Stack(
        children: [
          // Use AssessmentResultsDisplay with responsive header
          AssessmentResultsDisplay(
            title: '${widget.assessment['title'] as String? ?? 'Shot Assessment'} - Team Results',
            subjectName: widget.teamName,
            subjectType: 'team',
            overallScore: teamScore, // Already converted to 0-10 scale
            performanceLevel: _getTeamPerformanceLevel(teamScore / 10), // Convert back to 0-1 scale for func
            scoreColorProvider: AssessmentShotUtils.getScoreColor,
            headerContent: _buildResponsiveHeader(),
            tabs: [
              AssessmentResultTab(
                label: 'Summary',
                contentBuilder: (context) => TeamShotSummaryTab(
                  teamName: widget.teamName,
                  players: _players,
                  playerResults: _playerResults,
                  teamAverages: _teamMetrics,
                  playerShotResults: widget.playerShotResults,
                ),
              ),
              AssessmentResultTab(
                label: 'Details',
                contentBuilder: (context) => TeamShotDetailsTab(
                  assessment: widget.assessment,
                  players: _players,
                  playerResults: _playerResults,
                ),
              ),
              AssessmentResultTab(
                label: 'Recommendations',
                contentBuilder: (context) => TeamShotRecommendationsTab(
                  teamName: widget.teamName,
                  playerResults: _playerResults,
                  teamAverages: _teamMetrics,
                ),
              ),
            ],
            onReset: widget.onReset,
            onSave: () async {
              try {
                widget.onSave();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Team assessment saved successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save assessment: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            actionBuilder: _buildResponsiveActions,
          ),
          
          // Progress report loading overlay (like shot files)
          if (_isGeneratingProgressReport)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    ResponsiveSpacing(multiplier: 2),
                    ResponsiveText(
                      'Generating Team Progress Report...',
                      baseFontSize: 16,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 1),
                    ResponsiveText(
                      'Analyzing team performance and creating PDF',
                      baseFontSize: 14,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      
      // Responsive FloatingActionButton for Progress Report (like shot files)
      floatingActionButton: _availableAssessments.length >= 2
          ? AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                switch (deviceType) {
                  case DeviceType.mobile:
                    return FloatingActionButton(
                      onPressed: _showProgressReportDialog,
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.trending_up),
                    );
                  case DeviceType.tablet:
                    return FloatingActionButton.extended(
                      onPressed: _showProgressReportDialog,
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.trending_up),
                      label: ResponsiveText('Progress Report', baseFontSize: 14),
                    );
                  case DeviceType.desktop:
                    return FloatingActionButton.extended(
                      onPressed: _showProgressReportDialog,
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      icon: const Icon(Icons.trending_up),
                      label: ResponsiveText('Team Progress Report', baseFontSize: 14),
                    );
                }
              },
            )
          : null,
    );
  }

  // Responsive header content (team stats)
  Widget _buildResponsiveHeader() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileHeader();
          case DeviceType.tablet:
            return _buildTabletHeader();
          case DeviceType.desktop:
            return _buildDesktopHeader();
        }
      },
    );
  }

  Widget _buildMobileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: StatItemCard(
                label: 'Players',
                value: '${_players.length}',
                icon: Icons.people,
                color: Colors.blue,
              ),
            ),
            ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
            Expanded(
              child: StatItemCard(
                label: 'Total Shots',
                value: '${_calculateTotalShots()}',
                icon: Icons.sports_hockey,
                color: Colors.green,
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 1),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: StatItemCard(
                label: 'Success Rate',
                value: '${_calculateAverageSuccessRate().toStringAsFixed(1)}%',
                icon: Icons.check_circle,
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: StatItemCard(
            label: 'Players',
            value: '${_players.length}',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
        Expanded(
          child: StatItemCard(
            label: 'Total Shots',
            value: '${_calculateTotalShots()}',
            icon: Icons.sports_hockey,
            color: Colors.green,
          ),
        ),
        ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
        Expanded(
          child: StatItemCard(
            label: 'Success Rate',
            value: '${_calculateAverageSuccessRate().toStringAsFixed(1)}%',
            icon: Icons.check_circle,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: StatItemCard(
            label: 'Players',
            value: '${_players.length}',
            icon: Icons.people,
            color: Colors.blue,
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          child: StatItemCard(
            label: 'Total Shots',
            value: '${_calculateTotalShots()}',
            icon: Icons.sports_hockey,
            color: Colors.green,
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          child: StatItemCard(
            label: 'Success Rate',
            value: '${_calculateAverageSuccessRate().toStringAsFixed(1)}%',
            icon: Icons.check_circle,
            color: Colors.orange,
          ),
        ),
        ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
        Expanded(
          child: StatItemCard(
            label: 'Assessment Type',
            value: widget.assessment['category'] as String? ?? 'Standard',
            icon: Icons.assessment,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  // Responsive action builder for enhanced desktop features
  Widget? _buildResponsiveActions(BuildContext context) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return null; // No additional actions for mobile
          case DeviceType.tablet:
            return _buildTabletActions();
          case DeviceType.desktop:
            return _buildDesktopActions();
        }
      },
    );
  }

  Widget _buildTabletActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveButton(
          text: 'Export',
          onPressed: _exportTeamResults,
          baseHeight: 48,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.download, size: 16),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveButton(
          text: 'Share',
          onPressed: _shareTeamResults,
          baseHeight: 48,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.share, size: 16),
        ),
      ],
    );
  }

  Widget _buildDesktopActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveButton(
          text: 'Export Results',
          onPressed: _exportTeamResults,
          baseHeight: 48,
          backgroundColor: Colors.blue[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.download, size: 16),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveButton(
          text: 'Share Team Report',
          onPressed: _shareTeamResults,
          baseHeight: 48,
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.share, size: 16),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveButton(
          text: 'Schedule Follow-up',
          onPressed: _scheduleFollowUpAssessment,
          baseHeight: 48,
          backgroundColor: Colors.purple[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.schedule, size: 16),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveButton(
          text: 'Training Plan',
          onPressed: _createTeamTrainingPlan,
          baseHeight: 48,
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
          icon: const Icon(Icons.fitness_center, size: 16),
        ),
      ],
    );
  }

  int _calculateTotalShots() {
    int total = 0;
    for (var playerResult in _playerResults.values) {
      total += playerResult['totalShots'] as int? ?? 0;
    }
    return total;
  }
  
  double _calculateAverageSuccessRate() {
    return (_teamMetrics['overall_success_rate'] as double? ?? 0.0) * 100;
  }
  
  String _getTeamPerformanceLevel(double score) {
    if (score >= 0.85) return 'Elite';
    if (score >= 0.75) return 'Excellent';
    if (score >= 0.65) return 'Good';
    if (score >= 0.55) return 'Average';
    if (score >= 0.45) return 'Fair';
    if (score >= 0.35) return 'Needs Improvement';
    return 'Developing';
  }

  // Desktop-only action methods
  void _exportTeamResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export team results - Coming Soon')),
    );
  }

  void _shareTeamResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share team results - Coming Soon')),
    );
  }

  void _scheduleFollowUpAssessment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule follow-up assessment - Coming Soon')),
    );
  }

  void _createTeamTrainingPlan() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create team training plan - Coming Soon')),
    );
  }
}