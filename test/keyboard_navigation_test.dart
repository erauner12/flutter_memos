import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_memos/utils/keyboard_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple consumer stateful widget for testing
class TestKeyboardNavigationWidget extends ConsumerStatefulWidget {
  const TestKeyboardNavigationWidget({super.key});
  
  @override
  TestKeyboardNavigationState createState() => TestKeyboardNavigationState();
}

class TestKeyboardNavigationState
    extends ConsumerState<TestKeyboardNavigationWidget>
    with KeyboardNavigationMixin {
  
  int nextCalled = 0;
  int prevCalled = 0;
  int backCalled = 0;
  int forwardCalled = 0;
  
  void onNext() => nextCalled++;
  void onPrev() => prevCalled++;
  void onBack() => backCalled++;
  void onForward() => forwardCalled++;
  
  KeyEventResult testHandleKeyEvent(KeyEvent event) {
    return handleKeyEvent(
      event,
      ref,
      onUp: onPrev,
      onDown: onNext,
      onBack: onBack,
      onForward: onForward,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Container();
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

    test('selectedCommentIndexProvider starts at -1', () {
      final index = container.read(selectedCommentIndexProvider);
      expect(index, equals(-1));
    });

    test('selectedCommentIndexProvider can be updated', () {
      // Start at -1
      final initialIndex = container.read(selectedCommentIndexProvider);
      expect(initialIndex, equals(-1));

      // Set to 2
      container.read(selectedCommentIndexProvider.notifier).state = 2;
      final updatedIndex = container.read(selectedCommentIndexProvider);
      expect(updatedIndex, equals(2));
    });

    test('selectedMemoIndexProvider starts at -1', () {
      final index = container.read(selectedMemoIndexProvider);
      expect(index, equals(-1));
    });

    test('selectedMemoIndexProvider can be updated', () {
      // Start at -1
      final initialIndex = container.read(selectedMemoIndexProvider);
      expect(initialIndex, equals(-1));

      // Set to 3
      container.read(selectedMemoIndexProvider.notifier).state = 3;
      final updatedIndex = container.read(selectedMemoIndexProvider);
      expect(updatedIndex, equals(3));
    });
  });
  
  group('KeyboardNavigationMixin Tests', () {
    late GlobalKey<TestKeyboardNavigationState> testKey;
    late ProviderScope providerScope;
    
    setUp(() {
      testKey = GlobalKey<TestKeyboardNavigationState>();
      providerScope = ProviderScope(
        child: MaterialApp(home: TestKeyboardNavigationWidget(key: testKey),
        ),
      );
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
    
    testWidgets('key events handled correctly', (WidgetTester tester) async {
      await tester.pumpWidget(providerScope);
      
      final state = testKey.currentState!;
      final Duration testTimestamp = const Duration(milliseconds: 10);
      
      // Test J key
      final jKeyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyJ,
        logicalKey: LogicalKeyboardKey.keyJ,
        timeStamp: testTimestamp,
      );
      state.testHandleKeyEvent(jKeyEvent);
      expect(state.nextCalled, equals(1));
      expect(state.prevCalled, equals(0));
      
      // Test K key
      final kKeyEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.keyK,
        logicalKey: LogicalKeyboardKey.keyK,
        timeStamp: testTimestamp,
      );
      state.testHandleKeyEvent(kKeyEvent);
      expect(state.nextCalled, equals(1));
      expect(state.prevCalled, equals(1));
      
      // Test Shift+Down using KeyDownEvent with proper initialization
      final shiftDownEvent = KeyDownEvent(
        physicalKey: PhysicalKeyboardKey.arrowDown,
        logicalKey: LogicalKeyboardKey.arrowDown,
        timeStamp: testTimestamp,
        // Use the keyboard object to represent the state of modifiers
        character: null,
        synthesized: false,
      );
      
      // Set the keyboard state for testing
      ServicesBinding.instance.keyboard.handleKeyEvent({
        "type": "keydown",
        "keymap": "web",
        "code": "ShiftLeft",
        "key": "Shift",
        "location": 1,
        "metaState": 1, // Shift pressed
        "keyCode": 16,
      });
      
      state.testHandleKeyEvent(shiftDownEvent);
      expect(state.nextCalled, equals(2));
      
      // Reset keyboard state
      ServicesBinding.instance.keyboard.clearState();
    });
  });
}
