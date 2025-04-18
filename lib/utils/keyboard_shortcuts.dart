import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Defines all keyboard shortcut intents for the application
/// This centralizes our shortcut definitions in one place

// Define custom intents
class SubmitIntent extends Intent {}
class NavigateBackIntent extends Intent {}
class NavigateForwardIntent extends Intent {}
class SelectPreviousMemoIntent extends Intent {}
class SelectNextMemoIntent extends Intent {}
class ToggleCaptureUtilityIntent extends Intent {}
class NewMemoIntent extends Intent {}
class ToggleChatOverlayIntent extends Intent {
  // Define the new intent
  const ToggleChatOverlayIntent();
}

/// Creates a map of keyboard shortcuts to intents
Map<ShortcutActivator, Intent> buildGlobalShortcuts() {
  return {
    // Command + Enter => Submit
    const SingleActivator(LogicalKeyboardKey.enter, meta: true): SubmitIntent(),

    // Command + Left Arrow => Navigate Back
    const SingleActivator(LogicalKeyboardKey.arrowLeft, meta: true): NavigateBackIntent(),

    // Command + Right Arrow => Navigate Forward
    const SingleActivator(LogicalKeyboardKey.arrowRight, meta: true): NavigateForwardIntent(),

    // Support Shift+Up/Down for navigation
    const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true): SelectPreviousMemoIntent(),
    const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true): SelectNextMemoIntent(),

    // Command/Ctrl + Shift + M => Toggle Capture Utility
    const SingleActivator(LogicalKeyboardKey.keyM, meta: true, shift: true):
        ToggleCaptureUtilityIntent(),

    // Command/Ctrl + Shift + N => Create New Memo
    const SingleActivator(LogicalKeyboardKey.keyN, meta: true, shift: true):
        NewMemoIntent(),

    // Command/Ctrl + Shift + C => Toggle Chat Overlay (Example shortcut)
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true, shift: true):
        const ToggleChatOverlayIntent(),
  };
}
