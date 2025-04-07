import 'package:uuid/uuid.dart'; // Add uuid import

/// Server configuration model for device-level storage
class ServerConfig {
  final String id; // Add unique ID
  final String? name; // Add optional user-friendly name
  final String serverUrl;
  final String authToken;

  // Update constructor to accept id and name, generate ID if not provided
  ServerConfig({
    String? id, // Make id optional in constructor
    this.name,
    required this.serverUrl,
    required this.authToken,
  }) : id = id ?? const Uuid().v4(); // Generate UUID if id is null

  /// Create a copy of this configuration with some fields replaced
  ServerConfig copyWith({
    String? id,
    String? name, // Add name
    String? serverUrl,
    String? authToken,
  }) {
    return ServerConfig(
      id: id ?? this.id,
      name: name ?? this.name, // Copy name
      serverUrl: serverUrl ?? this.serverUrl,
      authToken: authToken ?? this.authToken,
    );
  }

  /// Convert to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id, // Add id
      'name': name, // Add name
      'serverUrl': serverUrl,
      'authToken': authToken,
    };
  }

  /// Create from a map (from storage)
  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      id:
          json['id'] as String? ??
          const Uuid().v4(), // Handle missing ID for migration
      name: json['name'] as String?, // Handle optional name
      serverUrl: json['serverUrl'] as String? ?? '',
      authToken: json['authToken'] as String? ?? '',
    );
  }

  /// Default configuration (no longer used directly, but keep for reference/tests)
  static ServerConfig get defaultConfig =>
      ServerConfig(
        serverUrl: '',
        authToken: '',
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServerConfig &&
        other.id == id && // Compare id
        other.name == name && // Compare name
        other.serverUrl == serverUrl &&
        other.authToken == authToken;
  }

  @override
  int get hashCode => Object.hash(id, name, serverUrl, authToken); // Hash id and name

  @override
  String toString() {
    return 'ServerConfig(id: $id, name: $name, serverUrl: $serverUrl, authToken: ${authToken.isNotEmpty ? "****" : "empty"})'; // Include id and name
  }
}
