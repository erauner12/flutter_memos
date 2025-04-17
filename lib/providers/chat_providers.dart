import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;

@immutable
class ChatState {
  final ChatSession session;
  final bool isLoading;
  final bool isInitializing;
  final String? errorMessage;

  const ChatState({
    required this.session,
    this.isLoading = false,
    this.isInitializing = true,
    this.errorMessage,
  });

  factory ChatState.initial() =>
      ChatState(session: ChatSession.initial(), isInitializing: true);

  ChatState copyWith({
    ChatSession? session,
    bool? isLoading,
    bool? isInitializing,
    String? errorMessage,
    bool clearError = false,
  }) => ChatState(
    session: session ?? this.session,
    isLoading: isLoading ?? this.isLoading,
    isInitializing: isInitializing ?? this.isInitializing,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  /* convenience getters used by UI */

  List<ChatMessage> get displayMessages => session.messages;
  String? get currentContextItemId => session.contextItemId;
  WorkbenchItemType? get currentContextItemType => session.contextItemType;
  String? get currentContextServerId => session.contextServerId;
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._ref, this._local, this._cloud)
    : super(ChatState.initial()) {
    _initGemini();
    _loadInitialSession();
  }

  final Ref _ref;
  final LocalStorageService _local;
  final ChatSessionCloudKitService _cloud;
  gen_ai.GenerativeModel? _model;
  Timer? _debounce;

  /* ---------- initialisation ---------- */

  void _initGemini() {
    final key = _ref.read(geminiApiKeyProvider);
    if (key.isEmpty) return;
    _model = gen_ai.GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: key,
    );
    _ref.listen(geminiApiKeyProvider, (_, next) {
      _model =
          next.isEmpty
              ? null
              : gen_ai.GenerativeModel(
                model: 'gemini-1.5-flash-latest',
                apiKey: next,
              );
    });
  }

  Future<void> _loadInitialSession() async {
    ChatSession? cloud;
    ChatSession? local;
    try {
      cloud = await _cloud.getChatSession();
    } catch (_) {}
    try {
      local = await _local.loadActiveChatSession();
    } catch (_) {}

    ChatSession chosen = cloud ?? local ?? ChatSession.initial();
    if (cloud != null && local != null) {
      chosen = cloud.lastUpdated.isAfter(local.lastUpdated) ? cloud : local;
    }
    // keep chosen synced everywhere
    await _local.saveActiveChatSession(chosen);
    await _cloud.saveChatSession(chosen);

    state = state.copyWith(session: chosen, isInitializing: false);
  }

  /* ---------- public API ---------- */

  Future<void> startChatWithContext({
    required String contextString,
    required String parentItemId,
    required WorkbenchItemType parentItemType,
    required String parentServerId,
  }) async {
    final system = ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      role: Role.system,
      text: 'Context:\n$contextString',
      timestamp: DateTime.now().toUtc(),
    );

    final s = ChatSession(
      id: ChatSession.activeSessionId,
      contextItemId: parentItemId,
      contextItemType: parentItemType,
      contextServerId: parentServerId,
      messages: [system],
      lastUpdated: DateTime.now().toUtc(),
    );

    state = state.copyWith(session: s, isLoading: false, clearError: true);
    _persistSoon();
  }

  Future<void> sendMessage(String text) async {
    if (_model == null || state.isLoading || text.trim().isEmpty) return;

    final user = ChatMessage(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      role: Role.user,
      text: text,
      timestamp: DateTime.now().toUtc(),
    );
    final loading = ChatMessage.loading();

    final newMessages = [...state.session.messages, user, loading];
    state = state.copyWith(
      session: state.session.copyWith(messages: newMessages),
      isLoading: true,
      clearError: true,
    );
    _persistSoon();

    try {
      // history for startChat
      final history =
          state.session.messages
              .where((m) => m.role != Role.system && !m.isLoading)
              .map(
                (m) => gen_ai.Content(m.role == Role.user ? 'user' : 'model', [
                  gen_ai.TextPart(m.text),
                ]),
              )
              .toList();

      final chat = _model!.startChat(history: history);

      // build request content correctly
      final gen_ai.Content request = gen_ai.Content('user', [
        gen_ai.TextPart(text),
      ]);

      final reply = await chat.sendMessage(request) as gen_ai.Content;
      final replyText = reply.text ?? '';

      final modelMsg = ChatMessage(
        id: 'model_${DateTime.now().microsecondsSinceEpoch}',
        role: Role.model,
        text: replyText,
        timestamp: DateTime.now().toUtc(),
      );

      final replaced =
          state.session.messages
              .map((m) => m.isLoading ? modelMsg : m)
              .toList();

      state = state.copyWith(
        session: state.session.copyWith(
          messages: replaced,
          lastUpdated: DateTime.now().toUtc(),
        ),
        isLoading: false,
      );
    } catch (e) {
      final err = ChatMessage.error('Error: $e');
      final replaced =
          state.session.messages.map((m) => m.isLoading ? err : m).toList();
      state = state.copyWith(
        session: state.session.copyWith(
          messages: replaced,
          lastUpdated: DateTime.now().toUtc(),
        ),
        isLoading: false,
        errorMessage: e.toString(),
      );
    } finally {
      _persistSoon();
    }
  }

  Future<void> clearChat() async {
    state = state.copyWith(
      session: ChatSession.initial(),
      clearError: true,
      isLoading: false,
    );
    await _local.deleteActiveChatSession();
    await _cloud.deleteChatSession();
  }

  void clearErrorMessage() =>
      state.errorMessage == null
          ? null
          : state = state.copyWith(clearError: true);

  /* ---------- internal ---------- */

  void _persistSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final latest = state.session.copyWith(
        lastUpdated: DateTime.now().toUtc(),
      );
      await _local.saveActiveChatSession(latest);
      await _cloud.saveChatSession(latest);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

/* ---------- providers ---------- */

final localStorageServiceProvider = Provider<LocalStorageService>((_) {
  return LocalStorageService();
});

final chatSessionCloudKitServiceProvider = Provider<ChatSessionCloudKitService>(
  (_) {
    return ChatSessionCloudKitService();
  },
);

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(
    ref,
    ref.read(localStorageServiceProvider),
    ref.read(chatSessionCloudKitServiceProvider),
  ),
);
