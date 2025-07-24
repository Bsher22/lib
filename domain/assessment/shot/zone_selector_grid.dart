// widgets/assessment/shot/zone_selector_grid.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class ZoneSelectorGrid extends StatelessWidget {
  final String selectedZone;
  final Function(String) onZoneSelected;
  final List<String>? intendedZones; // NEW: For highlighting target zones
  
  const ZoneSelectorGrid({
    Key? key,
    required this.selectedZone,
    required this.onZoneSelected,
    this.intendedZones,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final zones = List.generate(9, (index) => (index + 1).toString());
    final zoneLabels = {
      '1': 'Top Left',
      '2': 'Top Center', 
      '3': 'Top Right',
      '4': 'Mid Left',
      '5': 'Mid Center',
      '6': 'Mid Right',
      '7': 'Bottom Left',
      '8': 'Bottom Center',
      '9': 'Bottom Right',
    };

    // Responsive grid sizing
    final gridSize = context.responsive<double>(
      mobile: 200,
      tablet: 250,
      desktop: 300,
    );

    return Container(
      width: gridSize,
      height: gridSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: zones.length,
        itemBuilder: (context, index) {
          final zone = zones[index];
          final isSelected = selectedZone == zone;
          final isIntended = intendedZones?.contains(zone) ?? false;
          
          return GestureDetector(
            onTap: () => onZoneSelected(zone),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: isSelected 
                    ? Colors.cyanAccent[700]
                    : isIntended 
                        ? Colors.green[200]
                        : Colors.white,
                border: Border.all(
                  color: isSelected 
                      ? Colors.cyanAccent[700]!
                      : isIntended
                          ? Colors.green[400]!
                          : Colors.grey[400]!,
                  width: isSelected ? 3 : (isIntended ? 2 : 1),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    zone,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: ResponsiveConfig.fontSize(context, 16),
                    ),
                  ),
                  Text(
                    zoneLabels[zone] ?? '',
                    style: TextStyle(
                      fontSize: ResponsiveConfig.fontSize(context, 7),
                      color: isSelected ? Colors.white70 : Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}