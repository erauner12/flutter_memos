import 'package:flutter/foundation.dart';
import 'package:flutter_memos/models/comment.dart';
// Remove import for Memo model as it's replaced by NoteItem
// import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/models/note_item.dart'; // Import NoteItem
import 'package:flutter_memos/providers/api_providers.dart';
import 'package:flutter_memos/providers/error_handler_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Remove the old definition for memoDetailCacheProvider
// /// OPTIMIZATION: Cache for memo details to avoid redundant API calls
// final memoDetailCacheProvider = StateProvider<Map<String, Memo>>((ref) {
//   return {};
// }, name: 'memoDetailCache');

/// OPTIMIZATION: Cache for memo comments to avoid redundant API calls
final memoCommentsCacheProvider = StateProvider<Map<String, List<Comment>>>((ref) {
  return {};
}, name: 'memoCommentsCache');

/// Provider for memo details with integrated caching
///
/// OPTIMIZATION: This provider checks the cache first before making an API call
final memoDetailProvider = FutureProvider.family<NoteItem, String>((
  ref,
  id,
) async {
  // Changed return type to NoteItem
  // Check the cache first
  final cache = ref.read(
    noteDetailCacheProvider,
  ); // Use renamed cache provider with correct type
  if (cache.containsKey(id)) {
    if (kDebugMode) {
      print('[memoDetailProvider] Cache hit for note $id');
    }
    // Return cached data directly, cache type is now NoteItem
    return cache[id]!;
  }

  if (kDebugMode) {
    // Updated log message
    print('[memoDetailProvider] Cache miss for note $id, fetching from API');
  }

  try {
    // Fetch from API using BaseApiService
    final apiService = ref.read(apiServiceProvider);
    final note = await apiService.getNote(id); // Use getNote, returns NoteItem

    if (kDebugMode) {
      print(
        '[memoDetailProvider] Successfully fetched note $id with update time: ${note.updateTime}',
      );
    }

    // Update the cache after successful API fetch
    ref.read(noteDetailCacheProvider.notifier).update((state) => { // Use renamed cache provider
      ...state,
            id: note, // Assign NoteItem directly, no cast needed
    });

    return note; // Return NoteItem, no cast needed
  } catch (e, stackTrace) {
    // Record the error
    final errorHandler = ref.read(errorHandlerProvider);
    final errorType = ref.read(categorizeErrorProvider)(e);

    errorHandler(
      'Failed to load note: ${e.toString()}', // Updated message
      type: errorType,
      stackTrace: stackTrace,
      source: 'memoDetailProvider',
    );

    rethrow;
  }
}, name: 'memoDetail'); // Keep name or update if desired

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
    // Fetch from API using BaseApiService
    final apiService = ref.read(apiServiceProvider);
    final comments = await apiService.listNoteComments(memoId); // Use listNoteComments

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
      creatorId: comment.creatorId ?? '1', // Assuming creatorId is available or default
      createTime: DateTime.now().millisecondsSinceEpoch,
      // Add other necessary fields if Comment model requires them
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
      // Make the API call using BaseApiService
      final apiService = ref.read(apiServiceProvider);
      final newComment = await apiService.createNoteComment(memoId, comment); // Use createNoteComment

      // Update the cache with the real comment
      ref.read(memoCommentsCacheProvider.notifier).update((state) {
        final currentComments = state[memoId] ?? [];
        // Ensure the mapping produces List<Comment>
        final updatedList = currentComments.map((c) =>
          c.id == tempId ? newComment : c
        ).toList(); // Explicitly cast if needed, though toList() should infer correctly
        // Return the updated map state correctly
        return {
          ...state, // Spread existing state
          memoId: updatedList, // Update the list for the specific memoId
        }; // Close the map literal correctly
      }); // End of update callback

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

    ref.read(noteDetailCacheProvider.notifier).state = {}; // Use renamed cache provider
    ref.read(memoCommentsCacheProvider.notifier).state = {};
  };
}, name: 'clearMemoCaches');

// Renamed provider using NoteItem
final noteDetailCacheProvider = StateProvider<Map<String, NoteItem>>((ref) {
  // Ensure type is NoteItem
  return {};
}, name: 'noteDetailCache');
