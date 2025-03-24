# Generating API Client Code

This document provides instructions for generating API client code using the OpenAPI Generator.

## Prerequisites

Make sure you have installed all dependencies:

```bash
flutter pub get
```

## Generate API Client Code

To generate API client code from the OpenAPI specification:

```bash
dart run build_runner build --delete-conflicting-outputs
```

This will:
1. Read the OpenAPI specification from `api/openapi.yaml`
2. Generate Dart client code in `lib/api` directory
3. Create model classes, API clients, and helper utilities

## Troubleshooting

If the code generation doesn't work:

1. Try using the CLI directly:
   ```bash
   dart run openapi_generator_cli generate -i api/openapi.yaml -g dart2 -o lib/api --additional-properties=pubName=flutter_memos_api,pubVersion=1.0.0,useEnumExtension=true,dateLibrary=time
   ```

2. Check for errors in the OpenAPI specification file.

3. Ensure all dependencies are correctly installed:
   ```bash
   flutter pub get
   ```

4. Try clearing the build cache:
   ```bash
   dart run build_runner clean
   ```

## Using Generated Code

After generating the API client:

1. Import the generated API client in your code:
   ```dart
   import 'package:flutter_memos/api/api.dart';
   ```

2. Create an API client instance:
   ```dart
   final apiClient = ApiClient(baseUrl: 'https://your-api-url');
   final memoApi = MemoApi(apiClient);
   ```

3. Use the API methods:
   ```dart
   final memos = await memoApi.listMemos();
   ```

## Regenerating Code

Whenever the OpenAPI specification changes, regenerate the client code using the commands above.