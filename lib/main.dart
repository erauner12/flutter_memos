import 'package:flutter/cupertino.dart';
// Assume ItemDetailScreen exists here or create it
import 'package:flutter_memos/screens/item_detail/item_detail_screen.dart';
import 'package:flutter_memos/screens/new_note/new_note_screen.dart'; // Import NewNoteScreen
import 'package:flutter_memos/widgets/config_check_wrapper.dart'; // Import the wrapper
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase

// TODO: Replace with your actual Supabase URL and Anon Key, potentially from env vars
const String supabaseUrl = 'https://ugkvofhnqsqybgccxosm.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InVna3ZvZmhucXNxeWJnY2N4b3NtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDUzODc1NDYsImV4cCI6MjA2MDk2MzU0Nn0.niLzD267kFhw9SJJoloTEGVKnw-c3BbnoS1_A4kSOCQ';

void main() async {
  // Ensure Flutter bindings are initialized for async operations before runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    // Optional: Add auth flow types, storage options, etc.
    // authFlowType: AuthFlowType.pkce,
  );

  runApp(const ProviderScope(child: MyAppRoot()));
}

/// The root widget of the application.
/// Sets up the CupertinoApp and points to the ConfigCheckWrapper.
class MyAppRoot extends StatelessWidget {
  const MyAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // ConfigCheckWrapper will handle the initial loading and routing logic.
    return CupertinoApp(
      title: 'ThoughtCache', // Updated app title
      theme: const CupertinoThemeData(
        brightness: Brightness.light,
      ), // Optional: Set theme
      debugShowCheckedModeBanner: false,
      home: const ConfigCheckWrapper(), // Start with the wrapper
      // Add onGenerateRoute to handle named navigation
      onGenerateRoute: (RouteSettings settings) {
        switch (settings.name) {
          case '/new-note':
            return CupertinoPageRoute(
              builder: (_) => const NewNoteScreen(),
              settings: settings, // Pass settings along
            );
          case '/item-detail':
            // Extract arguments safely
            final args = settings.arguments as Map?;
            final itemId = args?['itemId'] as String?;
            // Ensure itemId is provided, otherwise handle error or default
            if (itemId != null) {
              return CupertinoPageRoute(
                builder: (_) => ItemDetailScreen(itemId: itemId),
                settings: settings, // Pass settings along
              );
            } else {
              // Handle error: itemId was expected but not provided
              // You could navigate to an error screen or back
              print(
                'Error: Navigating to /item-detail without providing an itemId.',
              );
              // Example: Navigate back or to a default screen
              return CupertinoPageRoute(
                builder:
                    (_) => const ConfigCheckWrapper(), // Or an error screen
                settings: settings,
              );
            }
          // Add cases for other named routes here if needed
          // case '/settings':
          //   return CupertinoPageRoute(builder: (_) => SettingsScreen());
          default:
            // If the route name is not recognized,
            // navigate to the home/default screen or show an error.
            // Returning null will cause an error, so handle it gracefully.
            print('Warning: Unhandled route: ${settings.name}');
            return CupertinoPageRoute(
              builder: (_) => const ConfigCheckWrapper(), // Fallback route
              settings: settings,
            );
        }
      },
    );
  }
}

// Placeholder for ItemDetailScreen if it doesn't exist yet.
// Create this file: lib/screens/item_detail/item_detail_screen.dart
// class ItemDetailScreen extends StatelessWidget {
//   final String itemId;
//   const ItemDetailScreen({super.key, required this.itemId});
//
//   @override
//   Widget build(BuildContext context) {
//     return CupertinoPageScaffold(
//       navigationBar: CupertinoNavigationBar(
//         middle: Text('Item Detail: $itemId'),
//       ),
//       child: Center(
//         child: Text('Details for item ID: $itemId'),
//       ),
//     );
//   }
// }
