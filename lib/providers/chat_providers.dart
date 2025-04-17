import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/service_providers.dart'
    show chatAiFacadeProvider;
import 'package:flutter_memos/services/chat_ai.dart'; // new
import 'package:flutter_memos/services/chat_session_cloud_kit_service.dart';
import 'package:flutter_memos/services/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;

abstract class ChatPersister {
  Future<void> save(ChatSession session);
}

class DefaultChatPersister implements ChatPersister {
  final LocalStorageService _local;

  DefaultChatPersister(this._local);

  @override
  Future<void> save(ChatSession session) async {
    await _local.saveActiveChatSession(session);
  }
}

@immutable
class ChatState {
  final ChatSession session;
  final bool isLoading;
  final bool isInitializing;
  final bool isSyncing;
  final String? errorMessage;

  const ChatState({
    required this.session,
    this.isLoading = false,
    this.isInitializing = true,
    this.isSyncing = false,
    this.errorMessage,
  });

  factory ChatState.initial() => ChatState(
    session: ChatSession.initial(),
    isInitializing: true,
    isSyncing: false,
  );

  ChatState copyWith({
    ChatSession? session,
    bool? isLoading,
    bool? isInitializing,
    bool? isSyncing,
    String? errorMessage,
    bool clearError = false,
  }) => ChatState(
    session: session ?? this.session,
    isLoading: isLoading ?? this.isLoading,
    isInitializing: isInitializing ?? this.isInitializing,
    isSyncing: isSyncing ?? this.isSyncing,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  List<ChatMessage> get displayMessages => session.messages;
  String? get currentContextItemId => session.contextItemId;
  WorkbenchItemType? get currentContextItemType => session.contextItemType;
  String? get currentContextServerId => session.contextServerId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          isLoading == other.isLoading &&
          isInitializing == other.isInitializing &&
          isSyncing == other.isSyncing &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode =>
      session.hashCode ^
      isLoading.hashCode ^
      isInitializing.hashCode ^
      isSyncing.hashCode ^
      errorMessage.hashCode;
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final LocalStorageService _local;
  final ChatSessionCloudKitService _cloud;
  final ChatPersister _persister;
  final ChatAiBackend _ai;

  bool _skipNextPersist = false;
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  ChatNotifier(
    this._ref,
    LocalStorageService local,
    ChatSessionCloudKitService cloud, {
    ChatPersister? persister,
    required ChatAiBackend ai,
    bool autoInit = true,
  }) : _local = local,
       _cloud = cloud,
       _persister = persister ?? DefaultChatPersister(local),
       _ai = ai,
       super(ChatState.initial()) {
    if (autoInit) {
      _loadInitialSession();
    }
  }

  Future<void> _loadInitialSession() async {
    ChatSession? cloud;
    ChatSession? local;
    try {
      cloud = await _cloud.getChatSession();
    } catch (e) {
      if (kDebugMode) print("[ChatNotifier] CloudKit fetch error on init: $e");
    }
    try {
      local = await _local.loadActiveChatSession();
    } catch (e) {
      if (kDebugMode) print("[ChatNotifier] Local load error on init: $e");
    }

    ChatSession chosen = ChatSession.initial();

    if (cloud != null && local != null) {
      if (cloud.lastUpdated.isAfter(local.lastUpdated)) {
        chosen = cloud;
        if (kDebugMode)
          print("[ChatNotifier] Init: Using newer Cloud session.");
        await _local.saveActiveChatSession(chosen);
      } else {
        chosen = local;
        if (kDebugMode)
          print("[ChatNotifier] Init: Using newer/same Local session.");
      }
    } else if (cloud != null) {
      chosen = cloud;
      if (kDebugMode)
        print("[ChatNotifier] Init: Using Cloud session (local missing).");
      await _local.saveActiveChatSession(chosen);
    } else if (local != null) {
      chosen = local;
      if (kDebugMode)
        print("[ChatNotifier] Init: Using Local session (cloud missing).");
      await _cloud.saveChatSession(chosen);
    } else {
      if (kDebugMode) print("[ChatNotifier] Init: No existing session found.");
    }

    if (mounted) {
      state = state.copyWith(session: chosen, isInitializing: false);
    }
  }

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
    if (state.isLoading || text.trim().isEmpty) return;

    final user = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
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
      final history =
          state.session.messages
              .where((m) => m.role != Role.system && !m.isLoading)
              .map(
                (m) => gen_ai.Content(m.role == Role.user ? 'user' : 'model', [
                  gen_ai.TextPart(m.text),
                ]),
              )
              .toList();

      final resp = await _ai.send(history, text);
      final replyText = resp.text;

      final modelMsg = ChatMessage(
        id: 'model_${DateTime.now().millisecondsSinceEpoch}',
        role: Role.model,
        text: replyText,
        timestamp: DateTime.now().toUtc(),
      );

      // Replace loading indicator with AI response
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
      if (kDebugMode) print("[ChatNotifier] SendMessage Error: $e");
      final err = ChatMessage.error('Error: $e');
      final replaced =
          state.session.messages.map((m) => m.isLoading ? err : m).toList();
      state = state.copyWith(
        session: state.session.copyWith(
          messages: replaced,
          lastUpdated: DateTime.now().toUtc(),
        ),
        isLoading: false,
        errorMessage: "Failed to get response from AI. ${e.toString()}",
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
      isSyncing: false,
    );
    await _local.deleteActiveChatSession();
    await _cloud.deleteChatSession();
  }

  void clearErrorMessage() =>
      state.errorMessage == null
          ? null
          : state = state.copyWith(clearError: true);

  Future<void> forceFetchFromCloud() async {
    if (state.isSyncing || state.isInitializing) return;

    if (kDebugMode)
      print("[ChatNotifier] Starting manual fetch from CloudKit...");
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final cloudSession = await _cloud.getChatSession();
      _skipNextPersist = true;
      if (cloudSession != null) {
        if (kDebugMode) {
          print(
            "[ChatNotifier] Fetched session from CloudKit (LastUpdated: ${cloudSession.lastUpdated}). Current local LastUpdated: ${state.session.lastUpdated}",
          );
        }
        state = state.copyWith(session: cloudSession, isSyncing: false);
        await _persister.save(cloudSession);
        if (kDebugMode)
          print(
            "[ChatNotifier] Updated local state and storage with fetched CloudKit session.",
          );
      } else {
        if (kDebugMode)
          print("[ChatNotifier] No chat session found in CloudKit.");
        state = state.copyWith(
          isSyncing: false,
          errorMessage: "No chat session found in iCloud.",
        );
      }
    } catch (e) {
      if (kDebugMode)
        print("[ChatNotifier] Error during forceFetchFromCloud: $e");
      state = state.copyWith(
        isSyncing: false,
        errorMessage: "Failed to fetch from iCloud: ${e.toString()}",
      );
    }
  }

  void _persistSoon() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      if (_skipNextPersist) {
        _skipNextPersist = false;
        return;
      }
      if (!mounted) return;
      final latest = state.session.copyWith(
        lastUpdated: DateTime.now().toUtc(),
      );
      await _persister.save(latest);
      await _cloud.saveChatSession(latest);
      if (kDebugMode) print("[ChatNotifier] Debounced save complete.");
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

class ChatNotifierTestConfig {
  final LocalStorageService local;
  final ChatSessionCloudKitService cloud;
  final ChatPersister? persister;
  final ChatAiBackend? ai;

  ChatNotifierTestConfig({
    required this.local,
    required this.cloud,
    this.persister,
    this.ai,
  });
}

final chatProviderTesting = StateNotifierProvider.family<
  ChatNotifier,
  ChatState,
  ChatNotifierTestConfig
>((ref, cfg) {
  return ChatNotifier(
    ref,
    cfg.local,
    cfg.cloud,
    persister: cfg.persister,
    ai: cfg.ai!,
    autoInit: false,
  );
});

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
    ai: ref.read(chatAiFacadeProvider),
  ),
);
