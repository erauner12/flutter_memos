import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder screen for the Home page in the Blinko web UI.
/// This will eventually display the main feed of notes/cards.
class BlinkoWebHome extends ConsumerWidget {
  const BlinkoWebHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Fetch notes using a Riverpod provider
    // final notesAsyncValue = ref.watch(notesProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Blinko Web Home',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This screen will display your notes feed.',
              textAlign: TextAlign.center,
            ),
            // TODO: Replace with actual note list/grid/masonry layout
            // notesAsyncValue.when(
            //   data: (notes) => Expanded(child: NotesGrid(notes: notes)), // Example grid widget
            //   loading: () => const CircularProgressIndicator(),
            //   error: (err, stack) => Text('Error loading notes: $err'),
            // ),
          ],
        ),
      ),
    );
  }
}
