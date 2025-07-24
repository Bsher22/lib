import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:hockey_shot_tracker/utils/math_utils.dart'; 
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// A scatter plot chart for visualizing correlations between two metrics
class ScatterPlotChart extends StatefulWidget {
  /// Type of visualization data to fetch from the API
  final String dataType;
  
  /// Parameters for the visualization API call
  final Map<String, dynamic> parameters;
  
  /// Title of the chart
  final String title;
  
  /// Subtitle of the chart (optional)
  final String? subtitle;
  
  /// Label for the x-axis
  final String xAxisLabel;
  
  /// Label for the y-axis
  final String yAxisLabel;
  
  /// Minimum x-value (optional)
  final double? minX;
  
  /// Maximum x-value (optional)
  final double? maxX;
  
  /// Minimum y-value (optional)
  final double? minY;
  
  /// Maximum y-value (optional)
  final double? maxY;
  
  /// Legend items to display (optional)
  final Map<String, Color>? legendItems;
  
  /// Formatter for tooltip values (optional)
  final String Function(dynamic)? tooltipFormatter;
  
  /// Whether to show a trend line
  final bool showTrendLine;
  
  /// Whether to use a card container
  final bool useCard;
  
  /// Custom padding for the card
  final EdgeInsetsGeometry padding;
  
  /// Color for the trend line
  final Color trendLineColor;
  
  /// Optional function to generate colors for data points based on their values
  final Color Function(String key, dynamic value)? colorGenerator;

  const ScatterPlotChart({
    Key? key,
    required this.dataType,
    required this.parameters,
    required this.title,
    this.subtitle,
    required this.xAxisLabel,
    required this.yAxisLabel,
    this.minX,
    this.maxX,
    this.minY,
    this.maxY,
    this.legendItems,
    this.tooltipFormatter,
    this.showTrendLine = false,
    this.useCard = true,
    this.padding = const EdgeInsets.all(16),
    this.trendLineColor = Colors.black45,
    this.colorGenerator,
  }) : super(key: key);
  
  /// Factory method for power vs success rate correlation
  factory ScatterPlotChart.powerVsSuccess({
    required int playerId,
    int dateRange = 30,
    bool showTrendLine = true,
  }) {
    return ScatterPlotChart(
      dataType: 'power_vs_success',
      parameters: {
        'player_id': playerId,
        'date_range': dateRange,
      },
      title: 'Shot Power vs. Success Rate',
      subtitle: 'Shows the relationship between shot power and success rate',
      xAxisLabel: 'Power (mph)',
      yAxisLabel: 'Success Rate (%)',
      showTrendLine: showTrendLine,
      trendLineColor: Colors.red.withOpacity(0.6),
      tooltipFormatter: (value) {
        if (value is double) {
          if (value > 10) { // Probably a power value
            return '${value.toStringAsFixed(0)} mph';
          } else { // Probably a success rate
            return '${value.toStringAsFixed(1)}%';
          }
        }
        return value.toString();
      },
    );
  }
  
  /// Factory method for quick release vs success correlation
  factory ScatterPlotChart.releaseVsSuccess({
    required int playerId,
    int dateRange = 30,
    bool showTrendLine = true,
  }) {
    return ScatterPlotChart(
      dataType: 'release_vs_success',
      parameters: {
        'player_id': playerId,
        'date_range': dateRange,
      },
      title: 'Quick Release Time vs. Success Rate',
      subtitle: 'Shows the relationship between release time and success rate',
      xAxisLabel: 'Release Time (sec)',
      yAxisLabel: 'Success Rate (%)',
      showTrendLine: showTrendLine,
      trendLineColor: Colors.purple.withOpacity(0.6),
      tooltipFormatter: (value) {
        if (value is double) {
          if (value < 10) { // Probably a release time
            return '${value.toStringAsFixed(2)} sec';
          } else { // Probably a success rate
            return '${value.toStringAsFixed(1)}%';
          }
        }
        return value.toString();
      },
    );
  }
  
  /// Factory method for comparing two players' skills
  factory ScatterPlotChart.playerComparison({
    required int player1Id,
    required int player2Id,
    required String player1Name,
    required String player2Name,
  }) {
    // Create legend items
    final legendItems = <String, Color>{
      'Better than ${player2Name}': Colors.green,
      'Similar': Colors.blue,
      'Needs improvement': Colors.red,
    };
    
    return ScatterPlotChart(
      dataType: 'player_comparison',
      parameters: {
        'player_id': player1Id,
        'comparison_id': player2Id,
      },
      title: 'Player Comparison: $player1Name vs $player2Name',
      subtitle: 'Comparing performance metrics between players',
      xAxisLabel: '$player1Name',
      yAxisLabel: '$player2Name',
      legendItems: legendItems,
      showTrendLine: true,
      trendLineColor: Colors.grey,
    );
  }

  @override
  State<ScatterPlotChart> createState() => _ScatterPlotChartState();
}

class _ScatterPlotChartState extends State<ScatterPlotChart> {
  int? _selectedDataIndex;
  bool _isLoading = true;
  List<Map<String, dynamic>> _data = [];
  Map<String, dynamic>? _trendLine;
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _fetchVisualizationData();
  }
  
  @override
  void didUpdateWidget(ScatterPlotChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if parameters changed
    if (oldWidget.dataType != widget.dataType || 
        oldWidget.parameters.toString() != widget.parameters.toString()) {
      _fetchVisualizationData();
    }
  }
  
  Future<void> _fetchVisualizationData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Build query parameters
      final queryParams = widget.parameters.entries
          .where((e) => e.value != null)
          .map((e) => '${e.key}=${e.value}')
          .join('&');

      // Fetch visualization data from API
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/analytics/visualization/${widget.dataType}?$queryParams'),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        setState(() {
          _data = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
          _trendLine = responseData['trend_line'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load visualization data';
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
      return _buildLoadingState();
    }

    if (_error != null) {
      return _buildErrorState();
    }
    
    if (_data.isEmpty) {
      return _buildEmptyState();
    }
    
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueGrey[800],
          ),
        ),
        if (widget.subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: GestureDetector(
            onTapUp: (details) {
              _handleChartTap(context, details.localPosition);
            },
            child: ScatterChart(
              ScatterChartData(
                scatterSpots: _buildScatterSpots(),
                minX: widget.minX ?? _calculateMinX(),
                maxX: widget.maxX ?? _calculateMaxX(),
                minY: widget.minY ?? _calculateMinY(),
                maxY: widget.maxY ?? _calculateMaxY(),
                titlesData: _buildTitlesData(),
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
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey[300]!),
                ),
                scatterTouchData: ScatterTouchData(
                  enabled: false, // Disable built-in touch handling
                ),
              ),
            ),
          ),
        ),
        if (widget.legendItems != null && widget.legendItems!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: widget.legendItems!.entries.map((entry) => 
                _buildLegendItem(entry.key, entry.value)
              ).toList(),
            ),
          ),
        if (_selectedDataIndex != null && _selectedDataIndex! >= 0 && _selectedDataIndex! < _data.length)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildDetailCard(_data[_selectedDataIndex!]),
          ),
      ],
    );
    
    if (widget.useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: widget.padding,
          child: content,
        ),
      );
    }
    
    return content;
  }
  
  Widget _buildLoadingState() {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading chart data...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
    
    if (widget.useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
              content,
            ],
          ),
        ),
      );
    }
    
    return content;
  }
  
  Widget _buildErrorState() {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading chart data',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchVisualizationData,
              child: Text('Retry'),
            ),
          ],
        ),
      ),
    );
    
    if (widget.useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
              content,
            ],
          ),
        ),
      );
    }
    
    return content;
  }
  
  Widget _buildEmptyState() {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scatter_plot,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No data available for scatter plot',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
    
    if (widget.useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: widget.padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800],
                ),
              ),
              content,
            ],
          ),
        ),
      );
    }
    
    return content;
  }
  
  void _handleChartTap(BuildContext context, Offset position) {
    // Get the size of the chart
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    
    final chartSize = renderBox.size;
    
    // Calculate x and y coordinates as percentages
    final percentX = position.dx / chartSize.width;
    final percentY = 1.0 - (position.dy / chartSize.height);
    
    // Convert to data values
    final minX = widget.minX ?? _calculateMinX();
    final maxX = widget.maxX ?? _calculateMaxX();
    final minY = widget.minY ?? _calculateMinY();
    final maxY = widget.maxY ?? _calculateMaxY();
    
    final xValue = minX + (maxX - minX) * percentX;
    final yValue = minY + (maxY - minY) * percentY;
    
    // Find closest data point
    double minDistance = double.infinity;
    int? closestIndex;
    
    for (int i = 0; i < _data.length; i++) {
      final item = _data[i];
      final x = _getXValue(item);
      final y = _getYValue(item);
      
      if (x == null || y == null) continue;
      
      // Calculate normalized distance
      final xDist = (x - xValue) / (maxX - minX);
      final yDist = (y - yValue) / (maxY - minY);
      final distance = xDist * xDist + yDist * yDist;
      
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    
    // If distance is too large, don't select anything
    if (minDistance > 0.01) {
      setState(() {
        _selectedDataIndex = null;
      });
    } else {
      setState(() {
        _selectedDataIndex = closestIndex;
      });
    }
  }
  
  List<ScatterSpot> _buildScatterSpots() {
    final List<ScatterSpot> spots = [];
    
    // X and Y axis keys from API response
    final String xKey = _trendLine != null ? _trendLine!['x_axis'] ?? 'x' : 'x';
    final String yKey = _trendLine != null ? _trendLine!['y_axis'] ?? 'y' : 'y';
    
    for (int i = 0; i < _data.length; i++) {
      final item = _data[i];
      final x = _getXValue(item);
      final y = _getYValue(item);
      
      if (x == null || y == null) continue;
      
      spots.add(ScatterSpot(
        x,
        y,
        dotPainter: _buildDotPainter(item, i),
      ));
    }
    
    // Add trend line if available and requested
    if (widget.showTrendLine && _trendLine != null && _trendLine!.containsKey('start')) {
      final startX = _trendLine!['start']['x'];
      final startY = _trendLine!['start']['y'];
      final endX = _trendLine!['end']['x'];
      final endY = _trendLine!['end']['y'];
      
      // Add invisible spots for the trend line
      spots.add(ScatterSpot(
        startX,
        startY,
        dotPainter: FlDotCirclePainter(
          color: Colors.transparent,
          strokeWidth: 0,
          strokeColor: Colors.transparent,
        ),
        show: false,
      ));
      
      spots.add(ScatterSpot(
        endX,
        endY,
        dotPainter: FlDotCirclePainter(
          color: Colors.transparent,
          strokeWidth: 0,
          strokeColor: Colors.transparent,
        ),
        show: false,
      ));
    }
    
    return spots;
  }
  
  double? _getXValue(Map<String, dynamic> item) {
    final String xKey = _trendLine != null && _trendLine!.containsKey('x_axis') 
        ? _trendLine!['x_axis'] 
        : 'x';
    
    if (item.containsKey(xKey)) {
      return (item[xKey] as num).toDouble();
    }
    
    // Try other possible keys
    final possibleKeys = ['x', 'power', 'quickRelease', 'player1'];
    for (final key in possibleKeys) {
      if (item.containsKey(key) && item[key] is num) {
        return (item[key] as num).toDouble();
      }
    }
    
    return null;
  }
  
  double? _getYValue(Map<String, dynamic> item) {
    final String yKey = _trendLine != null && _trendLine!.containsKey('y_axis') 
        ? _trendLine!['y_axis'] 
        : 'y';
    
    if (item.containsKey(yKey)) {
      return (item[yKey] as num).toDouble();
    }
    
    // Try other possible keys
    final possibleKeys = ['y', 'success_rate', 'successRate', 'player2'];
    for (final key in possibleKeys) {
      if (item.containsKey(key) && item[key] is num) {
        return (item[key] as num).toDouble();
      }
    }
    
    return null;
  }
  
  FlDotPainter _buildDotPainter(Map<String, dynamic> item, int index) {
    // Determine dot size
    double dotSize = 4.0;
    if (item.containsKey('total') && item['total'] is num) {
      final total = item['total'] as num;
      // Scale size between 3 and 10
      dotSize = 3 + (total / 100 * 7).clamp(0.0, 7.0);
    }
    
    // Determine dot color
    Color dotColor = Colors.blue;
    
    // Use colorGenerator if provided
    if (widget.colorGenerator != null && item.containsKey('metric')) {
      dotColor = widget.colorGenerator!('metric', item['metric']);
    }
    // Use power-specific coloring
    else if (item.containsKey('power') && item.containsKey('success_rate')) {
      final successRate = item['success_rate'] as double;
      dotColor = ColorHelper.getSuccessRateColor(successRate / 100); // Convert to 0-1 scale
    }
    // Use release-specific coloring
    else if (item.containsKey('quickRelease') && item.containsKey('success_rate')) {
      final successRate = item['success_rate'] as double;
      dotColor = ColorHelper.getSuccessRateColor(successRate / 100); // Convert to 0-1 scale
    }
    // Use player comparison coloring
    else if (item.containsKey('player1') && item.containsKey('player2')) {
      final player1Value = item['player1'] as double;
      final player2Value = item['player2'] as double;
      
      // Determine color based on the difference
      final ratio = player1Value / (player2Value > 0 ? player2Value : 1);
      
      if (ratio > 1.2) dotColor = Colors.green; // Significantly better
      else if (ratio < 0.8) dotColor = Colors.red; // Needs improvement
      else dotColor = Colors.blue; // Similar
    }
    
    // Highlight selected point
    if (_selectedDataIndex == index) {
      dotSize *= 1.5;
      return FlDotCirclePainter(
        radius: dotSize,
        color: dotColor,
        strokeWidth: 2,
        strokeColor: Colors.white,
      );
    }
    
    return FlDotCirclePainter(
      radius: dotSize,
      color: dotColor.withOpacity(0.8),
      strokeWidth: 1,
      strokeColor: Colors.white,
    );
  }
  
  FlTitlesData _buildTitlesData() {
    return FlTitlesData(
      show: true,
      topTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      rightTitles: const AxisTitles(
        sideTitles: SideTitles(showTitles: false),
      ),
      bottomTitles: AxisTitles(
        axisNameWidget: Text(
          widget.xAxisLabel,
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        axisNameSize: 25,
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _formatAxisValue(value),
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
        axisNameWidget: Text(
          widget.yAxisLabel,
          style: TextStyle(
            color: Colors.blueGrey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        axisNameSize: 25,
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                _formatAxisValue(value),
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
    );
  }
  
  String _formatAxisValue(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[700],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDetailCard(Map<String, dynamic> item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Point Details',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.blueGrey[800],
            ),
          ),
          const Divider(),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: item.entries
                .where((entry) => entry.value != null && !entry.key.startsWith('_'))
                .map((entry) => _buildDetailItem(entry.key, entry.value))
                .toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailItem(String key, dynamic value) {
    String formattedKey = _formatKey(key);
    String formattedValue = _formatValue(value);
    
    // Check if this is an X or Y axis value
    bool isXAxisKey = key == 'x' || 
                      key == 'power' || 
                      key == 'quickRelease' || 
                      key == 'player1';
                      
    bool isYAxisKey = key == 'y' || 
                      key == 'success_rate' || 
                      key == 'successRate' || 
                      key == 'player2';
    
    return SizedBox(
      width: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isXAxisKey || isYAxisKey
                ? Icons.star
                : Icons.circle,
            size: isXAxisKey || isYAxisKey ? 16 : 8,
            color: isXAxisKey || isYAxisKey
                ? Colors.amber
                : Colors.blueGrey[400],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedKey,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.blueGrey[600],
                  ),
                ),
                Text(
                  formattedValue,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatKey(String key) {
    // Handle special keys
    if (key == 'success_rate') return 'Success Rate';
    if (key == 'successRate') return 'Success Rate';
    if (key == 'quickRelease') return 'Quick Release';
    if (key == 'player1') return widget.xAxisLabel;
    if (key == 'player2') return widget.yAxisLabel;
    
    // Convert camelCase to Title Case
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    
    return result[0].toUpperCase() + result.substring(1);
  }
  
  String _formatValue(dynamic value) {
    if (widget.tooltipFormatter != null) {
      return widget.tooltipFormatter!(value);
    }
    
    if (value is double) {
      if (value > 10 && widget.xAxisLabel.contains('Power')) {
        return '${value.toInt()} mph';
      } else if (value < 10 && widget.xAxisLabel.contains('Release')) {
        return '${value.toStringAsFixed(2)} sec';
      } else if (widget.yAxisLabel.contains('Success') || 
                widget.yAxisLabel.contains('Rate')) {
        return '${value.toStringAsFixed(1)}%';
      } else {
        return value.toStringAsFixed(1);
      }
    }
    
    return value.toString();
  }
  
  double _calculateMinX() {
    if (_data.isEmpty) return 0;
    double min = double.infinity;
    
    for (var item in _data) {
      final x = _getXValue(item);
      if (x != null && x < min) min = x;
    }
    
    return min == double.infinity ? 0 : min * 0.9;
  }
  
  double _calculateMaxX() {
    if (_data.isEmpty) return 10;
    double max = -double.infinity;
    
    for (var item in _data) {
      final x = _getXValue(item);
      if (x != null && x > max) max = x;
    }
    
    return max == -double.infinity ? 10 : max * 1.1;
  }
  
  double _calculateMinY() {
    if (_data.isEmpty) return 0;
    double min = double.infinity;
    
    for (var item in _data) {
      final y = _getYValue(item);
      if (y != null && y < min) min = y;
    }
    
    return min == double.infinity ? 0 : min * 0.9;
  }
  
  double _calculateMaxY() {
    if (_data.isEmpty) return 10;
    double max = -double.infinity;
    
    for (var item in _data) {
      final y = _getYValue(item);
      if (y != null && y > max) max = y;
    }
    
    return max == -double.infinity ? 10 : max * 1.1;
  }
}