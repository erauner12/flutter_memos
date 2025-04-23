import 'package:flutter/material.dart';
import 'package:flutter_memos/models/workbench_item.dart'; // Assuming WorkbenchItem model exists
// TODO: Adjust import paths based on your project structure
import 'package:flutter_memos/providers/workbench_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart'; // For date formatting

/// Screen for displaying Workbench items in the Blinko web UI.
class BlinkoWebWorkbench extends ConsumerWidget {
  const BlinkoWebWorkbench({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the workbench items provider
    final workbenchDataAsync = ref.watch(workbenchItemsProvider); // Assuming provider exists

    return Scaffold(
      // This screen might be pushed or part of the main layout.
      // If pushed, it needs an AppBar.
      appBar: AppBar(
        title: const Text('Workbench'),
        // Add actions if needed, e.g., create new workbench item
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Create New Item',
            onPressed: () {
              // TODO: Implement creation flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Create workbench item not implemented yet.')),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: workbenchDataAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(child: Text('No workbench items found.'));
            }
            // Display items in a list
            return ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                return _buildWorkbenchItemCard(context, items[index]);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Error loading workbench items: $err',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds a card widget for a single workbench item.
  Widget _buildWorkbenchItemCard(BuildContext context, WorkbenchItem item) {
    final dateFormat = DateFormat.yMMMd().add_jm(); // Example date format

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.widgets_outlined), // Example icon
        title: Text(item.title ?? 'Untitled Item'),
        subtitle: Text('Created: ${item.createdAt != null ? dateFormat.format(item.createdAt!) : 'Unknown'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Implement navigation to workbench item detail
          print('Tapped on workbench item: ${item.id}');
          // Example: Navigator.pushNamed(context, '/workbench/${item.id}');
        },
      ),
    );
  }
}
