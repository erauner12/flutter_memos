//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class ProjectsApi {
  ProjectsApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Create a new project
  ///
  /// Creates a new project and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   Name of the project
  ///
  /// * [String] parentId:
  ///   Parent project ID
  ///
  /// * [String] color:
  ///   The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
  ///
  /// * [bool] isFavorite:
  ///   Whether the project is a favorite (a true or false value).
  ///
  /// * [String] viewStyle:
  ///   A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.
  Future<Response> createProjectWithHttpInfo(String name, { String? parentId, String? color, bool? isFavorite, String? viewStyle, }) async {
    // ignore: prefer_const_declarations
    final path = r'/projects';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

      queryParams.addAll(_queryParams('', 'name', name));
    if (parentId != null) {
      queryParams.addAll(_queryParams('', 'parent_id', parentId));
    }
    if (color != null) {
      queryParams.addAll(_queryParams('', 'color', color));
    }
    if (isFavorite != null) {
      queryParams.addAll(_queryParams('', 'is_favorite', isFavorite));
    }
    if (viewStyle != null) {
      queryParams.addAll(_queryParams('', 'view_style', viewStyle));
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

  /// Create a new project
  ///
  /// Creates a new project and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] name (required):
  ///   Name of the project
  ///
  /// * [String] parentId:
  ///   Parent project ID
  ///
  /// * [String] color:
  ///   The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
  ///
  /// * [bool] isFavorite:
  ///   Whether the project is a favorite (a true or false value).
  ///
  /// * [String] viewStyle:
  ///   A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.
  Future<Project?> createProject(String name, { String? parentId, String? color, bool? isFavorite, String? viewStyle, }) async {
    final response = await createProjectWithHttpInfo(name,  parentId: parentId, color: color, isFavorite: isFavorite, viewStyle: viewStyle, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Project',) as Project;
    
    }
    return null;
  }

  /// Delete a project
  ///
  /// Deletes a project.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<Response> deleteProjectWithHttpInfo(String projectId,) async {
    // ignore: prefer_const_declarations
    final path = r'/projects/{projectId}'
      .replaceAll('{projectId}', projectId);

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

  /// Delete a project
  ///
  /// Deletes a project.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<void> deleteProject(String projectId,) async {
    final response = await deleteProjectWithHttpInfo(projectId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get all project collaborators
  ///
  /// Returns JSON-encoded array containing all collaborators of a shared project.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<Response> getAllCollaboratorsWithHttpInfo(String projectId,) async {
    // ignore: prefer_const_declarations
    final path = r'/projects/{projectId}/collaborators'
      .replaceAll('{projectId}', projectId);

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

  /// Get all project collaborators
  ///
  /// Returns JSON-encoded array containing all collaborators of a shared project.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<List<Collaborator>?> getAllCollaborators(String projectId,) async {
    final response = await getAllCollaboratorsWithHttpInfo(projectId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Collaborator>') as List)
        .cast<Collaborator>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get all projects
  ///
  /// Returns JSON-encoded array containing all user projects.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  Future<Response> getAllProjectsWithHttpInfo() async {
    // ignore: prefer_const_declarations
    final path = r'/projects';

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

  /// Get all projects
  ///
  /// Returns JSON-encoded array containing all user projects.  A successful response has 200 OK status and application/json Content-Type. 
  Future<List<Project>?> getAllProjects() async {
    final response = await getAllProjectsWithHttpInfo();
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Project>') as List)
        .cast<Project>()
        .toList(growable: false);

    }
    return null;
  }

  /// Get a project
  ///
  /// Returns a JSON object containing a project object related to the given ID.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<Response> getProjectWithHttpInfo(String projectId,) async {
    // ignore: prefer_const_declarations
    final path = r'/projects/{projectId}'
      .replaceAll('{projectId}', projectId);

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

  /// Get a project
  ///
  /// Returns a JSON object containing a project object related to the given ID.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  Future<Project?> getProject(String projectId,) async {
    final response = await getProjectWithHttpInfo(projectId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Project',) as Project;
    
    }
    return null;
  }

  /// Update a project
  ///
  /// Returns a JSON object containing the updated project object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  ///
  /// * [String] name:
  ///   Name of the project
  ///
  /// * [String] color:
  ///   The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
  ///
  /// * [bool] isFavorite:
  ///   Whether the project is a favorite (a true or false value).
  ///
  /// * [String] viewStyle:
  ///   A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.
  Future<Response> updateProjectWithHttpInfo(String projectId, { String? name, String? color, bool? isFavorite, String? viewStyle, }) async {
    // ignore: prefer_const_declarations
    final path = r'/projects/{projectId}'
      .replaceAll('{projectId}', projectId);

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (name != null) {
      queryParams.addAll(_queryParams('', 'name', name));
    }
    if (color != null) {
      queryParams.addAll(_queryParams('', 'color', color));
    }
    if (isFavorite != null) {
      queryParams.addAll(_queryParams('', 'is_favorite', isFavorite));
    }
    if (viewStyle != null) {
      queryParams.addAll(_queryParams('', 'view_style', viewStyle));
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

  /// Update a project
  ///
  /// Returns a JSON object containing the updated project object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId (required):
  ///   Project ID.
  ///
  /// * [String] name:
  ///   Name of the project
  ///
  /// * [String] color:
  ///   The color of the project icon. Refer to the name column in the Colors guide for more info. https://developer.todoist.com/guides/#colors
  ///
  /// * [bool] isFavorite:
  ///   Whether the project is a favorite (a true or false value).
  ///
  /// * [String] viewStyle:
  ///   A string value (either list or board, default is list). This determines the way the project is displayed within the Todoist clients.
  Future<Project?> updateProject(String projectId, { String? name, String? color, bool? isFavorite, String? viewStyle, }) async {
    final response = await updateProjectWithHttpInfo(projectId,  name: name, color: color, isFavorite: isFavorite, viewStyle: viewStyle, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Project',) as Project;
    
    }
    return null;
  }
}
