import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

enum DistributionType {
  pie,
  grid,
  bar
}

class DistributionDisplay extends StatelessWidget {
  final DistributionType type;
  final String title;
  final String? subtitle;
  final Map<String, dynamic> distributionData;
  final String countKey;
  final String? percentageKey;
  final String? statusKey;
  final String? labelKey;
  final Map<String, Color>? colorMap;
  final Color Function(String key, num value)? colorGenerator;
  final int rows;
  final int columns;
  final bool useCard;
  final EdgeInsetsGeometry padding;
  final String? emptyMessage;
  final Widget Function(BuildContext, String, Map<String, dynamic>)? itemBuilder;

  const DistributionDisplay({
    Key? key,
    required this.type,
    required this.title,
    this.subtitle,
    required this.distributionData,
    this.countKey = 'count',
    this.percentageKey,
    this.statusKey,
    this.labelKey,
    this.colorMap,
    this.colorGenerator,
    this.rows = 3,
    this.columns = 3,
    this.useCard = true,
    this.padding = const EdgeInsets.all(16),
    this.emptyMessage = 'No data available',
    this.itemBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEmpty = distributionData.isEmpty;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.blueGrey[800],
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.blueGrey[600],
              ),
            ),
          ),
        const SizedBox(height: 16),
        isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Text(
                    emptyMessage ?? 'No data available',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey[400],
                    ),
                  ),
                ),
              )
            : _buildDistributionContent(context),
      ],
    );

    if (useCard) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: padding,
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildDistributionContent(BuildContext context) {
    switch (type) {
      case DistributionType.pie:
        return _buildPieChart(context);
      case DistributionType.grid:
        return _buildGridDisplay(context);
      case DistributionType.bar:
        return _buildBarChart(context);
    }
  }

  Widget _buildPieChart(BuildContext context) {
    final totalValue = distributionData.values.fold<num>(
        0, (sum, item) => sum + (item[countKey] as num));

    if (totalValue == 0) {
      return Center(
        child: Text(
          emptyMessage ?? 'No data available',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueGrey[400],
          ),
        ),
      );
    }

    // Prepare pie chart data
    final pieData = distributionData.entries.map((entry) {
      final label = entry.key;
      final count = entry.value[countKey] as num;
      final percentage = count / totalValue;
      final value = count.toDouble();

      return PieChartSectionData(
        value: value,
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 80,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        color: _getItemColor(label, count),
      );
    }).toList();

    return SizedBox(
      height: 320,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: pieData,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: distributionData.entries.map((entry) {
                final label = entry.key;
                final data = entry.value;
                final count = data[countKey] as num;
                final displayLabel = data[labelKey] ?? label;
                final percentage = count / totalValue;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _getItemColor(label, count),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$displayLabel: $count (${(percentage * 100).toStringAsFixed(0)}%)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blueGrey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridDisplay(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AspectRatio(
        aspectRatio: columns / rows,
        child: Column(
          children: List.generate(
            rows,
            (rowIndex) => Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  columns,
                  (colIndex) {
                    // Calculate zone number (depends on how you want to map grid positions to zones)
                    final zoneNumber = (rowIndex * columns + colIndex + 1).toString();
                    return Expanded(
                      child: _buildGridCell(context, zoneNumber),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildGridCell(BuildContext context, String zoneId) {
    if (!distributionData.containsKey(zoneId)) {
      return _buildEmptyGridCell(context, zoneId);
    }

    final zoneData = distributionData[zoneId]!;
    final count = zoneData[countKey] as num;
    
    if (count == 0) {
      return _buildEmptyGridCell(context, zoneId);
    }
    
    // If a custom item builder is provided, use it
    if (itemBuilder != null) {
      return itemBuilder!(context, zoneId, zoneData);
    }
    
    // Otherwise build a default grid cell
    final label = zoneData[labelKey] ?? '';
    final hasPercentage = percentageKey != null && zoneData.containsKey(percentageKey);
    final percentage = hasPercentage ? zoneData[percentageKey] as double : 0.0;
    final statusText = statusKey != null ? zoneData[statusKey] as String? : null;
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: hasPercentage 
            ? _getColorFromPercentage(percentage).withOpacity(0.7)
            : _getItemColor(zoneId, count).withOpacity(0.7),
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
              zoneId,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (label.isNotEmpty)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                ),
              ),
            if (hasPercentage)
              Text(
                '${(percentage * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            if (statusText != null)
              Text(
                statusText,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
            Text(
              '$count ${count == 1 ? 'shot' : 'shots'}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEmptyGridCell(BuildContext context, String zoneId) {
    final label = distributionData.containsKey(zoneId) && 
                 labelKey != null && 
                 distributionData[zoneId]!.containsKey(labelKey)
             ? distributionData[zoneId]![labelKey] as String
             : '';
             
    return Container(
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
              zoneId,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            if (label.isNotEmpty)
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
    );
  }
  
  Widget _buildBarChart(BuildContext context) {
    final totalItems = distributionData.length;
    if (totalItems == 0) {
      return Center(
        child: Text(
          emptyMessage ?? 'No data available',
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: Colors.blueGrey[400],
          ),
        ),
      );
    }
    
    // Convert to list and sort by count
    final items = distributionData.entries.map((e) => MapEntry(
      e.key, 
      e.value,
    )).toList();
    
    // Sort by count in descending order
    items.sort((a, b) => (b.value[countKey] as num).compareTo(a.value[countKey] as num));
    
    // Calculate maximum value for scaling
    final maxValue = items.isNotEmpty 
        ? (items.first.value[countKey] as num).toDouble() 
        : 0.0;
    
    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.1,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value < 0 || value >= items.length) {
                    return const SizedBox.shrink();
                  }
                  final item = items[value.toInt()];
                  final displayLabel = item.value[labelKey] ?? item.key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      displayLabel.toString(),
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
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
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
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey[300],
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final count = item.value[countKey] as num;
            
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: _getItemColor(item.key, count),
                  width: 15,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Color _getItemColor(String key, num value) {
    // 1. Check if a color generator function is provided
    if (colorGenerator != null) {
      return colorGenerator!(key, value);
    }
    
    // 2. Check if color is specified in color map
    if (colorMap != null && colorMap!.containsKey(key)) {
      return colorMap![key]!;
    }
    
    // 3. Generate a color based on key
    final colorOptions = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
    ];
    
    // Generate a consistent color based on the key's hashcode
    final index = key.hashCode % colorOptions.length;
    return colorOptions[index.abs()];
  }
  
  Color _getColorFromPercentage(double percentage) {
    if (percentage < 0.2) {
      return Colors.red;
    } else if (percentage < 0.4) {
      return Colors.orange;
    } else if (percentage < 0.6) {
      return Colors.yellow;
    } else if (percentage < 0.8) {
      return Colors.lightGreen;
    } else {
      return Colors.green;
    }
  }
  
  /// Factory for creating a pie chart distribution
  factory DistributionDisplay.pieChart({
    required String title,
    String? subtitle,
    required Map<String, Map<String, dynamic>> data,
    required String countKey,
    String? labelKey,
    Map<String, Color>? colorMap,
    bool useCard = true,
  }) {
    return DistributionDisplay(
      type: DistributionType.pie,
      title: title,
      subtitle: subtitle,
      distributionData: data,
      countKey: countKey,
      labelKey: labelKey,
      colorMap: colorMap,
      useCard: useCard,
    );
  }
  
  /// Factory for creating a zone grid display
  factory DistributionDisplay.zoneGrid({
    required String title,
    String? subtitle,
    required Map<String, Map<String, dynamic>> zoneData,
    required Map<String, String> zoneLabels,
    String? countKey = 'count',
    String? successRateKey = 'successRate',
    bool useCard = true,
  }) {
    // Prepare zone data with labels
    final enrichedZoneData = <String, Map<String, dynamic>>{};
    
    for (final entry in zoneData.entries) {
      enrichedZoneData[entry.key] = {
        ...entry.value,
        'label': zoneLabels[entry.key] ?? '',
      };
    }
    
    return DistributionDisplay(
      type: DistributionType.grid,
      title: title,
      subtitle: subtitle,
      distributionData: enrichedZoneData,
      countKey: countKey ?? 'count',
      percentageKey: successRateKey,
      labelKey: 'label',
      rows: 3,
      columns: 3,
      useCard: useCard,
    );
  }
  
  /// Factory for creating a bar chart distribution
  factory DistributionDisplay.barChart({
    required String title,
    String? subtitle,
    required Map<String, Map<String, dynamic>> data,
    required String countKey,
    String? labelKey,
    Map<String, Color>? colorMap,
    bool useCard = true,
  }) {
    return DistributionDisplay(
      type: DistributionType.bar,
      title: title,
      subtitle: subtitle,
      distributionData: data,
      countKey: countKey,
      labelKey: labelKey,
      colorMap: colorMap,
      useCard: useCard,
    );
  }
}