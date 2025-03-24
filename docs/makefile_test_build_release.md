# Flutter Memos Build & Test Guide

This document explains how to use the Flutter Memos build system for various development, testing, and deployment tasks.

## Table of Contents
- [macOS Workflows](#macos-workflows)
  - [Building for macOS](#building-for-macos)
  - [Creating & Installing DMG](#creating--installing-dmg)
- [iOS Workflows](#ios-workflows)
  - [Building for iOS](#building-for-ios)
  - [Deploying to Physical Device](#deploying-to-physical-device)
- [Testing Workflows](#testing-workflows)
  - [Running Tests on macOS](#running-tests-on-macos)
  - [Running Tests on iOS](#running-tests-on-ios)
  - [Running Tests on iPad](#running-tests-on-ipad)
  - [Running Tests on Web](#running-tests-on-web)
- [Command Reference](#command-reference)

## macOS Workflows

### Building for macOS

#### Debug Build

For development and debugging:

```bash
make build-macos
```

This builds a debug version of the application.

#### Release Build

For optimized production builds:

```bash
make release-macos
```

This creates a release build in `build/macos/Build/Products/Release/flutter_memos.app`.

#### Quick Install (without DMG)

To quickly install the app (after building) to your Downloads folder:

```bash
make install-macos
```

This copies the app to `~/Downloads/flutter_memos_app/` and opens it automatically.

### Creating & Installing DMG

#### Complete Workflow (Build + Install)

For a complete process to build and install the application:

```bash
# Step 1: Build the app and create DMG installer
make build-dmg

# Step 2: Install from the DMG
make install-dmg
```

This builds the app in release mode, packages it as a DMG, and then installs it to /Applications.

#### Just Create DMG

If you only want to create the DMG (for distribution):

```bash
make build-dmg
```

The DMG will be created at `~/Documents/flutter_memos_release/flutter_memos.dmg`.

#### Just Install from DMG

If you've already built the DMG and want to install it:

```bash
make install-dmg
```

#### Install from Custom DMG Path

If your DMG is in a different location, you can specify the path:

```bash
# Method 1: Using positional argument
make install-dmg-path /path/to/your/flutter_memos.dmg

# Method 2: Using named parameter
make install-dmg-from DMG_PATH=/path/to/your/flutter_memos.dmg
```

#### Clean Up DMG

To remove the previously built DMG:

```bash
make clean-dmg
```

## iOS Workflows

### Building for iOS

To build for iOS in release mode:

```bash
make build-iphone
```

This creates an iOS build in release mode.

### Deploying to Physical Device

#### Build and Install

To build and deploy to a physical iPhone:

```bash
make release-iphone
```

This builds the app and installs it to the connected iPhone specified by `IPHONE_DEVICE_ID`.

You can specify a different device ID:

```bash
make release-iphone IPHONE_DEVICE_ID=your-device-id
```

#### Run on Device (Debug)

To run the app on a physical iPhone in debug mode:

```bash
make run-iphone
```

Or with a custom device ID:

```bash
make run-iphone IPHONE_DEVICE_ID=your-device-id
```

## Testing Workflows

### Running Tests on macOS

```bash
make test-integration-macos
```

This runs the integration tests on macOS.

### Running Tests on iOS

To run tests on an iOS simulator:

```bash
make test-integration-ios
```

This creates an iPhone 16 Pro simulator, launches it, runs the tests, and then kills the simulator.

To run tests on a physical iPhone:

```bash
make test-integration-iphone
```

Or with a custom device ID:

```bash
make test-integration-iphone IPHONE_DEVICE_ID=your-device-id
```

### Running Tests on iPad

For iPad testing in portrait mode:

```bash
make test-integration-ipad-portrait
```

For iPad testing in landscape mode:

```bash
make test-integration-ipad-landscape
```

Both commands will create an iPad Pro 11-inch simulator, run the tests, and clean up.

### Running Tests on Web

To run tests on the web platform:

```bash
make test-integration-web
```

This starts a ChromeDriver server, runs the tests on a web server, and cleans up afterward.

### Running All Tests

To run all integration tests on macOS:

```bash
make test-integration-all
```

This will run all test files in the `integration_test/` directory.

## Command Reference

| Command | Description |
|---------|-------------|
| `make help` | Display help information |
| `make build-macos` | Build for macOS (debug) |
| `make release-macos` | Build for macOS (release) |
| `make build-dmg` | Create DMG installer |
| `make install-dmg` | Install from the built DMG |
| `make clean-dmg` | Remove the DMG file |
| `make install-macos` | Install directly from build folder |
| `make build-iphone` | Build for iOS |
| `make release-iphone` | Build and install to iPhone |
| `make run-iphone` | Run on iPhone (debug) |
| `make test-integration-macos` | Run tests on macOS |
| `make test-integration-ios` | Run tests on iOS simulator |
| `make test-integration-iphone` | Run tests on physical iPhone |
| `make test-integration-ipad-portrait` | Run tests on iPad (portrait) |
| `make test-integration-ipad-landscape` | Run tests on iPad (landscape) |
| `make test-integration-web` | Run tests on web |
| `make test-integration-all` | Run all tests on macOS |
| `make kill-simulator` | Kill the iOS simulator |
