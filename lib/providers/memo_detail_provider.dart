import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/error_handler_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OPTIMIZATION: Cache for memo details to avoid redundant API calls
final memoDetailCacheProvider = StateProvider<Map<String, Memo>>((ref) {
  return {};
}, name: 'memoDetailCache');

/// OPTIMIZATION: Cache for memo comments to avoid redundant API calls
final memoCommentsCacheProvider = StateProvider<Map<String, List<Comment>>>((ref) {
  return {};
}, name: 'memoCommentsCache');

/// Provider for memo details with integrated caching
///
/// OPTIMIZATION: This provider checks the cache first before making an API call
final memoDetailProvider = FutureProvider.family<Memo, String>((ref, id) async {
  // Check the cache first
  final cache = ref.read(memoDetailCacheProvider);
  if (cache.containsKey(id)) {
    if (kDebugMode) {
      print('[memoDetailProvider] Cache hit for memo $id');
    }
    return cache[id]!;
  }
  
  if (kDebugMode) {
    print('[memoDetailProvider] Cache miss for memo $id, fetching from API');
  }
  
  try {
    // Fetch from API
    final apiService = ref.read(apiServiceProvider);
    final memo = await apiService.getMemo(id);
    
    // Update the cache
    ref.read(memoDetailCacheProvider.notifier).update((state) => {
      ...state,
      id: memo,
    });
    
    return memo;
  } catch (e, stackTrace) {
    // Record the error
    final errorHandler = ref.read(errorHandlerProvider);
    final errorType = ref.read(categorizeErrorProvider)(e);
    
    errorHandler(
      'Failed to load memo: ${e.toString()}',
      type: errorType,
      stackTrace: stackTrace,
      source: 'memoDetailProvider',
    );
    
    rethrow;
  }
}, name: 'memoDetail');

/// Provider for memo comments with integrated caching
///
/// OPTIMIZATION: This provider checks the cache first before making an API call
final memoCommentsProvider = FutureProvider.family<List<Comment>, String>((ref, memoId) async {
  // Check the cache first
  final cache = ref.read(memoCommentsCacheProvider);
  if (cache.containsKey(memoId)) {
    if (kDebugMode) {
      print('[memoCommentsProvider] Cache hit for memo comments $memoId');
    }
    return cache[memoId]!;
  }
  
  if (kDebugMode) {
    print('[memoCommentsProvider] Cache miss for memo comments $memoId, fetching from API');
  }
  
  try {
    // Fetch from API
    final apiService = ref.read(apiServiceProvider);
    final comments = await apiService.listMemoComments(memoId);
    
    // Update the cache
    ref.read(memoCommentsCacheProvider.notifier).update((state) => {
      ...state,
      memoId: comments,
    });
    
    return comments;
  } catch (e, stackTrace) {
    // Record the error
    final errorHandler = ref.read(errorHandlerProvider);
    final errorType = ref.read(categorizeErrorProvider)(e);
    
    errorHandler(
      'Failed to load comments: ${e.toString()}',
      type: errorType,
      stackTrace: stackTrace,
      source: 'memoCommentsProvider',
    );
    
    rethrow;
  }
}, name: 'memoComments');

/// Provider for adding a comment with optimistic updates
///
/// OPTIMIZATION: This provider updates the cache immediately before the API call
final addCommentProvider = Provider.family<Future<Comment> Function(Comment), String>((ref, memoId) {
  return (Comment comment) async {
    if (kDebugMode) {
      print('[addCommentProvider] Adding comment to memo $memoId');
    }
    
    // Generate a temporary ID for optimistic updates
    final tempId = 'temp-${DateTime.now().millisecondsSinceEpoch}';
    final optimisticComment = Comment(
      id: tempId,
      content: comment.content,
      creatorId: comment.creatorId ?? '1',
      createTime: DateTime.now().millisecondsSinceEpoch,
    );
    
    // Add to cache immediately (optimistic update)
    ref.read(memoCommentsCacheProvider.notifier).update((state) {
      final currentComments = state[memoId] ?? [];
      return {
        ...state,
        memoId: [...currentComments, optimisticComment],
      };
    });
    
    try {
      // Make the API call
      final apiService = ref.read(apiServiceProvider);
      final newComment = await apiService.createMemoComment(memoId, comment);
      
      // Update the cache with the real comment
      ref.read(memoCommentsCacheProvider.notifier).update((state) {
        final currentComments = state[memoId] ?? [];
        return {
          ...state,
          memoId: currentComments.map((c) =>
            c.id == tempId ? newComment : c
          ).toList(),
        };
      });
      
      // Invalidate the provider to refresh the UI
      ref.invalidate(memoCommentsProvider(memoId));
      
      return newComment;
    } catch (e, stackTrace) {
      // Remove the optimistic comment on failure
      ref.read(memoCommentsCacheProvider.notifier).update((state) {
        final currentComments = state[memoId] ?? [];
        return {
          ...state,
          memoId: currentComments.where((c) => c.id != tempId).toList(),
        };
      });
      
      // Record the error
      final errorHandler = ref.read(errorHandlerProvider);
      final errorType = ref.read(categorizeErrorProvider)(e);
      
      errorHandler(
        'Failed to add comment: ${e.toString()}',
        type: errorType,
        stackTrace: stackTrace,
        source: 'addCommentProvider',
      );
      
      rethrow;
    }
  };
}, name: 'addComment');

/// OPTIMIZATION: Provider that clears memo caches
final clearMemoCachesProvider = Provider<void Function()>((ref) {
  return () {
    if (kDebugMode) {
      print('[clearMemoCachesProvider] Clearing all memo caches');
    }
    
    ref.read(memoDetailCacheProvider.notifier).state = {};
    ref.read(memoCommentsCacheProvider.notifier).state = {};
  };
}, name: 'clearMemoCaches');
