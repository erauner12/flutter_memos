// This is a simple environment configuration class
// In a real app, you would use something like flutter_dotenv or flutter_config
// to load environment variables from a .env file

class Env {
  // API configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5230/api/v1/memos',
  );
  
  static const String memosApiKey = String.fromEnvironment(
    'MEMOS_API_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsImtpZCI6InYxIiwidHlwIjoiSldUIn0.eyJuYW1lIjoiZXJhdW5lciIsImlzcyI6Im1lbW9zIiwic3ViIjoiMSIsImF1ZCI6WyJ1c2VyLmFjY2Vzcy10b2tlbiJdLCJpYXQiOjE3NDI1OTc1Nzd9.Wud-szLldpDNlfnzdEusoXLaFGS-NXNYMM3tolPFViY',
  );
  
  // MCP Server configuration
  static const String mcpServerUrl = String.fromEnvironment(
    'MCP_SERVER_URL',
    defaultValue: 'http://localhost:8080',
  );
  
  static const String mcpServerKey = String.fromEnvironment(
    'MCP_SERVER_KEY',
    defaultValue: '123456789',
  );

  // Helper method to check if configuration is complete
  static bool get isConfigured {
    return apiBaseUrl.isNotEmpty &&
           memosApiKey.isNotEmpty &&
           mcpServerUrl.isNotEmpty &&
           mcpServerKey.isNotEmpty;
  }
  
  // Helper to get API configuration status for debugging
  static Map<String, String> get configStatus {
    return {
      'API URL': apiBaseUrl.isNotEmpty ? 'Configured' : 'Missing',
      'API Key': memosApiKey.isNotEmpty ? 'Present (${_maskString(memosApiKey)})' : 'Missing',
      'MCP URL': mcpServerUrl.isNotEmpty ? 'Configured' : 'Missing',
      'MCP Key': mcpServerKey.isNotEmpty ? 'Present (${_maskString(mcpServerKey)})' : 'Missing',
    };
  }
  
  // Helper to mask sensitive strings for logging
  static String _maskString(String value) {
    if (value.isEmpty) return '';
    if (value.length <= 4) return '****';
    return '***${value.substring(value.length - 4)}';
  }
}
