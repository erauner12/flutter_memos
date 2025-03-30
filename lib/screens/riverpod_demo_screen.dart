import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/simple_counter.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RiverpodDemoScreen extends ConsumerWidget {
  const RiverpodDemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the simple counter provider
    final counter = ref.watch(simpleCounterProvider);
    
    // Watch the time filter provider
    final timeFilter = ref.watch(timeFilterProvider);
    
    // Watch the memos provider
    final memosAsync = ref.watch(memosProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riverpod Demo'),
      ),
      body: Column(
        children: [
          // Counter demo section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text(
                    'Counter Demo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Count: $counter',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed:
                            () => ref
                                .read(simpleCounterProvider.notifier)
                                .update((state) => state - 1),
                        child: const Text('-'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed:
                            () => ref
                                .read(simpleCounterProvider.notifier)
                                .update((state) => state + 1),
                        child: const Text('+'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Filter selection
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time Filter',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Current filter: $timeFilter'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: timeFilter == 'all',
                        onSelected: (_) => ref.read(timeFilterProvider.notifier).state = 'all',
                      ),
                      FilterChip(
                        label: const Text('Today'),
                        selected: timeFilter == 'today',
                        onSelected: (_) => ref.read(timeFilterProvider.notifier).state = 'today',
                      ),
                      FilterChip(
                        label: const Text('This Week'),
                        selected: timeFilter == 'this_week',
                        onSelected: (_) => ref.read(timeFilterProvider.notifier).state = 'this_week',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Memos section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Memos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: memosAsync.when(
                      data: (memos) {
                        if (memos.isEmpty) {
                          return const Center(
                            child: Text('No memos found'),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: memos.length,
                          itemBuilder: (context, index) {
                            final memo = memos[index];
                            return MemoCard(
                              id: memo.id,
                              content: memo.content,
                              pinned: memo.pinned,
                              // createdAt: memo.createTime,
                              updatedAt: memo.updateTime,
                              showTimeStamps: true,
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
