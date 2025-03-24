#!/bin/bash

# This script attempts to generate Riverpod code with minimal dependencies

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting minimal code generation approach${NC}"

# Create a temporary pubspec.yaml backup
cp pubspec.yaml pubspec.yaml.bak

# Create a minimal pubspec.yaml
cat > pubspec.yaml.minimal << EOL
name: flutter_memos
description: "A Flutter version of the memo app with assistant chat functionality."
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: ^3.7.2

dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.1.5

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  riverpod_generator: ^2.1.5

flutter:
  uses-material-design: true
EOL

# Create a test file
mkdir -p lib/test
cat > lib/test/simple_provider.dart << EOL
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'simple_provider.g.dart';

@riverpod
int counter(CounterRef ref) => 0;

@riverpod
class Counter extends _\$Counter {
  @override
  int build() => 0;
  
  void increment() => state++;
}
EOL

echo -e "${YELLOW}Created minimal test files${NC}"

# Try code generation with minimal dependencies
echo -e "${YELLOW}Attempting code generation with minimal dependencies...${NC}"

# Replace the pubspec
mv pubspec.yaml.minimal pubspec.yaml

# Get dependencies
flutter pub get

# Try building
echo -e "${YELLOW}Running build_runner...${NC}"
dart run build_runner build --delete-conflicting-outputs

# Check the result
if [ -f "lib/test/simple_provider.g.dart" ]; then
  echo -e "${GREEN}Success! Code generation worked with minimal dependencies.${NC}"
  echo -e "${YELLOW}The generated file is at lib/test/simple_provider.g.dart${NC}"
  
  # Restore original pubspec
  mv pubspec.yaml.bak pubspec.yaml
  flutter pub get
  
  echo -e "${YELLOW}Now you can:${NC}"
  echo -e "1. Look at the generated file to understand the pattern"
  echo -e "2. Apply similar patterns manually in your code"
  echo -e "3. Later, when dependencies align better, integrate code generation fully"
else
  echo -e "${RED}Code generation failed even with minimal dependencies.${NC}"
  
  # Restore original pubspec
  mv pubspec.yaml.bak pubspec.yaml
  flutter pub get
  
  echo -e "${YELLOW}Recommendation:${NC}"
  echo -e "1. Create a separate Flutter project to test code generation"
  echo -e "2. In this project, focus on improving Riverpod usage without code generation"
  echo -e "3. See doc/riverpod_strategy.md and doc/riverpod_optimization.md for guidance"
fi