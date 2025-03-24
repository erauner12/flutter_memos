

/// Server configuration model for device-level storage
class ServerConfig {
  final String serverUrl;
  final String authToken;

  const ServerConfig({
    required this.serverUrl,
    required this.authToken,
  });

  /// Create a copy of this configuration with some fields replaced
  ServerConfig copyWith({
    String? serverUrl,
    String? authToken,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'authToken': authToken,
    };
  }

  /// Create from a map (from storage)
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] as String? ?? '',
      authToken: json['authToken'] as String? ?? '',
    );
  }

  /// Default configuration
  static ServerConfig get defaultConfig => const ServerConfig(
        serverUrl: '',
        authToken: '',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.serverUrl == serverUrl &&
        other.authToken == authToken;
  }

  @override
  int get hashCode => Object.hash(serverUrl, authToken);

  @override
  String toString() {
    return 'ServerConfig(serverUrl: $serverUrl, authToken: ${authToken.isNotEmpty ? "****" : "empty"})';
  }
}