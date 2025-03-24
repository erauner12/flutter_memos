import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for ApiService to enable dependency injection and easier testing
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
