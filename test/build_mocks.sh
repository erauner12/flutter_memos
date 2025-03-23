#!/bin/bash

echo "Generating mocks for tests..."
dart run build_runner build --delete-conflicting-outputs
echo "Done generating mocks."