import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  // Remove unsupported parameters; fix return type mismatch
  responseDataCallback: (Map<String, dynamic>? data) async {
    print('Integration test results: $data');
    // We can't return a Map if the function must be Future<void>.
    // So just return nothing.
    return;
  },
);
