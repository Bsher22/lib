import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/user.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _isLoading = false;
  List<User> _coaches = [];
  List<User> _coordinators = [];
  List<Team> _teams = [];
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final api = appState.api;

      if (api.isAdmin()) {
        _coaches = await api.fetchUsersByRole('coach');
        _coordinators = await api.fetchUsersByRole('coordinator');
        _teams = await api.fetchTeams();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTeam(int teamId) async {
    setState(() => _isLoading = true);
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await appState.deleteTeam(teamId);
      setState(() {
        _teams.removeWhere((team) => team.id == teamId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting team: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _navigateToUserForm(String role, {User? user}) async {
    final result = await Navigator.pushNamed(
      context,
      role == 'coach' ? '/coach-form' : '/coordinator-form',
      arguments: user,
    );
    if (result == true) {
      await _fetchData(); // Refresh user lists
      setState(() {});
    }
  }

  Future<void> _navigateToTeamForm({Team? team}) async {
    final result = await Navigator.pushNamed(
      context,
      '/team-form',
      arguments: team,
    );
    if (result == true) {
      await _fetchData(); // Refresh team list
      setState(() {});
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: ResponsiveConfig.borderRadius(context, 16).topLeft,
        ),
      ),
      builder: (context) => Container(
        padding: ResponsiveConfig.paddingAll(context, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_add),
              title: ResponsiveText('Add Coach', baseFontSize: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToUserForm('coach');
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: ResponsiveText('Add Coordinator', baseFontSize: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToUserForm('coordinator');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_add),
              title: ResponsiveText('Add Team', baseFontSize: 16),
              onTap: () {
                Navigator.pop(context);
                _navigateToTeamForm();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isAdmin = appState.isAdmin();

    return AdaptiveScaffold(
      title: 'Admin Settings',
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(isAdmin),
      floatingActionButton: isAdmin
          ? FloatingActionButton(
              onPressed: () => _showAddOptions(context),
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black87,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(bool isAdmin) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return SingleChildScrollView(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1200 : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ResponsiveText(
                  'User Management',
                  baseFontSize: 24,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                _buildUserSection(
                  'Coaches',
                  _coaches,
                  'coach',
                  isAdmin,
                ),
                ResponsiveSpacing(multiplier: 3),
                _buildUserSection(
                  'Coordinators',
                  _coordinators,
                  'coordinator',
                  isAdmin,
                ),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveText(
                  'Team Management',
                  baseFontSize: 24,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                _buildTeamSection(isAdmin),
                ResponsiveSpacing(multiplier: 3),
                ResponsiveText(
                  'System Settings',
                  baseFontSize: 24,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                _buildSystemSettings(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserSection(
      String title, List<User> users, String role, bool isAdmin) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            title,
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          ResponsiveSpacing(multiplier: 1),
          users.isEmpty
              ? ResponsiveText(
                  'No users found.',
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.grey[600]),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserListTile(user, role, isAdmin);
                  },
                ),
          if (isAdmin) ...[
            ResponsiveSpacing(multiplier: 1),
            ResponsiveButton(
              text: 'Add $title',
              onPressed: () => _navigateToUserForm(role),
              baseHeight: 40,
              backgroundColor: Colors.cyanAccent,
              textColor: Colors.black87,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserListTile(User user, String role, bool isAdmin) {
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
        title: ResponsiveText(
          user.username ?? 'Unknown',
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: ResponsiveText(
          user.email ?? '',
          baseFontSize: 14,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _navigateToUserForm(role, user: user),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Delete ${user.username}?'),
                          action: SnackBarAction(
                            label: 'Confirm',
                            onPressed: () {
                              // Implement deletion logic
                            },
                          ),
                        ),
                      );
                    },
                    tooltip: 'Delete',
                  ),
                ],
              )
            : null,
        onTap: () {
          Navigator.pushNamed(
            context,
            role == 'coach' ? '/coach-details' : '/coordinator-details',
            arguments: user,
          );
        },
      ),
    );
  }

  Widget _buildTeamSection(bool isAdmin) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Teams',
            baseFontSize: 20,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          ResponsiveSpacing(multiplier: 1),
          _teams.isEmpty
              ? ResponsiveText(
                  'No teams found.',
                  baseFontSize: 14,
                  style: TextStyle(color: Colors.grey[600]),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];
                    return _buildTeamListTile(team, isAdmin);
                  },
                ),
          if (isAdmin) ...[
            ResponsiveSpacing(multiplier: 1),
            ResponsiveButton(
              text: 'Add Team',
              onPressed: () => _navigateToTeamForm(),
              baseHeight: 40,
              backgroundColor: Colors.cyanAccent,
              textColor: Colors.black87,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeamListTile(Team team, bool isAdmin) {
    return Container(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
        title: ResponsiveText(
          team.name ?? 'Unknown',
          baseFontSize: 16,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: ResponsiveText(
          'ID: ${team.id}',
          baseFontSize: 14,
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: isAdmin
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _navigateToTeamForm(team: team),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () => _deleteTeam(team.id!),
                    tooltip: 'Delete',
                  ),
                ],
              )
            : null,
        onTap: () {
          Navigator.pushNamed(context, '/team-details', arguments: team);
        },
      ),
    );
  }

  Widget _buildSystemSettings() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: ResponsiveText(
              'Enable Notifications',
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
            },
            activeColor: Colors.cyanAccent,
            contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
          ),
          ResponsiveSpacing(multiplier: 1),
          ListTile(
            title: ResponsiveText(
              'Clear Cache',
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.delete_forever),
            contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared')),
              );
            },
          ),
          ResponsiveSpacing(multiplier: 1),
          ListTile(
            title: ResponsiveText(
              'Export Data',
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.download),
            contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data export feature coming soon')),
              );
            },
          ),
          ResponsiveSpacing(multiplier: 1),
          ListTile(
            title: ResponsiveText(
              'System Diagnostics',
              baseFontSize: 16,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: const Icon(Icons.bug_report),
            contentPadding: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('System diagnostics feature coming soon')),
              );
            },
          ),
        ],
      ),
    );
  }
}