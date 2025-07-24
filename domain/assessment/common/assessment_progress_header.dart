// lib/widgets/domain/assessment/common/assessment_progress_header.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

/// A responsive reusable widget for displaying progress through an assessment
class AssessmentProgressHeader extends StatelessWidget {
  /// Title of the current group
  final String groupTitle;

  /// Description of the current group
  final String groupDescription;

  /// Current group index (0-based)
  final int currentGroupIndex;

  /// Total number of groups
  final int totalGroups;

  /// Current test/item index within the group (0-based)
  final int currentItemIndex;

  /// Total number of tests/items in current group
  final int totalItems;

  /// Overall progress value (0.0 to 1.0)
  final double progressValue;

  /// Optional color for progress indicator
  final Color? progressColor;

  /// Optional widget to display above the group information
  final Widget? topContent;

  /// Optional widget to display below the progress bar
  final Widget? bottomContent;

  /// Optional widget to display between progress text and bottom content
  final Widget? additionalContent;

  const AssessmentProgressHeader({
    Key? key,
    required this.groupTitle,
    required this.groupDescription,
    required this.currentGroupIndex,
    required this.totalGroups,
    required this.currentItemIndex,
    required this.totalItems,
    required this.progressValue,
    this.progressColor,
    this.topContent,
    this.bottomContent,
    this.additionalContent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 2)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top content if provided
          if (topContent != null) ...[
            topContent!,
            SizedBox(height: ResponsiveConfig.spacing(context, 2)),
          ],

          // Responsive layout for group information
          context.responsive<Widget>(
            mobile: _buildMobileGroupInfo(context),
            tablet: _buildTabletGroupInfo(context),
            desktop: _buildDesktopGroupInfo(context),
          ),

          SizedBox(height: ResponsiveConfig.spacing(context, 2)),

          // Progress indicator - always full width but responsive sizing
          _buildProgressIndicator(context),

          SizedBox(height: ResponsiveConfig.spacing(context, 1)),

          // Progress text - responsive layout
          _buildProgressText(context),

          // Additional content if provided
          if (additionalContent != null) ...[
            SizedBox(height: ResponsiveConfig.spacing(context, 2)),
            additionalContent!,
          ],

          // Bottom content if provided
          if (bottomContent != null) ...[
            SizedBox(height: ResponsiveConfig.spacing(context, 2)),
            bottomContent!,
          ],
        ],
      ),
    );
  }

  Widget _buildMobileGroupInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 16),
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: ResponsiveConfig.spacing(context, 0.5)),
        Text(
          groupDescription,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 14),
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTabletGroupInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          groupTitle,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        SizedBox(height: ResponsiveConfig.spacing(context, 0.5)),
        Text(
          groupDescription,
          style: TextStyle(
            fontSize: ResponsiveConfig.fontSize(context, 15),
            color: Colors.blueGrey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopGroupInfo(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupTitle,
                style: TextStyle(
                  fontSize: ResponsiveConfig.fontSize(context, 20),
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              SizedBox(height: ResponsiveConfig.spacing(context, 0.5)),
              Text(
                groupDescription,
                style: TextStyle(
                  fontSize: ResponsiveConfig.fontSize(context, 16),
                  color: Colors.blueGrey[600],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: EdgeInsets.all(ResponsiveConfig.spacing(context, 1.5)),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              children: [
                Text(
                  '${(progressValue * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.fontSize(context, 24),
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                Text(
                  'Complete',
                  style: TextStyle(
                    fontSize: ResponsiveConfig.fontSize(context, 12),
                    color: Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
                progressColor ?? Colors.cyanAccent[700]!),
            minHeight: context.responsive<double>(
              mobile: 6,
              tablet: 8,
              desktop: 10,
            ),
            borderRadius: BorderRadius.circular(
              context.responsive<double>(
                mobile: 3,
                tablet: 4,
                desktop: 5,
              ),
            ),
          ),
        ),
        SizedBox(width: ResponsiveConfig.spacing(context, 2)),
        // Show percentage on mobile/tablet, hide on desktop (shown in sidebar)
        if (!context.isDesktop)
          Text(
            '${(progressValue * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[700],
              fontSize: ResponsiveConfig.fontSize(context, 14),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressText(BuildContext context) {
    return context.responsive<Widget>(
      mobile: _buildMobileProgressText(context),
      tablet: _buildTabletProgressText(context),
      desktop: _buildDesktopProgressText(context),
    );
  }

  Widget _buildMobileProgressText(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Group ${currentGroupIndex + 1} of $totalGroups',
              style: TextStyle(
                fontSize: ResponsiveConfig.fontSize(context, 12),
                color: Colors.blueGrey[600],
              ),
            ),
            Text(
              'Item ${currentItemIndex + 1} of $totalItems',
              style: TextStyle(
                fontSize: ResponsiveConfig.fontSize(context, 12),
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletProgressText(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.spacing(context, 1),
            vertical: ResponsiveConfig.spacing(context, 0.5),
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Group ${currentGroupIndex + 1} of $totalGroups',
            style: TextStyle(
              fontSize: ResponsiveConfig.fontSize(context, 12),
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.spacing(context, 1),
            vertical: ResponsiveConfig.spacing(context, 0.5),
          ),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            'Item ${currentItemIndex + 1} of $totalItems',
            style: TextStyle(
              fontSize: ResponsiveConfig.fontSize(context, 12),
              color: Colors.blueGrey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopProgressText(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.spacing(context, 2),
            vertical: ResponsiveConfig.spacing(context, 1),
          ),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.group_work, color: Colors.blue[700], size: 16),
              SizedBox(width: ResponsiveConfig.spacing(context, 0.5)),
              Text(
                'Group ${currentGroupIndex + 1} of $totalGroups',
                style: TextStyle(
                  fontSize: ResponsiveConfig.fontSize(context, 13),
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: ResponsiveConfig.spacing(context, 2)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveConfig.spacing(context, 2),
            vertical: ResponsiveConfig.spacing(context, 1),
          ),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.sports_hockey, color: Colors.green[700], size: 16),
              SizedBox(width: ResponsiveConfig.spacing(context, 0.5)),
              Text(
                'Shot ${currentItemIndex + 1} of $totalItems',
                style: TextStyle(
                  fontSize: ResponsiveConfig.fontSize(context, 13),
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}