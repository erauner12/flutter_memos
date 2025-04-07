import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart' as launcher; // Add prefix

class UrlHelper {
  static Future<bool> launchUrl(
    String urlString, {
    required BuildContext context,
    required WidgetRef ref, // Keep ref if needed for other logic
  }) async {
    final Uri? uri = Uri.tryParse(urlString);
    if (uri == null) {
      if (kDebugMode) {
        debugPrint('[UrlHelper] Invalid URL: $urlString');
      }
      // Check mounted status even before await, as context might become invalid.
      if (context.mounted) {
        _showErrorDialog(
          context,
          'Invalid URL',
          'Could not parse the URL: $urlString',
        );
      }
      return false;
    }

    try {
      // Use the launchUrl function from url_launcher package
      if (await launcher.canLaunchUrl(uri)) {
        // Use prefix
        // Pass Uri object
        // Pass Uri object. Remove mode parameter as it seems to cause issues.
        final bool launched = await launcher.launchUrl(uri); // Use prefix
        if (!launched && kDebugMode) {
          debugPrint('[UrlHelper] Could not launch URL: $urlString');
          // Optionally show error dialog even if canLaunchUrl was true but launchUrl failed
          // if (context.mounted) _showErrorDialog(context, 'Launch Error', 'Could not open the URL: $urlString');
        }
        return launched;
      } else {
        if (kDebugMode) {
          debugPrint('[UrlHelper] Cannot launch URL: $urlString');
        }
        // Add mounted check after await
        if (!context.mounted) return false;
        _showErrorDialog(context, 'Cannot Launch URL', 'Device cannot handle this URL: $urlString');
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[UrlHelper] Error launching URL $urlString: $e');
      }
      // Add mounted check after await/catch
      if (!context.mounted) return false;
      _showErrorDialog(context, 'Launch Error', 'An error occurred while trying to open the URL: $e');
      return false;
    }
  }

  // Removed unused ref parameter
  static void _showErrorDialog(BuildContext context, String title, String content) {
    // Use showCupertinoDialog and CupertinoAlertDialog
    // Check mounted before showing dialog, although less critical here as it's synchronous
    if (!context.mounted) return;
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          // Use CupertinoDialogAction
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
