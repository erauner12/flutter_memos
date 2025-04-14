# todoist_blinko_api.api.AnalyticsApi

## Load the API package
```dart
import 'package:todoist_blinko_api/api.dart';
```

All URIs are relative to */api*

Method | HTTP request | Description
------------- | ------------- | -------------
[**analyticsDailyNoteCount**](AnalyticsApi.md#analyticsdailynotecount) | **POST** /v1/analytics/daily-note-count | Query daily note count
[**analyticsMonthlyStats**](AnalyticsApi.md#analyticsmonthlystats) | **POST** /v1/analytics/monthly-stats | Query monthly statistics


# **analyticsDailyNoteCount**
> List<AnalyticsDailyNoteCount200ResponseInner> analyticsDailyNoteCount()

Query daily note count

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AnalyticsApi();

try {
    final result = api_instance.analyticsDailyNoteCount();
    print(result);
} catch (e) {
    print('Exception when calling AnalyticsApi->analyticsDailyNoteCount: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**List<AnalyticsDailyNoteCount200ResponseInner>**](AnalyticsDailyNoteCount200ResponseInner.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **analyticsMonthlyStats**
> AnalyticsMonthlyStats200Response analyticsMonthlyStats(analyticsMonthlyStatsRequest)

Query monthly statistics

### Example
```dart
import 'package:todoist_blinko_api/api.dart';
// TODO Configure HTTP Bearer authorization: bearer
// Case 1. Use String Token
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken('YOUR_ACCESS_TOKEN');
// Case 2. Use Function which generate token.
// String yourTokenGeneratorFunction() { ... }
//defaultApiClient.getAuthentication<HttpBearerAuth>('bearer').setAccessToken(yourTokenGeneratorFunction);

final api_instance = AnalyticsApi();
final analyticsMonthlyStatsRequest = AnalyticsMonthlyStatsRequest(); // AnalyticsMonthlyStatsRequest | 

try {
    final result = api_instance.analyticsMonthlyStats(analyticsMonthlyStatsRequest);
    print(result);
} catch (e) {
    print('Exception when calling AnalyticsApi->analyticsMonthlyStats: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **analyticsMonthlyStatsRequest** | [**AnalyticsMonthlyStatsRequest**](AnalyticsMonthlyStatsRequest.md)|  | 

### Return type

[**AnalyticsMonthlyStats200Response**](AnalyticsMonthlyStats200Response.md)

### Authorization

[bearer](../README.md#bearer)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

