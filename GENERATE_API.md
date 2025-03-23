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
flutter pub run build_runner build --delete-conflicting-outputs
```

This will:
1. Read the OpenAPI specification from `api/openapi.yaml`
2. Generate Dart client code in `lib/api` directory
3. Create model classes, API clients, and helper utilities

## Manual Generation (Alternative)

You can also use the OpenAPI Generator CLI directly:

```bash
flutter pub run openapi_generator_cli generate -i api/openapi.yaml -g dart2 -o lib/api --additional-properties=pubName=flutter_memos_api,pubVersion=1.0.0,useEnumExtension=true,dateLibrary=time
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