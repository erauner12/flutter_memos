import 'dart:convert';

import 'package:collection/collection.dart'; // For DeepCollectionEquality
import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/server_config.dart';

@immutable
class MultiServerConfigState {
  final List<ServerConfig> servers;
  final String? activeServerId; // ID of the currently active server
  final String? defaultServerId; // ID of the server to activate on startup

  const MultiServerConfigState({
    this.servers = const [],
    this.activeServerId,
    this.defaultServerId,
  });

  MultiServerConfigState copyWith({
    List<ServerConfig>? servers,
    ValueGetter<String?>? activeServerId, // Use ValueGetter for nullable reset
    ValueGetter<String?>? defaultServerId, // Use ValueGetter for nullable reset
  }) {
    return MultiServerConfigState(
      servers: servers ?? this.servers,
      activeServerId:
          activeServerId != null ? activeServerId() : this.activeServerId,
      defaultServerId: defaultServerId != null ? defaultServerId() : this.defaultServerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'servers': servers.map((x) => x.toJson()).toList(),
      'activeServerId': activeServerId, // Note: activeServerId is usually not persisted
      'defaultServerId': defaultServerId,
    };
  }

  factory MultiServerConfigState.fromJson(Map<String, dynamic> map) {
    return MultiServerConfigState(
      servers: List<ServerConfig>.from(
        (map['servers'] as List<dynamic>? ?? [])
            .map((x) => ServerConfig.fromJson(x as Map<String, dynamic>)),
      ),
      // activeServerId is typically set on load based on defaultServerId
      activeServerId: null, // Do not load activeServerId from storage
      defaultServerId: map['defaultServerId'] as String?,
    );
  }

  String toJsonString() => json.encode(toJson());

  factory MultiServerConfigState.fromJsonString(String source) =>
      MultiServerConfigState.fromJson(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'MultiServerConfigState(servers: $servers, activeServerId: $activeServerId, defaultServerId: $defaultServerId)';

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
}

// Helper extension for ValueGetter usage in copyWith
extension ValueGetterExtension<T> on T {
  ValueGetter<T> call() => () => this;
}
