import 'package:flutter/material.dart';

class FilterDialogWidget extends StatefulWidget {
  final String timeRange;
  final List<String> selectedShotTypes;
  final List<String> allShotTypes;
  final Function(String, List<String>) onApply;

  const FilterDialogWidget({
    Key? key,
    required this.timeRange,
    required this.selectedShotTypes,
    required this.allShotTypes,
    required this.onApply,
  }) : super(key: key);

  @override
  State<FilterDialogWidget> createState() => _FilterDialogWidgetState();
}

class _FilterDialogWidgetState extends State<FilterDialogWidget> {
  late String _timeRange;
  late List<String> _selectedShotTypes;

  @override
  void initState() {
    super.initState();
    _timeRange = widget.timeRange;
    _selectedShotTypes = List.from(widget.selectedShotTypes);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Analysis Data'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time range filter
            const Text(
              'Time Range',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['7 days', '30 days', '90 days', 'All time'].map((range) {
                return ChoiceChip(
                  label: Text(range),
                  selected: _timeRange == range,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _timeRange = range;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Shot type filter
            const Text(
              'Shot Types',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: widget.allShotTypes.map((type) {
                return FilterChip(
                  label: Text(type),
                  selected: _selectedShotTypes.contains(type),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedShotTypes.add(type);
                      } else {
                        _selectedShotTypes.remove(type);
                        // Ensure at least one type is selected
                        if (_selectedShotTypes.isEmpty) {
                          _selectedShotTypes.add(type);
                        }
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _timeRange = '30 days';
              _selectedShotTypes = List.from(widget.allShotTypes);
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(_timeRange, _selectedShotTypes);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.cyanAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('Apply'),
        ),
      ],
    );
  }
}