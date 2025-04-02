import 'dart:async'; // Import for StreamSubscription

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_memos/providers/theme_provider.dart';
import 'package:flutter_memos/providers/ui_providers.dart'; // Import for UI providers including highlightedCommentIdProvider
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/codegen_test_screen.dart';
import 'package:flutter_memos/screens/edit_memo/edit_memo_screen.dart';
import 'package:flutter_memos/screens/filter_demo_screen.dart';
import 'package:flutter_memos/screens/mcp_screen.dart';
import 'package:flutter_memos/screens/memo_detail/memo_detail_screen.dart';
import 'package:flutter_memos/screens/memos/memos_screen.dart';
import 'package:flutter_memos/screens/new_memo/new_memo_screen.dart';
import 'package:flutter_memos/screens/riverpod_demo_screen.dart';
import 'package:flutter_memos/screens/settings_screen.dart';
import 'package:flutter_memos/utils/keyboard_shortcuts.dart'; // Import keyboard shortcuts
import 'package:flutter_memos/utils/provider_logger.dart';
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
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        if (kDebugMode) print('[AppLinks] Initial link found: $initialUri');
        _handleDeepLink(initialUri);
      } else {
        if (kDebugMode) print('[AppLinks] No initial link.');
      }
    } catch (e) {
      // Handle potential errors during initialization
      if (kDebugMode) print('[AppLinks] Error getting initial link: $e');
    }
  
    // Handle links received while the app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        if (kDebugMode) print('[AppLinks] Link received while running: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        // Handle potential errors in the stream
        if (kDebugMode)
          print('[AppLinks] Error listening to link stream: $err');
      },
    );
  }
  
  // Handle the deep link URI (This method remains unchanged)
  void _handleDeepLink(Uri? uri) {
    if (uri == null || uri.scheme != 'flutter-memos') {
      if (kDebugMode && uri != null)
        print('[DeepLink] Ignoring URI: ${uri.toString()}');
      return;
    }

    if (kDebugMode) print('[DeepLink] Handling URI: ${uri.toString()}');

    final host = uri.host; // Get the host: 'memo' or 'comment'
    final pathSegments = uri.pathSegments;

    if (kDebugMode)
      print('[DeepLink] Host: $host, Path segments: $pathSegments');

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
      if (kDebugMode)
        print(
          '[DeepLink] Invalid URI structure: $host/${pathSegments.join('/')}',
        );
      return;
    }

    if (kDebugMode)
      print(
        '[DeepLink] Navigating to memo: $memoId, highlight comment: $commentIdToHighlight',
      );

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

    // Configure keyboard settings for macOS to avoid key event issues
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      // Create a set to track pressed keys
      final pressedKeys = <int>{};
      
      ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
        // For KeyDownEvent, check if we've already seen this key
        if (event is KeyDownEvent) {
          final keyCode = event.physicalKey.usbHidUsage;

          // If key is already tracked as pressed, consume the event to prevent duplicates
          if (pressedKeys.contains(keyCode)) {
            return true; // Handle the event (don't propagate)
          }

          // Track the key as pressed
          pressedKeys.add(keyCode);
        }
        // For KeyUpEvent, remove from our tracking set
        else if (event is KeyUpEvent) {
          pressedKeys.remove(event.physicalKey.usbHidUsage);
        }
        
        // Allow the event to propagate to the framework
        return false;
      });
    }
    
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
                  ref.read(captureUtilityToggleProvider.notifier).toggle();
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
          child: MaterialApp(
            navigatorKey:
                _navigatorKey, // Add navigator key for deep link navigation
            title: 'Flutter Memos',
            debugShowCheckedModeBanner: false,
            // Light theme configuration
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFFDC4C3E),
                primary: const Color(0xFFDC4C3E),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFFDC4C3E),
                elevation: 0,
              ),
              scaffoldBackgroundColor: const Color(0xFFF8F8F8),
              useMaterial3: true,
            ),
            // Dark theme configuration
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFFF6B58), // Brighter primary color
                secondary: Color(0xFFFF8A7A), // Brighter secondary
                surface: Color(0xFF282828),
                onSurface: Color(0xFFF0F0F0), // Brighter text on background
                error: Color(0xFFFF5252), // Error color
              ),
              scaffoldBackgroundColor: const Color(
                0xFF1A1A1A,
              ), // Darker scaffold
              cardColor: const Color(0xFF2C2C2C), // Slightly lighter card
              canvasColor: const Color(0xFF2C2C2C),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF252525), // Darker app bar
                foregroundColor: Color(0xFFFF6B58), // Brighter text/icons
                elevation: 0,
                iconTheme: IconThemeData(color: Color(0xFFFF6B58)),
              ),
              dividerColor: const Color(0xFF404040),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Color(0xFFF0F0F0)),
                bodyMedium: TextStyle(color: Color(0xFFF0F0F0)),
                bodySmall: TextStyle(color: Color(0xFFD0D0D0)),
                titleLarge: TextStyle(color: Color(0xFFF0F0F0)),
                titleMedium: TextStyle(color: Color(0xFFF0F0F0)),
                titleSmall: TextStyle(color: Color(0xFFF0F0F0)),
              ),
              chipTheme: const ChipThemeData(
                backgroundColor: Color(0xFF383838),
                disabledColor: Color(0xFF323232),
                selectedColor: Color(0xFF505050),
                secondarySelectedColor: Color(0xFF606060),
                padding: EdgeInsets.all(4),
                labelStyle: TextStyle(color: Color(0xFFF0F0F0)),
                secondaryLabelStyle: TextStyle(color: Color(0xFFF0F0F0)),
                brightness: Brightness.dark,
              ),
              // Ensure better visibility for widgets like TextFields, Buttons, etc.
              inputDecorationTheme: const InputDecorationTheme(
                fillColor: Color(0xFF353535),
                filled: true,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF505050)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFFFF6B58), width: 2),
                ),
                labelStyle: TextStyle(color: Color(0xFFD0D0D0)),
              ),
              useMaterial3: true,
            ),
            themeMode: themeMode, // Use the theme mode from the provider
            initialRoute: '/',
            routes: {
              '/': (context) => const HomeScreen(),
              '/memos': (context) => const MemosScreen(),
              '/chat': (context) => const ChatScreen(),
              '/mcp': (context) => const McpScreen(),
              // Keep new-memo route for backward compatibility but it's no longer the primary way to create memos
              '/new-memo': (context) => const NewMemoScreen(),
              '/filter-demo': (context) => const FilterDemoScreen(),
              '/riverpod-demo': (context) => const RiverpodDemoScreen(),
              '/codegen-test': (context) => const CodegenTestScreen(),
              '/settings': (context) => const SettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/memo-detail') {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder:
                      (context) =>
                          MemoDetailScreen(memoId: args['memoId'] as String),
                );
              } else if (settings.name == '/edit-entity') {
                // Renamed route
                final args = settings.arguments as Map<String, dynamic>;
                final entityType =
                    args['entityType'] as String? ?? 'memo'; // Default to memo
                final entityId =
                    args['entityId']
                        as String; // Will be memoId or "memoId/commentId"

                return MaterialPageRoute(
                  builder:
                      (context) => EditMemoScreen(
                        entityId: entityId,
                        entityType: entityType,
                      ),
                );
              } else if (settings.name == '/deep-link-target') {
                // Handle deep link target route
                final args = settings.arguments as Map<String, dynamic>? ?? {};
                final memoId = args['memoId'] as String?;
                final commentIdToHighlight =
                    args['commentIdToHighlight'] as String?;

                if (memoId != null) {
                  // Return a route with the provider override to set the highlighted comment
                  return MaterialPageRoute(
                    builder:
                        (context) => ProviderScope(
                          overrides: [
                            // Set the highlighted comment ID provider value
                            highlightedCommentIdProvider.overrideWith(
                              (ref) => commentIdToHighlight,
                            ),
                          ],
                          child: MemoDetailScreen(memoId: memoId),
                        ),
                  );
                }
                return null;
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Memos'),
        actions: [
          // Settings button
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          // Theme toggle button with dropdown
          PopupMenuButton<Object>(
            tooltip: 'Select theme',
            icon: Icon(
              themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : themeMode == ThemeMode.light
                      ? Icons.light_mode
                      : Icons.brightness_auto,
            ),
            onSelected: (Object value) async {
              if (value is ThemeMode) {
                if (kDebugMode) {
                  print('[HomeScreen] User selected theme: $value');
                }

                // Set the theme mode first
                ref.read(themeModeProvider.notifier).state = value;

                // Then save the preference
                await ref.read(saveThemeModeProvider)(value);

                // Provide user feedback
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Theme set to ${value.toString().split('.').last}',
                      ),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }
            },
            itemBuilder:
                (BuildContext context) => <PopupMenuEntry<Object>>[
                  const PopupMenuItem<Object>(
                    value: ThemeMode.light,
                    child: Row(
                      children: [
                        Icon(Icons.light_mode, size: 18),
                        SizedBox(width: 8),
                        Text('Light Mode'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<Object>(
                    value: ThemeMode.dark,
                    child: Row(
                      children: [
                        Icon(Icons.dark_mode, size: 18),
                        SizedBox(width: 8),
                        Text('Dark Mode'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<Object>(
                    value: ThemeMode.system,
                    child: Row(
                      children: [
                        Icon(Icons.brightness_auto, size: 18),
                        SizedBox(width: 8),
                        Text('System Default'),
                      ],
                    ),
                  ),
                  const PopupMenuItem<Object>(
                    value: 'settings',
                    child: Row(
                      children: [
                        Icon(Icons.settings, size: 18),
                        SizedBox(width: 8),
                        Text('Settings'),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: const Column(
        children: [
          Expanded(child: MemosScreen()),

          // Demo UI components have been temporarily removed but preserved in code
          // The following code is commented out but kept for future reference
          /*
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // MCP Integration Demo
                DemoService.buildMCPIntegrationDemo(context: context),
                const SizedBox(height: 10),
                
                // Assistant Chat - partially implemented
                DemoService.buildAssistantChat(context: context),
                const SizedBox(height: 10),
                
                // Filter Demo
                DemoService.buildFilterDemo(context: context),
                const SizedBox(height: 10),
                
                // Riverpod Demo
                DemoService.buildRiverpodDemo(context: context),
                const SizedBox(height: 10),
                
                // Riverpod Codegen Test
                DemoService.buildRiverpodCodegenTest(context: context),
                const SizedBox(height: 10),
              ],
            ),
          ),
          */

          // TODO: To restore demo functionality:
          // 1. Uncomment the code block above
          // 2. All demo buttons are now encapsulated in the DemoService class
          // 3. Demo code is still present in respective screen files, ready to be used
        ],
      ),
    );
  }
}
