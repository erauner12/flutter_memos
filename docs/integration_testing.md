# Flutter Memos Integration Testing

This document describes how to run and maintain integration tests for the Flutter Memos application.

## Setup Requirements

Before running integration tests, make sure you have:

1. Flutter SDK properly installed and up-to-date
2. Required dependencies in `pubspec.yaml`:
	```yaml
	dev_dependencies:
		integration_test:
		sdk: flutter
	```
3. Proper directory structure:
	- `integration_test/` - Contains test files
	- `test_driver/` - Contains integration test drivers

## Running Integration Tests

### On macOS

```bash
flutter drive \
	--driver=test_driver/integration_test_driver.dart \
	--target=integration_test/memo_card_actions_test.dart \
	-d "macos"
```

### On iOS

```bash
# Ensure an iOS simulator is running or physical device is connected
flutter drive --driver=test_driver/integration_test_driver.dart \
             --target=integration_test/memo_card_actions_test.dart \
             -d "iPhone 16 Pro"
```

### On Android

```bash
# Ensure an Android emulator is running or physical device is connected
flutter drive \
	--driver=test_driver/integration_test_driver.dart \
	--target=integration_test/memo_card_actions_test.dart \
	-d "android"  # Or specify device ID
```

### Running All Integration Tests

If you have multiple test files, you can run them all in sequence using a shell script:

```bash
#!/bin/bash
# Run all integration tests
for test_file in integration_test/*_test.dart; do
	echo "Running test: $test_file"
	flutter drive \
	--driver=test_driver/integration_test_driver.dart \
	--target=$test_file \
	-d "macos"  # Change to your target platform
done
```

## macOS Integration Testing

For macOS integration tests, additional configuration is required to properly report test results:

1. The `integration_test_macos` package is added to dev_dependencies in pubspec.yaml
2. A `RunnerTests.swift` file is created in the macos/RunnerTests directory
3. The macOS XCScheme is updated to include the test target
4. The integration test driver is configured to capture screenshots and report results

This configuration eliminates the "integration_test plugin was not detected" warning.

### Running macOS Tests

You can run the tests using either of these approaches:

```bash
# Using flutter drive (typical approach)
fflutter drive --driver=test_driver/integration_test_driver.dart \
             --target=integration_test/memo_card_actions_test.dart \
             -d "macos"

# Using Flutter test directly (alternative approach)
flutter test integration_test/memo_card_actions_test.dart -d macos
```

## Running Web Integration Tests

For web integration tests,

```bash
flutter drive \
  --driver=test_driver/integration_test_driver.dart \
  --target=integration_test/memo_card_actions_test.dart \
  -d web-server
```

## Troubleshooting

### Common Issues and Solutions

1. **Test can't find UI elements**:
	- Ensure your app is loading test data
	- Check that finders match actual widget properties
	- Use `print` statements or `debugDumpApp()` to inspect widget tree

2. **Context Menu Actions Not Working**:
	- Verify the context menu is appearing (check for 'Memo Actions' text)
	- Ensure the action buttons have the exact text being searched for
	- Add delays with `tester.pumpAndSettle(Duration(seconds: 1))` if animations are interfering

3. **Count Assertions Failing**:
	- Print the actual counts before assertions
	- Update expected counts based on your app's state
	- Consider using relative changes instead of absolute counts:
		```dart
		// Instead of:
		expect(finalCount, 2);
		
		// Use:
		expect(finalCount, initialCount - 1);
		```

4. **Snackbar Text Not Found**:
	- Snackbars may be timing out before being tested
	- Use `find.textContaining()` for partial matches
	- Check if text is wrapped in other widgets

### Debugging Tips

1. Add print statements in tests:
	```dart
	print('Number of cards: ${find.byType(MemoCard).evaluate().length}');
	```

2. Use `await tester.pump(Duration(seconds: 1))` to see UI changes happen slowly

3. Record screenshots during testing:
	```dart
	await tester.pumpAndSettle();
	await binding.takeScreenshot('after_action');
	```

## Makefile Integration

You can add these commands to a Makefile for easy execution:

```makefile
.PHONY: test-integration-macos test-integration-ios test-integration-android

test-integration-macos:
	flutter drive --driver=test_driver/integration_test_driver.dart --target=integration_test/memo_card_actions_test.dart -d "macos"

test-integration-ios:
	flutter drive --driver=test_driver/integration_test_driver.dart --target=integration_test/memo_card_actions_test.dart -d "$(IOS_DEVICE)"

test-integration-android:
	flutter drive --driver=test_driver/integration_test_driver.dart --target=integration_test/memo_card_actions_test.dart -d "$(ANDROID_DEVICE)"

# Run all tests on macOS
test-integration-all:
	for test_file in integration_test/*_test.dart; do \
		flutter drive --driver=test_driver/integration_test_driver.dart --target=$$test_file -d "macos"; \
	done
```

## Creating New Integration Tests

When creating new integration tests:

1. Create a new file in the `integration_test/` directory
2. Follow the pattern established in existing tests
3. Consider testing one feature per file for better organization

Example template for a new test:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_memos/main.dart' as app;

void main() {
	IntegrationTestWidgetsFlutterBinding.ensureInitialized();

	group('Feature Name Integration Tests', () {
	testWidgets('Test specific functionality', (WidgetTester tester) async {
		// Launch app
		app.main();
		await tester.pumpAndSettle();

		// Find widgets
		final widgetFinder = find.byType(YourWidgetType);
		
		// Interact with widgets
		await tester.tap(widgetFinder);
		await tester.pumpAndSettle();
		
		// Verify results
		expect(find.text('Expected Result'), findsOneWidget);
	});
	});
}
```

## CI/CD Integration

For GitHub Actions, add a workflow like:

```yaml
name: Integration Tests

on:
	push:
	branches: [ main ]
	pull_request:
	branches: [ main ]

jobs:
	integration_test:
	runs-on: macos-latest
	steps:
		- uses: actions/checkout@v3
		- uses: subosito/flutter-action@v2
		with:
			flutter-version: '3.x'
			channel: 'stable'
		- name: Install dependencies
		run: flutter pub get
		- name: Run integration tests on macOS
		run: flutter drive --driver=test_driver/integration_test_driver.dart --target=integration_test/memo_card_actions_test.dart -d "macos"
```
