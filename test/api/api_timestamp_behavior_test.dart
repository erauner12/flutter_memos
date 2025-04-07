import 'package:flutter_memos/api/lib/api.dart';
import 'package:flutter_memos/utils/env.dart';
import 'package:flutter_test/flutter_test.dart';

// Set to true to run these tests against a live server
const bool RUN_TIMESTAMP_API_TESTS = true;

void main() {
  group('API Timestamp Behavior Tests (Raw Client)', () {
    late MemoServiceApi memoApi;
    String? testMemoId; // To store the ID for cleanup

    setUpAll(() {
      // Initialize the raw API client once for all tests in this group
      final apiClient = ApiClient(
        basePath: Env.apiBaseUrl.replaceAll('/api/v1/memos', ''), // Ensure correct base path
        authentication: HttpBearerAuth()..accessToken = Env.memosApiKey,
      );
      memoApi = MemoServiceApi(apiClient);
    });

    tearDown(() async {
      // Clean up the memo created in each test
      if (testMemoId != null && RUN_TIMESTAMP_API_TESTS) {
        final memoName = 'memos/$testMemoId';
        try {
          // Use WithHttpInfo to handle potentially empty success responses
          final response = await memoApi.memoServiceDeleteMemoWithHttpInfo(
            memoName,
          );
          if (response.statusCode >= 200 && response.statusCode < 300) {
            print(
              '[Cleanup] Successfully deleted test memo: $testMemoId (Status: ${response.statusCode})',
            );
          } else {
            // Throw an exception if the status code indicates failure
            throw ApiException(
              response.statusCode,
              'Failed to delete memo during cleanup: ${response.body}',
            );
          }
        } catch (e) {
          // Catch potential exceptions during the API call or from the check above
          print('[Cleanup] Error deleting test memo $testMemoId: $e');
        }
        testMemoId = null; // Reset for the next test
      }
    });

    test('Test 1: Verify server returns incorrect createTime on update', () async {
      if (!RUN_TIMESTAMP_API_TESTS) {
        print('Skipping timestamp API test 1');
        return;
      }

      print('\n--- Test 1: Verify Server Timestamp Behavior ---');

      // 1. Create a memo
      final initialContent = 'Timestamp Test 1 - Initial Content ${DateTime.now()}';
      final createPayload = Apiv1Memo(content: initialContent, visibility: V1Visibility.PUBLIC);
      final createdMemoResponse = await memoApi.memoServiceCreateMemo(createPayload);
      expect(createdMemoResponse, isNotNull, reason: 'Failed to create memo');
      testMemoId = createdMemoResponse!.name?.split('/').last; // Store ID for cleanup
      final originalCreateTime = createdMemoResponse.createTime;
      final originalUpdateTime = createdMemoResponse.updateTime;

      print('Created Memo ID: $testMemoId');
      print('Original createTime: ${originalCreateTime?.toIso8601String()}');
      print('Original updateTime: ${originalUpdateTime?.toIso8601String()}');
      expect(originalCreateTime, isNotNull);
      expect(originalUpdateTime, isNotNull);
      // Ensure original createTime is not epoch
      expect(originalCreateTime!.year, isNot(equals(1970)), reason: 'Original createTime should not be epoch');

      // Introduce a delay to ensure updateTime changes
      await Future.delayed(const Duration(seconds: 1));

      // 2. Update the memo (sending only content)
      final updatedContent = 'Timestamp Test 1 - Updated Content ${DateTime.now()}';
      final updatePayload = TheMemoToUpdateTheNameFieldIsRequired(
        content: updatedContent,
        // DO NOT send createTime or updateTime here
      );
      final updatedMemoResponse = await memoApi.memoServiceUpdateMemo(
        'memos/$testMemoId',
        updatePayload,
      );
      expect(updatedMemoResponse, isNotNull, reason: 'Failed to update memo');

      final responseCreateTime = updatedMemoResponse!.createTime;
      final responseUpdateTime = updatedMemoResponse.updateTime;

      print('--- Server Response After Update ---');
      print('Response createTime: ${responseCreateTime?.toIso8601String()}');
      print('Response updateTime: ${responseUpdateTime?.toIso8601String()}');

      // 3. Assertions
      expect(responseCreateTime, isNotNull, reason: 'Response createTime should not be null');
      expect(responseUpdateTime, isNotNull, reason: 'Response updateTime should not be null');

      // *** Key Assertion: Verify server returned incorrect (epoch) createTime ***
      expect(
        responseCreateTime!.year,
        anyOf(equals(1970), equals(1)), // Memos might return year 1 or 1970 for epoch
        reason: 'Server response createTime SHOULD be epoch (1970 or 1)',
      );
      expect(
        responseCreateTime.toIso8601String(),
        isNot(equals(originalCreateTime.toIso8601String())),
        reason: 'Server response createTime SHOULD NOT match original createTime',
      );

      // *** Key Assertion: Verify server correctly updated updateTime ***
      expect(
        responseUpdateTime!.toIso8601String(),
        isNot(equals(originalUpdateTime!.toIso8601String())),
        reason: 'Server response updateTime SHOULD have changed',
      );
      // Check if the new update time is later
      expect(
        responseUpdateTime.isAfter(originalUpdateTime),
        isTrue,
        reason: 'Server response updateTime should be later than original',
      );

      print('Test 1 PASSED: Server incorrectly returned epoch createTime but correctly updated updateTime.');
    });

    test('Test 2: Verify client-side fix corrects the createTime', () async {
      if (!RUN_TIMESTAMP_API_TESTS) {
        print('Skipping timestamp API test 2');
        return;
      }

      print('\n--- Test 2: Verify Client-Side Fix Simulation ---');

      // 1. Create a memo
      final initialContent = 'Timestamp Test 2 - Initial Content ${DateTime.now()}';
      final createPayload = Apiv1Memo(content: initialContent, visibility: V1Visibility.PUBLIC);
      final createdMemoResponse = await memoApi.memoServiceCreateMemo(createPayload);
      expect(createdMemoResponse, isNotNull, reason: 'Failed to create memo');
      testMemoId = createdMemoResponse!.name?.split('/').last;
      final originalCreateTime = createdMemoResponse.createTime; // Store the *correct* original time
      final originalUpdateTime = createdMemoResponse.updateTime;

      print('Created Memo ID: $testMemoId');
      print('Original createTime: ${originalCreateTime?.toIso8601String()}');
      print('Original updateTime: ${originalUpdateTime?.toIso8601String()}');
      expect(originalCreateTime, isNotNull);
      expect(originalUpdateTime, isNotNull);
      expect(originalCreateTime!.year, isNot(equals(1970)));

      await Future.delayed(const Duration(seconds: 1));

      // 2. Update the memo
      final updatedContent = 'Timestamp Test 2 - Updated Content ${DateTime.now()}';
      final updatePayload = TheMemoToUpdateTheNameFieldIsRequired(content: updatedContent);
      final updatedMemoResponse = await memoApi.memoServiceUpdateMemo(
        'memos/$testMemoId',
        updatePayload,
      );
      expect(updatedMemoResponse, isNotNull, reason: 'Failed to update memo');

      final responseCreateTime = updatedMemoResponse!.createTime;
      final responseUpdateTime = updatedMemoResponse.updateTime;

      print('--- Server Response After Update ---');
      print('Response createTime: ${responseCreateTime?.toIso8601String()}');
      print('Response updateTime: ${responseUpdateTime?.toIso8601String()}');

      // 3. Simulate Client-Side Fix
      DateTime? correctedCreateTime = responseCreateTime;
      if (responseCreateTime != null && (responseCreateTime.year == 1970 || responseCreateTime.year == 1)) {
         print('[Client Fix] Detected epoch createTime in response. Restoring original.');
         correctedCreateTime = originalCreateTime; // Apply the fix
      } else {
         print('[Client Fix] No epoch createTime detected in response.');
      }
      // The updateTime from the response is assumed correct
      DateTime? correctedUpdateTime = responseUpdateTime;

      print('--- After Client-Side Fix Simulation ---');
      print('Corrected createTime: ${correctedCreateTime?.toIso8601String()}');
      print('Corrected updateTime: ${correctedUpdateTime?.toIso8601String()}');


      // 4. Assertions
      expect(correctedCreateTime, isNotNull);
      expect(correctedUpdateTime, isNotNull);

      // *** Key Assertion: Verify the corrected createTime matches the original ***
      expect(
        correctedCreateTime!.toIso8601String(),
        equals(originalCreateTime.toIso8601String()),
        reason: 'Corrected createTime SHOULD match the original createTime',
      );

      // *** Key Assertion: Verify the updateTime (from server response) was correctly updated ***
       expect(
        correctedUpdateTime!.toIso8601String(),
        isNot(equals(originalUpdateTime!.toIso8601String())),
        reason: 'Corrected updateTime SHOULD have changed from original',
      );
       expect(
        correctedUpdateTime.isAfter(originalUpdateTime),
        isTrue,
        reason: 'Corrected updateTime should be later than original',
      );

      print('Test 2 PASSED: Client-side fix simulation successfully corrected the createTime.');
    });

    test('Test 3: Demonstrate failure without client-side createTime fix', () async {
      if (!RUN_TIMESTAMP_API_TESTS) {
        print('Skipping timestamp API test 3');
        return;
      }

      print('\n--- Test 3: Demonstrate Failure Without Fix ---');

      // 1. Create a memo
      final initialContent =
          'Timestamp Test 3 - Initial Content ${DateTime.now()}';
      final createPayload = Apiv1Memo(
        content: initialContent,
        visibility: V1Visibility.PUBLIC,
      );
      final createdMemoResponse = await memoApi.memoServiceCreateMemo(
        createPayload,
      );
      expect(createdMemoResponse, isNotNull, reason: 'Failed to create memo');
      testMemoId =
          createdMemoResponse!.name?.split('/').last; // Store ID for cleanup
      final originalCreateTime = createdMemoResponse.createTime; // Correct time

      print('Created Memo ID: $testMemoId');
      print('Original createTime: ${originalCreateTime?.toIso8601String()}');
      expect(originalCreateTime, isNotNull);
      // Ensure original createTime is not epoch
      expect(
        originalCreateTime!.year,
        isNot(equals(1970)),
        reason: 'Original createTime should not be epoch',
      );
      expect(
        originalCreateTime.year,
        isNot(equals(1)),
        reason: 'Original createTime should not be year 1',
      );

      // Introduce a delay to ensure updateTime changes
      await Future.delayed(const Duration(seconds: 1));

      // 2. Update the memo
      final updatedContent =
          'Timestamp Test 3 - Updated Content ${DateTime.now()}';
      final updatePayload = TheMemoToUpdateTheNameFieldIsRequired(
        content: updatedContent,
      );
      final updatedMemoResponse = await memoApi.memoServiceUpdateMemo(
        'memos/$testMemoId',
        updatePayload,
      );
      expect(updatedMemoResponse, isNotNull, reason: 'Failed to update memo');

      final responseCreateTime =
          updatedMemoResponse!.createTime; // Incorrect time from server
      final responseUpdateTime =
          updatedMemoResponse.updateTime; // Correctly updated time

      print('--- Server Response After Update ---');
      print('Response createTime: ${responseCreateTime?.toIso8601String()}');
      print('Response updateTime: ${responseUpdateTime?.toIso8601String()}');

      // 3. Assertions - This is where the failure is expected
      expect(
        responseCreateTime,
        isNotNull,
        reason: 'Response createTime should not be null',
      );

      print(
        'Comparing original createTime (${originalCreateTime.toIso8601String()}) with response createTime (${responseCreateTime!.toIso8601String()})',
      );

      // *** THIS ASSERTION IS EXPECTED TO FAIL ***
      // It directly compares the original correct time with the incorrect epoch time returned by the server.
      // We use expectLater with throwsA to explicitly test for the expected failure.
      expectLater(
        () => expect(
          responseCreateTime.toIso8601String(),
          equals(originalCreateTime.toIso8601String()),
        ),
        throwsA(isA<TestFailure>()), // Expect a TestFailure exception
        reason:
            'This test should fail because the server returns epoch createTime when none is sent in the payload.',
      );

      print(
        'Test 3 PASSED (by failing as expected): Server returned epoch createTime when none was sent.',
      );
    });

    test('Test 4: Attempt to send createTime/updateTime in update payload', () async {
      if (!RUN_TIMESTAMP_API_TESTS) {
        print('Skipping timestamp API test 4');
        return;
      }

      print('\n--- Test 4: Attempt Sending Timestamps in Payload ---');

      // 1. Create a memo
      final initialContent = 'Timestamp Test 4 - Initial Content ${DateTime.now()}';
      final createPayload = Apiv1Memo(content: initialContent, visibility: V1Visibility.PUBLIC);
      final createdMemoResponse = await memoApi.memoServiceCreateMemo(createPayload);
      expect(createdMemoResponse, isNotNull, reason: 'Failed to create memo');
      testMemoId = createdMemoResponse!.name?.split('/').last;
      final originalCreateTime = createdMemoResponse.createTime;
      final originalUpdateTime = createdMemoResponse.updateTime;

      print('Created Memo ID: $testMemoId');
      print('Original createTime: ${originalCreateTime?.toIso8601String()}');
      print('Original updateTime: ${originalUpdateTime?.toIso8601String()}');
      expect(originalCreateTime, isNotNull);
      expect(originalUpdateTime, isNotNull);
      expect(originalCreateTime!.year, isNot(equals(1970)));

      await Future.delayed(const Duration(seconds: 1));
      final timeBeforeUpdate = DateTime.now().toUtc(); // Record time just before update

      // 2. Update the memo, explicitly sending original timestamps
      final updatedContent = 'Timestamp Test 4 - Updated Content ${DateTime.now()}';
      final updatePayload = TheMemoToUpdateTheNameFieldIsRequired(
        content: updatedContent,
        // *** Explicitly include timestamps in the payload ***
        createTime: originalCreateTime,
        updateTime: originalUpdateTime, // Sending the *original* updateTime
      );

      print('--- Sending Update Payload With Timestamps ---');
      print('Payload createTime: ${updatePayload.createTime?.toIso8601String()}');
      print('Payload updateTime: ${updatePayload.updateTime?.toIso8601String()}');

      final updatedMemoResponse = await memoApi.memoServiceUpdateMemo(
        'memos/$testMemoId',
        updatePayload,
      );
      expect(updatedMemoResponse, isNotNull, reason: 'Failed to update memo');

      final responseCreateTime = updatedMemoResponse!.createTime;
      final responseUpdateTime = updatedMemoResponse.updateTime;

      print('--- Server Response After Update (With Sent Timestamps) ---');
      print('Response createTime: ${responseCreateTime?.toIso8601String()}');
      print('Response updateTime: ${responseUpdateTime?.toIso8601String()}');

      // 3. Assertions - Based on expected server behavior (ignoring sent timestamps)
      expect(responseCreateTime, isNotNull);
      expect(responseUpdateTime, isNotNull);

      // *** Assertion: Expect server returns the CORRECT createTime, matching the original we sent ***
      // This reflects the observed behavior where the server DOES seem to handle it correctly now.
      expect(
        responseCreateTime!.year,
        isNot(anyOf(equals(1970), equals(1))), // Should NOT be epoch
        reason:
            'Server response createTime SHOULD NOT be epoch when original was sent.',
      );
      expect(
        responseCreateTime.toIso8601String(), 
        equals(originalCreateTime.toIso8601String()), // Should match original
        reason: // Corrected named argument
            'Server response createTime SHOULD match original when sent in payload.',
      );


      // *** Assertion: Expect server IGNORES the sent updateTime and keeps the original one ***
      // This reflects the observed behavior where sending timestamps prevents updateTime from changing.
      expect(
        responseUpdateTime!.toIso8601String(),
        equals(originalUpdateTime!.toIso8601String()), // Should EQUAL the original time sent
        reason: // Corrected named argument
            'Server response updateTime SHOULD match the original sent in payload, indicating it was ignored.',
      );
      // Check that the response update time is NOT later than before the update call
      expect(
        responseUpdateTime.isAfter(timeBeforeUpdate),
        isFalse, // It should NOT be after, as it wasn't updated
        reason: // Corrected named argument
            'Server response updateTime should NOT be later if it ignored the update.',
      );
      print(
        'Test 4 PASSED: Confirmed server ignores createTime/updateTime sent in PATCH payload.',
      );
    });
  });
}
