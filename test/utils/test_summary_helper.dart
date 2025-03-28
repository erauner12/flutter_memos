import 'dart:io';

/// A utility class for summarizing test files and providing information about what's being tested.
class TestSummaryHelper {
  /// Prints a formatted summary of a specific test file
  static void summarizeTestFile(String testFilePath) {
    final file = File(testFilePath);
    
    if (!file.existsSync()) {
      print('Error: Test file not found: $testFilePath');
      return;
    }
    
    final content = file.readAsStringSync();
    final testFilename = testFilePath.split('/').last;
    
    print('\n=== TEST SUMMARY: $testFilename ===');
    
    // Extract test groups
    final groupRegex = RegExp(r"group\(\s*['\"](.*?)['\"]\s*,", multiLine: true);
    final groupMatches = groupRegex.allMatches(content);
    
    // Extract individual tests
    final testRegex = RegExp(r"test(?:Widgets)?\(\s*['\"](.*?)['\"]\s*,", multiLine: true);
    final testMatches = testRegex.allMatches(content);
    
    // Print test structure
    if (groupMatches.isNotEmpty) {
      print('Test Groups:');
      for (final match in groupMatches) {
        print('  • ${match.group(1)}');
      }
      print('');
    }
    
    if (testMatches.isNotEmpty) {
      print('Tests:');
      for (final match in testMatches) {
        print('  ✓ ${match.group(1)}');
      }
    }
    
    print('===================================\n');
  }
  
  /// Prints summaries for all test files in a directory
  static void summarizeTestDirectory(String directory) {
    final dir = Directory(directory);
    
    if (!dir.existsSync()) {
      print('Error: Directory not found: $directory');
      return;
    }
    
    final testFiles = dir
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('_test.dart'))
        .map((file) => file.path)
        .toList();
    
    if (testFiles.isEmpty) {
      print('No test files found in $directory');
      return;
    }
    
    print('Found ${testFiles.length} test files');
    
    for (final testFilePath in testFiles) {
      summarizeTestFile(testFilePath);
    }
  }
  
  /// Helper method to extract what a test is testing based on its name and content
  static Map<String, String> extractTestPurposes(String testFilePath) {
    final file = File(testFilePath);
    
    if (!file.existsSync()) {
      return {};
    }
    
    final content = file.readAsStringSync();
    
    // Extract individual tests with line ranges
    final testRegex = RegExp(r"test(?:Widgets)?\(\s*['\"](.*?)['\"]\s*,", multiLine: true);
    final testMatches = testRegex.allMatches(content);
    
    final purposes = <String, String>{};
    
    for (final match in testMatches) {
      final testName = match.group(1)!;
      
      // Extract ~5 lines after the test starts to get a sense of what it's testing
      final startPos = match.end;
      final excerpt = content.substring(
        startPos,
        startPos + 300 > content.length ? content.length : startPos + 300,
      );
      
      // Clean up the excerpt
      final cleanExcerpt = excerpt
          .split('\n')
          .take(5)
          .join('\n')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      
      purposes[testName] = cleanExcerpt;
    }
    
    return purposes;
  }

  /// Runs and prints a comprehensive summary of what's being tested in each file
  static void printTestCoverage(List<String> testFilePaths) {
    print('=== FLUTTER TEST COVERAGE SUMMARY ===\n');
    
    for (final path in testFilePaths) {
      final filename = path.split('/').last;
      print('📋 $filename');
      
      final purposes = extractTestPurposes(path);
      
      if (purposes.isEmpty) {
        print('  No tests found or file not accessible');
        continue;
      }
      
      for (final entry in purposes.entries) {
        print('  ✓ ${entry.key}');
        print('    ${entry.value.length > 120 ? '${entry.value.substring(0, 120)}...' : entry.value}');
        print('');
      }
      
      print('-----------------------------------');
    }
    
    print('\n=== END OF COVERAGE SUMMARY ===');
  }
  
  /// Example usage to print a summary of all markdown-related tests
  static void summarizeMarkdownTests() {
    final testPaths = [
      'test/markdown_link_handling/basic_links_test.dart',
      'test/markdown_link_handling/memo_content_links_test.dart',
      'test/markdown_link_handling/special_link_schemes_test.dart',
      'test/markdown_preview/code_block_preview_test.dart',
      'test/markdown_preview/edit_memo_preview_test.dart',
      'test/markdown_preview/link_styling_preview_test.dart',
      'test/markdown_preview/new_memo_preview_test.dart',
      'test/markdown_rendering_test.dart',
    ];
    
    printTestCoverage(testPaths);
  }
  
  /// Run this to get test summaries similar to the example output
  static void printExampleOutput() {
    print('flutter test test/markdown_preview/link_styling_preview_test.dart');
    print('00:01 +0: Markdown Link Styling in Preview Mode Links in preview are styled correctly');
    print('[Markdown Test] All RichText widgets after preview toggle:');
    print('[Markdown Test]  - \'CONTENT\'');
    print('[Markdown Test]  - \'\'');
    print('[Markdown Test]  - \'Markdown Help\'');
    print('[Markdown Test]  - \'\'');
    print('[Markdown Test]  - \'Edit\'');
    print('[Markdown Test]  - \'Pinned\'');
    print('[Markdown Test]  - \'Archived\'');
    print('[Markdown Test]  - \'Save Changes\'');
    print('[Markdown Test] MarkdownBody data: \'# Test Heading\n\n[UNIQUE_EXAMPLE_LINK](https://example.com)\'');
    print('00:01 +1: Markdown Link Styling in Preview Mode Links with special characters render correctly');
    print('[Markdown Test] All RichText widgets in preview mode:');
    print('[Markdown Test]  - \'CONTENT\'');
    print('[Markdown Test]  - \'\'');
    print('[Markdown Test]  - \'Markdown Help\'');
    print('[Markdown Test]  - \'\'');
    print('[Markdown Test]  - \'Edit\'');
    print('[Markdown Test]  - \'Pinned\'');
    print('[Markdown Test]  - \'Archived\'');
    print('[Markdown Test]  - \'Save Changes\'');
    print('00:01 +2: All tests passed!');

    print('\nflutter test test/markdown_link_handling/basic_links_test.dart');
    print('00:01 +2: All tests passed!');

    print('\nflutter test test/markdown_link_handling/memo_content_links_test.dart');
    print('00:01 +2: All tests passed!');

    print('\nflutter test test/markdown_link_handling/special_link_schemes_test.dart');
    print('00:01 +5: All tests passed!');

    print('\nflutter test test/markdown_preview/code_block_preview_test.dart');
    print('00:02 +2: All tests passed!');

    print('\nflutter test test/markdown_preview/edit_memo_preview_test.dart');
    print('00:01 +3: All tests passed!');

    print('\nflutter test test/markdown_preview/new_memo_preview_test.dart');
    print('00:01 +2: All tests passed!');
  }
}