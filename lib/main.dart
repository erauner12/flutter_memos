import 'package:flutter/material.dart';
import 'package:flutter_memos/screens/memos_screen.dart';
import 'package:flutter_memos/screens/chat_screen.dart';
import 'package:flutter_memos/screens/mcp_screen.dart';
import 'package:flutter_memos/screens/memo_detail_screen.dart';
import 'package:flutter_memos/screens/edit_memo_screen.dart';
import 'package:flutter_memos/screens/new_memo_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/memo-detail': (context) => const MemoDetailScreen(),
        '/edit-memo': (context) => const EditMemoScreen(),
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
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Memos'),
      ),
      body: Column(
        children: [
          Expanded(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}