// ignore_for_file: empty_catches

import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

class ShotCameraController {
  // Camera properties
  List<CameraDescription>? cameras;
  CameraController? controller;
  bool isInitialized = false;
  bool isRecording = false;
  
  // Feature toggle
  bool _cameraEnabled = false;
  bool get cameraEnabled => _cameraEnabled;
  
  // Singleton pattern
  static final ShotCameraController _instance = ShotCameraController._internal();
  factory ShotCameraController() => _instance;
  ShotCameraController._internal();
  
  Future<void> initialize() async {
    await _loadCameraPreference();
    if (_cameraEnabled) {
      await _initializeCamera();
    }
  }
  
  Future<void> _loadCameraPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _cameraEnabled = prefs.getBool('camera_enabled') ?? false;
  }
  
  Future<void> setCameraEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('camera_enabled', value);
    _cameraEnabled = value;
    
    if (value && !isInitialized) {
      await _initializeCamera();
    } else if (!value && isInitialized) {
      await disposeCamera();
    }
  }
  
  Future<void> _initializeCamera() async {
    if (!_cameraEnabled) return;
    
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        return;
      }
      
      controller = CameraController(
        cameras!.first,
        ResolutionPreset.high,
        enableAudio: true,
      );
      
      await controller!.initialize();
      isInitialized = true;
    } catch (e) {
    }
  }
  
  Future<void> disposeCamera() async {
    if (controller != null) {
      await controller!.dispose();
      controller = null;
      isInitialized = false;
    }
  }
  
  Future<String?> recordVideo() async {
    if (!isInitialized || controller == null) {
      return null;
    }
    
    if (isRecording) {
      return null;
    }
    
    try {
      await controller!.startVideoRecording();
      isRecording = true;
      return null;
    } catch (e) {
      return null;
    }
  }
  
  Future<String?> stopRecording() async {
    if (!isInitialized || controller == null || !isRecording) {
      return null;
    }
    
    try {
      final video = await controller!.stopVideoRecording();
      isRecording = false;
      
      // Save video to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final videoName = 'shot_$timestamp.mp4';
      final savedVideoPath = path.join(directory.path, videoName);
      
      await File(video.path).copy(savedVideoPath);
      return savedVideoPath;
    } catch (e) {
      return null;
    }
  }
}