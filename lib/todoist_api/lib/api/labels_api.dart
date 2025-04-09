//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class LabelsApi {
  LabelsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new personal label
  ///
  /// Creates a new personal label and returns its object as JSON.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   Name of the label.
  ///
  /// * [int] order:
  ///   Label order.
  ///
  /// * [String] color:
  ///   The color of the label icon. Refer to the name column in the Colors guide for more info.
  ///
  /// * [bool] isFavorite:
  ///   Whether the label is a favorite (a true or false value).
  Future<Response> createPersonalLabelWithHttpInfo(String name, { int? order, String? color, bool? isFavorite, }) async {
    // ignore: prefer_const_declarations
    final path = r'/labels';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'name', name));
    if (order != null) {
      queryParams.addAll(_queryParams('', 'order', order));
    }
    if (color != null) {
      queryParams.addAll(_queryParams('', 'color', color));
    }
    if (isFavorite != null) {
      queryParams.addAll(_queryParams('', 'is_favorite', isFavorite));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Create a new personal label
  ///
  /// Creates a new personal label and returns its object as JSON.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   Name of the label.
  ///
  /// * [int] order:
  ///   Label order.
  ///
  /// * [String] color:
  ///   The color of the label icon. Refer to the name column in the Colors guide for more info.
  ///
  /// * [bool] isFavorite:
  ///   Whether the label is a favorite (a true or false value).
  Future<Label?> createPersonalLabel(String name, { int? order, String? color, bool? isFavorite, }) async {
    final response = await createPersonalLabelWithHttpInfo(name,  order: order, color: color, isFavorite: isFavorite, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Label',) as Label;
    
    }
    return null;
  }

  /// Delete a personal label
  ///
  /// Deletes a personal label, all instances of the label will be removed from tasks.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] labelId (required):
  ///   The ID of the label to delete.
  Future<Response> deletePersonalLabelWithHttpInfo(int labelId,) async {
    // ignore: prefer_const_declarations
    final path = r'/labels/{label_id}'
      .replaceAll('{label_id}', labelId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'DELETE',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Delete a personal label
  ///
  /// Deletes a personal label, all instances of the label will be removed from tasks.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [int] labelId (required):
  ///   The ID of the label to delete.
  Future<void> deletePersonalLabel(int labelId,) async {
    final response = await deletePersonalLabelWithHttpInfo(labelId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get all personal labels
  ///
  /// Returns a JSON-encoded array containing all user labels.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAllPersonalLabelsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/labels';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get all personal labels
  ///
  /// Returns a JSON-encoded array containing all user labels.  A successful response has 200 OK status and application/json Content-Type. 
  Future<List<Label>?> getAllPersonalLabels() async {
    final response = await getAllPersonalLabelsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Label>') as List)
        .cast<Label>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get a personal label
  ///
  /// Returns a personal label by ID.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] labelId (required):
  ///   The ID of the label to retrieve.
  Future<Response> getPersonalLabelWithHttpInfo(int labelId,) async {
    // ignore: prefer_const_declarations
    final path = r'/labels/{label_id}'
      .replaceAll('{label_id}', labelId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'GET',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Get a personal label
  ///
  /// Returns a personal label by ID.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [int] labelId (required):
  ///   The ID of the label to retrieve.
  Future<Label?> getPersonalLabel(int labelId,) async {
    final response = await getPersonalLabelWithHttpInfo(labelId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Label',) as Label;
    
    }
    return null;
  }

  /// Update a personal label
  ///
  /// Returns the updated label.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] labelId (required):
  ///   The ID of the label to update.
  ///
  /// * [String] name:
  ///   New name of the label.
  ///
  /// * [int] order:
  ///   Number that is used by clients to sort the list of labels.
  ///
  /// * [String] color:
  ///   The color of the label icon. Refer to the name column in the Colors guide for more info.
  ///
  /// * [bool] isFavorite:
  ///   Whether the label is a favorite (a true or false value).
  Future<Response> updatePersonalLabelWithHttpInfo(String labelId, { String? name, int? order, String? color, bool? isFavorite, }) async {
    // ignore: prefer_const_declarations
    final path = r'/labels/{label_id}'
      .replaceAll('{label_id}', labelId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (name != null) {
      queryParams.addAll(_queryParams('', 'name', name));
    }
    if (order != null) {
      queryParams.addAll(_queryParams('', 'order', order));
    }
    if (color != null) {
      queryParams.addAll(_queryParams('', 'color', color));
    }
    if (isFavorite != null) {
      queryParams.addAll(_queryParams('', 'is_favorite', isFavorite));
    }

    const contentTypes = <String>[];


    return apiClient.invokeAPI(
      path,
      'POST',
      queryParams,
      postBody,
      headerParams,
      formParams,
      contentTypes.isEmpty ? null : contentTypes.first,
    );
  }

  /// Update a personal label
  ///
  /// Returns the updated label.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] labelId (required):
  ///   The ID of the label to update.
  ///
  /// * [String] name:
  ///   New name of the label.
  ///
  /// * [int] order:
  ///   Number that is used by clients to sort the list of labels.
  ///
  /// * [String] color:
  ///   The color of the label icon. Refer to the name column in the Colors guide for more info.
  ///
  /// * [bool] isFavorite:
  ///   Whether the label is a favorite (a true or false value).
  Future<Label?> updatePersonalLabel(String labelId, { String? name, int? order, String? color, bool? isFavorite, }) async {
    final response = await updatePersonalLabelWithHttpInfo(labelId,  name: name, order: order, color: color, isFavorite: isFavorite, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Label',) as Label;
    
    }
    return null;
  }
}
