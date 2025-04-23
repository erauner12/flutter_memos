import 'package:flutter/material.dart';
// Import the settings provider
import 'package:flutter_memos/providers/web_settings_provider.dart';
import 'package:flutter_memos/screens_web/blinko_web_ai_screen.dart';
import 'package:flutter_memos/screens_web/blinko_web_layout.dart';
// Import the new screens
import 'package:flutter_memos/screens_web/blinko_web_settings.dart';
import 'package:flutter_memos/screens_web/blinko_web_workbench.dart';
import 'package:flutter_memos/themes/blinko_web_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod

/// The root widget for the Blinko-styled web application.
/// Sets up the MaterialApp, custom theme, routes, and theme mode.
class BlinkoWebAppRoot extends ConsumerWidget {
  // Changed to ConsumerWidget
  const BlinkoWebAppRoot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Added WidgetRef ref
    // Watch the web settings provider to react to theme changes
    final settings = ref.watch(webSettingsProvider);

    return MaterialApp(
      title: 'Blinko Flutter Web',
      theme: BlinkoWebTheme.themeData, // Light theme
      darkTheme: BlinkoWebTheme.darkThemeData, // Dark theme (needs definition)
      // Set theme mode based on settings
      themeMode: settings.darkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (ctx) => const BlinkoWebLayout(),
        '/ai': (ctx) => const BlinkoWebAiScreen(),
        // Add routes for the new screens
        '/settings': (ctx) => const BlinkoWebSettings(),
        '/workbench': (ctx) => const BlinkoWebWorkbench(),
        // Add other top-level routes if needed
      },
      // Optional: Use onGenerateRoute for more complex routing logic
      // onGenerateRoute: (settings) {
      //   // Handle dynamic routes like /item/:id or /workbench/:id
      //   if (settings.name?.startsWith('/workbench/') ?? false) {
      //      final id = settings.name!.split('/').last;
      //      return MaterialPageRoute(builder: (context) => BlinkoWebWorkbenchDetail(id: id));
      //   }
      //   // Handle unknown routes
      //   return MaterialPageRoute(builder: (context) => NotFoundScreen());
      // },
    );
  }
}
