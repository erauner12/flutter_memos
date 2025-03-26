import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'new_memo_form.dart';

class NewMemoScreen extends ConsumerWidget {
  const NewMemoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create a New Memo'),
      ),
      body: const NewMemoForm(),
    );
  }
}
