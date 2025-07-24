// lib/widgets/core/form/standard_dropdown.dart
import 'package:flutter/material.dart';

class StandardDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final ValueChanged<T?>? onChanged;
  final FormFieldValidator<T>? validator;
  final bool isExpanded;
  final bool isDense;
  final bool enabled;
  final bool enableSearch;
  final String Function(T)? searchableTextExtractor;

  const StandardDropdown({
    Key? key,
    required this.items,
    this.value,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon,
    this.onChanged,
    this.validator,
    this.isExpanded = true,
    this.isDense = false,
    this.enabled = true,
    this.enableSearch = false,
    this.searchableTextExtractor,
  }) : super(key: key);

  @override
  State<StandardDropdown<T>> createState() => _StandardDropdownState<T>();
}

class _StandardDropdownState<T> extends State<StandardDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<DropdownMenuItem<T>> _filteredItems = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    if (widget.value != null && widget.enableSearch) {
      final selectedItem = widget.items.firstWhere(
        (item) => item.value == widget.value,
        orElse: () => widget.items.first,
      );
      if (selectedItem.child is Text) {
        _searchController.text = (selectedItem.child as Text).data ?? '';
      }
    }
  }

  @override
  void didUpdateWidget(StandardDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _filteredItems = widget.items;
      if (widget.enableSearch) {
        _filterItems(_searchController.text);
      }
    }
    if (widget.value != oldWidget.value && widget.enableSearch) {
      if (widget.value != null) {
        final selectedItem = widget.items.firstWhere(
          (item) => item.value == widget.value,
          orElse: () => widget.items.first,
        );
        if (selectedItem.child is Text) {
          _searchController.text = (selectedItem.child as Text).data ?? '';
        }
      } else {
        _searchController.clear();
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          String searchText = '';
          
          if (widget.searchableTextExtractor != null && item.value != null) {
            searchText = widget.searchableTextExtractor!(item.value as T);
          } else if (item.child is Text) {
            searchText = (item.child as Text).data ?? '';
          }
          
          return searchText.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
    _updateOverlay();
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;

    setState(() {
      _isOpen = true;
    });

    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {
      _isOpen = false;
    });
  }

  void _updateOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Size size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0.0, size.height + 8.0),
          child: Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 250),
              child: _buildDropdownList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownList() {
    if (_filteredItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 32,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No items found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        final isSelected = widget.value == item.value;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Colors.blue[50],
          title: item.child,
          trailing: isSelected ? Icon(Icons.check, color: Colors.blue[600]) : null,
          onTap: () {
            widget.onChanged?.call(item.value);
            if (item.child is Text) {
              _searchController.text = (item.child as Text).data ?? '';
            }
            _removeOverlay();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enableSearch) {
      // Use standard dropdown when search is disabled
      return DropdownButtonFormField<T>(
        value: widget.value,
        items: widget.items,
        onChanged: widget.enabled ? widget.onChanged : null,
        validator: widget.validator != null 
            ? (T? value) => widget.validator!(value)
            : null,
        isExpanded: widget.isExpanded,
        isDense: widget.isDense,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          errorText: widget.errorText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Use searchable dropdown when search is enabled
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _searchController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'Search and select...',
          errorText: widget.errorText,
          helperText: widget.helperText,
          prefixIcon: widget.prefixIcon != null 
              ? Icon(widget.prefixIcon) 
              : const Icon(Icons.search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty && widget.enabled)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onChanged?.call(null);
                    _filterItems('');
                  },
                ),
              IconButton(
                icon: Icon(_isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
                onPressed: widget.enabled ? _toggleDropdown : null,
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: _filterItems,
        onTap: () {
          if (!_isOpen && widget.enabled) {
            _showOverlay();
          }
        },
        validator: widget.validator != null 
            ? (String? value) {
                // For search mode, we validate the current selection, not the text
                return widget.validator!(widget.value);
              }
            : null,
      ),
    );
  }

  /// Helper method to create a list of DropdownMenuItems from a simple map
  static List<DropdownMenuItem<T>> itemsFromMap<T>(Map<T, String> itemsMap) {
    return itemsMap.entries.map((entry) {
      return DropdownMenuItem<T>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
  }

  /// Helper method to create a null item for "no selection"
  static DropdownMenuItem<T> createNullItem<T>(String text) {
    return DropdownMenuItem<T>(
      value: null,
      child: Text(text),
    );
  }

  /// Legacy method name for backwards compatibility  
  static DropdownMenuItem<T> nullItem<T>(String text) {
    return createNullItem<T>(text);
  }
}