import 'package:flutter_memos/providers/filter_providers.dart';
import 'package:flutter_memos/utils/filter_presets.dart'; // Import FilterPresets
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Filter Providers Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Initialize SharedPreferences mock values before creating the container
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('quickFilterPresetProvider should have correct default value', () {
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
    });

    test('rawCelFilterProvider should have correct default value', () {
      expect(container.read(rawCelFilterProvider), isEmpty);
    });

    test('combinedFilterProvider should use preset filter by default', () {
      // Default preset is 'inbox', which uses untaggedFilter
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.untaggedFilter()),
      );
    });

    test('combinedFilterProvider should use preset filter when changed', () {
      // Change preset to 'today'
      container.read(quickFilterPresetProvider.notifier).state = 'today';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.todayFilter()),
      );

      // Change preset to 'all'
      container.read(quickFilterPresetProvider.notifier).state = 'all';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.allFilter()), // Should be empty string
      );
      expect(container.read(combinedFilterProvider), isEmpty);

      // Change preset to 'tagged'
      container.read(quickFilterPresetProvider.notifier).state = 'tagged';
      expect(
        container.read(combinedFilterProvider),
        equals(FilterPresets.taggedFilter()),
      );
    });

    test(
      'combinedFilterProvider should use rawCelFilter when preset is custom',
      () {
        const customFilter =
            'content.contains("custom") && visibility == "PUBLIC"';

        // Set preset to 'custom' and provide a raw filter
        container.read(quickFilterPresetProvider.notifier).state = 'custom';
        container.read(rawCelFilterProvider.notifier).state = customFilter;

        // Verify combinedFilterProvider returns the raw filter
        expect(container.read(combinedFilterProvider), equals(customFilter));

        // Change raw filter while preset is still 'custom'
        const anotherCustomFilter = 'tag in ["project"]';
        container.read(rawCelFilterProvider.notifier).state =
            anotherCustomFilter;
      expect(
        container.read(combinedFilterProvider),
          equals(anotherCustomFilter),
      );
      },
    );

    test(
      'combinedFilterProvider should switch back to preset when preset changes from custom',
      () {
        const customFilter = 'content.contains("custom")';

        // Start with custom filter
        container.read(quickFilterPresetProvider.notifier).state = 'custom';
        container.read(rawCelFilterProvider.notifier).state = customFilter;
        expect(container.read(combinedFilterProvider), equals(customFilter));

        // Change preset back to 'inbox'
        container.read(quickFilterPresetProvider.notifier).state = 'inbox';
      expect(
        container.read(combinedFilterProvider),
          equals(FilterPresets.untaggedFilter()),
      );

        // Ensure raw filter wasn't cleared automatically (MemosScreen UI does this)
        expect(container.read(rawCelFilterProvider), equals(customFilter));
    });

    test(
      'saving and loading filter preferences uses quickFilterPresetProvider',
      () async {
        // Mock SharedPreferences (already done in setUp)

        // Set filter preset
        container.read(quickFilterPresetProvider.notifier).state = 'tagged';

        // Save preferences
        await container.read(filterPreferencesProvider)(
          container.read(quickFilterPresetProvider),
        );

        // Reset filter to default
        container.read(quickFilterPresetProvider.notifier).state = 'inbox';

        // Create a new container to simulate app restart
        final newContainer = ProviderContainer();
        // Ensure SharedPreferences are mocked for the new container too
        // SharedPreferences.setMockInitialValues are global, so this might not be strictly needed, but good practice.
        // If tests were parallel, this would be crucial.

        // Load preferences in the new container
        await newContainer.read(loadFilterPreferencesProvider.future);

        // Verify preferences were loaded into the new container
        expect(newContainer.read(quickFilterPresetProvider), equals('tagged'));

        newContainer.dispose(); // Clean up the new container
      },
    );

    test('saving preferences ignores "custom" preset key', () async {
      // Set filter preset to 'custom'
      container.read(quickFilterPresetProvider.notifier).state = 'custom';
      container.read(rawCelFilterProvider.notifier).state = 'some_filter';

      // Save preferences
      await container.read(filterPreferencesProvider)(
        container.read(quickFilterPresetProvider), // This is 'custom'
      );

      // Reset filter to default
      container.read(quickFilterPresetProvider.notifier).state = 'inbox';

      // Load preferences
      await container.read(loadFilterPreferencesProvider.future);

      // Verify preferences loaded the default ('inbox'), not 'custom'
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
    });

    test('loading preferences ignores invalid saved key', () async {
      // Manually set an invalid value in SharedPreferences mock
      SharedPreferences.setMockInitialValues({
        'last_quick_preset': 'invalid_key',
      });

      // Create container AFTER setting mock values
      final testContainer = ProviderContainer();

      // Load preferences
      await testContainer.read(loadFilterPreferencesProvider.future);

      // Verify that the provider defaulted to 'inbox' because the saved key was invalid
      expect(testContainer.read(quickFilterPresetProvider), equals('inbox'));

      testContainer.dispose();
    });

    test('filterKeyProvider derives state from quickFilterPresetProvider', () {
      // Default state
      expect(container.read(quickFilterPresetProvider), equals('inbox'));
      expect(container.read(filterKeyProvider), equals('inbox'));

      // Change preset
      container.read(quickFilterPresetProvider.notifier).state = 'all';
      expect(container.read(filterKeyProvider), equals('all'));

      container.read(quickFilterPresetProvider.notifier).state = 'tagged';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      container.read(quickFilterPresetProvider.notifier).state = 'today';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      container.read(quickFilterPresetProvider.notifier).state = 'custom';
      expect(
        container.read(filterKeyProvider),
        equals('all'),
      ); // Based on current mapping

      // Test a non-mapped preset key (if one existed)
      // container.read(quickFilterPresetProvider.notifier).state = 'some_tag';
      // expect(container.read(filterKeyProvider), equals('some_tag'));
    });

  });
}
