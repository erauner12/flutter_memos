#!/bin/bash

echo "Generating mocks for tests..."
echo "Make sure to run this after adding any new @GenerateNiceMocks annotations!"
dart run build_runner build --delete-conflicting-outputs

if [ $? -ne 0 ]; then
  echo "⚠️ Error generating mocks - check errors above"
  exit 1
fi

echo "Checking for generated mock files..."
mock_files=$(find test -name "*.mocks.dart")
if [ -z "$mock_files" ]; then
  echo "❌ No mock files were generated! Check your @GenerateMocks annotations."
  exit 1
fi

for file in $mock_files; do
  echo "✅ Generated: $file"
done

echo "✅ Successfully generated all mocks."
echo "New mocks added: url_launcher_service_test.mocks.dart"