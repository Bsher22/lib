// lib/widgets/core/form/searchable_player_dropdown.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';

class SearchablePlayerDropdown extends StatefulWidget {
  final Player? selectedPlayer;
  final List<Player> players;
  final Function(Player?) onChanged;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final bool enabled;
  final bool required;

  const SearchablePlayerDropdown({
    Key? key,
    required this.players,
    required this.onChanged,
    this.selectedPlayer,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.enabled = true,
    this.required = false,
  }) : super(key: key);

  @override
  State<SearchablePlayerDropdown> createState() => _SearchablePlayerDropdownState();
}

class _SearchablePlayerDropdownState extends State<SearchablePlayerDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<Player> _filteredPlayers = [];
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _filteredPlayers = widget.players;
    if (widget.selectedPlayer != null) {
      _searchController.text = _getPlayerDisplayText(widget.selectedPlayer!);
    }
  }

  @override
  void didUpdateWidget(SearchablePlayerDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.players != oldWidget.players) {
      _filteredPlayers = widget.players;
      _filterPlayers(_searchController.text);
    }
    if (widget.selectedPlayer != oldWidget.selectedPlayer) {
      if (widget.selectedPlayer != null) {
        _searchController.text = _getPlayerDisplayText(widget.selectedPlayer!);
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

  String _getPlayerDisplayText(Player player) {
    return '${player.name} ${player.jerseyNumber != null ? "(#${player.jerseyNumber})" : ""}';
  }

  void _filterPlayers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPlayers = widget.players;
      } else {
        _filteredPlayers = widget.players.where((player) {
          final name = player.name.toLowerCase();
          final jersey = player.jerseyNumber?.toString() ?? '';
          final position = player.position?.toLowerCase() ?? '';
          final team = player.teamName?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();
          
          return name.contains(searchLower) ||
                 jersey.contains(searchLower) ||
                 position.contains(searchLower) ||
                 team.contains(searchLower);
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
              constraints: const BoxConstraints(maxHeight: 300),
              child: _buildDropdownList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownList() {
    if (_filteredPlayers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'No players found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (_searchController.text.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Try adjusting your search',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      itemCount: _filteredPlayers.length,
      itemBuilder: (context, index) {
        final player = _filteredPlayers[index];
        final isSelected = widget.selectedPlayer?.id == player.id;

        return ListTile(
          selected: isSelected,
          selectedTileColor: Colors.blue[50],
          leading: CircleAvatar(
            radius: 18,
            backgroundColor: isSelected ? Colors.blue[600] : Colors.blueGrey[700],
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          title: Text(
            player.name,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (player.jerseyNumber != null)
                Text('Jersey #${player.jerseyNumber}'),
              if (player.position != null || player.teamName != null)
                Text(
                  [
                    if (player.position != null) player.position!,
                    if (player.teamName != null) player.teamName!,
                  ].join(' • '),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          trailing: isSelected
              ? Icon(Icons.check, color: Colors.blue[600])
              : null,
          onTap: () {
            widget.onChanged(player);
            _searchController.text = _getPlayerDisplayText(player);
            _removeOverlay();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: _searchController,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText ?? 'Search and select a player...',
          errorText: widget.errorText,
          helperText: widget.helperText,
          prefixIcon: const Icon(Icons.person_search),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty && widget.enabled)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onChanged(null);
                    _filterPlayers('');
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
        onChanged: _filterPlayers,
        onTap: () {
          if (!_isOpen && widget.enabled) {
            _showOverlay();
          }
        },
        validator: widget.required 
            ? (value) {
                if (widget.selectedPlayer == null) {
                  return 'Please select a player';
                }
                return null;
              }
            : null,
      ),
    );
  }
}