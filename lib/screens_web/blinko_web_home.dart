import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Adjust the import path based on your actual project structure
import 'package:flutter_memos/providers/note_providers.dart';
import 'package:flutter_memos/models/note.dart'; // Assuming Note model exists

/// Screen for the Home page in the Blinko web UI.
/// Displays the main feed of notes/cards using the notesProvider.
class BlinkoWebHome extends ConsumerWidget {
  const BlinkoWebHome({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notes provider to get the list of notes
    final notesAsyncValue = ref.watch(notesProvider); // Assuming notesProvider exists

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: notesAsyncValue.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Center(child: Text('No notes yet.'));
          }
          // Render a grid or list of notes - using Wrap for simplicity here
          return SingleChildScrollView(
            child: Wrap(
              spacing: 16.0, // Horizontal spacing between cards
              runSpacing: 16.0, // Vertical spacing between cards
              children: notes.map((note) => _buildNoteCard(context, note)).toList(),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Error loading notes: $err',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ),
    );
  }

  /// Builds a simple card widget for a single note.
  Widget _buildNoteCard(BuildContext context, Note note) {
    // Use Theme.of(context).cardTheme for styling consistency
    final cardTheme = Theme.of(context).cardTheme;

    return Card(
      // Apply theme properties
      shape: cardTheme.shape,
      elevation: cardTheme.elevation,
      margin: cardTheme.margin,
      color: cardTheme.color,
      child: InkWell( // Make card tappable
        onTap: () {
          // TODO: Implement navigation to note detail or edit screen for web
          print('Tapped on note: ${note.id}');
          // Example: Navigator.pushNamed(context, '/note/${note.id}');
        },
        borderRadius: (cardTheme.shape as RoundedRectangleBorder?)?.borderRadius ?? BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300, minHeight: 100), // Example constraints
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fit content
            children: [
              Text(
                note.title ?? 'Untitled Note', // Use title or fallback
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content ?? 'No content', // Use content or fallback
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              // Add more details like date, tags, etc. if needed
            ],
          ),
        ),
      ),
    );
  }
}
