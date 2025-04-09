import 'dart:convert'; // For jsonEncode/Decode

import 'package:collection/collection.dart'; // For listEquals
import 'package:flutter/foundation.dart'; // For ValueGetter
import 'package:flutter_memos/models/server_config.dart';

// Sentinel value to differentiate between 'not passed' and 'passed as null'
const _notPassedSentinel = Object();

@immutable
class MultiServerConfigState {
  final List<ServerConfig> servers;
  final String?
  activeServerId; // ID of the server currently active in the UI (ephemeral)
  final String?
  defaultServerId; // ID of the server to activate on startup (persistent)

  const MultiServerConfigState({
    this.servers = const [],
    this.activeServerId,
    this.defaultServerId,
  });

  // copyWith method for easier state updates
  MultiServerConfigState copyWith({
    List<ServerConfig>? servers,
    // Use sentinel to detect if activeServerId was explicitly passed, even as null
    Object? activeServerId = _notPassedSentinel,
    ValueGetter<String?>? defaultServerId, // Keep ValueGetter for default
  }) {
    return MultiServerConfigState(
      servers: servers ?? this.servers,
      // If sentinel is passed (meaning argument omitted), keep current value.
      // Otherwise, use the passed value (which could be null).
      activeServerId:
          activeServerId == _notPassedSentinel
              ? this.activeServerId
              : activeServerId as String?,
      // If defaultServerId getter is passed, call it to get the value (could be null).
      // Otherwise, keep the current value.
      defaultServerId: defaultServerId != null ? defaultServerId() : this.defaultServerId,
    );
  }

  // Serialization methods
  Map<String, dynamic> toJson() => {
    'servers': servers.map((s) => s.toJson()).toList(),
    'defaultServerId': defaultServerId,
    // activeServerId is intentionally NOT serialized
  };

  factory MultiServerConfigState.fromJson(Map<String, dynamic> json) {
    return MultiServerConfigState(
      servers:
          (json['servers'] as List<dynamic>?)
              ?.map((s) => ServerConfig.fromJson(s as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultServerId: json['defaultServerId'] as String?,
      // activeServerId is not loaded from JSON
      activeServerId:
          null, // Ensure activeServerId is null when loading from JSON
    );
  }

  // Helper methods for JSON string conversion
  String toJsonString() => jsonEncode(toJson());

  factory MultiServerConfigState.fromJsonString(String jsonString) =>
      MultiServerConfigState.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    final listEquals = const DeepCollectionEquality().equals;

    return other is MultiServerConfigState &&
        listEquals(other.servers, servers) &&
        other.activeServerId == activeServerId &&
        other.defaultServerId == defaultServerId;
  }

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(servers),
        activeServerId,
        defaultServerId,
      );

  @override
  String toString() {
    return 'MultiServerConfigState(servers: ${servers.length}, active: $activeServerId, default: $defaultServerId)';
  }
}

// Helper extension for ValueGetter usage in copyWith (still needed for defaultServerId)
extension ValueGetterExtension<T> on T {
  ValueGetter<T> call() => () => this;
}
