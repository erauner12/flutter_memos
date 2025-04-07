import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'
    show ThemeMode; // Keep Material import ONLY for ThemeMode enum
import 'package:flutter_localizations/flutter_localizations.dart'; // Import localizations
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/screens/home_screen.dart';
import 'package:flutter_memos/screens/mcp_screen.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Import keyboard shortcuts
import 'package:flutter_memos/utils/provider_logger.dart';
import 'package:flutter_memos/widgets/config_check_wrapper.dart'; // Import the new wrapper
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    ProviderScope(observers: [LoggingProviderObserver()], child: const MyApp()),
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
            print('[MyApp] Setting initial theme to: $savedMode');
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
      // Handle potential errors during initialization
      if (kDebugMode) print('[AppLinks] Error getting initial link: $e');
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
        // Handle potential errors in the stream
        if (kDebugMode) {
          print('[AppLinks] Error listening to link stream: $err');
        }
      },
    );
  }
  
  // Handle the deep link URI (This method remains unchanged)
  void _handleDeepLink(Uri? uri) {
    if (uri == null || uri.scheme != 'flutter-memos') {
      if (kDebugMode && uri != null) {
        if (kDebugMode) {
          print('[DeepLink] Ignoring URI: ${uri.toString()}');
        }
      }
      return;
    }

    if (kDebugMode) {
      print('[DeepLink] Handling URI: ${uri.toString()}');
    }

    final host = uri.host; // Get the host: 'memo' or 'comment'
    final pathSegments = uri.pathSegments;

    if (kDebugMode) {
      print('[DeepLink] Host: $host, Path segments: $pathSegments');
    }

    // Variables to extract
    String? memoId;
    String? commentIdToHighlight;

    if (host == 'memo' && pathSegments.isNotEmpty) {
      // For memo links: flutter-memos://memo/memoId
      memoId = pathSegments[0];
    } else if (host == 'comment' && pathSegments.length >= 2) {
      // For comment links: flutter-memos://comment/memoId/commentId
      memoId = pathSegments[0];
      commentIdToHighlight = pathSegments[1];
    } else {
      if (kDebugMode) {
        print(
          '[DeepLink] Invalid URI structure: $host/${pathSegments.join('/')}',
        );
      }
      return;
    }

    if (kDebugMode) {
      print(
        '[DeepLink] Navigating to memo: $memoId, highlight comment: $commentIdToHighlight',
      );
    }

    // Use the navigator key to access the navigator from anywhere
    _navigatorKey.currentState?.pushNamed(
      '/deep-link-target',
      arguments: {
        'memoId': memoId,
        'commentIdToHighlight': commentIdToHighlight,
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    // Watch the theme mode provider
    final themeMode = ref.watch(themeModeProvider);
    
    if (kDebugMode) {
      print('[MyApp] Building with theme mode: $themeMode');
    }

    // Removed custom macOS keyboard handler as it seems to cause assertion errors.
    // Relying on default Flutter keyboard handling for now.
    
    if (kDebugMode) {
      print('[MyApp] Current theme mode: $themeMode');
    }
    
    return Shortcuts(
      shortcuts: buildGlobalShortcuts(),
      child: Actions(
        actions: {
          // Global action for back navigation
          NavigateBackIntent: CallbackAction<NavigateBackIntent>(
            onInvoke: (intent) {
              final focusContext = FocusManager.instance.primaryFocus?.context;
              if (focusContext != null && Navigator.of(focusContext).canPop()) {
                Navigator.of(focusContext).pop();
              }
              return null;
            },
          ),
          
          // Add action for toggling CaptureUtility
          ToggleCaptureUtilityIntent:
              CallbackAction<ToggleCaptureUtilityIntent>(
                onInvoke: (intent) {
                  // Trigger the toggle via the provider
                  toggleCaptureUtility(ref);
                  if (kDebugMode) {
                    print('[MyApp Actions] Handled ToggleCaptureUtilityIntent');
                  }
                  return null;
                },
              ),
          
          // Add action for creating a new memo
          NewMemoIntent: CallbackAction<NewMemoIntent>(
            onInvoke: (intent) {
              // Navigate to new memo screen
              _navigatorKey.currentState?.pushNamed('/new-memo');
              if (kDebugMode) {
                print(
                  '[MyApp Actions] Handled NewMemoIntent - opening new memo screen',
                );
              }
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: () {
            // Unfocus when tapping outside of a text field
            FocusManager.instance.primaryFocus?.unfocus();
            // Don't toggle theme on general taps
          },
          child: Builder(
            // Use Builder to get context for MediaQuery
            builder: (context) {
              // Determine Brightness based on provider and system setting
              final themePreference = ref.watch(themeModeProvider);
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

              // Define base text style for mapping
              const TextStyle baseTextStyle = TextStyle(
                fontFamily: '.SF Pro Text', // Standard iOS font
                color: CupertinoColors.label, // Default label color
              );
              const TextStyle baseDarkTextStyle = TextStyle(
                fontFamily: '.SF Pro Text',
                color: CupertinoColors.label, // Default label color adapts
              );

              // Create CupertinoThemeData
              final cupertinoTheme = CupertinoThemeData(
                brightness: finalBrightness,
                // Map colors (example mapping, adjust as needed)
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
                        ? const Color(0xFF1D1D1D) // Dark nav bar background
                        : CupertinoColors
                            .systemGrey6, // Light nav bar background
                // Map text theme (basic example)
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
                  // Add other mappings as needed (navLargeTitleTextStyle, etc.)
                ),
              );

              return CupertinoApp(
                theme: cupertinoTheme,
                navigatorKey:
                    _navigatorKey, // Add navigator key for deep link navigation
                title: 'Flutter Memos',
                debugShowCheckedModeBanner: false,
                // Provide Material localizations needed by widgets like AppBar, TextField etc.
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations
                      .delegate, // Include Cupertino defaults too
                ],
                supportedLocales: const [
                  Locale('en', ''), // English, no country code
                  // Add other locales your app supports here
                ],
                // themeMode is handled by the brightness logic above
                home:
                    const ConfigCheckWrapper(), // Use ConfigCheckWrapper as home
                routes: {
                  // Define explicit routes needed for navigation
                  // '/' route is implicitly handled by 'home' now.
                  '/home':
                      (context) =>
                          const HomeScreen(),
                  '/memos': (context) => const MemosScreen(),
                  '/chat': (context) => const ChatScreen(),
                  '/mcp': (context) => const McpScreen(),
                },
                onGenerateRoute: (settings) {
                  // Use CupertinoPageRoute for iOS-style transitions later (Phase 4)
                  // For now, keep MaterialPageRoute to avoid breaking existing navigation
                  // until screens are migrated.
                  if (settings.name == '/memo-detail') {
                    final args = settings.arguments as Map<String, dynamic>;
                    return CupertinoPageRoute(
                      // Use CupertinoPageRoute
                      builder:
                          (context) =>
                          MemoDetailScreen(memoId: args['memoId'] as String),
                      settings: settings, // Pass settings
                    );
                  } else if (settings.name == '/edit-entity') {
                    final args = settings.arguments as Map<String, dynamic>;
                    final entityType =
                        args['entityType'] as String? ?? 'memo';
                    final entityId = args['entityId'] as String;

                    return CupertinoPageRoute(
                      // Use CupertinoPageRoute
                      builder:
                          (context) => EditMemoScreen(
                        entityId: entityId,
                        entityType: entityType,
                      ),
                      settings: settings, // Pass settings
                    );
                  } else if (settings.name == '/deep-link-target') {
                    final args =
                        settings.arguments as Map<String, dynamic>? ?? {};
                    final memoId = args['memoId'] as String?;
                    final commentIdToHighlight =
                        args['commentIdToHighlight'] as String?;

                    if (memoId != null) {
                      return CupertinoPageRoute(
                        // Use CupertinoPageRoute
                        builder:
                            (context) => ProviderScope(
                              overrides: [
                            highlightedCommentIdProvider.overrideWith(
                              (ref) => commentIdToHighlight,
                            ),
                          ],
                          child: MemoDetailScreen(memoId: memoId),
                        ),
                        settings: settings, // Pass settings
                      );
                    }
                    return null;
                  }
                  // Fallback for unknown routes (maybe show a 404 screen)
                  // Update fallback to use Cupertino widgets
                  return CupertinoPageRoute(
                    // Use CupertinoPageRoute
                    builder:
                        (context) => CupertinoPageScaffold(
                          navigationBar: const CupertinoNavigationBar(
                            middle: Text('Not Found'),
                          ),
                          child: Center(
                            child: Text(
                              'No route defined for ${settings.name}',
                            ),
                          ),
                        ),
                    settings: settings, // Pass settings
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

