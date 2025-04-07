import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/models/memo_relation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoRelation Tests', () {
    test('toApiRelation formats data correctly for API communication', () {
      // Create a test relation
      final relation = MemoRelation(
        relatedMemoId: 'test123',
        type: MemoRelation.typeComment
      );
      
      // Convert to API relation
      final apiRelation = relation.toApiRelation();
      
      // Verify structure is correct
      expect(apiRelation, isNotNull);
      expect(apiRelation.memo, isNotNull);
      expect(apiRelation.relatedMemo, isNotNull);
      expect(apiRelation.type, equals(V1MemoRelationType.COMMENT));
      
      // Verify the related memo reference is formatted correctly
      expect(apiRelation.relatedMemo?.name, equals('memos/test123'));
      
      // Verify placeholder memo reference exists
      expect(apiRelation.memo?.name, isNotNull);
    });
    
    test('handles different relation types correctly', () {
      // Test reference type
      final referenceRelation = MemoRelation(
        relatedMemoId: 'ref123',
        type: MemoRelation.typeReference
      );
      
      final refApiRelation = referenceRelation.toApiRelation();
      expect(refApiRelation.type, equals(V1MemoRelationType.REFERENCE));
      
      // Test unspecified type
      final unspecifiedRelation = MemoRelation(
        relatedMemoId: 'unsp123',
        type: MemoRelation.typeUnspecified
      );
      
      final unspApiRelation = unspecifiedRelation.toApiRelation();
      expect(unspApiRelation.type, equals(V1MemoRelationType.TYPE_UNSPECIFIED));
    });
  });
}
