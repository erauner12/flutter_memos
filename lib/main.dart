import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show ThemeMode; // Keep Material import ONLY for ThemeMode enum
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/chat_overlay_providers.dart'; // Import chat overlay provider
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings providers
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
import 'package:flutter_memos/screens/chat/chat_overlay.dart'; // Import the new overlay widget
// Import ChatScreen - Keep for potential direct navigation if needed, though primary access is overlay
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart'; // Updated import
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Updated import
import 'package:flutter_memos/screens/new_note/new_note_screen.dart'; // Updated import
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Import keyboard shortcuts (including ToggleChatOverlayIntent)
import 'package:flutter_memos/utils/provider_logger.dart';
import 'package:flutter_memos/widgets/config_check_wrapper.dart'; // Import the new wrapper
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart'; // Import Sentry

// Define the key globally or statically
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>();

// Provider to access the key
final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>((ref) {
  return rootNavigatorKey;
});

// Define the root route generator - moved outside main() to make it globally accessible
Route<dynamic>? generateRoute(RouteSettings settings) {
  if (kDebugMode) {
    print(
      '[RootNavigator] Generating route for: ${settings.name} with args: ${settings.arguments}',
    );
  }
  switch (settings.name) {
    case '/':
      // The 'home' property handles the root route, so this case might not be hit
      // unless explicitly pushed. Return null or handle as needed.
      // return CupertinoPageRoute(builder: (_) => const ConfigCheckWrapper());
      return null; // Let home handle '/'

    case '/chat':
      // This route might still be useful for direct navigation or deep links
      // but primary access is now the overlay.
      // If navigating here, maybe open the overlay instead?
      // For now, keep the direct screen route for potential fallback/testing.
      return CupertinoPageRoute(
        builder: (_) => const ChatScreen(), // Still builds the screen directly
        settings: settings, // Pass settings to access arguments in ChatScreen
      );

    case '/item-detail':
      // Handle item detail if pushed globally (e.g., from deep link handled outside MyApp state)
      final args = settings.arguments as Map<String, dynamic>?;
      final itemId = args?['itemId'] as String?;
      if (itemId != null) {
        return CupertinoPageRoute(
          builder: (_) => ItemDetailScreen(itemId: itemId),
          settings: settings,
        );
      }
      break; // Invalid args

    case '/edit-entity':
      // Handle edit entity if pushed globally
      final args = settings.arguments as Map<String, dynamic>?;
      final entityType = args?['entityType'] as String? ?? 'note';
      final entityId = args?['entityId'] as String?;
      if (entityId != null) {
        return CupertinoPageRoute(
          builder:
              (_) =>
                  EditEntityScreen(entityId: entityId, entityType: entityType),
          settings: settings,
        );
      }
      break; // Invalid args

    case '/new-note':
      // Handle new note if pushed globally (e.g., from keyboard shortcut)
      return CupertinoPageRoute(
        builder: (_) => const NewNoteScreen(),
        settings: settings,
      );

    case '/deep-link-target':
      // Handle deep link navigation target setup
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      final itemId = args['itemId'] as String?; // Changed from memoId
      final commentIdToHighlight = args['commentIdToHighlight'] as String?;

      if (itemId != null) {
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
      break; // Invalid args

    // Add other root-level routes here if needed

    default:
      // Handle unknown routes pushed on the root navigator
      if (kDebugMode) {
        print('[RootNavigator] Unknown route: ${settings.name}');
      }
      return CupertinoPageRoute(
        builder:
            (context) => const CupertinoPageScaffold(
              navigationBar: CupertinoNavigationBar(middle: Text('Not Found')),
              child: Center(child: Text('Route not found')),
            ),
        settings: settings,
      );
  }

  // If a case breaks without returning a route (e.g., invalid args)
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
  // Make main async
  // Ensure bindings are initialized before Sentry and runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Read the SENTRY_DSN from environment variables passed via --dart-define
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  // Add back the check for an empty DSN
  if (sentryDsn.isEmpty) {
    // Log a warning if the DSN is not provided during build/run
    // Sentry will be effectively disabled in this case by not setting options.dsn
    if (kDebugMode) {
      print(
        'Warning: SENTRY_DSN environment variable not set. Sentry reporting will be disabled.',
      );
    }
  }

  await SentryFlutter.init(
    (options) {
      // Set the DSN only if it was provided via --dart-define
      if (sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      } else {
        // Sentry is automatically disabled if options.dsn is null or empty.
        // No need to set options.enabled = false;
        if (kDebugMode) {
          print("Sentry DSN not found, Sentry integration disabled.");
        }
      }
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
      // Adjust this value in production.
      options.tracesSampleRate = 1.0;
      // Optional: Set environment based on build mode
      options.environment =
          kReleaseMode
              ? 'production'
              : (kProfileMode ? 'profile' : 'development');
      // Optional: Enable Sentry debug logging in non-release builds
      options.debug = !kReleaseMode;
    },
    // Wrap your original runApp call, now using AppWithChatOverlay
    appRunner:
        () => runApp(
          ProviderScope(
            observers: [LoggingProviderObserver()],
            // Use the new root widget that includes the overlay
            child: const AppWithChatOverlay(),
          ),
        ),
  );
}

// New Root Widget incorporating the Stack and Chat Overlay
class AppWithChatOverlay extends ConsumerWidget {
  const AppWithChatOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme mode to pass to MyAppCore
    final themeMode = ref.watch(themeModeProvider);
    // Watch initial load states (optional, could be handled within MyAppCore)
    // final initialThemeLoaded = ref.watch(_initialThemeLoadedProvider);
    // final initialConfigLoaded = ref.watch(_initialConfigLoadedProvider);

    // If you need loading indicators based on initial loads, handle them here or inside MyAppCore
    // if (!initialThemeLoaded || !initialConfigLoaded) {
    //   return const Center(child: CupertinoActivityIndicator()); // Or a splash screen
    // }

    return Stack(
      children: [
        // 1) Main app content (extracted logic into MyAppCore)
        Positioned.fill(child: MyAppCore(themeMode: themeMode)),

        // 2) The chat overlay:
        const ChatOverlay(),

        // 3) Optional: Global loading indicators or other overlays
      ],
    );
  }
}


// Renamed original MyApp to MyAppCore to represent the main app content
// without the overlay stack structure.
class MyAppCore extends ConsumerStatefulWidget {
  final ThemeMode themeMode; // Pass theme mode down

  const MyAppCore({required this.themeMode, super.key});

  @override
  ConsumerState<MyAppCore> createState() => _MyAppCoreState();
}

// Internal state providers for MyAppCore (optional, could remain in _MyAppCoreState)
// final _initialThemeLoadedProvider = StateProvider<bool>((ref) => false);
// final _initialConfigLoadedProvider = StateProvider<bool>((ref) => false);

class _MyAppCoreState extends ConsumerState<MyAppCore> {
  // Keep track of initialization state locally if not using providers above
  bool _initialThemeLoaded = false;
  bool _initialConfigLoaded = false;

  late final AppLinks _appLinks;
  StreamSubscription<Uri>?
  _linkSubscription; // Subscription for app_links stream

  @override
  void initState() {
    super.initState();

    // Load theme and server config once in initState instead of every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTheme();
      _loadServerConfig();
      _initializePersistentNotifiers(); // Call method to initialize string notifiers
      _initAppLinks(); // Initialize app_links handling
    });
  }

  @override
  void dispose() {
    // Cancel the app_links subscription
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialTheme() {
    if (!_initialThemeLoaded) {
      if (kDebugMode) {
        print('[MyAppCore] Loading initial theme preference');
      }

      final prefs = ref.read(loadThemeModeProvider);
      prefs.whenData((savedMode) {
        if (mounted) {
          if (kDebugMode) {
            print('[MyAppCore] Setting initial theme to: $savedMode');
          }
          // Update the provider, which AppWithChatOverlay watches
          ref.read(themeModeProvider.notifier).state = savedMode;
          setState(() {
            _initialThemeLoaded = true;
          });
          // ref.read(_initialThemeLoadedProvider.notifier).state = true; // Update state provider if used
        }
      });
    }
  }

  void _loadServerConfig() {
    if (!_initialConfigLoaded) {
      if (kDebugMode) {
        print('[MyAppCore] Loading server configuration');
      }

      final configLoader = ref.read(loadServerConfigProvider);
      configLoader.whenData((_) {
        if (mounted) {
          setState(() {
            _initialConfigLoaded = true;
          });
          // ref.read(_initialConfigLoadedProvider.notifier).state = true; // Update state provider if used
          if (kDebugMode) {
            print('[MyAppCore] Server configuration loaded');
          }
        }
      });
    }
  }

  // New method to initialize all PersistentStringNotifiers
  void _initializePersistentNotifiers() {
    Future.wait<void>([
          ref.read(todoistApiKeyProvider.notifier).init(),
          ref.read(openAiApiKeyProvider.notifier).init(),
          ref.read(openAiModelIdProvider.notifier).init(),
          ref.read(geminiApiKeyProvider.notifier).init(),
          // Add initialization for the new PersistentSetNotifier
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
        });
  }

  // Initialize deep link handling using app_links
  Future<void> _initAppLinks() async {
    _appLinks = AppLinks(); // Initialize AppLinks

    // Handle links the app is opened with
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

    // Handle links received while the app is running
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

  // Handle the deep link URI
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

    // Use the global rootNavigatorKey provided via ref
    final navigator = ref.read(rootNavigatorKeyProvider).currentState;

    if (host == 'memo' && pathSegments.isNotEmpty) {
      final memoId = pathSegments[0];
      navigator?.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': null,
        }, // Use itemId
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      navigator?.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId, // Use itemId
          'commentIdToHighlight': commentIdToHighlight,
        },
      );
    } else if (host == 'chat') {
      // Handle deep link to open chat overlay
      ref.read(chatOverlayVisibleProvider.notifier).state = true;
      if (kDebugMode) {
        print('[DeepLink] Opening chat overlay via deep link.');
      }
      // Optionally pass context if the deep link includes it
      // e.g., flutter-memos://chat?contextItemId=...&contextItemType=note
      final contextItemId = uri.queryParameters['contextItemId'];
      final contextItemTypeStr = uri.queryParameters['contextItemType'];
      final contextString =
          uri.queryParameters['contextString']; // Optional context text
      final parentServerId =
          uri.queryParameters['parentServerId']; // Optional server ID

      if (contextItemId != null &&
          contextItemTypeStr != null &&
          parentServerId != null) {
        // Convert string type to enum (add error handling)
        WorkbenchItemType? contextItemType;
        try {
          contextItemType = WorkbenchItemType.values.byName(contextItemTypeStr);
        } catch (_) {
          if (kDebugMode) {
            print('[DeepLink] Invalid contextItemType: $contextItemTypeStr');
          }
          contextItemType = WorkbenchItemType.unknown; // Fallback
        }

        // Use addPostFrameCallback to ensure notifier call happens after build/overlay animation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(chatProvider.notifier)
                .startChatWithContext(
                  contextString:
                      contextString ??
                      "Context from deep link", // Provide default or use query param
                  parentItemId: contextItemId,
                  // Pass the non-nullable type (or fallback)
                  parentItemType: contextItemType ?? WorkbenchItemType.unknown,
                  parentServerId: parentServerId,
                );
            if (kDebugMode) {
              print(
                '[DeepLink] Started chat with context: $contextItemId ($contextItemType)',
              );
            }
          }
        });
      }
    } else {
      if (kDebugMode) {
        print(
          '[DeepLink] Invalid URI structure: $uri',
        );
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the themeMode passed from AppWithChatOverlay
    final themePreference = widget.themeMode;

    // if (kDebugMode) {
    //   // print(
    //   //   '[MyAppCore] Building with theme mode: $themePreference',
    //   // );
    // }

    // Show loading indicator until initial theme/config are loaded
    if (!_initialThemeLoaded || !_initialConfigLoaded) {
      // Return a simple loading indicator within a CupertinoApp structure
      // to avoid errors during the brief loading phase.
      return const CupertinoApp(
        theme: CupertinoThemeData(
          brightness: Brightness.light,
        ), // Default theme
        home: CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        ),
      );
    }


    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
      child: Actions(
        actions: {
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) {
              // Use the global rootNavigatorKey provided via ref
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
              // Use the global rootNavigatorKey provided via ref
              ref
                  .read(rootNavigatorKeyProvider)
                  .currentState
                  ?.pushNamed(
                '/new-note',
              ); // Use new route
              if (kDebugMode) {
                print(
                  '[MyApp Actions] Handled NewMemoIntent - opening new note screen',
                ); // Updated log message
              }
              return null;
            },
          ),
          // Add action to toggle chat overlay
          ToggleChatOverlayIntent: CallbackAction<ToggleChatOverlayIntent>(
            onInvoke: (intent) {
              final currentVisibility = ref.read(chatOverlayVisibleProvider);
              ref.read(chatOverlayVisibleProvider.notifier).state =
                  !currentVisibility;
              if (kDebugMode) {
                print(
                  '[MyApp Actions] Toggled chat overlay visibility to ${!currentVisibility}',
                );
              }
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Builder(
            // Use Builder to get context below Actions/Shortcuts
            builder: (context) {
              final platformBrightness =
                  MediaQuery.of(context).platformBrightness;
              // Theme preference is now passed via widget.themeMode

              Brightness finalBrightness;
              switch (themePreference) {
                case ThemeMode.light:
                  finalBrightness = Brightness.light;
                  break;
                case ThemeMode.dark:
                  finalBrightness = Brightness.dark;
                  break;
                case ThemeMode.system:
                  finalBrightness = platformBrightness;
                  break;
                // Removed default clause as it's covered by the enum cases
              }

              // Define base colors and font family
              const String sfFontFamily = '.SF Pro Text';
              final Color primaryColor =
                  finalBrightness == Brightness.dark
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemBlue;
              final Color labelColor = CupertinoColors.label.resolveFrom(
                context,
              ); // Use resolved label color

              // Define base TextStyles with inherit: false
              final TextStyle baseTextStyle = TextStyle(
                inherit: false, // Set inherit to false
                fontFamily: sfFontFamily,
                color: labelColor,
                fontSize: 17,
              );

              final TextStyle baseActionTextStyle = TextStyle(
                inherit: false, // Set inherit to false
                fontFamily: sfFontFamily,
                color: primaryColor, // Use primary color for actions
                fontSize: 17,
              );

              final TextStyle baseNavTitleTextStyle = TextStyle(
                inherit: false, // Set inherit to false
                fontFamily: sfFontFamily,
                color: labelColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
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
                // Apply the base styles with inherit: false
                textTheme: CupertinoTextThemeData(
                  textStyle: baseTextStyle,
                  actionTextStyle: baseActionTextStyle,
                  navTitleTextStyle: baseNavTitleTextStyle,
                  // Define other styles explicitly if needed
                  navLargeTitleTextStyle: baseNavTitleTextStyle.copyWith(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.41,
                    inherit: false, // Ensure inherit is false here too
                  ),
                  pickerTextStyle: baseTextStyle.copyWith(
                    fontSize: 21,
                    inherit: false,
                  ),
                  dateTimePickerTextStyle: baseTextStyle.copyWith(
                    fontSize: 21,
                    inherit: false,
                  ),
                ),
              );

              // This CupertinoApp represents the core content, placed inside the Stack
              return CupertinoApp(
                theme: cupertinoTheme,
                // Assign the global key here
                navigatorKey: ref.read(
                  rootNavigatorKeyProvider,
                ), // Use provider to get key
                title: 'Flutter Memos',
                debugShowCheckedModeBanner: false,
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''),
                ],
                // Set home instead of using initialRoute or routes['/']
                home: const ConfigCheckWrapper(), // Start with config check
                // Use onGenerateRoute for root-level navigation handling
                onGenerateRoute: generateRoute,
                // Ensure builder context is used for MediaQuery if needed elsewhere
                builder: (context, child) {
                  // You could wrap child with MediaQuery or other providers if necessary
                  return child ??
                      const SizedBox.shrink(); // Return child or empty box
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
