import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/codegen_test_screen.dart'; // Add this import
import 'package:flutter_memos/screens/edit_memo_screen.dart';
import 'package:flutter_memos/screens/filter_demo_screen.dart';
import 'package:flutter_memos/screens/mcp_screen.dart';
import 'package:flutter_memos/screens/memo_detail_screen.dart';
import 'package:flutter_memos/screens/memos_screen.dart';
import 'package:flutter_memos/screens/new_memo_screen.dart';
import 'package:flutter_memos/screens/riverpod_demo_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configure keyboard settings for macOS to avoid key event issues
    if (Theme.of(context).platform == TargetPlatform.macOS) {
      ServicesBinding.instance.keyboard.addHandler((KeyEvent event) {
        // Allow the event to propagate to the framework
        return false;
      });
    }
    
    return GestureDetector(
      onTap: () {
        // Unfocus when tapping outside of a text field
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
      title: 'Flutter Memos',
      debugShowCheckedModeBanner: false,
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/memos': (context) => const MemosScreen(),
        '/chat': (context) => const ChatScreen(),
        '/mcp': (context) => const McpScreen(),
        '/new-memo': (context) => const NewMemoScreen(),
          '/filter-demo': (context) => const FilterDemoScreen(),
          '/riverpod-demo': (context) => const RiverpodDemoScreen(),
          '/codegen-test': (context) => const CodegenTestScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/memo-detail') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => MemoDetailScreen(
              memoId: args['memoId'] as String,
            ),
            );
        } else if (settings.name == '/edit-memo') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => EditMemoScreen(
              memoId: args['memoId'] as String,
            ),
          );
        }
        return null;
        },
      ),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Memos'),
      ),
      body: Column(
        children: [
          const Expanded(
            child: MemosScreen(),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0079BF),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/mcp');
                    },
                    child: const Text('MCP Integration Demo'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC4C3E),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                    child: const Text('Assistant Chat'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/filter-demo');
                    },
                    child: const Text('Filter Demo'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9C27B0),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/riverpod-demo');
                    },
                    child: const Text('Riverpod Demo'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF673AB7),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(context, '/codegen-test');
                    },
                    child: const Text('Riverpod Codegen Test'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
