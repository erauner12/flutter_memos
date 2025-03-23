import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the current screen in the app
final currentScreenProvider = StateProvider<String>((ref) => '/memos');

/// Provider that tracks navigation history
final navigationHistoryProvider = StateProvider<List<String>>((ref) => ['/memos']);

/// Provider for adding a screen to navigation history
final addToNavigationHistoryProvider = Provider<void Function(String)>((ref) {
  return (String route) {
    final currentHistory = ref.read(navigationHistoryProvider);
    
    // Don't add duplicate consecutive routes
    if (currentHistory.isNotEmpty && currentHistory.last == route) {
      return;
    }
    
    ref.read(navigationHistoryProvider.notifier).state = [...currentHistory, route];
    ref.read(currentScreenProvider.notifier).state = route;
  };
});

/// Provider for popping from navigation history
final popNavigationProvider = Provider<String? Function()>((ref) {
  return () {
    final currentHistory = ref.read(navigationHistoryProvider);
    
    // Can't pop if we're at the root or have no history
    if (currentHistory.length <= 1) {
      return null;
    }
    
    // Remove the current route and set the previous one as current
    final newHistory = currentHistory.sublist(0, currentHistory.length - 1);
    ref.read(navigationHistoryProvider.notifier).state = newHistory;
    ref.read(currentScreenProvider.notifier).state = newHistory.last;
    
    return newHistory.last;
  };
});

/// Provider for clearing navigation history back to the root
final clearNavigationHistoryProvider = Provider<void Function()>((ref) {
  return () {
    ref.read(navigationHistoryProvider.notifier).state = ['/memos'];
    ref.read(currentScreenProvider.notifier).state = '/memos';
  };
});
