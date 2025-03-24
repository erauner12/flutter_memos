# Makefile for running Flutter Memos integration tests on various platforms

.PHONY: test-integration-macos test-integration-ios test-integration-ipad-portrait test-integration-ipad-landscape test-integration-web kill-simulator test-integration-iphone run-iphone

# iOS device ID - change this to your device ID
IPHONE_DEVICE_ID ?= 00008140-0016052002FB001C

test-integration-macos:
	@echo "Running macOS integration tests..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "macos"

# New target for physical iPhone testing
test-integration-iphone:
	@echo "Running integration tests on physical iPhone with ID $(IPHONE_DEVICE_ID)..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d $(IPHONE_DEVICE_ID)

# Run the app on physical iPhone without tests
run-iphone:
	@echo "Building and running app on physical iPhone with ID $(IPHONE_DEVICE_ID)..."
	flutter run -d $(IPHONE_DEVICE_ID)

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

test-integration-ipad-portrait:
	@echo "Creating iPad Pro 11-inch simulator in portrait mode..."
	@UDID=$$(xcrun simctl create "iPad Pro 11-inch" "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-16GB" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	echo "Opening iOS Simulator (iPad Pro 11-inch) with UDID $$UDID..."; \
	open -a Simulator --args -CurrentDeviceUDID $$UDID; \
	echo "Waiting for iPad simulator to start..."; \
	sleep 20; \
	echo "Running integration tests on 'iPad Pro 11-inch' (Portrait)..."; \
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d $$UDID; \
	echo "Killing iOS simulator after iPad tests..."; \
	make kill-simulator

test-integration-ipad-landscape:
	@echo "Creating iPad Pro 11-inch simulator in landscape mode..."
	@UDID=$$(xcrun simctl create "iPad Pro 11-inch" "com.apple.CoreSimulator.SimDeviceType.iPad-Pro-11-inch-M4-16GB" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	echo "Opening iOS Simulator (iPad Pro 11-inch) with UDID $$UDID..."; \
	open -a Simulator --args -CurrentDeviceUDID $$UDID; \
	echo "Waiting for iPad simulator to start..."; \
	sleep 20; \
	echo "Rotating Simulator to Landscape via AppleScript..."; \
	osascript -e 'tell application "Simulator" to activate' -e 'tell application "System Events" to key code 123 using {command down}'; \
	sleep 3; \
	echo "Running integration tests on 'iPad Pro 11-inch' (Landscape)..."; \
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

build-macos:
	@echo "Building Flutter Memos for macOS (release mode)..."
	flutter build macos --release

release-macos: build-macos
	@echo "Release build for macOS complete. You can find the app in build/macos/Build/Products/Release/"

build-iphone:
	@echo "Building Flutter Memos for iPhone (iOS release mode)..."
	flutter build ios --release

release-iphone: build-iphone
	@echo "Installing Flutter Memos to iPhone device with ID $(IPHONE_DEVICE_ID)..."
	flutter install -d $(IPHONE_DEVICE_ID)

install-macos: release-macos
	@echo "Copying flutter_memos.app to ~/Downloads..."
	mkdir -p ~/Downloads/flutter_memos_app
	cp -rf build/macos/Build/Products/Release/flutter_memos.app ~/Downloads/flutter_memos_app/flutter_memos.app
	@echo "Opening flutter_memos.app from ~/Downloads..."
	open ~/Downloads/flutter_memos_app/flutter_memos.app