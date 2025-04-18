import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/workbench_instance.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a CupertinoActionSheet to allow the user to select a Workbench instance.
///
/// Returns the selected [WorkbenchInstance] or `null` if the user cancels
/// or if there are no instances available.
/// If only one instance exists, it returns that instance directly without showing a picker.
Future<WorkbenchInstance?> showWorkbenchInstancePicker(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Select Workbench',
}) async {
  final instancesState = ref.read(workbenchInstancesProvider);
  final availableInstances = instancesState.instances;
  final activeInstanceId = instancesState.activeInstanceId;

  if (availableInstances.isEmpty) {
    // Handle case where no instances exist (should ideally not happen due to default)
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: const Text('No workbench instances found.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
    return null;
  }

  if (availableInstances.length == 1) {
    // If only one instance, return it directly
    return availableInstances.first;
  }

  // Show picker if multiple instances exist
  final selectedInstance = await showCupertinoModalPopup<WorkbenchInstance>(
    context: context,
    builder: (BuildContext popupContext) {
      return CupertinoActionSheet(
        title: Text(title),
        actions: availableInstances.map((instance) {
          final bool isCurrentlyActive = instance.id == activeInstanceId;
          return CupertinoActionSheetAction(
            child: Text(
              '${instance.name}${isCurrentlyActive ? " (Active)" : ""}',
            ),
            onPressed: () {
              Navigator.pop(popupContext, instance); // Return the selected instance
            },
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(popupContext, null); // Return null on cancel
          },
        ),
      );
    },
  );

  return selectedInstance; // Return the selected instance or null
}
