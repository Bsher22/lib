// File: lib/widgets/domain/assessment/common/assessment_setup_form.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/domain/assessment/common/assessment_type_selector.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/searchable_player_dropdown.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// Enhanced responsive unified setup form for assessments
class AssessmentSetupForm extends StatefulWidget {
  /// Title to display at the top of the form
  final String title;

  /// Type of assessment ('shot' or 'skating')
  final String assessmentType;

  /// Currently selected assessment subtype
  final String selectedAssessmentSubtype;

  /// Map of assessment subtypes with their details
  final Map<String, Map<String, dynamic>> assessmentSubtypes;

  /// Available players to select from
  final List<Player> players;

  /// Currently selected player
  final Player? selectedPlayer;

  /// Display style for the assessment type selector ('radio' or 'card')
  final String displayStyle;

  /// Callback function for when the assessment subtype changes
  final Function(String) onAssessmentSubtypeChanged;

  /// Callback function for when the player changes
  final Function(Player?) onPlayerChanged;

  /// Custom builder for the preview section
  final Widget Function(BuildContext, String)? previewBuilder;

  /// Optional additional form fields
  final List<Widget>? additionalFields;

  const AssessmentSetupForm({
    Key? key,
    required this.title,
    required this.assessmentType,
    required this.selectedAssessmentSubtype,
    required this.assessmentSubtypes,
    required this.players,
    required this.selectedPlayer,
    this.displayStyle = 'radio',
    required this.onAssessmentSubtypeChanged,
    required this.onPlayerChanged,
    this.previewBuilder,
    this.additionalFields,
  }) : super(key: key);

  @override
  _AssessmentSetupFormState createState() => _AssessmentSetupFormState();
}

class _AssessmentSetupFormState extends State<AssessmentSetupForm> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 2)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.title.isNotEmpty) ...[
            Text(
              widget.title,
              style: TextStyle(
                fontSize: ResponsiveConfig.fontSize(context, 24),
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: ResponsiveConfig.spacing(context, 3)),
          ],

          // Responsive layout
          context.responsive<Widget>(
            mobile: _buildMobileLayout(),
            tablet: _buildTabletLayout(),
            desktop: _buildDesktopLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Player selection first on mobile
        _buildPlayerSection(),
        SizedBox(height: ResponsiveConfig.spacing(context, 3)),
        
        // Assessment type selection
        _buildAssessmentTypeSection(),
        SizedBox(height: ResponsiveConfig.spacing(context, 3)),
        
        // Preview below on mobile
        _buildPreviewSection(),

        // Additional fields if provided
        if (widget.additionalFields != null) ...[
          SizedBox(height: ResponsiveConfig.spacing(context, 3)),
          ...widget.additionalFields!,
        ],
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        // Player selection (full width on tablet)
        _buildPlayerSection(),
        SizedBox(height: ResponsiveConfig.spacing(context, 3)),
        
        // Two-column layout for assessment type and preview
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: _buildAssessmentTypeSection(),
            ),
            SizedBox(width: ResponsiveConfig.spacing(context, 3)),
            Expanded(
              flex: 2,
              child: _buildPreviewSection(),
            ),
          ],
        ),

        // Additional fields if provided
        if (widget.additionalFields != null) ...[
          SizedBox(height: ResponsiveConfig.spacing(context, 3)),
          ...widget.additionalFields!,
        ],
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Player Selection and Assessment Type
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPlayerSection(),
              SizedBox(height: ResponsiveConfig.spacing(context, 4)),
              _buildAssessmentTypeSection(),

              // Additional fields if provided
              if (widget.additionalFields != null) ...[
                SizedBox(height: ResponsiveConfig.spacing(context, 3)),
                ...widget.additionalFields!,
              ],
            ],
          ),
        ),

        SizedBox(width: ResponsiveConfig.spacing(context, 4)),

        // Right Column - Assessment Preview (larger on desktop)
        Expanded(
          flex: 3,
          child: _buildPreviewSection(),
        ),
      ],
    );
  }

  Widget _buildPlayerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Player',
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
        _buildPlayerSelector(),
      ],
    );
  }

  Widget _buildAssessmentTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Assessment Type',
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
        _buildAssessmentTypeSelector(),
      ],
    );
  }

  Widget _buildPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Only show preview title on larger screens
        if (!context.isMobile) ...[
          Text(
            'Assessment Preview',
            style: TextStyle(
              fontSize: ResponsiveConfig.fontSize(context, 18),
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
        ],
        _buildPreview(context),
      ],
    );
  }

  Widget _buildAssessmentTypeSelector() {
    if (widget.assessmentType == 'shot') {
      return AssessmentTypeSelector.forShotAssessment(
        selectedType: widget.selectedAssessmentSubtype,
        onTypeSelected: widget.onAssessmentSubtypeChanged,
        assessmentTypes: widget.assessmentSubtypes,
        displayStyle: widget.displayStyle,
      );
    } else {
      return AssessmentTypeSelector.forSkatingAssessment(
        selectedType: widget.selectedAssessmentSubtype,
        onTypeSelected: widget.onAssessmentSubtypeChanged,
        assessmentTypes: widget.assessmentSubtypes,
        displayStyle: widget.displayStyle,
      );
    }
  }

  Widget _buildPlayerSelector() {
    if (widget.players.isEmpty) {
      return Container(
        height: context.responsive<double>(
          mobile: 60,
          tablet: 65,
          desktop: 70,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[400]!),
                ),
              ),
              SizedBox(width: ResponsiveConfig.spacing(context, 1.5)),
              Text(
                'Loading players...',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: ResponsiveConfig.fontSize(context, 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SearchablePlayerDropdown(
      selectedPlayer: widget.selectedPlayer,
      players: widget.players,
      onChanged: (player) {
        widget.onPlayerChanged(player);
      },
      labelText: 'Player',
      hintText: 'Search for a player by name, jersey number, position, or team...',
      required: true,
      helperText: widget.players.length == 1 
          ? '1 player available'
          : '${widget.players.length} players available',
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (widget.previewBuilder != null) {
      return widget.previewBuilder!(context, widget.selectedAssessmentSubtype);
    }

    final assessmentData = widget.assessmentSubtypes[widget.selectedAssessmentSubtype] ?? {};

    return Container(
      padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 2)),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blueGrey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header (mobile shows this)
          if (context.isMobile)
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Colors.blueGrey[700],
                  size: 20,
                ),
                SizedBox(width: ResponsiveConfig.spacing(context, 1)),
                Text(
                  'Assessment Preview',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.fontSize(context, 16),
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          
          if (context.isMobile) SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
          
          // Selected player info
          if (widget.selectedPlayer != null)
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 1.5)),
              margin: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 1.5)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: context.responsive<double>(
                      mobile: 14,
                      tablet: 16,
                      desktop: 18,
                    ),
                    backgroundColor: Colors.blue[600],
                    child: Text(
                      widget.selectedPlayer!.name.isNotEmpty 
                          ? widget.selectedPlayer!.name[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: ResponsiveConfig.fontSize(context, 14),
                      ),
                    ),
                  ),
                  SizedBox(width: ResponsiveConfig.spacing(context, 1.5)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectedPlayer!.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: ResponsiveConfig.fontSize(context, 14),
                          ),
                        ),
                        if (widget.selectedPlayer!.jerseyNumber != null ||
                            widget.selectedPlayer!.position != null)
                          Text(
                            [
                              if (widget.selectedPlayer!.jerseyNumber != null)
                                '#${widget.selectedPlayer!.jerseyNumber}',
                              if (widget.selectedPlayer!.position != null)
                                widget.selectedPlayer!.position!,
                              if (widget.selectedPlayer!.ageGroup != null)
                                _formatAgeGroup(widget.selectedPlayer!.ageGroup!),
                            ].join(' • '),
                            style: TextStyle(
                              fontSize: ResponsiveConfig.fontSize(context, 12),
                              color: Colors.blue[700],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          
          // Assessment title and description
          if (assessmentData['title'] != null) ...[
            Text(
              assessmentData['title'] as String,
              style: TextStyle(
                fontSize: ResponsiveConfig.fontSize(context, 16),
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            SizedBox(height: ResponsiveConfig.spacing(context, 1)),
          ],
          
          Text(
            assessmentData['description'] as String? ?? 'No description available',
            style: TextStyle(
              fontSize: ResponsiveConfig.fontSize(context, 14),
              color: Colors.blueGrey[600],
            ),
          ),
          
          // Assessment details
          if (assessmentData.containsKey('estimatedDuration') || assessmentData.containsKey('totalShots')) ...[
            SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
            Container(
              padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 1)),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  if (assessmentData['estimatedDuration'] != null)
                    Row(
                      children: [
                        Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                        SizedBox(width: ResponsiveConfig.spacing(context, 0.75)),
                        Text(
                          'Duration: ${assessmentData['estimatedDuration']} minutes',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.fontSize(context, 12),
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  if (assessmentData['totalShots'] != null) ...[
                    SizedBox(height: ResponsiveConfig.spacing(context, 0.5)),
                    Row(
                      children: [
                        Icon(Icons.sports_hockey, size: 16, color: Colors.grey[600]),
                        SizedBox(width: ResponsiveConfig.spacing(context, 0.75)),
                        Text(
                          'Total Shots: ${assessmentData['totalShots']}',
                          style: TextStyle(
                            fontSize: ResponsiveConfig.fontSize(context, 12),
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          if (assessmentData.containsKey('groups')) ...[
            SizedBox(height: ResponsiveConfig.spacing(context, 2)),
            Text(
              widget.assessmentType == 'shot' ? 'Shot Groups:' : 'Test Groups:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
                fontSize: ResponsiveConfig.fontSize(context, 14),
              ),
            ),
            SizedBox(height: ResponsiveConfig.spacing(context, 1)),
            _buildGroupsList(assessmentData['groups'] as List? ?? []),
          ],
        ],
      ),
    );
  }

  String _formatAgeGroup(String ageGroup) {
    switch (ageGroup) {
      case 'youth_12_14':
        return 'Youth 12-14';
      case 'youth_15_18':
        return 'Youth 15-18';
      case 'adult':
        return 'Adult';
      case 'senior':
        return 'Senior';
      default:
        return ageGroup.replaceAll('_', ' ').toUpperCase();
    }
  }

  Widget _buildGroupsList(List groups) {
    int totalItems = 0;
    for (var group in groups) {
      if (widget.assessmentType == 'shot') {
        totalItems += group['shots'] as int? ?? 0;
      } else if (group.containsKey('tests')) {
        totalItems += (group['tests'] as List?)?.length ?? 0;
      }
    }

    return Column(
      children: [
        for (int i = 0; i < groups.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: ResponsiveConfig.spacing(context, 0.75)),
            child: Row(
              children: [
                Container(
                  width: context.responsive<double>(
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  height: context.responsive<double>(
                    mobile: 18,
                    tablet: 20,
                    desktop: 22,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: ResponsiveConfig.fontSize(context, 11),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: ResponsiveConfig.spacing(context, 1)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        groups[i]['title'] as String? ?? 'Untitled Group',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: ResponsiveConfig.fontSize(context, 13),
                        ),
                      ),
                      Text(
                        widget.assessmentType == 'shot'
                            ? '${groups[i]['shots'] as int? ?? 0} shots'
                            : groups[i].containsKey('tests')
                                ? '${(groups[i]['tests'] as List?)?.length ?? 0} tests'
                                : 'No tests',
                        style: TextStyle(
                          fontSize: ResponsiveConfig.fontSize(context, 11),
                          color: Colors.blueGrey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: ResponsiveConfig.spacing(context, 1.5)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.spacing(context, 1.5),
            vertical: ResponsiveConfig.spacing(context, 0.5),
          ),
          decoration: BoxDecoration(
            color: Colors.cyanAccent[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.assessmentType == 'shot'
                ? 'Total: $totalItems shots'
                : 'Total: $totalItems tests',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
              fontSize: ResponsiveConfig.fontSize(context, 13),
            ),
          ),
        ),
      ],
    );
  }

  /// Factory constructor for shot assessment setup
  static AssessmentSetupForm forShotAssessment({
    required String selectedAssessmentSubtype,
    required Map<String, Map<String, dynamic>> assessmentSubtypes,
    required List<Player> players,
    required Player? selectedPlayer,
    String title = 'Shot Assessment Setup',
    String displayStyle = 'card',
    required Function(String) onAssessmentSubtypeChanged,
    required Function(Player?) onPlayerChanged,
    Widget Function(BuildContext, String)? previewBuilder,
    List<Widget>? additionalFields,
  }) {
    return AssessmentSetupForm(
      title: title,
      assessmentType: 'shot',
      selectedAssessmentSubtype: selectedAssessmentSubtype,
      assessmentSubtypes: assessmentSubtypes,
      players: players,
      selectedPlayer: selectedPlayer,
      displayStyle: displayStyle,
      onAssessmentSubtypeChanged: onAssessmentSubtypeChanged,
      onPlayerChanged: onPlayerChanged,
      previewBuilder: previewBuilder,
      additionalFields: additionalFields,
    );
  }

  /// Factory constructor for skating assessment setup
  static AssessmentSetupForm forSkatingAssessment({
    required String selectedAssessmentSubtype,
    required Map<String, Map<String, dynamic>> assessmentSubtypes,
    required List<Player> players,
    required Player? selectedPlayer,
    String title = 'Skating Assessment Setup',
    String displayStyle = 'card',
    required Function(String) onAssessmentSubtypeChanged,
    required Function(Player?) onPlayerChanged,
    Widget Function(BuildContext, String)? previewBuilder,
    List<Widget>? additionalFields,
  }) {
    return AssessmentSetupForm(
      title: title,
      assessmentType: 'skating',
      selectedAssessmentSubtype: selectedAssessmentSubtype,
      assessmentSubtypes: assessmentSubtypes,
      players: players,
      selectedPlayer: selectedPlayer,
      displayStyle: displayStyle,
      onAssessmentSubtypeChanged: onAssessmentSubtypeChanged,
      onPlayerChanged: onPlayerChanged,
      previewBuilder: previewBuilder,
      additionalFields: additionalFields,
    );
  }
}