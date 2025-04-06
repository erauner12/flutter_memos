import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

/// Helper class for handling URLs
class UrlHelper {
  /// Launch a URL and return whether the operation was successful
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
        // For macOS and custom schemes, use platformBrowserLaunch which has better
        // support for handling custom URL schemes on desktop platforms
        if (Platform.isMacOS && _isCustomAppScheme(uri.scheme)) {
          if (kDebugMode) {
            print('[URL] Using platform-specific launch for macOS: $url');
          }

          // Try to launch with universal_links first, which has better macOS support
          return await url_launcher.launchUrl(
            uri,
            mode: url_launcher.LaunchMode.externalApplication,
          );
        }

        // For other platforms or schemes, try standard launch
        final canLaunch = await url_launcher.canLaunchUrl(uri);
        if (kDebugMode) {
          print('[URL] Can launch: $canLaunch');
        }
        
        if (canLaunch) {
          return await url_launcher.launchUrl(
            uri,
            mode:
                url_launcher
                    .LaunchMode
                    .externalApplication, // Changed from default to ensure external app launch
          );
        } else {
          // Show a snackbar if the URL can't be launched and we have context
          if (context != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot open: $url'),
                action: SnackBarAction(
                  label: 'Copy',
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard')),
                    );
                  },
                ),
              ),
            );
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
        
        // Show error message to user if context is available
        if (context != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open "$url": ${e.toString()}'),
              action: SnackBarAction(
                label: 'Copy URL',
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('URL copied to clipboard')),
                  );
                },
              ),
            ),
          );
        }
        return false;
      }
    }

    // Try to launch other schemes
    try {
      if (kDebugMode) {
        print('[URL] Attempting to launch URL with scheme: ${uri.scheme}');
      }
      return await url_launcher.launchUrl(
        uri,
        mode:
            url_launcher
                .LaunchMode
                .externalApplication, // Use external app mode for all URLs
      );
    } catch (e) {
      if (kDebugMode) {
        print('[URL] Error launching URL $url: $e');
      }
      
      // Show error message to user if context is available
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening URL: ${e.toString()}'),
            action: SnackBarAction(
              label: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('URL copied to clipboard')),
                );
              },
            ),
          ),
        );
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
