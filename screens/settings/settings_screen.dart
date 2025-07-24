import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/database_service.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _serverUrl;
  bool _isSyncing = false;
  bool _isClearing = false;
  double _databaseSize = 0;
  late TextEditingController _serverUrlController;
  String? _syncSuccessMessage;
  String? _syncErrorMessage;
  String? _clearSuccessMessage;
  String? _clearErrorMessage;

  @override
  void initState() {
    super.initState();
    _calculateDatabaseSize();
    _serverUrl = 'http://192.168.1.4:5000';
    _serverUrlController = TextEditingController(text: _serverUrl);
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    super.dispose();
  }

  Future<void> _calculateDatabaseSize() async {
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbDir.path}/hockey_tracker_local.db');
      if (await dbFile.exists()) {
        final size = await dbFile.length();
        if (mounted) {
          setState(() {
            _databaseSize = size / (1024 * 1024); // Convert to MB
          });
        }
      }
    } catch (e) {
      debugPrint('Error calculating database size: $e');
    }
  }

  Future<void> _syncWithBackend() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    setState(() {
      _isSyncing = true;
      _syncSuccessMessage = null;
      _syncErrorMessage = null;
    });
    
    bool success = false;
    
    try {
      await LocalDatabaseService.instance.syncWithBackend();
      await appState.loadInitialData();
      
      _syncSuccessMessage = 'Sync completed successfully';
      success = true;
    } catch (e) {
      _syncErrorMessage = 'Sync failed: $e';
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncSuccessMessage!),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_syncErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_syncErrorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _clearLocalDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: ResponsiveText('Clear Local Data?', baseFontSize: 18),
        content: ResponsiveText(
          'This will delete all locally stored data. Synced data will still be available when you connect to the server. This action cannot be undone.',
          baseFontSize: 16,
        ),
        contentPadding: ResponsiveConfig.paddingAll(context, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: ResponsiveText('Cancel', baseFontSize: 16),
          ),
          ResponsiveButton(
            text: 'Clear Data',
            baseHeight: 40,
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed || !mounted) return;

    final appState = Provider.of<AppState>(context, listen: false);

    setState(() {
      _isClearing = true;
      _clearSuccessMessage = null;
      _clearErrorMessage = null;
    });
    
    bool success = false;
    
    try {
      final dbDir = await getApplicationDocumentsDirectory();
      final dbFile = File('${dbDir.path}/hockey_tracker_local.db');
      if (await dbFile.exists()) {
        await dbFile.delete();
        await LocalDatabaseService.instance.database;
      }

      await appState.loadInitialData();

      _clearSuccessMessage = 'Local data cleared successfully';
      success = true;
    } catch (e) {
      _clearErrorMessage = 'Failed to clear data: $e';
    } finally {
      if (mounted) {
        setState(() {
          _isClearing = false;
          if (success) {
            _databaseSize = 0;
          }
        });
      }
    }
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_clearSuccessMessage!),
          backgroundColor: Colors.green,
        ),
      );
    } else if (_clearErrorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_clearErrorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveScaffold(
      title: 'Settings',
      backgroundColor: Colors.grey[100],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
              ),
              child: _buildContent(deviceType, isLandscape),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(DeviceType deviceType, bool isLandscape) {
    switch (deviceType) {
      case DeviceType.mobile:
        return _buildMobileLayout();
      case DeviceType.tablet:
        return isLandscape ? _buildTabletLayout() : _buildMobileLayout();
      case DeviceType.desktop:
        return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSection(
          title: 'Server Configuration',
          children: [
            _buildServerUrlField(),
            ResponsiveSpacing(multiplier: 2),
            _buildSyncButton(),
          ],
        ),
        ResponsiveSpacing(multiplier: 3),
        _buildSection(
          title: 'Local Data',
          children: [
            _buildDatabaseSizeInfo(),
            ResponsiveSpacing(multiplier: 1),
            _buildClearDataButton(),
          ],
        ),
        ResponsiveSpacing(multiplier: 3),
        _buildSection(
          title: 'About',
          children: [
            _buildAboutInfo(),
          ],
        ),
        ResponsiveSpacing(multiplier: 4),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Two-column layout for main sections
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSection(
                    title: 'Server Configuration',
                    children: [
                      _buildServerUrlField(),
                      ResponsiveSpacing(multiplier: 2),
                      _buildSyncButton(),
                    ],
                  ),
                  ResponsiveSpacing(multiplier: 3),
                  _buildSection(
                    title: 'Local Data',
                    children: [
                      _buildDatabaseSizeInfo(),
                      ResponsiveSpacing(multiplier: 1),
                      _buildClearDataButton(),
                    ],
                  ),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
            Expanded(
              child: _buildSection(
                title: 'About',
                children: [
                  _buildAboutInfo(),
                ],
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 4),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Three-column layout for desktop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _buildSection(
                title: 'Server Configuration',
                children: [
                  _buildServerUrlField(),
                  ResponsiveSpacing(multiplier: 2),
                  _buildSyncButton(),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
            Expanded(
              flex: 2,
              child: _buildSection(
                title: 'Local Data',
                children: [
                  _buildDatabaseSizeInfo(),
                  ResponsiveSpacing(multiplier: 1),
                  _buildClearDataButton(),
                ],
              ),
            ),
            ResponsiveSpacing(multiplier: 3, direction: Axis.horizontal),
            Expanded(
              flex: 1,
              child: _buildSection(
                title: 'About',
                children: [
                  _buildAboutInfo(),
                ],
              ),
            ),
          ],
        ),
        ResponsiveSpacing(multiplier: 4),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            title,
            baseFontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
          ResponsiveSpacing(multiplier: 2),
          ...children,
        ],
      ),
    );
  }

  Widget _buildServerUrlField() {
    return TextFormField(
      controller: _serverUrlController,
      decoration: InputDecoration(
        labelText: 'Server URL',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.link),
        contentPadding: ResponsiveConfig.paddingSymmetric(
          context,
          horizontal: 16,
          vertical: 12,
        ),
      ),
      style: TextStyle(fontSize: ResponsiveConfig.fontSize(context, 16)),
      onChanged: (value) {
        setState(() {
          _serverUrl = value;
        });
      },
    );
  }

  Widget _buildSyncButton() {
    return ResponsiveButton(
      text: _isSyncing ? 'Syncing...' : 'Sync Now',
      baseHeight: 48,
      width: double.infinity,
      onPressed: _isSyncing ? null : _syncWithBackend,
      icon: _isSyncing ? Icons.sync : Icons.sync,
      isLoading: _isSyncing, // FIXED: Changed from loadingIndicator to isLoading
    );
  }

  Widget _buildDatabaseSizeInfo() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: ResponsiveText(
        'Database Size',
        baseFontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitle: ResponsiveText(
        '${_databaseSize.toStringAsFixed(2)} MB',
        baseFontSize: 14,
        color: Colors.grey[600],
      ),
      leading: Icon(
        Icons.storage,
        size: ResponsiveConfig.dimension(context, 24),
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildClearDataButton() {
    return ResponsiveButton(
      text: _isClearing ? 'Clearing...' : 'Clear Local Data',
      baseHeight: 48,
      width: double.infinity,
      onPressed: _isClearing ? null : _clearLocalDatabase,
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: _isClearing ? Icons.hourglass_empty : Icons.delete_forever,
      isLoading: _isClearing, // FIXED: Changed from loadingIndicator to isLoading
    );
  }

  Widget _buildAboutInfo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildAboutItem(
          icon: Icons.info,
          title: 'Version',
          subtitle: '1.0.0',
        ),
        ResponsiveSpacing(multiplier: 1),
        _buildAboutItem(
          icon: Icons.code,
          title: 'Developer',
          subtitle: 'Hockey Shot Tracker Team',
        ),
        ResponsiveSpacing(multiplier: 1),
        _buildAboutItem(
          icon: Icons.sports_hockey,
          title: 'App',
          subtitle: 'HIRE Hockey Tracker',
        ),
      ],
    );
  }

  Widget _buildAboutItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        size: ResponsiveConfig.dimension(context, 24),
        color: Theme.of(context).primaryColor,
      ),
      title: ResponsiveText(
        title,
        baseFontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      subtitle: ResponsiveText(
        subtitle,
        baseFontSize: 14,
        color: Colors.grey[600],
      ),
    );
  }
}