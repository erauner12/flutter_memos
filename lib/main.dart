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
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart'; // Updated import
import 'package:flutter_memos/screens/home_screen.dart';
// Remove import for the env file
// import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart'; // Updated import
import 'package:flutter_memos/screens/items/items_screen.dart'; // Updated import
import 'package:flutter_memos/screens/new_note/new_note_screen.dart'; // Updated import
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Import keyboard shortcuts
import 'package:flutter_memos/utils/provider_logger.dart';
import 'package:flutter_memos/widgets/config_check_wrapper.dart'; // Import the new wrapper
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart'; // Import Sentry

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
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>(); // For navigation from deep links

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
      if (kDebugMode) {
        print(
          '[DeepLink] Navigating to memo: \$memoId, highlight comment: null',
        );
      }
      _navigatorKey.currentState?.pushNamed(
        '/deep-link-target',
        arguments: {'memoId': memoId, 'commentIdToHighlight': null},
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      if (kDebugMode) {
        print(
          '[DeepLink] Navigating to memo: \$memoId, highlight comment: \$commentIdToHighlight',
        );
      }
      _navigatorKey.currentState?.pushNamed(
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
              _navigatorKey.currentState?.pushNamed(
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
                navigatorKey: _navigatorKey,
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
                home: const ConfigCheckWrapper(),
                routes: {
                  '/home': (context) => const HomeScreen(),
                  '/items':
                      (context) =>
                          const ItemsScreen(), // Updated route name and screen
                  '/new-note':
                      (context) =>
                          const NewNoteScreen(), // Updated route name and screen
                  '/item-detail': (context) {
                    final args =
                        ModalRoute.of(context)!.settings.arguments
                            as Map<String, dynamic>;
                    return ItemDetailScreen(
                      itemId: args['itemId'] as String,
                    ); // Updated screen and argument name
                  },
                  '/edit-entity': (context) {
                    final args =
                        ModalRoute.of(context)!.settings.arguments
                            as Map<String, dynamic>;
                    final entityType =
                        args['entityType'] as String? ??
                        'note'; // Default to note if needed
                    final entityId = args['entityId'] as String;
                    return EditEntityScreen(
                      entityId: entityId,
                      entityType: entityType,
                    ); // Use EditEntityScreen
                  },
                },
                onGenerateRoute: (settings) {
                  if (settings.name == '/item-detail') {
                    // Updated route name
                    final args = settings.arguments as Map<String, dynamic>;
                    return CupertinoPageRoute(
                      builder:
                          (context) => ItemDetailScreen(
                            itemId: args['itemId'] as String,
                          ),
                      settings: settings,
                    );
                  } else if (settings.name == '/edit-entity') {
                    final args = settings.arguments as Map<String, dynamic>;
                    final entityType =
                        args['entityType'] as String? ??
                        'note'; // Default to note
                    final entityId = args['entityId'] as String;

                    return CupertinoPageRoute(
                      builder:
                          (context) => EditEntityScreen(
                            entityId: entityId,
                            entityType: entityType,
                          ),
                      settings: settings,
                    );
                  } else if (settings.name == '/deep-link-target') {
                    final args =
                        settings.arguments as Map<String, dynamic>? ?? {};
                    final itemId =
                        args['itemId'] as String?; // Updated argument name
                    final commentIdToHighlight =
                        args['commentIdToHighlight'] as String?;

                    if (itemId != null) {
                      return CupertinoPageRoute(
                        builder:
                            (context) => ProviderScope(
                              overrides: [
                                highlightedCommentIdProvider.overrideWith(
                                  (ref) => commentIdToHighlight,
                                ),
                              ],
                              child: ItemDetailScreen(
                                itemId: itemId,
                              ), // Updated screen and argument name
                            ),
                        settings: settings,
                      );
                    }
                    return null;
                  }
                  return CupertinoPageRoute(
                    builder:
                        (context) => const CupertinoPageScaffold(
                          navigationBar: CupertinoNavigationBar(
                            middle: Text('Not Found'),
                          ),
                          child: Center(
                            child: Text(
                              'No route defined for \${settings.name}',
                            ),
                          ),
                        ),
                    settings: settings,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
