// widgets/cards/stat_item_card.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';

class StatItemCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;
  final VoidCallback? onTap;
  
  const StatItemCard({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return StandardCard(
      padding: const EdgeInsets.all(16),
      elevation: 2,
      borderRadius: 12,
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.blueGrey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}