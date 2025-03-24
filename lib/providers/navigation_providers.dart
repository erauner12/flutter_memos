import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current screen in the app
///
/// OPTIMIZATION: Added name for better debugging
final currentScreenProvider = StateProvider<String>(
  (ref) => '/memos',
  name: 'currentScreen',
);

/// Provider that tracks navigation history
///
/// OPTIMIZATION: Added name and max history size
final navigationHistoryProvider = StateProvider<List<String>>((ref) {
  // Start with the home screen
  return ['/memos'];
}, name: 'navigationHistory');

/// OPTIMIZATION: Provider for navigation state data
/// This allows passing data between screens without parameters
final navigationDataProvider = StateProvider<Map<String, dynamic>>((ref) {
  return {};
}, name: 'navigationData');

/// Provider for adding a screen to navigation history
///
/// OPTIMIZATION: Added return value, better logging, and data handling
final addToNavigationHistoryProvider =
    Provider<bool Function(String, {Map<String, dynamic>? data})>((ref) {
      return (String route, {Map<String, dynamic>? data}) {
        if (kDebugMode) {
          print('[Navigation] Navigating to: $route');
        }
    
    final currentHistory = ref.read(navigationHistoryProvider);
    
    // Don't add duplicate consecutive routes
    if (currentHistory.isNotEmpty && currentHistory.last == route) {
          if (kDebugMode) {
            print('[Navigation] Already at $route, not adding to history');
          }

          // Update data if provided
          if (data != null && data.isNotEmpty) {
            ref
                .read(navigationDataProvider.notifier)
                .update((state) => {...state, ...data});
          }

          return false;
        }

        // OPTIMIZATION: Limit history size to avoid memory issues
        final maxHistorySize = 20;
        List<String> newHistory = [...currentHistory, route];
        if (newHistory.length > maxHistorySize) {
          newHistory = newHistory.sublist(newHistory.length - maxHistorySize);
        }

        // Update history and current screen
        ref.read(navigationHistoryProvider.notifier).state = newHistory;
    ref.read(currentScreenProvider.notifier).state = route;
    
        // Update navigation data if provided
        if (data != null && data.isNotEmpty) {
          if (kDebugMode) {
            print('[Navigation] Updating navigation data: $data');
          }
          ref.read(navigationDataProvider.notifier).state = data;
        }

        return true;
  };
}, name: 'addToNavigationHistory');

/// Provider for popping from navigation history
///
/// OPTIMIZATION: Added better error handling, logging, and data management
final popNavigationProvider =
    Provider<String? Function({Map<String, dynamic>? data})>((ref) {
      return ({Map<String, dynamic>? data}) {
    final currentHistory = ref.read(navigationHistoryProvider);
    
    // Can't pop if we're at the root or have no history
    if (currentHistory.length <= 1) {
          if (kDebugMode) {
            print('[Navigation] Cannot pop: at root or empty history');
          }
      return null;
    }
    
        // Get the route we're returning to
        final previousRoute = currentHistory[currentHistory.length - 2];

        if (kDebugMode) {
          print('[Navigation] Popping back to: $previousRoute');
        }
    
    // Remove the current route and set the previous one as current
    final newHistory = currentHistory.sublist(0, currentHistory.length - 1);
    ref.read(navigationHistoryProvider.notifier).state = newHistory;
        ref.read(currentScreenProvider.notifier).state = previousRoute;

        // Update navigation data if provided
        if (data != null && data.isNotEmpty) {
          if (kDebugMode) {
            print('[Navigation] Updating navigation data on pop: $data');
          }
          ref.read(navigationDataProvider.notifier).state = data;
        }

        return previousRoute;
  };
}, name: 'popNavigation');

/// Provider for clearing navigation history back to the root
///
/// OPTIMIZATION: Added better logging and return value
final clearNavigationHistoryProvider =
    Provider<bool Function({Map<String, dynamic>? data})>((ref) {
      return ({Map<String, dynamic>? data}) {
        if (kDebugMode) {
          print('[Navigation] Clearing navigation history');
        }
    
    ref.read(navigationHistoryProvider.notifier).state = ['/memos'];
    ref.read(currentScreenProvider.notifier).state = '/memos';
    
        // Update navigation data if provided
        if (data != null) {
          ref.read(navigationDataProvider.notifier).state = data;
        } else {
          // Clear navigation data when clearing history
          ref.read(navigationDataProvider.notifier).state = {};
        }

        return true;
      };
    }, name: 'clearNavigationHistory');

/// OPTIMIZATION: New provider for handling deep linking
final handleDeepLinkProvider =
    Provider<bool Function(String uri, {Map<String, dynamic>? data})>((ref) {
      return (String uri, {Map<String, dynamic>? data}) {
        if (kDebugMode) {
          print('[Navigation] Handling deep link: $uri');
        }

        // Simple URI parsing
        Uri? parsedUri;
        try {
          parsedUri = Uri.parse(uri);
        } catch (e) {
          if (kDebugMode) {
            print('[Navigation] Invalid deep link URI: $e');
          }
          return false;
        }

        // Handle different paths
        final path = parsedUri.path;

        // Merge any query parameters with provided data
        final queryParams = parsedUri.queryParameters;
        final mergedData = {...queryParams, ...(data ?? {})};

        // Navigate to the appropriate screen
        return ref.read(addToNavigationHistoryProvider)(path, data: mergedData);
      };
    }, name: 'handleDeepLink');
