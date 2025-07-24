// widgets/analysis/team_selector_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';

class TeamSelectorWidget extends StatelessWidget {
  final Team? selectedTeam;
  final Function(Team) onTeamSelected;
  final bool showTeamDetails;

  const TeamSelectorWidget({
    Key? key,
    required this.selectedTeam,
    required this.onTeamSelected,
    this.showTeamDetails = false,
  }) : super(key: key);

  void _showTeamSelector(BuildContext context) async {
    final appState = Provider.of<AppState>(context, listen: false);
    final teams = appState.teams;

    final selectedTeam = await showDialog<Team>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Team'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final team = teams[index];
              return ListTile(
                title: Text(team.name),
                subtitle: showTeamDetails 
                    ? Text('${appState.getPlayersByTeam(team.id).length} players')
                    : null,
                selected: team.id == this.selectedTeam?.id,
                onTap: () => Navigator.pop(context, team),
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

    if (selectedTeam != null && selectedTeam.id != this.selectedTeam?.id) {
      onTeamSelected(selectedTeam);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (selectedTeam == null) {
      return OutlinedButton.icon(
        onPressed: () => _showTeamSelector(context),
        icon: const Icon(Icons.group),
        label: const Text('Select Team'),
      );
    }
    
    return InkWell(
      onTap: () => _showTeamSelector(context),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey[700],
              child: const Icon(
                Icons.group,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              selectedTeam!.name,
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