# Flutter Memos

A Flutter implementation of the memo app with assistant chat functionality, ported from the React Native version.

## Features

1. **Memos List** – Show user's pinned or unpinned memos
2. **Archives** – Screen for archived memos
3. **Tags** – Tag grouping for memos
4. **Comments** - Add and view comments on memos
5. **Assistant Chat** – AI-powered assistant that can create, search and manage memos through conversation
6. **MCP Integration** - Message Control Protocol server for extended functionality
7. **Riverpod State Management** - Modern state management with dependency injection and reactive UI updates

## Setup Instructions

### 1. Environment Configuration

Create a `lib/utils/env_config.dart` file to store your environment variables:

```dart
// lib/utils/env_config.dart
class EnvConfig {
  static const String apiBaseUrl = 'YOUR_API_BASE_URL';
  static const String memosApiKey = 'YOUR_MEMOS_API_KEY';
  static const String mcpServerUrl = 'YOUR_MCP_SERVER_URL';
  static const String mcpServerKey = 'YOUR_MCP_SERVER_KEY';
}
```

Or set up environment variables using the `--dart-define` flag when running your app:

```bash
flutter run --dart-define=API_BASE_URL=https://yourmemosserver.com \
            --dart-define=MEMOS_API_KEY=your_api_key \
            --dart-define=MCP_SERVER_URL=http://mcp-server:8080 \
            --dart-define=MCP_SERVER_KEY=your_mcp_key
```

### 2. Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/flutter_memos.git
   cd flutter_memos
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### 3. Docker Setup (for MCP Server)

The MCP (Message Control Protocol) server provides extended functionality for the Flutter Memos app.

1. Copy environment example files:
   ```bash
   cp .env.example .env
   cp mcp-server/.env.example mcp-server/.env
   ```

2. Configure both .env files with appropriate values.

3. Start both the Memos server and MCP server:
   ```bash
   docker-compose up -d
   ```

4. Access the MCP server health endpoint:
   ```
   http://localhost:8080/health
   ```

## App Structure

- `lib/main.dart` - App entry point and navigation setup
- `lib/models/` - Data models
- `lib/screens/` - App screens
- `lib/services/` - API and service classes
- `lib/utils/` - Utility functions
- `lib/widgets/` - Reusable UI components

## API Integration

The app connects to two main APIs:
1. **Memos API** - For managing memos, comments, etc.
2. **MCP Server API** - For assistant chat and extended functionality

## Assistant Chat Feature

The assistant chat feature uses LLM technology (via OpenAI's API) to provide an intelligent interface for creating and managing memos:

1. Navigate to the Assistant Chat screen from the home screen
2. Chat naturally with the assistant about your memos
3. The assistant can:
   - Create new memos based on your requests
   - Find memos containing specific information
   - Answer questions about your memos
   - Link directly to memos in the conversation

For the assistant to work properly:
- The MCP server must be running
- You must have a valid OpenAI API key in `mcp-server/.env`
- The assistant uses function calling to interact with your memos database

## State Management

The app uses Riverpod for state management, providing several benefits:

1. **Dependency Injection**: Services are easily provided throughout the app
2. **Reactive UI**: UI automatically updates when state changes
3. **Testability**: Easier to write unit and widget tests with mock providers
4. **Code Organization**: Separation of concerns between UI and business logic

Key providers include:
- `apiServiceProvider`: Provides the API service throughout the app
- `memosProvider`: Fetches and manages the list of memos
- `filterProviders`: Manages filter state for the memo list

See [RIVERPOD_MIGRATION.md](docs/RIVERPOD_MIGRATION.md) for more details on our approach to Riverpod adoption.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin feature/my-new-feature`)
5. Create a new Pull Request
