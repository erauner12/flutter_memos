import 'package:flutter/cupertino.dart'; // Import Cupertino
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_memo_form.dart';

class NewMemoScreen extends ConsumerWidget {
  const NewMemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use CupertinoPageScaffold and CupertinoNavigationBar
    return const CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('Create a New Memo'),
        transitionBetweenRoutes: false, // Disable default hero animation
        // Add previousPageTitle automatically if pushed from a Cupertino route
      ),
      child: SafeArea(
        // Add SafeArea
        child: NewMemoForm(),
      ),
    );
  }
}
