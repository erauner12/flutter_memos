import 'package:flutter_memos/models/server_config.dart';
import 'package:flutter_memos/providers/server_config_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ServerConfigNotifier', () {
    late ProviderContainer container;
    late ServerConfigNotifier notifier;

    setUp(() {
      // Clear any existing mock preferences
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      notifier = container.read(serverConfigProvider.notifier);
    });

    test('Loads default config when prefs are empty', () async {
      await notifier.loadFromPreferences();
      final config = container.read(serverConfigProvider);
      expect(config.serverUrl, '');
      expect(config.authToken, '');
    });

    test('Saves and loads config properly', () async {
      // 1. Save config
      final testConfig = const ServerConfig(
        serverUrl: 'https://example.com',
        authToken: 'abc123',
      );
      final saveSuccess = await notifier.saveToPreferences(testConfig);
      expect(saveSuccess, isTrue);

      // 2. Create a new container to simulate app restart
      final newContainer = ProviderContainer();
      final newNotifier = newContainer.read(serverConfigProvider.notifier);

      // 3. Load from prefs
      await newNotifier.loadFromPreferences();
      final loadedConfig = newContainer.read(serverConfigProvider);

      expect(loadedConfig.serverUrl, 'https://example.com');
      expect(loadedConfig.authToken, 'abc123');
    });
  });
}
