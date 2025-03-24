# Makefile for running Flutter Memos integration tests on various platforms

.PHONY: test-integration-macos test-integration-ios test-integration-ipad test-integration-web kill-simulator

test-integration-macos:
	@echo "Running macOS integration tests..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "macos"

test-integration-ios:
	@echo "Creating iPhone 16 Pro simulator..."
	@UDID=$$(xcrun simctl create "iPhone 16 Pro" "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	echo "Opening iOS Simulator (iPhone 16 Pro) with UDID $$UDID..."; \
	open -a Simulator --args -CurrentDeviceUDID $$UDID; \
	echo "Waiting for iOS simulator to start..."; \
	sleep 15; \
	echo "Running integration tests on 'iPhone 16 Pro'..."; \
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d $$UDID; \
	echo "Killing iOS simulator after tests..."; \
	make kill-simulator

test-integration-ipad:
	@echo "Creating iPad Pro 11-inch simulator..."
	@UDID=$$(xcrun simctl create "iPad Pro 11-inch" "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-16GB" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	echo "Opening iOS Simulator (iPad Pro 11-inch) with UDID $$UDID..."; \
	open -a Simulator --args -CurrentDeviceUDID $$UDID; \
	echo "Waiting for iPad simulator to start..."; \
	sleep 15; \
	echo "Running integration tests on 'iPad Pro 11-inch'..."; \
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d $$UDID; \
	echo "Killing iOS simulator after iPad tests..."; \
	make kill-simulator

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
