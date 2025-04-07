// This is a simple environment configuration class
// In a real app, you would use something like flutter_dotenv or flutter_config
// to load environment variables from a .env file

class Env {
  // API configuration
  // NOTE: This is a build-time variable. The actual runtime server URL
  // is managed by ServerConfigNotifier and stored in SharedPreferences.
  // Use ref.watch(serverConfigProvider).serverUrl to get the runtime URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '', // No longer defaults to localhost
  );

  static const String memosApiKey = String.fromEnvironment(
    'MEMOS_API_KEY',
    defaultValue: '', // Provide a default value if needed, or handle absence
  );
}
