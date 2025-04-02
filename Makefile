# Makefile for Flutter Memos - Build, Test, and Distribution

# PHONY targets to prevent conflicts with files of the same names
.PHONY: test-integration-macos test-integration-ios test-integration-ipad-portrait test-integration-ipad-landscape \
		test-integration-web kill-simulator test-integration-iphone run-iphone \
		build-macos release-macos build-dmg install-dmg clean-dmg \
		build-iphone release-iphone install-macos test-integration-all help

# Default target - show help
help:
	@echo "Flutter Memos Build System"
	@echo ""
	@echo "Build & Install Targets:"
	@echo "  build-macos         - Build Flutter Memos for macOS (debug mode)"
	@echo "  release-macos       - Build Flutter Memos for macOS (release mode)"
	@echo "  build-dmg           - Build a DMG installer"
	@echo "  install-dmg         - Install from the previously built DMG"
	@echo "  clean-dmg           - Remove previous DMG builds"
	@echo "  install-macos       - Copy and open app from build directory"
	@echo "  build-iphone        - Build Flutter Memos for iOS"
	@echo "  release-iphone      - Install to physical iPhone device"
	@echo "  run-iphone          - Run on physical iPhone device"
	@echo ""
	@echo "Test Targets:"
	@echo "  test-integration-macos       - Run integration tests on macOS"
	@echo "  test-integration-ios         - Run integration tests on iOS simulator"
	@echo "  test-integration-iphone      - Run integration tests on physical iPhone"
	@echo "  test-integration-ipad-portrait  - Run integration tests on iPad (portrait)"
	@echo "  test-integration-ipad-landscape - Run integration tests on iPad (landscape)"
	@echo "  test-integration-web         - Run integration tests on web"
	@echo "  test-integration-all         - Run all integration tests on macOS"
	@echo "  test-deep-link-memo        - Launch simulator and open a memo deep link via xcrun"
	@echo "  test-deep-link-comment     - Launch simulator and open a comment deep link via xcrun"
	@echo ""
	@echo "macOS Installation workflow:"
	@echo "  1. make build-dmg     (builds the app and creates DMG)"
	@echo "  2. make install-dmg   (installs the app from the DMG)"

# iOS device ID - change this to your device ID
IPHONE_DEVICE_ID ?= 00008140-0016052002FB001C

# Location for the DMG file
DMG_DIR := $(HOME)/Documents/flutter_memos_release
DMG_PATH := $(DMG_DIR)/flutter_memos.dmg

#
# MacOS Build & Release Targets
#

# Build for macOS (debug mode)
build-macos:
	@echo "Building Flutter Memos for macOS (debug mode)..."
	flutter build macos

# Build for macOS (release mode)
release-macos:
	@echo "Building Flutter Memos for macOS (release mode)..."
	flutter build macos --release
	@echo "Release build for macOS complete. You can find the app in build/macos/Build/Products/Release/"

# Install built macOS app directly (without DMG)
install-macos:
	@echo "Copying flutter_memos.app to ~/Downloads..."
	mkdir -p ~/Downloads/flutter_memos_app
	cp -rf build/macos/Build/Products/Release/flutter_memos.app ~/Downloads/flutter_memos_app/flutter_memos.app
	@echo "Opening flutter_memos.app from ~/Downloads..."
	open ~/Downloads/flutter_memos_app/flutter_memos.app

#
# iOS/iPhone Build & Release Targets
#

# Build for iPhone
build-iphone:
	@echo "Building Flutter Memos for iPhone (iOS release mode)..."
	flutter build ios --release

# Install to physical iPhone
release-iphone: build-iphone
	@echo "Installing Flutter Memos to iPhone device with ID $(IPHONE_DEVICE_ID)..."
	flutter install -d $(IPHONE_DEVICE_ID)

# Run app on physical iPhone without tests
run-iphone:
	@echo "Building and running app on physical iPhone with ID $(IPHONE_DEVICE_ID)..."
	flutter run -d $(IPHONE_DEVICE_ID)

#
# DMG Packaging & Installation
#

# Build the DMG installer
build-dmg: release-macos
	@echo "Packaging flutter_memos.app into a DMG..."
	
	# Attempt to detach leftover disk images for "Flutter Memos Installer" volume name
	@hdiutil info | grep "Flutter Memos Installer" -B 1 | grep /dev/disk | awk '{print $$1}' | xargs -I{} hdiutil detach -force {} 2>/dev/null || true
	# Short delay may reduce resource-busy issues
	sleep 2
	
	# Create a release folder
	mkdir -p "$(DMG_DIR)"
	rm -f "$(DMG_PATH)"

	# Create the DMG
	@echo "Creating DMG using create-dmg..."
	create-dmg --hdiutil-verbose \
		--volname "Flutter Memos Installer" \
		--icon-size 160 \
		--app-drop-link 300 200 \
		--window-pos 100 100 \
		--window-size 600 400 \
		--volicon "build/macos/Build/Products/Release/flutter_memos.app/Contents/Resources/AppIcon.icns" \
		"$(DMG_PATH)" \
		"build/macos/Build/Products/Release/flutter_memos.app"

	@echo "DMG created at: $(DMG_PATH)"
	@echo "You can open or distribute this DMG. No automatic open performed."

# Install from the previously built DMG
install-dmg:
	@echo "Installing Flutter Memos from DMG..."
	
	# Check if DMG exists
	@if [ ! -f "$(DMG_PATH)" ]; then \
		echo "ERROR: DMG file not found at: $(DMG_PATH)"; \
		echo "Run 'make build-dmg' first to create the DMG."; \
		exit 1; \
	fi
	
	# Mount the DMG
	@echo "Mounting the DMG..."
	$(eval HDI_OUTPUT := $(shell hdiutil attach "$(DMG_PATH)" | tee /dev/stderr))
	
	# Extract the mount point
	$(eval MOUNT_PATH := $(shell echo "$(HDI_OUTPUT)" | grep "Apple_HFS" | sed -E 's/.*Apple_HFS[[:space:]]+(.+)/\1/'))
	@if [ -z "$(MOUNT_PATH)" ]; then \
		echo "ERROR: Could not find mount point in hdiutil output."; \
		echo "Full output:"; \
		echo "$(HDI_OUTPUT)"; \
		exit 1; \
	fi
	
	# Copy the app to Applications
	@echo "Mount path is: $(MOUNT_PATH)"
	@if [ ! -d "$(MOUNT_PATH)/flutter_memos.app" ]; then \
		echo "ERROR: Could not find flutter_memos.app in $(MOUNT_PATH)"; \
		echo "Available files in $(MOUNT_PATH):"; \
		ls -la "$(MOUNT_PATH)"; \
		hdiutil detach "$(MOUNT_PATH)" || true; \
		exit 1; \
	fi
	
	@echo "Copying flutter_memos.app to /Applications..."
	cp -R "$(MOUNT_PATH)/flutter_memos.app" "/Applications"
	
	# Unmount the DMG
	@echo "Unmounting the DMG..."
	hdiutil detach "$(MOUNT_PATH)" || true
	
	@echo "Installation complete. You can now run flutter_memos.app from /Applications."

# Install from DMG path specified as positional argument
# Usage: make install-dmg-path /path/to/flutter_memos.dmg
install-dmg-path:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "ERROR: Please specify the DMG path"; \
		echo "Example: make install-dmg-path ~/Documents/flutter_memos_release/flutter_memos.dmg"; \
		exit 1; \
	fi
	@echo "Attaching DMG from $(filter-out $@,$(MAKECMDGOALS)) ..."
	$(eval DMG_PATH := $(filter-out $@,$(MAKECMDGOALS)))
	$(eval DMG_EXPANDED_PATH := $(shell eval echo $(DMG_PATH)))
	@if [ ! -f "$(DMG_EXPANDED_PATH)" ]; then \
		echo "ERROR: DMG file not found at: $(DMG_EXPANDED_PATH)"; \
		exit 1; \
	fi
	$(eval HDI_OUTPUT := $(shell hdiutil attach "$(DMG_EXPANDED_PATH)" | tee /dev/stderr))
	
	@echo "Parsing hdiutil output for mount path..."
	# Extract the mount point path (/Volumes/xxx) by finding the Apple_HFS line and extracting volume path
	$(eval MOUNT_PATH := $(shell echo "$(HDI_OUTPUT)" | grep "Apple_HFS" | sed -E 's/.*Apple_HFS[[:space:]]+(.+)/\1/'))
	@if [ -z "$(MOUNT_PATH)" ]; then \
		echo "ERROR: Could not find mount point in hdiutil output."; \
		echo "Full output:"; \
		echo "$(HDI_OUTPUT)"; \
		exit 1; \
	fi
	
	@echo "Mount path is: $(MOUNT_PATH)"
	@if [ ! -d "$(MOUNT_PATH)/flutter_memos.app" ]; then \
		echo "ERROR: Could not find flutter_memos.app in $(MOUNT_PATH)"; \
		echo "Available files in $(MOUNT_PATH):"; \
		ls -la "$(MOUNT_PATH)"; \
		hdiutil detach "$(MOUNT_PATH)" || true; \
		exit 1; \
	fi
	@echo "Copying flutter_memos.app from '$(MOUNT_PATH)' to /Applications..."
	cp -R "$(MOUNT_PATH)/flutter_memos.app" "/Applications"
	
	@echo "Detaching DMG..."
	hdiutil detach "$(MOUNT_PATH)" || true
	
	@echo "Install from DMG complete. You can now run flutter_memos.app from /Applications."

# Install the app from a user-specified DMG path:
# Usage: make install-dmg-from DMG_PATH=/path/to/flutter_memos.dmg
install-dmg-from:
	@if [ -z "$(DMG_PATH)" ]; then \
		echo "ERROR: Please specify DMG_PATH=/path/to/flutter_memos.dmg"; \
		echo "Example: make install-dmg-from DMG_PATH=~/Documents/flutter_memos_release/flutter_memos.dmg"; \
		echo "Or use: make install-dmg-path /path/to/flutter_memos.dmg"; \
		exit 1; \
	fi
	@echo "Attaching DMG from $(DMG_PATH) ..."
	$(eval DMG_EXPANDED_PATH := $(shell eval echo $(DMG_PATH)))
	@if [ ! -f "$(DMG_EXPANDED_PATH)" ]; then \
		echo "ERROR: DMG file not found at: $(DMG_EXPANDED_PATH)"; \
		exit 1; \
	fi
	$(eval HDI_OUTPUT := $(shell hdiutil attach "$(DMG_EXPANDED_PATH)" | tee /dev/stderr))
	
	@echo "Parsing hdiutil output for mount path..."
	# Extract the mount point path (/Volumes/xxx) by finding the Apple_HFS line and extracting volume path
	$(eval MOUNT_PATH := $(shell echo "$(HDI_OUTPUT)" | grep "Apple_HFS" | sed -E 's/.*Apple_HFS[[:space:]]+(.+)/\1/'))
	@if [ -z "$(MOUNT_PATH)" ]; then \
		echo "ERROR: Could not find mount point in hdiutil output."; \
		echo "Full output:"; \
		echo "$(HDI_OUTPUT)"; \
		exit 1; \
	fi
	
	@echo "Mount path is: $(MOUNT_PATH)"
	@if [ ! -d "$(MOUNT_PATH)/flutter_memos.app" ]; then \
		echo "ERROR: Could not find flutter_memos.app in $(MOUNT_PATH)"; \
		echo "Available files in $(MOUNT_PATH):"; \
		ls -la "$(MOUNT_PATH)"; \
		hdiutil detach "$(MOUNT_PATH)" || true; \
		exit 1; \
	fi
	@echo "Copying flutter_memos.app from '$(MOUNT_PATH)' to /Applications..."
	cp -R "$(MOUNT_PATH)/flutter_memos.app" "/Applications"
	
	@echo "Detaching DMG..."
	hdiutil detach "$(MOUNT_PATH)" || true
	
	@echo "Install from DMG (from $(DMG_PATH)) complete. You can now run flutter_memos.app from /Applications."

# Clean up by removing previous DMG builds
clean-dmg:
	@echo "Removing previous DMG builds..."
	rm -f "$(DMG_PATH)"
	@echo "Removed $(DMG_PATH)"

#
# Integration Tests
#

# Run tests on macOS
test-integration-macos:
	@echo "Running macOS integration tests..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d "macos"

# Run tests on physical iPhone
test-integration-iphone:
	@echo "Running integration tests on physical iPhone with ID $(IPHONE_DEVICE_ID)..."
	flutter drive \
		--driver=test_driver/integration_test_driver.dart \
		--target=integration_test/memo_card_actions_test.dart \
		-d $(IPHONE_DEVICE_ID)

# Run tests on iOS simulator
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

# Run tests on iPad in portrait mode
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

# Run tests on iPad in landscape mode
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

# Run tests on web
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

# Kill the iOS simulator
kill-simulator:
	@echo "Killing iOS simulator..."
	pkill Simulator || true

# Run all tests on macOS
test-integration-all:
	for test_file in integration_test/*_test.dart; do \
		flutter drive --driver=test_driver/integration_test_driver.dart --target=$$test_file -d "macos"; \
	done

#
# Deep Link Testing via Simulator
#

# Helper target to boot simulator and install app (used by deep link tests)
# Usage: make _setup-sim-for-deeplink SIM_UDID=<udid>
.PHONY: _setup-sim-for-deeplink
_setup-sim-for-deeplink:
	@echo "Opening iOS Simulator with UDID $(SIM_UDID)..."
	open -a Simulator --args -CurrentDeviceUDID $(SIM_UDID)
	@echo "Waiting for simulator to boot..."
	xcrun simctl bootstatus $(SIM_UDID) -b
	@echo "Installing app (debug build)..."
	flutter build ios --debug --simulator # Ensure debug build for simulator
	xcrun simctl install $(SIM_UDID) build/ios/iphonesimulator/Runner.app
	@echo "Simulator setup complete for UDID $(SIM_UDID)."

# Test opening a memo deep link
# Note: Uses a placeholder ID. Assumes app is built and simulator exists.
test-deep-link-memo: kill-simulator
	@echo "Setting up simulator for Memo Deep Link test..."
	@UDID=$$(xcrun simctl create "iPhone 16 Pro DL" "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	make _setup-sim-for-deeplink SIM_UDID=$$UDID; \
	echo "Opening memo deep link (flutter-memos://memo/placeholder-memo-id)..."; \
	xcrun simctl openurl $$UDID "flutter-memos://memo/placeholder-memo-id"; \
	echo "Deep link sent. Check simulator. Pausing for manual inspection..."; \
	sleep 15; \
	make kill-simulator SIM_UDID=$$UDID # Clean up specific simulator

# Test opening a comment deep link
# Note: Uses placeholder IDs. Assumes app is built and simulator exists.
test-deep-link-comment: kill-simulator
	@echo "Setting up simulator for Comment Deep Link test..."
	@UDID=$$(xcrun simctl create "iPhone 16 Pro DL" "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro" "com.apple.CoreSimulator.SimRuntime.iOS-18-3"); \
	echo "Simulator created with UDID: $$UDID"; \
	make _setup-sim-for-deeplink SIM_UDID=$$UDID; \
	echo "Opening comment deep link (flutter-memos://comment/placeholder-memo-id/placeholder-comment-id)..."; \
	xcrun simctl openurl $$UDID "flutter-memos://comment/placeholder-memo-id/placeholder-comment-id"; \
	echo "Deep link sent. Check simulator. Pausing for manual inspection..."; \
	sleep 15; \
	make kill-simulator SIM_UDID=$$UDID # Clean up specific simulator

# Allow arbitrary arguments to be passed to targets like install-dmg-path
%:
	@: