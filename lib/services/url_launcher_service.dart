import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Service wrapper for URL launcher functionality
class UrlLauncherService {
  /// Launch a URL and return whether the operation was successful
  Future<bool> launch(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      
      if (kDebugMode) {
        print('[UrlLauncherService] Attempting to launch URL: $urlString');
      }
      
      // Try to launch the URL using url_launcher
      final canLaunch = await url_launcher.canLaunchUrl(url);
      
      if (canLaunch) {
        return await url_launcher.launchUrl(
          url,
          mode: url_launcher.LaunchMode.platformDefault,
        );
      } else {
        if (kDebugMode) {
          print('[UrlLauncherService] Cannot launch URL: $urlString');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[UrlLauncherService] Error launching URL: $e');
      }
      return false;
    }
  }
}

/// Provider for the URL launcher service
final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return UrlLauncherService();
});
