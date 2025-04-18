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
      return null; // Let home handle '/'
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

    return Stack(
      children: [
        Positioned.fill(child: MyAppCore(themeMode: themeMode)),
        const ChatOverlay(),
      ],
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
        print('[MyAppCore] Loading server configuration');
      }
      final configLoader = ref.read(loadServerConfigProvider);
      configLoader.whenData((_) {
        if (mounted) {
          setState(() {
            _initialConfigLoaded = true;
          });
          if (kDebugMode) {
            print('[MyAppCore] Server configuration loaded');
          }
        }
      });
    }
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
    if (!_initialThemeLoaded || !_initialConfigLoaded) {
      return const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.light),
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
              final platformBrightness =
                  MediaQuery.of(context).platformBrightness;
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

              const String sfFontFamily = '.SF Pro Text';
              final Color primaryColor =
                  finalBrightness == Brightness.dark
                      ? CupertinoColors.systemOrange
                      : CupertinoColors.systemBlue;
              final Color labelColor = CupertinoColors.label.resolveFrom(
                context,
              );

              final TextStyle baseTextStyle = TextStyle(
                inherit: false,
                fontFamily: sfFontFamily,
                color: labelColor,
                fontSize: 17,
              );
              final TextStyle baseActionTextStyle = TextStyle(
                inherit: false,
                fontFamily: sfFontFamily,
                color: primaryColor,
                fontSize: 17,
              );
              final TextStyle baseNavTitleTextStyle = TextStyle(
                inherit: false,
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
                home: const ConfigCheckWrapper(),
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
