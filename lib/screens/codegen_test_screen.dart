import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/providers/simple_riverpod.dart';
import 'package:flutter_memos/widgets/memo_card.dart'; // Assuming MemoCard is migrated
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CodegenTestScreen extends ConsumerWidget {
  const CodegenTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use CupertinoPageScaffold and CupertinoNavigationBar
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Riverpod Examples'),
        transitionBetweenRoutes: false,
      ),
      child: SafeArea(
        // Add SafeArea
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitle('Riverpod Examples'),
            _buildDescription(
              'This screen demonstrates various Riverpod patterns that you can use in your app.',
            ),

            _buildSectionHeader('Simple Providers'),
            _buildSimpleProviderExample(context, ref),

            _buildSectionHeader('Notifier Providers'),
            _buildNotifierExample(context, ref),

            _buildSectionHeader('Async Providers'),
            _buildAsyncExample(context, ref),

            _buildSectionHeader('Family Providers'),
            _buildFamilyExample(context, ref),

            _buildSectionHeader('Provider Dependencies'),
            _buildDependentProvidersExample(context, ref),

            _buildSectionHeader('Advanced Example'),
            _buildAdvancedExample(context, ref),

            const SizedBox(height: 40),

            _buildNote(context, '''
Note: We're using standard Riverpod providers here instead of code generation.
The advantage of code generation is less boilerplate, especially for Notifier classes,
but the core functionality is the same.

You can migrate to code generation later when the tooling issues are resolved.
            '''),
          ],
        ),
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

  // Use Cupertino style section header
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: CupertinoColors.secondaryLabel,
        ),
      ),
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildSimpleProviderExample(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterProvider);
    final greeting = ref.watch(greetingProvider);

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        CupertinoListTile(title: Text('Greeting: $greeting')),
        CupertinoListTile(
          title: Text('Counter: $count'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoButton(
                // Use CupertinoButton
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minSize: 0,
                onPressed: () => ref.read(counterProvider.notifier).state--,
                child: const Text('-'),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                // Use CupertinoButton
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minSize: 0,
                onPressed: () => ref.read(counterProvider.notifier).state++,
                child: const Text('+'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildNotifierExample(BuildContext context, WidgetRef ref) {
    final count = ref.watch(counterNotifierProvider);
    final notifier = ref.read(counterNotifierProvider.notifier);

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        CupertinoListTile(title: Text('Notifier Counter: $count')),
        Padding(
          // Wrap buttons for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                onPressed: notifier.decrement,
                child: const Text('-'),
              ),
              CupertinoButton(
                onPressed: notifier.increment,
                child: const Text('+'),
              ),
              CupertinoButton(
                onPressed: notifier.reset,
                child: const Text('Reset'),
              ),
              CupertinoButton(
                onPressed: () => notifier.setValue(10),
                child: const Text('Set to 10'),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 0, 15.0, 8.0),
          child: Text(
            'Notice how we can define methods on the notifier class, making state manipulation more organized.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildAsyncExample(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(asyncDataProvider);

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        const CupertinoListTile(title: Text('Async Data:')),
        Padding(
          // Wrap the async content for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: asyncData.when(
            data: (data) => Text('Data: $data'),
            loading:
                () => const Center(
                  child: CupertinoActivityIndicator(),
                ), // Use CupertinoActivityIndicator
            error:
                (error, stackTrace) => Text(
                  'Error: $error',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
          ),
        ),
        Padding(
          // Wrap button for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: CupertinoButton(
            onPressed: () => ref.invalidate(asyncDataProvider),
            child: const Text('Refresh'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 0, 15.0, 8.0),
          child: Text(
            'Async providers automatically handle loading, error, and data states.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildFamilyExample(BuildContext context, WidgetRef ref) {
    final greeting = ref.watch(parameterizedProvider('User'));
    final asyncData = ref.watch(asyncParameterizedProvider(2));

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        CupertinoListTile(title: Text('Parameterized: $greeting')),
        const CupertinoListTile(
          title: Text('Async Parameterized (2 seconds):'),
        ),
        Padding(
          // Wrap async content for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: asyncData.when(
            data: (data) => Text(data),
            loading:
                () => const Center(
                  child: CupertinoActivityIndicator(),
                ), // Use CupertinoActivityIndicator
            error:
                (error, stackTrace) => Text(
                  'Error: $error',
                  style: const TextStyle(color: CupertinoColors.systemRed),
                ),
          ),
        ),
        Padding(
          // Wrap button for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: CupertinoButton(
            onPressed: () => ref.invalidate(asyncParameterizedProvider(2)),
            child: const Text('Refresh'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 0, 15.0, 8.0),
          child: Text(
            'Family providers allow passing parameters to providers.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildDependentProvidersExample(BuildContext context, WidgetRef ref) {
    final dependent = ref.watch(dependentProvider);
    final dependentAsync = ref.watch(dependentAsyncProvider);

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        CupertinoListTile(title: Text('Dependent: $dependent')),
        CupertinoListTile(
          title: Text(
            'Dependent Async: ${dependentAsync.when(data: (data) => data, loading: () => "Loading...", error: (error, _) => "Error: $error")}',
          ),
        ),
        Padding(
          // Wrap button for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: CupertinoButton(
            onPressed: () => ref.read(counterProvider.notifier).state++,
            child: const Text('Increment Counter'),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 0, 15.0, 8.0),
          child: Text(
            'Providers can depend on other providers and automatically update when dependencies change.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  // Replace Card with CupertinoListSection
  Widget _buildAdvancedExample(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(memoFilterProvider);
    final memosAsync = ref.watch(advancedMemosProvider);

    return CupertinoListSection.insetGrouped(
      margin: EdgeInsets.zero,
      children: [
        const CupertinoListTile(title: Text('Filter Memos:')),
        Padding(
          // Wrap filter chips for padding
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 8.0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // Replace FilterChip with styled CupertinoButton
              _buildFilterChipButton(context, ref, 'All', 'all', filter),
              _buildFilterChipButton(context, ref, 'Pinned', 'pinned', filter),
              _buildFilterChipButton(context, ref, 'Normal', 'normal', filter),
              _buildFilterChipButton(
                context,
                ref,
                'Archived',
                'archived',
                filter,
              ),
            ],
          ),
        ),
        const CupertinoListTile(title: Text('Memos:')),
        SizedBox(
          // Keep SizedBox for height constraint
          height: 200,
          child: Padding(
            // Add padding around the list view
            padding: const EdgeInsets.symmetric(
              horizontal: 15.0,
              vertical: 8.0,
            ),
            child: memosAsync.when(
              data: (memos) {
                if (memos.isEmpty) {
                  return const Center(child: Text('No memos found'));
                }

                return ListView.builder(
                  itemCount: memos.length,
                  itemBuilder: (context, index) {
                    final memo = memos[index];
                    // Assuming MemoCard is migrated
                    return Padding(
                      // Add padding around MemoCard
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: MemoCard(
                        id: memo.id,
                        content: memo.content,
                        pinned: memo.pinned,
                        updatedAt: memo.updateTime,
                        showTimeStamps: true,
                      ),
                    );
                  },
                );
              },
              loading:
                  () => const Center(
                    child: CupertinoActivityIndicator(),
                  ), // Use CupertinoActivityIndicator
              error:
                  (error, stackTrace) => Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(15.0, 8.0, 15.0, 8.0),
          child: Text(
            'This example combines state, async data, and dependent providers to create a full feature.',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 12,
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ),
      ],
    );
  }

  // Helper to build filter chip-like buttons
  Widget _buildFilterChipButton(
    BuildContext context,
    WidgetRef ref,
    String label,
    String value,
    String currentValue,
  ) {
    final bool selected = currentValue == value;
    final theme = CupertinoTheme.of(context);

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      color:
          selected
              ? theme.primaryColor
              : CupertinoColors.secondarySystemFill.resolveFrom(context),
      onPressed: () => ref.read(memoFilterProvider.notifier).state = value,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color:
              selected
                  ? CupertinoColors.white
                  : CupertinoColors.label.resolveFrom(context),
        ),
      ),
    );
  }

  Widget _buildNote(BuildContext context, String text) {
    // Use Cupertino dynamic colors
    final Color backgroundColor = CupertinoColors
        .secondarySystemGroupedBackground
        .resolveFrom(context);
    final Color textColor = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: textColor)),
    );
  }
}
