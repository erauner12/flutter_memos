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
import 'package:flutter_memos/screens/chat_screen.dart'; // Keep for potential direct navigation
import 'package:flutter_memos/screens/edit_entity/edit_entity_screen.dart';
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart';
import 'package:flutter_memos/screens/new_note/new_note_screen.dart';
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // ToggleChatOverlayIntent, etc.
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
      return null;
    case '/chat':
      return CupertinoPageRoute(
        builder: (_) => const ChatScreen(),
        settings: settings,
      );
    case '/item-detail':
      final args = settings.arguments as Map<String, dynamic>?;
      final itemId = args?['itemId'] as String?;
      if (itemId != null) {
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
      if (entityId != null) {
        return CupertinoPageRoute(
          builder:
              (_) =>
                  EditEntityScreen(entityId: entityId, entityType: entityType),
          settings: settings,
        );
      }
      break;
    case '/new-note':
      return CupertinoPageRoute(
        builder: (_) => const NewNoteScreen(),
        settings: settings,
      );
    case '/deep-link-target':
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
      break;
    default:
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
            child: const AppWithChatOverlay(),
          ),
        ),
  );
}

class AppWithChatOverlay extends ConsumerWidget {
  const AppWithChatOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Wrap the Stack in a Directionality or CupertinoApp to fix missing directionality.
    return Directionality(
      textDirection: TextDirection.ltr, // Or TextDirection.rtl based on locale
      child: Stack(
        children: [
          Positioned.fill(child: MyAppCore(themeMode: themeMode)),
          const ChatOverlay(),
        ],
      ),
    );
  }
}

class MyAppCore extends ConsumerStatefulWidget {
  final ThemeMode themeMode;
  const MyAppCore({required this.themeMode, super.key});

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
      _loadInitialTheme();
      _loadServerConfig();
      _initializePersistentNotifiers();
      _initAppLinks();
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialTheme() {
    // No need to check _initialThemeLoaded here, provider handles idempotency
    if (kDebugMode) {
      print('[MyAppCore] Requesting initial theme preference load');
    }
    final prefs = ref.read(loadThemeModeProvider);
    prefs.whenData((savedMode) {
      if (mounted && !_initialThemeLoaded) {
        // Check flag *before* setting
        if (kDebugMode) {
          print('[MyAppCore] Setting initial theme to: $savedMode');
        }
        ref.read(themeModeProvider.notifier).state = savedMode;
        setState(() {
          _initialThemeLoaded = true;
          if (kDebugMode) {
            print('[MyAppCore] _initialThemeLoaded set to true');
          }
        });
      } else if (mounted && _initialThemeLoaded) {
        if (kDebugMode) {
          print(
            '[MyAppCore] Theme already loaded, ignoring subsequent whenData.',
          );
        }
      }
    });
    // Handle potential error case for theme loading if needed
    prefs.maybeWhen(
      error: (error, stackTrace) {
        if (kDebugMode) {
          print(
            '[MyAppCore] Error loading theme preference: $error. Proceeding with default.',
          );
        }
        if (mounted && !_initialThemeLoaded) {
          setState(() {
            _initialThemeLoaded =
                true; // Mark as loaded even on error to proceed
            if (kDebugMode) {
              print(
                '[MyAppCore] _initialThemeLoaded set to true (due to error)',
              );
            }
          });
        }
      },
      orElse: () {}, // Do nothing for loading or data if already handled
    );
  }


  void _loadServerConfig() {
    // No need to check _initialConfigLoaded here, provider handles idempotency
    if (kDebugMode) {
      print('[MyAppCore] Requesting server configuration load');
    }
    final configLoader = ref.read(loadServerConfigProvider);
    configLoader.when(
      data: (_) {
        if (mounted && !_initialConfigLoaded) {
          // Check flag *before* setting
          setState(() {
            _initialConfigLoaded = true;
            if (kDebugMode) {
              print(
                '[MyAppCore] _initialConfigLoaded set to true (data received)',
              );
            }
          });
          if (kDebugMode) {
            print('[MyAppCore] Server configuration loaded callback executed');
          }
        } else if (mounted && _initialConfigLoaded) {
          if (kDebugMode) {
            print(
              '[MyAppCore] Config already loaded, ignoring subsequent data.',
            );
          }
        }
      },
      error: (error, stackTrace) {
        if (kDebugMode) {
          print('[MyAppCore] Error loading server config: $error');
        }
        // Set config loaded to true even on error to prevent infinite spinner
        if (mounted && !_initialConfigLoaded) {
          // Check flag *before* setting
          setState(() {
            _initialConfigLoaded =
                true; // *** CRITICAL FIX: Set true on error ***
            if (kDebugMode) {
              print(
                '[MyAppCore] _initialConfigLoaded set to true (error occurred)',
              );
            }
          });
        } else if (mounted && _initialConfigLoaded) {
          if (kDebugMode) {
            print(
              '[MyAppCore] Config already loaded, ignoring subsequent error.',
            );
          }
        }
      },
      loading: () {
        if (kDebugMode) {
          // Optional: print only once or less frequently if needed
          // print('[MyAppCore] Server configuration is loading...');
        }
      },
    );
  }


  void _initializePersistentNotifiers() {
    Future.wait<void>([
          ref.read(todoistApiKeyProvider.notifier).init(),
          ref.read(openAiApiKeyProvider.notifier).init(),
          ref.read(openAiModelIdProvider.notifier).init(),
          ref.read(geminiApiKeyProvider.notifier).init(),
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

    if (host == 'memo' && pathSegments.isNotEmpty) {
      final memoId = pathSegments[0];
      navigator?.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': null,
        },
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      navigator?.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': commentIdToHighlight,
        },
      );
    } else if (host == 'chat') {
      ref.read(chatOverlayVisibleProvider.notifier).state = true;
      if (kDebugMode) {
        print('[DeepLink] Opening chat overlay via deep link.');
      }
      final contextItemId = uri.queryParameters['contextItemId'];
      final contextItemTypeStr = uri.queryParameters['contextItemType'];
      final contextString = uri.queryParameters['contextString'];
      final parentServerId = uri.queryParameters['parentServerId'];

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

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(chatProvider.notifier)
                .startChatWithContext(
                  contextString: contextString ?? "Context from deep link",
                  parentItemId: contextItemId,
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
        print('[DeepLink] Invalid URI structure: $uri');
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themePreference = widget.themeMode;

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
    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
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
            builder: (context) {
              // Determine brightness based on themePreference and platform
              final platformBrightness =
                  MediaQuery.platformBrightnessOf(
                context,
              ); // Use platformBrightnessOf
              Brightness finalBrightness;
              switch (themePreference) {
                case ThemeMode.light:
                  finalBrightness = Brightness.light;
                  break;
                case ThemeMode.dark:
                  finalBrightness = Brightness.dark;
                  break;
                case ThemeMode.system:
                default: // Default to system if preference is invalid
                  finalBrightness = platformBrightness;
                  break;
              }

              const String sfFontFamily = '.SF Pro Text';
              final Color primaryColor =
                  finalBrightness == Brightness.dark
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemBlue;
              // Resolve label color based on the final brightness
              final Color labelColor =
                  finalBrightness == Brightness.dark
                      ? CupertinoColors.white
                      : CupertinoColors.black;

              final TextStyle baseTextStyle = TextStyle(
                inherit: false,
                fontFamily: sfFontFamily,
                color: labelColor,
                fontSize: 17,
                decoration: TextDecoration.none, // Ensure no default underlines
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

              // Build the main CupertinoApp only when loading is complete
              return CupertinoApp(
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
                home:
                    const ConfigCheckWrapper(), // This now runs after loading flags are true
                onGenerateRoute: generateRoute,
                builder: (context, child) => child ?? const SizedBox.shrink(),
              );
            },
          ),
        ),
      ),
    );
  }
}
