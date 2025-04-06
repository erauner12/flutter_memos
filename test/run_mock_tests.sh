#!/bin/bash

echo "🔍 Finding test files that use mocks..."

# Find all mock files
mock_files=$(find test -name "*.mocks.dart")

if [ -z "$mock_files" ]; then
  echo "❌ No mock files found! Run ./test/build_mocks.sh first to generate mocks."
  exit 1
fi

# Find all test files that import mocks
test_files_with_mocks=()
for mock_file in $mock_files; do
  # Extract the mock file name without path
  mock_name=$(basename "$mock_file")
  
  # Find test files that import this mock
  files=$(grep -l "import.*$mock_name" $(find test -name "*_test.dart"))
  
  for file in $files; do
    if [[ ! " ${test_files_with_mocks[@]} " =~ " ${file} " ]]; then
      test_files_with_mocks+=("$file")
    fi
  done
done

if [ ${#test_files_with_mocks[@]} -eq 0 ]; then
  echo "❌ Found mock files but couldn't find tests that use them."
  echo "Check that your test files correctly import the mock files."
  exit 1
fi

echo "🧪 Found ${#test_files_with_mocks[@]} test files that use mocks:"
for test_file in "${test_files_with_mocks[@]}"; do
  echo "  - $test_file"
done

echo "▶️ Running tests with mocks..."
flutter test "${test_files_with_mocks[@]}"

exit_code=$?
if [ $exit_code -eq 0 ]; then
  echo "✅ All mock-dependent tests passed!"
else
  echo "❌ Some mock-dependent tests failed. Exit code: $exit_code"
  exit $exit_code
fi
