import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/note_providers.dart'; // Import note providers
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheNotesScreen extends ConsumerWidget {
  const CacheNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use ProviderScope to override the generic notesNotifierProvider
    // with the specific cacheNotesNotifierProvider for the ItemsScreen below.
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Cache'),
        // Add other nav bar elements if needed (e.g., add button)
        // trailing: CupertinoButton(
        //   padding: EdgeInsets.zero,
        //   child: const Icon(CupertinoIcons.add),
        //   onPressed: () {
        //     // Navigate to new note screen, potentially passing BlinkoNoteType.cache
        //     Navigator.of(context, rootNavigator: true).pushNamed('/new-note', arguments: {'blinkoType': BlinkoNoteType.cache});
        //   },
        // ),
      ),
      child: ProviderScope(
        overrides: [
          // Override the generic provider with the cache-specific one
          notesNotifierProvider.overrideWithProvider(
            cacheNotesNotifierProvider,
          ),
        ],
        // Render ItemsScreen without its internal navigation bar
        child: const ItemsScreen(showNavigationBar: false),
      ),
    );
  }
}
