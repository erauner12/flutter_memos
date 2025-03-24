#!/bin/bash

# This script generates .g.dart files for Riverpod code generation
# It's helpful to run this script after making changes to any @riverpod annotated files

# Colors for better output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Riverpod code generation...${NC}"

# Run the build_runner command
flutter pub run build_runner build --delete-conflicting-outputs

# Check if the command was successful
if [ $? -eq 0 ]; then
  echo -e "${GREEN}Code generation completed successfully!${NC}"
  
  # Count the number of generated files
  generated_files=$(find lib -name "*.g.dart" | wc -l)
  echo -e "${GREEN}Generated $generated_files .g.dart files.${NC}"
else
  echo -e "${RED}Error during code generation. Please check the output above.${NC}"
  exit 1
fi

echo -e "${YELLOW}Tip: You can also use watch mode:${NC}"
echo -e "flutter pub run build_runner watch --delete-conflicting-outputs"