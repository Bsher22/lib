import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TrainingImpactCalculator extends StatefulWidget {
  final int playerId;
  final int dateRange;

  const TrainingImpactCalculator({
    Key? key,
    required this.playerId,
    this.dateRange = 30,
  }) : super(key: key);

  @override
  _TrainingImpactCalculatorState createState() => _TrainingImpactCalculatorState();
}

class _TrainingImpactCalculatorState extends State<TrainingImpactCalculator> {
  bool _isLoading = true;
  Map<String, dynamic> _impactData = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTrainingImpact();
  }

  Future<void> _fetchTrainingImpact() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch training impact from API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analytics/training-impact/${widget.playerId}?date_range=${widget.dateRange}'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        setState(() {
          _impactData = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load training impact data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text('Error: $_error'),
      );
    }

    // Extract data from API response
    final programsImpact = _impactData['programs_impact'] as List<dynamic>;
    final trendPercentage = _impactData['trend_percentage'] as double?;
    final totalWorkouts = _impactData['total_workouts'] as int;
    final totalShots = _impactData['total_shots'] as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Training Program Impact',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        if (programsImpact.isEmpty)
          _buildEmptyState()
        else
          _buildTrainingImpactVisuals(context, programsImpact.cast<Map<String, dynamic>>()),
        
        const SizedBox(height: 24),
        _buildOverallProgressCard(context, trendPercentage, totalWorkouts, totalShots),
      ],
    );
  }
  
  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No completed workouts yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete training programs to track their impact on your performance',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrainingImpactVisuals(
    BuildContext context, 
    List<Map<String, dynamic>> programs
  ) {
    // Sort programs by success rate
    final sortedPrograms = List<Map<String, dynamic>>.from(programs)
      ..sort((a, b) => (b['success_rate'] as double).compareTo(a['success_rate'] as double));
      
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Program success rate chart
        AspectRatio(
          aspectRatio: 1.7,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: 1.0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final program = sortedPrograms[groupIndex];
                    return BarTooltipItem(
                      '${program['program_name']}\n',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      children: [
                        TextSpan(
                          text: 'Success rate: ${(program['success_rate'] * 100).toStringAsFixed(1)}%\n',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: 'Sessions: ${program['sessions']}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value >= sortedPrograms.length) {
                        return const SizedBox();
                      }
                      
                      // Show abbreviated program names
                      final programName = sortedPrograms[value.toInt()]['program_name'] as String;
                      String abbreviation = programName.split(' ').map((word) => word[0]).take(2).join('');
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          abbreviation,
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                    reservedSize: 24,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          '${(value * 100).toInt()}%',
                          style: TextStyle(
                            color: Colors.blueGrey[600],
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                    reservedSize: 32,
                    interval: 0.2,
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blueGrey[300]!,
                    width: 1,
                  ),
                  left: BorderSide(
                    color: Colors.blueGrey[300]!,
                    width: 1,
                  ),
                  right: BorderSide.none,
                  top: BorderSide.none,
                ),
              ),
              gridData: FlGridData(
                show: true,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey[300]!,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  );
                },
                drawVerticalLine: false,
                horizontalInterval: 0.2,
              ),
              barGroups: List.generate(sortedPrograms.length, (index) {
                final program = sortedPrograms[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: program['success_rate'] as double,
                      width: 25,
                      color: _getSuccessRateColor(program['success_rate'] as double),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Program details
        ...sortedPrograms.map((program) => _buildProgramImpactCard(program)),
      ],
    );
  }
  
  Widget _buildProgramImpactCard(Map<String, dynamic> program) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final successRate = program['success_rate'] as double;
    final dates = (program['dates'] as List).map((d) => DateTime.parse(d as String)).toList();
    dates.sort((a, b) => b.compareTo(a)); // Most recent first
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    program['program_name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSuccessRateColor(successRate).withAlpha(52),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(successRate * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _getSuccessRateColor(successRate),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.blueGrey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Last session: ${dates.isNotEmpty ? dateFormat.format(dates.first) : "N/A"}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.repeat,
                  size: 14,
                  color: Colors.blueGrey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  '${program['sessions']} sessions',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.sports_hockey,
                  size: 14,
                  color: Colors.blueGrey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  'Total shots: ${program['total_shots']}',
                  style: TextStyle(
                    fontSize: 12, 
                    color: Colors.blueGrey[600],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(
                  Icons.check_circle,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  'Successful: ${program['successful_shots']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildOverallProgressCard(BuildContext context, double? trendPercentage, int totalWorkouts, int totalShots) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Training Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 16),
            
            // Training impact indicator
            if (trendPercentage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (trendPercentage >= 0 ? Colors.green : Colors.red).withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      trendPercentage >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: trendPercentage >= 0 ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trendPercentage >= 0 
                              ? 'Improving Performance' 
                              : 'Performance Needs Work',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: trendPercentage >= 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trendPercentage >= 0
                              ? 'Your success rate has improved by ${trendPercentage.abs().toStringAsFixed(1)}% since you started training.'
                              : 'Your success rate has decreased by ${trendPercentage.abs().toStringAsFixed(1)}% recently.',
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
              )
            else
              Center(
                child: Text(
                  'Complete more workouts to see your progress trend',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.blueGrey[400],
                  ),
                ),
              ),
            
            if (totalWorkouts > 0)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem(
                      label: 'Completed workouts',
                      value: totalWorkouts.toString(),
                      icon: Icons.assignment_turned_in,
                    ),
                    _buildStatItem(
                      label: 'Total shots',
                      value: totalShots.toString(),
                      icon: Icons.sports_hockey,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyanAccent, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blueGrey[800],
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.blueGrey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  // Utility method
  Color _getSuccessRateColor(double rate) {
    if (rate >= 0.7) return Colors.green;
    if (rate >= 0.5) return Colors.lime;
    if (rate >= 0.3) return Colors.orange;
    return Colors.red;
  }
}