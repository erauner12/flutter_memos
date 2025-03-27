import 'package:flutter_memos/providers/ui_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Comment Keyboard Navigation Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('selectedCommentIndexProvider starts at -1', () {
      final index = container.read(selectedCommentIndexProvider);
      expect(index, equals(-1));
    });

    test('selectedCommentIndexProvider can be updated', () {
      // Start at -1
      final initialIndex = container.read(selectedCommentIndexProvider);
      expect(initialIndex, equals(-1));

      // Set to 2
      container.read(selectedCommentIndexProvider.notifier).state = 2;
      final updatedIndex = container.read(selectedCommentIndexProvider);
      expect(updatedIndex, equals(2));
    });

    test('selectedMemoIndexProvider starts at -1', () {
      final index = container.read(selectedMemoIndexProvider);
      expect(index, equals(-1));
    });

    test('selectedMemoIndexProvider can be updated', () {
      // Start at -1
      final initialIndex = container.read(selectedMemoIndexProvider);
      expect(initialIndex, equals(-1));

      // Set to 3
      container.read(selectedMemoIndexProvider.notifier).state = 3;
      final updatedIndex = container.read(selectedMemoIndexProvider);
      expect(updatedIndex, equals(3));
    });
  });
}
