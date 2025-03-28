import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class UrlHelper {
  /// Launch URL in browser or handle custom schemes
  static Future<bool> launchUrl(String url, {BuildContext? context}) async {
    if (kDebugMode) {
      print('[URL] Launching URL: $url');
    }
    
    // Check if it's a valid URL
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (kDebugMode) {
        print('[URL] Invalid URL: $url');
      }
      return false;
    }
    
    // Enhanced debug info
    if (kDebugMode) {
      print(
        '[URL] Scheme: ${uri.scheme}, Path: ${uri.path}, Query: ${uri.query}',
      );
      print('[URL] Fragment: ${uri.fragment}, Authority: ${uri.authority}');
    }
    
    // Handle different URL schemes
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      return await url_launcher.launchUrl(
        uri,
        mode: url_launcher.LaunchMode.externalApplication,
      );
    } else if (uri.scheme == 'memo') {
      // Handle internal memo links, e.g., memo://123 to open memo with ID 123
      if (kDebugMode) {
        print('[URL] Handling internal memo link: $url');
      }
      // Implement custom routing logic here
      return true;
    }
    // Handle app URL schemes
    else if (uri.scheme.startsWith('app') ||
        uri.scheme == 'tel' ||
        uri.scheme == 'sms' ||
        uri.scheme == 'mailto' ||
        _isCustomAppScheme(uri.scheme)) {
      if (kDebugMode) {
        print('[URL] Handling app URL scheme: ${uri.scheme}');
      }

      try {
        // Try to launch the app URL
        final canLaunch = await url_launcher.canLaunchUrl(uri);
        if (kDebugMode) {
          print('[URL] Can launch: $canLaunch');
        }
        if (canLaunch) {
          return await url_launcher.launchUrl(uri);
        } else {
          // Show a snackbar if the URL can't be launched and we have context
          if (context != null) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Cannot open: $url')));
          }
          if (kDebugMode) {
            print('[URL] Cannot launch URL: $url');
          }
          return false;
        }
      } catch (e) {
        if (kDebugMode) {
          print('[URL] Error launching URL $url: $e');
        }
        return false;
      }
    }

    // Try to launch other schemes
    try {
      if (kDebugMode) {
        print('[URL] Attempting to launch URL with scheme: ${uri.scheme}');
      }
      return await url_launcher.launchUrl(uri);
    } catch (e) {
      if (kDebugMode) {
        print('[URL] Error launching URL $url: $e');
      }
      return false;
    }
  }

  /// Check if a scheme appears to be a custom app scheme
  static bool _isCustomAppScheme(String scheme) {
    // List of common custom app schemes
    final customSchemes = [
      'fb',
      'twitter',
      'instagram',
      'snapchat',
      'whatsapp',
      'telegram',
      'spotify',
      'youtube',
      'netflix',
      'maps',
      'uber',
      'lyft',
      'paypal',
      'venmo',
      'cashapp',
      'zelle',
      'drafts', // Added drafts scheme
      'things',
      'omnifocus',
      'bear',
      'notion',
      'obsidian'
    ];

    // Check if the scheme is in our list or follows common patterns
    final isCustom =
        customSchemes.contains(scheme.toLowerCase()) ||
        scheme.contains(
          '.',
        ) || // Often used in reverse-domain notation (com.example.app)
        scheme.length >= 3; // Most custom schemes are at least 3 chars

    if (kDebugMode && isCustom) {
      print('[URL] Identified custom app scheme: $scheme');
    }

    return isCustom;
  }
}
