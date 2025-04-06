import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A mixin for consistent keyboard navigation handling across the app
mixin KeyboardNavigationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Check if the current focus is on a text input field
  bool _isTextInputFocused() {
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode == null) return false;

    // Check if the widget type suggests it's a text input
    final widget = focusNode.context?.widget;
    if (widget == null) return false;

    // Check for EditableText or TextField or TextFormField or any input-related widgets
    final typeStr = widget.runtimeType.toString().toLowerCase();
    final isTextInput =
        typeStr.contains('text') ||
        typeStr.contains('edit') ||
        typeStr.contains('field') ||
        typeStr.contains('input') ||
        widget is EditableText ||
        widget is TextField ||
        widget is TextFormField;

    if (isTextInput && kDebugMode) {
      print('[KeyboardNavigation] Text input focused: $typeStr');
    }

    return isTextInput;
  }

  /// Handle a key event with standard navigation shortcuts
  KeyEventResult handleKeyEvent(KeyEvent event, WidgetRef ref, {
    VoidCallback? onUp,
    VoidCallback? onDown,
    VoidCallback? onBack,
    VoidCallback? onForward,
    VoidCallback? onSubmit,
    VoidCallback? onEscape,
  }) {
    // Only handle key down events to avoid duplicate handling
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    
    if (kDebugMode) {
      print(
        '[KeyboardNavigation] Received key event: ${event.logicalKey.keyLabel}',
      );
    }
    
    // Always handle Command+Enter for submission regardless of focus
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta)) {
      if (onSubmit != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing SUBMIT command');
        }
        onSubmit();
        return KeyEventResult.handled;
      }
    }
    
    // Always handle Escape key to exit text input focus
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (onEscape != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing ESCAPE command');
        }
        onEscape();
        return KeyEventResult.handled;
      }
      
      // Default behavior: unfocus current focus node
      if (_isTextInputFocused()) {
        FocusManager.instance.primaryFocus?.unfocus();
        return KeyEventResult.handled;
      }
    }
    
    // If any text input is focused, ignore other navigation keys
    if (_isTextInputFocused()) {
      if (kDebugMode) {
        print('[KeyboardNavigation] Ignoring navigation keys in text input');
      }
      return KeyEventResult.ignored;
    }
    
    // Navigate up (previous item) with BOTH Shift+Up OR plain Up arrow
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (onUp != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing UP navigation');
        }
        onUp();
        return KeyEventResult.handled;
      }
    }
    
    // Navigate down (next item) with BOTH Shift+Down OR plain Down arrow
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (onDown != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing DOWN navigation');
        }
        onDown();
        return KeyEventResult.handled;
      }
    }
    
    // Navigate back - Command+Left (macOS) or Alt+Left (Windows/Linux)
    else if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
        (HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.meta,
            ) ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.alt,
            ))) {
      if (onBack != null) {
        onBack();
        return KeyEventResult.handled;
      }
    }
    
    // Navigate forward - Command+Right (macOS) or Alt+Right (Windows/Linux)
    else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
        (HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.meta,
            ) ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.alt,
            ))) {
      if (onForward != null) {
        onForward();
        return KeyEventResult.handled;
      }
    }
    
    return KeyEventResult.ignored;
  }
  
  /// Helper method to select the next item in a list
  int getNextIndex(int currentIndex, int itemCount) {
    if (itemCount == 0) return -1;
    return currentIndex < 0 ? 0 : (currentIndex + 1) % itemCount;
  }
  
  /// Helper method to select the previous item in a list
  int getPreviousIndex(int currentIndex, int itemCount) {
    if (itemCount == 0) return -1;
    return currentIndex < 0
        ? itemCount - 1
        : (currentIndex - 1 + itemCount) % itemCount;
  }
}
