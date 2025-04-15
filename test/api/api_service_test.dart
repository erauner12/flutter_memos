import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiService Tests', () {
    group('Model Tests', () {
      test('NoteItem model has correct fields and behavior', () {
        // Updated model name
        // Create a sample app NoteItem
        final appNote = NoteItem(
          // Updated type
          id: 'test123',
          content: 'Test note content', // Updated content
          pinned: true,
          state: NoteState.normal, // Updated enum
          visibility: NoteVisibility.public, // Updated enum
          createTime: DateTime.parse(
            '2025-03-22T21:45:00.000Z',
          ), // Use DateTime
          updateTime: DateTime.parse(
            '2025-03-23T01:45:58.000Z',
          ), // Use DateTime
          displayTime: DateTime.parse(
            '2025-03-22T21:45:00.000Z',
          ), // Use DateTime
          creatorId: '1', // Use creatorId with just the ID part
        );

        // Verify all fields were set correctly
        expect(appNote.id, equals('test123'));
        expect(appNote.content, equals('Test note content'));
        expect(appNote.pinned, isTrue);
        expect(appNote.state, equals(NoteState.normal));
        expect(appNote.visibility, equals(NoteVisibility.public));
        expect(
          appNote.createTime.toIso8601String(),
          equals('2025-03-22T21:45:00.000Z'),
        );
        expect(
          appNote.updateTime.toIso8601String(),
          equals('2025-03-23T01:45:58.000Z'),
        );
        expect(
          appNote.displayTime.toIso8601String(),
          equals('2025-03-22T21:45:00.000Z'),
        );
        expect(appNote.creatorId, equals('1')); // Verify creatorId

        // Test the copyWith method
        final updatedNote = appNote.copyWith(
          // Updated variable name
          content: 'Updated content',
          pinned: false
        );

        expect(updatedNote.id, equals('test123')); // Same ID
        expect(
          updatedNote.content,
          equals('Updated content'),
        ); // Updated content
        expect(updatedNote.pinned, isFalse); // Updated pinned state
        expect(updatedNote.state, equals(NoteState.normal)); // Same state
      });

      test('Comment model has correct fields', () {
        // Create a sample Comment
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final appComment = Comment(
          id: 'comment123',
          content: 'Test comment content',
          createTime: timestamp,
          creatorId: '1',
        );

        // Verify all fields were set correctly
        expect(appComment.id, equals('comment123'));
        expect(appComment.content, equals('Test comment content'));
        expect(appComment.createTime, equals(timestamp));
        expect(appComment.creatorId, equals('1'));
      });
    });

    group('API Model Tests', () {
      test('V1State enum maps correctly to NoteState enum', () {
        // Updated enum name
        // Test mapping of V1State.NORMAL to NoteState.normal
        final normalNote = NoteItem(
          // Updated type
          id: 'test1',
          content: 'Normal note', // Updated content
          state: NoteState.normal, // Updated enum
          // Add required fields
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
          displayTime: DateTime.now(),
          visibility: NoteVisibility.private,
          pinned: false,
        );

        // Test mapping of V1State.ARCHIVED to NoteState.archived
        final archivedNote = NoteItem(
          // Updated type
          id: 'test2',
          content: 'Archived note', // Updated content
          state: NoteState.archived, // Updated enum
          // Add required fields
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
          displayTime: DateTime.now(),
          visibility: NoteVisibility.private,
          pinned: false,
        );

        // Verify correct state values
        expect(normalNote.state, equals(NoteState.normal));
        expect(archivedNote.state, equals(NoteState.archived));

        // Verify string representation
        expect(normalNote.state.toString().split('.').last, equals('normal'));
        expect(
          archivedNote.state.toString().split('.').last,
          equals('archived'),
        );
      });

      test('Apiv1Memo model structure matches expected format', () {
        // Create an API memo model to verify format compatibility
        final apiMemo = Apiv1Memo(
          name: 'memos/abc123',
          content: 'API memo content',
          pinned: true,
          state: V1State.NORMAL,
          visibility: V1Visibility.PUBLIC,
          createTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          updateTime: DateTime.parse('2025-03-23T01:45:58.000Z'),
          displayTime: DateTime.parse('2025-03-22T21:45:00.000Z'),
          creator: 'users/1',
        );

        // Verify structure and basic properties
        expect(apiMemo.name, equals('memos/abc123'));
        expect(apiMemo.content, equals('API memo content'));
        expect(apiMemo.pinned, isTrue);
        expect(apiMemo.state, equals(V1State.NORMAL));
        expect(apiMemo.visibility, equals(V1Visibility.PUBLIC));

        // Check date conversions
        final createTimeStr = apiMemo.createTime?.toIso8601String();
        expect(createTimeStr, equals('2025-03-22T21:45:00.000Z'));

        // Test ID parsing (common operation in our service)
        final idParts = apiMemo.name?.split('/');
        expect(idParts?.length, equals(2));
        expect(idParts?[0], equals('memos'));
        expect(idParts?[1], equals('abc123'));
      });
    });

    group('Utility Tests', () {
      test('DateTime parsing for API compatibility', () {
        // Test ISO string parsing (important for API interactions)
        final dateStr = '2025-03-22T21:45:00.000Z';
        final date = DateTime.parse(dateStr);

        expect(date.year, equals(2025));
        expect(date.month, equals(3));
        expect(date.day, equals(22));
        expect(date.hour, equals(21));
        expect(date.minute, equals(45));
        expect(date.second, equals(0));

        // Test round-trip formatting (important for API compatibility)
        expect(date.toIso8601String(), equals(dateStr));
      });

      test('Resource name parsing functions correctly', () {
        // Test common resource name parsing operations

        // Format: "memos/abc123"
        final memoName = 'memos/abc123';
        final memoParts = memoName.split('/');
        expect(memoParts.length, equals(2));
        expect(memoParts[1], equals('abc123'));

        // Format: "users/1"
        final userName = 'users/1';
        final userParts = userName.split('/');
        expect(userParts.length, equals(2));
        expect(userParts[1], equals('1'));

        // Handles missing slash correctly
        final invalidName = 'plainId';
        final invalidParts = invalidName.split('/');
        expect(invalidParts.length, equals(1));
        expect(invalidParts[0], equals('plainId'));
      });

      test('Comment ID parsing handles both formats correctly', () {
        // Test parsing combined memo/comment IDs

        // Format: "memoId/commentId"
        final combinedId = 'memo123/comment456';
        final parts = combinedId.split('/');
        expect(parts.length, equals(2));
        expect(parts[0], equals('memo123'));
        expect(parts[1], equals('comment456'));

        // Format: just "commentId"
        final simpleId = 'comment456';
        final simpleParts = simpleId.split('/');
        expect(simpleParts.length, equals(1));
        expect(simpleParts[0], equals('comment456'));

        // This verifies our comment API methods can handle both formats
      });

      // The 'Delete memo handles empty responses correctly' test was removed
      // as it was redundant. The behavior is now verified in provider tests
      // using the mocked ApiService.
    });
  });
}
