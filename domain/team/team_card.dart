// lib/widgets/domain/team/team_card.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/widgets/core/list/list_item_with_actions.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';

class TeamCard extends StatelessWidget {
  final Team team;
  final int playerCount;
  final int coachCount;
  final bool showActions;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onViewPlayersTap;
  final VoidCallback? onViewStatsTap;
  final Color? highlightColor;
  final String? statusBadgeText;
  final Color? statusBadgeColor;
  
  const TeamCard({
    Key? key,
    required this.team,
    this.playerCount = 0,
    this.coachCount = 0,
    this.showActions = true,
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
    this.onEditTap,
    this.onViewPlayersTap,
    this.onViewStatsTap,
    this.highlightColor,
    this.statusBadgeText,
    this.statusBadgeColor,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    // Create actions list
    final actions = <Widget>[];
    
    // Add status badge if provided
    if (statusBadgeText != null) {
      actions.add(
        StatusBadge(
          text: statusBadgeText!,
          color: statusBadgeColor ?? Colors.green[700]!,
          size: StatusBadgeSize.small,
        ),
      );
    }
    
    // Add action buttons if needed
    if (showActions) {
      // View players button
      if (onViewPlayersTap != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.people,
            tooltip: 'View Players',
            onPressed: onViewPlayersTap,
          ),
        );
      }
      
      // View stats button
      if (onViewStatsTap != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.bar_chart,
            tooltip: 'View Stats',
            onPressed: onViewStatsTap,
          ),
        );
      }
      
      // Edit button
      if (onEditTap != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.edit,
            tooltip: 'Edit Team',
            onPressed: onEditTap,
          ),
        );
      }
    }
    
    // Create team logo/icon
    final leading = isSelectable
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap?.call(),
                activeColor: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildTeamLogo(),
            ],
          )
        : _buildTeamLogo();
    
    // Create stats subtitle
    final stats = <String>[];
    if (playerCount > 0 || team.playerCount > 0) {
      stats.add('${playerCount > 0 ? playerCount : team.playerCount} ${playerCount == 1 || team.playerCount == 1 ? 'player' : 'players'}');
    }
    if (coachCount > 0) {
      stats.add('$coachCount ${coachCount == 1 ? 'coach' : 'coaches'}');
    }
    if (team.createdAt != null) {
      stats.add('Created: ${_formatDate(team.createdAt!)}');
    }
    
    final subtitle2 = stats.isNotEmpty ? stats.join(' • ') : null;
    
    // Create the list item
    return ListItemWithActions(
      leading: leading,
      title: team.name,
      subtitle: team.description,
      subtitle2: subtitle2,
      actions: actions,
      onTap: onTap,
      isSelected: isSelected,
      selectedColor: highlightColor ?? Colors.blue[50],
      padding: const EdgeInsets.all(12),
      leadingSpacing: 16,
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
  
  Widget _buildTeamLogo() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.blueGrey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: team.logoPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                team.logoPath!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => 
                  Icon(Icons.sports_hockey, size: 30, color: Colors.blueGrey[400]),
              ),
            )
          : Icon(Icons.sports_hockey, size: 30, color: Colors.blueGrey[400]),
    );
  }
  
  /// Formats a date into readable text
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}