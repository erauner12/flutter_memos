# Makefile for running Flutter Memos integration tests on various platforms

.PHONY: test-integration-macos test-integration-ios test-integration-android test-integration-web kill-simulator

test-integration-macos:
	@echo "Running macOS integration tests..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "macos"

test-integration-ios:
	@echo "Opening iOS Simulator..."
	open -a Simulator

	# Give the simulator time to launch and register
	@echo "Waiting for iOS simulator to start..."
	sleep 15

	@echo "Running iOS integration tests on 'iPhone 16 Pro'..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "iPhone 16 Pro"

test-integration-android:
	@echo "Running Android integration tests..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "android"

test-integration-web:
	@echo "Starting Chromedriver on port 4444..."
	chromedriver-mac-arm64/chromedriver --port=4444 &

	# Let Chromedriver start
	sleep 1

	@echo "Running Web integration tests with web-server device..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d web-server

	@echo "Killing Chromedriver..."
	kill %1

kill-simulator:
	@echo "Killing iOS simulator..."
	pkill Simulator || true
