import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_memos/screens/workbench/workbench_screen.dart'; // Import for _showInstanceActions
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Helper function to show instance actions from the selector widget
// Needs access to context, ref, and the specific instance.
// It finds the WorkbenchScreenState to call its _showInstanceActions method.
void _showInstanceActionsViaRef(
  BuildContext context,
  WidgetRef ref,
  WorkbenchInstance instance,
) {
  // Find the state object of the WorkbenchScreen ancestor
  final workbenchScreenState =
      context.findAncestorStateOfType<_WorkbenchScreenState>();
  if (workbenchScreenState != null) {
    // Call the method on the found state object
    workbenchScreenState._showInstanceActions(instance);
  } else {
    // Fallback or error handling if the state cannot be found
    print(
      "Error: Could not find WorkbenchScreenState to show instance actions.",
    );
    // Optionally show a generic error message
  }
}


class WorkbenchInstanceSelector extends ConsumerWidget {
  const WorkbenchInstanceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(workbenchInstancesProvider).instances;
    final activeId  = ref.watch(workbenchInstancesProvider).activeInstanceId;

    // Map<instanceId, Widget> for CupertinoSlidingSegmentedControl
    final segments = {
      for (final i in instances)
        i.id: GestureDetector(
          // Add long-press gesture detector
          onLongPress: () => _showInstanceActionsViaRef(context, ref, i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              i.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ),
    };

    // Handle empty instances case for the segmented control
    if (segments.isEmpty) {
      // Return a placeholder or an empty container if no instances exist
      return const SizedBox.shrink(); // Or Text('No Workbenches') etc.
    }

    return CupertinoSlidingSegmentedControl<String>(
      groupValue: activeId,
      children: segments,
      onValueChanged: (val) {
        if (val != null) {
          ref.read(workbenchInstancesProvider.notifier)
             .setActiveInstance(val);
        }
      },
    );
  }
}
