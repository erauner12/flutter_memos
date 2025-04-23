import 'dart:developer'; // Import the developer log

import 'package:flutter/material.dart';
import 'package:flutter_memos/models/workbench_item_reference.dart'; // Use WorkbenchItemReference
import 'package:flutter_memos/models/workbench_item_type.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/providers/workbench_provider.dart'; // Import the correct provider file
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

/// Screen for displaying Workbench items in the Blinko web UI.
class BlinkoWebWorkbench extends ConsumerWidget {
  const BlinkoWebWorkbench({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the combined workbench items provider
    final combinedState = ref.watch(allWorkbenchItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workbench (All Items)'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Items',
            onPressed:
                combinedState.isLoading
                    ? null // Disable if already loading
                    : () {
                      // Trigger refresh on all individual notifiers
                      final instances =
                          ref.read(workbenchInstancesProvider).instances;
                      for (final instance in instances) {
                        ref
                            .read(workbenchProviderFamily(instance.id).notifier)
                            .refreshItemDetails();
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Refreshing workbench items...'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create New Item',
            onPressed: () {
              // TODO: Implement creation flow (likely needs instance selection)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create workbench item not implemented yet.')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(context, combinedState),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WorkbenchCombinedState state) {
    if (state.isLoading && state.items.isEmpty) {
      // Show loading indicator only if loading initial data
      return const Center(child: CircularProgressIndicator());
    } else if (state.error != null) {
      // Show error message
      return Center(
        child: Text(
          'Error loading workbench items: ${state.error}',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      );
    } else if (state.items.isEmpty) {
      // Show empty state message
      return const Center(
        child: Text('No workbench items found across all instances.'),
      );
    } else {
      // Display items in a list
      // Add a subtle loading indicator at the top if refreshing
      return Column(
        children: [
          if (state.isLoading && state.items.isNotEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: LinearProgressIndicator(),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: state.items.length,
              itemBuilder: (context, index) {
                return _buildWorkbenchItemCard(context, state.items[index]);
              },
            ),
          ),
        ],
      );
    }
  }


  /// Builds a card widget for a single workbench item reference.
  Widget _buildWorkbenchItemCard(
    BuildContext context,
    WorkbenchItemReference itemRef,
  ) {
    final dateFormat = DateFormat.yMMMd().add_jm(); // Example date format
    final theme = Theme.of(context);

    // Determine icon based on type
    IconData itemIcon;
    switch (itemRef.referencedItemType) {
      case WorkbenchItemType.note:
        itemIcon = Icons.description_outlined;
        break;
      case WorkbenchItemType.task:
        itemIcon = Icons.task_alt_outlined;
        break;
      case WorkbenchItemType
          .comment: // Assuming comments might be directly referenced someday
        itemIcon = Icons.comment_outlined;
        break;
      default:
        itemIcon = Icons.widgets_outlined; // Default/Unknown
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(itemIcon, color: theme.colorScheme.primary),
        title: Text(itemRef.previewContent ?? 'No Preview Available'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Server: ${itemRef.serverName ?? itemRef.serverId} (${itemRef.serverType.name})',
            ),
            Text(
              'Last Activity: ${dateFormat.format(itemRef.overallLastUpdateTime.toLocal())}',
            ),
            // Optionally show instance ID/Name if needed for context
            // Text('Instance: ${itemRef.instanceId}'),
            if (itemRef.latestComment != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Latest Comment: "${itemRef.latestComment!.content ?? ""}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine:
            itemRef.latestComment != null, // Adjust layout if comment shown
        onTap: () {
          // TODO: Implement navigation to workbench item detail (might need instance context)
          log(
            'Tapped on workbench item reference: ${itemRef.id} (Ref ID: ${itemRef.referencedItemId}, Instance: ${itemRef.instanceId})',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Tapped item: ${itemRef.id}. Navigation not implemented.',
              ),
            ),
          );
          // Example: Navigator.pushNamed(context, '/workbench/${itemRef.instanceId}/${itemRef.id}');
        },
      ),
    );
  }
}
