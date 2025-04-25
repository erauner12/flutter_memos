import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import BlinkoNoteType
// Import note providers - no longer needed for override
// import 'package:flutter_memos/providers/note_providers.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart'; // Import SettingsScreen
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheNotesScreen extends ConsumerWidget {
  const CacheNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Directly render ItemsScreen, passing the specific type.
    // No ProviderScope override is needed.
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Cache'),
        // Keep trailing add button, passing the type
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Existing Add button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.add),
              onPressed: () {
                // Navigate to new note screen, passing BlinkoNoteType.cache
                Navigator.of(context, rootNavigator: true).pushNamed(
                  '/new-note',
                  arguments: {'blinkoType': BlinkoNoteType.cache},
                );
              },
            ),
            // Spacing
            const SizedBox(width: 8),
            // New Settings button
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.settings, size: 24),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                    builder: (_) => const SettingsScreen(isInitialSetup: false),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      // Render ItemsScreen without its internal navigation bar and specify the type
      child: const ItemsScreen(
        showNavigationBar: false,
        type: BlinkoNoteType.cache, // Pass the type parameter
      ),
    );
  }
}
