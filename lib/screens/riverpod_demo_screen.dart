import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_memos/providers/simple_counter.dart';
import 'package:flutter_memos/widgets/memo_card.dart'; // Assuming MemoCard is migrated
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
    final memosAsync = ref.watch(memosNotifierProvider);

    // Use CupertinoPageScaffold and CupertinoNavigationBar
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Riverpod Demo'),
        transitionBetweenRoutes: false,
      ),
      child: SafeArea(
        // Add SafeArea
        child: ListView(
          // Use ListView for scrolling content
          padding: const EdgeInsets.all(16.0),
          children: [
            // Counter demo section - Replace Card with CupertinoListSection
            CupertinoListSection.insetGrouped(
              header: const Text('COUNTER DEMO'),
              children: [
                CupertinoListTile(
                  title: Text(
                    'Count: $counter',
                    style: const TextStyle(fontSize: 24),
                  ),
                  // Use trailing for buttons
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton(
                        // Use CupertinoButton
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minSize: 0,
                        onPressed:
                            () => ref
                                .read(simpleCounterProvider.notifier)
                                .update((state) => state - 1),
                        child: const Text('-'),
                      ),
                      const SizedBox(width: 8), // Add spacing
                      CupertinoButton(
                        // Use CupertinoButton
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minSize: 0,
                        onPressed:
                            () => ref
                                .read(simpleCounterProvider.notifier)
                                .update((state) => state + 1),
                        child: const Text('+'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing between sections

            // Filter selection - Replace Card with CupertinoListSection
            CupertinoListSection.insetGrouped(
              header: const Text('TIME FILTER'),
              children: [
                CupertinoListTile(title: Text('Current filter: $timeFilter')),
                // Use Wrap for filter chips (buttons)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15.0,
                    vertical: 8.0,
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4, // Add run spacing
                    children: [
                      // Replace FilterChip with styled CupertinoButton
                      _buildFilterChipButton(
                        context,
                        ref,
                        'All',
                        'all',
                        timeFilter,
                      ),
                      _buildFilterChipButton(
                        context,
                        ref,
                        'Today',
                        'today',
                        timeFilter,
                      ),
                      _buildFilterChipButton(
                        context,
                        ref,
                        'This Week',
                        'this_week',
                        timeFilter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing between sections
            // Memos section
            const Text(
              'MEMOS',
              style: TextStyle(
                fontSize: 14, // Adjust size for section header
                fontWeight: FontWeight.w600,
                color:
                    CupertinoColors.secondaryLabel, // Use secondary label color
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              // Use SizedBox to constrain height if needed, or let ListView handle it
              height: 300, // Example fixed height, adjust as needed
              child: Builder(
                builder: (context) {
                  // Show loading spinner for initial load
                  if (memosAsync.isLoading && memosAsync.memos.isEmpty) {
                    return const Center(
                      child:
                          CupertinoActivityIndicator(), // Use CupertinoActivityIndicator
                    );
                  }

                  // Show error message if there's an error and no memos to display
                  if (memosAsync.error != null && memosAsync.memos.isEmpty) {
                    return Center(
                      child: Text(
                        'Error: ${memosAsync.error}',
                        style: TextStyle(
                          color: CupertinoColors.systemRed.resolveFrom(context),
                        ),
                      ),
                    );
                  }

                  final memos = memosAsync.memos;
                  if (memos.isEmpty) {
                    return const Center(child: Text('No memos found'));
                  }

                  // Use ListView.builder directly (assuming MemoCard is migrated)
                  return ListView.builder(
                    itemCount: memos.length,
                    itemBuilder: (context, index) {
                      final memo = memos[index];
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
              ),
            ),
          ],
        ),
      ),
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
      onPressed: () => ref.read(timeFilterProvider.notifier).state = value,
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
}
