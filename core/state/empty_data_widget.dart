import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';

class EmptyDataWidget extends StatelessWidget {
  final Player? selectedPlayer;

  const EmptyDataWidget({
    Key? key,
    required this.selectedPlayer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.sports_hockey,
            size: 64,
            color: Colors.blueGrey[200],
          ),
          const SizedBox(height: 16),
          Text(
            'No Shot Data Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Record shots for ${selectedPlayer?.name} to see analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.blueGrey[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/shot-input'),
            icon: const Icon(Icons.add),
            label: const Text('Record Shots'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}