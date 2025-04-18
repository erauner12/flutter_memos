import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/services.dart';
// add the ui_providers.dart import
// lib/providers/ui_providers.dart
import 'package:flutter_memos/providers/ui_providers.dart' as ui_providers;
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Import helper
import './utils/keyboard_navigation_helpers.dart'; // Corrected path

// Simple consumer stateful widget for testing
class TestKeyboardNavigationWidget extends ConsumerStatefulWidget {
  const TestKeyboardNavigationWidget({super.key});
  
  @override
  TestKeyboardNavigationState createState() => TestKeyboardNavigationState();
}

class TestKeyboardNavigationState
    extends ConsumerState<TestKeyboardNavigationWidget>
    with KeyboardNavigationMixin<TestKeyboardNavigationWidget> {
  
  int nextCalled = 0;
  int prevCalled = 0;
  int backCalled = 0;
  int forwardCalled = 0;
  int submitCalled = 0;
  int escapeCalled = 0;
  
  void onNext() => nextCalled++;
  void onPrev() => prevCalled++;
  void onBack() => backCalled++;
  void onForward() => forwardCalled++;
  void onSubmit() => submitCalled++;
  void onEscape() => escapeCalled++;
  
  KeyEventResult testHandleKeyEvent(KeyEvent event) {
    return handleKeyEvent(
      event,
      ref,
      onUp: onPrev,
      onDown: onNext,
      onBack: onBack,
      onForward: onForward,
      onSubmit: onSubmit,
      onEscape: onEscape,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Return a basic Cupertino widget instead of Container
    return const SizedBox.shrink();
  }
  
  // Expose the helper methods for testing
  int testGetNextIndex(int current, int total) => getNextIndex(current, total);
  int testGetPreviousIndex(int current, int total) =>
      getPreviousIndex(current, total);
}

void main() {
  group('Keyboard Navigation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('selectedItemIdProvider can be updated', () {
      // Reset selection before each test
      container.read(ui_providers.selectedItemIdProvider.notifier).state = null;
      
      // Test initial state (null)
      final initialId = container.read(selectedItemIdProvider);
      expect(initialId, isNull);

      // Set to some test ID
      const testItemId = 'test-item-123';
      container.read(selectedItemIdProvider.notifier).state = testItemId;
      final updatedId = container.read(selectedItemIdProvider);
      expect(updatedId, equals(testItemId));
    });

    // Test removed as selectedMemoIdProvider is deprecated and removed
    // test('selectedMemoIdProvider can be updated', () { ... });
  });
  
  group('KeyboardNavigationMixin Tests', () {
    late GlobalKey<TestKeyboardNavigationState> testKey;
    late ProviderScope providerScope;
    late FocusNode testTextFieldFocusNode; // Declare FocusNode
    
    setUp(() {
      testKey = GlobalKey<TestKeyboardNavigationState>();
      testTextFieldFocusNode = FocusNode(); // Instantiate FocusNode
      providerScope = ProviderScope(
        // Use CupertinoApp and CupertinoPageScaffold
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: Column(
              children: [
                CupertinoTextField(
                  // Use CupertinoTextField
                  key: const Key('testTextField'),
                  focusNode: testTextFieldFocusNode, // Assign FocusNode
                  placeholder: 'Test Input', // Add placeholder
                ),
                TestKeyboardNavigationWidget(key: testKey),
              ],
            ),
          ),
        ),
      );
    });

    tearDown(() {
      testTextFieldFocusNode.dispose(); // Dispose FocusNode
    });

    testWidgets('next/previous index calculation works correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(providerScope);
      
      final state = testKey.currentState!;
      
      // Next index tests
      expect(state.testGetNextIndex(-1, 5), equals(0)); // Initial selection
      expect(state.testGetNextIndex(0, 5), equals(1)); // Normal increment
      expect(state.testGetNextIndex(4, 5), equals(0)); // Wrap around to start
      expect(state.testGetNextIndex(0, 0), equals(-1)); // Empty list
      
      // Previous index tests
      expect(state.testGetPreviousIndex(-1, 5), equals(4)); // Initial selection
      expect(state.testGetPreviousIndex(2, 5), equals(1)); // Normal decrement
      expect(state.testGetPreviousIndex(0, 5), equals(4)); // Wrap around to end
      expect(state.testGetPreviousIndex(0, 0), equals(-1)); // Empty list
    });
    
    testWidgets('arrow key events handled correctly when not in text input', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(providerScope);
      
      final state = testKey.currentState!;
      final Duration testTimestamp = const Duration(milliseconds: 10);
      
      // Properly set up HardwareKeyboard to recognize shift as pressed
      HardwareKeyboard.instance.addHandler((KeyEvent event) => false);
      
      // Simulate shift key being pressed
      ServicesBinding.instance.keyboard.handleKeyEvent(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.shiftLeft,
          logicalKey: LogicalKeyboardKey.shift,
          timeStamp: testTimestamp,
        ),
      );
      
      // Test Shift+Down
      final shiftDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );
      
      state.testHandleKeyEvent(shiftDownEvent);
      expect(state.nextCalled, equals(1));
      expect(state.prevCalled, equals(0));
      
      // Test Shift+Up
      final shiftUpEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );
      
      state.testHandleKeyEvent(shiftUpEvent);
      expect(state.nextCalled, equals(1));
      expect(state.prevCalled, equals(1));
      
      // Verify that the callbacks *were* called (or adjust based on desired behavior)
      // The mixin might intentionally allow focus traversal from text fields.
      // If the desired behavior is truly to *ignore* nav keys in text fields,
      // the mixin or the calling widget's onKeyEvent handler needs adjustment.
      // For now, let's assume the current behavior is acceptable for the test.
      expect(
        state.nextCalled,
        greaterThanOrEqualTo(1),
        reason: 'nextCalled should be called',
      );
      expect(
        state.prevCalled,
        greaterThanOrEqualTo(1),
        reason: 'prevCalled should be called',
      );

      // If strict ignoring is needed, the test should be:
      // expect(state.nextCalled, 0, reason: 'nextCalled should not increase');
      // expect(state.prevCalled, 0, reason: 'prevCalled should not increase');
    });

    testWidgets('Command+Enter works regardless of text input focus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(providerScope);

      final state = testKey.currentState!;
      final Duration testTimestamp = const Duration(milliseconds: 10);

      // First, focus the text field
      await tester.tap(find.byKey(const Key('testTextField')));
      await tester.pump();

      // Simulate Command key being pressed
      ServicesBinding.instance.keyboard.handleKeyEvent(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.metaLeft,
          logicalKey: LogicalKeyboardKey.meta,
          timeStamp: testTimestamp,
        ),
      );

      // Test Command+Enter while text field is focused
      final commandEnterEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.enter,
        logicalKey: LogicalKeyboardKey.enter,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );

      state.testHandleKeyEvent(commandEnterEvent);
      expect(
        state.submitCalled,
        equals(1),
        reason: 'Submit should be called even with text input focus',
      );

      // Reset keyboard state
      ServicesBinding.instance.keyboard.clearState();
    });

    testWidgets('Escape key works to dismiss text input focus', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(providerScope);

      final state = testKey.currentState!;
      final Duration testTimestamp = const Duration(milliseconds: 10);

      // First, focus the text field
      await tester.tap(find.byKey(const Key('testTextField')));
      await tester.pump();

      // Test Escape key
      final escapeEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.escape,
        logicalKey: LogicalKeyboardKey.escape,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );

      state.testHandleKeyEvent(escapeEvent);
      expect(
        state.escapeCalled,
        equals(1),
        reason: 'Escape handler should be called',
      );

      // Reset keyboard state
      ServicesBinding.instance.keyboard.clearState();
    });

    testWidgets('navigation keys are ignored when text input is focused', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(providerScope);

      final state = testKey.currentState!;
      final Duration testTimestamp = const Duration(milliseconds: 10);
      final textFieldFinder = find.byKey(const Key('testTextField'));

      // First, focus the text field using the helper
      await focusTextFieldAndWait(tester, textFieldFinder);
      // Add extra debug log
      final primaryFocus = FocusManager.instance.primaryFocus;
      tester.printToConsole(
        '[Test Debug] Focus AFTER focusTextFieldAndWait: $primaryFocus, Widget: ${primaryFocus?.context?.widget.runtimeType}, RenderObject: ${primaryFocus?.context?.findRenderObject()?.runtimeType}',
      );

      // The initial count of navigation calls
      final initialNextCalled = state.nextCalled;
      final initialPrevCalled = state.prevCalled;

      // Simulate shift key being pressed
      ServicesBinding.instance.keyboard.handleKeyEvent(
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.shiftLeft,
          logicalKey: LogicalKeyboardKey.shift,
          timeStamp: testTimestamp,
        ),
      );
      
      // Test Shift+Down while text field is focused - should be ignored
      final shiftDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );
      
      // For debugging, use tester.printToConsole instead of print in tests
      tester.printToConsole(
        '[Test Debug] Focus before Shift+Down: ${FocusManager.instance.primaryFocus}',
      );
      final downResult = state.testHandleKeyEvent(shiftDownEvent);

      // Test Shift+Up while text field is focused - should be ignored
      final shiftUpEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowUp,
        logicalKey: LogicalKeyboardKey.arrowUp,
        timeStamp: testTimestamp,
        character: null,
        synthesized: false,
      );
      
      // For debugging, use tester.printToConsole instead of print in tests
      tester.printToConsole(
        '[Test Debug] Focus before Shift+Up: ${FocusManager.instance.primaryFocus}',
      );
      final upResult = state.testHandleKeyEvent(shiftUpEvent);

      // Verify navigation callbacks were NOT called because focus is on text input
      expect(
        state.nextCalled,
        equals(initialNextCalled),
        reason:
            'nextCalled should not increase when CupertinoTextField has focus',
      );
      expect(
        state.prevCalled,
        equals(initialPrevCalled),
        reason:
            'prevCalled should not increase when CupertinoTextField has focus',
      );

      // Verify the key events were correctly ignored by the mixin's handler
      expect(
        downResult,
        equals(KeyEventResult.ignored), // Correct expectation
        reason: 'Shift+Down should be ignored',
      );
      expect(
        upResult,
        equals(KeyEventResult.ignored), // Correct expectation
        reason: 'Shift+Up should be ignored',
      );
      
      // Reset keyboard state
      ServicesBinding.instance.keyboard.clearState();
    });
  });
}
