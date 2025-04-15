import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/workbench_provider.dart';
import 'package:flutter_memos/screens/workbench/widgets/workbench_item_tile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class WorkbenchScreen extends ConsumerWidget {
  const WorkbenchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workbenchState = ref.watch(workbenchProvider);
    final items = workbenchState.items;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('Workbench'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: workbenchState.isLoading
              ? null // Disable refresh while loading
              : () => ref.read(workbenchProvider.notifier).loadItems(),
          child: const Icon(CupertinoIcons.refresh),
        ),
      ),
      child: SafeArea(
        child: Builder( // Use Builder to get context with theme
          builder: (context) {
            if (workbenchState.isLoading && items.isEmpty) {
              return const Center(child: CupertinoActivityIndicator());
            }

            if (workbenchState.error != null && items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.exclamationmark_triangle, size: 40, color: CupertinoColors.systemRed),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        'Error loading Workbench: ${workbenchState.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                        ),
                    ),
                    const SizedBox(height: 10),
                    CupertinoButton(
                      child: const Text('Retry'),
                      onPressed: () => ref.read(workbenchProvider.notifier).loadItems(),
                    ),
                  ],
                ),
              );
            }

            if (items.isEmpty) {
              return const Center(
                child: Text(
                  'Your Workbench is empty.\nAdd items via long-press or actions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: CupertinoColors.secondaryLabel),
                ),
              );
            }

            // Use CupertinoListSection for better iOS styling
            return CupertinoListSection.insetGrouped(
              header: workbenchState.isLoading ? const Padding(
                padding: EdgeInsets.all(8.0),
                child: Center(child: CupertinoActivityIndicator()),
              ) : null, // Show loading indicator in header if loading more
              children: items.map((item) => WorkbenchItemTile(
                key: ValueKey(item.id), // Use reference ID as key
                itemReference: item,
              )).toList(),
            );
          }
        ),
      ),
    );
  }
}
