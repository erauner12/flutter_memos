import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Global control flag for debug logs in markdown tests
bool markdownDebugEnabled = true;  // Changed from false to true to enable debugging by default

/// Print debug info only when markdown debugging is enabled
void debugMarkdown(String message) {
  if (markdownDebugEnabled) {
    debugPrint('[Markdown Test] $message');
  }
}

/// Temporarily enable markdown debugging for a specific test
void withMarkdownDebug(Function() testFunction) {
  final oldValue = markdownDebugEnabled;
  markdownDebugEnabled = true;
  try {
    testFunction();
  } finally {
    markdownDebugEnabled = oldValue;
  }
}

/// Use this to wrap any verbose debug operations
void debugDumpAppIfEnabled() {
  if (markdownDebugEnabled) {
    debugPrint('=== WIDGET TREE DUMP ===');
    debugDumpRenderTree();
    debugPrint('=== LAYER TREE DUMP ===');
    debugDumpLayerTree();
    debugPrint('=== SEMANTICS TREE DUMP ===');
    debugDumpSemanticsTree();
  }
}

/// Helper function to find text in RichText widgets
/// Returns true if any RichText widget contains the specified text
bool findTextInRichText(WidgetTester tester, String text) {
  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));

  for (final widget in richTextWidgets) {
    if (widget.text.toPlainText().contains(text)) {
      return true;
    }
  }

  return false;
}

/// Helper function that finds and returns a RichText widget containing the specified text
RichText? findRichTextWithText(WidgetTester tester, String text) {
  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));

  for (final widget in richTextWidgets) {
    if (widget.text.toPlainText().contains(text)) {
      return widget;
    }
  }

  return null;
}

/// Dumps all RichText content to the console when debugging is enabled
void dumpRichTextContent(WidgetTester tester) {
  if (!markdownDebugEnabled) return;

  final richTextWidgets = tester.widgetList<RichText>(find.byType(RichText));
  debugMarkdown("Found ${richTextWidgets.length} RichText widgets:");

  int index = 0;
  for (final widget in richTextWidgets) {
    debugMarkdown("[$index] - '${widget.text.toPlainText()}'");
    index++;
  }
}