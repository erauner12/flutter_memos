import 'package:flutter_memos/api/lib/api.dart' as memos_api; // For Memos Authentication interface
import 'package:flutter_memos/blinko_api/lib/api.dart'
    as blinko_api; // For Blinko Authentication interface
import 'package:vikunja_flutter_api/vikunja_api/lib/api.dart'
    as vikunja; // For Vikunja Authentication interface
// Removed todoist import

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
  /// Kept in case Memos server type is used, assuming its client uses Bearer.
  memos_api.Authentication createMemosAuth();

  // Removed createTodoistAuth abstract method

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

  // Removed createTodoistAuth implementation

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
/// Note: Most generated clients expect Bearer token. This strategy primarily
/// provides the header via `getAuthHeaders` for manual injection if needed.
/// The `create...Auth` methods default to using the key as a Bearer token
/// for compatibility with generated clients.
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
    // Memos generated client likely uses HttpBearerAuth.
    // Return Bearer token auth using the API key for compatibility.
    // If Memos *truly* needs X-Use-Access-Token header via the Auth object,
    // a custom Authentication wrapper would be needed (like the removed MemosAuthWrapper).
    return memos_api.HttpBearerAuth()..accessToken = _apiKey;
  }

  // Removed createTodoistAuth implementation

  @override
  blinko_api.Authentication createBlinkoAuth() {
    // Blinko generated client uses HttpBearerAuth. Use key as Bearer token.
    return blinko_api.HttpBearerAuth()..accessToken = _apiKey;
  }

  @override
  vikunja.Authentication createVikunjaAuth() {
    // Vikunja generated client uses HttpBearerAuth. Use key as Bearer token.
    return vikunja.HttpBearerAuth()..accessToken = _apiKey;
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

// Removed MemosAuthWrapper class
// Removed TodoistAuthWrapper class

/// Wraps an AuthStrategy for the Blinko API client's Authentication interface.
/// Useful if Blinko ever required a non-Bearer auth method handled by the client.
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
/// Useful if Vikunja ever required a non-Bearer auth method handled by the client.
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
