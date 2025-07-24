import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/color_helper.dart';
import 'package:hockey_shot_tracker/widgets/core/list/standard_card.dart';
import 'package:hockey_shot_tracker/widgets/core/list/status_badge.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hockey_shot_tracker/utils/api_config.dart';

class ShotTypesAnalysisWidget extends StatefulWidget {
  final int playerId;
  final Map<String, dynamic>? filters;

  const ShotTypesAnalysisWidget({
    Key? key,
    required this.playerId,
    this.filters,
  }) : super(key: key);

  @override
  _ShotTypesAnalysisWidgetState createState() => _ShotTypesAnalysisWidgetState();
}

class _ShotTypesAnalysisWidgetState extends State<ShotTypesAnalysisWidget> {
  bool _isLoading = true;
  Map<String, Map<String, dynamic>> _shotTypeMetrics = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  @override
  void didUpdateWidget(ShotTypesAnalysisWidget oldWidget) {
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
        
        // Process shot type metrics
        final typeSuccessRates = data['type_success_rates'] as Map<String, dynamic>;
        final Map<String, Map<String, dynamic>> shotTypeMetrics = {};
        
        // Get shot patterns to get counts by type and power by type
        final patternsResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/api/analytics/patterns/${widget.playerId}'),
          headers: await ApiConfig.getHeaders(),
        );
        
        if (patternsResponse.statusCode == 200) {
          final patternsData = json.decode(patternsResponse.body);
          
          if (patternsData.containsKey('tendencies') && 
              patternsData['tendencies'].containsKey('type_distribution')) {
            final typeDistribution = patternsData['tendencies']['type_distribution'] as Map<String, dynamic>;
            final totalShots = patternsData['total_shots'] as int;
            
            // Initialize shot type metrics with distribution
            for (var type in typeDistribution.keys) {
              final percentage = typeDistribution[type] as double;
              final successRate = typeSuccessRates[type] as double? ?? 0.0;
              
              shotTypeMetrics[type] = {
                'successRate': successRate,
                'count': (percentage * totalShots).round(),
                'avgPower': 0.0,
              };
            }
            
            // Get individual shots to calculate power by type
            final shotsResponse = await http.get(
              Uri.parse('${ApiConfig.baseUrl}/api/shots/player/${widget.playerId}'),
              headers: await ApiConfig.getHeaders(),
            );
            
            if (shotsResponse.statusCode == 200) {
              final shotsData = json.decode(shotsResponse.body);
              final shots = shotsData['shots'] as List<dynamic>;
              
              // Calculate average power by shot type
              final Map<String, List<double>> powerByType = {};
              
              for (var shot in shots) {
                final type = shot['type'] as String;
                final power = shot['power'] as double?;
                
                if (power != null) {
                  if (!powerByType.containsKey(type)) {
                    powerByType[type] = [];
                  }
                  
                  powerByType[type]!.add(power);
                }
              }
              
              // Update shot type metrics with power
              for (var type in powerByType.keys) {
                final powers = powerByType[type]!;
                final avgPower = powers.isNotEmpty
                    ? powers.reduce((a, b) => a + b) / powers.length
                    : 0.0;
                
                if (shotTypeMetrics.containsKey(type)) {
                  shotTypeMetrics[type]!['avgPower'] = avgPower;
                }
              }
            }
          }
        }
        
        setState(() {
          _shotTypeMetrics = shotTypeMetrics;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text('Error: $_error'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Shot Types Analysis',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        StandardCard(
          borderRadius: 12,
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ..._shotTypeMetrics.entries.map((entry) {
                  final type = entry.key;
                  final metrics = entry.value;
                  final count = metrics['count'] as int;
                  final successRate = metrics['successRate'] as double;
                  final avgPower = metrics['avgPower'] as double;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          StatusBadge(
                            text: '$count shots',
                            color: Colors.blueGrey[600]!,
                            size: StatusBadgeSize.small,
                            withBorder: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Success Rate: ${(successRate * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorHelper.getSuccessRateColor(successRate),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            text: ColorHelper.getSuccessRateDescription(successRate),
                            color: ColorHelper.getSuccessRateColor(successRate),
                            size: StatusBadgeSize.small,
                            shape: StatusBadgeShape.pill,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: successRate,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ColorHelper.getSuccessRateColor(successRate)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Power: ${avgPower.toStringAsFixed(1)} mph',
                              style: TextStyle(
                                fontSize: 14,
                                color: ColorHelper.getPowerColor(avgPower),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(
                            text: ColorHelper.getPowerDescription(avgPower),
                            color: ColorHelper.getPowerColor(avgPower),
                            size: StatusBadgeSize.small,
                            shape: StatusBadgeShape.pill,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: avgPower / 100, // Assuming 100 mph is max
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                            ColorHelper.getPowerColor(avgPower)),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const Divider(height: 32),
                    ],
                  );
                }).toList(),
                if (_shotTypeMetrics.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No shot type data available'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}