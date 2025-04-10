import 'package:flutter_memos/services/cloud_kit_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for accessing the CloudKitService instance.
final cloudKitServiceProvider = Provider<CloudKitService>((ref) {
  // Initialization (like checking account status) should be done elsewhere,
  // typically at app startup, perhaps triggered by another provider (like loadServerConfigProvider).
  return CloudKitService();
}, name: 'cloudKitService');
