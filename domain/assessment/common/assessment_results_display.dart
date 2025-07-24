import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/dialog/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';

class AssessmentResultTab {
  final String label;
  final Widget Function(BuildContext) contentBuilder;
  
  AssessmentResultTab({
    required this.label,
    required this.contentBuilder,
  });
}

class AssessmentResultsDisplay extends StatefulWidget {
  // Common properties
  final String title;
  final String? subjectName;
  final String? subjectType; // "player", "team"
  final double overallScore;
  final String performanceLevel;
  final Color Function(double) scoreColorProvider;
  final List<AssessmentResultTab> tabs;
  final VoidCallback? onReset;
  final VoidCallback? onSave;
  final Widget? headerContent;
  final Widget? sidebarContent; // ✅ ADD THIS LINE
  final Future<void> Function()? onExportPdf; // New callback for PDF export

  const AssessmentResultsDisplay({
    Key? key,
    required this.title,
    this.subjectName,
    this.subjectType = 'player',
    required this.overallScore,
    required this.performanceLevel,
    required this.scoreColorProvider,
    required this.tabs,
    this.onReset,
    this.onSave,
    this.headerContent,
    this.sidebarContent, // ✅ ADD THIS LINE
    this.onExportPdf,
  }) : super(key: key);

  // Named constructor for team skating assessment
  static AssessmentResultsDisplay forTeamSkatingAssessment({
    required String title,
    required String teamName,
    required double overallScore,
    required String performanceLevel,
    required Color Function(double) scoreColorProvider,
    required List<AssessmentResultTab> tabs,
    VoidCallback? onReset,
    VoidCallback? onSave,
    Widget? headerContent,
    Widget? sidebarContent,
    Future<void> Function()? onExportPdf,
  }) {
    return AssessmentResultsDisplay(
      title: title,
      subjectName: teamName,
      subjectType: 'team',
      overallScore: overallScore,
      performanceLevel: performanceLevel,
      scoreColorProvider: scoreColorProvider,
      tabs: tabs,
      onReset: onReset,
      onSave: onSave,
      headerContent: headerContent,
      sidebarContent: sidebarContent,
      onExportPdf: onExportPdf,
    );
  }

  @override
  _AssessmentResultsDisplayState createState() => _AssessmentResultsDisplayState();
}

class _AssessmentResultsDisplayState extends State<AssessmentResultsDisplay> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.tabs.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareResults,
            tooltip: 'Share Results',
          ),
        ],
        backgroundColor: Colors.blueGrey[900],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Processing...',
        color: Colors.cyanAccent,
        child: widget.sidebarContent != null 
          ? Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildTabContent(),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 350,
                  child: widget.sidebarContent!,
                ),
              ],
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _buildTabContent(),
                ),
              ],
            ),
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }
  
  Widget _buildHeader() {
    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.scoreColorProvider(widget.overallScore),
                  radius: 32,
                  child: Text(
                    widget.overallScore.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.overallScore >= 7.0 ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectName ?? 'Assessment Results',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.performanceLevel,
                        style: TextStyle(
                          fontSize: 16,
                          color: widget.scoreColorProvider(widget.overallScore),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.headerContent != null) ...[
              const SizedBox(height: 16),
              widget.headerContent!,
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabContent() {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.cyanAccent[700],
          unselectedLabelColor: Colors.blueGrey[600],
          indicatorColor: Colors.cyanAccent[700],
          tabs: widget.tabs.map((tab) => Tab(text: tab.label)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.tabs.map((tab) => tab.contentBuilder(context)).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (widget.onReset != null)
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: _confirmReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Reset'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          if (widget.onReset != null && widget.onSave != null)
            const SizedBox(width: 16),
          if (widget.onSave != null)
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _saveResults,
                icon: const Icon(Icons.save),
                label: const Text('Save Results'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  void _confirmReset() {
    if (widget.onReset == null) return;
    
    DialogService.showConfirmation(
      context,
      title: 'Reset Assessment',
      message: 'Are you sure you want to reset this assessment? All recorded data will be lost.',
      confirmLabel: 'Reset',
      cancelLabel: 'Cancel',
      isDestructive: true,
    ).then((result) {
      if (result == true) {
        widget.onReset?.call();
      }
    });
  }
  
  void _saveResults() {
    if (widget.onSave == null) return;
    
    setState(() {
      _isLoading = true;
    });
    
    // Simulate saving delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      
      // Call save callback
      widget.onSave?.call();
      
      // Show success dialog
      DialogService.showSuccess(
        context,
        title: 'Saved Successfully',
        message: 'The assessment results have been saved.',
      );
    });
  }
  
  void _shareResults() {
    // Show sharing options dialog
    DialogService.showCustom<void>(
      context,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ListTile(
            title: Text('Share Results'),
            subtitle: Text('Choose how to share these results'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
            title: const Text('Export as PDF'),
            subtitle: const Text('Create a PDF report'),
            onTap: () async {
              Navigator.of(context).pop();
              if (widget.onExportPdf != null) {
                try {
                  await widget.onExportPdf!();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error exporting PDF: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export not available')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.email, color: Colors.blue),
            title: const Text('Share via Email'),
            subtitle: const Text('Send results to player/coach'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preparing email...')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.purple),
            title: const Text('Save to Team Dashboard'),
            subtitle: const Text('Make results available to team'),
            onTap: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Saving to team dashboard...')),
              );
            },
          ),
        ],
      ),
    );
  }
}