import 'package:flutter/material.dart';
import 'package:flutter_memos/web_layout.dart'; // Import the new web layout scaffold

/// The root widget for the web application.
/// Sets up the MaterialApp and points to the WebLayout scaffold.
class WebAppRoot extends StatelessWidget {
  const WebAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MaterialApp for a standard web look and feel
    return MaterialApp(
      title: 'Flutter Memos Web', // Web-specific title
      theme: ThemeData(
        // Define a basic Material theme (customize as needed)
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.light, // Default to light theme
        // Add other theme customizations here
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        brightness: Brightness.dark, // Default to dark theme
        // Add other dark theme customizations here
      ),
      themeMode: ThemeMode.system, // Respect system theme preference
      debugShowCheckedModeBanner: false,
      home: const WebLayout(), // Use the new Blinko-like layout
    );
  }
}
