import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';

class ZoneHeatmapWidget extends StatelessWidget {
  final Map<String, Map<String, dynamic>> zoneMetrics;
  final Map<String, String> zoneLabels;
  final int totalShots;

  const ZoneHeatmapWidget({
    Key? key,
    required this.zoneMetrics,
    required this.zoneLabels,
    required this.totalShots,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goalie View',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Success rate by zone (showing $totalShots shots)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: SizedBox(
                height: 300,
                child: _buildZoneHeatmapVisualization(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildColorLegend('0-20%', Colors.red),
                _buildColorLegend('21-40%', Colors.orange),
                _buildColorLegend('41-60%', Colors.yellow),
                _buildColorLegend('61-80%', Colors.lightGreen),
                _buildColorLegend('81-100%', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneHeatmapVisualization() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeatmapZoneCell('1'),
              _buildHeatmapZoneCell('2'),
              _buildHeatmapZoneCell('3'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeatmapZoneCell('4'),
              _buildHeatmapZoneCell('5'),
              _buildHeatmapZoneCell('6'),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildHeatmapZoneCell('7'),
              _buildHeatmapZoneCell('8'),
              _buildHeatmapZoneCell('9'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapZoneCell(String zone) {
    final metrics = zoneMetrics[zone];
    final label = zoneLabels[zone] ?? '';

    if (metrics == null) {
      return _buildEmptyHeatmapCell(zone, label);
    }

    final count = metrics['count'] as int;
    final successRate = metrics['successRate'] as double;

    if (count == 0) {
      return _buildEmptyHeatmapCell(zone, label);
    }

    Color cellColor;
    if (successRate < 0.2) {
      cellColor = Colors.red;
    } else if (successRate < 0.4) {
      cellColor = Colors.orange;
    } else if (successRate < 0.6) {
      cellColor = Colors.yellow;
    } else if (successRate < 0.8) {
      cellColor = Colors.lightGreen;
    } else {
      cellColor = Colors.green;
    }

    return SizedBox(
      width: 90,
      height: 90,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cellColor.withOpacity(0.7),
          border: Border.all(
            color: Colors.black54,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
              Text(
                '${(successRate * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '$count shots',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyHeatmapCell(String zone, String label) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.black54,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'No data',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorLegend(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.blueGrey[700],
            ),
          ),
        ],
      ),
    );
  }
}