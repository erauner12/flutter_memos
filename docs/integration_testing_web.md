# Flutter Memos Web Integration Testing

This guide explains how to run your Flutter integration tests in a web environment. On macOS and other platforms, you can simply run `flutter drive` against a desktop target. However, web tests require a bit more setup.

## 1. Recommended Approach: Using `flutter test --platform=chrome`

For many integration test scenarios on the web, you can rely on **`flutter test`** rather than **`flutter drive`**. This approach:
- Does **not** require manually starting `chromedriver`.
- Automatically launches the browser and runs tests in a headless environment.

### Steps

1. Put your test files in `integration_test/`.
2. Run:
	```bash
	flutter test integration_test/my_integration_test.dart -p chrome

If you have multiple tests in integration_test/, you can also run them all at once:

flutter test integration_test -p chrome

	3.	Observe the test output in the terminal.

Note: If you see a warning about the integration_test plugin not being detected, that usually refers to the additional features available via flutter drive. For most browser-based tests, you can ignore that as long as your tests pass. The test harness for web is simpler and does not rely on flutter drive or a connected WebDriver server.

⸻

2. Advanced Approach: Using flutter drive and a Chromedriver Server

If you need flutter drive for a specialized reason (for example, using the VM Service Flutter Driver commands on the web), you must configure Chromedriver. The flutter drive command expects an external WebDriver instance to control the browser.

Steps
	1.	Install Chromedriver matching your installed Chrome version:
	•	Check your Chrome version by going to chrome://version in your browser.
	•	Download a matching Chromedriver from https://chromedriver.chromium.org/downloads.
	•	Put the chromedriver binary somewhere on your PATH or specify its path explicitly.
	2.	Start Chromedriver on port 4444 (default for Flutter tests):

./chromedriver --port=4444

Leave this running in a dedicated terminal window.

	3.	Run the test using flutter drive, targeting the web-server device:

flutter drive \
	--driver=test_driver/integration_test_driver.dart \
	--target=integration_test/memo_card_actions_test.dart \
	-d web-server

The web-server device is a pseudo-device that serves your Flutter Web app, then talks to Chromedriver.

	4.	Check your logs. If flutter drive fails with Unable to start a WebDriver session, ensure:
	•	Chromedriver is still running on port 4444.
	•	Your Chrome version matches the Chromedriver version.

⸻

3. Troubleshooting
	1.	Unable to start a WebDriver session for web testing.
	•	You did not start chromedriver or it’s not on port 4444.
	•	Your Chrome version does not match the Chromedriver version.
	•	Double-check your environment variables and paths.
	2.	Warning: integration_test plugin was not detected.
	•	For web tests, this is fairly common when using flutter test. It does not typically prevent your web tests from running. The message indicates that some of the integration_test plugin features (like image diff checks) may not be fully available on the web.
	3.	Identifying Chrome Location
	•	Typically, you don’t need to supply the Chrome path manually if it’s installed in a standard location. Chromedriver will launch Chrome automatically so long as they’re compatible versions.
	•	If you use a non-standard install, set the --binary argument for Chromedriver or a CHROME_EXECUTABLE environment variable.
	4.	Platform Differences
	•	The web environment does not support all the same platform channels or OS-level APIs as macOS, iOS, or Android.
	•	Code that relies on mobile-specific APIs may need conditional checks or mocks to run tests in a web environment.

⸻

4. Example Makefile or Script

Below is an example bash script for web tests:

#!/usr/bin/env bash

# Start chromedriver
chromedriver --port=4444 &

# Let chromedriver start for a second
sleep 1

# Run the integration test
flutter drive \
	--driver=test_driver/integration_test_driver.dart \
	--target=integration_test/memo_card_actions_test.dart \
	-d web-server

# Kill the chromedriver process afterward
kill %1

If you’d rather not depend on a separate Chromedriver process, try the simpler flutter test approach:

flutter test integration_test --platform=chrome



⸻

5. Summary
	•	Easiest: flutter test integration_test/my_test.dart -p chrome
	•	With flutter drive: Manually run Chromedriver, then specify the web-server device.
	•	Check versions: Chromedriver and Chrome must match.
	•	Ignore: The integration_test plugin warning if you’re using flutter test.

That should get your web-based integration tests up and running.
