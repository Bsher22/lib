import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectivityStream => _controller.stream;

  void initialize() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _controller.add(result);
    });
  }

  Future<ConnectivityResult> checkConnectivity() async {
    return await _connectivity.checkConnectivity();
  }

  Future<bool> isConnected() async {
    final result = await checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void dispose() {
    _controller.close();
  }
}