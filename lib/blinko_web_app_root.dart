import 'package:flutter/material.dart';
import 'package:flutter_memos/themes/blinko_web_theme.dart'; // Import the custom theme
import 'package:flutter_memos/screens_web/blinko_web_layout.dart'; // Import the main layout
import 'package:flutter_memos/screens_web/blinko_web_ai_screen.dart'; // Import AI screen

/// The root widget for the Blinko-styled web application.
/// Sets up the MaterialApp, custom theme, and initial routes.
class BlinkoWebAppRoot extends StatelessWidget {
  const BlinkoWebAppRoot({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blinko Flutter Web', // Blinko-specific title
      theme: BlinkoWebTheme.themeData, // Apply the custom Blinko theme
      debugShowCheckedModeBanner: false,
      initialRoute: '/', // Start at the main layout
      routes: {
        '/': (ctx) => const BlinkoWebLayout(), // Main layout containing home, resources, etc.
        '/ai': (ctx) => const BlinkoWebAiScreen(), // Dedicated AI screen route
        // Add other top-level routes if needed
      },
      // Optional: Use onGenerateRoute for more complex routing logic
      // onGenerateRoute: (settings) {
      //   // Handle dynamic routes like /item/:id
      //   return MaterialPageRoute(builder: (context) => NotFoundScreen());
      // },
    );
  }
}
