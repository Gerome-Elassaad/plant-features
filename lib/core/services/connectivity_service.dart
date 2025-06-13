import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  static final ConnectivityService instance = ConnectivityService._internal();
  factory ConnectivityService() => instance;
  ConnectivityService._internal();
  
  final Connectivity _connectivity = Connectivity();
  final StreamController<ConnectivityResult> _connectivityController = 
      StreamController<ConnectivityResult>.broadcast();
  
  Stream<ConnectivityResult> get connectivityStream => _connectivityController.stream;
  ConnectivityResult? _currentStatus;
  ConnectivityResult? get currentStatus => _currentStatus;
  
  bool get isConnected => 
      _currentStatus != null && _currentStatus != ConnectivityResult.none;
  
  void init() {
    // Check initial connectivity
    checkConnectivity();
    
    // Listen to connectivity changes
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      _currentStatus = result;
      _connectivityController.add(result);
    });
  }
  
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _currentStatus = result;
      _connectivityController.add(result);
      return result != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }
  
  void dispose() {
    _connectivityController.close();
  }
}