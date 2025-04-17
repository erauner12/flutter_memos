import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A mixin for consistent keyboard navigation handling across the app
mixin KeyboardNavigationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Checks if the currently focused node belongs to a text input widget.
  bool _isTextInputFocused([FocusNode? primaryFocus]) {
    final focusNode = primaryFocus ?? FocusManager.instance.primaryFocus;
    if (focusNode == null ||
        !focusNode.hasPrimaryFocus ||
        focusNode.context == null) {
      if (kDebugMode) print('[_isTextInputFocused] No primary focus or context.');
      return false;
    }

    // Get the BuildContext and associated Widget/RenderObject
    final BuildContext? context = focusNode.context;
    final Widget? widget = context?.widget;
    final RenderObject? renderObject = context?.findRenderObject();

    if (kDebugMode) {
      print(
        '[_isTextInputFocused] Checking Node: $focusNode, Context: ${context?.runtimeType}, Widget: ${widget?.runtimeType}, RenderObject: ${renderObject?.runtimeType}',
      );
    }

    // Check common text input widgets directly (Cupertino and general)
    if (widget is EditableText || widget is CupertinoTextField) {
      if (kDebugMode) {
        print(
          '[KeyboardNavigation] Focused widget IS an EditableText/CupertinoTextField.',
        );
      }
      return true;
    }

    // Check the render object type as a fallback
    // RenderEditable is used by both Material and Cupertino text fields internally
    if (renderObject is RenderEditable) {
      if (kDebugMode) {
        print('[KeyboardNavigation] Focused RenderObject IS RenderEditable.');
      }
      return true;
    }

    // Check semantics as another fallback
    try {
      final semanticsNode = renderObject?.debugSemantics;
      if (semanticsNode != null &&
          (semanticsNode.hasFlag(SemanticsFlag.isTextField) ||
              semanticsNode.hasFlag(SemanticsFlag.isObscured))) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Semantics indicate text field.');
        }
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('[KeyboardNavigation] Error checking semantics: $e');
    }

    // If direct checks fail, traverse up to see if an ancestor is a text field
    // This handles cases where focus might be on an internal helper widget
    bool isTextInputAncestor = false;
    if (context is Element) { // Ensure context is an Element before visiting ancestors
      context.visitAncestorElements((ancestor) {
        // Check for CupertinoTextField or the general EditableText
        if (ancestor.widget is CupertinoTextField ||
            ancestor.widget is EditableText) {
          if (kDebugMode) print('[KeyboardNavigation] Found text input ancestor: ${ancestor.widget.runtimeType}');
          isTextInputAncestor = true;
          return false; // Stop traversal
        }
        return true; // Continue traversal
      });
    } else if (kDebugMode) {
      print('[KeyboardNavigation] Context is not an Element, cannot visit ancestors.');
    }

    if (isTextInputAncestor) {
      return true;
    }

    if (kDebugMode) {
      print(
        '[_isTextInputFocused] Focused widget/ancestor is not recognized as text input.',
      );
    }

    return false; // Default to false if no text input found
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

    // Check if text input is focused *first*
    final bool isTextFocused = _isTextInputFocused();

    // Handle specific shortcuts that might apply regardless of text focus
    // Escape: Always trigger onEscape if provided, otherwise unfocus if text focused
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (onEscape != null) {
        if (kDebugMode) {
          print(
            '[KeyboardNavigation] Processing ESCAPE command (custom handler)',
          );
        }
        onEscape();
        return KeyEventResult.handled;
      } else if (isTextFocused) {
        if (kDebugMode) {
          print(
            '[KeyboardNavigation] Processing ESCAPE command (default unfocus)',
          );
        }
        FocusManager.instance.primaryFocus?.unfocus();
        return KeyEventResult.handled;
      }
      // If onEscape is null and text is not focused, let it bubble up or ignore
    }

    // Cmd+Enter: Always trigger onSubmit if provided
    if (event.logicalKey == LogicalKeyboardKey.enter &&
        (HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.meta,
            ) ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.metaLeft,
            ) ||
            HardwareKeyboard.instance.isLogicalKeyPressed(
              LogicalKeyboardKey.metaRight,
            ))) {
      if (onSubmit != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing SUBMIT command (Cmd+Enter)');
        }
        onSubmit();
        return KeyEventResult.handled;
      }
    }

    // *** Critical Change: If text is focused, ignore all other keys ***
    if (isTextFocused) {
      // Allow the TextField's default handlers for character input, arrows, etc.
      if (kDebugMode) {
        print(
          '[KeyboardNavigation] Text input focused, ignoring event: ${event.logicalKey.keyLabel}',
        );
      }
      return KeyEventResult.ignored;
    }

    // *** If text is NOT focused, handle navigation and other actions ***

    // Navigate up (previous item) with Up arrow
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (onUp != null) {
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing UP navigation');
        }
        onUp();
        return KeyEventResult.handled;
      }
    }
    // Navigate down (next item) with Down arrow
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
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing BACK navigation');
        }
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
        if (kDebugMode) {
          print('[KeyboardNavigation] Processing FORWARD navigation');
        }
        onForward();
        return KeyEventResult.handled;
      }
    }
    // Handle plain Enter (without Cmd) for submission when *not* in text field
    else if (event.logicalKey == LogicalKeyboardKey.enter && onSubmit != null) {
      if (kDebugMode) {
        print('[KeyboardNavigation] Processing SUBMIT command (Plain Enter)');
      }
      onSubmit();
      return KeyEventResult.handled;
    }

    // If no specific handling matched, ignore the event
    if (kDebugMode) {
      print(
        '[KeyboardNavigation] Ignoring unhandled event: ${event.logicalKey.keyLabel}',
      );
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
