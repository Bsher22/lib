// lib/services/pdf_report_service.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'dart:io';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/utils/assessment_shot_utils.dart';
import 'package:hockey_shot_tracker/utils/assessment_skating_utils.dart';
import 'package:flutter/material.dart' as material;

class PdfReportService {
  // Remove font loading - use built-in fonts instead
  
  // Fix: Remove async from header builder and use built-in fonts
  static pw.Widget _buildReportHeader(String assessmentType, String playerName, String date) {
    return pw.Header(
      level: 0,
      child: pw.Row(
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
                  font: pw.Font.helvetica(),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                '$assessmentType Assessment Report', 
                style: pw.TextStyle(
                  fontSize: 18,
                  font: pw.Font.helvetica(),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Player: $playerName', 
                style: pw.TextStyle(
                  fontSize: 14,
                  font: pw.Font.helvetica(),
                ),
              ),
              pw.Text(
                'Date: $date', 
                style: pw.TextStyle(
                  fontSize: 12, 
                  color: PdfColors.grey700,
                  font: pw.Font.helvetica(),
                ),
              ),
            ],
          ),
          // Logo placeholder
          pw.Container(
            height: 80,
            width: 80,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Center(
              child: pw.Text(
                'HIRE\nHOCKEY', 
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  font: pw.Font.helvetica(),
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Fix: Add color with opacity helper
  static PdfColor _colorWithOpacity(PdfColor color, double opacity) {
    return PdfColor(
      color.red,
      color.green, 
      color.blue,
      opacity,
    );
  }

  // Helper to create a section title
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20, bottom: 10),
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: PdfColors.blueGrey700, width: 1)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 16, 
          fontWeight: pw.FontWeight.bold, 
          color: PdfColors.blueGrey800,
          font: pw.Font.helvetica(),
        ),
      ),
    );
  }

  // Helper to create a simple metric display
  static pw.Widget _buildMetricItem(String label, String value, PdfColor color) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label, 
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: color, 
              fontWeight: pw.FontWeight.bold,
              font: pw.Font.helvetica(),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to create strengths and improvement lists
  static pw.Widget _buildStrengthsAndImprovements(
      List<String> strengths, List<String> improvements) {
    return pw.Container(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Strengths', 
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, 
              color: PdfColors.green700,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 5),
          for (var strength in strengths)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 5,
                    height: 5,
                    margin: const pw.EdgeInsets.only(top: 3, right: 5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      strength,
                      style: pw.TextStyle(font: pw.Font.helvetica()),
                    ),
                  ),
                ],
              ),
            ),
          pw.SizedBox(height: 15),
          pw.Text(
            'Areas for Improvement', 
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold, 
              color: PdfColors.orange700,
              font: pw.Font.helvetica(),
            ),
          ),
          pw.SizedBox(height: 5),
          for (var improvement in improvements)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 5,
                    height: 5,
                    margin: const pw.EdgeInsets.only(top: 3, right: 5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.orange,
                      shape: pw.BoxShape.circle,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      improvement,
                      style: pw.TextStyle(font: pw.Font.helvetica()),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Create a simple PDF for initial testing
  static Future<Uint8List> generateTestPDF() async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Center(
            child: pw.Text(
              'Test PDF Generation', 
              style: pw.TextStyle(
                fontSize: 24,
                font: pw.Font.helvetica(),
              ),
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }

  /// Generate a Skating Assessment PDF report
  static Future<Uint8List> generateSkatingAssessmentPDF({
    required Player player,
    required Map<String, dynamic> assessment,
    required Map<String, dynamic> results,
    required Map<String, Map<String, dynamic>> testResults,
  }) async {
    final pdf = pw.Document();
    
    final categoryScores = results['scores'] as Map<String, dynamic>;
    final overallScore = categoryScores['Overall'] as double? ?? 0.0;
    final strengths = (results['strengths'] as List).cast<String>();
    final improvements = (results['improvements'] as List).cast<String>();
    
    // Formatting the date from assessment
    final assessmentDate = DateTime.parse(assessment['date'] as String);
    final formattedDate = '${assessmentDate.month}/${assessmentDate.day}/${assessmentDate.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader('Skating', player.name, formattedDate),
        build: (context) => [
          // Overall Performance Summary
          _buildSectionTitle('Overall Performance'),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricItem(
                  'Overall Score', 
                  '${overallScore.toStringAsFixed(1)}/10.0',
                  _getScoreColor(overallScore),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricItem(
                  'Performance Level',
                  results['performance_level'] as String? ?? 'Not Rated',
                  _getLevelColor(results['performance_level'] as String? ?? ''),
                ),
              ),
            ],
          ),
          
          // Category Scores
          _buildSectionTitle('Skating Categories'),
          pw.Column(
            children: [
              for (var entry in categoryScores.entries)
                if (entry.key != 'Overall')
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              entry.key,
                              style: pw.TextStyle(font: pw.Font.helvetica()),
                            ),
                            pw.Text(
                              '${(entry.value as num).toStringAsFixed(1)}/10',
                              style: pw.TextStyle(font: pw.Font.helvetica()),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          height: 10,
                          child: pw.ClipRRect(
                            horizontalRadius: 5,
                            verticalRadius: 5,
                            child: pw.LinearProgressIndicator(
                              value: (entry.value as num) / 10,
                              backgroundColor: PdfColors.grey300,
                              valueColor: _getScoreColor((entry.value as num).toDouble()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          
          // Test Results
          _buildSectionTitle('Test Results'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Test', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Time (s)', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Rating', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ),
                ],
              ),
              // Test rows
              for (var entry in testResults.entries)
                pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _getTestName(entry.key, assessment),
                        style: pw.TextStyle(font: pw.Font.helvetica()),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        '${(entry.value['time'] as num).toStringAsFixed(2)}',
                        style: pw.TextStyle(font: pw.Font.helvetica()),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        _getTestRating(entry.key, results) ?? 'N/A',
                        style: pw.TextStyle(font: pw.Font.helvetica()),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          
          // Strengths and Improvements
          _buildSectionTitle('Analysis & Recommendations'),
          _buildStrengthsAndImprovements(strengths, improvements),
          
          // Recommended Training
          _buildSectionTitle('Recommended Training Focus'),
          pw.Bullet(
            text: 'Skating sessions: 2-3 times per week',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          pw.Bullet(
            text: 'Focus on ${improvements.isNotEmpty ? improvements.first.toLowerCase() : "all-around technique"}',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          if (improvements.length > 1)
            pw.Bullet(
              text: 'Secondary focus: ${improvements[1].toLowerCase()}',
              style: pw.TextStyle(font: pw.Font.helvetica()),
            ),
          pw.Bullet(
            text: 'Incorporate balance and edge control exercises into warm-ups',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Reassess in 4-6 weeks to measure improvement.',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          
          // Footer with signature space
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Coach Signature:',
                    style: pw.TextStyle(font: pw.Font.helvetica()),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Player Signature:',
                    style: pw.TextStyle(font: pw.Font.helvetica()),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
            ],
          ),
        ],
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                color: PdfColors.grey,
                font: pw.Font.helvetica(),
              ),
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }

  /// Generate a Shot Assessment PDF report
  static Future<Uint8List> generateShotAssessmentPDF({
    required Player player,
    required Map<String, dynamic> assessment,
    required Map<String, dynamic> results,
    required Map<int, List<Map<String, dynamic>>> shotResults,
  }) async {
    final pdf = pw.Document();
    
    final categoryScores = results['categoryScores'] as Map<String, dynamic>? ?? {};
    final overallScore = results['overallScore'] as double? ?? 0.0;
    final zoneRates = results['zoneRates'] as Map<String, dynamic>? ?? {};
    final strengths = (results['strengths'] as List?)?.cast<String>() ?? [];
    final improvements = (results['improvements'] as List?)?.cast<String>() ?? [];
    
    // Formatting the date
    final assessmentDate = DateTime.now(); // Use current date if not available
    final formattedDate = '${assessmentDate.month}/${assessmentDate.day}/${assessmentDate.year}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildReportHeader('Shot', player.name, formattedDate),
        build: (context) => [
          // Overall Performance Summary
          _buildSectionTitle('Overall Performance'),
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricItem(
                  'Overall Score', 
                  '${overallScore.toStringAsFixed(1)}/10.0',
                  _getScoreColor(overallScore),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricItem(
                  'Success Rate',
                  '${((results['overallRate'] as num?)?.toDouble() ?? 0.0 * 100).toStringAsFixed(1)}%',
                  _getSuccessRateColor((results['overallRate'] as num?)?.toDouble() ?? 0.0),
                ),
              ),
            ],
          ),
          
          // Shot statistics
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildMetricItem(
                  'Total Shots', 
                  '${results['totalShots'] ?? _countTotalShots(shotResults)}',
                  PdfColors.blue700,
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: _buildMetricItem(
                  'Shot Types',
                  '${(results['typeRates'] as Map<String, dynamic>?)?.length ?? 0}',
                  PdfColors.purple700,
                ),
              ),
            ],
          ),
          
          // Category Scores
          _buildSectionTitle('Shot Categories'),
          pw.Column(
            children: [
              for (var entry in categoryScores.entries)
                if (entry.key != 'Overall')
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              entry.key,
                              style: pw.TextStyle(font: pw.Font.helvetica()),
                            ),
                            pw.Text(
                              '${(entry.value as num).toStringAsFixed(1)}/10',
                              style: pw.TextStyle(font: pw.Font.helvetica()),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Container(
                          height: 10,
                          child: pw.ClipRRect(
                            horizontalRadius: 5,
                            verticalRadius: 5,
                            child: pw.LinearProgressIndicator(
                              value: (entry.value as num) / 10,
                              backgroundColor: PdfColors.grey300,
                              valueColor: _getScoreColor((entry.value as num).toDouble()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
          
          // Shot Zone Performance
          _buildSectionTitle('Shot Zone Performance'),
          pw.Container(
            child: pw.Column(
              children: [
                // Simple zone visualization
                pw.Container(
                  height: 180,
                  child: pw.GridView(
                    crossAxisCount: 3,
                    childAspectRatio: 1,
                    children: List.generate(9, (index) {
                      final zoneNumber = (index + 1).toString();
                      final zoneRate = zoneRates[zoneNumber] as double? ?? 0.0;
                      final zoneColor = _getSuccessRateColor(zoneRate);
                      
                      return pw.Container(
                        margin: const pw.EdgeInsets.all(4),
                        decoration: pw.BoxDecoration(
                          color: _colorWithOpacity(zoneColor, 0.2),
                          border: pw.Border.all(color: zoneColor),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          children: [
                            pw.Text(
                              zoneNumber, 
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                font: pw.Font.helvetica(),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              '${(zoneRate * 100).toStringAsFixed(0)}%',
                              style: pw.TextStyle(font: pw.Font.helvetica()),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Net zone diagram (1-9) with success rates',
                  style: pw.TextStyle(
                    fontStyle: pw.FontStyle.italic, 
                    fontSize: 10, 
                    color: PdfColors.grey700,
                    font: pw.Font.helvetica(),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Strengths and Improvements
          _buildSectionTitle('Analysis & Recommendations'),
          _buildStrengthsAndImprovements(strengths, improvements),
          
          // Recommended Training
          _buildSectionTitle('Recommended Training Plan'),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Focus Area', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(
                      'Recommended Drill', 
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        font: pw.Font.helvetica(),
                      ),
                    ),
                  ),
                ],
              ),
              ...List.generate(
                improvements.length > 0 ? improvements.length : 1,
                (index) {
                  final improvement = improvements.length > index ? improvements[index] : "All-around shooting";
                  final drill = _getRecommendedDrill(improvement);
                  
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          improvement,
                          style: pw.TextStyle(font: pw.Font.helvetica()),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          drill,
                          style: pw.TextStyle(font: pw.Font.helvetica()),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Complete 2-3 shooting sessions per week focusing on these areas.',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          pw.Text(
            'Incorporate shot practice into regular training routines.',
            style: pw.TextStyle(font: pw.Font.helvetica()),
          ),
          
          // Footer with signature space
          pw.SizedBox(height: 40),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Coach Signature:',
                    style: pw.TextStyle(font: pw.Font.helvetica()),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Player Signature:',
                    style: pw.TextStyle(font: pw.Font.helvetica()),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Container(width: 150, height: 1, color: PdfColors.black),
                ],
              ),
            ],
          ),
        ],
        footer: (context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 1.0 * PdfPageFormat.cm),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: pw.TextStyle(
                color: PdfColors.grey,
                font: pw.Font.helvetica(),
              ),
            ),
          );
        },
      ),
    );
    
    return pdf.save();
  }
  
  // Helper function to get score color
  static PdfColor _getScoreColor(double score) {
    if (score >= 8.5) return PdfColors.green700;
    if (score >= 7.0) return PdfColors.green;
    if (score >= 5.5) return PdfColors.lime700;
    if (score >= 4.0) return PdfColors.orange;
    if (score >= 2.5) return PdfColors.deepOrange;
    return PdfColors.red;
  }
  
  // Helper function to get success rate color
  static PdfColor _getSuccessRateColor(double rate) {
    if (rate >= 0.8) return PdfColors.green700;
    if (rate >= 0.6) return PdfColors.green;
    if (rate >= 0.4) return PdfColors.orange;
    if (rate >= 0.2) return PdfColors.deepOrange;
    return PdfColors.red;
  }
  
  // Helper function to get performance level color
  static PdfColor _getLevelColor(String level) {
    switch (level) {
      case 'Elite':
        return PdfColors.purple700;
      case 'Advanced':
        return PdfColors.blue700;
      case 'Proficient':
        return PdfColors.green700;
      case 'Developing':
        return PdfColors.orange;
      case 'Basic':
        return PdfColors.deepOrange;
      default:
        return PdfColors.red;
    }
  }
  
  // Helper to get a test name from the assessment data
  static String _getTestName(String testId, Map<String, dynamic> assessment) {
    final groups = assessment['groups'] as List?;
    if (groups == null) return testId;
    
    for (var group in groups) {
      final tests = (group as Map<String, dynamic>)['tests'] as List?;
      if (tests == null) continue;
      
      for (var test in tests) {
        final test_id = (test as Map<String, dynamic>)['id'];
        if (test_id == testId) {
          return test['title'] as String? ?? testId;
        }
      }
    }
    
    return testId;
  }
  
  // Helper to get a test rating from results
  static String? _getTestRating(String testId, Map<String, dynamic> results) {
    final testBenchmarks = results['testBenchmarks'] as Map<String, dynamic>?;
    return testBenchmarks?[testId] as String?;
  }
  
  // Helper to count total shots
  static int _countTotalShots(Map<int, List<Map<String, dynamic>>> shotResults) {
    int total = 0;
    shotResults.forEach((groupId, shots) {
      total += shots.length;
    });
    return total;
  }
  
  // Helper to get a recommended drill based on an improvement area
  static String _getRecommendedDrill(String improvement) {
    if (improvement.toLowerCase().contains('wrist shot')) {
      return 'Quick release wrist shots (50 shots, alternating corners)';
    } else if (improvement.toLowerCase().contains('slap shot')) {
      return 'Power slap shot training (30 shots from point position)';
    } else if (improvement.toLowerCase().contains('accuracy')) {
      return 'Target practice progression (60 shots across zones)';
    } else if (improvement.toLowerCase().contains('power')) {
      return 'Power development drills (focus on technique and follow-through)';
    } else if (improvement.toLowerCase().contains('quick release')) {
      return 'Pass-to-shot drills emphasizing minimal reception time';
    } else if (improvement.toLowerCase().contains('zones')) {
      return 'Zone-specific targeting drills';
    } else {
      return 'Comprehensive shooting circuit (all shot types and zones)';
    }
  }
  
  // Fix: Update share method to use share_plus
  static Future<void> sharePDF(Uint8List pdfData, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(pdfData);
    await share_plus.Share.shareXFiles([share_plus.XFile(file.path)], text: 'Shot Assessment Report');
  }
}