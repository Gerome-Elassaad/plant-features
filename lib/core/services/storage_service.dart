import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static final StorageService instance = StorageService._internal();
  factory StorageService() => instance;
  StorageService._internal();
  
  late SharedPreferences _prefs;
  late FlutterSecureStorage _secureStorage;
  
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _secureStorage = const FlutterSecureStorage();
  }
  
  // Regular storage (SharedPreferences)
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }
  
  Future<String?> getString(String key) async {
    return _prefs.getString(key);
  }
  
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }
  
  Future<bool?> getBool(String key) async {
    return _prefs.getBool(key);
  }
  
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }
  
  Future<int?> getInt(String key) async {
    return _prefs.getInt(key);
  }
  
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }
  
  Future<double?> getDouble(String key) async {
    return _prefs.getDouble(key);
  }
  
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }
  
  Future<List<String>?> getStringList(String key) async {
    return _prefs.getStringList(key);
  }
  
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }
  
  Future<bool> clear() async {
    return await _prefs.clear();
  }
  
  // Secure storage
  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }
  
  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }
  
  Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }
  
  Future<void> deleteAllSecure() async {
    await _secureStorage.deleteAll();
  }
  
  // Helper methods
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }
  
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}