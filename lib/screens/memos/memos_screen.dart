import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/widgets/capture_utility.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memos_body.dart';
import 'memos_filter_bar.dart';

class MemosScreen extends ConsumerStatefulWidget {
  const MemosScreen({super.key});

  @override
  ConsumerState<MemosScreen> createState() => _MemosScreenState();
}

class _MemosScreenState extends ConsumerState<MemosScreen> {
  @override
  void initState() {
    super.initState();
    // Load saved filter preferences
    ref.read(loadFilterPreferencesProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memos'),
        // Removed sort toggle button from actions
        // actions: [ ... ],
      ),
      body: const Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(
            children: [
              // Filter area
              MemosFilterBar(),
              // Main content area
              Expanded(child: MemosBody()),
            ],
          ),
          // Pinned capture utility at bottom for creating new memos
          CaptureUtility(
            mode: CaptureMode.createMemo,
            hintText: 'Type or paste memo content...',
            buttonText: 'Add Memo',
          ),
        ],
      ),
      // FloatingActionButton removed as it's replaced by the CaptureUtility
    );
  }
}
