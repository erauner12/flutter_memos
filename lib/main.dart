import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show ThemeMode; // Keep Material import ONLY for ThemeMode enum
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/chat_providers.dart';
import 'package:flutter_memos/providers/server_config_provider.dart'; // Keep for loadServerConfigProvider
import 'package:flutter_memos/providers/settings_provider.dart'; // Import settings providers
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
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
      return CupertinoPageRoute(
        builder: (_) => const ChatScreen(),
        settings: settings,
      );
    case '/item-detail':
      final args = settings.arguments as Map<String, dynamic>?;
      final itemId = args?['itemId'] as String?;
      // serverId is no longer needed from args, context comes from noteServerConfigProvider
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
      // serverId is no longer needed from args
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
      // serverId is no longer needed from args
      return CupertinoPageRoute(
        builder: (_) => const NewNoteScreen(),
        settings: settings,
      );
    case '/deep-link-target':
      final args = settings.arguments as Map<String, dynamic>? ?? {};
      final itemId = args['itemId'] as String?;
      final commentIdToHighlight = args['commentIdToHighlight'] as String?;
      // serverId is no longer needed from args
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
    // Replace parameterized notes route with a single route
    case '/notes': // Changed from '/notes/:serverId'
      // serverId is no longer needed, ItemsScreen will use noteServerConfigProvider
      return CupertinoPageRoute(
        builder: (_) => const ItemsScreen(serverId: ''),
        settings: settings,
      );

    default:
      if (kDebugMode) print('[RootNavigator] Unknown route: ${settings.name}');
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
  if (sentryDsn.isEmpty && kDebugMode) {
    print(
      'Warning: SENTRY_DSN environment variable not set. Sentry reporting will be disabled.',
    );
  }

  await SentryFlutter.init(
    (options) {
      if (sentryDsn.isNotEmpty) {
        options.dsn = sentryDsn;
      } else if (kDebugMode) {
        print("Sentry DSN not found, Sentry integration disabled.");
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
            child: const MyAppCore(),
          ),
        ),
  );
}

class MyAppCore extends ConsumerStatefulWidget {
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
      _triggerInitialLoads();
      _initializePersistentNotifiers();
      _initAppLinks();
    });
  }

  void _triggerInitialLoads() {
    if (kDebugMode)
      print('[MyAppCore] Triggering initial theme and config loads');
    // Read the providers to trigger initialization. Listeners handle state updates.
    ref.read(loadThemeModeProvider);
    ref.read(
      loadServerConfigProvider,
    ); // This now loads Note, Task, MCP configs
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initializePersistentNotifiers() {
    Future.wait<void>([
          ref.read(openAiApiKeyProvider.notifier).init(),
          ref.read(openAiModelIdProvider.notifier).init(),
          ref.read(geminiApiKeyProvider.notifier).init(),
          ref.read(vikunjaApiKeyProvider.notifier).init(),
          ref.read(manuallyHiddenNoteIdsProvider.notifier).init(),
        ])
        .then((_) {
          if (kDebugMode)
            print('[MyAppCore] All PersistentStringNotifiers initialized.');
        })
        .catchError((e) {
          if (kDebugMode)
            print(
              '[MyAppCore] Error initializing PersistentStringNotifiers: $e',
            );
        });
  }

  Future<void> _initAppLinks() async {
    _appLinks = AppLinks();
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        if (kDebugMode) print('[AppLinks] Initial link found: $initialUri');
        _handleDeepLink(initialUri);
      } else {
        if (kDebugMode) print('[AppLinks] No initial link.');
      }
    } catch (e) {
      if (kDebugMode) print('[AppLinks] Error getting initial link: $e');
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (kDebugMode) print('[AppLinks] Link received while running: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        if (kDebugMode)
          print('[AppLinks] Error listening to link stream: $err');
      },
    );
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null || uri.scheme != 'flutter-memos') {
      if (kDebugMode && uri != null)
        print('[DeepLink] Ignoring URI: ${uri.toString()}');
      return;
    }
    if (kDebugMode) print('[DeepLink] Handling URI: ${uri.toString()}');

    final host = uri.host;
    final pathSegments = uri.pathSegments;
    final navigator = ref.read(rootNavigatorKeyProvider).currentState;

    if (navigator == null) {
      if (kDebugMode) print('[DeepLink] Navigator not available yet.');
      return;
    }

    // Assuming deep links now implicitly target the configured Note server
    // The 'serverId' query parameter is ignored.

    if (host == 'memo' && pathSegments.isNotEmpty) {
      final memoId = pathSegments[0];
      navigator.pushNamed(
        '/deep-link-target',
        arguments: {'itemId': memoId, 'commentIdToHighlight': null},
      );
    } else if (host == 'comment' && pathSegments.length >= 2) {
      final memoId = pathSegments[0];
      final commentIdToHighlight = pathSegments[1];
      navigator.pushNamed(
        '/deep-link-target',
        arguments: {
          'itemId': memoId,
          'commentIdToHighlight': commentIdToHighlight,
        },
      );
    } else if (host == 'chat') {
      if (kDebugMode)
        print('[DeepLink] Navigating to chat route via deep link.');
      final contextItemId = uri.queryParameters['contextItemId'];
      final contextItemTypeStr = uri.queryParameters['contextItemType'];
      final contextString = uri.queryParameters['contextString'];
      // parentServerId might still be relevant if context comes from MCP or a specific server
      final parentServerId = uri.queryParameters['parentServerId'];

      Map<String, dynamic>? chatArgs;
      if (contextItemId != null &&
          contextItemTypeStr != null &&
          parentServerId != null) {
        WorkbenchItemType? contextItemType;
        try {
          contextItemType = WorkbenchItemType.values.byName(contextItemTypeStr);
        } catch (_) {
          if (kDebugMode)
            print('[DeepLink] Invalid contextItemType: $contextItemTypeStr');
          contextItemType = WorkbenchItemType.unknown;
        }
        chatArgs = {
          'contextString': contextString ?? "Context from deep link",
          'parentItemId': contextItemId,
          'parentItemType': contextItemType,
          'parentServerId': parentServerId, // Keep serverId for context origin
        };
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref
                .read(chatProvider.notifier)
                .startChatWithContext(
                  contextString: chatArgs!['contextString'] as String,
                  parentItemId: chatArgs['parentItemId'] as String,
                  parentItemType:
                      chatArgs['parentItemType'] as WorkbenchItemType,
                  parentServerId: chatArgs['parentServerId'] as String,
                );
            if (kDebugMode)
              print(
                '[DeepLink] Started chat with context: $contextItemId ($contextItemType)',
              );
          }
        });
      }
      navigator.pushNamed('/chat', arguments: chatArgs);
    } else {
      if (kDebugMode) print('[DeepLink] Invalid URI structure: $uri');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Listener for theme loading
    ref.listen<AsyncValue<ThemeMode>>(loadThemeModeProvider, (previous, next) {
      if (!next.isLoading && mounted && !_initialThemeLoaded) {
        if (kDebugMode)
          print(
            '[MyAppCore Listener - Build] loadThemeModeProvider finished loading.',
          );
        if (next.hasValue) {
          ref.read(themeModeProvider.notifier).state = next.value!;
          if (kDebugMode)
            print('[MyAppCore Listener - Build] Applied theme: ${next.value}');
        } else if (next.hasError) {
          if (kDebugMode)
            print(
              '[MyAppCore Listener - Build] Theme loading finished with error: ${next.error}.',
            );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_initialThemeLoaded)
            setState(() {
              _initialThemeLoaded = true;
            });
        });
      }
    });

    // Listener for config loading (Note, Task, MCP)
    ref.listen<AsyncValue<void>>(loadServerConfigProvider, (previous, next) {
      if (!next.isLoading && mounted && !_initialConfigLoaded) {
        if (kDebugMode)
          print(
            '[MyAppCore Listener - Build] loadServerConfigProvider finished loading.',
          );
        if (next.hasError) {
          if (kDebugMode)
            print(
              '[MyAppCore Listener - Build] Server config loading finished with error: ${next.error}.',
            );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_initialConfigLoaded)
            setState(() {
              _initialConfigLoaded = true;
            });
        });
      }
    });

    final themePreference = ref.watch(themeModeProvider);

    if (kDebugMode)
      print(
        '[MyAppCore Build] Loading state: Theme=$_initialThemeLoaded, Config=$_initialConfigLoaded',
      );

    if (!_initialThemeLoaded || !_initialConfigLoaded) {
      return const CupertinoApp(
        theme: CupertinoThemeData(brightness: Brightness.light),
        home: CupertinoPageScaffold(
          child: Center(child: CupertinoActivityIndicator()),
        ),
        debugShowCheckedModeBanner: false,
      );
    }

    if (kDebugMode)
      print('[MyAppCore Build] Loading complete, building main app UI.');

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

    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
      child: Actions(
        actions: {
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) {
              final navigator = ref.read(rootNavigatorKeyProvider).currentState;
              if (navigator?.canPop() ?? false) navigator!.pop();
              return null;
            },
          ),
          ToggleCaptureUtilityIntent:
              CallbackAction<ToggleCaptureUtilityIntent>(
                onInvoke: (intent) {
                  toggleCaptureUtility(ref);
                  if (kDebugMode)
                    print('[MyApp Actions] Handled ToggleCaptureUtilityIntent');
                  return null;
                },
              ),
          NewMemoIntent: CallbackAction<NewMemoIntent>(
            onInvoke: (intent) {
              // Navigate to the generic new note screen. It will use the configured note server.
              ref
                  .read(rootNavigatorKeyProvider)
                  .currentState
                  ?.pushNamed('/new-note');
              if (kDebugMode)
                print(
                  '[MyApp Actions] Handled NewMemoIntent - opening new note screen',
                );
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: CupertinoApp(
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
            builder: (context, child) => child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
