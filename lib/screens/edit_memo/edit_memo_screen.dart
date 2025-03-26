import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edit_memo_form.dart';
import 'edit_memo_providers.dart';

class EditMemoScreen extends ConsumerWidget {
  final String memoId;

  const EditMemoScreen({
    super.key,
    required this.memoId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoAsync = ref.watch(editMemoProvider(memoId));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Memo'),
      ),
      body: memoAsync.when(
        data: (memo) => EditMemoForm(memo: memo, memoId: memoId),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  }
}
