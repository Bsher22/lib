// Fixed lib/services/progress_pdf_service.dart
// Changes:
// - Changed withOpacity to PdfColor.fromHex or manual alpha, since PdfColor doesn't have withOpacity. Used PdfColors.green100 etc for opacity.
// - Added missing _formatDate method

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/pdf_report_service.dart';
import 'package:intl/intl.dart';

class ProgressPDFService {
  /// Generate a Progress Assessment PDF comparing full assessment baseline with mini-assessment results
  static Future<Uint8List> generateProgressReportPDF({
    required Player player,
    required Map<String, dynamic> baselineAssessment,
    required Map<String, dynamic> baselineResults,
    required List<Map<String, dynamic>> miniAssessments, // List of mini-assessments with results
    String? progressPeriod,
  }) async {
    final pdf = pw.Document();
    
    // Calculate progress metrics with targeted group analysis
    final progressAnalysis = _calculateProgressMetrics(
      baselineResults, 
      miniAssessments,
      baselineAssessment, // Pass the full baseline assessment for group matching
    );
    final overallProgress = progressAnalysis['overallProgress'] as double;
    final categoryProgress = progressAnalysis['categoryProgress'] as Map<String, double>;
    final zoneProgress = progressAnalysis['zoneProgress'] as Map<String, double>;
    final recommendations = progressAnalysis['recommendations'] as List<String>;
    
    // Format dates
    final baselineDate = DateTime.parse(baselineAssessment['date'] as String? ?? DateTime.now().toIso8601String());
    final latestDate = miniAssessments.isNotEmpty 
        ? DateTime.parse(miniAssessments.last['date'] as String? ?? DateTime.now().toIso8601String())
        : DateTime.now();
    final formattedBaselineDate = _formatDate(baselineAssessment['date']);
    final formattedLatestDate = _formatDate(miniAssessments.isNotEmpty ? miniAssessments.last['date'] : DateTime.now().toIso8601String());
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildProgressHeader(player, formattedBaselineDate, formattedLatestDate, progressPeriod),
        build: (context) => [
          // Progress Overview
          _buildProgressOverview(overallProgress, miniAssessments.length),
          
          // Progress Timeline
          _buildProgressTimeline(baselineAssessment, miniAssessments),
          
          // Category Progress Analysis
          _buildCategoryProgressSection(categoryProgress, baselineResults, miniAssessments),
          
          // Zone Progress Analysis (for shot assessments)
          if (baselineResults.containsKey('zoneRates'))
            _buildZoneProgressSection(zoneProgress, baselineResults, miniAssessments),
          
          // Detailed Mini-Assessment Results
          _buildMiniAssessmentDetails(miniAssessments),
          
          // Progress Insights & Recommendations
          _buildProgressInsights(recommendations, progressAnalysis),
          
          // Next Steps
          _buildNextStepsSection(progressAnalysis),
        ],
        footer: (context) => _buildFooter(context),
      ),
    );
    
    return pdf.save();
  }
  
  /// Format date string for display
  static String _formatDate(dynamic dateInput) {
    try {
      DateTime date;
      if (dateInput is String) {
        date = DateTime.parse(dateInput);
      } else if (dateInput is DateTime) {
        date = dateInput;
      } else {
        date = DateTime.now();
      }
      return DateFormat('MMM d, yyyy').format(date);
    } catch (e) {
      print('Error formatting date: $e');
      return DateFormat('MMM d, yyyy').format(DateTime.now());
    }
  }
  
  static pw.Widget _buildProgressHeader(Player player, String baselineDate, String latestDate, String? period) {
    return pw.Header(
      level: 0,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'HIRE Hockey', 
                    style: pw.TextStyle(
                      fontSize: 24, 
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                      font: pw.Font.helvetica(),
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Progress Development Report', 
                    style: pw.TextStyle(
                      fontSize: 18,
                      color: PdfColors.green700,
                      fontWeight: pw.FontWeight.bold,
                      font: pw.Font.helvetica(),
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Player: ${player.name}', 
                    style: pw.TextStyle(
                      fontSize: 14,
                      font: pw.Font.helvetica(),
                    ),
                  ),
                  pw.Text(
                    'Baseline: $baselineDate → Latest: $latestDate', 
                    style: pw.TextStyle(
                      fontSize: 12, 
                      color: PdfColors.grey700,
                      font: pw.Font.helvetica(),
                    ),
                  ),
                  if (period != null)
                    pw.Text(
                      'Period: $period', 
                      style: pw.TextStyle(
                        fontSize: 12, 
                        color: PdfColors.grey700,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                ],
              ),
              // Progress indicator icon
              pw.Container(
                height: 80,
                width: 80,
                decoration: pw.BoxDecoration(
                  color: PdfColors.green100, // FIXED: Used PdfColors.green100 instead of withOpacity
                  border: pw.Border.all(color: PdfColors.green300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Center(
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        '📈', 
                        style: pw.TextStyle(fontSize: 24),
                      ),
                      pw.Text(
                        'PROGRESS', 
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green700,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            height: 1,
            color: PdfColors.blue300,
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildProgressOverview(double overallProgress, int miniAssessmentCount) {
    final progressColor = overallProgress >= 0 ? PdfColors.green : PdfColors.orange;
    final progressText = overallProgress >= 0 ? 'IMPROVEMENT' : 'NEEDS FOCUS';
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Progress Overview',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Row(
            children: [
              // Overall progress indicator
              pw.Expanded(
                flex: 2,
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(progressColor.red, progressColor.green, progressColor.blue, 0.1), // FIXED: Used PdfColor constructor with alpha
                    border: pw.Border.all(color: progressColor),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        '${overallProgress >= 0 ? '+' : ''}${overallProgress.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: progressColor,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        progressText,
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: progressColor,
                          font: pw.Font.helvetica(),
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Overall Performance Change',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                          font: pw.Font.helvetica(),
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 20),
              // Assessment count
              pw.Expanded(
                child: pw.Column(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            '$miniAssessmentCount',
                            style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue700,
                              font: pw.Font.helvetica(),
                            ),
                          ),
                          pw.Text(
                            'Mini-Assessments',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.blue600,
                              font: pw.Font.helvetica(),
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildProgressTimeline(Map<String, dynamic> baseline, List<Map<String, dynamic>> miniAssessments) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Progress Timeline',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                // Baseline
                pw.Row(
                  children: [
                    pw.Container(
                      width: 12,
                      height: 12,
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.blue700,
                        shape: pw.BoxShape.circle,
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Text(
                        'Baseline Assessment: ${baseline['title'] ?? 'Full Assessment'}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Text(
                      _formatDate(baseline['date']),
                      style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
                // Timeline line and mini-assessments
                for (int i = 0; i < miniAssessments.length; i++) ...[
                  pw.SizedBox(height: 10),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 2,
                        height: 20,
                        color: PdfColors.blue300,
                        margin: const pw.EdgeInsets.only(left: 5),
                      ),
                    ],
                  ),
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 12,
                        height: 12,
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.green600,
                          shape: pw.BoxShape.circle,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Expanded(
                        child: pw.Text(
                          'Mini-Assessment: ${miniAssessments[i]['assessmentTitle'] ?? 'Focus Training'}',
                        ),
                      ),
                      pw.Text(
                        _formatDate(miniAssessments[i]['date']),
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildCategoryProgressSection(
    Map<String, double> categoryProgress, 
    Map<String, dynamic> baselineResults, 
    List<Map<String, dynamic>> miniAssessments
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Category Progress Analysis',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          // Progress bars for each category
          for (var entry in categoryProgress.entries) ...[
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        entry.key,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '${entry.value >= 0 ? '+' : ''}${entry.value.toStringAsFixed(1)}%',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          color: entry.value >= 0 ? PdfColors.green700 : PdfColors.orange700,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    height: 8,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.LinearProgressIndicator(
                      value: (entry.value.abs() / 50).clamp(0.0, 1.0), // Scale for visual representation
                      backgroundColor: PdfColors.grey300,
                      valueColor: entry.value >= 0 ? PdfColors.green600 : PdfColors.orange600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  static pw.Widget _buildZoneProgressSection(
    Map<String, double> zoneProgress, 
    Map<String, dynamic> baselineResults, 
    List<Map<String, dynamic>> miniAssessments
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Zone Progress Analysis',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          // Zone progress grid
          pw.Container(
            height: 180,
            child: pw.GridView(
              crossAxisCount: 3,
              childAspectRatio: 1,
              children: List.generate(9, (index) {
                final zoneNumber = (index + 1).toString();
                final progress = zoneProgress[zoneNumber] ?? 0.0;
                final progressColor = progress >= 0 ? PdfColors.green600 : PdfColors.orange600;
                
                return pw.Container(
                  margin: const pw.EdgeInsets.all(4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(progressColor.red, progressColor.green, progressColor.blue, 0.1), // FIXED: Used PdfColor constructor with alpha
                    border: pw.Border.all(color: progressColor),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    mainAxisAlignment: pw.MainAxisAlignment.center,
                    children: [
                      pw.Text(
                        zoneNumber,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '${progress >= 0 ? '+' : ''}${progress.toStringAsFixed(1)}%',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: progressColor, fontSize: 10),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Zone improvement comparison: Baseline vs Latest Mini-Assessment',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildMiniAssessmentDetails(List<Map<String, dynamic>> miniAssessments) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Mini-Assessment Performance Details',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Assessment',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Date',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Score',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Focus Area',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ),
                ],
              ),
              // Data rows
              for (var assessment in miniAssessments)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        assessment['assessmentTitle'] ?? 'Mini Assessment',
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _formatDate(assessment['date']),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${(assessment['overallScore'] as double? ?? 0.0).toStringAsFixed(1)}/10',
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        assessment['focusArea'] ?? assessment['category'] ?? 'General',
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildProgressInsights(List<String> recommendations, Map<String, dynamic> analysis) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Progress Insights & Analysis',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          
          // Key insights
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              border: pw.Border.all(color: PdfColors.green300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Key Progress Insights:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
                pw.SizedBox(height: 8),
                for (var insight in recommendations)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('• ', style: pw.TextStyle(color: PdfColors.green700)),
                        pw.Expanded(
                          child: pw.Text(
                            insight,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildNextStepsSection(Map<String, dynamic> analysis) {
    final nextSteps = analysis['nextSteps'] as List<String>? ?? [];
    
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Recommended Next Steps',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 15),
          
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (var step in nextSteps.isNotEmpty ? nextSteps : _getDefaultNextSteps())
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('✓ ', style: pw.TextStyle(color: PdfColors.blue700, fontSize: 12)),
                        pw.Expanded(
                          child: pw.Text(
                            step,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
      child: pw.Text(
        'Progress Report - Page ${context.pageNumber} of ${context.pagesCount}',
        style: pw.TextStyle(
          color: PdfColors.grey,
          fontSize: 10,
        ),
      ),
    );
  }
  
  // Progress calculation methods with targeted group extraction
  static Map<String, dynamic> _calculateProgressMetrics(
    Map<String, dynamic> baselineResults,
    List<Map<String, dynamic>> miniAssessments,
    Map<String, dynamic>? baselineAssessment, // Add full baseline assessment data
  ) {
    if (miniAssessments.isEmpty) {
      return {
        'overallProgress': 0.0,
        'categoryProgress': <String, double>{},
        'zoneProgress': <String, double>{},
        'groupProgress': <String, double>{},
        'recommendations': <String>['No mini-assessments completed yet'],
        'nextSteps': _getDefaultNextSteps(),
      };
    }
    
    // Calculate targeted group progress (new approach)
    final groupProgress = <String, double>{};
    
    if (baselineAssessment != null) {
      for (var miniAssessment in miniAssessments) {
        final matchingGroupProgress = _calculateMatchingGroupProgress(
          baselineAssessment, 
          baselineResults, 
          miniAssessment
        );
        groupProgress.addAll(matchingGroupProgress);
      }
    }
    
    // Calculate overall progress (fallback to traditional method)
    final baselineScore = baselineResults['overallScore'] as double? ?? 
                         baselineResults['overallRate'] as double? ?? 0.0;
    final latestAssessment = miniAssessments.last;
    final latestScore = latestAssessment['overallScore'] as double? ?? 0.0;
    final overallProgress = baselineScore > 0 ? ((latestScore - baselineScore) / baselineScore * 100) : 0.0;
    
    // Calculate category progress
    final categoryProgress = <String, double>{};
    final baselineCategories = baselineResults['categoryScores'] as Map<String, dynamic>? ?? {};
    
    for (var assessment in miniAssessments) {
      final assessmentCategories = assessment['categoryScores'] as Map<String, dynamic>? ?? {};
      for (var entry in assessmentCategories.entries) {
        final baselineValue = baselineCategories[entry.key] as double? ?? 0.0;
        final currentValue = entry.value as double? ?? 0.0;
        if (baselineValue > 0) {
          final progress = (currentValue - baselineValue) / baselineValue * 100;
          categoryProgress[entry.key] = progress;
        }
      }
    }
    
    // Calculate zone progress (for shot assessments)
    final zoneProgress = <String, double>{};
    final baselineZones = baselineResults['zoneRates'] as Map<String, dynamic>? ?? {};
    
    for (var assessment in miniAssessments) {
      final assessmentZones = assessment['zoneRates'] as Map<String, dynamic>? ?? {};
      for (var entry in assessmentZones.entries) {
        final baselineValue = baselineZones[entry.key] as double? ?? 0.0;
        final currentValue = entry.value as double? ?? 0.0;
        if (baselineValue > 0) {
          final progress = (currentValue - baselineValue) / baselineValue * 100;
          zoneProgress[entry.key] = progress;
        }
      }
    }
    
    // Generate recommendations using targeted group progress
    final recommendations = _generateProgressRecommendations(
      overallProgress, categoryProgress, zoneProgress, miniAssessments, groupProgress
    );
    
    // Generate next steps
    final nextSteps = _generateProgressNextSteps(overallProgress, categoryProgress);
    
    return {
      'overallProgress': overallProgress,
      'categoryProgress': categoryProgress,
      'zoneProgress': zoneProgress,
      'groupProgress': groupProgress, // NEW: Include targeted group progress
      'recommendations': recommendations,
      'nextSteps': nextSteps,
    };
  }
  
  /// Calculate progress for matching groups between full assessment and mini-assessment
  static Map<String, double> _calculateMatchingGroupProgress(
    Map<String, dynamic> baselineAssessment,
    Map<String, dynamic> baselineResults,
    Map<String, dynamic> miniAssessment,
  ) {
    final groupProgress = <String, double>{};
    
    // Get mini-assessment details
    final miniAssessmentType = miniAssessment['assessmentType'] as String? ?? 
                              miniAssessment['type'] as String? ?? '';
    final miniTitle = miniAssessment['assessmentTitle'] as String? ?? '';
    
    // Get baseline assessment groups
    final baselineGroups = baselineAssessment['groups'] as List? ?? [];
    
    // Map mini-assessment types to baseline group patterns
    final matchingGroup = _findMatchingBaselineGroup(
      miniAssessmentType, 
      miniTitle, 
      baselineGroups
    );
    
    if (matchingGroup != null) {
      final groupIndex = matchingGroup['groupIndex'] as int;
      final groupTitle = matchingGroup['title'] as String;
      
      // Extract baseline group performance using the new group-aware method
      final baselineGroupPerformance = _extractGroupPerformance(
        baselineResults, 
        groupIndex
      );
      
      // Get mini-assessment performance  
      final miniPerformance = {
        'overallScore': miniAssessment['overallScore'] as double? ?? 0.0,
        'overallRate': miniAssessment['overallRate'] as double? ?? 0.0,
        'totalShots': miniAssessment['totalShots'] as int? ?? 0,
        'successfulShots': miniAssessment['successfulShots'] as int? ?? 0,
        'zoneRates': miniAssessment['zoneRates'] as Map<String, dynamic>? ?? {},
        'categoryScores': miniAssessment['categoryScores'] as Map<String, dynamic>? ?? {},
      };
      
      // Calculate targeted progress using group-specific baseline
      final baselineRate = baselineGroupPerformance['overallRate'] as double;
      final miniRate = miniPerformance['overallRate'] as double;
      
      if (baselineRate > 0) {
        final progress = ((miniRate - baselineRate) / baselineRate * 100);
        groupProgress[groupTitle] = progress;
        
        // Add detailed progress description
        final progressDescription = _getDetailedProgressDescription(
          groupTitle, 
          baselineRate, 
          miniRate, 
          baselineGroupPerformance['totalShots'] as int? ?? 0,
          miniPerformance['totalShots'] as int? ?? 0
        );
        groupProgress['${groupTitle} (Details)'] = progress; // Store for detailed view
      }
      
      // Calculate zone-specific progress for the matching group
      final baselineGroupZones = baselineGroupPerformance['zoneRates'] as Map<String, dynamic>? ?? {};
      final miniZones = miniPerformance['zoneRates'] as Map<String, dynamic>? ?? {};
      
      for (var zone in miniZones.keys) {
        final baselineZoneRate = baselineGroupZones[zone] as double? ?? 0.0;
        final miniZoneRate = miniZones[zone] as double? ?? 0.0;
        
        if (baselineZoneRate > 0) {
          final zoneProgress = (miniZoneRate - baselineZoneRate) / baselineZoneRate * 100;
          groupProgress['${groupTitle} - Zone $zone'] = zoneProgress;
        }
      }
      
      // Add shot type progress if applicable
      final baselineGroupShots = _getBaselineGroupShotsByType(baselineResults, groupIndex);
      final miniShots = _getMiniAssessmentShotsByType(miniAssessment);
      
      for (var shotType in miniShots.keys) {
        if (baselineGroupShots.containsKey(shotType)) {
          final baselineTypeRate = baselineGroupShots[shotType] as double;
          final miniTypeRate = miniShots[shotType] as double;
          
          if (baselineTypeRate > 0) {
            final typeProgress = (miniTypeRate - baselineTypeRate) / baselineTypeRate * 100;
            groupProgress['${groupTitle} - $shotType'] = typeProgress;
          }
        }
      }
    } else {
      // No direct group match found - provide feedback
      groupProgress['No Direct Match'] = 0.0;
      groupProgress['Match Status'] = 0.0; // Indicates no match for reporting
    }
    
    return groupProgress;
  }
  
  /// Get detailed progress description for better insights
  static String _getDetailedProgressDescription(
    String groupTitle,
    double baselineRate,
    double miniRate,
    int baselineShots,
    int miniShots,
  ) {
    final improvement = ((miniRate - baselineRate) / baselineRate * 100);
    final baselinePercent = (baselineRate * 100).toStringAsFixed(1);
    final miniPercent = (miniRate * 100).toStringAsFixed(1);
    
    return '$groupTitle: $baselinePercent% ($baselineShots shots) → $miniPercent% ($miniShots shots) = ${improvement > 0 ? '+' : ''}${improvement.toStringAsFixed(1)}% change';
  }
  
  /// Extract shot type performance for baseline group
  static Map<String, double> _getBaselineGroupShotsByType(
    Map<String, dynamic> baselineResults,
    int groupIndex,
  ) {
    final groupTypePerformance = baselineResults['groupTypePerformance'] as Map<String, dynamic>? ?? {};
    final groupTypes = groupTypePerformance[groupIndex.toString()] as Map<String, dynamic>? ?? {};
    
    if (groupTypes.isNotEmpty) {
      return groupTypes.cast<String, double>();
    }
    
    // Fallback to overall type rates
    return (baselineResults['typeRates'] as Map<String, dynamic>? ?? {}).cast<String, double>();
  }
  
  /// Extract shot type performance for mini-assessment
  static Map<String, double> _getMiniAssessmentShotsByType(
    Map<String, dynamic> miniAssessment,
  ) {
    return (miniAssessment['typeRates'] as Map<String, dynamic>? ?? {}).cast<String, double>();
  }
  
  /// Find the matching baseline group for a mini-assessment
  static Map<String, dynamic>? _findMatchingBaselineGroup(
    String miniAssessmentType,
    String miniTitle,
    List baselineGroups,
  ) {
    // Mini-assessment to baseline group mapping
    final mappings = {
      'right_side_precision_25': ['Right Side Precision', 'right side'],
      'left_side_precision_25': ['Left Side Precision', 'left side'],
      'center_line_targeting_25': ['Center Line Targeting', 'center line', 'center'],
      'high_corner_precision_25': ['High Corner Precision', 'high corner', 'high'],
      'slap_shot_power_20': ['Slap Shot Power', 'slap shot'],
      'wrist_shot_power_20': ['Wrist Shot Power', 'wrist shot'],
      'one_timer_power_20': ['One-Timer Power', 'one timer', 'one-timer'],
      'wrist_shot_technique_15': ['Wrist Shot Technique', 'wrist shot'],
      'snap_shot_technique_15': ['Snap Shot Technique', 'snap shot'],
      'backhand_technique_15': ['Backhand Technique', 'backhand'],
    };
    
    final searchTerms = mappings[miniAssessmentType] ?? 
                       _extractSearchTermsFromTitle(miniTitle);
    
    // Search through baseline groups for matches
    for (int i = 0; i < baselineGroups.length; i++) {
      final group = baselineGroups[i] as Map<String, dynamic>;
      final groupTitle = group['title'] as String? ?? '';
      final groupName = group['name'] as String? ?? '';
      final groupId = group['id'] as String? ?? i.toString();
      
      // Check if any search terms match the group title/name
      for (final term in searchTerms) {
        if (groupTitle.toLowerCase().contains(term.toLowerCase()) ||
            groupName.toLowerCase().contains(term.toLowerCase())) {
          return {
            'groupIndex': i,
            'groupId': groupId,
            'title': groupTitle.isNotEmpty ? groupTitle : groupName,
            'targetZones': group['targetZones'] ?? group['intendedZones'] ?? [],
            'shotType': group['defaultType'] ?? '',
          };
        }
      }
    }
    
    return null; // No matching group found
  }
  
  /// Extract searchterms from mini-assessment title
  static List<String> _extractSearchTermsFromTitle(String title) {
    final terms = <String>[];
    final titleLower = title.toLowerCase();
    
    // Extract key terms
    if (titleLower.contains('right')) terms.add('right');
    if (titleLower.contains('left')) terms.add('left');
    if (titleLower.contains('center')) terms.add('center');
    if (titleLower.contains('high')) terms.add('high');
    if (titleLower.contains('wrist')) terms.add('wrist');
    if (titleLower.contains('slap')) terms.add('slap');
    if (titleLower.contains('snap')) terms.add('snap');
    if (titleLower.contains('backhand')) terms.add('backhand');
    if (titleLower.contains('one-timer') || titleLower.contains('one timer')) terms.add('one timer');
    if (titleLower.contains('power')) terms.add('power');
    if (titleLower.contains('technique')) terms.add('technique');
    if (titleLower.contains('precision')) terms.add('precision');
    
    return terms.isNotEmpty ? terms : [title];
  }
  
  /// Extract performance data for a specific group from baseline results
  static Map<String, dynamic> _extractGroupPerformance(
    Map<String, dynamic> baselineResults,
    int groupIndex,
  ) {
    // Check if baseline results contain group-specific data
    final intendedZonePerformance = baselineResults['intendedZonePerformance'] as Map<String, dynamic>? ?? {};
    final groupPerformance = intendedZonePerformance[groupIndex.toString()] as Map<String, dynamic>? ?? {};
    
    if (groupPerformance.isNotEmpty) {
      // Extract group-specific performance
      final totalShots = groupPerformance['total_shots'] as int? ?? 0;
      final intendedHits = groupPerformance['intended_hits'] as int? ?? 0;
      final overallRate = groupPerformance['intended_hit_rate'] as double? ?? 
                         (totalShots > 0 ? intendedHits / totalShots : 0.0);
      
      return {
        'overallRate': overallRate,
        'totalShots': totalShots,
        'intendedHits': intendedHits,
        'successes': groupPerformance['successes'] as int? ?? intendedHits,
        'zoneRates': _extractGroupZoneRates(baselineResults, groupIndex),
        'groupIndex': groupIndex,
      };
    } else {
      // Fallback to overall baseline performance
      return {
        'overallRate': baselineResults['overallRate'] as double? ?? 0.0,
        'totalShots': baselineResults['totalShots'] as int? ?? 0,
        'zoneRates': baselineResults['zoneRates'] as Map<String, dynamic>? ?? {},
        'groupIndex': null,
      };
    }
  }
  
  /// Extract zone rates for a specific group from shot-level data
  static Map<String, dynamic> _extractGroupZoneRates(
    Map<String, dynamic> baselineResults,
    int groupIndex,
  ) {
    // Check if we have zone performance data by group
    final groupZonePerformance = baselineResults['groupZonePerformance'] as Map<String, dynamic>? ?? {};
    final groupZones = groupZonePerformance[groupIndex.toString()] as Map<String, dynamic>? ?? {};
    
    if (groupZones.isNotEmpty) {
      return groupZones;
    }
    
    // Check if we have shot-level data to calculate group zone rates
    final shotLevelData = baselineResults['shotLevelData'] as List? ?? [];
    if (shotLevelData.isNotEmpty) {
      return _calculateGroupZoneRatesFromShots(shotLevelData, groupIndex);
    }
    
    // Fallback to overall zone rates (less accurate but better than nothing)
    return baselineResults['zoneRates'] as Map<String, dynamic>? ?? {};
  }
  
  /// Calculate zone rates for a specific group from shot-level data
  static Map<String, dynamic> _calculateGroupZoneRatesFromShots(
    List shotLevelData,
    int groupIndex,
  ) {
    final zoneAttempts = <String, int>{};
    final zoneSuccesses = <String, int>{};
    
    // Filter shots for this group and calculate zone rates
    for (var shot in shotLevelData) {
      final shotMap = shot as Map<String, dynamic>;
      final groupIndex = shotMap['group_index'] as int? ?? shotMap['groupIndex'] as int?;
      
      if (groupIndex == groupIndex) {
        final zone = shotMap['zone'] as String? ?? 'unknown';
        final success = shotMap['success'] as bool? ?? false;
        
        if (zone != 'unknown' && !zone.startsWith('miss_')) {
          zoneAttempts[zone] = (zoneAttempts[zone] ?? 0) + 1;
          if (success) {
            zoneSuccesses[zone] = (zoneSuccesses[zone] ?? 0) + 1;
          }
        }
      }
    }
    
    // Calculate success rates
    final zoneRates = <String, dynamic>{};
    for (var zone in zoneAttempts.keys) {
      final attempts = zoneAttempts[zone] ?? 0;
      final successes = zoneSuccesses[zone] ?? 0;
      zoneRates[zone] = attempts > 0 ? successes / attempts : 0.0;
    }
    
    return zoneRates;
  }
  
  static List<String> _generateProgressRecommendations(
    double overallProgress,
    Map<String, double> categoryProgress,
    Map<String, double> zoneProgress,
    List<Map<String, dynamic>> miniAssessments,
    Map<String, double> groupProgress, // NEW: Include targeted group progress
  ) {
    final recommendations = <String>[];
    
    // Overall progress recommendations
    if (overallProgress > 10) {
      recommendations.add('Excellent overall improvement of ${overallProgress.toStringAsFixed(1)}% shows focused training is working');
    } else if (overallProgress > 0) {
      recommendations.add('Positive progress of ${overallProgress.toStringAsFixed(1)}% indicates training is on track');
    } else {
      recommendations.add('Performance needs attention - consider adjusting training approach');
    }
    
    // NEW: Targeted group progress recommendations
    for (var entry in groupProgress.entries) {
      if (entry.value > 15) {
        recommendations.add('${entry.key} shows exceptional targeted improvement (+${entry.value.toStringAsFixed(1)}%)');
      } else if (entry.value > 5) {
        recommendations.add('${entry.key} demonstrates solid focused progress (+${entry.value.toStringAsFixed(1)}%)');
      } else if (entry.value < -10) {
        recommendations.add('${entry.key} requires additional focused training (${entry.value.toStringAsFixed(1)}% decline)');
      }
    }
    
    // Category-specific recommendations
    for (var entry in categoryProgress.entries) {
      if (entry.value > 15) {
        recommendations.add('${entry.key} shows strong improvement (+${entry.value.toStringAsFixed(1)}%)');
      } else if (entry.value < -10) {
        recommendations.add('${entry.key} requires focused attention (${entry.value.toStringAsFixed(1)}% decline)');
      }
    }
    
    // Assessment frequency recommendation
    if (miniAssessments.length < 3) {
      recommendations.add('Complete more targeted mini-assessments to better track focused skill development');
    } else {
      recommendations.add('Good targeted assessment frequency - continue regular focused skill monitoring');
    }
    
    return recommendations;
  }
  
  static List<String> _generateProgressNextSteps(
    double overallProgress,
    Map<String, double> categoryProgress,
  ) {
    final steps = <String>[];
    
    if (overallProgress < 5) {
      steps.add('Schedule additional focused training sessions');
      steps.add('Review current training methodology with coach');
    }
    
    // Find areas needing most improvement
    final weakestCategory = categoryProgress.entries
        .where((e) => e.value < 0)
        .fold<MapEntry<String, double>?>(null, (prev, curr) => 
            prev == null || curr.value < prev.value ? curr : prev);
    
    if (weakestCategory != null) {
      steps.add('Prioritize ${weakestCategory.key.toLowerCase()} training in upcoming sessions');
    }
    
    steps.add('Continue mini-assessments every 1-2 weeks to monitor progress');
    steps.add('Plan next full assessment in 4-6 weeks');
    
    return steps;
  }
  
  static List<String> _getDefaultNextSteps() {
    return [
      'Complete targeted mini-assessments in identified weak areas',
      'Maintain consistent training schedule',
      'Schedule follow-up progress review in 2-3 weeks',
      'Plan comprehensive re-assessment in 4-6 weeks',
    ];
  }
  
  /// Share the generated progress PDF
  static Future<void> shareProgressPDF(Uint8List pdfData, String fileName) async {
    return PdfReportService.sharePDF(pdfData, fileName);
  }
  
  /// Helper method to load shot-level data for accurate group progress tracking
  /// This should be called from your API service to get detailed shot data
  static Future<Map<String, dynamic>> loadBaselineResultsWithShotData(
    String baselineAssessmentId,
    Map<String, dynamic> existingResults,
  ) async {
    try {
      // This would be called from your ApiService
      // Example implementation:
      /*
      final shotLevelData = await ApiService().getShotsByAssessment(
        baselineAssessmentId,
        includeGroupIndex: true, // Important: include group_index
      );
      
      final enhancedResults = Map<String, dynamic>.from(existingResults);
      enhancedResults['shotLevelData'] = shotLevelData;
      
      // Calculate group-specific zone rates
      enhancedResults['groupZonePerformance'] = _calculateGroupZonePerformance(shotLevelData);
      enhancedResults['groupTypePerformance'] = _calculateGroupTypePerformance(shotLevelData);
      
      return enhancedResults;
      */
      
      // For now, return existing results
      return existingResults;
    } catch (e) {
      print('Error loading shot-level data: $e');
      return existingResults;
    }
  }
  
  /// Helper method to calculate group zone performance from shot data
  static Map<String, dynamic> _calculateGroupZonePerformance(List shotData) {
    final groupZonePerformance = <String, Map<String, dynamic>>{};
    
    // Group shots by group_index
    final shotsByGroup = <int, List<Map<String, dynamic>>>{};
    for (var shot in shotData) {
      final shotMap = shot as Map<String, dynamic>;
      final groupIndex = shotMap['group_index'] as int? ?? 0;
      shotsByGroup[groupIndex] ??= [];
      shotsByGroup[groupIndex]!.add(shotMap);
    }
    
    // Calculate zone rates for each group
    for (var entry in shotsByGroup.entries) {
      final groupIndex = entry.key;
      final groupShots = entry.value;
      
      final zoneAttempts = <String, int>{};
      final zoneSuccesses = <String, int>{};
      
      for (var shot in groupShots) {
        final zone = shot['zone'] as String? ?? 'unknown';
        final success = shot['success'] as bool? ?? false;
        
        if (zone != 'unknown' && !zone.startsWith('miss_')) {
          zoneAttempts[zone] = (zoneAttempts[zone] ?? 0) + 1;
          if (success) {
            zoneSuccesses[zone] = (zoneSuccesses[zone] ?? 0) + 1;
          }
        }
      }
      
      final zoneRates = <String, double>{};
      for (var zone in zoneAttempts.keys) {
        final attempts = zoneAttempts[zone] ?? 0;
        final successes = zoneSuccesses[zone] ?? 0;
        zoneRates[zone] = attempts > 0 ? successes / attempts : 0.0;
      }
      
      groupZonePerformance[groupIndex.toString()] = zoneRates;
    }
    
    return groupZonePerformance;
  }
  
  /// Helper method to calculate group shot type performance from shot data
  static Map<String, dynamic> _calculateGroupTypePerformance(List shotData) {
    final groupTypePerformance = <String, Map<String, dynamic>>{};
    
    // Group shots by group_index
    final shotsByGroup = <int, List<Map<String, dynamic>>>{};
    for (var shot in shotData) {
      final shotMap = shot as Map<String, dynamic>;
      final groupIndex = shotMap['group_index'] as int? ?? 0;
      shotsByGroup[groupIndex] ??= [];
      shotsByGroup[groupIndex]!.add(shotMap);
    }
    
    // Calculate shot type rates for each group
    for (var entry in shotsByGroup.entries) {
      final groupIndex = entry.key;
      final groupShots = entry.value;
      
      final typeAttempts = <String, int>{};
      final typeSuccesses = <String, int>{};
      
      for (var shot in groupShots) {
        final type = shot['type'] as String? ?? 'Unknown';
        final success = shot['success'] as bool? ?? false;
        
        typeAttempts[type] = (typeAttempts[type] ?? 0) + 1;
        if (success) {
          typeSuccesses[type] = (typeSuccesses[type] ?? 0) + 1;
        }
      }
      
      final typeRates = <String, double>{};
      for (var type in typeAttempts.keys) {
        final attempts = typeAttempts[type] ?? 0;
        final successes = typeSuccesses[type] ?? 0;
        typeRates[type] = attempts > 0 ? successes / attempts : 0.0;
      }
      
      groupTypePerformance[groupIndex.toString()] = typeRates;
    }
    
    return groupTypePerformance;
  }
}