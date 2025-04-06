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
  final focusNode = Focus.of(tester.element(textFieldFinder)).focusNode;
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
  await tester.sendKeyDownEvent(
    key,
    isControlPressed: isControlPressed,
    isShiftPressed: isShiftPressed,
    isAltPressed: isAltPressed,
    isMetaPressed: isMetaPressed,
  );
  
  // Wait for key down event to be processed
  await tester.pump(const Duration(milliseconds: 50));
  
  await tester.sendKeyUpEvent(
    key,
    isControlPressed: isControlPressed,
    isShiftPressed: isShiftPressed,
    isAltPressed: isAltPressed,
    isMetaPressed: isMetaPressed,
  );
  
  // Wait for key up event to be processed
  await tester.pump(const Duration(milliseconds: 50));
  
  // Final pump to ensure all event handlers have completed
  await tester.pumpAndSettle();
}
