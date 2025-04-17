import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show ThemeMode; // Keep Material import ONLY for ThemeMode enum
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings providers
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
// Import ChatScreen
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart'; // Updated import
// Remove import for the env file
// import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Updated import
import 'package:flutter_memos/screens/new_note/new_note_screen.dart'; // Updated import
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Import keyboard shortcuts
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
      // Build ChatScreen when /chat is pushed on the root navigator
      return CupertinoPageRoute(
        builder: (_) => const ChatScreen(),
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
      final itemId = args['itemId'] as String?;
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
    // Wrap your original runApp call
    appRunner:
        () => runApp(
          ProviderScope(
            observers: [LoggingProviderObserver()],
            child: const MyApp(),
          ),
        ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _initialThemeLoaded = false;
  bool _initialConfigLoaded = false;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>?
  _linkSubscription; // Subscription for app_links stream
  // Remove the local navigator key
  // final GlobalKey<NavigatorState> _navigatorKey =
  //     GlobalKey<NavigatorState>(); // For navigation from deep links

  @override
  void initState() {
    super.initState();
    
    // Load theme and server config once in initState instead of every build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialTheme();
      _loadServerConfig();
      // Removed call to the now obsolete loading method
      _initializePersistentNotifiers(); // Call method to initialize string notifiers
      // Replace uni_links initialization
      // _initUniLinks();
      // Initialize app_links handling
      _initAppLinks();
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
        print('[MyApp] Loading initial theme preference');
      }
      
      final prefs = ref.read(loadThemeModeProvider);
      prefs.whenData((savedMode) {
        if (mounted) {
          if (kDebugMode) {
            print('[MyApp] Setting initial theme to: \$savedMode');
          }
          ref.read(themeModeProvider.notifier).state = savedMode;
          setState(() {
            _initialThemeLoaded = true;
          });
        }
      });
    }
  }
  
  void _loadServerConfig() {
    if (!_initialConfigLoaded) {
      if (kDebugMode) {
        print('[MyApp] Loading server configuration');
      }

      final configLoader = ref.read(loadServerConfigProvider);
      configLoader.whenData((_) {
        if (mounted) {
          setState(() {
            _initialConfigLoaded = true;
          });
          if (kDebugMode) {
            print('[MyApp] Server configuration loaded');
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
            print('[MyApp] All PersistentStringNotifiers initialized.');
          }
        })
        .catchError((e) {
          if (kDebugMode) {
            print('[MyApp] Error initializing PersistentStringNotifiers: \$e');
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
          print('[AppLinks] Initial link found: \$initialUri');
        }
        _handleDeepLink(initialUri);
      } else {
        if (kDebugMode) {
          print('[AppLinks] No initial link.');
        }
      }
    } catch (e) {
      if (kDebugMode) print('[AppLinks] Error getting initial link: \$e');
    }
  
    // Handle links received while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (kDebugMode) {
          print('[AppLinks] Link received while running: \$uri');
        }
        _handleDeepLink(uri);
      },
      onError: (err) {
        if (kDebugMode) {
          print('[AppLinks] Error listening to link stream: \$err');
        }
      },
    );
  }
  
  // Handle the deep link URI
  void _handleDeepLink(Uri? uri) {
    if (uri == null || uri.scheme != 'flutter-memos') {
      if (kDebugMode && uri != null) {
        print('[DeepLink] Ignoring URI: \${uri.toString()}');
      }
      return;
    }

    if (kDebugMode) {
      print('[DeepLink] Handling URI: \${uri.toString()}');
    }

    final host = uri.host;
    final pathSegments = uri.pathSegments;

    if (host == 'memo' && pathSegments.isNotEmpty) {
      final memoId = pathSegments[0];

      // Use the global rootNavigatorKey
      rootNavigatorKey.currentState?.pushNamed(
        '/deep-link-target',
        arguments: {'memoId': memoId, 'commentIdToHighlight': null},
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      // Use the global rootNavigatorKey
      rootNavigatorKey.currentState?.pushNamed(
        '/deep-link-target',
        arguments: {
          'memoId': memoId,
          'commentIdToHighlight': commentIdToHighlight,
        },
      );
    } else {
      if (kDebugMode) {
        print(
          '[DeepLink] Invalid URI structure: \$uri',
        );
      }
      return;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print(
        '[MyApp] Building with theme mode: \${ref.watch(themeModeProvider)}',
      );
    }
    
    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
      child: Actions(
        actions: {
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) {
              final focusContext = FocusManager.instance.primaryFocus?.context;
              if (focusContext != null && Navigator.of(focusContext).canPop()) {
                Navigator.of(focusContext).pop();
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
              // Use the global rootNavigatorKey
              rootNavigatorKey.currentState?.pushNamed(
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
        },
        child: GestureDetector(
          onTap: () {
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Builder(
            builder: (context) {
              final platformBrightness =
                  MediaQuery.of(context).platformBrightness;
              final themePreference = ref.watch(themeModeProvider);

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
              }

              const TextStyle baseTextStyle = TextStyle(
                fontFamily: '.SF Pro Text',
                color: CupertinoColors.label,
              );
              const TextStyle baseDarkTextStyle = TextStyle(
                fontFamily: '.SF Pro Text',
                color: CupertinoColors.label,
              );

              final cupertinoTheme = CupertinoThemeData(
                brightness: finalBrightness,
                primaryColor:
                    finalBrightness == Brightness.dark
                        ? CupertinoColors.systemOrange
                        : CupertinoColors.systemBlue,
                scaffoldBackgroundColor:
                    finalBrightness == Brightness.dark
                        ? CupertinoColors.black
                        : CupertinoColors.systemGroupedBackground,
                barBackgroundColor:
                    finalBrightness == Brightness.dark
                        ? const Color(0xFF1D1D1D)
                        : CupertinoColors.systemGrey6,
                textTheme: CupertinoTextThemeData(
                  textStyle:
                      finalBrightness == Brightness.dark
                          ? baseDarkTextStyle.copyWith(fontSize: 17)
                          : baseTextStyle.copyWith(fontSize: 17),
                  actionTextStyle:
                      finalBrightness == Brightness.dark
                          ? baseDarkTextStyle.copyWith(
                            fontSize: 17,
                            color: CupertinoColors.systemOrange,
                          )
                          : baseTextStyle.copyWith(
                            fontSize: 17,
                            color: CupertinoColors.systemBlue,
                          ),
                  navTitleTextStyle:
                      finalBrightness == Brightness.dark
                          ? baseDarkTextStyle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          )
                          : baseTextStyle.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                ),
              );

              return CupertinoApp(
                theme: cupertinoTheme,
                // Assign the global key here
                navigatorKey: rootNavigatorKey,
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
                home: const ConfigCheckWrapper(),
                // Remove the routes map
                // routes: { ... },
                // Use onGenerateRoute for root-level navigation handling
                onGenerateRoute: generateRoute,
              );
            },
          ),
        ),
      ),
    );
  }
}
