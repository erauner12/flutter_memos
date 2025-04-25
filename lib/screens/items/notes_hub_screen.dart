import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
// ItemsScreen is no longer directly navigated to from here. Cache/Vault/Generic tabs handle it.
// import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// This screen acts as a placeholder or entry point, primarily shown when
/// no note server is configured yet. Navigation to actual notes happens
/// via the main app tabs (Cache, Vault, All Notes).
class NotesHubScreen extends ConsumerWidget {
  const NotesHubScreen({super.key});

  IconData _getServerIcon(ServerType type) {
    switch (type) {
      case ServerType.memos:
        return CupertinoIcons.bolt_horizontal_circle_fill;
      case ServerType.blinko:
        return CupertinoIcons.sparkles;
      case ServerType.vikunja:
        return CupertinoIcons.list_bullet;
      case ServerType.todoist:
        return CupertinoIcons.check_mark_circled;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the single note server config provider
    final noteServerConfig = ref.watch(noteServerConfigProvider);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notes Setup'), // Keep title relevant
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings, size: 22),
          onPressed: () {
            // Use root navigator to push settings over the tabs
            Navigator.of(context, rootNavigator: true).push(
              CupertinoPageRoute(
                builder: (ctx) => const SettingsScreen(isInitialSetup: false),
              ),
            );
          },
        ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            if (noteServerConfig == null)
              // Show setup instructions if no server is configured
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Text(
                        'No Note Server Configured',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Please add a Memos, Blinko, or Vikunja server in Settings to view notes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        child: const Text('Go to Settings'),
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push(
                            CupertinoPageRoute(
                              builder: (ctx) => const SettingsScreen(isInitialSetup: true), // Mark as initial setup
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              // If a server IS configured, show its details but no direct navigation.
              // The user should use the main tabs (Cache/Vault/All) to see notes.
              CupertinoListSection.insetGrouped(
                header: const Text('CONFIGURED NOTE SERVER'),
                footer: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 15.0),
                  child: Text('Use the main tabs (Cache, Vault, All Notes) at the bottom to view your notes.'),
                ),
                children: [
                  CupertinoListTile(
                    title: Text(noteServerConfig.name ?? noteServerConfig.serverUrl),
                    subtitle: Text(
                      noteServerConfig.name != null ? noteServerConfig.serverUrl : 'Server configured',
                    ),
                    leading: Icon(_getServerIcon(noteServerConfig.serverType)),
                    // No trailing chevron or onTap needed here.
                  ),
                ],
              ),
            // Add other sections if this hub serves another purpose (e.g., onboarding)
          ],
        ),
      ),
    );
  }
}