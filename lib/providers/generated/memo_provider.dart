import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// Generate the .g.dart file that will contain the actual implementation
part 'memo_provider.g.dart';

/// A code-generated provider for fetching a single memo by ID
///
/// This replaces the manually defined FutureProvider.family
@riverpod
Future<Memo> memo(MemoRef ref, String id) async {
  // This is equivalent to:
  // final memoProvider = FutureProvider.family<Memo, String>((ref, id) async {
  //   return ref.read(apiServiceProvider).getMemo(id);
  // });
  
  final apiService = ref.watch(apiServiceProvider);
  return apiService.getMemo(id);
}

/// A provider that fetches all memos with optional filter
@riverpod
Future<List<Memo>> memos(MemosRef ref, {String? filter}) async {
  final apiService = ref.watch(apiServiceProvider);
  
  // If filter is not provided, fetch all memos
  if (filter == null || filter.isEmpty) {
    return apiService.listMemos();
  }
  
  // Otherwise, use the filter
  return apiService.listMemos(filter: filter);
}