import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder screen for the Resources page in the Blinko web UI.
class BlinkoWebResources extends ConsumerWidget {
  const BlinkoWebResources({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch resources using a Riverpod provider

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_copy_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Blinko Web Resources',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will display your files and folders.',
              textAlign: TextAlign.center,
            ),
            // TODO: Replace with actual resource list/grid
          ],
        ),
      ),
    );
  }
}
