import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/screens/home_screen.dart'; // Import HomeScreen
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConfigCheckWrapper extends ConsumerWidget {
  const ConfigCheckWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configLoadState = ref.watch(loadServerConfigProvider);

    return configLoadState.when(
      loading: () => const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      ),
      error: (err, stack) => CupertinoPageScaffold(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error loading configuration: $err\nPlease restart the app or check storage permissions.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ),
      ),
      data: (_) {
        // Config loaded (or attempted), now check the actual config state
        final serverConfig = ref.watch(serverConfigProvider);

        // Determine if this is the initial setup scenario
        final bool isInitialSetup = serverConfig.serverUrl.isEmpty;

        if (isInitialSetup) {
          // Not configured, show settings screen for initial setup
          // Pass a flag to SettingsScreen if needed to adjust UI
          return const SettingsScreen(isInitialSetup: true);
        } else {
          // Configured, show main app home screen
          return const HomeScreen();
        }
      },
    );
  }
}
