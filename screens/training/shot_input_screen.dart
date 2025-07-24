import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Updated imports using index files
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/state/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/widgets/core/timer/index.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';

class ShotInputScreen extends StatefulWidget {
  const ShotInputScreen({super.key});

  @override
  State<ShotInputScreen> createState() => _ShotInputScreenState();
}

class _ShotInputScreenState extends State<ShotInputScreen> with WidgetsBindingObserver {
  // Shot data
  String selectedZone = '';
  String selectedType = '';
  String selectedOutcome = 'Goal';
  final shotTypes = ['Wrist', 'Slap', 'Snap', 'Backhand'];
  final zones = List.generate(9, (index) => (index + 1).toString());

  // Advanced metrics
  bool _showAdvancedMetrics = false;
  final TextEditingController _powerController = TextEditingController();
  final UnifiedTimerController _quickReleaseController = UnifiedTimerController();
  final TextEditingController _distanceController = TextEditingController();
  String _locationOnIce = 'Slot';
  final List<String> _iceLocations = ['Slot', 'Left Wing', 'Right Wing', 'Point', 'Behind Net'];
  
  // Zone descriptions
  final Map<String, String> zoneLabels = {
    '1': 'Top Left', '2': 'Top Center', '3': 'Top Right',
    '4': 'Mid Left', '5': 'Mid Center', '6': 'Mid Right',
    '7': 'Bottom Left', '8': 'Bottom Center', '9': 'Bottom Right',
  };
  
  // Camera properties
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  String? _videoPath;
  bool _showCameraView = false;
  bool _cameraEnabled = false;
  
  // Status tracking
  bool _isSaving = false;
  String? _errorMessage;
  bool _shotRecorded = false;
  bool _videoCaptured = false;
  
  // Session tracking
  List<Map<String, dynamic>> _sessionShots = [];
  bool _sessionActive = false;
  DateTime? _sessionStartTime;
  
  // Mock data for shots
  List<Map<String, dynamic>> shots = [];
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserPreferences();
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    cameraController?.dispose();
    _powerController.dispose();
    _quickReleaseController.dispose();
    _distanceController.dispose();
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (cameraController == null || !_isCameraInitialized) {
      return;
    }
    
    if (state == AppLifecycleState.inactive) {
      cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }
  
  Future<void> _loadUserPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _cameraEnabled = prefs.getBool('camera_enabled') ?? false;
        _showAdvancedMetrics = prefs.getBool('advanced_metrics_enabled') ?? false;
      });
      
      if (_cameraEnabled) {
        _initializeCamera();
      }
    }
  }
  
  Future<void> _toggleCameraFeature(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camera_enabled', value);
    
    if (!mounted) return;
    
    setState(() {
      _cameraEnabled = value;
      if (!value) {
        _showCameraView = false;
      }
    });
    
    if (value && !_isCameraInitialized) {
      await _initializeCamera();
    } else if (!value && _isCameraInitialized) {
      await cameraController?.dispose();
      
      if (!mounted) return;
      
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }
  
  Future<void> _toggleAdvancedMetrics(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('advanced_metrics_enabled', value);
    
    if (!mounted) return;
    
    setState(() {
      _showAdvancedMetrics = value;
    });
  }
  
  Future<void> _initializeCamera() async {
    if (!_cameraEnabled) return;
    
    try {
      cameras = await availableCameras();
      if (cameras != null && cameras!.isNotEmpty) {
        cameraController = CameraController(
          cameras!.first,
          ResolutionPreset.medium,
          enableAudio: true,
        );
        
        await cameraController!.initialize();
        
        if (!mounted) return;
        
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e'))
        );
      }
    }
  }
  
  void _toggleCameraView() {
    if (!_cameraEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enable camera in settings first'))
      );
      return;
    }
    
    if (!_isCameraInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera initializing, please wait...'))
      );
      _initializeCamera();
      return;
    }
    
    setState(() {
      _showCameraView = !_showCameraView;
    });
  }
  
  Future<void> _startVideoRecording() async {
    if (cameraController == null || !_isCameraInitialized) {
      return;
    }
    
    if (_isRecording) {
      return;
    }
    
    try {
      await cameraController!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
    } catch (e) {
      debugPrint('Error starting video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e'))
        );
      }
    }
  }
  
  Future<void> _stopVideoRecording() async {
    if (cameraController == null || !_isCameraInitialized || !_isRecording) {
      return;
    }
    
    _videoCaptured = false;
    String? localVideoPath;
    
    try {
      final video = await cameraController!.stopVideoRecording();
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final videoName = 'shot_$timestamp.mp4';
      final savedVideoPath = path.join(directory.path, videoName);
      
      await File(video.path).copy(savedVideoPath);
      
      _isRecording = false;
      localVideoPath = savedVideoPath;
      _videoCaptured = true;
    } catch (e) {
      debugPrint('Error stopping video recording: $e');
      _errorMessage = 'Failed to capture video: $e';
    }
    
    if (!mounted) return;
    
    setState(() {
      _isRecording = false;
      if (_videoCaptured) {
        _videoPath = localVideoPath;
        _showCameraView = false;
      }
    });
    
    if (_videoCaptured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video captured successfully!'))
      );
    } else if (_errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!))
      );
    }
  }
  
  Future<void> _addShot() async {
    _errorMessage = null;
    _shotRecorded = false;
    
    if (selectedZone.isEmpty || selectedType.isEmpty) {
      await DialogService.showInformation(
        context,
        title: 'Missing Data',
        message: 'Please select a zone and shot type',
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      if (!_sessionActive) {
        _sessionActive = true;
        _sessionStartTime = DateTime.now();
        _sessionShots = [];
      }
      
      final shotData = {
        'player_id': 1,
        'goal_x': selectedZone,
        'goal_y': '0',
        'type': selectedType,
        'success': selectedOutcome == 'Goal',
        'outcome': selectedOutcome,
        'date': DateTime.now(),
        'video_path': _videoPath,
        'session_id': _sessionStartTime?.millisecondsSinceEpoch.toString(),
      };
      
      if (_showAdvancedMetrics) {
        if (_powerController.text.isNotEmpty) {
          shotData['power'] = double.tryParse(_powerController.text);
        }
        
        if (_quickReleaseController.isUsed) {
          shotData['quick_release'] = _quickReleaseController.elapsedSeconds;
        }
        
        if (_distanceController.text.isNotEmpty) {
          shotData['distance'] = double.tryParse(_distanceController.text);
        }
        
        shotData['location_on_ice'] = _locationOnIce;
      }
      
      await Future.delayed(const Duration(milliseconds: 500));
      
      _sessionShots.add(shotData);
      shots.insert(0, shotData);
      
      _shotRecorded = true;
    } catch (e) {
      _errorMessage = 'Error recording shot: $e';
    }
    
    if (!mounted) return;
    
    setState(() {
      _isSaving = false;
      if (_shotRecorded) {
        selectedZone = '';
        selectedType = '';
        selectedOutcome = 'Goal';
        _videoPath = null;
        
        _powerController.clear();
        _quickReleaseController.reset();
        _distanceController.clear();
      }
    });
    
    if (_shotRecorded) {
      await DialogService.showSuccess(
        context,
        title: 'Success',
        message: 'Shot recorded successfully!',
        buttonLabel: 'Great',
      );
    } else if (_errorMessage != null) {
      await DialogService.showError(
        context,
        title: 'Error',
        message: _errorMessage!,
      );
    }
  }
  
  void _endSession() {
    if (_sessionShots.isEmpty) {
      DialogService.showInformation(
        context,
        title: 'Empty Session',
        message: 'No shots recorded in this session',
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ShotSessionReviewScreen(
          sessionShots: _sessionShots,
          sessionStartTime: _sessionStartTime!,
        ),
      ),
    ).then((_) {
      setState(() {
        _sessionActive = false;
        _sessionStartTime = null;
        _sessionShots = [];
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    
    return AdaptiveScaffold(
      title: 'Shot Input',
      backgroundColor: Colors.grey[100],
      actions: [
        _buildCameraToggle(),
        _buildAdvancedToggle(),
        if (_sessionActive) _buildSessionButton(),
      ],
      body: _showCameraView ? _buildCameraView() : AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 1400 : null,
            ),
            child: _buildShotInputContent(deviceType, isLandscape, dateFormat),
          );
        },
      ),
      floatingActionButton: _cameraEnabled && !_showCameraView ? 
        FloatingActionButton(
          onPressed: _toggleCameraView,
          backgroundColor: Colors.cyanAccent,
          foregroundColor: Colors.black87,
          tooltip: 'Record Shot Video',
          child: Icon(Icons.videocam),
        ) : null,
    );
  }

  Widget _buildCameraToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText('Camera', baseFontSize: 14, style: TextStyle(color: Colors.white)),
        Switch(
          value: _cameraEnabled,
          onChanged: _toggleCameraFeature,
          activeColor: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildAdvancedToggle() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText('Advanced', baseFontSize: 14, style: TextStyle(color: Colors.white)),
        Switch(
          value: _showAdvancedMetrics,
          onChanged: _toggleAdvancedMetrics,
          activeColor: Colors.cyanAccent,
        ),
      ],
    );
  }

  Widget _buildSessionButton() {
    return TextButton.icon(
      onPressed: _endSession,
      icon: const Icon(Icons.check_circle, color: Colors.white),
      label: ResponsiveText('End Session', baseFontSize: 14, style: TextStyle(color: Colors.white)),
    );
  }

  Widget _buildShotInputContent(DeviceType deviceType, bool isLandscape, DateFormat dateFormat) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        switch (deviceType) {
          case DeviceType.mobile:
            return _buildMobileLayout(dateFormat);
          case DeviceType.tablet:
            return _buildTabletLayout(dateFormat, isLandscape);
          case DeviceType.desktop:
            return _buildDesktopLayout(dateFormat);
        }
      },
    );
  }

  Widget _buildMobileLayout(DateFormat dateFormat) {
    return SingleChildScrollView(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_sessionActive) _buildSessionHeader(dateFormat),
          if (_videoPath != null) _buildVideoCapture(),
          ResponsiveText(
            'Record a Shot',
            baseFontSize: 24,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 2),
          _buildZoneSelector(),
          ResponsiveSpacing(multiplier: 2),
          _buildShotTypeSelector(),
          ResponsiveSpacing(multiplier: 2),
          _buildOutcomeSelector(),
          if (_showAdvancedMetrics) ...[
            ResponsiveSpacing(multiplier: 3),
            _buildAdvancedMetrics(),
          ],
          ResponsiveSpacing(multiplier: 3),
          _buildRecordButton(),
          ResponsiveSpacing(multiplier: 3),
          _buildRecentShotsList(dateFormat),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(DateFormat dateFormat, bool isLandscape) {
    if (!isLandscape) {
      return _buildMobileLayout(dateFormat);
    }

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sessionActive) _buildSessionHeader(dateFormat),
                if (_videoPath != null) _buildVideoCapture(),
                ResponsiveText(
                  'Record a Shot',
                  baseFontSize: 24,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                _buildZoneSelector(),
                ResponsiveSpacing(multiplier: 2),
                Row(
                  children: [
                    Expanded(child: _buildShotTypeSelector()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildOutcomeSelector()),
                  ],
                ),
                if (_showAdvancedMetrics) ...[
                  ResponsiveSpacing(multiplier: 3),
                  _buildAdvancedMetrics(),
                ],
                ResponsiveSpacing(multiplier: 3),
                _buildRecordButton(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildShotHistorySidebar(dateFormat),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(DateFormat dateFormat) {
    return Row(
      children: [
        Expanded(
          flex: 7,
          child: SingleChildScrollView(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_sessionActive) _buildSessionHeader(dateFormat),
                if (_videoPath != null) _buildVideoCapture(),
                ResponsiveText(
                  'Record a Shot',
                  baseFontSize: 24,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ResponsiveSpacing(multiplier: 2),
                _buildZoneSelector(),
                ResponsiveSpacing(multiplier: 2),
                Row(
                  children: [
                    Expanded(child: _buildShotTypeSelector()),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(child: _buildOutcomeSelector()),
                  ],
                ),
                if (_showAdvancedMetrics) ...[
                  ResponsiveSpacing(multiplier: 3),
                  _buildAdvancedMetrics(),
                ],
                ResponsiveSpacing(multiplier: 3),
                _buildRecordButton(),
              ],
            ),
          ),
        ),
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border(left: BorderSide(color: Colors.grey[300]!)),
          ),
          child: _buildShotHistorySidebar(dateFormat),
        ),
      ],
    );
  }

  Widget _buildSessionHeader(DateFormat dateFormat) {
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      backgroundColor: Colors.green.withOpacity(0.1),
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 12),
        child: Row(
          children: [
            Icon(Icons.timer, color: Colors.green, size: ResponsiveConfig.iconSize(context, 24)),
            ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    'Session Active',
                    baseFontSize: 16,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  ResponsiveText(
                    '${_sessionShots.length} shots recorded - started at ${dateFormat.format(_sessionStartTime!)}',
                    baseFontSize: 12,
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
            ResponsiveButton(
              text: 'End & Review',
              onPressed: _endSession,
              baseHeight: 36,
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoCapture() {
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 8),
      child: Padding(
        padding: ResponsiveConfig.paddingAll(context, 12),
        child: Row(
          children: [
            Container(
              width: ResponsiveConfig.dimension(context, 48),
              height: ResponsiveConfig.dimension(context, 48),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(52),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.video_library, color: Colors.green, size: ResponsiveConfig.iconSize(context, 24)),
            ),
            ResponsiveSpacing(multiplier: 1.5, direction: Axis.horizontal),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ResponsiveText(
                    'Video Captured',
                    baseFontSize: 16,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ResponsiveText(
                    'This video will be attached to your shot record',
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: ResponsiveConfig.iconSize(context, 20)),
              onPressed: () {
                setState(() {
                  _videoPath = null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Select Zone',
          baseFontSize: 18,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1),
        Container(
          width: ResponsiveConfig.dimension(context, 300),
          height: ResponsiveConfig.dimension(context, 300),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GridSelector<String>(
            options: zones,
            selectedOption: selectedZone.isEmpty ? null : selectedZone,
            onSelected: (zone) {
              setState(() {
                selectedZone = zone;
              });
            },
            labelBuilder: (zone) => zone,
            sublabelBuilder: (zone) => zoneLabels[zone] ?? '',
            crossAxisCount: 3,
            selectedColor: Colors.cyanAccent,
            unselectedColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildShotTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Shot Type',
          baseFontSize: 18,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1),
        FilterChipGroup<String>(
          options: shotTypes,
          selectedOptions: selectedType.isEmpty ? [] : [selectedType],
          onSelected: (type, selected) {
            if (selected) {
              setState(() => selectedType = type);
            }
          },
          labelBuilder: (type) => type,
          selectedColor: Colors.cyanAccent,
          backgroundColor: Colors.white,
        ),
      ],
    );
  }

  Widget _buildOutcomeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Outcome',
          baseFontSize: 18,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 1),
        ToggleButtonGroup<String>(
          options: const ['Goal', 'Miss', 'Save'],
          selectedOption: selectedOutcome,
          onSelected: (outcome) {
            setState(() => selectedOutcome = outcome);
          },
          colorMap: {
            'Goal': Colors.green,
            'Miss': Colors.red,
            'Save': Colors.orange,
          },
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }

  Widget _buildAdvancedMetrics() {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      backgroundColor: Colors.blueGrey.withOpacity(0.1),
      border: Border.all(color: Colors.blueGrey.withOpacity(0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ResponsiveText(
            'Advanced Metrics',
            baseFontSize: 18,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ResponsiveSpacing(multiplier: 2),
          StandardTextField(
            controller: _powerController,
            labelText: 'Shot Power (mph)',
            prefixIcon: Icons.speed,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: ValidationHelper.numberRange(0, 150, 'Please enter a valid shot power'),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ResponsiveText(
                'Quick Release Timer',
                baseFontSize: 16,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[700],
                ),
              ),
              ResponsiveSpacing(multiplier: 1),
              UnifiedTimer(
                controller: _quickReleaseController,
                displayStyle: TimerDisplayStyle.compact,
                primaryColor: Colors.purple,
                onTimeRecorded: (timeInSeconds) {
                  setState(() {});
                },
              ),
            ],
          ),
          ResponsiveSpacing(multiplier: 1.5),
          StandardTextField(
            controller: _distanceController,
            labelText: 'Distance from Goal (feet)',
            prefixIcon: Icons.straighten,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            validator: ValidationHelper.numberRange(0, 200, 'Please enter a valid distance'),
          ),
          ResponsiveSpacing(multiplier: 1.5),
          StandardDropdown<String>(
            value: _locationOnIce,
            labelText: 'Location on Ice',
            prefixIcon: Icons.location_on,
            items: _iceLocations.map((location) {
              return DropdownMenuItem<String>(
                value: location,
                child: ResponsiveText(location, baseFontSize: 16),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _locationOnIce = value);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton() {
    return ResponsiveButton(
      text: _isSaving ? 'Saving...' : 'Record Shot',
      onPressed: _isSaving ? null : _addShot,
      baseHeight: 50,
      width: double.infinity,
      backgroundColor: Colors.cyanAccent,
      foregroundColor: Colors.black,
      icon: _isSaving ? null : Icons.add_circle,
      prefix: _isSaving // FIXED: Changed from suffix to prefix
        ? SizedBox(
            width: ResponsiveConfig.dimension(context, 20),
            height: ResponsiveConfig.dimension(context, 20),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.black54,
            ),
          )
        : null,
    );
  }

  Widget _buildRecentShotsList(DateFormat dateFormat) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResponsiveText(
          'Recent Shots',
          baseFontSize: 20,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ResponsiveSpacing(multiplier: 2),
        shots.isEmpty
          ? EmptyStateDisplay(
              title: 'No shots recorded yet',
              description: 'Record your first shot to get started',
              icon: Icons.sports_hockey,
              iconColor: Colors.blueGrey[200],
              animate: true,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: shots.take(5).map((shot) => _buildShotListItem(shot, dateFormat)).toList(),
            ),
      ],
    );
  }

  Widget _buildShotHistorySidebar(DateFormat dateFormat) {
    return Column(
      children: [
        Padding(
          padding: ResponsiveConfig.paddingAll(context, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ResponsiveText(
                'Recent Shots',
                baseFontSize: 20,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_sessionActive)
                ResponsiveText(
                  'Session: ${_sessionShots.length} shots',
                  baseFontSize: 14,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: shots.isEmpty
            ? EmptyStateDisplay(
                title: 'No shots recorded yet',
                description: 'Record your first shot to get started',
                icon: Icons.sports_hockey,
                iconColor: Colors.blueGrey[200],
                animate: true,
              )
            : ListView.builder(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16),
                itemCount: shots.length,
                itemBuilder: (context, index) {
                  final shot = shots[index];
                  return _buildShotListItem(shot, dateFormat);
                },
              ),
        ),
        if (shots.isNotEmpty)
          Padding(
            padding: ResponsiveConfig.paddingAll(context, 16),
            child: ResponsiveButton(
              text: 'View All History',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ShotSessionReviewScreen(
                      sessionShots: shots,
                      sessionStartTime: DateTime.now(),
                      isHistoryView: true,
                    ),
                  ),
                );
              },
              baseHeight: 48,
              width: double.infinity,
              backgroundColor: Colors.blueGrey[700],
              foregroundColor: Colors.white,
              icon: Icons.history,
            ),
          ),
      ],
    );
  }

  Widget _buildShotListItem(Map<String, dynamic> shot, DateFormat dateFormat) {
    final zoneLabel = zoneLabels[shot['goal_x']] ?? 'Unknown';
    
    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 4),
      baseBorderRadius: 8,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: shot['success']
            ? Colors.green
            : shot['outcome'] == 'Miss'
              ? Colors.red
              : Colors.orange,
          child: Icon(
            shot['success']
              ? Icons.check
              : shot['outcome'] == 'Miss'
                ? Icons.close
                : Icons.shield,
            color: Colors.white,
            size: ResponsiveConfig.iconSize(context, 20),
          ),
        ),
        title: ResponsiveText(
          '${shot['type']} - $zoneLabel',
          baseFontSize: 16,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ResponsiveText(
              dateFormat.format(shot['date']),
              baseFontSize: 14,
            ),
            if (shot['power'] != null || shot['quick_release'] != null) 
              ResponsiveText(
                _buildMetricsString(shot),
                baseFontSize: 11,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: shot['video_path'] != null
          ? IconButton(
              icon: Icon(Icons.play_circle, color: Colors.blue, size: ResponsiveConfig.iconSize(context, 24)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video playback to be implemented'))
                );
              },
            )
          : null,
        isThreeLine: shot['power'] != null || shot['quick_release'] != null,
      ),
    );
  }

  Widget _buildCameraView() {
    if (!_isCameraInitialized || cameraController == null) {
      return LoadingOverlay.simple(
        message: 'Initializing camera...',
        color: Colors.cyanAccent,
      );
    }
    
    return Stack(
      children: [
        Center(
          child: CameraPreview(cameraController!),
        ),
        
        if (_isRecording)
          Positioned(
            top: ResponsiveConfig.dimension(context, 16),
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: ResponsiveConfig.paddingSymmetric(context, horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, color: Colors.white, size: ResponsiveConfig.iconSize(context, 12)),
                    ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
                    ResponsiveText(
                      'RECORDING',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black.withOpacity(0.5),
            padding: ResponsiveConfig.paddingSymmetric(context, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.white, size: ResponsiveConfig.iconSize(context, 28)),
                  onPressed: () {
                    if (_isRecording) {
                      _stopVideoRecording();
                    } else {
                      setState(() {
                        _showCameraView = false;
                      });
                    }
                  },
                ),
                
                GestureDetector(
                  onTap: _isRecording ? _stopVideoRecording : _startVideoRecording,
                  child: Container(
                    height: ResponsiveConfig.dimension(context, 72),
                    width: ResponsiveConfig.dimension(context, 72),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      color: _isRecording ? Colors.red : Colors.transparent,
                    ),
                    child: _isRecording 
                      ? Icon(Icons.stop, color: Colors.white, size: ResponsiveConfig.iconSize(context, 32))
                      : Container(),
                  ),
                ),
                
                SizedBox(width: ResponsiveConfig.dimension(context, 48)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _buildMetricsString(Map<String, dynamic> shot) {
    final metrics = <String>[];
    
    if (shot['power'] != null) {
      metrics.add('${shot['power']} mph');
    }
    
    if (shot['quick_release'] != null) {
      metrics.add('${shot['quick_release']} sec');
    }
    
    if (shot['location_on_ice'] != null) {
      metrics.add('From: ${shot['location_on_ice']}');
    }
    
    return metrics.join(' | ');
  }
}

// Keep the existing ShotSessionReviewScreen class as-is for now
// This would need similar responsive refactoring if time permits
class ShotSessionReviewScreen extends StatefulWidget {
  final List<Map<String, dynamic>> sessionShots;
  final DateTime sessionStartTime;
  final bool isHistoryView;
  
  const ShotSessionReviewScreen({
    Key? key,
    required this.sessionShots,
    required this.sessionStartTime,
    this.isHistoryView = false,
  }) : super(key: key);

  @override
  State<ShotSessionReviewScreen> createState() => _ShotSessionReviewScreenState();
}

class _ShotSessionReviewScreenState extends State<ShotSessionReviewScreen> {
  List<Map<String, dynamic>> _shots = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  int _totalShots = 0;
  double _successRate = 0.0;
  Map<String, int> _shotTypeDistribution = {};
  Map<String, int> _zoneDistribution = {};
  
  final Map<String, String> _zoneLabels = {
    '1': 'Top Left', '2': 'Top Center', '3': 'Top Right',
    '4': 'Mid Left', '5': 'Mid Center', '6': 'Mid Right',
    '7': 'Bottom Left', '8': 'Bottom Center', '9': 'Bottom Right',
  };
  
  final TextEditingController _powerController = TextEditingController();
  final UnifiedTimerController _quickReleaseController = UnifiedTimerController();
  final TextEditingController _distanceController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _shots = List.from(widget.sessionShots);
    _calculateStatistics();
  }
  
  @override
  void dispose() {
    _powerController.dispose();
    _quickReleaseController.dispose();
    _distanceController.dispose();
    super.dispose();
  }
  
  void _calculateStatistics() {
    if (_shots.isEmpty) return;
    
    _totalShots = _shots.length;
    final successfulShots = _shots.where((shot) => shot['success'] == true).length;
    _successRate = successfulShots / _totalShots;
    
    _shotTypeDistribution = {};
    for (final shot in _shots) {
      final type = shot['type'] as String;
      _shotTypeDistribution[type] = (_shotTypeDistribution[type] ?? 0) + 1;
    }
    
    _zoneDistribution = {};
    for (final shot in _shots) {
      final zone = shot['goal_x'] as String;
      _zoneDistribution[zone] = (_zoneDistribution[zone] ?? 0) + 1;
    }
  }
  
  void _showEditDialog(int index) {
    final shot = _shots[index];
    
    _powerController.text = shot['power']?.toString() ?? '';
    if (shot['quick_release'] != null) {
      _quickReleaseController.setTime(Duration(milliseconds: (shot['quick_release'] * 1000).round()));
    } else {
      _quickReleaseController.reset();
    }
    _distanceController.text = shot['distance']?.toString() ?? '';
    
    DialogService.showCustom<void>(
      context,
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Shot Metrics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey[800],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${shot['type']} Shot - Zone ${shot['goal_x']} (${_zoneLabels[shot['goal_x']]}) - ${shot['success'] ? 'Goal' : shot['outcome']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            StandardTextField(
              controller: _powerController,
              labelText: 'Shot Power (mph)',
              prefixIcon: Icons.speed,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: 12),
            
            StandardTextField(
              controller: _distanceController,
              labelText: 'Distance from Goal (feet)',
              prefixIcon: Icons.straighten,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            
            const SizedBox(height: 20),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _updateShotMetrics(index);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  void _updateShotMetrics(int index) {
    if (index < 0 || index >= _shots.length) return;
    
    setState(() {
      final shot = Map<String, dynamic>.from(_shots[index]);
      
      if (_powerController.text.isNotEmpty) {
        shot['power'] = double.tryParse(_powerController.text);
      } else {
        shot.remove('power');
      }
      
      if (_quickReleaseController.isUsed) {
        shot['quick_release'] = _quickReleaseController.elapsedSeconds;
      } else {
        shot.remove('quick_release');
      }
      
      if (_distanceController.text.isNotEmpty) {
        shot['distance'] = double.tryParse(_distanceController.text);
      } else {
        shot.remove('distance');
      }
      
      _shots[index] = shot;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Shot metrics updated successfully')),
    );
  }
  
  Future<void> _saveSession() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      
      Navigator.pop(context);
      
      await DialogService.showSuccess(
        context,
        title: 'Session Saved',
        message: 'Session saved successfully',
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving session: $e';
        _isLoading = false;
      });
      
      await DialogService.showError(
        context,
        title: 'Error',
        message: _errorMessage!,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMMM d, yyyy - h:mm a');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isHistoryView ? 'Shot History' : 'Session Review',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          if (!widget.isHistoryView)
            TextButton.icon(
              onPressed: _isLoading ? null : _saveSession,
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                'Save Session',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _shots.isEmpty
              ? _buildEmptyState()
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.isHistoryView ? 'All Shots' : 'Session Shots',
                                  style: Theme.of(context).textTheme.headlineSmall,
                                ),
                                Text(
                                  'Started: ${dateFormat.format(widget.sessionStartTime)}',
                                  style: TextStyle(
                                    color: Colors.blueGrey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                              itemCount: _shots.length,
                              itemBuilder: (context, index) {
                                final shot = _shots[index];
                                final zoneLabel = _zoneLabels[shot['goal_x']] ?? 'Unknown';
                                final date = shot['date'] as DateTime;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: shot['success']
                                        ? Colors.green
                                        : shot['outcome'] == 'Miss'
                                          ? Colors.red
                                          : Colors.orange,
                                      child: Icon(
                                        shot['success']
                                          ? Icons.check
                                          : shot['outcome'] == 'Miss'
                                            ? Icons.close
                                            : Icons.shield,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      '${shot['type']} - $zoneLabel',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(DateFormat('h:mm:ss a').format(date)),
                                        _buildMetricsRow(shot),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (shot['video_path'] != null)
                                          IconButton(
                                            icon: const Icon(Icons.play_circle, color: Colors.blue),
                                            onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Video playback to be implemented'))
                                              );
                                            },
                                            tooltip: 'Play Video',
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueGrey),
                                          onPressed: () => _showEditDialog(index),
                                          tooltip: 'Edit Metrics',
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.withOpacity(0.05),
                          border: Border(
                            left: BorderSide(
                              color: Colors.blueGrey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Session Statistics',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 24),
                              
                              _buildStatCard(
                                'Total Shots',
                                _totalShots.toString(),
                                Icons.sports_hockey,
                                Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              _buildStatCard(
                                'Success Rate',
                                '${(_successRate * 100).toStringAsFixed(1)}%',
                                Icons.check_circle,
                                _successRate >= 0.7 ? Colors.green : _successRate >= 0.4 ? Colors.orange : Colors.red,
                              ),
                              const SizedBox(height: 24),
                              
                              Text(
                                'Shot Types',
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._shotTypeDistribution.entries.map((entry) {
                                final percentage = (entry.value / _totalShots * 100).toStringAsFixed(1);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(entry.key),
                                          Text('$percentage% (${entry.value})'),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      LinearProgressIndicator(
                                        value: entry.value / _totalShots,
                                        backgroundColor: Colors.grey[200],
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                        minHeight: 8,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              
                              const SizedBox(height: 24),
                              
                              Text(
                                'Target Zones',
                                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: _buildZoneHeatmap(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildEmptyState() {
    return EmptyStateDisplay(
      title: 'No shots in this session',
      description: 'Go back and record some shots',
      icon: Icons.sports_hockey,
      primaryActionLabel: 'Back',
      onPrimaryAction: () => Navigator.pop(context),
      animate: true,
    );
  }
  
  Widget _buildMetricsRow(Map<String, dynamic> shot) {
    final metrics = <Widget>[];
    
    if (shot['power'] != null) {
      metrics.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed, size: 12, color: Colors.blue),
            const SizedBox(width: 2),
            Text('${shot['power']} mph', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (shot['quick_release'] != null) {
      metrics.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, size: 12, color: Colors.purple),
            const SizedBox(width: 2),
            Text('${shot['quick_release']} sec', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (shot['distance'] != null) {
      metrics.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.straighten, size: 12, color: Colors.orange),
            const SizedBox(width: 2),
            Text('${shot['distance']} ft', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (shot['location_on_ice'] != null) {
      metrics.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.location_on, size: 12, color: Colors.green),
            const SizedBox(width: 2),
            Text(shot['location_on_ice'], style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }
    
    if (metrics.isEmpty) {
      return const Text(
        'No advanced metrics',
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Colors.grey,
        ),
      );
    }
    
    return Wrap(
      spacing: 8,
      children: metrics,
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey[800],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildZoneHeatmap() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneHeatmapCell('1'),
            _buildZoneHeatmapCell('2'),
            _buildZoneHeatmapCell('3'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneHeatmapCell('4'),
            _buildZoneHeatmapCell('5'),
            _buildZoneHeatmapCell('6'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildZoneHeatmapCell('7'),
            _buildZoneHeatmapCell('8'),
            _buildZoneHeatmapCell('9'),
          ],
        ),
      ],
    );
  }
  
  Widget _buildZoneHeatmapCell(String zone) {
    final count = _zoneDistribution[zone] ?? 0;
    final intensity = count / (_totalShots > 0 ? _totalShots : 1);
    
    final color = count > 0
        ? Color.lerp(Colors.blue[50], Colors.blue[800], intensity.clamp(0.2, 0.9))!
        : Colors.grey[200]!;
        
    return SizedBox(
      width: 60,
      height: 60,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          border: Border.all(
            color: Colors.grey[400]!,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                zone,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? Colors.white : Colors.grey[600],
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: count > 0 ? Colors.white : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}