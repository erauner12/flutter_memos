import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/models/focus_instance.dart'; // Correct import
import 'package:flutter_memos/providers/focus_instances_provider.dart'; // Correct import
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shows a CupertinoActionSheet to pick a Focus Instance.
/// Returns the selected FocusInstance or null if cancelled.
Future<FocusInstance?> showFocusInstancePicker(
  BuildContext context,
  WidgetRef ref, {
  String title = 'Select Focus Board', // Updated text
  String message = 'Choose which focus board to use.', // Updated text
}) async {
  final instancesState = ref.read(focusInstancesProvider); // Correct provider
  final instances = instancesState.instances;

  if (instances.isEmpty) {
    // Handle case with no instances (e.g., show an alert)
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('No Focus Boards Found'), // Updated text
        content: const Text('Please create a focus board first.'), // Updated text
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

  // Sort instances: default first, then by name or creation date
  final sortedInstances = [...instances]..sort((a, b) {
    if (a.isSystemDefault) return -1;
    if (b.isSystemDefault) return 1;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  FocusInstance? selectedInstance;

  await showCupertinoModalPopup<void>(
    context: context,
    builder: (BuildContext popupContext) => CupertinoActionSheet(
      title: Text(title),
      message: Text(message),
      actions: sortedInstances.map<Widget>((instance) {
        return CupertinoActionSheetAction(
          child: Text(instance.name),
          onPressed: () {
            selectedInstance = instance;
            Navigator.pop(popupContext); // Close the action sheet
          },
        );
      }).toList(),
      cancelButton: CupertinoActionSheetAction(
        isDefaultAction: true,
        child: const Text('Cancel'),
        onPressed: () {
          Navigator.pop(popupContext); // Close the action sheet
        },
      ),
    ),
  );

  return selectedInstance;
}
