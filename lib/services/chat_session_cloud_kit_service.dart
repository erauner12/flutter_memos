import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cloud_kit/flutter_cloud_kit.dart';
import 'package:flutter_cloud_kit/types/database_scope.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/utils/env.dart';

class ChatSessionCloudKitService {
  static const _recordType = 'ChatSessionRecord';
  static const _recordName = 'currentUserActiveChat';

  final FlutterCloudKit _cloudKit =
      FlutterCloudKit(containerId: Env.cloudKitContainerId);

  final CloudKitDatabaseScope _scope = CloudKitDatabaseScope.private;

  Map<String, String> _asStringMap(Map<String, dynamic> data) =>
      data.map((k, v) => MapEntry(k, v?.toString() ?? ''));

  Future<bool> saveChatSession(ChatSession session) async {
    try {
      final json = session.toJson();
      json['messages'] = jsonEncode(json['messages']); // flatten list
      await _cloudKit.saveRecord(
        scope: _scope,
        recordType: _recordType,
        recordName: _recordName,
        record: _asStringMap(json),
      );
      return true;
    } on PlatformException catch (e) {
      // treat conflict as success (newer‑wins elsewhere)
      if (e.message?.contains('already exists') == true) return true;
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] save error: $e');
      }
      return false;
    }
  }

  Future<ChatSession?> getChatSession() async {
    try {
      final rec =
          await _cloudKit.getRecord(scope: _scope, recordName: _recordName);
      if (rec.recordType != _recordType) return null;

      final Map<String, dynamic> json = rec.values.map((k, v) {
        if (k == 'messages') return MapEntry(k, jsonDecode(v));
        if (k == 'lastUpdated') return MapEntry(k, DateTime.tryParse(v));
        return MapEntry(k, v);
      });
      json['id'] = _recordName;
      return ChatSession.fromJson(json);
    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) return null;
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] get error: $e');
      }
      return null;
    }
  }

  Future<bool> deleteChatSession() async {
    try {
      await _cloudKit.deleteRecord(scope: _scope, recordName: _recordName);
      return true;
    } on PlatformException catch (e) {
      if (e.message?.contains('not found') == true) return true;
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('[ChatSessionCloudKitService] delete error: $e');
      }
      return false;
    }
  }
}
