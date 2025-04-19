import 'package:flutter_memos/api/lib/api.dart' as memos_api; // For Memos Authentication interface
import 'package:flutter_memos/blinko_api/lib/api.dart'
    as blinko_api; // For Blinko Authentication interface
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart'
    as vikunja; // For Vikunja Authentication interface

/// Defines a contract for providing authentication details for API services.
abstract class AuthStrategy {
  /// Returns the necessary authentication headers for an HTTP request.
  Map<String, String> getAuthHeaders();

  /// Returns the underlying token or key, if applicable and simple.
  /// Used for fallback or simpler configuration scenarios.
  String? getSimpleToken();

  /// Optionally handles token refresh logic.
  Future<void> refreshIfNeeded() async {}

  /// Creates an Authentication object suitable for the Memos API client.
  memos_api.Authentication createMemosAuth();

  /// Creates an Authentication object suitable for the Todoist API client.
  todoist.Authentication createTodoistAuth();

  /// Creates an Authentication object suitable for the Blinko API client.
  blinko_api.Authentication createBlinkoAuth();

  /// Creates an Authentication object suitable for the Vikunja API client.
  vikunja.Authentication createVikunjaAuth();
}

// --- Concrete Implementations ---

/// An AuthStrategy using a Bearer token.
class BearerTokenAuthStrategy implements AuthStrategy {
  final String _token;

  BearerTokenAuthStrategy(this._token);

  @override
  Map<String, String> getAuthHeaders() {
    return {'Authorization': 'Bearer $_token'};
  }

  @override
  String? getSimpleToken() => _token;

  @override
  memos_api.Authentication createMemosAuth() {
    // Memos uses Bearer token directly in its HttpBearerAuth
    return memos_api.HttpBearerAuth()..accessToken = _token;
  }

  @override
  todoist.Authentication createTodoistAuth() {
    // Todoist also uses Bearer token directly in its HttpBearerAuth
    return todoist.HttpBearerAuth()..accessToken = _token;
  }

  @override
  blinko_api.Authentication createBlinkoAuth() {
    // Blinko uses Bearer token directly in its HttpBearerAuth
    return blinko_api.HttpBearerAuth()..accessToken = _token;
  }

  @override
  vikunja.Authentication createVikunjaAuth() {
    // Vikunja also uses Bearer token authentication
    return vikunja.HttpBearerAuth()..accessToken = _token;
  }

  // Add concrete implementation for refreshIfNeeded
  @override
  Future<void> refreshIfNeeded() async {
    // No-op for simple bearer token
  }
}

/// An AuthStrategy using a custom header, like Memos' X-Use-Access-Token.
/// Note: Memos API client generator actually expects Bearer token,
/// so this might be less useful unless the generator is customized or
/// headers are manually added. For now, we assume Memos uses Bearer.
/// If a different header is needed, a custom Authentication wrapper is required.
class ApiKeyAuthStrategy implements AuthStrategy {
  final String _apiKey;
  final String _headerName;

  ApiKeyAuthStrategy(this._apiKey, {String headerName = 'X-Use-Access-Token'})
      : _headerName = headerName;

  @override
  Map<String, String> getAuthHeaders() {
    return {_headerName: _apiKey};
  }

  @override
  String? getSimpleToken() => _apiKey;

  @override
  memos_api.Authentication createMemosAuth() {
    // Memos generated client uses HttpBearerAuth. If API Key header is needed,
    // we need a custom wrapper or manual header injection.
    // Assuming Bearer for now based on MemosApiService implementation.
    // If Memos *truly* needs X-Use-Access-Token, this needs adjustment.
    // Let's return a Bearer token auth for compatibility with the current Memos client.
    // Consider adding proper logging instead of print if this warning is important.
    // print("Warning: ApiKeyAuthStrategy used for Memos, but client expects Bearer. Using token as Bearer.");
    return memos_api.HttpBearerAuth()..accessToken = _apiKey;
    // If a custom header is strictly required:
    // return MemosAuthWrapper(this); // Requires MemosAuthWrapper implementation
  }

  @override
  todoist.Authentication createTodoistAuth() {
    // Todoist uses Bearer tokens. This strategy is likely not applicable.
    // Throwing an error or returning a default might be better.
    // Consider adding proper logging instead of print if this warning is important.
    // print("Warning: ApiKeyAuthStrategy used for Todoist, which expects Bearer. Using key as Bearer.");
    return todoist.HttpBearerAuth()..accessToken = _apiKey;
    // If a custom header is strictly required:
    // return TodoistAuthWrapper(this); // Requires TodoistAuthWrapper implementation
  }

  @override
  blinko_api.Authentication createBlinkoAuth() {
    // Blinko generated client uses HttpBearerAuth.
    // Assuming Bearer for now based on BlinkoApiService implementation.
    // Consider adding proper logging instead of print if this warning is important.
    // print("Warning: ApiKeyAuthStrategy used for Blinko, but client expects Bearer. Using key as Bearer.");
    return blinko_api.HttpBearerAuth()..accessToken = _apiKey;
    // If a custom header is strictly required:
    // return BlinkoAuthWrapper(this); // Requires BlinkoAuthWrapper implementation
  }

  @override
  vikunja.Authentication createVikunjaAuth() {
    // For Vikunja, we'll use bearer auth by default even with API key strategy
    // Consider adding proper logging if this warning is important
    // print("Warning: ApiKeyAuthStrategy used for Vikunja, which expects Bearer. Using key as Bearer.");
    return vikunja.HttpBearerAuth()..accessToken = _apiKey;
    // If a custom header is needed:
    // return VikunjaAuthWrapper(this);
  }

  // Add concrete implementation for refreshIfNeeded
  @override
  Future<void> refreshIfNeeded() async {
    // No-op for simple API key
  }
}

// --- Custom Authentication Wrappers (If needed for non-standard headers) ---
// These wrappers would be necessary if the generated API clients don't
// directly support the required authentication method (e.g., custom headers
// instead of Bearer tokens) and manual header injection isn't feasible.

/// Wraps an AuthStrategy for the Memos API client's Authentication interface.
class MemosAuthWrapper implements memos_api.Authentication {
  final AuthStrategy _strategy;

  MemosAuthWrapper(this._strategy);

  @override
  Future<void> applyToParams(
    List<memos_api.QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    await _strategy.refreshIfNeeded();
    headerParams.addAll(_strategy.getAuthHeaders());
  }
}

/// Wraps an AuthStrategy for the Todoist API client's Authentication interface.
class TodoistAuthWrapper implements todoist.Authentication {
  final AuthStrategy _strategy;

  TodoistAuthWrapper(this._strategy);

  @override
  Future<void> applyToParams(
    List<todoist.QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    await _strategy.refreshIfNeeded();
    headerParams.addAll(_strategy.getAuthHeaders());
  }
}

/// Wraps an AuthStrategy for the Blinko API client's Authentication interface.
class BlinkoAuthWrapper implements blinko_api.Authentication {
  final AuthStrategy _strategy;

  BlinkoAuthWrapper(this._strategy);

  @override
  Future<void> applyToParams(
    List<blinko_api.QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    await _strategy.refreshIfNeeded();
    headerParams.addAll(_strategy.getAuthHeaders());
  }
}

/// Wraps an AuthStrategy for the Vikunja API client's Authentication interface.
class VikunjaAuthWrapper implements vikunja.Authentication {
  final AuthStrategy _strategy;

  VikunjaAuthWrapper(this._strategy);

  @override
  Future<void> applyToParams(
    List<vikunja.QueryParam> queryParams,
    Map<String, String> headerParams,
  ) async {
    await _strategy.refreshIfNeeded();
    headerParams.addAll(_strategy.getAuthHeaders());
  }
}
