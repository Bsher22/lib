// Fixed lib/widgets/domain/assessment/shot/shot_assessment_results_screen.dart
// Change: generateProgressReport called with no args, but requires 1 positional. Added required parameters.

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/services/index.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/shot/shot_result_summary_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/shot/shot_result_details_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/shot/shot_result_recommendations_tab.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_results_display.dart';
import 'package:hockey_shot_tracker/widgets/core/state/loading_overlay.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/shot_assessment.dart';
import 'package:get_it/get_it.dart';
import 'package:hockey_shot_tracker/services/pdf_report_service.dart';
import 'package:hockey_shot_tracker/screens/pdf/pdf_preview_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ShotAssessmentResultsScreen extends StatefulWidget {
  final Map<String, dynamic> assessment;
  final Map<String, List<Map<String, dynamic>>> shotResults;
  final VoidCallback onReset;
  final VoidCallback onSave;
  final int? playerId;
  final String? assessmentId;

  const ShotAssessmentResultsScreen({
    Key? key,
    required this.assessment,
    required this.shotResults,
    required this.onReset,
    required this.onSave,
    this.playerId,
    this.assessmentId,
  }) : super(key: key);

  @override
  _ShotAssessmentResultsScreenState createState() => _ShotAssessmentResultsScreenState();
}

class _ShotAssessmentResultsScreenState extends State<ShotAssessmentResultsScreen> {
  Map<String, dynamic>? _results;
  bool _isLoading = true;
  bool _isGeneratingProgressReport = false;
  String? _errorMessage;
  final getIt = GetIt.instance;
  late Map<String, dynamic> _localAssessment;
  
  // Progress report state
  List<ShotAssessment> _availableAssessments = [];
  ShotAssessment? _selectedBaseline;
  List<ShotAssessment> _selectedMiniAssessments = [];
  bool _showProgressOptions = false;

  @override
  void initState() {
    super.initState();
    print('Assessment data: ${widget.assessment}');
    print('ShotResults data: ${widget.shotResults}');
    print('Player ID: ${widget.playerId}');
    print('Assessment ID: ${widget.assessmentId}');
    _localAssessment = Map<String, dynamic>.from(widget.assessment);
    _loadResults();
    _loadAvailableAssessments();
  }

  Future<void> _loadResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Validate and preprocess assessment groups
      final groups = (_localAssessment['groups'] as List? ?? []).map((group) {
        final groupMap = group as Map<String, dynamic>? ?? {};
        final groupName = groupMap['name'] as String? ?? groupMap['title'] as String? ?? 'Group ${groupMap['id'] ?? 'Unknown'}';
        if (groupMap['name'] == null && groupMap['title'] == null) {
          print('Group at index ${groupMap['id'] ?? 'Unknown'} lacks name or title: $groupMap');
        }
        return {
          'name': groupName,
          'shots': groupMap['shots'] ?? 0,
          'location': groupMap['location'] as String? ?? 'Unknown',
          'defaultType': groupMap['defaultType'] is String && (groupMap['defaultType'] as String).isNotEmpty
              ? groupMap['defaultType']
              : 'Wrist Shot',
          ...groupMap,
        };
      }).toList();
      _localAssessment['groups'] = groups;

      if (groups.isEmpty) {
        print('Warning: assessment.groups is empty or null');
      }

      final Map<int, List<Shot>> shotResultsForCalc = widget.shotResults.map((key, shots) {
        try {
          final parsedKey = int.parse(key);
          final validShots = shots.where((shot) {
            final hasRequiredFields = shot['zone'] is String &&
                shot['type'] is String &&
                shot['success'] is bool &&
                (shot['outcome'] == null || shot['outcome'] is String) &&
                (shot['timestamp'] == null || shot['timestamp'] is String);
            if (!hasRequiredFields) {
              print('Invalid shot data: $shot');
            }
            return hasRequiredFields;
          }).map<Shot>((shot) {
            return Shot(
              id: DateTime.now().millisecondsSinceEpoch,
              playerId: widget.playerId ?? parsedKey,
              zone: shot['zone'] as String? ?? '0',
              type: shot['type'] as String? ?? 'Wrist',
              success: shot['success'] as bool,
              outcome: shot['outcome'] as String? ?? (shot['success'] as bool ? 'Goal' : 'Miss'),
              power: (shot['power'] as num?)?.toDouble(),
              quickRelease: (shot['quick_release'] as num?)?.toDouble(),
              timestamp: DateTime.parse(shot['timestamp'] as String? ?? DateTime.now().toIso8601String()),
              source: 'assessment',
              assessmentId: shot['assessment_id'] as String? ?? widget.assessmentId,
              groupIndex: shot['group_index'] as int?,
              groupId: shot['group_id'] as String?,
              intendedZone: shot['intended_zone'] as String?,
            );
          }).toList();

          return MapEntry(parsedKey, validShots);
        } catch (e) {
          print('Error processing shot results for key $key: $e');
          return MapEntry(int.parse(key), <Shot>[]);
        }
      });

      final calculatedResults = AssessmentShotUtils.calculateResults(
        _localAssessment,
        shotResultsForCalc,
      );

      setState(() {
        _results = calculatedResults;
        _isLoading = false;
      });
    } catch (error) {
      print('Error loading results: $error');
      setState(() {
        _errorMessage = 'Failed to load assessment results: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadAvailableAssessments() async {
    if (widget.playerId == null) return;

    try {
      final assessments = await ApiService(baseUrl: 'http://localhost:5000')
          .getPlayerShotAssessments(widget.playerId!, status: 'completed', context: context);
      
      setState(() {
        _availableAssessments = assessments;
      });
    } catch (e) {
      print('Error loading available assessments: $e');
    }
  }

  Future<void> _generatePDF() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final resultsForPdf = Map<int, List<Map<String, dynamic>>>.from(
        widget.shotResults.map(
          (key, shots) => MapEntry(
            int.parse(key),
            shots.map((shot) => Map<String, dynamic>.from(shot)).toList(),
          ),
        ),
      );

      final pdfData = await PdfReportService.generateShotAssessmentPDF(
        player: Player(
          id: widget.playerId,
          name: _localAssessment['playerName'] as String? ?? 'Unknown Player',
          createdAt: DateTime.now(),
        ),
        assessment: _localAssessment,
        results: _results!,
        shotResults: resultsForPdf,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFPreviewScreen(
              pdfData: pdfData,
              fileName:
                  'shot_assessment_${_localAssessment['playerName'] as String? ?? 'Player'}_${DateTime.now().millisecondsSinceEpoch}.pdf',
            ),
          ),
        );
      }
    } catch (error) {
      print('Error generating PDF: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _generateProgressReport() async {
    if (widget.playerId == null || _selectedBaseline == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a baseline assessment first')),
      );
      return;
    }

    setState(() {
      _isGeneratingProgressReport = true;
    });

    try {
      final baselineDate = _selectedBaseline!.date;
      final currentDate = DateTime.now();
      final daysDiff = currentDate.difference(baselineDate).inDays;
      final progressPeriod = daysDiff <= 7 
          ? '$daysDiff-day progress' 
          : daysDiff <= 30 
              ? '${(daysDiff / 7).round()}-week progress'
              : '${(daysDiff / 30).round()}-month progress';

      // FIXED: Added required parameters to generateProgressReport
      final response = await ApiService(baseUrl: 'http://localhost:5000')
          .generateProgressReport(
            widget.playerId ?? 0,
            options: {
              'assessmentId': widget.assessmentId,
              'baselineAssessmentId': _selectedBaseline!.id,
              'miniAssessmentIds': _selectedMiniAssessments.map((a) => a.id).toList(),
              'progressPeriod': progressPeriod,
              'includeCharts': true,
              'includeRecommendations': true,
              'format': 'detailed',
              'reportType': 'shot_assessment_progress',
              'comparisonType': 'baseline_vs_mini',
            },
          );

      await _handleProgressReportPDF(response);

    } catch (error) {
      print('Error generating progress report: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate progress report: $error'),
            backgroundColor: Colors.red,
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

  Future<void> _handleProgressReportPDF(dynamic pdfData) async {
    try {
      Uint8List pdfBytes;
      
      if (pdfData is Uint8List) {
        pdfBytes = pdfData;
      } else if (pdfData is List<int>) {
        pdfBytes = Uint8List.fromList(pdfData);
      } else {
        throw Exception('Invalid PDF data format');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName = 'progress_report_${_localAssessment['playerName']?.toString().replaceAll(' ', '_') ?? 'player'}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);

      await Share.shareXFiles([XFile(file.path)], text: 'Hockey Progress Report');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress report generated successfully!'),
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

  void _showProgressReportDialog() {
    showDialog(
      context: context,
      builder: (context) => AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              title: ResponsiveText(
                'Generate Progress Report',
                baseFontSize: 18,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: deviceType.responsive<double>(
                  mobile: MediaQuery.of(context).size.width * 0.9,
                  tablet: 500,
                  desktop: 600,
                ),
                child: SingleChildScrollView(
                  child: _buildProgressReportContent(deviceType, isLandscape, setDialogState),
                ),
              ),
              actions: _buildProgressReportActions(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressReportContent(DeviceType deviceType, bool isLandscape, StateSetter setDialogState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResponsiveText(
          'Select a baseline assessment to compare against:',
          baseFontSize: 14,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 2),
        _buildBaselineSelector(deviceType, setDialogState),
        ResponsiveSpacing(multiplier: 2),
        if (_selectedBaseline != null) ...[
          ResponsiveText(
            'Mini-assessments to include (optional):',
            baseFontSize: 14,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 1),
          _buildMiniAssessmentSelector(deviceType, setDialogState),
          ResponsiveSpacing(multiplier: 2),
        ],
        _buildProgressReportInfo(),
      ],
    );
  }

  Widget _buildBaselineSelector(DeviceType deviceType, StateSetter setDialogState) {
    return Container(
      padding: ResponsiveConfig.paddingSymmetric(
        context,
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ShotAssessment>(
          value: _selectedBaseline,
          hint: ResponsiveText('Select baseline assessment', baseFontSize: 14),
          isExpanded: true,
          items: _availableAssessments.map((assessment) {
            return DropdownMenuItem<ShotAssessment>(
              value: assessment,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    assessment.title,
                    baseFontSize: 14,
                    style: TextStyle(fontWeight: FontWeight.bold),
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
              _selectedMiniAssessments.clear();
            });
          },
        ),
      ),
    );
  }

  Widget _buildMiniAssessmentSelector(DeviceType deviceType, StateSetter setDialogState) {
    return Container(
      height: deviceType.responsive<double>(
        mobile: 120,
        tablet: 150,
        desktop: 180,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView(
        children: _availableAssessments
            .where((a) => a.date.isAfter(_selectedBaseline!.date) && a.id != widget.assessmentId)
            .map((assessment) {
          final isSelected = _selectedMiniAssessments.contains(assessment);
          return CheckboxListTile(
            title: ResponsiveText(
              assessment.title,
              baseFontSize: 13,
            ),
            subtitle: ResponsiveText(
              'Date: ${assessment.date.toString().split(' ')[0]}',
              baseFontSize: 11,
            ),
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
    );
  }

  Widget _buildProgressReportInfo() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: ResponsiveConfig.iconSize(context, 16)),
              ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
              ResponsiveText(
                'Progress Report Features:',
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
            '• Group-specific progress tracking\n'
            '• Zone accuracy improvements\n'
            '• Training recommendations\n'
            '• Timeline visualization\n'
            '• Professional PDF report',
            baseFontSize: 11,
            style: TextStyle(color: Colors.blue[800]),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildProgressReportActions() {
    return [
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
        baseHeight: 40,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        prefix: Icon(Icons.trending_up, color: Colors.white),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AdaptiveScaffold(
        title: 'Assessment Results',
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.cyanAccent),
              ResponsiveSpacing(multiplier: 2),
              ResponsiveText(
                'Loading assessment results...',
                baseFontSize: 16,
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return AdaptiveScaffold(
        title: 'Assessment Results',
        backgroundColor: Colors.grey[100],
        body: Center(
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(context, maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveConfig.iconSize(context, 80),
                    color: Colors.red[300],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    _errorMessage!,
                    baseFontSize: 16,
                    style: TextStyle(color: Colors.red[700]),
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveButton(
                    text: 'Retry',
                    onPressed: _loadResults,
                    baseHeight: 48,
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black87,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (widget.playerId == null) {
      return AdaptiveScaffold(
        title: 'Assessment Results',
        backgroundColor: Colors.grey[100],
        body: Center(
          child: ResponsiveText(
            'Error: Player ID is missing',
            baseFontSize: 16,
            style: TextStyle(color: Colors.red[700]),
          ),
        ),
      );
    }

    final resultsForDetails = widget.shotResults.map((key, shots) {
      try {
        return MapEntry(int.parse(key), shots);
      } catch (e) {
        print('Error parsing key $key: $e');
        return MapEntry(0, shots);
      }
    });

    return AdaptiveScaffold(
      title: _localAssessment['title'] as String? ?? 'Assessment Results',
      backgroundColor: Colors.grey[100],
      body: LoadingOverlay(
        isLoading: _isGeneratingProgressReport,
        message: 'Generating Progress Report...\nAnalyzing group performance and creating PDF',
        color: Colors.cyanAccent,
        backgroundColor: Colors.black.withOpacity(0.7),
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return _buildResultsLayout(deviceType, isLandscape, resultsForDetails);
          },
        ),
      ),
      floatingActionButton: _buildResponsiveFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildResultsLayout(
    DeviceType deviceType, 
    bool isLandscape, 
    Map<int, List<Map<String, dynamic>>> resultsForDetails
  ) {
    if (deviceType == DeviceType.desktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: _buildMainResultsDisplay(resultsForDetails),
          ),
          Container(
            width: ResponsiveConfig.dimension(context, 320),
            child: _buildDesktopSidebar(),
          ),
        ],
      );
    } else {
      return _buildMainResultsDisplay(resultsForDetails);
    }
  }

  Widget _buildMainResultsDisplay(Map<int, List<Map<String, dynamic>>> resultsForDetails) {
    return AssessmentResultsDisplay(
      title: _localAssessment['title'] as String? ?? 'Shot Assessment Results',
      subjectName: _localAssessment['playerName'] as String? ?? 'Unknown Player',
      subjectType: 'player',
      overallScore: (_results?['overallScore'] as num?)?.toDouble() ?? 0.0,
      performanceLevel: _results?['performanceLevel'] as String? ?? 'Not Rated',
      scoreColorProvider: AssessmentShotUtils.getScoreColor,
      tabs: _buildResultTabs(resultsForDetails),
      onReset: widget.onReset,
      onSave: _handleSave,
      onExportPdf: _generatePDF,
    );
  }

  Widget _buildDesktopSidebar() {
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
            _buildQuickActionButtons(),
            ResponsiveSpacing(multiplier: 4),
            _buildAssessmentInfoCard(),
            ResponsiveSpacing(multiplier: 4),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    return Column(
      children: [
        ResponsiveButton(
          text: 'Export PDF',
          onPressed: _generatePDF,
          baseHeight: 48,
          width: double.infinity,
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
          prefix: Icon(Icons.picture_as_pdf, color: Colors.white),
        ),
        ResponsiveSpacing(multiplier: 1),
        if (_availableAssessments.length >= 2)
          ResponsiveButton(
            text: 'Progress Report',
            onPressed: _showProgressReportDialog,
            baseHeight: 48,
            width: double.infinity,
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            prefix: Icon(Icons.trending_up, color: Colors.white),
          ),
      ],
    );
  }

  Widget _buildAssessmentInfoCard() {
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
          _buildInfoRow('Player', _localAssessment['playerName'] as String? ?? 'Unknown'),
          _buildInfoRow('Type', _localAssessment['type'] as String? ?? 'Unknown'),
          _buildInfoRow('Date', DateTime.now().toString().split(' ')[0]),
          if (_localAssessment['totalShots'] != null)
            _buildInfoRow('Total Shots', _localAssessment['totalShots'].toString()),
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
            width: ResponsiveConfig.dimension(context, 80),
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

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: ResponsiveButton(
            text: 'New Assessment',
            onPressed: widget.onReset,
            baseHeight: 40,
            backgroundColor: Colors.grey[200],
            foregroundColor: Colors.blueGrey[700],
          ),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        Expanded(
          child: ResponsiveButton(
            text: 'Save',
            onPressed: _handleSave,
            baseHeight: 40,
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black87,
            prefix: Icon(Icons.save, color: Colors.black87),
          ),
        ),
      ],
    );
  }

  Widget? _buildResponsiveFloatingActionButton() {
    // Don't show FAB on desktop (uses sidebar buttons)
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        if (deviceType == DeviceType.desktop) return SizedBox.shrink();
        
        if (_availableAssessments.length >= 2) {
          return FloatingActionButton.extended(
            onPressed: _showProgressReportDialog,
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            icon: const Icon(Icons.trending_up),
            label: ResponsiveText(
              deviceType == DeviceType.mobile ? 'Progress' : 'Progress Report',
              baseFontSize: 14,
            ),
          );
        }
        
        return SizedBox.shrink();
      },
    );
  }

  Future<void> _handleSave() async {
    try {
      widget.onSave();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save assessment: $e')),
        );
      }
    }
  }

  List<AssessmentResultTab> _buildResultTabs(Map<int, List<Map<String, dynamic>>> resultsForDetails) {
    return [
      AssessmentResultTab(
        label: 'Summary',
        contentBuilder: (context) => ShotResultSummaryTab(
          results: _results!,
          playerId: widget.playerId!,
        ),
      ),
      AssessmentResultTab(
        label: 'Details',
        contentBuilder: (context) => ShotResultDetailsTab(
          assessment: _localAssessment,
          results: _results!,
          shotResults: resultsForDetails,
        ),
      ),
      AssessmentResultTab(
        label: 'Recommendations',
        contentBuilder: (context) => ShotResultRecommendationsTab(
          results: _results!,
          playerId: widget.playerId,
          assessmentId: widget.assessmentId,
        ),
      ),
    ];
  }
}