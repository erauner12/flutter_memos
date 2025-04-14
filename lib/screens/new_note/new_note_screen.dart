import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_note_form.dart'; // Updated import

class NewNoteScreen extends ConsumerWidget { // Renamed class
  const NewNoteScreen({super.key}); // Renamed constructor

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Create a New Note'), // Updated text
        transitionBetweenRoutes: false,
      ),
      child: SafeArea(
        child: NewNoteForm(), // Use renamed form
      ),
    );
  }
}