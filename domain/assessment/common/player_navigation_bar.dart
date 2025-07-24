// widgets/assessment/common/player_navigation_bar.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';

/// A reusable widget for navigating between players in an assessment
class PlayerNavigationBar extends StatelessWidget {
  /// List of players available for navigation
  final List<Player> players;
  
  /// Index of the currently selected player
  final int currentIndex;
  
  /// Callback when previous button is pressed
  final VoidCallback onPrevious;
  
  /// Callback when next button is pressed
  final VoidCallback onNext;
  
  /// Optional text to display in the center (defaults to player count)
  final String? centerText;
  
  /// Optional button style to apply to navigation buttons
  final ButtonStyle? buttonStyle;
  
  const PlayerNavigationBar({
    Key? key,
    required this.players,
    required this.currentIndex,
    required this.onPrevious,
    required this.onNext,
    this.centerText,
    this.buttonStyle,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final defaultButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: Colors.grey[200],
      foregroundColor: Colors.blueGrey[700],
    );
    
    final effectiveButtonStyle = buttonStyle ?? defaultButtonStyle;
    
    return Row(
      children: [
        ElevatedButton.icon(
          onPressed: currentIndex > 0 ? onPrevious : null,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Previous'),
          style: effectiveButtonStyle,
        ),
        Expanded(
          child: Center(
            child: Text(
              centerText ?? 'Player ${currentIndex + 1} of ${players.length}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[700],
              ),
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: currentIndex < players.length - 1 ? onNext : null,
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Next'),
          style: effectiveButtonStyle,
        ),
      ],
    );
  }
}