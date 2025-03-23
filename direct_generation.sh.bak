#!/bin/bash

# This script directly generates API client code using the OpenAPI Generator CLI
# It bypasses the build_runner system which can sometimes be problematic

echo "Starting direct API client generation..."

# Generate the API client code
echo "Generating API client code..."
flutter pub run openapi_generator_cli generate \
  -i api/openapi.yaml \
  -g dart2 \
  -o lib/api \
  --additional-properties="pubName=flutter_memos_api,pubVersion=1.0.0,useEnumExtension=true,dateLibrary=time"

# Check if generation was successful
if [ $? -eq 0 ]; then
  echo "API client generation completed successfully."
else
  echo "API client generation failed. See error messages above."
fi
