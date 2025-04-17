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
  final bool isLoading; // For AI response loading
  final bool isInitializing; // For initial session load
  final bool isSyncing; // For manual cloud fetch loading
  final String? errorMessage;

  const ChatState({
    required this.session,
    this.isLoading = false,
    this.isInitializing = true,
    this.isSyncing = false, // Default to false
    this.errorMessage,
  });

  factory ChatState.initial() => ChatState(
    session: ChatSession.initial(),
    isInitializing: true,
    isSyncing: false, // Initialize
  );

  ChatState copyWith({
    ChatSession? session,
    bool? isLoading,
    bool? isInitializing,
    bool? isSyncing, // Add isSyncing
    String? errorMessage,
    bool clearError = false,
  }) => ChatState(
    session: session ?? this.session,
    isLoading: isLoading ?? this.isLoading,
    isInitializing: isInitializing ?? this.isInitializing,
    isSyncing: isSyncing ?? this.isSyncing, // Update copyWith
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
  );

  /* convenience getters used by UI */

  List<ChatMessage> get displayMessages => session.messages;
  String? get currentContextItemId => session.contextItemId;
  WorkbenchItemType? get currentContextItemType => session.contextItemType;
  String? get currentContextServerId => session.contextServerId;

  // Add equality check for isSyncing
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatState &&
          runtimeType == other.runtimeType &&
          session == other.session &&
          isLoading == other.isLoading &&
          isInitializing == other.isInitializing &&
          isSyncing == other.isSyncing && // Add isSyncing
          errorMessage == other.errorMessage;

  // Add hashing for isSyncing
  @override
  int get hashCode =>
      session.hashCode ^
      isLoading.hashCode ^
      isInitializing.hashCode ^
      isSyncing.hashCode ^ // Add isSyncing
      errorMessage.hashCode;
}


class ChatNotifier extends StateNotifier<ChatState> {
  final LocalStorageService _local;
  final ChatSessionCloudKitService _cloud;
  final ChatPersister _persister;
  bool _skipNextPersist = false;

  ChatNotifier(
    this._ref,
    LocalStorageService local,
    ChatSessionCloudKitService cloud, {
    ChatPersister? persister,
  }) : _local = local,
       _cloud = cloud,
       _persister = persister ?? DefaultChatPersister(local),
       super(ChatState.initial()) {
    _initGemini();
    _loadInitialSession();
  }

  final Ref _ref;
  gen_ai.GenerativeModel? _model;
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  /* ---------- initialisation ---------- */

  void _initGemini() {
    final key = _ref.read(geminiApiKeyProvider);
    if (key.isEmpty) return;
    _model = gen_ai.GenerativeModel(
      model: 'gemini-1.5-flash-latest',
      apiKey: key,
      // Add safety settings if needed
      safetySettings: [
        gen_ai.SafetySetting(
          gen_ai.HarmCategory.dangerousContent,
          gen_ai.HarmBlockThreshold.none,
        ),
        gen_ai.SafetySetting(
          gen_ai.HarmCategory.sexuallyExplicit,
          gen_ai.HarmBlockThreshold.none,
        ),
        gen_ai.SafetySetting(
          gen_ai.HarmCategory.hateSpeech,
          gen_ai.HarmBlockThreshold.none,
        ),
        gen_ai.SafetySetting(
          gen_ai.HarmCategory.harassment,
          gen_ai.HarmBlockThreshold.none,
        ),
      ],
    );
    _ref.listen(geminiApiKeyProvider, (_, next) {
      _model =
          next.isEmpty
              ? null
              : gen_ai.GenerativeModel(
                model: 'gemini-1.5-flash-latest',
                apiKey: next,
                // Repeat safety settings here too
                safetySettings: [
                  gen_ai.SafetySetting(
                    gen_ai.HarmCategory.dangerousContent,
                    gen_ai.HarmBlockThreshold.none,
                  ),
                  gen_ai.SafetySetting(
                    gen_ai.HarmCategory.sexuallyExplicit,
                    gen_ai.HarmBlockThreshold.none,
                  ),
                  gen_ai.SafetySetting(
                    gen_ai.HarmCategory.hateSpeech,
                    gen_ai.HarmBlockThreshold.none,
                  ),
                  gen_ai.SafetySetting(
                    gen_ai.HarmCategory.harassment,
                    gen_ai.HarmBlockThreshold.none,
                  ),
                ],
              );
    });
  }

  Future<void> _loadInitialSession() async {
    // Keep existing initial load logic...
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

    ChatSession chosen = ChatSession.initial(); // Default to empty

    if (cloud != null && local != null) {
      if (cloud.lastUpdated.isAfter(local.lastUpdated)) {
        chosen = cloud;
        if (kDebugMode)
          print("[ChatNotifier] Init: Using newer Cloud session.");
        // Update local with newer cloud version
        await _local.saveActiveChatSession(chosen);
      } else {
        chosen = local;
        if (kDebugMode)
          print("[ChatNotifier] Init: Using newer/same Local session.");
        // Update cloud with newer local version (optional, can cause loops if not careful)
        // await _cloud.saveChatSession(chosen); // Avoid potential loops for now
      }
    } else if (cloud != null) {
      chosen = cloud;
      if (kDebugMode)
        print("[ChatNotifier] Init: Using Cloud session (local missing).");
      // Save to local if it didn't exist
      await _local.saveActiveChatSession(chosen);
    } else if (local != null) {
      chosen = local;
      if (kDebugMode)
        print("[ChatNotifier] Init: Using Local session (cloud missing).");
      // Save to cloud if it didn't exist
      await _cloud.saveChatSession(chosen);
    } else {
      if (kDebugMode) print("[ChatNotifier] Init: No existing session found.");
      // No need to save initial empty session yet
    }

    // Ensure state is updated only if mounted
    if (mounted) {
      state = state.copyWith(session: chosen, isInitializing: false);
    }
  }

  /* ---------- public API ---------- */

  Future<void> startChatWithContext({
    required String contextString,
    required String parentItemId,
    required WorkbenchItemType parentItemType,
    required String parentServerId,
  }) async {
    // Keep existing startChatWithContext logic...
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
    // Keep existing sendMessage logic...
    if (_model == null || state.isLoading || text.trim().isEmpty) return;

    final user = ChatMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}', // Use milliseconds
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
    _persistSoon(); // Save intermediate state with user message + loading

    try {
      // history for startChat
      final history =
          state.session.messages
              .where(
                (m) => m.role != Role.system && !m.isLoading,
              ) // Exclude system/loading
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

      // Use generateContent for single response
      final response = await chat.sendMessage(request);
      // Access text directly from response (assuming it's GenerateContentResponse)
      final replyText = response.text;

      if (replyText == null) {
        throw Exception("Received null response from API.");
      }

      final modelMsg = ChatMessage(
        id: 'model_${DateTime.now().millisecondsSinceEpoch}', // Use milliseconds
        role: Role.model,
        text: replyText,
        timestamp: DateTime.now().toUtc(),
      );

      // Replace loading indicator with model response
      final replaced =
          state.session.messages
              .map((m) => m.isLoading ? modelMsg : m)
              .toList();

      state = state.copyWith(
        session: state.session.copyWith(
          messages: replaced,
          lastUpdated: DateTime.now().toUtc(), // Update timestamp
        ),
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) print("[ChatNotifier] SendMessage Error: $e");
      final err = ChatMessage.error('Error: $e');
      // Replace loading indicator with error message
      final replaced =
          state.session.messages.map((m) => m.isLoading ? err : m).toList();
      state = state.copyWith(
        session: state.session.copyWith(
          messages: replaced,
          lastUpdated: DateTime.now().toUtc(), // Update timestamp even on error
        ),
        isLoading: false,
        errorMessage: "Failed to get response from AI. ${e.toString()}",
      );
    } finally {
      _persistSoon(); // Save final state
    }
  }

  Future<void> clearChat() async {
    // Keep existing clearChat logic...
    state = state.copyWith(
      session: ChatSession.initial(),
      clearError: true,
      isLoading: false,
      isSyncing: false, // Ensure syncing is false if chat is cleared
    );
    await _local.deleteActiveChatSession();
    await _cloud.deleteChatSession();
  }

  void clearErrorMessage() =>
      state.errorMessage == null
          ? null
          : state = state.copyWith(clearError: true);

  // --- NEW: Manual Fetch from Cloud ---
  Future<void> forceFetchFromCloud() async {
    if (state.isSyncing || state.isInitializing)
      return; // Prevent concurrent fetches

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
        // Overwrite local state with the fetched cloud session
        state = state.copyWith(session: cloudSession, isSyncing: false);
        // Also update local storage to match the fetched cloud version
        await _persister.save(cloudSession);
        if (kDebugMode)
          print(
            "[ChatNotifier] Updated local state and storage with fetched CloudKit session.",
          );
      } else {
        // No session found in CloudKit
        if (kDebugMode)
          print("[ChatNotifier] No chat session found in CloudKit.");
        // Optionally clear local state or show a message
        // For now, just stop syncing and keep local state
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

  /* ---------- internal ---------- */

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
