import 'package:flutter_test/flutter_test.dart';

// Helper function to extract the deep link parsing logic for testing
Map<String, String?>? parseDeepLink(Uri? uri) {
  if (uri == null) {
    return null;
  }

  // Check scheme - ensure we're comparing correctly
  final validScheme = 'flutter-memos';
  if (uri.scheme.toLowerCase() != validScheme.toLowerCase()) {
    return null;
  }

  final host = uri.host; // Use host instead of pathSegments[0]
  final pathSegments = uri.pathSegments;

  // Variables to extract
  String? memoId;
  String? commentIdToHighlight;

  if (host == 'memo' && pathSegments.isNotEmpty) {
    // For memo links: flutter-memos://memo/memoId
    memoId = pathSegments[0];
  } else if (host == 'comment' && pathSegments.length >= 2) {
    // For comment links: flutter-memos://comment/memoId/commentId
    memoId = pathSegments[0];
    commentIdToHighlight = pathSegments[1];
  } else {
    return null;
  }

  return {
    'memoId': memoId,
    'commentIdToHighlight': commentIdToHighlight,
  };
}

void main() {
  group('Deep Link Parser Tests', () {
    test('should parse memo link correctly', () {
      final uri = Uri.parse('flutter-memos://memo/abc123');
      final result = parseDeepLink(uri);
      
      expect(result, isNotNull);
      expect(result!['memoId'], equals('abc123'));
      expect(result['commentIdToHighlight'], isNull);
    });

    test('should parse comment link correctly', () {
      final uri = Uri.parse('flutter-memos://comment/memo456/comment789');
      final result = parseDeepLink(uri);
      
      expect(result, isNotNull);
      expect(result!['memoId'], equals('memo456'));
      expect(result['commentIdToHighlight'], equals('comment789'));
    });

    test('should return null for null URI', () {
      final result = parseDeepLink(null);
      expect(result, isNull);
    });

    test('should return null for invalid scheme', () {
      final uri = Uri.parse('http://example.com/memo/123');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });

    test('should return null for empty path segments', () {
      final uri = Uri.parse('flutter-memos://');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });

    test('should return null for invalid memo path (no ID)', () {
      final uri = Uri.parse('flutter-memos://memo');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });

    test('should return null for invalid comment path (missing memo ID)', () {
      final uri = Uri.parse('flutter-memos://comment');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });

    test('should return null for invalid comment path (missing comment ID)', () {
      final uri = Uri.parse('flutter-memos://comment/memo123');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });

    test('should return null for invalid type', () {
      final uri = Uri.parse('flutter-memos://unknown/123');
      final result = parseDeepLink(uri);
      expect(result, isNull);
    });
  });
}
