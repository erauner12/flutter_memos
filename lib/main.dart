import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show ThemeMode; // Keep Material import ONLY for ThemeMode enum
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:flutter_memos/models/workbench_item_type.dart';
// Removed chat overlay provider import
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings providers
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
// Removed chat overlay import
import 'package:flutter_memos/screens/chat_screen.dart'; // Keep for potential direct navigation
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart';
import 'package:flutter_memos/screens/items/items_screen.dart'; // Import ItemsScreen
import 'package:flutter_memos/screens/new_note/new_note_screen.dart';
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Keep for other shortcuts
import 'package:flutter_memos/utils/provider_logger.dart';
import 'package:flutter_memos/widgets/config_check_wrapper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return rootNavigatorKey;
});

Route<dynamic>? generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    print(
      '[RootNavigator] Generating route for: ${settings.name} with args: ${settings.arguments}',
    );
  }
  switch (settings.name) {
    case '/':
      return null; // Handled by home in CupertinoApp
    case '/chat':
      // Pass arguments directly to ChatScreen if needed via settings
      return CupertinoPageRoute(
        builder: (_) => const ChatScreen(), // ChatScreen is now a regular route
        settings: settings,
      );
    case '/item-detail':
      final args = settings.arguments as Map<String, dynamic>?;
      final itemId = args?['itemId'] as String?;
      final serverId =
          args?['serverId'] as String?; // Optional serverId for context
      if (itemId != null) {
        // Potentially pass serverId if ItemDetailScreen needs it
        return CupertinoPageRoute(
          builder: (_) => ItemDetailScreen(itemId: itemId),
          settings: settings,
        );
      }
      break;
    case '/edit-entity':
      final args = settings.arguments as Map<String, dynamic>?;
      final entityType = args?['entityType'] as String? ?? 'note';
      final entityId = args?['entityId'] as String?;
      final serverId =
          args?['serverId'] as String?; // Optional serverId for context
      if (entityId != null) {
        // Potentially pass serverId if EditEntityScreen needs it
        return CupertinoPageRoute(
          builder:
              (_) =>
                  EditEntityScreen(entityId: entityId, entityType: entityType),
          settings: settings,
        );
      }
      break;
    case '/new-note':
      final args = settings.arguments as Map<String, dynamic>?;
      final serverId =
          args?['serverId'] as String?; // Optional serverId for context
      // Potentially pass serverId if NewNoteScreen needs it
      return CupertinoPageRoute(
        builder: (_) => const NewNoteScreen(),
        settings: settings,
      );
    case '/deep-link-target':
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      final itemId = args['itemId'] as String?;
      final commentIdToHighlight = args['commentIdToHighlight'] as String?;
      final serverId =
          args['serverId'] as String?; // Optional serverId for context
      if (itemId != null) {
        // Potentially pass serverId if ItemDetailScreen needs it
        return CupertinoPageRoute(
          builder:
              (context) => ProviderScope(
                overrides: [
                  highlightedCommentIdProvider.overrideWith(
                    (ref) => commentIdToHighlight,
                  ),
                ],
                child: ItemDetailScreen(itemId: itemId),
              ),
          settings: settings,
        );
      }
      break;
    // Add case for parameterized notes route
    case String name when name.startsWith('/notes/'):
      final serverId = name.substring('/notes/'.length);
      if (serverId.isNotEmpty) {
        return CupertinoPageRoute(
          builder: (_) => ItemsScreen(serverId: serverId),
          settings: settings, // Pass settings along
        );
      }
      break; // Fall through if serverId is empty

    default:
      if (kDebugMode) {
        print('[RootNavigator] Unknown route: ${settings.name}');
      }
      // Fallback for unknown routes
      return CupertinoPageRoute(
        builder:
            (context) => const CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text('Not Found')),
              child: Center(child: Text('Route not found')),
            ),
        settings: settings,
      );
  }

  // Fallback for invalid arguments or missing IDs
  if (kDebugMode) {
    print('[RootNavigator] Route generation failed for: ${settings.name}');
  }
  return CupertinoPageRoute(
    builder:
        (context) => const CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(middle: Text('Error')),
          child: Center(child: Text('Invalid route arguments')),
        ),
    settings: settings,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (sentryDsn.isEmpty) {
    if (kDebugMode) {
      print(
        'Warning: SENTRY_DSN environment variable not set. Sentry reporting will be disabled.',
      );
    }
  }

  await SentryFlutter.init(
    (options) {
      if (sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      } else {
        if (kDebugMode) {
          print("Sentry DSN not found, Sentry integration disabled.");
        }
      }
      options.tracesSampleRate = 1.0;
      options.environment =
          kReleaseMode
              ? 'production'
              : (kProfileMode ? 'profile' : 'development');
      options.debug = !kReleaseMode;
    },
    appRunner:
        () => runApp(
          ProviderScope(
            observers: [LoggingProviderObserver()],
            // Use MyAppCore directly as the root widget
            child: const MyAppCore(),
          ),
        ),
  );
}

// Removed AppWithChatOverlay class

class MyAppCore extends ConsumerStatefulWidget {
  // Removed themeMode parameter as it's watched inside build
  const MyAppCore({super.key});

  @override
  ConsumerState<MyAppCore> createState() => _MyAppCoreState();
}

class _MyAppCoreState extends ConsumerState<MyAppCore> {
  bool _initialThemeLoaded = false;
  bool _initialConfigLoaded = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Keep triggering loads here
      _triggerInitialLoads();
      _initializePersistentNotifiers();
      _initAppLinks();
      // Listeners are now set up in the build method
    });
  }

  void _triggerInitialLoads() {
    // Just read the providers to trigger their initialization if not already loading.
    // The actual logic to update state is now handled by the listeners in build.
    if (kDebugMode) {
      print(
        '[MyAppCore] Triggering initial theme and config loads (if not already active)',
      );
    }
    ref.read(loadThemeModeProvider);
    ref.read(loadServerConfigProvider);
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initializePersistentNotifiers() {
    // Initialize all persistent notifiers concurrently
    Future.wait<void>([
          // Removed todoistApiKeyProvider init
          ref.read(openAiApiKeyProvider.notifier).init(),
          ref.read(openAiModelIdProvider.notifier).init(),
          ref.read(geminiApiKeyProvider.notifier).init(),
          ref.read(vikunjaApiKeyProvider.notifier).init(), // Added Vikunja
          ref.read(manuallyHiddenNoteIdsProvider.notifier).init(),
        ])
        .then((_) {
          if (kDebugMode) {
            print('[MyAppCore] All PersistentStringNotifiers initialized.');
          }
        })
        .catchError((e) {
          if (kDebugMode) {
            print(
              '[MyAppCore] Error initializing PersistentStringNotifiers: $e',
            );
          }
          // Decide if this error should block the UI or not.
          // Currently, it doesn't block.
        });
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) {
          print('[AppLinks] Initial link found: $initialUri');
        }
        _handleDeepLink(initialUri);
      } else {
        if (kDebugMode) {
          print('[AppLinks] No initial link.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[AppLinks] Error getting initial link: $e');
      }
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (kDebugMode) {
          print('[AppLinks] Link received while running: $uri');
        }
        _handleDeepLink(uri);
      },
      onError: (err) {
        if (kDebugMode) {
          print('[AppLinks] Error listening to link stream: $err');
        }
      },
    );
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null || uri.scheme != 'flutter-memos') {
      if (kDebugMode && uri != null) {
        print('[DeepLink] Ignoring URI: ${uri.toString()}');
      }
      return;
    }
    if (kDebugMode) {
      print('[DeepLink] Handling URI: ${uri.toString()}');
    }

    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final navigator = ref.read(rootNavigatorKeyProvider).currentState;

    if (navigator == null) {
      if (kDebugMode) {
        print('[DeepLink] Navigator not available yet.');
      }
      // Optionally retry later or queue the link
      return;
    }


    if (host == 'memo' && pathSegments.isNotEmpty) {
      final memoId = pathSegments[0];
      final serverId =
          uri.queryParameters['serverId']; // Optional server context
      navigator.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': null,
          'serverId': serverId, // Pass serverId if available
        },
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      final serverId =
          uri.queryParameters['serverId']; // Optional server context
      navigator.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': commentIdToHighlight,
          'serverId': serverId, // Pass serverId if available
        },
      );
    } else if (host == 'chat') {
      // Navigate to the chat route instead of toggling overlay
      if (kDebugMode) {
        print('[DeepLink] Navigating to chat route via deep link.');
      }
      final contextItemId = uri.queryParameters['contextItemId'];
      final contextItemTypeStr = uri.queryParameters['contextItemType'];
      final contextString = uri.queryParameters['contextString'];
      final parentServerId = uri.queryParameters['parentServerId'];

      // Prepare arguments for the ChatScreen route
      Map<String, dynamic>? chatArgs;
      if (contextItemId != null &&
          contextItemTypeStr != null &&
          parentServerId != null) {
        WorkbenchItemType? contextItemType;
        try {
          contextItemType = WorkbenchItemType.values.byName(contextItemTypeStr);
        } catch (_) {
          if (kDebugMode) {
            print('[DeepLink] Invalid contextItemType: $contextItemTypeStr');
          }
          contextItemType = WorkbenchItemType.unknown;
        }
        chatArgs = {
          'contextString': contextString ?? "Context from deep link",
          'parentItemId': contextItemId,
          'parentItemType': contextItemType,
          'parentServerId': parentServerId,
        };
        // Set context immediately if needed before navigation
        // Use addPostFrameCallback to ensure notifier exists if called early
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            // Check mounted again inside callback
            ref
                .read(chatProvider.notifier)
                .startChatWithContext(
                  contextString: chatArgs!['contextString'] as String,
                  parentItemId: chatArgs['parentItemId'] as String,
                  parentItemType:
                      chatArgs['parentItemType'] as WorkbenchItemType,
                  parentServerId: chatArgs['parentServerId'] as String,
                );
            if (kDebugMode) {
              print(
                '[DeepLink] Started chat with context: $contextItemId ($contextItemType)',
              );
            }
          }
        });
      }
      // Push the chat route, potentially with arguments
      navigator.pushNamed('/chat', arguments: chatArgs);

    } else {
      if (kDebugMode) {
        print('[DeepLink] Invalid URI structure: $uri');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // *** Set up listeners within the build method ***
    ref.listen<AsyncValue<ThemeMode>>(loadThemeModeProvider, (previous, next) {
      if (!next.isLoading) {
        // Check if loading is finished (data or error)
        if (mounted && !_initialThemeLoaded) {
          if (kDebugMode) {
            print(
              '[MyAppCore Listener - Build] loadThemeModeProvider finished loading (State: ${next.hasError ? 'Error' : 'Data'}). Setting flag.',
            );
          }
          // If data is available, apply it
          if (next.hasValue) {
            ref.read(themeModeProvider.notifier).state = next.value!;
            if (kDebugMode) {
              print(
                '[MyAppCore Listener - Build] Applied theme: ${next.value}',
              );
            }
          } else if (next.hasError) {
            if (kDebugMode) {
              print(
                '[MyAppCore Listener - Build] Theme loading finished with error: ${next.error}. Proceeding with default.',
              );
            }
          }
          // Use WidgetsBinding.instance.addPostFrameCallback to schedule the setState
          // after the current build cycle completes, avoiding build-time state changes.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_initialThemeLoaded) {
              // Double-check mounted status
              setState(() {
                _initialThemeLoaded = true;
              });
            }
          });
        }
      }
    });

    ref.listen<AsyncValue<dynamic>>(loadServerConfigProvider, (previous, next) {
      if (!next.isLoading) {
        // Check if loading is finished (data or error)
        if (mounted && !_initialConfigLoaded) {
          if (kDebugMode) {
            print(
              '[MyAppCore Listener - Build] loadServerConfigProvider finished loading (State: ${next.hasError ? 'Error' : 'Data'}). Setting flag.',
            );
          }
          if (next.hasError) {
            if (kDebugMode) {
              print(
                '[MyAppCore Listener - Build] Server config loading finished with error: ${next.error}.',
              );
            }
          }
          // Use WidgetsBinding.instance.addPostFrameCallback here as well
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_initialConfigLoaded) {
              // Double-check mounted status
              setState(() {
                _initialConfigLoaded = true;
              });
            }
          });
        }
      }
    });

    // Read the current theme mode state for building the CupertinoApp theme
    final themePreference = ref.watch(themeModeProvider);

    if (kDebugMode) {
      print(
        '[MyAppCore Build] Checking loading state: _initialThemeLoaded=$_initialThemeLoaded, _initialConfigLoaded=$_initialConfigLoaded',
      );
    }

    if (!_initialThemeLoaded || !_initialConfigLoaded) {
      // Still loading theme or config
      // Use a minimal CupertinoApp for the loading state
      return const CupertinoApp(
        theme: CupertinoThemeData(
          brightness: Brightness.light, // Or detect system brightness
        ),
        home: CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (kDebugMode) {
      print('[MyAppCore Build] Loading complete, building main app UI.');
    }

    // Main app UI build logic starts here
    // Determine brightness based on themePreference and platform
    final platformBrightness = MediaQuery.platformBrightnessOf(context);
    Brightness finalBrightness;
    switch (themePreference) {
      case ThemeMode.light:
        finalBrightness = Brightness.light;
        break;
      case ThemeMode.dark:
        finalBrightness = Brightness.dark;
        break;
      case ThemeMode.system:
      default:
        finalBrightness = platformBrightness;
        break;
    }

    const String sfFontFamily = '.SF Pro Text';
    final Color primaryColor =
        finalBrightness == Brightness.dark
            ? CupertinoColors.systemOrange
            : CupertinoColors.systemBlue;
    final Color labelColor =
        finalBrightness == Brightness.dark
            ? CupertinoColors.white
            : CupertinoColors.black;

    final TextStyle baseTextStyle = TextStyle(
      inherit: false,
      fontFamily: sfFontFamily,
      color: labelColor,
      fontSize: 17,
      decoration: TextDecoration.none,
    );
    final TextStyle baseActionTextStyle = TextStyle(
      inherit: false,
      fontFamily: sfFontFamily,
      color: primaryColor,
      fontSize: 17,
      decoration: TextDecoration.none,
    );
    final TextStyle baseNavTitleTextStyle = TextStyle(
      inherit: false,
      fontFamily: sfFontFamily,
      color: labelColor,
      fontSize: 17,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.none,
    );

    final cupertinoTheme = CupertinoThemeData(
      brightness: finalBrightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor:
          finalBrightness == Brightness.dark
              ? CupertinoColors.black
              : CupertinoColors.systemGroupedBackground,
      barBackgroundColor:
          finalBrightness == Brightness.dark
              ? const Color(0xFF1D1D1D)
              : CupertinoColors.systemGrey6,
      textTheme: CupertinoTextThemeData(
        textStyle: baseTextStyle,
        actionTextStyle: baseActionTextStyle,
        navTitleTextStyle: baseNavTitleTextStyle,
        navLargeTitleTextStyle: baseNavTitleTextStyle.copyWith(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.41,
          inherit: false,
        ),
        pickerTextStyle: baseTextStyle.copyWith(fontSize: 21, inherit: false),
        dateTimePickerTextStyle: baseTextStyle.copyWith(
          fontSize: 21,
          inherit: false,
        ),
      ),
    );

    // Build the main CupertinoApp only when loading is complete
    return Shortcuts(
      shortcuts: buildGlobalShortcuts(), // Keep existing shortcuts
      child: Actions(
        actions: {
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) {
              final navigator = ref.read(rootNavigatorKeyProvider).currentState;
              if (navigator?.canPop() ?? false) {
                navigator!.pop();
              }
              return null;
            },
          ),
          ToggleCaptureUtilityIntent:
              CallbackAction<ToggleCaptureUtilityIntent>(
                onInvoke: (intent) {
                  toggleCaptureUtility(ref);
                  if (kDebugMode) {
                    print('[MyApp Actions] Handled ToggleCaptureUtilityIntent');
                  }
                  return null;
                },
              ),
          NewMemoIntent: CallbackAction<NewMemoIntent>(
            onInvoke: (intent) {
              // Decide where to navigate: maybe the Notes Hub now?
              // Or keep it opening the generic new note screen?
              // Let's keep it generic for now.
              ref
                  .read(rootNavigatorKeyProvider)
                  .currentState
                  ?.pushNamed('/new-note');
              if (kDebugMode) {
                print(
                  '[MyApp Actions] Handled NewMemoIntent - opening new note screen',
                );
              }
              return null;
            },
          ),
          // Removed ToggleChatOverlayIntent action
        },
        child: GestureDetector(
          // Keep GestureDetector for unfocus
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: CupertinoApp(
            // This is now the root UI widget
            theme: cupertinoTheme,
            navigatorKey: ref.read(rootNavigatorKeyProvider),
            title: 'Flutter Memos',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en', '')],
            home: const ConfigCheckWrapper(), // Initial screen after loading
            onGenerateRoute: generateRoute, // Use the global route generator
            // Removed the builder that added the ChatOverlay
            builder: (context, child) => child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
