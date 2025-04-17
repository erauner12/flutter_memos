import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const _key = 'activeChatSession';

  Future<SharedPreferences> _prefs() => SharedPreferences.getInstance();

  Future<void> saveActiveChatSession(ChatSession session) async {
    try {
      final jsonString = jsonEncode(session.toJson());
      await (await _prefs()).setString(_key, jsonString);
      if (kDebugMode) {
        print('[LocalStorageService] ChatSession saved locally.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageService] Save error: $e');
      }
    }
  }

  Future<ChatSession?> loadActiveChatSession() async {
    try {
      final jsonString = (await _prefs()).getString(_key);
      if (jsonString == null) return null;
      return ChatSession.fromJson(jsonDecode(jsonString));
    } catch (e) {
      if (kDebugMode) {
        print('[LocalStorageService] Load error: $e');
      }
      // wipe corrupted data
      await deleteActiveChatSession();
      return null;
    }
  }

  Future<void> deleteActiveChatSession() async {
    await (await _prefs()).remove(_key);
  }
}
