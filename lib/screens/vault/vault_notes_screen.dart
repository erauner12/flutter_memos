import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class VaultNotesScreen extends ConsumerWidget {
  const VaultNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Option 1: Use ProviderScope override if ItemsScreen reads the preset directly
    // return ProviderScope(
    //   overrides: [
    //     quickFilterPresetProvider.overrideWithValue('vault'), // Assuming 'vault' preset exists
    //   ],
    //   child: const ItemsScreen(),
    // );

    // Option 2: Pass presetKey via constructor (requires ItemsScreen modification)
    return const ItemsScreen(presetKey: 'vault');

    // Basic Placeholder:
    // return const CupertinoPageScaffold(
    //   navigationBar: CupertinoNavigationBar(
    //     middle: Text('Vault'),
    //   ),
    //   child: Center(
    //     child: Text('Vault Notes Placeholder'),
    //   ),
    // );
  }
}
