import 'package:flutter/material.dart';
import 'screens/memos_screen.dart';
import 'screens/new_memo_screen.dart';
import 'screens/memo_detail_screen.dart';
import 'screens/edit_memo_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/mcp_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test API connection on app start
  await ApiService.instance.testConnection().then((isConnected) {
    if (!isConnected) {
      print("Warning: Could not connect to API server or invalid credentials. Check that apiBaseUrl is correct in api_service.dart.");
    } else {
      print("Successfully connected to API server.");
    }
  });
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Memos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      // Start at the Memos screen
      initialRoute: '/',
      routes: {
        '/': (context) => const MemosScreen(),
        '/newMemo': (context) => const NewMemoScreen(),
        '/memoDetail': (context) => const MemoDetailScreen(),
        '/editMemo': (context) => const EditMemoScreen(),
        '/chat': (context) => const ChatScreen(),
        '/mcp': (context) => const McpScreen(),
      },
    );
  }
}