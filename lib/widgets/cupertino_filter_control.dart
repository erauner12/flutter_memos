import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A Cupertino-styled filter control using sliding segmented control
class CupertinoFilterControl<T extends Object> extends ConsumerWidget {
  final Map<T, Widget> segments;
  final T groupValue;
  final ValueChanged<T> onValueChanged;
  final String label;
  
  const CupertinoFilterControl({
    super.key,
    required this.segments,
    required this.groupValue,
    required this.onValueChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: CupertinoSlidingSegmentedControl<T>(
            groupValue: groupValue,
            onValueChanged: (T? value) {
              // Only call the callback if we receive a non-null value
              if (value != null) {
                onValueChanged(value);
              }
            },
            children: segments,
            thumbColor: CupertinoColors.systemBackground.resolveFrom(context),
            backgroundColor: CupertinoColors.systemFill.resolveFrom(context),
          ),
        ),
      ],
    );
  }
}
