import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

/// An interactive trend chart with tooltips, touch highlighting, and optional zooming
class InteractiveTrendChart extends StatefulWidget {
  /// Player ID for data fetching
  final int playerId;
  
  /// Date range for data fetching in days
  final int dateRange;
  
  /// Interval for data aggregation ('day', 'week', 'month')
  final String interval;
  
  /// The metric to display ('success_rate', 'shot_count', 'power', etc.)
  final String metric;
  
  /// Chart title
  final String title;
  
  /// Chart subtitle
  final String? subtitle;
  
  /// Line color
  final Color lineColor;
  
  /// Label for the y-axis
  final String? yAxisLabel;
  
  /// Whether to show the area below the line
  final bool showArea;
  
  /// Whether to use a curved line
  final bool useCurvedLine;
  
  /// Minimum value for the y-axis (optional)
  final double? minY;
  
  /// Maximum value for the y-axis (optional)
  final double? maxY;
  
  /// Whether the data is a percentage (0-100)
  final bool isPercentage;
  
  /// Whether to enable zooming
  final bool enableZoom;
  
  /// Tooltip formatter for the y-axis value
  final String Function(dynamic)? valueFormatter;
  
  /// Date formatter for the tooltip
  final String Function(DateTime)? dateFormatter;
  
  /// Whether to use a card container
  final bool useCard;
  
  /// Custom padding for the card
  final EdgeInsetsGeometry padding;

  const InteractiveTrendChart({
    Key? key,
    required this.playerId,
    this.dateRange = 90,
    this.interval = 'week',
    required this.metric,
    required this.title,
    this.subtitle,
    required this.lineColor,
    this.yAxisLabel,
    this.showArea = true,
    this.useCurvedLine = true,
    this.minY,
    this.maxY,
    this.isPercentage = false,
    this.enableZoom = false,
    this.valueFormatter,
    this.dateFormatter,
    this.useCard = true,
    this.padding = const EdgeInsets.all(16),
  }) : super(key: key);
  
  /// Factory method for shot success rate over time
  factory InteractiveTrendChart.successRate({
    required int playerId,
    int dateRange = 90,
    String interval = 'week',
    String title = 'Success Rate Trend',
    String? subtitle,
    bool enableZoom = true,
  }) {
    return InteractiveTrendChart(
      playerId: playerId,
      dateRange: dateRange,
      interval: interval,
      metric: 'success_rate',
      title: title,
      subtitle: subtitle,
      lineColor: Colors.green,
      yAxisLabel: 'Success Rate',
      isPercentage: true,
      enableZoom: enableZoom,
      valueFormatter: (value) => '${(value as double).toStringAsFixed(1)}%',
    );
  }
  
  /// Factory method for shot volume over time
  factory InteractiveTrendChart.shotVolume({
    required int playerId,
    int dateRange = 90,
    String interval = 'week',
    String title = 'Shot Volume Trend',
    String? subtitle,
    bool enableZoom = true,
  }) {
    return InteractiveTrendChart(
      playerId: playerId,
      dateRange: dateRange,
      interval: interval,
      metric: 'shot_count',
      title: title,
      subtitle: subtitle,
      lineColor: Colors.blue,
      yAxisLabel: 'Shots',
      enableZoom: enableZoom,
    );
  }
  
  /// Factory method for shot power over time
  factory InteractiveTrendChart.shotPower({
    required int playerId,
    int dateRange = 90,
    String interval = 'week',
    String title = 'Shot Power Trend',
    String? subtitle,
    bool enableZoom = true,
  }) {
    return InteractiveTrendChart(
      playerId: playerId,
      dateRange: dateRange,
      interval: interval,
      metric: 'avg_power',
      title: title,
      subtitle: subtitle,
      lineColor: Colors.orange,
      yAxisLabel: 'MPH',
      enableZoom: enableZoom,
      valueFormatter: (value) => '${(value as double).toStringAsFixed(1)} mph',
    );
  }

  @override
  State<InteractiveTrendChart> createState() => _InteractiveTrendChartState();
}

class _InteractiveTrendChartState extends State<InteractiveTrendChart> {
  int? _touchedIndex;
  double? _minX;
  double? _maxX;
  double? _minY;
  double? _maxY;
  bool _isLoading = true;
  List<Map<String, dynamic>> _trendData = [];
  String? _error;
  
  // For pinch to zoom
  double _scaleStart = 1.0;
  double _scale = 1.0;
  
  @override
  void initState() {
    super.initState();
    _fetchTrendData();
  }
  
  @override
  void didUpdateWidget(InteractiveTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if key parameters changed
    if (oldWidget.playerId != widget.playerId ||
        oldWidget.dateRange != widget.dateRange ||
        oldWidget.interval != widget.interval ||
        oldWidget.metric != widget.metric) {
      _fetchTrendData();
    }
  }
  
  Future<void> _fetchTrendData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      // Build URL with parameters
      final url = '${ApiConfig.baseUrl}/api/analytics/visualization/success_trend?'
          'player_id=${widget.playerId}&'
          'date_range=${widget.dateRange}&'
          'interval=${widget.interval}&'
          'metric=${widget.metric}';
          
      // Fetch trend data from API
      final response = await http.get(
        Uri.parse(url),
        headers: await ApiConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        setState(() {
          _trendData = List<Map<String, dynamic>>.from(responseData['data'] ?? []);
          _isLoading = false;
          
          // Reset zoom to fit new data
          _resetZoom();
        });
      } else {
        setState(() {
          _error = 'Failed to load trend data';
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
  
  void _resetZoom() {
    setState(() {
      _scale = 1.0;
      _scaleStart = 1.0;
      
      _minX = 0;
      _maxX = (_trendData.length - 1).toDouble();
      
      // Calculate Y axis bounds
      double minValue = double.infinity;
      double maxValue = -double.infinity;
      
      final metricKey = _getMetricKey();
      
      for (var data in _trendData) {
        if (data.containsKey(metricKey)) {
          final value = data[metricKey] as num;
          if (value < minValue) minValue = value.toDouble();
          if (value > maxValue) maxValue = value.toDouble();
        }
      }
      
      _minY = widget.minY ?? (minValue < 0 ? minValue * 1.1 : 0);
      
      if (widget.isPercentage) {
        _maxY = 100.0;
      } else {
        _maxY = widget.maxY ?? (maxValue * 1.1).ceilToDouble();
      }
    });
  }
  
  String _getMetricKey() {
    // Map API metric to data field in response
    switch (widget.metric) {
      case 'success_rate':
        return 'successRate';
      case 'shot_count':
        return 'shotCount';
      case 'avg_power':
        return 'avgPower';
      case 'avg_quick_release':
        return 'avgQuickRelease';
      default:
        return widget.metric;
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
    
    if (_trendData.isEmpty) {
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
          height: 240,
          child: Stack(
            children: [
              GestureDetector(
                onScaleStart: widget.enableZoom ? _handleScaleStart : null,
                onScaleUpdate: widget.enableZoom ? _handleScaleUpdate : null,
                onDoubleTap: widget.enableZoom ? _resetZoom : null,
                child: LineChart(
                  _buildLineChartData(),
                ),
              ),
              if (widget.enableZoom)
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.refresh, size: 18),
                    onPressed: _resetZoom,
                    tooltip: 'Reset zoom',
                  ),
                ),
            ],
          ),
        ),
        if (_touchedIndex != null && _touchedIndex! >= 0 && _touchedIndex! < _trendData.length)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: _buildTooltipContent(_touchedIndex!),
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
              'Loading trend data...',
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
              'Error loading trend data',
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
              onPressed: _fetchTrendData,
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
              Icons.timeline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trend data available',
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
  
  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    final metricKey = _getMetricKey();
    
    for (int i = 0; i < _trendData.length; i++) {
      final trend = _trendData[i];
      if (trend.containsKey(metricKey)) {
        final value = trend[metricKey] as num;
        spots.add(FlSpot(i.toDouble(), value.toDouble()));
      }
    }
    
    return LineChartData(
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
        leftTitles: _buildLeftTitles(),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!),
      ),
      minX: _minX,
      maxX: _maxX,
      minY: _minY,
      maxY: _maxY,
      lineTouchData: _buildLineTouchData(),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: widget.useCurvedLine,
          color: widget.lineColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: _touchedIndex == index ? 5 : 3,
                color: widget.lineColor,
                strokeWidth: 1,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: widget.showArea,
            color: widget.lineColor.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
  
  AxisTitles _buildBottomTitles() {
    return AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          if (value % 1 != 0 || value < 0 || value >= _trendData.length) {
            return const SizedBox.shrink();
          }
          
          // Show fewer labels when zoomed out
          if (_trendData.length > 10 && (_maxX! - _minX! > 10)) {
            if (value % 2 != 0) {
              return const SizedBox.shrink();
            }
          }
          
          final item = _trendData[value.toInt()];
          final date = DateTime.parse(item['date'] as String);
          
          String formattedDate;
          if (widget.dateFormatter != null) {
            formattedDate = widget.dateFormatter!(date);
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
  
  AxisTitles _buildLeftTitles() {
    return AxisTitles(
      axisNameWidget: widget.yAxisLabel != null ? Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          widget.yAxisLabel!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.blueGrey[700],
          ),
        ),
      ) : null,
      sideTitles: SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          String formattedValue;
          
          if (widget.valueFormatter != null) {
            formattedValue = widget.valueFormatter!(value);
          } else if (widget.isPercentage) {
            formattedValue = '${value.toInt()}%';
          } else if (value == value.toInt()) {
            formattedValue = value.toInt().toString();
          } else {
            formattedValue = value.toStringAsFixed(1);
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
  
  LineTouchData _buildLineTouchData() {
    return LineTouchData(
      enabled: true,
      handleBuiltInTouches: true,
      touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (LineBarSpot spot) => Colors.blueGrey[800]!.withOpacity(0.9),
        tooltipBorder: const BorderSide(color: Colors.grey, width: 1),
        tooltipPadding: const EdgeInsets.all(8),
        tooltipMargin: 0,
        getTooltipItems: (List<LineBarSpot> touchedSpots) {
          return touchedSpots.map((spot) {
            final index = spot.x.toInt();
            if (index >= 0 && index < _trendData.length) {
              final item = _trendData[index];
              final value = item[_getMetricKey()] as num;
              final date = DateTime.parse(item['date'] as String);
              
              String formattedValue;
              if (widget.valueFormatter != null) {
                formattedValue = widget.valueFormatter!(value);
              } else if (widget.isPercentage) {
                formattedValue = '${value.toStringAsFixed(1)}%';
              } else {
                formattedValue = value.toString();
              }
              
              String formattedDate;
              if (widget.dateFormatter != null) {
                formattedDate = widget.dateFormatter!(date);
              } else {
                formattedDate = DateFormat('MM/dd/yyyy').format(date);
              }
              
              return LineTooltipItem(
                '$formattedValue\n$formattedDate',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              );
            }
            return null;
          }).toList();
        },
      ),
      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
        setState(() {
          if (event is FlPanEndEvent || event is FlLongPressEnd) {
            _touchedIndex = null;
          } else if (touchResponse != null && touchResponse.lineBarSpots != null) {
            if (touchResponse.lineBarSpots!.isNotEmpty) {
              _touchedIndex = touchResponse.lineBarSpots!.first.spotIndex;
            } else {
              _touchedIndex = null;
            }
          }
        });
      },
    );
  }
  
  Widget _buildTooltipContent(int index) {
    final item = _trendData[index];
    final value = item[_getMetricKey()] as num;
    final date = DateTime.parse(item['date'] as String);
    
    String formattedValue;
    if (widget.valueFormatter != null) {
      formattedValue = widget.valueFormatter!(value);
    } else if (widget.isPercentage) {
      formattedValue = '${value.toStringAsFixed(1)}%';
    } else {
      formattedValue = value.toString();
    }
    
    String formattedDate;
    if (widget.dateFormatter != null) {
      formattedDate = widget.dateFormatter!(date);
    } else {
      formattedDate = DateFormat('MMMM d, yyyy').format(date);
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: widget.lineColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Colors.blueGrey[600],
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                widget.isPercentage 
                    ? Icons.percent 
                    : Icons.show_chart,
                size: 16,
                color: widget.lineColor,
              ),
              const SizedBox(width: 8),
              Text(
                '$formattedValue${widget.yAxisLabel != null ? ' ${widget.yAxisLabel}' : ''}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.lineColor,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          // Add additional data points if they exist in the item
          ...item.entries
              .where((entry) => 
                  entry.key != 'date' && 
                  entry.key != _getMetricKey() &&
                  entry.value != null)
              .map((entry) => 
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.blueGrey[400],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatKey(entry.key)}: ${entry.value}',
                          style: TextStyle(
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ).toList(),
        ],
      ),
    );
  }
  
  String _formatKey(String key) {
    // Handle special keys
    if (key == 'shotCount') return 'Shot Count';
    if (key == 'successfulShots') return 'Successful Shots';
    if (key == 'avgPower') return 'Average Power';
    if (key == 'avgQuickRelease') return 'Average Quick Release';
    
    // Convert camelCase to Title Case
    final result = key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    
    return result[0].toUpperCase() + result.substring(1);
  }
  
  void _handleScaleStart(ScaleStartDetails details) {
    _scaleStart = _scale;
  }
  
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      // Update the scale
      _scale = _scaleStart * details.scale;
      
      // Ensure minimum scale
      _scale = _scale.clamp(1.0, 10.0);
      
      // Calculate new bounds based on scale
      final originalRange = _trendData.length - 1;
      final visibleRange = originalRange / _scale;
      
      // Calculate new boundaries
      final rangeMiddle = (_minX! + _maxX!) / 2;
      
      _minX = (rangeMiddle - visibleRange / 2).clamp(0.0, originalRange.toDouble());
      _maxX = (rangeMiddle + visibleRange / 2).clamp(0.0, originalRange.toDouble());
      
      // Ensure we don't zoom in too far
      if (_maxX! - _minX! < 2) {
        final center = (_minX! + _maxX!) / 2;
        _minX = (center - 1).clamp(0.0, originalRange.toDouble());
        _maxX = (center + 1).clamp(0.0, originalRange.toDouble());
      }
    });
  }
}