// lib/widgets/domain/player/player_card.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/widgets/core/list/list_item_with_actions.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';

class PlayerCard extends StatelessWidget {
  final Player player;
  final bool showTeam;
  final bool showCoach;
  final bool showCoordinator;
  final bool showActions;
  final bool isSelectable;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onEditTap;
  final VoidCallback? onAssignTap;
  final VoidCallback? onViewStats;
  final Color? highlightColor;
  final bool showBadges;
  
  const PlayerCard({
    Key? key,
    required this.player,
    this.showTeam = true,
    this.showCoach = true,
    this.showCoordinator = false,
    this.showActions = true,
    this.isSelectable = false,
    this.isSelected = false,
    this.onTap,
    this.onEditTap,
    this.onAssignTap,
    this.onViewStats,
    this.highlightColor,
    this.showBadges = true,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final userRole = appState.getCurrentUserRole() ?? '';
    
    // Determine if the current user can edit this player
    final canEdit = userRole == 'admin' || 
                    userRole == 'director' || 
                    (userRole == 'coordinator' && player.coordinatorId == appState.currentUser?['id']) ||
                    (userRole == 'coach' && player.primaryCoachId == appState.currentUser?['id']);
                     
    // Look up team info if showing team
    Team? team;
    if (showTeam && player.teamId != null) {
      team = appState.teams.firstWhereOrNull(
        (t) => t.id == player.teamId, 
        orElse: () => null,
      );
    }
    
    // Add performance indicators if available
    final hasPerformanceData = player.id != null && appState.shots.isNotEmpty;
    
    // Create actions for the player item
    final actions = <Widget>[];
    
    // Add status badge if needed
    if (showBadges) {
      actions.add(
        StatusBadge.success(
          text: 'Active',
          size: StatusBadgeSize.small,
        ),
      );
      
      // Performance indicator badge
      if (hasPerformanceData) {
        actions.add(
          Container(
            margin: const EdgeInsets.only(left: 8),
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: _getPerformanceColor(),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
          ),
        );
      }
    }
    
    // Add action buttons if needed
    if (showActions) {
      // Stats button
      if (onViewStats != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.bar_chart,
            tooltip: 'View Stats',
            onPressed: onViewStats,
          ),
        );
      }
      
      // Edit button
      if (canEdit && onEditTap != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.edit,
            tooltip: 'Edit Player',
            onPressed: onEditTap,
          ),
        );
      }
      
      // Assign button
      if (canEdit && onAssignTap != null) {
        actions.add(
          ListItemWithActions.createIconAction(
            icon: Icons.assignment_ind,
            tooltip: 'Assign Player',
            onPressed: onAssignTap,
          ),
        );
      }
    }
    
    // Create player avatar
    final leading = isSelectable
        ? Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap?.call(),
                activeColor: Colors.blue,
              ),
              CircleAvatar(
                radius: 24,
                backgroundColor: _getPlayerAvatarColor(),
                child: Text(
                  player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          )
        : CircleAvatar(
            radius: 24,
            backgroundColor: _getPlayerAvatarColor(),
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
    
    // Build subtitle text
    String? subtitle = player.position;
    String? subtitle2;
    
    // Team info
    if (showTeam && team != null) {
      subtitle2 = "Team: ${team.name}";
    }
    
    // Coach info
    if (showCoach && player.primaryCoachName != null) {
      subtitle2 = subtitle2 != null 
          ? "$subtitle2 • Coach: ${player.primaryCoachName}"
          : "Coach: ${player.primaryCoachName}";
    }
    
    // Coordinator info
    if (showCoordinator && player.coordinatorName != null) {
      subtitle2 = subtitle2 != null 
          ? "$subtitle2 • Coordinator: ${player.coordinatorName}"
          : "Coordinator: ${player.coordinatorName}";
    }
    
    // Use ListItemWithActions for consistent list items
    return ListItemWithActions(
      leading: leading,
      title: player.name,
      subtitle: subtitle,
      subtitle2: subtitle2,
      actions: actions,
      onTap: onTap,
      isSelected: isSelected,
      selectedColor: highlightColor ?? Colors.blue[50],
      showDivider: false,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
    );
  }
  
  // Get color for player avatar based on position or other attributes
  Color _getPlayerAvatarColor() {
    // This could be based on position, team, or other player attributes
    return Colors.blueGrey;
  }
  
  // Get color for performance indicator
  Color _getPerformanceColor() {
    // This would be based on actual performance data
    // Green: Improving, Orange: Stable, Red: Declining
    return Colors.green;
  }
}

// Extension method for firstWhereOrNull
extension IterableExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E) test, {E Function()? orElse}) {
    for (var element in this) {
      if (test(element)) return element;
    }
    if (orElse != null) {
      return orElse();
    }
    return null;
  }
}