#!/bin/bash

# This script generates Riverpod code

echo "Running build_runner..."

# Clean up first
echo "Cleaning up..."
flutter clean
rm -rf .dart_tool
flutter pub get

# Run build_runner
echo "Generating code..."
dart run build_runner build --delete-conflicting-outputs

echo "Done!"