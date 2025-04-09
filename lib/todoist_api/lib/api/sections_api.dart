//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class SectionsApi {
  SectionsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new section
  ///
  /// Creates a new section and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID this section should belong to
  ///
  /// * [String] name (required):
  ///   Section name
  ///
  /// * [int] order:
  ///   Order among other sections in a project
  Future<Response> createSectionWithHttpInfo(String projectId, String name, { int? order, }) async {
    // ignore: prefer_const_declarations
    final path = r'/sections';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'project_id', projectId));
      queryParams.addAll(_queryParams('', 'name', name));
    if (order != null) {
      queryParams.addAll(_queryParams('', 'order', order));
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

  /// Create a new section
  ///
  /// Creates a new section and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID this section should belong to
  ///
  /// * [String] name (required):
  ///   Section name
  ///
  /// * [int] order:
  ///   Order among other sections in a project
  Future<Section?> createSection(String projectId, String name, { int? order, }) async {
    final response = await createSectionWithHttpInfo(projectId, name,  order: order, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Section',) as Section;
    
    }
    return null;
  }

  /// Delete a section
  ///
  /// Deletes a section.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  Future<Response> deleteSectionWithHttpInfo(String sectionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/sections/{sectionId}'
      .replaceAll('{sectionId}', sectionId);

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

  /// Delete a section
  ///
  /// Deletes a section.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  Future<void> deleteSection(String sectionId,) async {
    final response = await deleteSectionWithHttpInfo(sectionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get all sections
  ///
  /// Returns a JSON array of all sections.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   Project ID.
  Future<Response> getAllSectionsWithHttpInfo({ String? projectId, }) async {
    // ignore: prefer_const_declarations
    final path = r'/sections';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (projectId != null) {
      queryParams.addAll(_queryParams('', 'project_id', projectId));
    }

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

  /// Get all sections
  ///
  /// Returns a JSON array of all sections.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   Project ID.
  Future<List<Section>?> getAllSections({ String? projectId, }) async {
    final response = await getAllSectionsWithHttpInfo( projectId: projectId, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Section>') as List)
        .cast<Section>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get single section
  ///
  /// Returns a single section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  Future<Response> getSingleSectionWithHttpInfo(String sectionId,) async {
    // ignore: prefer_const_declarations
    final path = r'/sections/{sectionId}'
      .replaceAll('{sectionId}', sectionId);

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

  /// Get single section
  ///
  /// Returns a single section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  Future<Section?> getSingleSection(String sectionId,) async {
    final response = await getSingleSectionWithHttpInfo(sectionId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Section',) as Section;
    
    }
    return null;
  }

  /// Update a section name
  ///
  /// Returns the updated section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  ///
  /// * [String] name (required):
  ///   Section name.
  Future<Response> updateSectionWithHttpInfo(String sectionId, String name,) async {
    // ignore: prefer_const_declarations
    final path = r'/sections/{sectionId}'
      .replaceAll('{sectionId}', sectionId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'name', name));

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

  /// Update a section name
  ///
  /// Returns the updated section as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] sectionId (required):
  ///   Section ID.
  ///
  /// * [String] name (required):
  ///   Section name.
  Future<Section?> updateSection(String sectionId, String name,) async {
    final response = await updateSectionWithHttpInfo(sectionId, name,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Section',) as Section;
    
    }
    return null;
  }
}
