// widgets/assessment/common/training_plan_widget.dart
import 'package:flutter/material.dart';

/// A reusable widget for displaying a training plan week with sessions
class TrainingPlanWidget extends StatelessWidget {
  /// Title of the training week (e.g., "Week 1: Foundation")
  final String title;
  
  /// Description of the training focus for the week
  final String description;
  
  /// List of sessions for this training week
  final List<String> sessions;
  
  /// Optional custom color for the container
  final Color? backgroundColor;
  
  /// Optional custom color for the border
  final Color? borderColor;
  
  const TrainingPlanWidget({
    Key? key,
    required this.title,
    required this.description,
    required this.sessions,
    this.backgroundColor,
    this.borderColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blueGrey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? Colors.blueGrey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blueGrey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(),
          const SizedBox(height: 8),
          for (var session in sessions)
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule, size: 14, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      session,
                      style: const TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}