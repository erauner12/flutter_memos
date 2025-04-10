import 'package:flutter_memos/providers/service_providers.dart';
import 'package:flutter_memos/providers/settings_provider.dart';
import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import generated mocks
import 'persistent_string_notifier_test.mocks.dart';

// Define keys used in tests
const testPrefKey = 'test_api_key';
const defaultValue = '';
const secureValue = 'value_from_secure_storage';
const prefsValue = 'value_from_old_prefs';
const cloudValue = 'value_from_cloudkit';

// Annotations to generate mocks
@GenerateMocks([CloudKitService, FlutterSecureStorage])
void main() {
  // --- Test Setup ---
  late MockCloudKitService mockCloudKitService;
  late MockFlutterSecureStorage mockSecureStorage;
  late ProviderContainer container;

  // Helper Provider for testing
  final testNotifierProvider =
      StateNotifierProvider<PersistentStringNotifier, String>((ref) {
    return PersistentStringNotifier(ref, defaultValue, testPrefKey);
  });

  setUp(() {
    // Create mocks
    mockCloudKitService = MockCloudKitService();
    mockSecureStorage = MockFlutterSecureStorage();

    // Create ProviderContainer with overrides
    container = ProviderContainer(
      overrides: [
        cloudKitServiceProvider.overrideWithValue(mockCloudKitService),
        // Override FlutterSecureStorage - Requires a way to inject the mock.
        // Since it's used via `const FlutterSecureStorage()`, direct override
        // isn't straightforward via Provider. We'll mock its methods directly.
        // This assumes the test environment allows mocking instance methods
        // even if the instance is created with `const`. If not, refactoring
        // PersistentStringNotifier to take FlutterSecureStorage via constructor
        // would be necessary for clean injection.
        // For now, we rely on Mockito's ability to mock the instance methods.
      ],
    );

    // Default mock behavior
    // Secure Storage
    when(mockSecureStorage.read(key: anyNamed('key'))).thenAnswer((_) async => null);
    when(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value'))).thenAnswer((_) async {
      return;
    });
    when(mockSecureStorage.delete(key: anyNamed('key'))).thenAnswer((_) async {
      return;
    });

    // CloudKit Settings
    when(mockCloudKitService.getSetting(any)).thenAnswer((_) async => null);
    when(
      mockCloudKitService.saveSetting(any, any),
    ).thenAnswer((_) async => true);

    // Clear SharedPreferences mock values
    SharedPreferences.setMockInitialValues({});

    // **Inject mockSecureStorage into the notifier instance**
    final notifierInstance = container.read(testNotifierProvider.notifier);
    notifierInstance.debugSecureStorage =
        mockSecureStorage; // Using setter instead of method
  });

  tearDown(() {
    container.dispose();
  });

  // --- Test Cases ---

  group('init / _loadValue', () {
    test('Initial state is default when all sources are empty', () async {
      // Arrange: Mocks default to null/empty, Prefs empty
      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init(); // Trigger loading
      await container.pump();

      // Assert
      expect(notifier.state, defaultValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Verify no migration attempts
      verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(testPrefKey), isNull);
    });

    test('Loads from Secure Storage when available, CloudKit empty', () async {
      // Arrange
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => secureValue);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => null); // CloudKit empty

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert
      expect(notifier.state, secureValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Should attempt to upload the local value to CloudKit
      verify(mockCloudKitService.saveSetting(testPrefKey, secureValue)).called(1);
      verifyNever(
        mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')),
      );
    });

    test('Loads from Secure Storage, CloudKit matches, no upload/write', () async {
      // Arrange
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => secureValue);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => secureValue); // CloudKit matches

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert
      expect(notifier.state, secureValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // No upload or write needed as they match
      verifyNever(mockCloudKitService.saveSetting(any, any));
      verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });

    test('Loads from Secure Storage, CloudKit differs, updates state and storage', () async {
      // Arrange
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => secureValue);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => cloudValue); // CloudKit has different value

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State updated to CloudKit value
      expect(notifier.state, cloudValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Secure storage should be updated with CloudKit value
      verify(mockSecureStorage.write(key: testPrefKey, value: cloudValue)).called(1);
      verifyNever(mockCloudKitService.saveSetting(any, any)); // No upload needed
    });

    test('Migrates from SharedPreferences when Secure Storage empty, CloudKit empty', () async {
      // Arrange: Secure Storage empty, Prefs has value, CloudKit empty
      SharedPreferences.setMockInitialValues({testPrefKey: prefsValue});
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => null);

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State loaded from prefs
      expect(notifier.state, prefsValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);

      // Assert Migration actions:
      // 1. Upload to CloudKit
      verify(mockCloudKitService.saveSetting(testPrefKey, prefsValue)).called(1);
      // 2. Write to Secure Storage (happens during migration cleanup)
      verify(mockSecureStorage.write(key: testPrefKey, value: prefsValue)).called(1);
      // 3. Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(testPrefKey), isNull);
    });

    test(
      'Migrates from SharedPreferences, CloudKit matches prefs value',
      () async {
      // Arrange: Secure Storage empty, Prefs has value, CloudKit matches prefs
      SharedPreferences.setMockInitialValues({testPrefKey: prefsValue});
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => prefsValue);

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State loaded from prefs initially, remains prefsValue
      expect(notifier.state, prefsValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);

      // Assert Migration actions:
      // 1. No upload to CloudKit (already matches)
      verifyNever(mockCloudKitService.saveSetting(any, any));
      // 2. Write to Secure Storage (still needed as part of migration)
      verify(mockSecureStorage.write(key: testPrefKey, value: prefsValue)).called(1);
      // 3. Remove from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(testPrefKey), isNull);
    });

    test('Migrates from SharedPreferences, CloudKit has different value', () async {
      // Arrange: Secure Storage empty, Prefs has value, CloudKit has different value
      SharedPreferences.setMockInitialValues({testPrefKey: prefsValue});
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => cloudValue);

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State loaded from prefs initially, then updated to CloudKit value
      expect(notifier.state, cloudValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);

      // Assert Migration actions:
      // 1. No upload to CloudKit (CloudKit value takes precedence)
      verifyNever(mockCloudKitService.saveSetting(any, any));
      // 2. Write CloudKit value to Secure Storage
      verify(mockSecureStorage.write(key: testPrefKey, value: cloudValue)).called(1);
      // 3. Remove from SharedPreferences (cleaned up because CloudKit provided value)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(testPrefKey), isNull);
    });

    test('Loads from CloudKit when Secure Storage and Prefs are empty', () async {
      // Arrange: Secure Storage empty, Prefs empty, CloudKit has value
      SharedPreferences.setMockInitialValues({});
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => cloudValue);

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State updated from CloudKit
      expect(notifier.state, cloudValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Secure storage should be updated with CloudKit value
      verify(mockSecureStorage.write(key: testPrefKey, value: cloudValue)).called(1);
      verifyNever(mockCloudKitService.saveSetting(any, any)); // No upload needed
    });

    test(
      'Handles CloudKit error gracefully, uses local value (Secure Storage)',
      () async {
      // Arrange
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => secureValue);
      when(mockCloudKitService.getSetting(testPrefKey)).thenThrow(Exception('Network Error'));

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State remains from Secure Storage
      expect(notifier.state, secureValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1); // Attempted
      verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
      verifyNever(mockCloudKitService.saveSetting(any, any));
    });

    test(
      'Handles CloudKit error gracefully during migration, uses local value (Prefs)',
      () async {
      // Arrange: Secure Storage empty, Prefs has value, CloudKit fails
      SharedPreferences.setMockInitialValues({testPrefKey: prefsValue});
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.getSetting(testPrefKey)).thenThrow(Exception('Network Error'));

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();

      // Assert: State remains from Prefs
      expect(notifier.state, prefsValue);
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1); // Attempted

      // Assert Migration actions (partial):
      // 1. CloudKit upload attempt fails (implicitly tested by error)
      verifyNever(mockCloudKitService.saveSetting(any, any));
      // 2. Write to Secure Storage (should still happen post-CloudKit check)
      verify(mockSecureStorage.write(key: testPrefKey, value: prefsValue)).called(1);
      // 3. Remove from SharedPreferences (should still happen post-CloudKit check)
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(testPrefKey), isNull);
    });

    test('Does not run CloudKit check multiple times', () async {
      // Arrange
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async => secureValue);
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => null);

      // Act
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init(); // First init
      await container.pump();
      await notifier.init(); // Second init (should be no-op for CloudKit)
      await container.pump();

      // Assert
      expect(notifier.state, secureValue);
      // CloudKit check should only happen once
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Secure storage read might happen again, depending on implementation, let's check at least once
      verify(
        mockSecureStorage.read(key: testPrefKey),
      ).called(greaterThan(0)); // Use greaterThan(0)
    });
  });

  group('set', () {
    test('Saves to CloudKit first, then updates state and Secure Storage on success', () async {
      // Arrange
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init(); // Initialize first
      await container.pump();
      expect(notifier.state, defaultValue); // Start with default
      const newValue = 'new_value_set';
      // Mock CloudKit success
      when(mockCloudKitService.saveSetting(testPrefKey, newValue)).thenAnswer((_) async => true);

      // Act
      final success = await notifier.set(newValue);
      await container.pump();

      // Assert
      expect(success, isTrue);
      // Verify order: CloudKit save -> state update -> Secure Storage write
      verifyInOrder([
          mockCloudKitService.saveSetting(testPrefKey, newValue),
        mockSecureStorage.write(key: testPrefKey, value: newValue),
      ]);
      expect(notifier.state, newValue);
    });

    test('Does not update state or Secure Storage if CloudKit save fails', () async {
      // Arrange
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();
      expect(notifier.state, defaultValue);
      const newValue = 'new_value_set_fail';
      // Mock CloudKit failure
      when(mockCloudKitService.saveSetting(testPrefKey, newValue)).thenAnswer((_) async => false);

      // Act
      final success = await notifier.set(newValue);
      await container.pump();

      // Assert
      expect(success, isFalse);
      verify(mockCloudKitService.saveSetting(testPrefKey, newValue)).called(1);
      // Verify state and storage were NOT updated
      expect(notifier.state, defaultValue);
      verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });

    test('Handles CloudKit exception during save gracefully', () async {
      // Arrange
      final notifier = container.read(testNotifierProvider.notifier);
      await notifier.init();
      await container.pump();
      expect(notifier.state, defaultValue);
      const newValue = 'new_value_set_exception';
      // Mock CloudKit exception
      when(mockCloudKitService.saveSetting(testPrefKey, newValue)).thenThrow(Exception('Save Error'));

      // Act
      final success = await notifier.set(newValue);
      await container.pump();

      // Assert
      expect(success, isFalse);
      verify(mockCloudKitService.saveSetting(testPrefKey, newValue)).called(1);
      // Verify state and storage were NOT updated
      expect(notifier.state, defaultValue);
      verifyNever(mockSecureStorage.write(key: anyNamed('key'), value: anyNamed('value')));
    });

    test('Waits for initialization if set is called early', () async {
      // Arrange: Don't call init explicitly yet
      final notifier = container.read(testNotifierProvider.notifier);
      const newValue = 'set_before_init';

      // Mock the init process to take some time and succeed
      when(mockSecureStorage.read(key: testPrefKey)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 50)); // Simulate delay
        return null; // Start empty
      });
      when(mockCloudKitService.getSetting(testPrefKey)).thenAnswer((_) async => null);
      when(mockCloudKitService.saveSetting(testPrefKey, newValue)).thenAnswer((_) async => true);

      // Act: Call set *before* init finishes (or even starts)
      final setResult = notifier.set(newValue); // Don't await yet

      // Allow time for init to potentially start and run
      await container.pump(const Duration(milliseconds: 10));
      // Now await the set result, which should internally await init
      final success = await setResult;
      await container.pump(); // Allow final updates

      // Assert
      expect(success, isTrue);
      // Verify init actions happened
      verify(mockSecureStorage.read(key: testPrefKey)).called(1);
      verify(mockCloudKitService.getSetting(testPrefKey)).called(1);
      // Verify set actions happened *after* init
      verifyInOrder([
        mockCloudKitService.saveSetting(testPrefKey, newValue),
        mockSecureStorage.write(key: testPrefKey, value: newValue),
      ]);
      expect(notifier.state, newValue);
    });
  });

  group('clear', () {
    test('Calls set with an empty string', () async {
      // Arrange
      final notifier = container.read(testNotifierProvider.notifier);
      // Set an initial value first
      when(mockCloudKitService.saveSetting(testPrefKey, 'initial_value')).thenAnswer((_) async => true);
      await notifier.init();
      await notifier.set('initial_value');
      await container.pump();
      expect(notifier.state, 'initial_value');

      // Mock the set('') call for clear
      when(mockCloudKitService.saveSetting(testPrefKey, '')).thenAnswer((_) async => true);

      // Act
      final success = await notifier.clear();
      await container.pump();

      // Assert
      expect(success, isTrue);
      // Verify set('') was called via CloudKit and Secure Storage
      verify(mockCloudKitService.saveSetting(testPrefKey, '')).called(1);
      verify(mockSecureStorage.write(key: testPrefKey, value: '')).called(1);
      expect(notifier.state, '');
    });
  });
}

// Helper extension for pumping futures in tests
extension PumpExtension on ProviderContainer {
  // Make the Duration parameter an optional positional parameter
  Future<void> pump([Duration duration = Duration.zero]) async {
    // Correct signature
    await Future.delayed(duration);
  }
}
