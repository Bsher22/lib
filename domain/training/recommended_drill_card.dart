// lib/widgets/domain/training/recommended_drill_card.dart
// Enhanced version that supports both individual parameters and drill map
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';

class RecommendedDrillCard extends StatelessWidget {
  final String name;
  final String description;
  final String? repetitions;
  final String? frequency;
  final List<String>? keyPoints;
  final VoidCallback? onTap;
  final String? priorityLevel;
  final bool isExpanded;
  
  const RecommendedDrillCard({
    Key? key,
    required this.name,
    required this.description,
    this.repetitions,
    this.frequency,
    this.keyPoints,
    this.onTap,
    this.priorityLevel,
    this.isExpanded = false,
  }) : super(key: key);
  
  // Factory constructor to create from drill map
  factory RecommendedDrillCard.fromDrill({
    Key? key,
    required Map<String, dynamic> drill,
    VoidCallback? onTap,
    bool isExpanded = false,
  }) {
    return RecommendedDrillCard(
      key: key,
      name: drill['name'] as String? ?? 'Training Drill',
      description: drill['description'] as String? ?? 'Fundamental practice drill',
      repetitions: drill['repetitions'] as String?,
      frequency: drill['frequency'] as String?,
      keyPoints: (drill['keyPoints'] as List<dynamic>?)?.cast<String>() ?? 
                (drill['key_points'] as List<dynamic>?)?.cast<String>(),
      priorityLevel: drill['priorityLevel'] as String? ?? drill['priority_level'] as String?,
      onTap: onTap,
      isExpanded: isExpanded,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return StandardCard(
      padding: const EdgeInsets.all(16),
      elevation: 2,
      borderRadius: 12,
      backgroundColor: Colors.purple.withOpacity(0.05),
      border: BorderSide(color: Colors.purple.withOpacity(0.2)),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with drill icon and priority
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 20,
                  color: Colors.purple[700],
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ),
              if (priorityLevel != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(priorityLevel!),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    priorityLevel!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: isExpanded ? null : 3,
            overflow: isExpanded ? null : TextOverflow.ellipsis,
          ),
          
          // Repetitions and frequency (if provided)
          if (repetitions != null || frequency != null) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
              ),
              child: Row(
                children: [
                  if (repetitions != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Repetitions',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            repetitions!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (repetitions != null && frequency != null) ...[
                    Container(
                      width: 1,
                      height: 30,
                      color: Colors.purple[300],
                    ),
                    SizedBox(width: 12),
                  ],
                  if (frequency != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Frequency',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[700],
                            ),
                          ),
                          Text(
                            frequency!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          
          // Key points (if provided)
          if (keyPoints != null && keyPoints!.isNotEmpty) ...[
            SizedBox(height: 12),
            Text(
              'Key Points',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.purple[800],
              ),
            ),
            SizedBox(height: 6),
            ...keyPoints!.take(isExpanded ? keyPoints!.length : 3).map((point) => Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 12,
                    color: Colors.purple[600],
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      point,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.purple[700],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
            if (!isExpanded && keyPoints!.length > 3) ...[
              SizedBox(height: 4),
              Text(
                '... and ${keyPoints!.length - 3} more points',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.purple[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
  
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red[700]!;
      case 'high': return Colors.orange[700]!;
      case 'medium':
      case 'moderate': return Colors.yellow[700]!;
      default: return Colors.green[700]!;
    }
  }
}