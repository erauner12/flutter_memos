import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier for managing server configuration with persistence
class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  ServerConfigNotifier() : super(ServerConfig.defaultConfig);

  /// Load configuration from SharedPreferences
  Future<void> loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final serverUrl = prefs.getString('server_url') ?? 'http://localhost:5230';
      final authToken = prefs.getString('auth_token') ?? '';
      
      state = ServerConfig(
        serverUrl: serverUrl,
        authToken: authToken,
      );
      
      if (kDebugMode) {
        print('[ServerConfigNotifier] Loaded config: serverUrl=$serverUrl, token=${authToken.isNotEmpty ? "present" : "empty"}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[ServerConfigNotifier] Error loading config: $e');
      }
      // Keep the default configuration
    }
  }

  /// Save configuration to SharedPreferences
  Future<bool> saveToPreferences(ServerConfig config) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final results = await Future.wait([
        prefs.setString('server_url', config.serverUrl),
        prefs.setString('auth_token', config.authToken),
      ]);
      
      // Update state with new configuration
      state = config;
      
      if (kDebugMode) {
        print('[ServerConfigNotifier] Saved config: serverUrl=${config.serverUrl}, token=${config.authToken.isNotEmpty ? "present" : "empty"}');
      }
      
      // Return true if all operations succeeded
      return results.every((result) => result);
    } catch (e) {
      if (kDebugMode) {
        print('[ServerConfigNotifier] Error saving config: $e');
      }
      return false;
    }
  }
  
  /// Update server URL only
  Future<bool> updateServerUrl(String url) async {
    return saveToPreferences(state.copyWith(serverUrl: url));
  }
  
  /// Update auth token only
  Future<bool> updateAuthToken(String token) async {
    return saveToPreferences(state.copyWith(authToken: token));
  }
}

/// Provider for server configuration
final serverConfigProvider = StateNotifierProvider<ServerConfigNotifier, ServerConfig>((ref) {
  return ServerConfigNotifier();
}, name: 'serverConfig');

/// Provider for loading server configuration on app startup
final loadServerConfigProvider = FutureProvider<bool>((ref) async {
  await ref.read(serverConfigProvider.notifier).loadFromPreferences();
  return true;
}, name: 'loadServerConfig');
