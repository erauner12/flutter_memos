import 'package:flutter/cupertino.dart';
// Import the new default screen, e.g., Vault or Cache, or keep ItemsScreen if it handles default
// import 'package:flutter_memos/screens/vault/vault_notes_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Keep ItemsScreen for now
import 'package:flutter_riverpod/flutter_riverpod.dart';

// HomeScreen might not be used directly in the tab structure anymore,
// depending on how ConfigCheckWrapper sets up the tabs.
// If it IS used for one of the tabs (e.g., the initial one), it should
// return the appropriate screen (Vault, Cache, etc.).
// For now, let's assume it might still be referenced somewhere and point it to ItemsScreen
// which might default to a specific preset like 'today' or 'all'.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Return the default screen for the first tab, e.g., Vault or Cache.
    // Or return ItemsScreen which might default to 'today' or 'all' if no preset is given.
    // return const VaultNotesScreen(); // Example: Default to Vault
    return const ItemsScreen(
      presetKey: 'today',
    ); // Example: Default to ItemsScreen with 'today' preset

    // If ItemsScreen doesn't include a Scaffold, you might need one:
    // return const CupertinoPageScaffold(
    //   child: ItemsScreen(presetKey: 'today'),
    // );
  }
}
