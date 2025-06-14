import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectivityController =
      StreamController<ConnectivityResult>.broadcast();

  Stream<ConnectivityResult> get connectivityStream =>
      _connectivityController.stream;
  ConnectivityResult _currentStatus = ConnectivityResult.none; // Initialize with a default
  ConnectivityResult get currentStatus => _currentStatus;

  bool get isConnected => _currentStatus != ConnectivityResult.none;

  // Helper to determine a single status from a list
  ConnectivityResult _getStatusFromResult(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.ethernet)) {
      return ConnectivityResult.ethernet;
    }
    if (results.contains(ConnectivityResult.wifi)) {
      return ConnectivityResult.wifi;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return ConnectivityResult.mobile;
    }
    if (results.contains(ConnectivityResult.vpn)) {
      return ConnectivityResult.vpn;
    }
    if (results.contains(ConnectivityResult.bluetooth)) {
      return ConnectivityResult.bluetooth;
    }
    // If 'other' is present and no primary types, use 'other'
    if (results.contains(ConnectivityResult.other) && results.every((r) => r == ConnectivityResult.other || r == ConnectivityResult.none)) {
      return ConnectivityResult.other;
    }
    return ConnectivityResult.none;
  }

  void init() {
    // Check initial connectivity
    checkConnectivity();

    // Listen to connectivity changes
    _connectivity.onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      _currentStatus = _getStatusFromResult(results);
      _connectivityController.add(_currentStatus);
    });
  }

  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _currentStatus = _getStatusFromResult(results);
      _connectivityController.add(_currentStatus);
      return _currentStatus != ConnectivityResult.none;
    } catch (e) {
      // In case of error, assume no connectivity and report it
      _currentStatus = ConnectivityResult.none;
      _connectivityController.add(_currentStatus);
      return false;
    }
  }
  
  void dispose() {
    _connectivityController.close();
  }
}
