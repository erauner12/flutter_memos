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

  group('UrlLauncherService Tests (using mock)', () {
    test('launch returns true when mock is stubbed to succeed', () async {
      // Arrange
      const testUrl = 'https://example.com';
      // Stub the mock to return true
      when(mockUrlLauncherService.launch(testUrl)).thenAnswer((_) async => true);

      // Act: Read the provider (which returns the mock) and call launch
      final result = await container.read(urlLauncherServiceProvider).launch(testUrl);

      // Assert
      expect(result, isTrue);
      // Verify the mock's launch method was called
      verify(mockUrlLauncherService.launch(testUrl)).called(1);
    });

    test('launch returns false when mock is stubbed to fail', () async {
      // Arrange
      const testUrl = 'invalid:url';
      // Stub the mock to return false
      when(mockUrlLauncherService.launch(testUrl)).thenAnswer((_) async => false);

      // Act
      final result = await container.read(urlLauncherServiceProvider).launch(testUrl);

      // Assert
      expect(result, isFalse);
      verify(mockUrlLauncherService.launch(testUrl)).called(1);
    });
  });
}
