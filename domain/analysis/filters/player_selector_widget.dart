import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';

class PlayerSelectorWidget extends StatelessWidget {
  final Player? selectedPlayer;
  final Function(Player) onPlayerSelected;

  const PlayerSelectorWidget({
    Key? key,
    required this.selectedPlayer,
    required this.onPlayerSelected,
  }) : super(key: key);

  void _showPlayerSelector(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final players = appState.players;

    final selectedPlayer = await showDialog<Player>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Player'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: players.length,
            itemBuilder: (context, index) {
              final player = players[index];
              return ListTile(
                title: Text(player.name),
                subtitle: Text(player.teamName ?? 'No Team'),
                selected: player.id == this.selectedPlayer?.id,
                onTap: () => Navigator.pop(context, player),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedPlayer != null && selectedPlayer.id != this.selectedPlayer?.id) {
      onPlayerSelected(selectedPlayer);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showPlayerSelector(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey[700],
              child: Text(
                selectedPlayer!.name[0].toUpperCase(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedPlayer!.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}