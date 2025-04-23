import 'package:flutter/material.dart';
// TODO: Adjust import path if web_settings_provider is elsewhere
import 'package:flutter_memos/providers/web_settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen for managing web application settings.
class BlinkoWebSettings extends ConsumerWidget {
  const BlinkoWebSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the settings state
    final settings = ref.watch(webSettingsProvider);
    // Get the notifier to call update methods
    final settingsNotifier = ref.read(webSettingsProvider.notifier);

    return Scaffold(
      // Use a standard AppBar if this screen is pushed onto the stack
      // If it's part of the main layout's body, you might not need an AppBar here.
      appBar: AppBar(
        title: const Text('Web Settings'),
        // Add back button automatically if pushed via Navigator
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Dark Mode Toggle
          SwitchListTile(
            title: const Text('Enable Dark Mode'),
            subtitle: const Text('Switch between light and dark themes'),
            value: settings.darkMode,
            onChanged: (value) {
              settingsNotifier.updateDarkMode(value);
            },
            secondary: const Icon(Icons.brightness_6_outlined),
          ),

          const Divider(),

          // Placeholder for other settings
          ListTile(
            leading: const Icon(Icons.language_outlined),
            title: const Text('Language'),
            subtitle: const Text('English (US)'), // Example
            onTap: () {
              // TODO: Implement language selection
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language setting not implemented yet.')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications'),
            onTap: () {
              // TODO: Implement notification settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings not implemented yet.')),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About Blinko Web'),
            subtitle: const Text('Version 1.0.0'), // Example version
            onTap: () {
              // TODO: Show about dialog or screen
            },
          ),
        ],
      ),
    );
  }
}
