// lib/widgets/domain/player/player_action_buttons.dart

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';

/// A widget that displays action buttons for player management
class PlayerActionButtons extends StatelessWidget {
  final Player player;
  final VoidCallback? onEdit;
  final VoidCallback? onAssignCoach;
  final VoidCallback? onAssignTeam;
  final VoidCallback? onRecordShot;
  final VoidCallback? onRecordSkating; // NEW: Record skating callback
  final VoidCallback? onViewAnalytics;
  final VoidCallback? onViewSkatingAnalytics; // NEW: View skating analytics

  const PlayerActionButtons({
    Key? key,
    required this.player,
    this.onEdit,
    this.onAssignCoach,
    this.onAssignTeam,
    this.onRecordShot,
    this.onRecordSkating, // NEW
    this.onViewAnalytics,
    this.onViewSkatingAnalytics, // NEW
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            if (onEdit != null)
              _buildActionButton(
                'Edit Profile',
                Icons.edit,
                Colors.blue,
                onEdit!,
              ),
            if (onAssignCoach != null)
              _buildActionButton(
                'Assign to Coach',
                Icons.sports,
                Colors.green,
                onAssignCoach!,
              ),
            if (onAssignTeam != null)
              _buildActionButton(
                'Assign to Team',
                Icons.group,
                Colors.orange,
                onAssignTeam!,
              ),
            if (onRecordShot != null)
              _buildActionButton(
                'Record Shot',
                Icons.sports_hockey,
                Colors.purple,
                onRecordShot!,
              ),
            if (onRecordSkating != null) // NEW: Skating record button
              _buildActionButton(
                'Record Skating',
                Icons.speed,
                Colors.teal,
                onRecordSkating!,
              ),
            if (onViewAnalytics != null)
              _buildActionButton(
                'Shot Analytics',
                Icons.bar_chart,
                Colors.indigo,
                onViewAnalytics!,
              ),
            if (onViewSkatingAnalytics != null) // NEW: Skating analytics button
              _buildActionButton(
                'Skating Analytics',
                Icons.analytics,
                Colors.cyan,
                onViewSkatingAnalytics!,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}