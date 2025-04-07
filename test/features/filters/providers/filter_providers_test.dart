import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Filter Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('filter providers should have correct default values', () {
      expect(container.read(timeFilterProvider), equals('all'));
      expect(container.read(statusFilterProvider), equals('untagged'));
    });
    
    test('combinedFilterProvider should correctly combine filters', () {
      // Case 1: Both filters are default
      expect(container.read(combinedFilterProvider), isNotEmpty);
      
      // Case 2: Change time filter
      container.read(timeFilterProvider.notifier).state = 'today';
      // Check for date pattern rather than literal "today" string
      expect(
        container.read(combinedFilterProvider),
        contains('create_time >='),
      );
      expect(
        container.read(combinedFilterProvider),
        contains('create_time <='),
      );
      
      // Case 3: Change status filter
      container.read(statusFilterProvider.notifier).state = 'tagged';
      expect(
        container.read(combinedFilterProvider),
        contains('create_time >='),
      );
      expect(
        container.read(combinedFilterProvider),
        contains('content.contains("#")'),
      );
      
      // Case 4: Set both filters to 'all'
      container.read(timeFilterProvider.notifier).state = 'all';
      container.read(statusFilterProvider.notifier).state = 'all';
      expect(container.read(combinedFilterProvider), isEmpty);
    });
    
    test('saving and loading filter preferences', () async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      
      // Set filter values
      container.read(timeFilterProvider.notifier).state = 'this_week';
      container.read(statusFilterProvider.notifier).state = 'tagged';
      
      // Save preferences
      await container.read(filterPreferencesProvider)(
        container.read(timeFilterProvider),
        container.read(statusFilterProvider),
      );
      
      // Reset filters to default
      container.read(timeFilterProvider.notifier).state = 'all';
      container.read(statusFilterProvider.notifier).state = 'untagged';
      
      // Load preferences
      await container.read(loadFilterPreferencesProvider.future);
      
      // Verify preferences were loaded
      expect(container.read(timeFilterProvider), equals('this_week'));
      expect(container.read(statusFilterProvider), equals('tagged'));
    });
  });
}
