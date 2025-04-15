import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/main.dart' as app;
// Import NoteItem instead of Memo
import 'package:flutter_memos/models/note_item.dart';
// Import NoteCard or NoteListItem widget
import 'package:flutter_memos/screens/items/note_list_item.dart';
// Import ApiService or relevant service/provider for creating notes
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_memos/widgets/note_card.dart'; // Keep NoteCard for finding content
import 'package:flutter_slidable/flutter_slidable.dart'; // Import Slidable
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Hidden Notes Filter Integration Tests', () {
    // List to store IDs of notes created during the test for cleanup
    final List<String> createdNoteIds = [];
    String noteVisibleId = '';
    String noteToHideId = '';
    String noteFutureId = '';
    String notePinnedId = '';
    // Archived notes are handled differently, might not need direct creation here

    // --- Test Data ---
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final noteVisibleContent = 'Visible Test Note $timestamp';
    final noteToHideContent = 'Hide Me Test Note $timestamp';
    final noteFutureContent = 'Future Test Note $timestamp';
    final notePinnedContent = 'Pinned Test Note $timestamp';
    final futureStartDate = DateTime.now().add(const Duration(days: 3));

    // Helper function to create a note PROGRAMMATICALLY and return it
    // Adapted for NoteItem and optional startDate
    Future<NoteItem?> createNote(
      WidgetTester tester,
      String content, {
      DateTime? startDate,
      bool pinned = false,
      // Add other relevant NoteItem fields if needed (visibility, etc.)
    }) async {
      debugPrint(
        'Attempting to create note programmatically: "$content"${startDate != null ? " (Start: $startDate)" : ""}${pinned ? " (Pinned)" : ""}',
      );
      try {
        final apiService = ApiService(); // Assuming direct API use is feasible

        // Create a NoteItem object (adapt fields as necessary)
        final newNote = NoteItem(
          id: 'temp-${DateTime.now().millisecondsSinceEpoch}', // Temporary ID
          content: content,
          pinned: pinned,
          state: NoteState.normal, // Default state
          visibility: NoteVisibility.public, // Default visibility
          createTime: DateTime.now(),
          updateTime: DateTime.now(),
          displayTime: DateTime.now(),
          startDate: startDate,
          // Add other required fields if the model changes
        );

        // Call the API service to create the note
        // NOTE: ApiService currently uses Memo, needs adaptation for NoteItem
        // For now, we'll assume a hypothetical createNoteItem exists or adapt createMemo
        // This part WILL require modification based on your actual API service implementation
        // final createdNote = await apiService.createNoteItem(newNote); // Hypothetical

        // --- TEMPORARY WORKAROUND using createMemo ---
        // This assumes your backend handles NoteItem structure via the Memo endpoint
        // You MUST adjust this if your backend/API service differs
        final tempMemo = Memo(
          id: newNote.id,
          content: newNote.content,
          visibility: newNote.visibility.name.toUpperCase(),
          pinned: newNote.pinned,
          createdTs: (newNote.createTime.millisecondsSinceEpoch / 1000).round(),
          updatedTs: (newNote.updateTime.millisecondsSinceEpoch / 1000).round(),
          // Memos API might not directly support startDate/endDate via standard create
          // You might need a custom endpoint or update mechanism
        );
        final createdMemo = await apiService.createMemo(tempMemo);
        // Map back to NoteItem (partially)
        final createdNote = NoteItem(
          id: createdMemo.id,
          content: createdMemo.content,
          pinned: createdMemo.pinned ?? false,
          state: createdMemo.rowStatus == 'ARCHIVED'
              ? NoteState.archived
              : NoteState.normal,
          visibility: NoteVisibility.values.firstWhere(
            (v) => v.name.toUpperCase() == createdMemo.visibility,
            orElse: () => NoteVisibility.public,
          ),
          createTime: DateTime.fromMillisecondsSinceEpoch(
            (createdMemo.createdTs ?? 0) * 1000,
          ),
          updateTime: DateTime.fromMillisecondsSinceEpoch(
            (createdMemo.updatedTs ?? 0) * 1000,
          ),
          displayTime: DateTime.fromMillisecondsSinceEpoch(
            (createdMemo.updatedTs ?? 0) * 1000,
          ), // Use updateTime for display?
          // We still need to handle startDate/endDate separately if needed
          startDate: startDate, // Keep the intended start date
        );
        // If startDate needs to be set via an UPDATE call after creation:
        if (startDate != null) {
          debugPrint(
            'Note created with ID ${createdNote.id}. Attempting to update start date...',
          );
          // Hypothetical update call - replace with your actual implementation
          // await apiService.updateNoteStartDate(createdNote.id, startDate);
          // For now, we assume the test proceeds with the startDate set locally
        }
        // --- END TEMPORARY WORKAROUND ---


        debugPrint(
          'Programmatic note creation successful for: "$content" with ID: ${createdNote.id}',
        );
        createdNoteIds.add(createdNote.id);
        return createdNote;
      } catch (e, stackTrace) {
        debugPrint('Error creating note programmatically: $e\n$stackTrace');
        fail('Failed to create note programmatically: $e');
      }
      return null;
    }

    // Helper function to find a NoteListItem containing specific text
    // Uses NoteCard internally as that's where the text is rendered
    Finder findNoteListItemWithText(String text) {
      return find.ancestor(
        of: find.widgetWithText(NoteCard, text), // Find the NoteCard first
        matching: find.byType(NoteListItem), // Find its NoteListItem ancestor
      );
    }

    // Helper function to perform slide action
    Future<void> performSlideAction(
      WidgetTester tester,
      Finder itemFinder,
      IconData actionIcon,
      String actionLabel, // For logging/debugging
    ) async {
      debugPrint('[Test Action] Performing "$actionLabel" slide action...');
      // Ensure the item is visible
      await tester.ensureVisible(itemFinder);
      await tester.pumpAndSettle();

      // Find the Slidable widget associated with the NoteListItem
      final slidableFinder = find.ancestor(
        of: itemFinder,
        matching: find.byType(Slidable),
      );
      expect(slidableFinder, findsOneWidget, reason: 'Slidable not found for the item');

      // Determine swipe direction based on icon (heuristic)
      // Left-side actions (Edit, Pin/Unpin, Hide/Unhide) -> Swipe Right
      // Right-side actions (Delete, Archive) -> Swipe Left
      Offset swipeOffset;
      if ([
            CupertinoIcons.pencil,
            CupertinoIcons.pin_fill,
            CupertinoIcons.pin_slash_fill,
            CupertinoIcons.eye_fill, // Unhide
            CupertinoIcons.eye_slash_fill, // Hide
          ].contains(actionIcon)) {
        swipeOffset = const Offset(400.0, 0.0); // Swipe Right
        debugPrint('[Test Action] Swiping Right to reveal start action pane');
      } else {
        swipeOffset = const Offset(-400.0, 0.0); // Swipe Left
        debugPrint('[Test Action] Swiping Left to reveal end action pane');
      }

      await tester.drag(itemFinder, swipeOffset);
      await tester.pumpAndSettle(); // Wait for animation

      // Find the specific action button within the Slidable's action pane
      final actionButtonFinder = find.widgetWithIcon(SlidableAction, actionIcon);
      expect(
        actionButtonFinder,
        findsOneWidget,
        reason: '"$actionLabel" action button (Icon: $actionIcon) not found after slide',
      );

      // Tap the action button
      await tester.tap(actionButtonFinder);
      await tester.pumpAndSettle(); // Wait for action and list update
      debugPrint('[Test Action] Tapped "$actionLabel" action.');
    }

    // Helper function to tap a quick filter segment
    Future<void> tapQuickFilter(WidgetTester tester, String filterKey) async {
      debugPrint('[Test Action] Tapping quick filter: "$filterKey"');
      // Find the segmented control
      final segmentedControlFinder = find.byType(CupertinoSlidingSegmentedControl);
      expect(segmentedControlFinder, findsOneWidget, reason: 'CupertinoSlidingSegmentedControl not found');

      // Find the specific segment. We might need to find by text within the segment.
      // The keys map to widgets, often containing Text. Find the Text widget.
      final segmentFinder = find.descendant(
        of: segmentedControlFinder,
        matching: find.text(
          // Get the label from the presets map defined in filter_providers.dart
          // This assumes the test environment can access that map or has a local copy.
          // For simplicity, let's hardcode expected labels for now.
          // TODO: Refactor to use the actual preset map if possible.
          {
            'inbox': 'Inbox',
            'today': 'Today',
            'tagged': 'Tagged',
            'all': 'All',
            'hidden': 'Hidden',
          }[filterKey] ??
              'Unknown', // Fallback label
        ),
      );

      // It's possible the Text widget itself isn't tappable, but its parent is.
      // Find the tappable ancestor within the segmented control.
      final tappableSegmentFinder = find.ancestor(
        of: segmentFinder,
        matching: find.byWidgetPredicate(
          (widget) => widget is GestureDetector || widget is CupertinoButton, // Common tappable widgets
        ),
      ).first; // Assume the first tappable ancestor is the one we want

      expect(
        tappableSegmentFinder,
        findsOneWidget,
        reason: 'Segment for filter "$filterKey" not found or not tappable',
      );

      await tester.tap(tappableSegmentFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500)); // Extra wait
      debugPrint('[Test Action] Quick filter "$filterKey" tapped.');
    }

    // --- Setup ---
    setUpAll(() async {
      // Launch the app once for all tests in this group
      app.main();
      // Allow time for the app to initialize, load initial data, etc.
      // Increased initial wait time
      await Future.delayed(const Duration(seconds: 5));

      // Create test notes programmatically
      debugPrint('[Test Setup] Creating test notes...');
      final noteVisible = await createNote(tester, noteVisibleContent);
      final noteToHide = await createNote(tester, noteToHideContent);
      final noteFuture = await createNote(
        tester,
        noteFutureContent,
        startDate: futureStartDate,
      );
      final notePinned = await createNote(
        tester,
        notePinnedContent,
        pinned: true,
      );

      expect(noteVisible, isNotNull, reason: 'Failed to create visible note');
      expect(noteToHide, isNotNull, reason: 'Failed to create note to hide');
      expect(noteFuture, isNotNull, reason: 'Failed to create future note');
      expect(notePinned, isNotNull, reason: 'Failed to create pinned note');

      noteVisibleId = noteVisible!.id;
      noteToHideId = noteToHide!.id;
      noteFutureId = noteFuture!.id;
      notePinnedId = notePinned!.id;

      debugPrint('[Test Setup] Test notes created. Performing initial refresh...');

      // Initial refresh to load created notes
      final listFinder = find.byType(Scrollable).first;
      expect(listFinder, findsOneWidget, reason: 'Scrollable list not found for initial refresh');
      await tester.fling(listFinder, const Offset(0.0, 400.0), 1000.0);
      await tester.pumpAndSettle(const Duration(seconds: 3));
      debugPrint('[Test Setup] Initial refresh complete.');
    });

    // --- Teardown ---
    tearDownAll(() async {
      if (createdNoteIds.isNotEmpty) {
        debugPrint(
          '[Test Cleanup] Deleting ${createdNoteIds.length} test notes...',
        );
        final apiService = ApiService();
        try {
          await Future.wait(
            createdNoteIds.map((id) => apiService.deleteMemo(id)), // Assuming deleteMemo works for notes
          );
          debugPrint('[Test Cleanup] Successfully deleted test notes.');
        } catch (e) {
          debugPrint('[Test Cleanup] Error deleting test notes: $e');
        }
        createdNoteIds.clear();
      } else {
        debugPrint('[Test Cleanup] No test notes to delete.');
      }
    });

    // --- Test Cases ---

    testWidgets('Manually Hiding and Viewing in Hidden Tab', (tester) async {
      // Arrange: Start in 'All' view (or default)
      await tapQuickFilter(tester, 'all');
      final noteToHideFinder = findNoteListItemWithText(noteToHideContent);
      final noteVisibleFinder = findNoteListItemWithText(noteVisibleContent);

      // Assert initial state
      expect(noteToHideFinder, findsOneWidget, reason: 'Note to hide should be visible initially');
      expect(noteVisibleFinder, findsOneWidget, reason: 'Visible note should be visible initially');

      // Act: Hide the note
      await performSlideAction(
        tester,
        noteToHideFinder,
        CupertinoIcons.eye_slash_fill,
        'Hide',
      );

      // Assert: Note is hidden in 'All' view
      expect(noteToHideFinder, findsNothing, reason: 'Note should be hidden after Hide action');
      expect(noteVisibleFinder, findsOneWidget, reason: 'Visible note should remain visible');

      // Act: Switch to 'Hidden' view
      await tapQuickFilter(tester, 'hidden');

      // Assert: Notes in 'Hidden' view
      final noteToHideFinderHidden = findNoteListItemWithText(noteToHideContent);
      final noteFutureFinderHidden = findNoteListItemWithText(noteFutureContent);
      final noteVisibleFinderHidden = findNoteListItemWithText(noteVisibleContent);
      final unhideAllButtonFinder = find.widgetWithText(CupertinoButton, 'Unhide All Manually Hidden'); // Adjust text if needed

      expect(noteToHideFinderHidden, findsOneWidget, reason: 'Manually hidden note should be in Hidden view');
      expect(noteFutureFinderHidden, findsOneWidget, reason: 'Future note should be in Hidden view');
      expect(noteVisibleFinderHidden, findsNothing, reason: 'Visible note should NOT be in Hidden view');
      expect(unhideAllButtonFinder, findsOneWidget, reason: '"Unhide All" button should be visible');

      // Cleanup for next test (Unhide the note)
      await performSlideAction(
        tester,
        noteToHideFinderHidden,
        CupertinoIcons.eye_fill, // Unhide action
        'Unhide',
      );
      expect(noteToHideFinderHidden, findsNothing, reason: 'Note should disappear after Unhide');
    });

    testWidgets('Future-Dated Note Visibility', (tester) async {
      // Arrange: Start in 'All' view
      await tapQuickFilter(tester, 'all');
      final noteFutureFinderAll = findNoteListItemWithText(noteFutureContent);
      final noteVisibleFinderAll = findNoteListItemWithText(noteVisibleContent);

      // Assert: Future note not visible in 'All' (assuming default hide)
      // This depends on showHiddenNotesProvider default being false
      expect(noteFutureFinderAll, findsNothing, reason: 'Future note should NOT be visible in All view by default');
      expect(noteVisibleFinderAll, findsOneWidget, reason: 'Visible note should be in All view');

      // Act: Switch to 'Hidden' view
      await tapQuickFilter(tester, 'hidden');

      // Assert: Future note is visible in 'Hidden' view
      final noteFutureFinderHidden = findNoteListItemWithText(noteFutureContent);
      final noteVisibleFinderHidden = findNoteListItemWithText(noteVisibleContent);

      expect(noteFutureFinderHidden, findsOneWidget, reason: 'Future note SHOULD be visible in Hidden view');
      expect(noteVisibleFinderHidden, findsNothing, reason: 'Visible note should NOT be in Hidden view');
    });

    testWidgets('Unhiding Manually Hidden Note from Hidden Tab', (tester) async {
      // Arrange: Hide a note and go to Hidden view
      await tapQuickFilter(tester, 'all');
      final noteToHideFinderAll = findNoteListItemWithText(noteToHideContent);
      await performSlideAction(tester, noteToHideFinderAll, CupertinoIcons.eye_slash_fill, 'Hide');
      await tapQuickFilter(tester, 'hidden');
      final noteToHideFinderHidden = findNoteListItemWithText(noteToHideContent);
      expect(noteToHideFinderHidden, findsOneWidget, reason: 'Note should be in Hidden view before unhide');

      // Act: Unhide the note from Hidden view
      await performSlideAction(tester, noteToHideFinderHidden, CupertinoIcons.eye_fill, 'Unhide');

      // Assert: Note disappears from Hidden view
      expect(noteToHideFinderHidden, findsNothing, reason: 'Note should disappear from Hidden view after Unhide');

      // Act: Switch back to 'All' view
      await tapQuickFilter(tester, 'all');

      // Assert: Note reappears in 'All' view
      final noteToHideFinderAllAfter = findNoteListItemWithText(noteToHideContent);
      expect(noteToHideFinderAllAfter, findsOneWidget, reason: 'Note should reappear in All view after Unhide');
    });

    testWidgets('"Unhide All" Button Functionality', (tester) async {
      // Arrange: Hide a note, go to Hidden view
      await tapQuickFilter(tester, 'all');
      final noteToHideFinderAll = findNoteListItemWithText(noteToHideContent);
      await performSlideAction(tester, noteToHideFinderAll, CupertinoIcons.eye_slash_fill, 'Hide');
      await tapQuickFilter(tester, 'hidden');

      final noteToHideFinderHidden = findNoteListItemWithText(noteToHideContent);
      final noteFutureFinderHidden = findNoteListItemWithText(noteFutureContent);
      final unhideAllButtonFinder = find.widgetWithText(CupertinoButton, 'Unhide All Manually Hidden'); // Adjust text if needed

      expect(noteToHideFinderHidden, findsOneWidget, reason: 'Manually hidden note should be present');
      expect(noteFutureFinderHidden, findsOneWidget, reason: 'Future note should be present');
      expect(unhideAllButtonFinder, findsOneWidget, reason: '"Unhide All" button should be visible');

      // Act: Tap "Unhide All" and confirm dialog
      await tester.tap(unhideAllButtonFinder);
      await tester.pumpAndSettle();

      // Find and tap confirmation button in the dialog
      final dialogConfirmButton = find.widgetWithText(CupertinoDialogAction, 'Unhide All');
      expect(dialogConfirmButton, findsOneWidget, reason: 'Unhide All confirmation button not found in dialog');
      await tester.tap(dialogConfirmButton);
      await tester.pumpAndSettle(); // Wait for dialog dismiss and list update

      // Assert: Manually hidden note gone, future note remains in Hidden view
      // The view might switch automatically, or stay on Hidden. Test both possibilities.
      // Let's assume it stays on Hidden for now unless implementation changes.
      expect(noteToHideFinderHidden, findsNothing, reason: 'Manually hidden note should be gone after Unhide All');
      expect(noteFutureFinderHidden, findsOneWidget, reason: 'Future note should remain after Unhide All');

      // Assert: Check 'All' view
      await tapQuickFilter(tester, 'all');
      final noteToHideFinderAllAfter = findNoteListItemWithText(noteToHideContent);
      expect(noteToHideFinderAllAfter, findsOneWidget, reason: 'Manually hidden note should reappear in All view after Unhide All');
    });

    // Optional: Add test for search interaction if needed
    // testWidgets('Interaction with Search in Hidden Tab', (tester) async { ... });

  });
}
