import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hockey_shot_tracker/models/shot.dart';

class ShotDistributionChart extends StatelessWidget {
  final List<Shot> filteredShots;

  const ShotDistributionChart({Key? key, required this.filteredShots})
      : super(key: key);

  // Colors for outcomes (used for stacked bars and legend)
  Color _getOutcomeColor(String outcome) {
    switch (outcome) {
      case 'Goal':
        return Colors.green;
      case 'Save':
        return Colors.blue;
      case 'Miss':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle empty data
    if (filteredShots.isEmpty) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: const Center(child: Text('No shots available')),
      );
    }

    // Group shots by type and outcome
    final data = <String, Map<String, int>>{};
    for (final shot in filteredShots) {
      final type = shot.type ?? 'Unknown';
      final outcome = shot.outcome ?? 'Unknown';
      data[type] ??= {'Goal': 0, 'Save': 0, 'Miss': 0, 'Unknown': 0};
      data[type]![outcome] = (data[type]![outcome] ?? 0) + 1;
    }

    // Define possible outcomes for consistent stacking order
    const outcomes = ['Goal', 'Save', 'Miss', 'Unknown'];

    // Create bar groups for each shot type
    final barGroups = data.entries.toList().asMap().entries.map((entry) {
      final index = entry.key;
      final shotType = entry.value.key;
      final outcomeCounts = entry.value.value;

      // Create stacked rods for each outcome
      final rods = outcomes.map((outcome) {
        final count = outcomeCounts[outcome]?.toDouble() ?? 0.0;
        return BarChartRodData(
          toY: count,
          color: _getOutcomeColor(outcome),
          width: data.length > 6 ? 8 : 12, // Narrower bars for many shot types
        );
      }).toList();

      return BarChartGroupData(
        x: index,
        barRods: rods,
      );
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart title
              Text(
                'Shot Distribution by Outcome',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
              const SizedBox(height: 16),
              // Bar chart with horizontal scrolling for many shot types
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.35, // 35% of screen height
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: data.length * 60.0, // Dynamic width based on number of bars
                    child: BarChart(
                      BarChartData(
                        barGroups: barGroups,
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < data.keys.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      data.keys.elementAt(index),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey[700],
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(show: false),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final shotType = data.keys.elementAt(group.x);
                              final outcome = outcomes[rodIndex];
                              return BarTooltipItem(
                                '$shotType - $outcome: ${rod.toY.toInt()}',
                                const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Legend for outcomes
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: outcomes.map((outcome) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getOutcomeColor(outcome),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        outcome,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blueGrey[700],
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}