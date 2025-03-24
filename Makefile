# Makefile for running Flutter Memos integration tests on various platforms

.PHONY: test-integration-macos test-integration-ios test-integration-ipad-portrait test-integration-ipad-landscape test-integration-web kill-simulator test-integration-iphone run-iphone install-dmg-locally install-dmg-from

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

# Be sure to have create-dmg installed, for example using:
#   brew install create-dmg
#
# Then run: `make make-dmg`
# to generate a DMG in build/macos/Build/Products/Release/installer.

make-dmg: release-macos
	@echo "Packaging flutter_memos.app into a DMG (no custom background, using $(HOME) instead of ~)"

	# Attempt to detach leftover disk images for "Flutter Memos Installer" volume name
	@hdiutil info | grep "Flutter Memos Installer" -B 1 | grep /dev/disk | awk '{print $$1}' | xargs -I{} hdiutil detach -force {} 2>/dev/null || true
	# Short delay may reduce resource-busy issues
	sleep 2

	# Create a release folder in $(HOME)/Documents
	mkdir -p "$(HOME)/Documents/flutter_memos_release"
	rm -f "$(HOME)/Documents/flutter_memos_release/flutter_memos.dmg"

	# Run create-dmg without --background, using an absolute path
	create-dmg --hdiutil-verbose \
		--volname "Flutter Memos Installer" \
		--icon-size 160 \
		--app-drop-link 300 200 \
		--window-pos 100 100 \
		--window-size 600 400 \
		--volicon "build/macos/Build/Products/Release/flutter_memos.app/Contents/Resources/AppIcon.icns" \
		"$(HOME)/Documents/flutter_memos_release/flutter_memos.dmg" \
		"build/macos/Build/Products/Release/flutter_memos.app"

	@echo "DMG created at: $(HOME)/Documents/flutter_memos_release/flutter_memos.dmg"
	@echo "You can open or distribute this DMG. No automatic open performed."

# Run all tests on macOS
test-integration-all:
	for test_file in integration_test/*_test.dart; do \
		flutter drive --driver=test_driver/integration_test_driver.dart --target=$$test_file -d "macos"; \
	done

# Install the app from the newly built DMG in ~/Documents
install-dmg-locally: make-dmg
	@echo "Attaching DMG from $(HOME)/Documents/flutter_memos_release/flutter_memos.dmg ..."
	# We'll store the hdiutil output in a variable so we can parse the mount point
	$(eval HDI_OUTPUT := $(shell hdiutil attach "$(HOME)/Documents/flutter_memos_release/flutter_memos.dmg" | tee /dev/stderr))

	@echo "Searching for the mount point in the hdiutil output..."
	# Extract the mount point path (/Volumes/xxx) - using grep to find /Volumes/ path
	$(eval MOUNT_PATH := $(shell echo "$(HDI_OUTPUT)" | grep -Eo "/Volumes/[^ ]+"))
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
	@if [ ! -d "$(MOUNT_PATH)/flutter_memos.app" ]; then \
		echo "ERROR: Could not find flutter_memos.app in $(MOUNT_PATH)"; \
	
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
# IMPORTANT: Use DMG_PATH=path format (no space after install-dmg-from)
install-dmg-from:
	@if [ -z "$(DMG_PATH)" ]; then \
		echo "ERROR: Please specify DMG_PATH=/path/to/flutter_memos.dmg"; \
		echo "Example: make install-dmg-from DMG_PATH=~/Documents/flutter_memos_release/flutter_memos.dmg"; \
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
	# Extract the mount point path (/Volumes/xxx) - using grep to find /Volumes/ path
	$(eval MOUNT_PATH := $(shell echo "$(HDI_OUTPUT)" | grep -Eo "/Volumes/[^ ]+"))
	@if [ -z "$(MOUNT_PATH)" ]; then \
		echo "ERROR: Could not find mount point in hdiutil output."; \
		echo "Full output:"; \
		echo "$(HDI_OUTPUT)"; \
		exit 1; \
	fi
	
	@echo "Mount path is: $(MOUNT_PATH)"
	@echo "Copying flutter_memos.app from '$(MOUNT_PATH)' to /Applications..."
	cp -R "$(MOUNT_PATH)/flutter_memos.app" "/Applications"
	
	@echo "Detaching DMG..."
	hdiutil detach "$(MOUNT_PATH)" || true
	
	@echo "Install from DMG (from $(DMG_PATH)) complete. You can now run flutter_memos.app from /Applications."