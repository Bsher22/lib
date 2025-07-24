import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum TrendDataType {
  volume,       // Integer counts (shots)
  metric,       // Double values (power, times)
  percentage    // Percentage values (0-100)
}

class ConfigurableTrendChart extends StatelessWidget {
  final List<Map<String, dynamic>> trendData;
  final TrendDataType dataType;
  final String dataKey;
  final String? dateKey;
  final String title;
  final Color lineColor;
  final String? yAxisLabel;
  final bool showArea;
  final bool useCurvedLine;
  final double? minY;
  final double? maxY;
  final double? yAxisInterval;
  final String Function(double)? yAxisValueFormatter;
  final String Function(DateTime)? dateFormatter;
  final String? noDataMessage;

  const ConfigurableTrendChart({
    Key? key,
    required this.trendData,
    required this.dataType,
    required this.dataKey,
    this.dateKey = 'weekStart',
    this.title = '',
    required this.lineColor, 
    this.yAxisLabel,
    this.showArea = true,
    this.useCurvedLine = true,
    this.minY,
    this.maxY,
    this.yAxisInterval,
    this.yAxisValueFormatter,
    this.dateFormatter,
    this.noDataMessage = 'No trend data available',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (trendData.isEmpty) {
      return Center(child: Text(noDataMessage ?? 'No trend data available'));
    }

    final spots = <FlSpot>[];
    double maxValue = 0;

    for (int i = 0; i < trendData.length; i++) {
      final trend = trendData[i];
      final value = trend[dataKey] as num;
      spots.add(FlSpot(i.toDouble(), value.toDouble()));
      if (value > maxValue) {
        maxValue = value.toDouble();
      }
    }

    // Calculate appropriate max Y value if not provided
    final calculatedMaxY = maxY ?? _calculateDefaultMaxY(maxValue);
    
    // Calculate appropriate interval if not provided
    final calculatedInterval = yAxisInterval ?? _calculateDefaultInterval(calculatedMaxY);

    return SizedBox(
      height: 200,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
            ),
          Expanded(
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
                  bottomTitles: _buildBottomTitles(),
                  leftTitles: _buildLeftTitles(calculatedInterval),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                minX: 0,
                maxX: (trendData.length - 1).toDouble(),
                minY: minY ?? 0,
                maxY: calculatedMaxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: useCurvedLine,
                    color: lineColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: showArea,
                      color: lineColor.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  AxisTitles _buildBottomTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value % 1 != 0 || value < 0 || value >= trendData.length) {
            return const SizedBox.shrink();
          }
          
          final item = trendData[value.toInt()];
          final date = item[dateKey] as DateTime;
          
          String formattedDate;
          if (dateFormatter != null) {
            formattedDate = dateFormatter!(date);
          } else {
            formattedDate = DateFormat('MM/dd').format(date);
          }
          
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey[600],
              ),
            ),
          );
        },
        reservedSize: 30,
      ),
    );
  }

  AxisTitles _buildLeftTitles(double interval) {
    return AxisTitles(
      axisNameWidget: yAxisLabel != null ? Text(
        yAxisLabel!,
        style: TextStyle(
          fontSize: 12,
          color: Colors.blueGrey[700],
        ),
      ) : null,
      sideTitles: SideTitles(
        showTitles: true,
        interval: interval,
        getTitlesWidget: (value, meta) {
          String formattedValue;
          
          if (yAxisValueFormatter != null) {
            formattedValue = yAxisValueFormatter!(value);
          } else {
            switch (dataType) {
              case TrendDataType.volume:
                formattedValue = value.toInt().toString();
                break;
              case TrendDataType.metric:
                formattedValue = value.toStringAsFixed(1);
                break;
              case TrendDataType.percentage:
                formattedValue = '${value.toInt()}%';
                break;
            }
          }
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              formattedValue,
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey[600],
              ),
            ),
          );
        },
        reservedSize: 40,
      ),
    );
  }

  double _calculateDefaultMaxY(double maxValue) {
    switch (dataType) {
      case TrendDataType.volume:
        final buffer = maxValue * 0.1;
        return (maxValue + buffer).ceilToDouble();
      case TrendDataType.metric:
        return (maxValue * 1.1).ceilToDouble();
      case TrendDataType.percentage:
        return 100.0;
    }
  }

  double _calculateDefaultInterval(double maxY) {
    switch (dataType) {
      case TrendDataType.volume:
        if (maxY <= 20) return 5;
        if (maxY <= 50) return 10;
        if (maxY <= 100) return 20;
        return 50;
      case TrendDataType.metric:
        if (maxY <= 10) return 1;
        if (maxY <= 50) return 10;
        if (maxY <= 100) return 20;
        return 50;
      case TrendDataType.percentage:
        return 20;
    }
  }

  /// Factory method for creating a shot count trend chart
  factory ConfigurableTrendChart.volume({
    required List<Map<String, dynamic>> trendData,
    required String countKey,
    String? dateKey,
    String title = 'Shot Volume Trend',
    Color color = Colors.blue,
  }) {
    return ConfigurableTrendChart(
      trendData: trendData,
      dataType: TrendDataType.volume,
      dataKey: countKey,
      dateKey: dateKey ?? 'weekStart',
      title: title,
      lineColor: color,
    );
  }

  /// Factory method for creating a power/metric trend chart
  factory ConfigurableTrendChart.metric({
    required List<Map<String, dynamic>> trendData,
    required String metricKey,
    String? dateKey,
    String title = 'Power Trend',
    Color color = Colors.orange,
    String? yAxisLabel,
  }) {
    return ConfigurableTrendChart(
      trendData: trendData,
      dataType: TrendDataType.metric,
      dataKey: metricKey,
      dateKey: dateKey ?? 'weekStart',
      title: title,
      lineColor: color,
      yAxisLabel: yAxisLabel,
    );
  }

  /// Factory method for creating a success rate trend chart
  factory ConfigurableTrendChart.percentage({
    required List<Map<String, dynamic>> trendData,
    required String rateKey,
    String? dateKey,
    String title = 'Success Rate Trend',
    Color color = Colors.green,
    bool showRateAsDecimal = true,
  }) {
    // FIXED: Process the trend data to convert decimal rates to percentages if needed
    final processedTrendData = showRateAsDecimal 
        ? trendData.map((e) => {
            ...e,
            rateKey: (e[rateKey] as double) * 100,
          }).toList()
        : trendData;
    
    return ConfigurableTrendChart(
      trendData: processedTrendData, // FIXED: Use processed data instead of duplicating trendData parameter
      dataType: TrendDataType.percentage,
      dataKey: rateKey,
      dateKey: dateKey ?? 'weekStart',
      title: title,
      lineColor: color,
      yAxisValueFormatter: (value) => '${value.toInt()}%',
      minY: 0,
      maxY: 100,
    );
  }
}