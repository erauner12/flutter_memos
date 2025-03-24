import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  // Enable screenshot capture for macOS tests
  captureScreenshots: true,
  // Setup for proper reporting
  responseDataCallback: (data) async {
    print('Integration test results: ${data.toString()}');
    return data;
  },
);
