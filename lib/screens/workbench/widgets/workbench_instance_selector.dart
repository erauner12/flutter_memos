import 'package:flutter/cupertino.dart';
import 'package:flutter_memos/providers/workbench_instances_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WorkbenchInstanceSelector extends ConsumerWidget {
  const WorkbenchInstanceSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final instances = ref.watch(workbenchInstancesProvider).instances;
    final activeId  = ref.watch(workbenchInstancesProvider).activeInstanceId;

    // Map<instanceId, Widget> for CupertinoSlidingSegmentedControl
    final segments = {
      for (final i in instances)
        i.id : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(i.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
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
