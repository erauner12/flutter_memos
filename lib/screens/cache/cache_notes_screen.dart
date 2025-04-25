import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/screens/items/items_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CacheNotesScreen extends ConsumerWidget {
  const CacheNotesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Option 1: Use ProviderScope override
    // return ProviderScope(
    //   overrides: [
    //     quickFilterPresetProvider.overrideWithValue('cache'), // Assuming 'cache' preset exists
    //   ],
    //   child: const ItemsScreen(),
    // );

    // Option 2: Pass presetKey via constructor
     return const ItemsScreen(presetKey: 'cache');

    // Basic Placeholder:
    // return const CupertinoPageScaffold(
    //   navigationBar: CupertinoNavigationBar(
    //     middle: Text('Cache'),
    //   ),
    //   child: Center(
    //     child: Text('Cache Notes Placeholder'),
    //   ),
    // );
  }
}
