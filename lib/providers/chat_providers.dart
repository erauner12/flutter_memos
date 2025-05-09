import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart'; // Import WidgetsBinding
import 'package:flutter_memos/models/chat_message.dart';
import 'package:flutter_memos/models/chat_session.dart';
import 'package:flutter_memos/models/workbench_item_type.dart';
// Import service providers correctly
import 'package:flutter_memos/providers/service_providers.dart'
    show
        minimalOpenAiServiceProvider,
        supabaseDataServiceProvider; // Add supabaseDataServiceProvider
import 'package:flutter_memos/services/chat_ai.dart'; // Use ChatAiBackend, ChatAiFacade, OpenAiGptBackend
// Removed ChatSessionCloudKitService import
import 'package:flutter_memos/services/local_storage_service.dart';
// Import MCP client provider with prefix to avoid ambiguity
import 'package:flutter_memos/services/mcp_client_service.dart' as mcp_service; // For McpClientNotifier
import 'package:flutter_memos/services/supabase_data_service.dart'; // Import SupabaseDataService
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart' as gen_ai;

// --- ChatPersister and DefaultChatPersister (No changes needed) ---
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

// --- ChatState (No changes needed) ---
@immutable
class ChatState {
  final ChatSession session;
  final bool isLoading;
  final bool isInitializing;
  final bool isSyncing; // Kept for potential future Supabase sync indicator
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

// --- ChatNotifier ---
class ChatNotifier extends StateNotifier<ChatState> {
  final Ref _ref;
  final LocalStorageService _local;
  // Replace ChatSessionCloudKitService with SupabaseDataService
  final SupabaseDataService _supabase;
  final ChatPersister _persister;
  final ChatAiBackend _ai; // This remains the same interface

  bool _skipNextPersist = false;
  Timer? _debounce;
  final Duration _debounceDuration = const Duration(milliseconds: 500);
  bool _hasExternalContext = false;

  ChatNotifier(
    this._ref,
    LocalStorageService local,
    // Update constructor parameter type
    SupabaseDataService supabase, {
    ChatPersister? persister,
    required ChatAiBackend ai, // Injected dependency
    bool autoInit = true,
  }) : _local = local,
       _supabase = supabase, // Assign Supabase service
       _persister = persister ?? DefaultChatPersister(local),
       _ai = ai, // Assign the injected AI backend facade
       super(ChatState.initial()) {
    if (autoInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_hasExternalContext && mounted) {
          _loadInitialSession();
        } else if (mounted) {
          state = state.copyWith(isInitializing: false);
          if (kDebugMode) {
            print(
              "[ChatNotifier] Skipping initial load due to external context.",
            );
          }
        }
      });
    } else {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> _loadInitialSession() async {
    if (!mounted) return;
    if (!state.isInitializing) {
      // If already initialized (e.g. by external context), don't reload
    }

    ChatSession? supabaseSession;
    ChatSession? localSession;
    try {
      // Fetch from Supabase instead of CloudKit
      supabaseSession = await _supabase.getChatSession(
        ChatSession.activeSessionId,
      );
    } catch (e) {
      if (kDebugMode) {
        print("[ChatNotifier] Supabase fetch error on init: $e");
      }
    }
    try {
      localSession = await _local.loadActiveChatSession();
    } catch (e) {
      if (kDebugMode) {
        print("[ChatNotifier] Local load error on init: $e");
      }
    }

    if (!mounted) return;

    ChatSession chosen = ChatSession.initial();

    // Compare Supabase and Local sessions
    if (supabaseSession != null && localSession != null) {
      chosen =
          supabaseSession.lastUpdated.isAfter(localSession.lastUpdated)
              ? supabaseSession
              : localSession;
      if (kDebugMode) {
        print(
          "[ChatNotifier] Init: Using ${chosen == supabaseSession ? 'Supabase' : 'Local'} session.",
        );
      }
    } else if (supabaseSession != null) {
      chosen = supabaseSession;
      if (kDebugMode) {
        print("[ChatNotifier] Init: Using Supabase session (local missing).");
      }
    } else if (localSession != null) {
      chosen = localSession;
      if (kDebugMode) {
        print("[ChatNotifier] Init: Using Local session (Supabase missing).");
      }
    } else {
      if (kDebugMode) {
        print("[ChatNotifier] Init: No existing session found.");
      }
    }

    if (mounted && state.session != chosen) {
      state = state.copyWith(session: chosen, isInitializing: false);
      _persistSoon(); // Persist if a session was loaded or newly created
    } else if (mounted) {
      state = state.copyWith(isInitializing: false);
    }
  }

  Future<void> startChatWithContext({
    required String contextString,
    required String parentItemId,
    required WorkbenchItemType parentItemType,
    required String parentServerId,
  }) async {
    _hasExternalContext = true;
    if (kDebugMode) {
      print("[ChatNotifier] startChatWithContext called.");
    }

    final system = ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      role: Role.system,
      text: 'Context for ${parentItemType.name} $parentItemId:\n$contextString',
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

    state = state.copyWith(
      session: s,
      isLoading: false,
      clearError: true,
      isInitializing: false, // We have initialized with context
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

    final currentMessages = [...state.session.messages];
    final newMessages = [...currentMessages, user, loading];

    state = state.copyWith(
      session: state.session.copyWith(messages: newMessages),
      isLoading: true,
      clearError: true,
    );
    _persistSoon();

    try {
      final history =
          currentMessages.where((m) => !m.isLoading).map((m) {
            final roleString = switch (m.role) {
              Role.user => 'user',
              Role.model => 'model',
              Role.system => 'system',
              Role.function => 'function',
            };
            return gen_ai.Content(roleString, [gen_ai.TextPart(m.text)]);
          }).toList();

      if (kDebugMode) {
        print(
          "[ChatNotifier] Sending message. History size: ${history.length}",
        );
      }

      final resp = await _ai.send(history, text);
      final replyText = resp.text;

      final modelMsg = ChatMessage(
        id: 'model_${DateTime.now().millisecondsSinceEpoch}',
        role: Role.model,
        text: replyText,
        timestamp: DateTime.now().toUtc(),
      );

      if (!mounted) return;
      final finalMessages =
          state.session.messages
              .map((m) => m.isLoading ? modelMsg : m)
              .toList();

      state = state.copyWith(
        session: state.session.copyWith(
          messages: finalMessages,
          lastUpdated: DateTime.now().toUtc(),
        ),
        isLoading: false,
      );
    } catch (e) {
      if (kDebugMode) {
        print("[ChatNotifier] SendMessage Error: $e");
      }
      final err = ChatMessage.error('Error: $e');
      if (!mounted) return;
      final finalMessages =
          state.session.messages.map((m) => m.isLoading ? err : m).toList();
      state = state.copyWith(
        session: state.session.copyWith(
          messages: finalMessages,
          lastUpdated: DateTime.now().toUtc(),
        ),
        isLoading: false,
        errorMessage: "Failed to get response from AI. ${e.toString()}",
      );
    } finally {
      if (mounted) {
        _persistSoon();
      }
    }
  }

  Future<void> clearChat() async {
    _hasExternalContext = false;
    final sessionId = state.session.id; // Get ID before clearing state
    state = state.copyWith(
      session: ChatSession.initial(),
      clearError: true,
      isLoading: false,
      isSyncing: false,
      isInitializing: false,
    );
    await _local.deleteActiveChatSession();
    // Delete from Supabase instead of CloudKit
    await _supabase.deleteChatSession(sessionId);
  }

  /// Clears the context information (item ID, type, server ID) from the current chat session.
  void clearChatContext() {
    if (state.session.contextItemId == null &&
        state.session.contextItemType == null) {
      // No context to clear
      return;
    }
    if (kDebugMode) {
      print("[ChatNotifier] Clearing chat context.");
    }
    // Create a new session instance with context fields set to null
    final clearedSession = state.session.copyWith(
      contextItemId: null,
      contextItemType: null,
      contextServerId: null,
      lastUpdated: DateTime.now().toUtc(),
    );
    state = state.copyWith(session: clearedSession);
    _persistSoon();
  }

  void clearErrorMessage() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  // Renamed forceFetchFromCloud to forceFetchFromSupabase for clarity
  Future<void> forceFetchFromSupabase() async {
    if (state.isSyncing || state.isInitializing) return;

    if (kDebugMode) {
      print("[ChatNotifier] Starting manual fetch from Supabase...");
    }
    _hasExternalContext = false;
    state = state.copyWith(isSyncing: true, clearError: true);

    try {
      // Fetch from Supabase
      final supabaseSession = await _supabase.getChatSession(
        ChatSession.activeSessionId,
      );
      _skipNextPersist = true;

      if (!mounted) return;

      if (supabaseSession != null) {
        if (kDebugMode) {
          print("[ChatNotifier] Fetched session from Supabase.");
        }
        state = state.copyWith(
          session: supabaseSession,
          isSyncing: false,
          isInitializing: false,
        );
        await _local.saveActiveChatSession(supabaseSession);
        if (kDebugMode) {
          print("[ChatNotifier] Updated local state with Supabase session.");
        }
      } else {
        if (kDebugMode) {
          print("[ChatNotifier] No chat session found in Supabase.");
        }
        state = state.copyWith(
          isSyncing: false,
          errorMessage: "No chat session found in Supabase.",
          isInitializing: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print("[ChatNotifier] Error during forceFetchFromSupabase: $e");
      }
      if (!mounted) return;
      state = state.copyWith(
        isSyncing: false,
        errorMessage: "Failed to fetch from Supabase: ${e.toString()}",
        isInitializing: false,
      );
    } finally {
      _skipNextPersist = false;
    }
  }

  void _persistSoon() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () async {
      if (_skipNextPersist) {
        _skipNextPersist = false;
        if (kDebugMode) {
          print("[ChatNotifier] Skipping debounced save.");
        }
        return;
      }
      if (!mounted) {
        if (kDebugMode) {
          print("[ChatNotifier] Skipping debounced save (unmounted).");
        }
        return;
      }
      final sessionToSave = state.session.copyWith(
        lastUpdated: DateTime.now().toUtc(),
      );

      try {
        // No need to update state here just for timestamp
        await _persister.save(sessionToSave); // Save locally
        // Save to Supabase instead of CloudKit
        await _supabase.saveChatSession(sessionToSave);
        if (kDebugMode) {
          print("[ChatNotifier] Debounced save complete (Local & Supabase).");
        }
      } catch (e) {
        if (kDebugMode) {
          print("[ChatNotifier] Error during debounced save: $e");
        }
        // Optionally update state with error message
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

// --- Providers ---

// chatAiFacadeProvider: Now instantiates ChatAiFacade with OpenAiGptBackend
final chatAiFacadeProvider = Provider<ChatAiBackend>((ref) {
  // Create the OpenAI backend, providing the MinimalOpenAiService instance
  final openAiBackend = OpenAiGptBackend(
    ref.watch(minimalOpenAiServiceProvider),
    // Optionally configure defaultModel: 'gpt-4' or 'gpt-4o' here if needed
    // defaultModel: 'gpt-4o',
  );

  // Get the MCP Notifier
  final mcpNotifier = ref.watch(mcp_service.mcpClientProvider.notifier);

  // Return the Facade, using openAiBackend as the default
  return ChatAiFacade(
    defaultBackend: openAiBackend, // Use the new OpenAI backend
    mcpNotifier: mcpNotifier,
  );
});

// --- Other Service Providers (No changes needed) ---
final localStorageServiceProvider = Provider<LocalStorageService>((_) {
  return LocalStorageService();
});

// Removed chatSessionCloudKitServiceProvider
// final chatSessionCloudKitServiceProvider = Provider<ChatSessionCloudKitService>(
//   (_) {
//     return ChatSessionCloudKitService();
//   },
// );

// --- Main Chat Provider ---
final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
  (ref) => ChatNotifier(
    ref,
    ref.read(localStorageServiceProvider),
    // Provide SupabaseDataService instead of ChatSessionCloudKitService
    ref.read(supabaseDataServiceProvider),
    ai: ref.read(chatAiFacadeProvider), // Reads the configured facade
  ),
);

// --- Test Config Provider ---
class ChatNotifierTestConfig {
  final LocalStorageService local;
  // Replace ChatSessionCloudKitService with SupabaseDataService
  final SupabaseDataService supabase;
  final ChatPersister? persister;
  final ChatAiBackend ai; // Keep as ChatAiBackend, could be mock, OpenAI, etc.

  ChatNotifierTestConfig({
    required this.local,
    // Update parameter name
    required this.supabase,
    this.persister,
    required this.ai, // Make AI required for clarity
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
    // Pass Supabase service
    cfg.supabase,
    persister: cfg.persister,
    ai: cfg.ai, // Pass the provided AI backend
    autoInit: false,
  );
});
