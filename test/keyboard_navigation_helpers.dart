import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper function to focus a text field and wait for it to properly accept focus
/// before sending keyboard events
Future<void> focusTextFieldAndWait(
  WidgetTester tester,
  Finder textFieldFinder,
) async {
  // Focus the text field
  await tester.tap(textFieldFinder);
  
  // Pump once to start processing the focus request
  await tester.pump();
  
  // Add a small delay to ensure the focus is properly established
  // before proceeding with keyboard events
  await tester.pump(const Duration(milliseconds: 200));
  
  // Final pump to ensure all animations and focus changes are complete
  await tester.pumpAndSettle();
  
  // Verify that the text field has focus
  final focusNode = Focus.of(tester.element(textFieldFinder));
  expect(focusNode.hasFocus, isTrue, reason: 'Text field should have focus');
}

/// Helper to send a keyboard event and properly wait for it to be processed
Future<void> sendKeyEventAndWait(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool isControlPressed = false,
  bool isShiftPressed = false,
  bool isAltPressed = false,
  bool isMetaPressed = false,
}) async {
  // Press modifier keys first if needed
  if (isControlPressed) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await tester.pump(const Duration(milliseconds: 20));
  }
  
  if (isShiftPressed) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
    await tester.pump(const Duration(milliseconds: 20));
  }

  if (isAltPressed) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.alt);
    await tester.pump(const Duration(milliseconds: 20));
  }

  if (isMetaPressed) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 20));
  }

  // Send main key down event
  await tester.sendKeyDownEvent(key);
  await tester.pump(const Duration(milliseconds: 50));

  // Send main key up event
  await tester.sendKeyUpEvent(key);
  await tester.pump(const Duration(milliseconds: 50));
  
  // Release modifier keys in reverse order
  if (isMetaPressed) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump(const Duration(milliseconds: 20));
  }

  if (isAltPressed) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.alt);
    await tester.pump(const Duration(milliseconds: 20));
  }

  if (isShiftPressed) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
    await tester.pump(const Duration(milliseconds: 20));
  }
  
  if (isControlPressed) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
    await tester.pump(const Duration(milliseconds: 20));
  }
  
  // Final pump to ensure all event handlers have completed
  await tester.pumpAndSettle();
}
