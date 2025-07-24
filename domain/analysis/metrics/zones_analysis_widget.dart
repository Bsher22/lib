import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class ZonesAnalysisWidget extends StatefulWidget {
  final int playerId;
  final Map<String, dynamic>? filters;

  const ZonesAnalysisWidget({
    Key? key,
    required this.playerId,
    this.filters,
  }) : super(key: key);

  @override
  _ZonesAnalysisWidgetState createState() => _ZonesAnalysisWidgetState();
}

class _ZonesAnalysisWidgetState extends State<ZonesAnalysisWidget> {
  bool _isLoading = true;
  Map<String, dynamic> _playerMetrics = {};
  Map<String, Map<String, dynamic>> _zoneMetrics = {};
  Map<String, String> _zoneLabels = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
    _fetchZoneLabels();
  }

  @override
  void didUpdateWidget(ZonesAnalysisWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Refetch if player ID or filters changed
    if (oldWidget.playerId != widget.playerId || 
        oldWidget.filters.toString() != widget.filters.toString()) {
      _fetchAnalytics();
    }
  }

  Future<void> _fetchAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Build URL with filters if provided
      String url = '${ApiConfig.baseUrl}/api/analytics/${widget.playerId}';
      
      if (widget.filters != null && widget.filters!.isNotEmpty) {
        final queryParams = [];
        
        widget.filters!.forEach((key, value) {
          if (value is List) {
            for (var item in value) {
              queryParams.add('$key=$item');
            }
          } else if (value != null) {
            queryParams.add('$key=$value');
          }
        });
        
        if (queryParams.isNotEmpty) {
          url += '?' + queryParams.join('&');
        }
      }

      // Fetch metrics from API
      final response = await http.get(
        Uri.parse(url),
        headers: await ApiConfig.getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Process zone metrics
        final zoneSuccessRates = data['zone_success_rates'] as Map<String, dynamic>;
        final Map<String, Map<String, dynamic>> zoneMetrics = {};
        
        // Determine most common zone, best zone, worst zone
        String? mostCommonZone;
        String? bestZone;
        String? worstZone;
        double bestSuccess = 0.0;
        double worstSuccess = 1.0;
        
        for (var zone in zoneSuccessRates.keys) {
          final successRate = zoneSuccessRates[zone] as double;
          zoneMetrics[zone] = {
            'successRate': successRate,
            'count': 0, // Will be populated from patterns API
          };
          
          if (successRate > bestSuccess) {
            bestSuccess = successRate;
            bestZone = zone;
          }
          
          if (successRate < worstSuccess && successRate > 0) {
            worstSuccess = successRate;
            worstZone = zone;
          }
        }
        
        // Get shot patterns to get counts by zone
        final patternsResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/analytics/patterns/${widget.playerId}'),
          headers: await ApiConfig.getHeaders(),
        );
        
        if (patternsResponse.statusCode == 200) {
          final patternsData = json.decode(patternsResponse.body);
          
          if (patternsData.containsKey('tendencies') && 
              patternsData['tendencies'].containsKey('zone_distribution')) {
            final zoneDistribution = patternsData['tendencies']['zone_distribution'] as Map<String, dynamic>;
            final totalShots = patternsData['total_shots'] as int;
            
            // Find most common zone
            double highestPercentage = 0.0;
            
            for (var zone in zoneDistribution.keys) {
              final percentage = zoneDistribution[zone] as double;
              
              // Update zone metrics with count
              if (zoneMetrics.containsKey(zone)) {
                zoneMetrics[zone]!['count'] = (percentage * totalShots).round();
              } else {
                zoneMetrics[zone] = {
                  'successRate': 0.0,
                  'count': (percentage * totalShots).round(),
                };
              }
              
              if (percentage > highestPercentage) {
                highestPercentage = percentage;
                mostCommonZone = zone;
              }
            }
          }
        }
        
        setState(() {
          _playerMetrics = {
            'mostCommonZone': mostCommonZone,
            'bestZone': bestZone,
            'worstZone': worstZone,
            'overallSuccessRate': data['overall_success_rate'] as double,
          };
          _zoneMetrics = zoneMetrics;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load metrics';
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
  
  Future<void> _fetchZoneLabels() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/config/shot-zones'),
        headers: await ApiConfig.getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, String> labels = {};
        
        for (var entry in data.entries) {
          labels[entry.key] = entry.value['name'] as String;
        }
        
        setState(() {
          _zoneLabels = labels;
        });
      }
    } catch (e) {
      // Fallback to default labels if API call fails
      setState(() {
        _zoneLabels = {
          '1': 'Top Left',
          '2': 'Top Center',
          '3': 'Top Right',
          '4': 'Middle Left',
          '5': 'Middle Center',
          '6': 'Middle Right',
          '7': 'Bottom Left',
          '8': 'Bottom Center',
          '9': 'Bottom Right',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shot Zones Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Target Zone Insights',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                if (_playerMetrics['mostCommonZone'] != null)
                  _buildZoneInsight(
                    'Most Targeted Zone',
                    _playerMetrics['mostCommonZone'] as String,
                    Icons.center_focus_strong,
                    Colors.blue,
                  )
                else
                  const SizedBox.shrink(),
                if (_playerMetrics['bestZone'] != null)
                  _buildZoneInsight(
                    'Highest Success Zone',
                    _playerMetrics['bestZone'] as String,
                    Icons.emoji_events,
                    Colors.green,
                  )
                else
                  const SizedBox.shrink(),
                if (_playerMetrics['worstZone'] != null)
                  _buildZoneInsight(
                    'Needs Improvement Zone',
                    _playerMetrics['worstZone'] as String,
                    Icons.trending_down,
                    Colors.orange,
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 16),
                const Text(
                  'Zone Performance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 210, // Increased from 200 to accommodate larger cells (3 * 66 + margins)
                  child: _buildZonePerformanceGrid(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneInsight(String title, String zone, IconData icon, Color color) {
    final zoneLabel = _zoneLabels[zone] ?? 'Unknown';
    final metrics = _zoneMetrics[zone];

    if (metrics == null) return const SizedBox.shrink();

    final count = metrics['count'] as int;
    final successRate = metrics['successRate'] as double;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Zone $zone ($zoneLabel) - ${(successRate * 100).toStringAsFixed(1)}% success rate',
                  style: TextStyle(
                    color: Colors.blueGrey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '$count shots',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZonePerformanceGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneCell('1', context),
            _buildZoneCell('2', context),
            _buildZoneCell('3', context),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneCell('4', context),
            _buildZoneCell('5', context),
            _buildZoneCell('6', context),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneCell('7', context),
            _buildZoneCell('8', context),
            _buildZoneCell('9', context),
          ],
        ),
      ],
    );
  }

  Widget _buildZoneCell(String zone, BuildContext context) {
    final metrics = _zoneMetrics[zone];

    if (metrics == null) {
      return _buildEmptyZoneCell(zone);
    }

    final count = metrics['count'] as int;
    final successRate = metrics['successRate'] as double;

    if (count == 0) {
      return _buildEmptyZoneCell(zone);
    }

    final color = ColorHelper.getSuccessRateColor(successRate);

    return SizedBox(
      width: 66, // Increased from 60 to 66
      height: 66, // Increased from 60 to 66
      child: GestureDetector(
        onTap: () {
          // Handle the zone selection
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Selected Zone $zone: ${(successRate * 100).toStringAsFixed(1)}% success')),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            border: Border.all(
              color: color,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  zone,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '${(successRate * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$count shots',
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyZoneCell(String zone) {
    return SizedBox(
      width: 78, // Increased from 60 to 66
      height: 78, // Increased from 60 to 66
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(
            color: Colors.grey[400]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'No data',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}