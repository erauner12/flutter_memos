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
  }) {
    // Only handle key down events to avoid duplicate handling
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    
    if (kDebugMode) {
      print(
        '[KeyboardNavigation] Received key event: ${event.logicalKey.keyLabel}',
      );
    }
    
    // If any text input is focused, ignore navigation keys
    if (_isTextInputFocused()) {
      if (kDebugMode) {
        print('[KeyboardNavigation] Ignoring navigation keys in text input');
      }
      
      // Only handle Command+Enter for submission even when text input is focused
      if (event.logicalKey == LogicalKeyboardKey.enter &&
          HardwareKeyboard.instance.isLogicalKeyPressed(
            LogicalKeyboardKey.meta,
          )) {
        if (onSubmit != null) {
          onSubmit();
          return KeyEventResult.handled;
        }
      }
      
      return KeyEventResult.ignored;
    }
    
    // Navigate up (previous item) - Shift+Up
    if (event.logicalKey == LogicalKeyboardKey.arrowUp &&
        HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.shift,
        )) {
      if (onUp != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing UP navigation');
        }
        onUp();
        return KeyEventResult.handled;
      }
    }
    
    // Navigate down (next item) - Shift+Down
    else if (event.logicalKey == LogicalKeyboardKey.arrowDown &&
        HardwareKeyboard.instance.isLogicalKeyPressed(
          LogicalKeyboardKey.shift,
        )) {
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
          (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta) ||
           HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.alt))) {
      if (onBack != null) {
        onBack();
        return KeyEventResult.handled;
      }
    }
    
    // Navigate forward - Command+Right (macOS) or Alt+Right (Windows/Linux)
    else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
          (HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta) ||
           HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.alt))) {
      if (onForward != null) {
        onForward();
        return KeyEventResult.handled;
      }
    }
    
    // Submit - Command+Enter
    else if (event.logicalKey == LogicalKeyboardKey.enter &&
           HardwareKeyboard.instance.isLogicalKeyPressed(LogicalKeyboardKey.meta)) {
      if (onSubmit != null) {
        onSubmit();
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
