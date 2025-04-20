import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/server_config.dart';
// Import new single config provider
import 'package:flutter_memos/providers/note_server_config_provider.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        middle: const Text('Notes'),
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
                                    isInitialSetup: false,
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
                          : 'Tap to view notes',
                    ),
                    leading: Icon(_getServerIcon(noteServerConfig.serverType)),
                    trailing: const CupertinoListTileChevron(),
                    onTap: () {
                      // Navigate to the ItemsScreen for this server
                      // The route '/notes/:serverId' is now just '/notes'
                      // ItemsScreen no longer takes serverId
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder:
                              (_) => const ItemsScreen(), // Remove serverId arg
                          settings: const RouteSettings(
                            name: '/notes',
                          ), // Use generic route name
                        ),
                      );
                    },
                  ),
                ],
              ),
            // Add other sections to the hub if needed (e.g., recent items, quick actions)
          ],
        ),
      ),
    );
  }
}
