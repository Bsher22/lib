import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class PowerTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> weeklyTrends;

  const PowerTrendChart({
    Key? key,
    required this.weeklyTrends,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weeklyTrends.isEmpty) {
      return const Center(child: Text('No trend data available'));
    }

    final spots = <FlSpot>[];
    double maxPower = 0;

    for (int i = 0; i < weeklyTrends.length; i++) {
      final trend = weeklyTrends[i];
      final power = trend['avgPower'] as double;
      spots.add(FlSpot(i.toDouble(), power));
      if (power > maxPower) {
        maxPower = power;
      }
    }

    maxPower = (maxPower * 1.1).ceilToDouble();
    if (maxPower < 50) maxPower = 50;

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawHorizontalLine: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300],
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value % 1 != 0 ||
                      value < 0 ||
                      value >= weeklyTrends.length) {
                    return const SizedBox.shrink();
                  }
                  final week = weeklyTrends[value.toInt()]['weekStart'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MM/dd').format(week),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  if (value % 10 != 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey[300]!),
          ),
          minX: 0,
          maxX: (weeklyTrends.length - 1).toDouble(),
          minY: 0,
          maxY: maxPower,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.orange,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.orange.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}