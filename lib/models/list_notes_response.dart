import 'package:flutter_memos/models/note_item.dart';

class ListNotesResponse {
  final List<NoteItem> notes;
  final String? nextPageToken;

  ListNotesResponse({required this.notes, this.nextPageToken});

  bool get hasMorePages => nextPageToken != null && nextPageToken!.isNotEmpty;
  bool get isEmpty => notes.isEmpty;
}
