import 'package:flutter_memos/services/url_launcher_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Generate mock for the UrlLauncherService
@GenerateNiceMocks([MockSpec<UrlLauncherService>()])
import 'url_launcher_service_test.mocks.dart';

void main() {
  late ProviderContainer container;
  late MockUrlLauncherService mockUrlLauncherService;

  setUp(() {
    mockUrlLauncherService = MockUrlLauncherService();
    container = ProviderContainer(
      overrides: [
        urlLauncherServiceProvider.overrideWithValue(mockUrlLauncherService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('UrlLauncherService Tests', () {
    test('launch returns true when URL can be launched', () async {
      // Arrange
      const testUrl = 'https://example.com';
      when(mockUrlLauncherService.launch(testUrl)).thenAnswer((_) async => true);

      // Act
      final result = await container.read(urlLauncherServiceProvider).launch(testUrl);

      // Assert
      expect(result, isTrue);
      verify(mockUrlLauncherService.launch(testUrl)).called(1);
    });

    test('launch returns false when URL cannot be launched', () async {
      // Arrange
      const testUrl = 'invalid:url';
      when(mockUrlLauncherService.launch(testUrl)).thenAnswer((_) async => false);

      // Act
      final result = await container.read(urlLauncherServiceProvider).launch(testUrl);

      // Assert
      expect(result, isFalse);
      verify(mockUrlLauncherService.launch(testUrl)).called(1);
    });
  });
}
