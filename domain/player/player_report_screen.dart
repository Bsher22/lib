// lib/screens/analysis/player_report_screen.dart
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/player.dart';

class PlayerReportScreen extends StatefulWidget {
  final Player player;

  const PlayerReportScreen({
    Key? key,
    required this.player,
  }) : super(key: key);

  @override
  _PlayerReportScreenState createState() => _PlayerReportScreenState();
}

class _PlayerReportScreenState extends State<PlayerReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPlayerData();
  }
  
  Future<void> _loadPlayerData() async {
    // This would normally fetch player data from your providers
    // For now, we'll just simulate a loading delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.player.name} Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Shots'),
            Tab(text: 'Skating'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildShotsTab(),
                _buildSkatingTab(),
              ],
            ),
    );
  }
  
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Player Information', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  _infoRow('Name', widget.player.name),
                  if (widget.player.jerseyNumber != null)
                    _infoRow('Jersey Number', '#${widget.player.jerseyNumber}'),
                  if (widget.player.preferredPosition != null)
                    _infoRow('Position', widget.player.preferredPosition!),
                  if (widget.player.teamName != null)
                    _infoRow('Team', widget.player.teamName!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Performance Summary', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  const Text(
                    'This section would display a summary of the player\'s performance metrics, '
                    'including shot success rates, skating assessments, and recent improvements.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Placeholder for Performance Charts',
                      style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShotsTab() {
    return const Center(
      child: Text(
        'Shot data visualizations would appear here.\n'
        'This would include shot maps, success rates by type,\n'
        'and trend analysis over time.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
  
  Widget _buildSkatingTab() {
    return const Center(
      child: Text(
        'Skating assessment results would appear here.\n'
        'This would include speed, agility, and transition metrics,\n'
        'along with comparisons to benchmarks.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16),
      ),
    );
  }
  
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}