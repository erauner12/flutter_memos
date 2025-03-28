# Flutter Memos Test Summary

This document provides a summary of the tests in the Flutter Memos project, focusing on the markdown-related functionality.

## Markdown Link Handling Tests

### `basic_links_test.dart`
- **MarkdownBody passes link tap events to callback**: Tests that tapping links properly calls the onTapLink callback with the correct URL.
- **Different link types are displayed correctly**: Verifies rendering of various link types (regular links, email links, phone links, custom scheme links).

### `memo_content_links_test.dart`
- **MemoContent handles link taps correctly**: Tests that links in memo content can be tapped and handled.
- **MemoContent handles different link types**: Verifies the rendering of different URL schemes (HTTP, HTTPS, memo://, etc).

### `special_link_schemes_test.dart`
- **UrlHelper parses and validates different URL schemes**: Tests URL scheme parsing and validation.
- **Custom scheme links render correctly and can be tapped**: Verifies that custom scheme links (memo://, tel:, etc) render properly.
- **UrlHelper._isCustomAppScheme identifies app schemes correctly**: Tests the custom app scheme detection logic.
- **Links with encoded characters render correctly**: Verifies that URLs with percent-encoded characters display properly.
- **Links with fragments and query parameters render correctly**: Tests links with URL fragments (#) and query parameters (?).

## Markdown Preview Tests

### `code_block_preview_test.dart`
- **Markdown code blocks are rendered with monospace font**: Verifies that code blocks use monospace styling.
- **Indented code blocks are properly rendered**: Tests the rendering of code blocks created with indentation.

### `edit_memo_preview_test.dart`
- **EditMemoForm markdown help toggle works**: Tests that the markdown help can be shown and hidden.
- **Live preview updates when content changes**: Verifies that changes to the content are reflected in the preview.
- **Toggle between edit and preview modes works correctly**: Tests switching between edit and preview modes.

### `link_styling_preview_test.dart`
- **Links in preview are styled correctly**: Tests that links are properly styled in preview mode.
- **Links with special characters render correctly**: Verifies that links with spaces, params, fragments render correctly.

### `new_memo_preview_test.dart`
- **Preview mode shows rendered markdown**: Tests that markdown is properly rendered in preview mode.
- **Markdown help toggle displays help information**: Verifies that markdown help can be shown/hidden.

## General Markdown Rendering Tests

### `markdown_rendering_test.dart`
- **Basic markdown elements render correctly in MarkdownBody**: Tests standard markdown rendering (headings, bold, lists, etc).
- **Markdown renders with custom styling**: Tests custom style sheets for markdown.
- **MemoContent renders markdown correctly**: Verifies markdown rendering in the MemoContent widget.
- **CommentCard renders markdown correctly**: Tests markdown in CommentCard widgets.
- **MemoCard renders markdown correctly**: Verifies markdown in MemoCard widgets.
- **EditMemoForm toggles between edit and preview modes**: Tests mode switching with markdown content.
- **Complex nested markdown renders correctly**: Tests complex, nested markdown structures.
- **Special characters in markdown are handled correctly**: Verifies handling of special characters and emoji.

## Running the Tests

You can run all tests with:
```bash
flutter test
```

Or run specific tests with:
```bash
flutter test test/markdown_link_handling/basic_links_test.dart
```

Set `markdownDebugEnabled = true` in a test to see detailed debug output.
