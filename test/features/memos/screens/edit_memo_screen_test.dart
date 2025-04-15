import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/list_notes_response.dart'; // Updated import
import 'package:flutter_memos/models/note_item.dart'; // Updated import
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart'; // Updated import
import 'package:flutter_memos/services/base_api_service.dart'; // Updated import
import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Import the mock for UrlLauncherService
import '../../../services/url_launcher_service_test.mocks.dart';
// Generate nice mocks for BaseApiService
@GenerateNiceMocks([MockSpec<BaseApiService>()])
// This import will work after running build_runner
import 'edit_memo_screen_test.mocks.dart'; // Keep mock file name for now

void main() {
  late MockBaseApiService mockApiService; // Updated mock type
  late MockUrlLauncherService mockUrlLauncherService;
  late NoteItem testNote; // Updated type

  setUp(() {
    // Initialize mock services
    mockApiService = MockBaseApiService(); // Updated mock type
    mockUrlLauncherService = MockUrlLauncherService();

    // Stub the launch method to return success by default
    when(mockUrlLauncherService.launch(any)).thenAnswer((_) async => true);

    // Add stub for apiBaseUrl property
    when(mockApiService.apiBaseUrl).thenReturn('http://test-url.com');

    // Create a test note
    testNote = NoteItem(
      // Updated type
      id: 'test-edit-note-id', // Updated prefix
      content: 'Test note content for editing', // Updated content
      pinned: false,
      createTime: DateTime.now().subtract(const Duration(days: 1)),
      updateTime: DateTime.now(),
      displayTime: DateTime.now(), // Add required field
      visibility: NoteVisibility.private, // Add required field
      state: NoteState.normal, // Add required field
    );
    // Stub getNote
    when(mockApiService.getNote(argThat(isA<String>()))).thenAnswer((
      invocation,
    ) async {
      // Updated method name
      final id = invocation.positionalArguments[0] as String;
      if (id == testNote.id) {
        return testNote;
      }
      throw Exception('Note not found: $id'); // Updated message
    });

    // Stub updateNote
    when(
      mockApiService.updateNote(
        argThat(isA<String>()),
        argThat(isA<NoteItem>()),
      ),
    ).thenAnswer((invocation) async {
      // Updated method name and type
      final id = invocation.positionalArguments[0] as String;
      final note =
          invocation.positionalArguments[1] as NoteItem; // Updated type

      // Return updated note
      return note.copyWith(
        id: id,
        updateTime: DateTime.now(),
      );
    });

    // Stub listNotes - this is needed to avoid errors during refresh operations
    when(
      mockApiService.listNotes(
        // Updated method name
        filter: anyNamed('filter'),
        state: anyNamed('state'),
        sort: anyNamed('sort'),
        direction: anyNamed('direction'),
        pageSize: anyNamed('pageSize'),
        pageToken: anyNamed('pageToken'),
      ),
    ).thenAnswer(
      (_) async => ListNotesResponse(
        // Updated response type
        notes: [testNote], // Updated field name
        nextPageToken: null,
      ),
    );
  });

  testWidgets('EditEntityScreen loads and displays note content', (
    WidgetTester tester,
  ) async {
    // Updated screen name
    // Set up mock response
    when(mockApiService.getNote('test-note-id')).thenAnswer((invocation) async {
      // Updated method name
      return NoteItem(
        // Updated type
        id: 'test-note-id', // Updated prefix
        content: 'Test Note Content', // Updated content
        pinned: true,
        state: NoteState.normal, // Updated enum
        createTime: DateTime.now(), // Add required field
        updateTime: DateTime.now(), // Add required field
        displayTime: DateTime.now(), // Add required field
        visibility: NoteVisibility.private, // Add required field
        // pinned: true, // Already present
      );
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ),
        ],
        child: const CupertinoApp(
          home: EditEntityScreen(
            // Updated screen name
            entityId: 'test-note-id',
            entityType: 'note', // Updated type
          ),
        ),
      ),
    );

    // Initially we should see a loading indicator
    expect(
      find.byType(CupertinoActivityIndicator),
      findsOneWidget,
    );

    // Wait for the future to complete
    await tester.pumpAndSettle();

    // Now we should see the form with the note content
    expect(find.text('Test Note Content'), findsOneWidget); // Updated content
    expect(
      find.byType(CupertinoTextField),
      findsOneWidget,
    );
    expect(
      find.byType(CupertinoSwitch),
      findsNWidgets(2), // Assuming still 2 switches (pinned, visibility?)
    );
  });

  testWidgets('EditEntityScreen handles save properly', (
    WidgetTester tester,
  ) async {
    // Updated screen name
    // Set up mock responses
    when(mockApiService.getNote('test-edit-note-id')).thenAnswer((
      // Updated method name
      invocation,
    ) async {
      return testNote;
    });

    when(
      mockApiService.updateNote(
        // Updated method name
        argThat(equals('test-edit-note-id')),
        argThat(isA<NoteItem>()), // Updated type
      ),
    ).thenAnswer((invocation) async {
      final note =
          invocation.positionalArguments[1] as NoteItem; // Updated type
      return note.copyWith(id: 'test-edit-note-id', updateTime: DateTime.now(),
      );
    });

    // Build our app and trigger a frame
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(mockApiService),
          urlLauncherServiceProvider.overrideWithValue(
            mockUrlLauncherService,
          ),
        ],
        child: const CupertinoApp(
          home: EditEntityScreen(
            // Updated screen name
            entityId: 'test-edit-note-id',
            entityType: 'note', // Updated type
          ),
        ),
      ),
    );

    // Wait for data to load
    await tester.pumpAndSettle();

    // Edit the content
    await tester.enterText(
      find.byType(CupertinoTextField),
      'Updated Content',
    );

    // Tap the save button (assuming CupertinoButton with text)
    await tester.tap(
      find.widgetWithText(CupertinoButton, 'Save Changes'),
    );
    await tester.pumpAndSettle();

    // Verify the updateNote was called
    verify(
      mockApiService.updateNote(
        argThat(equals('test-edit-note-id')),
        any,
      ), // Updated method name
    ).called(1);
  });
}
