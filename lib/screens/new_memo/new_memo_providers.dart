import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/memo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Provider for creating a new memo
final createMemoProvider = Provider<Future<Memo> Function(Memo)>((ref) {
  return (Memo memo) async {
    final apiService = ref.read(apiServiceProvider);
    final createdMemo = await apiService.createMemo(memo);
    ref.invalidate(memosNotifierProvider); // Refresh the memos list
    return createdMemo;
  };
});
