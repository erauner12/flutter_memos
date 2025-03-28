import 'test_summary_helper.dart';

void main() {
  // Print a summary of what each markdown test is testing
  print('Generating test summaries for all markdown tests...\n');
  TestSummaryHelper.summarizeMarkdownTests();
  
  // Alternatively, summarize specific test files
  // TestSummaryHelper.summarizeTestFile('test/markdown_preview/link_styling_preview_test.dart');
  
  // Or summarize all tests in a directory
  // TestSummaryHelper.summarizeTestDirectory('test');
  
  // Print example output similar to the flutter test runs
  print('\n\nExample test output format:');
  print('===========================');
  TestSummaryHelper.printExampleOutput();
}
