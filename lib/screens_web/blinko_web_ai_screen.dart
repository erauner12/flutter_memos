import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Placeholder screen for the AI Chat page in the Blinko web UI.
class BlinkoWebAiScreen extends ConsumerWidget {
  const BlinkoWebAiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Implement AI chat functionality using Riverpod providers

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blinko AI Chat'),
        leading: IconButton( // Add back button
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 60, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'AI Chat Interface',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'This screen will contain the AI chat UI.',
                textAlign: TextAlign.center,
              ),
              // TODO: Replace with actual chat input and message list
              const Spacer(), // Pushes content to center for now
              const TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message to AI...',
                  suffixIcon: Icon(Icons.send),
                ),
              ),
              const SizedBox(height: 16), // Spacing at the bottom
            ],
          ),
        ),
      ),
    );
  }
}
