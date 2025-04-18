import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Import WidgetsBinding
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart';
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
  WorkbenchItemType? get currentContextItemType =>
      session.contextItemType;
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
  // ignore: unused_field
  final Ref _ref;
  final LocalStorageService _local;
  final ChatSessionCloudKitService _cloud;
  final ChatPersister _persister;
  final ChatAiBackend _ai;

  bool _skipNextPersist = false;
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);

  // Flag to indicate if context was set externally (e.g., via route arguments)
  bool _hasExternalContext = false;

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
      // Use addPostFrameCallback to ensure _loadInitialSession runs *after*
      // any potential immediate calls to startChatWithContext from didChangeDependencies.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only load if no external context was set during the first frame.
        if (!_hasExternalContext && mounted) {
          _loadInitialSession();
        } else if (mounted) {
          // If external context *was* set, ensure initializing is false.
          // The session state is already set by startChatWithContext.
          state = state.copyWith(isInitializing: false);
          if (kDebugMode) {
            print(
              "[ChatNotifier] Skipping initial load due to external context.",
            );
          }
        }
      });
    } else {
      // If autoInit is false, ensure initializing is also false.
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _loadInitialSession() async {
    // This method is now called *after* the first frame,
    // so _hasExternalContext check in constructor handles the race condition.
    // No need for the check here anymore.

    // Ensure we don't run if the notifier is disposed during the async gap.
    if (!mounted) return;

    // Set initializing true *before* loading, but only if we are actually loading.
    // If called manually (e.g., force fetch), isInitializing might already be false.
    if (state.isInitializing) {
      // Already set to true by default or constructor logic handles it.
    } else {
      // If called later (e.g. after clear), mark as initializing again.
      // This path shouldn't normally be hit with the current logic, but added for safety.
      state = state.copyWith(isInitializing: true);
    }


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

    // Ensure still mounted after async operations
    if (!mounted) return;

    ChatSession chosen = ChatSession.initial();

    if (cloud != null && local != null) {
      if (cloud.lastUpdated.isAfter(local.lastUpdated)) {
        chosen = cloud;
        if (kDebugMode) {
          print("[ChatNotifier] Init: Using newer Cloud session.");
        }
        // Don't save locally here, let persistSoon handle it if needed.
        // await _local.saveActiveChatSession(chosen);
      } else {
        chosen = local;
        if (kDebugMode) {
          print("[ChatNotifier] Init: Using newer/same Local session.");
        }
      }
    } else if (cloud != null) {
      chosen = cloud;
      if (kDebugMode) {
        print("[ChatNotifier] Init: Using Cloud session (local missing).");
      }
      // Don't save locally here.
      // await _local.saveActiveChatSession(chosen);
    } else if (local != null) {
      chosen = local;
      if (kDebugMode) {
        print("[ChatNotifier] Init: Using Local session (cloud missing).");
      }
      // Don't save to cloud here.
      // await _cloud.saveChatSession(chosen);
    } else {
      if (kDebugMode) print("[ChatNotifier] Init: No existing session found.");
    }

    // Only update state if the chosen session is different from the current one
    // to avoid unnecessary rebuilds. Also check mounted again.
    if (mounted && state.session != chosen) {
      state = state.copyWith(session: chosen, isInitializing: false);
      // Persist the chosen session if it came from cloud or was different from local
      if ((cloud != null && chosen == cloud) ||
          (local != null && chosen == local)) {
        _persistSoon(); // Save the chosen session (local and cloud)
      } else if (cloud == null && local == null) {
        // If it's a brand new initial session, persist it.
        _persistSoon();
      }
    } else if (mounted) {
      // If session is the same, just ensure initializing is false.
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> startChatWithContext({
    required String contextString,
    required String parentItemId,
    required WorkbenchItemType parentItemType,
    required String parentServerId,
  }) async {
    // Set the flag *before* updating state.
    // This prevents _loadInitialSession (if called later) from overwriting.
    _hasExternalContext = true;
    if (kDebugMode)
      print(
        "[ChatNotifier] startChatWithContext called, setting _hasExternalContext = true.",
      );


    final system = ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      role: Role.system,
      text: 'Context:\n$contextString',
      timestamp: DateTime.now().toUtc(),
    );

    final s = ChatSession(
      id: ChatSession.activeSessionId,
      contextItemId: parentItemId,
      // ChatSession expects a nullable enum, so pass the enum with explicit cast
      contextItemType: parentItemType as WorkbenchItemType?,
      contextServerId: parentServerId,
      messages: [system],
      lastUpdated: DateTime.now().toUtc(),
    );

    // Update state and ensure initializing is false, as we now have a session.
    state = state.copyWith(
      session: s,
      isLoading: false,
      clearError: true,
      isInitializing: false,
    );
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
      // Ensure mounted before accessing state after await
      if (!mounted) return;
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
      // Ensure mounted before accessing state after await
      if (!mounted) return;
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
      // Ensure mounted before calling persist
      if (mounted) {
        _persistSoon();
      }
    }
  }

  Future<void> clearChat() async {
    // Reset the external context flag when clearing
    _hasExternalContext = false;
    state = state.copyWith(
      session: ChatSession.initial(),
      clearError: true,
      isLoading: false,
      isSyncing: false,
      // Keep isInitializing false, as we have an initial (empty) session
      isInitializing: false,
    );
    await _local.deleteActiveChatSession();
    await _cloud.deleteChatSession();
    // No need to call persistSoon as we just deleted everything.
  }

  void clearErrorMessage() =>
      state.errorMessage == null
          ? null
          : state = state.copyWith(clearError: true);

  Future<void> forceFetchFromCloud() async {
    if (state.isSyncing || state.isInitializing) {
      return;
    }

    if (kDebugMode) {
      print("[ChatNotifier] Starting manual fetch from CloudKit...");
    }
    // Reset external context flag on manual fetch, assuming user wants cloud version
    _hasExternalContext = false;
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      final cloudSession = await _cloud.getChatSession();
      _skipNextPersist = true; // Prevent immediate save back to cloud

      // Ensure mounted after await
      if (!mounted) return;

      if (cloudSession != null) {
        if (kDebugMode) {
          print(
            "[ChatNotifier] Fetched session from CloudKit (LastUpdated: ${cloudSession.lastUpdated}). Current local LastUpdated: ${state.session.lastUpdated}",
          );
        }
        // Update state with the fetched session
        state = state.copyWith(
          session: cloudSession,
          isSyncing: false,
          isInitializing: false,
        );
        // Save the fetched session locally
        await _local.saveActiveChatSession(cloudSession);
        if (kDebugMode) {
          print(
            "[ChatNotifier] Updated local state and storage with fetched CloudKit session.",
          );
        }
      } else {
        if (kDebugMode) {
          print("[ChatNotifier] No chat session found in CloudKit.");
        }
        // If no cloud session, potentially clear local? Or keep local?
        // Current behaviour: Keep local, show error.
        state = state.copyWith(
          isSyncing: false,
          errorMessage: "No chat session found in iCloud.",
          isInitializing:
              false, // Ensure initializing is false even if cloud fetch fails
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("[ChatNotifier] Error during forceFetchFromCloud: $e");
      }
      // Ensure mounted after await
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: "Failed to fetch from iCloud: ${e.toString()}",
        isInitializing: false, // Ensure initializing is false on error
      );
    } finally {
      _skipNextPersist = false; // Re-enable persistence
    }
  }

  void _persistSoon() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      if (_skipNextPersist) {
        _skipNextPersist = false;
        if (kDebugMode) print("[ChatNotifier] Skipping debounced save.");
        return;
      }
      if (!mounted) {
        if (kDebugMode)
          print("[ChatNotifier] Skipping debounced save (unmounted).");
        return;
      }
      // Create a final copy of the session to save
      final sessionToSave = state.session.copyWith(
        lastUpdated: DateTime.now().toUtc(),
      );
      // Update state silently with just the new timestamp before saving
      // This prevents potential race conditions if state changes again quickly
      // state = state.copyWith(session: sessionToSave); // Avoid this - causes rebuilds

      try {
        await _persister.save(sessionToSave);
        await _cloud.saveChatSession(sessionToSave);
        if (kDebugMode)
          print(
            "[ChatNotifier] Debounced save complete for session updated at ${sessionToSave.lastUpdated}.",
          );
      } catch (e) {
        if (kDebugMode) print("[ChatNotifier] Error during debounced save: $e");
        // Optionally set an error state here if persistence fails critically
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// --- Test Config and Providers (No changes needed below this line) ---

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
  // Ensure autoInit is false for testing setup unless explicitly needed
  return ChatNotifier(
    ref,
    cfg.local,
    cfg.cloud,
    persister: cfg.persister,
    ai: cfg.ai!,
    autoInit: false, // Typically false for controlled testing
  );
});

final localStorageServiceProvider = Provider<LocalStorageService>((_) {
  // Assuming LocalStorageService has a synchronous constructor or uses getInstance internally
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
    // autoInit defaults to true, constructor handles the logic
  ),
);
