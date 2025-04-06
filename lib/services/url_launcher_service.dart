import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Service wrapper for URL launcher functionality to facilitate testing.
class UrlLauncherService {
  /// Launches the given URL string.
  /// Returns true if launching was successful, false otherwise.
  Future<bool> launch(String urlString) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (kDebugMode) {
        print('[UrlLauncherService] Invalid URL: $urlString');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('[UrlLauncherService] Attempting to launch URL: $uri');
      }
      // Use canLaunchUrl for better pre-check, though launchUrl also handles it
      if (await url_launcher.canLaunchUrl(uri)) {
        final success = await url_launcher.launchUrl(
          uri,
          // Prefer external application for http/https links
          mode:
              (uri.scheme == 'http' || uri.scheme == 'https')
                  ? url_launcher.LaunchMode.externalApplication
                  : url_launcher.LaunchMode.platformDefault,
        );
        if (kDebugMode) {
          print('[UrlLauncherService] Launch success: $success for $uri');
        }
        return success;
      } else {
        if (kDebugMode) {
          print('[UrlLauncherService] Cannot launch URL: $uri');
        }
        return false;
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('[UrlLauncherService] Error launching URL $uri: $e\n$s');
      }
      return false;
    }
  }
}

/// Provider for the URL launcher service.
final urlLauncherServiceProvider = Provider<UrlLauncherService>((ref) {
  return UrlLauncherService();
});
