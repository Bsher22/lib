// lib/widgets/domain/common/pagination_shot_list.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/shot.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class PaginatedShotList extends StatefulWidget {
  final int initialLimit;
  
  const PaginatedShotList({
    super.key,
    this.initialLimit = 20,
  });
  
  @override
  State<PaginatedShotList> createState() => _PaginatedShotListState();
}

class _PaginatedShotListState extends State<PaginatedShotList> {
  bool _loadingMore = false;
  final ScrollController _scrollController = ScrollController();
  int _pageOffset = 0;
  
  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // No need to call a specific load method here, as the shots should 
    // already be loaded from the AppState initialization
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }
  
  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreShots();
    }
  }
  
  Future<void> _loadMoreShots() async {
    if (_loadingMore) return;
    
    setState(() {
      _loadingMore = true;
    });
    
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Use the reloadShotsFromApi method that exists in AppState
    await appState.reloadShotsFromApi();
    _pageOffset += widget.initialLimit;
    
    if (mounted) {
      setState(() {
        _loadingMore = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: appState.shots.length + 1, // +1 for loading indicator
      itemBuilder: (context, index) {
        if (index == appState.shots.length) {
          return _loadingMore 
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : const SizedBox.shrink();
        }
        
        final shot = appState.shots[index];
        return _buildShotItem(shot);
      },
    );
  }
  
  Widget _buildShotItem(Shot shot) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: shot.success
              ? Colors.green
              : shot.outcome == 'Miss'
                  ? Colors.red
                  : Colors.orange,
          child: Icon(
            shot.success
                ? Icons.check
                : shot.outcome == 'Miss'
                    ? Icons.close
                    : Icons.shield,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          '${shot.type ?? "Unknown"} - Zone ${shot.zone ?? "Unknown"}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateFormat.format(shot.timestamp ?? shot.timestamp)),
            if (shot.workout != null && shot.workout!.isNotEmpty)
              Text(
                'Workout: ${shot.workout}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blueGrey[600],
                ),
              ),
          ],
        ),
        trailing: shot.videoPath != null
            ? IconButton(
                icon: const Icon(Icons.play_circle, color: Colors.blue),
                onPressed: () {
                  // Video playback functionality to be implemented
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Video playback to be implemented'),
                    ),
                  );
                },
              )
            : null,
        onTap: () {
          // Shot detail view to be implemented
        },
      ),
    );
  }
}