// lib/screens/pdf/pdf_preview_screen.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:hockey_shot_tracker/services/pdf_report_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:pdf/pdf.dart';

class PDFPreviewScreen extends StatelessWidget {
  final Uint8List pdfData;
  final String fileName;
  
  const PDFPreviewScreen({
    Key? key, 
    required this.pdfData,
    this.fileName = 'assessment_report.pdf',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ResponsiveText(
          'Assessment Report',
          baseFontSize: 20,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => PdfReportService.sharePDF(pdfData, fileName),
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => Printing.layoutPdf(
              onLayout: (_) async => pdfData,
              name: fileName,
            ),
            tooltip: 'Print PDF',
          ),
        ],
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: AdaptiveLayout(
          builder: (deviceType, isLandscape) {
            return Container(
              margin: ResponsiveConfig.paddingAll(context, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: ResponsiveConfig.borderRadius(context, 8),
                child: PdfPreview(
                  build: (format) => pdfData,
                  allowPrinting: true,
                  allowSharing: true,
                  canChangePageFormat: false,
                  canChangeOrientation: false,
                  initialPageFormat: PdfPageFormat.a4,
                  pdfFileName: fileName,
                  loadingWidget: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        ResponsiveSpacing(multiplier: 2),
                        ResponsiveText(
                          'Loading PDF...',
                          baseFontSize: 16,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    PdfPreviewAction(
                      icon: const Icon(Icons.download),
                      onPressed: (context, build, pageFormat) async {
                        // Note: savePDF method needs to be implemented or use different method
                        await PdfReportService.sharePDF(pdfData, fileName);
                      },
                    ),
                    PdfPreviewAction(
                      icon: const Icon(Icons.share),
                      onPressed: (context, build, pageFormat) async {
                        await PdfReportService.sharePDF(pdfData, fileName);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}