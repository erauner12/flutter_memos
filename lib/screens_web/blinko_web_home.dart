import 'dart:developer'; // Import dart:developer for log

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/note_item.dart'; // Correct import for NoteItem
import 'package:flutter_memos/providers/note_providers.dart'; // Correct import for notes providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

/// Screen for the Home page in the Blinko web UI.
/// Displays the main feed of notes/cards using the notesNotifierProvider.
class BlinkoWebHome extends ConsumerWidget {
  const BlinkoWebHome({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the notes notifier provider to get the state
    final notesState = ref.watch(notesNotifierProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _buildBody(context, notesState),
    );
  }

  Widget _buildBody(BuildContext context, NotesState state) {
    if (state.isLoading && state.notes.isEmpty) {
      // Show loading indicator only if loading initial data
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      // Show error message
      return Center(
        child: Text(
          'Error loading notes: ${state.error}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    } else if (state.notes.isEmpty && !state.isLoading) {
      // Show empty state message only if not loading
      return const Center(child: Text('No notes yet.'));
    } else {
      // Display notes, potentially with a loading indicator if loading more
      return Column(
        children: [
          if (state.isLoading && state.notes.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child:
                  LinearProgressIndicator(), // Show subtle loading if refreshing/loading more
            ),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 16.0, // Horizontal spacing between cards
                runSpacing: 16.0, // Vertical spacing between cards
                children:
                    state.notes
                        .map((note) => _buildNoteCard(context, note))
                        .toList(),
              ),
            ),
          ),
          if (state.isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      );
    }
  }

  /// Builds a simple card widget for a single note item.
  Widget _buildNoteCard(BuildContext context, NoteItem note) {
    // Changed Note to NoteItem
    final cardTheme = Theme.of(context).cardTheme;
    final dateFormat = DateFormat.yMMMd().add_jm(); // Example date format

    // Attempt to get borderRadius, default if shape is not RoundedRectangleBorder
    BorderRadius borderRadius = BorderRadius.circular(12.0); // Default value
    if (cardTheme.shape is RoundedRectangleBorder) {
      borderRadius = (cardTheme.shape as RoundedRectangleBorder).borderRadius
          .resolve(Directionality.of(context));
    }

    // Generate a title from the first line or first N characters of content
    String displayTitle = note.content.split('\n').first;
    if (displayTitle.length > 50) {
      displayTitle = '${displayTitle.substring(0, 50)}...';
    }
    if (displayTitle.trim().isEmpty) {
      displayTitle = 'Untitled Note';
    }


    return Card(
      shape: cardTheme.shape,
      elevation: cardTheme.elevation,
      margin:
          cardTheme.margin ??
          const EdgeInsets.symmetric(
            vertical: 4.0,
            horizontal: 8.0,
          ), // Provide default margin
      color: cardTheme.color,
      child: InkWell(
        onTap: () {
          // TODO: Implement navigation to note detail or edit screen for web
          log('Tapped on note: ${note.id}'); // Use log instead of print
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped note: ${note.id}. Navigation not implemented.',
              ),
            ),
          );
          // Example: Navigator.pushNamed(context, '/note/${note.id}');
        },
        borderRadius:
            borderRadius, // Use the calculated or default borderRadius
        child: Container(
          padding: const EdgeInsets.all(16.0),
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 300, minHeight: 100), // Example constraints
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Fit content
            children: [
              Text(
                displayTitle, // Use generated title
                style: Theme.of(context).textTheme.titleMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                note.content, // Use full content
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'Updated: ${dateFormat.format(note.updateTime.toLocal())}', // Show update time
                style: Theme.of(context).textTheme.labelSmall,
              ),
              // Add more details like date, tags, etc. if needed
            ],
          ),
        ),
      ),
    );
  }
}
