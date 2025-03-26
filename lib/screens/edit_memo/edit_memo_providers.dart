import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for the current memo being edited
final editMemoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
});

// Provider for saving memo changes
final saveMemoProvider = Provider.family<Future<void> Function(Memo), String>((
  ref,
  id,
) {
  return (Memo updatedMemo) async {
    final apiService = ref.read(apiServiceProvider);
    await apiService.updateMemo(id, updatedMemo);
    ref.invalidate(memosProvider); // Refresh the memos list
  };
});
