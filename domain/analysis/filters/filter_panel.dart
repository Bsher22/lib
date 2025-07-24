import 'package:flutter/material.dart';

class FilterOption {
  final String id;
  final String label;
  final bool isSelected;
  
  FilterOption({
    required this.id,
    required this.label,
    this.isSelected = false,
  });
  
  FilterOption copyWith({bool? isSelected}) {
    return FilterOption(
      id: this.id,
      label: this.label,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

typedef OnFilterChanged = void Function(List<String> selectedIds);

class FilterPanel extends StatefulWidget {
  final String title;
  final List<FilterOption> options;
  final OnFilterChanged onFilterChanged;
  final bool showClearButton;
  final bool initiallyExpanded;
  final Widget? leading;

  const FilterPanel({
    Key? key,
    required this.title,
    required this.options,
    required this.onFilterChanged,
    this.showClearButton = true,
    this.initiallyExpanded = false,
    this.leading,
  }) : super(key: key);

  @override
  _FilterPanelState createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late List<FilterOption> _options;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.options);
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  void didUpdateWidget(FilterPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      _options = List.from(widget.options);
    }
  }

  void _updateFilter(int index, bool value) {
    setState(() {
      _options[index] = _options[index].copyWith(isSelected: value);
    });
    _notifyFilterChanged();
  }

  void _clearFilters() {
    setState(() {
      for (int i = 0; i < _options.length; i++) {
        _options[i] = _options[i].copyWith(isSelected: false);
      }
    });
    _notifyFilterChanged();
  }

  void _notifyFilterChanged() {
    final selectedIds = _options
        .where((opt) => opt.isSelected)
        .map((opt) => opt.id)
        .toList();
    widget.onFilterChanged(selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (widget.leading != null) ...[
                    widget.leading!,
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                  ),
                  if (widget.showClearButton && _options.any((opt) => opt.isSelected))
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 0),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.blueGrey[400],
                  ),
                ],
              ),
            ),
          ),
          
          // Filter options
          if (_isExpanded) 
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_options.length, (index) {
                  return FilterChip(
                    label: Text(_options[index].label),
                    selected: _options[index].isSelected,
                    onSelected: (value) => _updateFilter(index, value),
                    selectedColor: Colors.cyanAccent,
                    checkmarkColor: Colors.black87,
                    labelStyle: TextStyle(
                      color: _options[index].isSelected ? Colors.black87 : Colors.blueGrey[700],
                      fontWeight: _options[index].isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}