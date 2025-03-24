import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/generated/counter_provider.dart';
import 'package:flutter_memos/providers/generated/filter_providers.dart';
import 'package:flutter_memos/providers/generated/memo_provider.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodegenExampleScreen extends ConsumerWidget {
  const CodegenExampleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the generated counter providers
    final counterValue = ref.watch(counterProvider);
    final controllerValue = ref.watch(counterControllerProvider);
    
    // Use the generated filter providers
    final timeFilter = ref.watch(timeFilterProvider);
    final statusFilter = ref.watch(statusFilterProvider);
    final combinedFilter = ref.watch(combinedFilterProvider);
    
    // Use the generated memo providers (only if we've run build_runner)
    final memosAsync = ref.watch(memosProvider(filter: combinedFilter));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Codegen Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Counter section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Counter Examples',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Simple Counter: $counterValue'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => ref.read(counterProvider.notifier).update((state) => state - 1),
                        child: const Text('-'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(counterProvider.notifier).update((state) => state + 1),
                        child: const Text('+'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Notifier Counter: $controllerValue'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => ref.read(counterControllerProvider.notifier).decrement(),
                        child: const Text('-'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(counterControllerProvider.notifier).increment(),
                        child: const Text('+'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => ref.read(counterControllerProvider.notifier).reset(),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Filter section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Examples',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text('Time Filter: $timeFilter'),
                  Text('Status Filter: $statusFilter'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Today'),
                        selected: timeFilter == 'today',
                        onSelected: (_) => ref.read(timeFilterProvider.notifier).updateFilter('today'),
                      ),
                      FilterChip(
                        label: const Text('All Time'),
                        selected: timeFilter == 'all',
                        onSelected: (_) => ref.read(timeFilterProvider.notifier).updateFilter('all'),
                      ),
                      FilterChip(
                        label: const Text('Untagged'),
                        selected: statusFilter == 'untagged',
                        onSelected: (_) => ref.read(statusFilterProvider.notifier).updateFilter('untagged'),
                      ),
                      FilterChip(
                        label: const Text('Tagged'),
                        selected: statusFilter == 'tagged',
                        onSelected: (_) => ref.read(statusFilterProvider.notifier).updateFilter('tagged'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Combined Filter: ${combinedFilter.isEmpty ? '(none)' : combinedFilter}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Memos section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Memos Example',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 250,
                    child: memosAsync.when(
                      data: (memos) {
                        if (memos.isEmpty) {
                          return const Center(
                            child: Text('No memos found with the current filters'),
                          );
                        }
                        
                        return ListView.builder(
                          itemCount: memos.length,
                          itemBuilder: (context, index) {
                            final memo = memos[index];
                            return MemoCard(
                              content: memo.content,
                              pinned: memo.pinned,
                              createdAt: memo.createTime,
                              updatedAt: memo.updateTime,
                              onTap: () {
                                // Show memo details
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Tapped memo: ${memo.id}')),
                                );
                              },
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text('Error: $error'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Note about code generation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'Note: Code Generation Required',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'To make this screen fully functional, run:',
                  textAlign: TextAlign.center,
                ),
                Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'flutter pub run build_runner build --delete-conflicting-outputs',
                    style: TextStyle(fontFamily: 'monospace'),
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
