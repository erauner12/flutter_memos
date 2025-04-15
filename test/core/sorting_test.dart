import 'dart:math';

import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/utils/note_utils.dart'; // Updated import
import 'package:flutter_test/flutter_test.dart';

/// These tests verify that our client-side sorting works correctly,
/// independently of any server-side sorting issues.
///
/// The Memos server has limited support for dynamic sorting as it uses
/// specific boolean flags (OrderByUpdatedTs, OrderByTimeAsc) rather than
/// generic sort fields. Our app implements reliable client-side sorting
/// as a solution.
void main() {
  group('Client-side Sorting Tests', () {
    test('sortByPinnedThenUpdateTime correctly sorts notes', () {
      // Updated test name to match function
      // Create test notes with different update times
      final now = DateTime.now();
      // Explicitly type the list
      final List<NoteItem> notes = [
        NoteItem(
          id: '1',
          content: 'Oldest update',
          pinned: false, // Add required field
          updateTime: now.subtract(const Duration(days: 2)),
          createTime: now.subtract(const Duration(days: 4)),
          displayTime: now.subtract(const Duration(days: 2)),
          visibility: NoteVisibility.private, // Add required fields
          state: NoteState.normal,
        ),
        NoteItem(
          id: '2',
          content: 'Middle update',
          updateTime: now.subtract(const Duration(days: 1)),
          createTime: now.subtract(const Duration(days: 5)),
          displayTime: now.subtract(const Duration(days: 1)),
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false, // Add required field
        ),
        NoteItem(
          id: '3',
          pinned: false, // Add required field
          content: 'Newest update',
          updateTime: now,
          createTime: now.subtract(const Duration(days: 6)),
          displayTime: now,
          visibility: NoteVisibility.private,
          state: NoteState.normal,
        ),
      ]; // Close the list

      // Shuffle the list to ensure initial order doesn't match expected order
      final random = Random(42); // Fixed seed for reproducibility
      notes.shuffle(random);

      // Apply sorting using the actual implementation
      NoteUtils.sortByPinnedThenUpdateTime(
        notes,
      ); // Use the specific sort function

      // Verify the order (newest first)
      expect(
        notes[0].id,
        equals('3'),
        reason: 'First note should be the newest by update time',
      );
      expect(
        notes[1].id,
        equals('2'),
        reason: 'Second note should be the middle by update time',
      );
      expect(
        notes[2].id,
        equals('1'),
        reason: 'Third note should be the oldest by update time',
      );
    });

    test('sortNotes handles epoch timestamps gracefully', () {
      // Updated test name
      // Create test notes with epoch timestamps
      final now = DateTime.now();
      final epochTime = DateTime.fromMillisecondsSinceEpoch(0);
      // Explicitly type the list
      final List<NoteItem> notes = [
        NoteItem(
          id: '1',
          content: 'Epoch update time',
          updateTime: epochTime, // Use epoch time
          createTime: now.subtract(const Duration(days: 6)),
          displayTime: now.subtract(const Duration(days: 2)),
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false, // Add required field
        ),
        NoteItem(
          id: '2',
          content: 'Epoch create time',
          updateTime: now.subtract(const Duration(days: 1)),
          createTime: epochTime, // Use epoch time
          displayTime: now.subtract(const Duration(days: 1)),
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false, // Add required field
        ),
        NoteItem(
          id: '3',
          content: 'All times present',
          updateTime: now,
          createTime: now.subtract(const Duration(days: 4)),
          displayTime: now,
          visibility: NoteVisibility.private,
          state: NoteState.normal,
          pinned: false, // Add required field
        ),
      ];

      // Test update time sorting (pinned then update time)
      NoteUtils.sortByPinnedThenUpdateTime(
        notes,
      ); // Use the specific sort function
      expect(
        notes[0].id,
        equals('3'),
        reason: 'Note with valid update time should come first',
      );
      expect(
        notes[1].id,
        equals('2'),
        reason: 'Note with middle update time should be second',
      );
      expect(
        notes[2].id,
        equals('1'),
        reason: 'Note with epoch update time should be last',
      );


      // Test create time sorting
      NoteUtils.sortByCreateTime(notes);
      expect(
        notes[0].id,
        equals('3'),
        reason: 'Note with valid create time should come first',
      );
      expect(
        notes[1].id,
        equals('1'),
        reason: 'Note with middle create time should be second',
      );
      expect(
        notes[2].id,
        equals('2'),
        reason: 'Note with epoch create time should be last',
      );
    });
  });
}
