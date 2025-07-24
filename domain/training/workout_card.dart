// lib/widgets/domain/training/workout_card.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';

class WorkoutCard extends StatelessWidget {
  final Map<String, String> workout;
  final VoidCallback onSelect;

  const WorkoutCard({super.key, required this.workout, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return StandardCard(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 4,
      borderRadius: 16,
      border: BorderSide(color: Colors.blueGrey[200]!, width: 0.5),
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  workout['name']!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
                Text(
                  workout['duration']!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              workout['description']!,
              style: TextStyle(
                fontSize: 16,
                color: Colors.blueGrey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Drills: ${workout['drills']!}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[500],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Select',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}