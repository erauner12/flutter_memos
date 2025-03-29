import 'package:flutter_memos/models/memo.dart';
import 'package:flutter_memos/services/api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Set to true to run this test against a live server
const bool RUN_REAL_API_TIMESTAMP_TEST = true;

/// This integration test uses the REAL ApiService and connects to the
/// actual Memos server defined in the environment.
///
/// Purpose: To verify the end-to-end behavior of timestamps during an update,
/// specifically checking if the client-side correction applied within
/// `ApiService.updateMemo` results in the memo having the correct original
/// `createTime` even when it's subsequently fetched via `ApiService.listMemos`.
/// It also verifies that the `updateTime` is correctly reflected and used for sorting.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Real API Update Timestamp End-to-End Test', () {
    late ApiService apiService;
    String? testMemoId;
    String? originalCreateTimeStr; // Store the original create time string

    setUpAll(() {
      // Initialize the real ApiService
      apiService = ApiService();
      // Ensure it's configured (uses Env variables by default if baseUrl/token are empty)
      apiService.configureService(baseUrl: '', authToken: '');
      // Allow time for initialization if needed
      return Future.delayed(const Duration(milliseconds: 500));
    });

    tearDown(() async {
      // Clean up the memo created in the test
      if (testMemoId != null && RUN_REAL_API_TIMESTAMP_TEST) {
        print('[Real API Cleanup] Deleting test memo: $testMemoId');
        try {
          await apiService.deleteMemo(testMemoId!);
          print('[Real API Cleanup] Successfully deleted test memo.');
        } catch (e) {
          print('[Real API Cleanup] Error deleting test memo $testMemoId: $e');
        }
        testMemoId = null;
        originalCreateTimeStr = null;
      }
    });

    test('Update memo and verify timestamps/sorting in subsequent list fetch', () async {
      if (!RUN_REAL_API_TIMESTAMP_TEST) {
        print('Skipping real API timestamp test');
        return;
      }

      print('\n--- Real API Test: Update and Verify List ---');

      // 1. Create a memo
      final initialContent = 'Real API Timestamp Test - Initial ${DateTime.now()}';
      final createMemoData = Memo(id: 'temp', content: initialContent, visibility: 'PUBLIC');
      final createdMemo = await apiService.createMemo(createMemoData);
      testMemoId = createdMemo.id;
      originalCreateTimeStr = createdMemo.createTime; // Capture the correct original createTime string

      print('Created Memo ID: $testMemoId');
      print('Original createTime String: $originalCreateTimeStr');
      expect(testMemoId, isNotEmpty);
      expect(originalCreateTimeStr, isNotNull);
      expect(originalCreateTimeStr, isNotEmpty);
      // Basic check that it's not epoch
      expect(originalCreateTimeStr!.startsWith('1970-01-01'), isFalse);
      expect(originalCreateTimeStr!.startsWith('0001-01-01'), isFalse);


      // Wait a second to ensure updateTime changes
      await Future.delayed(const Duration(seconds: 1));

      // 2. Update the memo using ApiService.updateMemo
      // This call internally applies the client-side createTime fix to its *direct* response.
      final updatedContent = 'Real API Timestamp Test - Updated ${DateTime.now()}';
      // We need the full memo object to pass to updateMemo, including the original createTime
      final memoToUpdate = createdMemo.copyWith(content: updatedContent);
      print('Updating memo $testMemoId...');
      final updatedMemoDirectResponse = await apiService.updateMemo(testMemoId!, memoToUpdate);
      final expectedNewUpdateTimeStr = updatedMemoDirectResponse.updateTime;

      print('--- Direct Response from updateMemo (After Client Fix) ---');
      print('Response createTime: ${updatedMemoDirectResponse.createTime}');
      print('Response updateTime: ${updatedMemoDirectResponse.updateTime}');

      // Verify the direct response has the corrected createTime and new updateTime
      expect(updatedMemoDirectResponse.createTime, equals(originalCreateTimeStr), reason: 'Direct update response should have corrected createTime');
      expect(expectedNewUpdateTimeStr, isNotNull);
      expect(expectedNewUpdateTimeStr, isNot(equals(createdMemo.updateTime)), reason: 'Direct update response should have new updateTime');


      // 3. List memos to see how the updated memo appears in the list context
      print('Fetching memo list (sorted by updateTime) after update...');
      final memoList = await apiService.listMemos(
        parent: 'users/1', // Assuming user 1 for simplicity
        sort: 'updateTime',
        direction: 'DESC',
      );

      expect(memoList, isNotEmpty, reason: 'Memo list should not be empty');
      print('Fetched list with ${memoList.length} memos.');

      // 4. Find the updated memo in the list
      final memoFromList = memoList.firstWhere(
            (m) => m.id == testMemoId,
        orElse: () => throw StateError('Updated memo $testMemoId not found in the fetched list!'),
      );
      print('--- Memo Found in List (${memoFromList.id}) ---');
      print('List createTime: ${memoFromList.createTime}');
      print('List updateTime: ${memoFromList.updateTime}');

      // 5. Assertions
      // Verify Sorting: The updated memo should be the first one due to sorting
      expect(
        memoList.first.id,
        equals(testMemoId),
        reason: 'Updated memo should be the first in the list when sorted by updateTime',
      );
      print('Verified: Updated memo is first in the list.');

      // *** Key Assertion: Verify createTime in the LIST matches the ORIGINAL ***
      // This checks if _convertApiMemoToAppMemo handled the list response correctly,
      // OR if the server happened to send the correct createTime in the list response this time.
      expect(
        memoFromList.createTime,
        equals(originalCreateTimeStr),
        reason: 'createTime of the memo fetched in the LIST should match the original createTime',
      );
      print('Verified: createTime in list matches original.');

      // Verify updateTime in the LIST matches the one from the update response
      expect(
        memoFromList.updateTime,
        equals(expectedNewUpdateTimeStr),
        reason: 'updateTime of the memo fetched in the LIST should match the updateTime from the update response',
      );
      print('Verified: updateTime in list matches expected new updateTime.');

      print('--- Real API Test PASSED ---');
    });
  });
}
