import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Remove direct import of url_launcher
// import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Add Riverpod import

import '../services/url_launcher_service.dart'; // Import the new service

/// Helper class for handling URLs
class UrlHelper {
  // Modify to accept WidgetRef
  static Future<bool> launchUrl(
    String url, {
    required WidgetRef ref,
    BuildContext? context,
  }) async {
    if (kDebugMode) {
      print('[URL Helper] Launching URL: $url');
    }

    // Get the service instance from the provider
    final launcherService = ref.read(urlLauncherServiceProvider);

    // Delegate the launch call to the service
    final success = await launcherService.launch(url);

    // Handle failure feedback (optional, could also be handled by caller)
    if (!success && context != null && context.mounted) {
      if (kDebugMode) {
        print('[URL Helper] Launch failed for $url, showing Snackbar');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open link: $url'),
          action: SnackBarAction(
            label: 'Copy URL',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              }
            },
          ),
        ),
      );
    } else if (success && kDebugMode) {
      print('[URL Helper] Launch successful for $url');
    }

    return success;
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
      'drafts', // Drafts app scheme
      'things',
      'omnifocus',
      'bear',
      'notion',
      'obsidian',
      'tweetbot',
      'twitterrific',
      'mastodon',
      'testflight',
      'shortcuts',
      'workflow',
      'dropbox',
      'evernote',
      'onenote',
      'pocket',
      'overcast',
      'castro',
      'pcast',
    ];

    // More advanced scheme detection and logging
    final isCustom =
        customSchemes.contains(scheme.toLowerCase()) ||
        scheme.contains(
          '.',
        ) || // Often used in reverse-domain notation (com.example.app)
        scheme.length >= 3; // Most custom schemes are at least 3 chars

    if (kDebugMode) {
      if (isCustom) {
        print('[URL] Identified scheme "$scheme" as a custom app scheme');

        if (customSchemes.contains(scheme.toLowerCase())) {
          print('[URL] Matched "$scheme" in known app schemes list');
        } else if (scheme.contains('.')) {
          print('[URL] Detected "$scheme" as likely reverse-domain format');
        }
      } else {
        print('[URL] Scheme "$scheme" not identified as a custom app scheme');
      }
    }

    return isCustom;
  }
}
