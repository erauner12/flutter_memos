import 'package:flutter/material.dart';
import 'package:flutter_memos/providers/simple_riverpod.dart';
import 'package:flutter_memos/widgets/memo_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodegenTestScreen extends ConsumerWidget {
  const CodegenTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riverpod Examples')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTitle('Riverpod Examples'),
          _buildDescription(
            'This screen demonstrates various Riverpod patterns that you can use in your app.',
          ),
          
          _buildSection('Simple Providers'),
          _buildSimpleProviderExample(ref),
          
          _buildSection('Notifier Providers'),
          _buildNotifierExample(ref),

          _buildSection('Async Providers'),
          _buildAsyncExample(ref),

          _buildSection('Family Providers'),
          _buildFamilyExample(ref),

          _buildSection('Provider Dependencies'),
          _buildDependentProvidersExample(ref),

          _buildSection('Advanced Example'),
          _buildAdvancedExample(ref),

          const SizedBox(height: 40),

          _buildNote('''
Note: We're using standard Riverpod providers here instead of code generation.
The advantage of code generation is less boilerplate, especially for Notifier classes,
but the core functionality is the same.

You can migrate to code generation later when the tooling issues are resolved.
          '''),
        ],
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDescription(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildSimpleProviderExample(WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final greeting = ref.watch(greetingProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Greeting: $greeting'),
            const SizedBox(height: 8),
            Text('Counter: $count'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => ref.read(counterProvider.notifier).state--,
                  child: const Text('-'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => ref.read(counterProvider.notifier).state++,
                  child: const Text('+'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifierExample(WidgetRef ref) {
    final count = ref.watch(counterNotifierProvider);
    final notifier = ref.read(counterNotifierProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notifier Counter: $count'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: notifier.decrement,
                  child: const Text('-'),
                ),
                ElevatedButton(
                  onPressed: notifier.increment,
                  child: const Text('+'),
                ),
                ElevatedButton(
                  onPressed: notifier.reset,
                  child: const Text('Reset'),
                ),
                ElevatedButton(
                  onPressed: () => notifier.setValue(10),
                  child: const Text('Set to 10'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Notice how we can define methods on the notifier class, making state manipulation more organized.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAsyncExample(WidgetRef ref) {
    final asyncData = ref.watch(asyncDataProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Async Data:'),
            const SizedBox(height: 8),
            asyncData.when(
              data: (data) => Text('Data: $data'),
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(asyncDataProvider),
              child: const Text('Refresh'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Async providers automatically handle loading, error, and data states.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyExample(WidgetRef ref) {
    final greeting = ref.watch(parameterizedProvider('User'));
    final asyncData = ref.watch(asyncParameterizedProvider(2));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Parameterized: $greeting'),
            const SizedBox(height: 8),
            const Text('Async Parameterized (2 seconds):'),
            const SizedBox(height: 4),
            asyncData.when(
              data: (data) => Text(data),
              loading: () => const CircularProgressIndicator(),
              error: (error, stackTrace) => Text('Error: $error'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed:
                      () => ref.invalidate(asyncParameterizedProvider(2)),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Family providers allow passing parameters to providers.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDependentProvidersExample(WidgetRef ref) {
    final dependent = ref.watch(dependentProvider);
    final dependentAsync = ref.watch(dependentAsyncProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dependent: $dependent'),
            const SizedBox(height: 8),
            Text(
              'Dependent Async: ${dependentAsync.when(data: (data) => data, loading: () => "Loading...", error: (error, _) => "Error: $error")}',
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.read(counterProvider.notifier).state++,
              child: const Text('Increment Counter'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Providers can depend on other providers and automatically update when dependencies change.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAdvancedExample(WidgetRef ref) {
    final filter = ref.watch(memoFilterProvider);
    final memosAsync = ref.watch(advancedMemosProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter Memos:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter == 'all',
                  onSelected:
                      (_) =>
                          ref.read(memoFilterProvider.notifier).state = 'all',
                ),
                FilterChip(
                  label: const Text('Pinned'),
                  selected: filter == 'pinned',
                  onSelected:
                      (_) =>
                          ref.read(memoFilterProvider.notifier).state =
                              'pinned',
                ),
                FilterChip(
                  label: const Text('Normal'),
                  selected: filter == 'normal',
                  onSelected:
                      (_) =>
                          ref.read(memoFilterProvider.notifier).state =
                              'normal',
                ),
                FilterChip(
                  label: const Text('Archived'),
                  selected: filter == 'archived',
                  onSelected:
                      (_) =>
                          ref.read(memoFilterProvider.notifier).state =
                              'archived',
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Memos:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: memosAsync.when(
                data: (memos) {
                  if (memos.isEmpty) {
                    return const Center(child: Text('No memos found'));
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
                        showTimeStamps: true,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error:
                    (error, stackTrace) => Center(child: Text('Error: $error')),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This example combines state, async data, and dependent providers to create a full feature.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildNote(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}
