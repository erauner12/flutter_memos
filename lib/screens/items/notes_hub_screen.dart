import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
// ItemsScreen might not be directly navigated to from here anymore
// import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// This screen might become less relevant if Vault/Cache tabs directly show ItemsScreen.
// It could still serve as a fallback or entry point if no server is configured.
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
      // Navigation bar might be redundant if this screen isn't a primary navigation target
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Notes Setup'), // Adjusted title
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.settings, size: 22),
          onPressed: () {
            Navigator.of(context).push(
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
                          color: CupertinoColors.secondaryLabel.resolveFrom(
                            context,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CupertinoButton.filled(
                        child: const Text('Go to Settings'),
                        onPressed: () {
                          Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder:
                                  (ctx) => const SettingsScreen(
                                    isInitialSetup: false, // Or true if needed
                                  ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              )
            else
              // This section might be removed if Vault/Cache tabs are the primary way to view notes
              CupertinoListSection.insetGrouped(
                header: const Text('CONFIGURED NOTE SERVER'),
                children: [
                  CupertinoListTile(
                    title: Text(
                      noteServerConfig.name ?? noteServerConfig.serverUrl,
                    ),
                    subtitle: Text(
                      noteServerConfig.name != null
                          ? noteServerConfig.serverUrl
                          : 'Server configured', // Updated subtitle
                    ),
                    leading: Icon(_getServerIcon(noteServerConfig.serverType)),
                    // Remove chevron and onTap if direct navigation is handled by tabs
                    // trailing: const CupertinoListTileChevron(),
                    // onTap: () {
                    //   // Navigation likely handled by Vault/Cache tabs now
                    //   // Navigator.of(context).push(
                    //   //   CupertinoPageRoute(
                    //   //     builder: (_) => const ItemsScreen(), // Example: Default view
                    //   //     settings: const RouteSettings(name: '/notes'),
                    //   //   ),
                    //   // );
                    // },
                  ),
                ],
              ),
            // Add other sections if this hub serves another purpose
          ],
        ),
      ),
    );
  }
}
