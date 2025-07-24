import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/models/completed_workout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ImprovementTimeline extends StatefulWidget {
  final List<Shot> shots;
  final List<CompletedWorkout> completedWorkouts;
  final int timeRangeInDays;

  const ImprovementTimeline({
    super.key,
    required this.shots,
    required this.completedWorkouts,
    this.timeRangeInDays = 30, // Default to 30 days
  });

  @override
  State<ImprovementTimeline> createState() => _ImprovementTimelineState();
}

class _ImprovementTimelineState extends State<ImprovementTimeline> {
  final List<int> _timeRangeOptions = [7, 30, 90, 365]; // days
  late int _selectedTimeRange;

  @override
  void initState() {
    super.initState();
    _selectedTimeRange = widget.timeRangeInDays;
  }

  @override
  Widget build(BuildContext context) {
    final timelineData = _processTimelineData();
    final milestones = _processWorkoutMilestones();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context),
        const SizedBox(height: 16),
        _buildTimeRangeSelector(),
        const SizedBox(height: 16),
        timelineData.isEmpty
            ? _buildEmptyState()
            : _buildTimelineChart(timelineData, milestones),
        const SizedBox(height: 16),
        _buildMilestoneLegend(milestones),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Progress Over Time',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        _buildImprovementIndicator(),
      ],
    );
  }

  Widget _buildImprovementIndicator() {
    final improvement = _calculateImprovement();

    if (improvement == null) {
      return const SizedBox();
    }

    final color = improvement >= 0 ? Colors.green : Colors.red;
    final icon = improvement >= 0 ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '${improvement.abs().toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangeSelector() {
    return Center(
      child: SegmentedButton<int>(
        segments: _timeRangeOptions.map((days) {
          return ButtonSegment<int>(
            value: days,
            label: Text(_getTimeRangeLabel(days)),
          );
        }).toList(),
        selected: {_selectedTimeRange},
        onSelectionChanged: (newSelection) {
          setState(() {
            _selectedTimeRange = newSelection.first;
          });
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) {
              if (states.contains(WidgetState.selected)) {
                return Colors.cyanAccent;
              }
              return Colors.transparent;
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Not enough data to display timeline',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Record more shots over time to see your progress',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineChart(List<FlSpot> timelineData, List<Map<String, dynamic>> milestones) {
    double minY = 0;
    double maxY = 1;
    if (timelineData.isNotEmpty) {
      minY = timelineData.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
      maxY = timelineData.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);
      minY = (minY * 0.9).clamp(0.0, 1.0);
      maxY = (maxY * 1.1).clamp(minY + 0.1, 1.0);
    }

    final dateFormatter = _getDateFormatter();

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            horizontalInterval: 0.1,
            verticalInterval: 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
                dashArray: value == 0 ? null : [4, 4],
              );
            },
            getDrawingVerticalLine: (value) {
              return FlLine(
                color: Colors.grey[300]!,
                strokeWidth: 1,
                dashArray: [4, 4],
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= timelineData.length) {
                    return Container();
                  }
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    timelineData[value.toInt()].x.toInt(),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: _selectedTimeRange > 30 ? 0.5 : 0,
                      child: Text(
                        dateFormatter.format(date),
                        style: TextStyle(
                          color: Colors.blueGrey[700],
                          fontSize: 10,
                        ),
                      ),
                    ),
                  );
                },
                interval: _getXAxisInterval(timelineData.length),
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.blueGrey[700],
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                interval: 0.2,
              ),
            ),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: Colors.blueGrey[300]!, width: 1),
              bottom: BorderSide(color: Colors.blueGrey[300]!, width: 1),
              top: BorderSide.none,
              right: BorderSide.none,
            ),
          ),
          minX: 0,
          maxX: (timelineData.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              tooltipRoundedRadius: 8,
              tooltipBorder: BorderSide(color: Colors.blueGrey[800]!, width: 1),
              getTooltipColor: (_) => Colors.blueGrey[800]!.withAlpha(204),
              getTooltipItems: (List<LineBarSpot> touchedSpots) {
                return touchedSpots.map((spot) {
                  final date = DateTime.fromMillisecondsSinceEpoch(
                    spot.x.toInt(),
                  );
                  return LineTooltipItem(
                    '${DateFormat('MM/dd/yyyy').format(date)}\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    children: [
                      TextSpan(
                        text: 'Success Rate: ${(spot.y * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: timelineData,
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  bool isMilestone = milestones.any((m) {
                    return (spot.x - 86400000 <= m['timestamp'] &&
                        spot.x + 86400000 >= m['timestamp']);
                  });
                  return FlDotCirclePainter(
                    radius: isMilestone ? 6 : 4,
                    color: isMilestone ? Colors.amber : Colors.cyanAccent,
                    strokeWidth: isMilestone ? 2 : 0,
                    strokeColor: isMilestone ? Colors.amber.shade800 : Colors.transparent,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Colors.cyanAccent.withAlpha(52),
              ),
            ),
            LineChartBarData(
              spots: _calculateTrendLine(timelineData),
              isCurved: true,
              color: Colors.blueGrey.withAlpha(128),
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
              belowBarData: BarAreaData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: 0.8,
                color: Colors.green,
                strokeWidth: 1,
                dashArray: [5, 5],
                label: HorizontalLineLabel(
                  show: true,
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  labelResolver: (line) => 'Target',
                ),
              ),
            ],
            verticalLines: _buildWorkoutLines(milestones),
          ),
        ),
      ),
    );
  }

  List<VerticalLine> _buildWorkoutLines(List<Map<String, dynamic>> milestones) {
    final lines = <VerticalLine>[];

    for (final milestone in milestones) {
      final timestamp = milestone['timestamp'];
      int closestIndex = 0;
      double minDistance = double.infinity;

      for (int i = 0; i < widget.shots.length; i++) {
        final shotTimestamp = widget.shots[i].date.millisecondsSinceEpoch;
        final distance = (shotTimestamp - timestamp).abs();
        if (distance < minDistance) {
          minDistance = distance.toDouble();
          closestIndex = i;
        }
      }

      lines.add(
        VerticalLine(
          x: closestIndex.toDouble(),
          color: Colors.amber.withAlpha(128),
          strokeWidth: 2,
          dashArray: [5, 5],
          label: VerticalLineLabel(show: false),
        ),
      );
    }

    return lines;
  }

  Widget _buildMilestoneLegend(List<Map<String, dynamic>> milestones) {
    if (milestones.isEmpty) {
      return const SizedBox();
    }

    milestones.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));
    final recentMilestones = milestones.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Milestones',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
        const SizedBox(height: 8),
        ...recentMilestones.map((milestone) => _buildMilestoneItem(milestone)),
      ],
    );
  }

  Widget _buildMilestoneItem(Map<String, dynamic> milestone) {
    final date = DateTime.fromMillisecondsSinceEpoch(milestone['timestamp']);
    final dateStr = DateFormat('MMM d, yyyy').format(date);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber.shade800, width: 2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
                Text(
                  '$dateStr - ${milestone['description']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _processTimelineData() {
    if (widget.shots.isEmpty) {
      return [];
    }

    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedTimeRange));
    final filteredShots = widget.shots.where((shot) => shot.date.isAfter(cutoffDate)).toList();

    if (filteredShots.isEmpty) {
      return [];
    }

    final Map<String, List<Shot>> shotsByDay = {};
    for (final shot in filteredShots) {
      final dateKey = DateFormat('yyyy-MM-dd').format(shot.date);
      if (!shotsByDay.containsKey(dateKey)) {
        shotsByDay[dateKey] = [];
      }
      shotsByDay[dateKey]!.add(shot);
    }

    final List<MapEntry<DateTime, double>> successRateByDay = [];
    for (final entry in shotsByDay.entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      final shots = entry.value;
      final successfulShots = shots.where((s) => s.success).length;
      final successRate = shots.isNotEmpty ? successfulShots / shots.length : 0.0;
      successRateByDay.add(MapEntry(date, successRate));
    }

    successRateByDay.sort((a, b) => a.key.compareTo(b.key));

    final timelineData = successRateByDay.map((dateSuccessRate) {
      return FlSpot(
        dateSuccessRate.key.millisecondsSinceEpoch.toDouble(),
        dateSuccessRate.value,
      );
    }).toList();

    return timelineData;
  }

  List<Map<String, dynamic>> _processWorkoutMilestones() {
    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedTimeRange));
    final filteredWorkouts = widget.completedWorkouts
        .where((workout) => workout.dateCompleted.isAfter(cutoffDate))
        .toList();

    return filteredWorkouts.map((workout) {
      return {
        'timestamp': workout.dateCompleted.millisecondsSinceEpoch,
        'name': workout.programName ?? 'Workout',
        'description': '${workout.successfulShots}/${workout.totalShots} successful',
      };
    }).toList();
  }

  List<FlSpot> _calculateTrendLine(List<FlSpot> data) {
    if (data.length < 2) return data;

    const windowSize = 3;
    final trendLine = <FlSpot>[];

    for (int i = 0; i < data.length; i++) {
      int startIdx = (i - windowSize ~/ 2).clamp(0, data.length - 1);
      int endIdx = (i + windowSize ~/ 2).clamp(0, data.length - 1);

      double sum = 0;
      for (int j = startIdx; j <= endIdx; j++) {
        sum += data[j].y;
      }

      double avg = sum / (endIdx - startIdx + 1);
      trendLine.add(FlSpot(data[i].x, avg));
    }

    return trendLine;
  }

  double? _calculateImprovement() {
    if (widget.shots.isEmpty) return null;

    final cutoffDate = DateTime.now().subtract(Duration(days: _selectedTimeRange));
    final filteredShots = widget.shots.where((shot) => shot.date.isAfter(cutoffDate)).toList();

    if (filteredShots.length < 5) return null;

    filteredShots.sort((a, b) => a.date.compareTo(b.date));
    final midPoint = filteredShots.length ~/ 2;

    final firstHalf = filteredShots.sublist(0, midPoint);
    final secondHalf = filteredShots.sublist(midPoint);

    final firstHalfSuccess = firstHalf.where((s) => s.success).length / firstHalf.length;
    final secondHalfSuccess = secondHalf.where((s) => s.success).length / secondHalf.length;

    return (secondHalfSuccess - firstHalfSuccess) * 100;
  }

  String _getTimeRangeLabel(int days) {
    switch (days) {
      case 7:
        return '1W';
      case 30:
        return '1M';
      case 90:
        return '3M';
      case 365:
        return '1Y';
      default:
        return '${days}D';
    }
  }

  DateFormat _getDateFormatter() {
    switch (_selectedTimeRange) {
      case 7:
        return DateFormat('E');
      case 30:
        return DateFormat('MM/dd');
      case 90:
        return DateFormat('MM/dd');
      case 365:
        return DateFormat('MMM');
      default:
        return DateFormat('MM/dd');
    }
  }

  double _getXAxisInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 30) return 5;
    if (dataLength <= 90) return 15;
    return 30;
  }
}