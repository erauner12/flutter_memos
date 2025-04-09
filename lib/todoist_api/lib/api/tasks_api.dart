//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class TasksApi {
  TasksApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Close a task
  ///
  /// Closes a task. Regular tasks are marked complete and moved to history, along with their subtasks. Tasks with recurring due dates will be scheduled to their next occurrence.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to close.
  Future<Response> closeTaskWithHttpInfo(int taskId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks/{taskId}/close'
      .replaceAll('{taskId}', taskId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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

  /// Close a task
  ///
  /// Closes a task. Regular tasks are marked complete and moved to history, along with their subtasks. Tasks with recurring due dates will be scheduled to their next occurrence.  A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to close.
  Future<void> closeTask(int taskId,) async {
    final response = await closeTaskWithHttpInfo(taskId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Create a new task
  ///
  /// Creates a new task and returns it as a JSON object. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [CreateTaskRequest] createTaskRequest (required):
  Future<Response> createTaskWithHttpInfo(CreateTaskRequest createTaskRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks';

    // ignore: prefer_final_locals
    Object? postBody = createTaskRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


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

  /// Create a new task
  ///
  /// Creates a new task and returns it as a JSON object. 
  ///
  /// Parameters:
  ///
  /// * [CreateTaskRequest] createTaskRequest (required):
  Future<Task?> createTask(CreateTaskRequest createTaskRequest,) async {
    final response = await createTaskWithHttpInfo(createTaskRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Task',) as Task;
    
    }
    return null;
  }

  /// Delete a task
  ///
  /// Deletes a task.   A successful response has 204 No Content status and an empty body. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to delete.
  Future<Response> deleteTaskWithHttpInfo(int taskId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks/{taskId}'
      .replaceAll('{taskId}', taskId.toString());

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

  /// Delete a task
  ///
  /// Deletes a task.   A successful response has 204 No Content status and an empty body. 
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to delete.
  Future<void> deleteTask(int taskId,) async {
    final response = await deleteTaskWithHttpInfo(taskId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Get an active task
  ///
  /// Returns a single active (non-completed) task by ID as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to retrieve.
  Future<Response> getActiveTaskWithHttpInfo(int taskId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks/{taskId}'
      .replaceAll('{taskId}', taskId.toString());

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

  /// Get an active task
  ///
  /// Returns a single active (non-completed) task by ID as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to retrieve.
  Future<Task?> getActiveTask(int taskId,) async {
    final response = await getActiveTaskWithHttpInfo(taskId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Task',) as Task;
    
    }
    return null;
  }

  /// Get active tasks
  ///
  /// Returns a JSON-encoded array containing all active tasks.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   Filter tasks by project ID.
  ///
  /// * [String] sectionId:
  ///   Filter tasks by section ID.
  ///
  /// * [String] label:
  ///   Filter tasks by label name.
  ///
  /// * [String] filter:
  ///   Filter by any supported filter.
  ///
  /// * [String] lang:
  ///   IETF language tag defining what language the filter is written in, if it differs from the default English.
  ///
  /// * [List<int>] ids:
  ///   A list of the task IDs to retrieve, this should be a comma-separated list.
  Future<Response> getActiveTasksWithHttpInfo({ String? projectId, String? sectionId, String? label, String? filter, String? lang, List<int>? ids, }) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    if (projectId != null) {
      queryParams.addAll(_queryParams('', 'project_id', projectId));
    }
    if (sectionId != null) {
      queryParams.addAll(_queryParams('', 'section_id', sectionId));
    }
    if (label != null) {
      queryParams.addAll(_queryParams('', 'label', label));
    }
    if (filter != null) {
      queryParams.addAll(_queryParams('', 'filter', filter));
    }
    if (lang != null) {
      queryParams.addAll(_queryParams('', 'lang', lang));
    }
    if (ids != null) {
      queryParams.addAll(_queryParams('multi', 'ids', ids));
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

  /// Get active tasks
  ///
  /// Returns a JSON-encoded array containing all active tasks.  A successful response has 200 OK status and application/json Content-Type. 
  ///
  /// Parameters:
  ///
  /// * [String] projectId:
  ///   Filter tasks by project ID.
  ///
  /// * [String] sectionId:
  ///   Filter tasks by section ID.
  ///
  /// * [String] label:
  ///   Filter tasks by label name.
  ///
  /// * [String] filter:
  ///   Filter by any supported filter.
  ///
  /// * [String] lang:
  ///   IETF language tag defining what language the filter is written in, if it differs from the default English.
  ///
  /// * [List<int>] ids:
  ///   A list of the task IDs to retrieve, this should be a comma-separated list.
  Future<List<Task>?> getActiveTasks({ String? projectId, String? sectionId, String? label, String? filter, String? lang, List<int>? ids, }) async {
    final response = await getActiveTasksWithHttpInfo( projectId: projectId, sectionId: sectionId, label: label, filter: filter, lang: lang, ids: ids, );
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      final responseBody = await _decodeBodyBytes(response);
      return (await apiClient.deserializeAsync(responseBody, 'List<Task>') as List)
        .cast<Task>()
        .toList(growable: false);

    }
    return null;
  }

  /// Reopen a task
  ///
  /// Reopens a task. Any ancestor items or sections will also be marked as uncomplete and restored from history. The reinstated items and sections will appear at the end of the list within their parent, after any previously active items.  A successful response has 204 No Content status... 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to reopen.
  Future<Response> reopenTaskWithHttpInfo(int taskId,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks/{taskId}/reopen'
      .replaceAll('{taskId}', taskId.toString());

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

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

  /// Reopen a task
  ///
  /// Reopens a task. Any ancestor items or sections will also be marked as uncomplete and restored from history. The reinstated items and sections will appear at the end of the list within their parent, after any previously active items.  A successful response has 204 No Content status... 
  ///
  /// Parameters:
  ///
  /// * [int] taskId (required):
  ///   The ID of the task to reopen.
  Future<void> reopenTask(int taskId,) async {
    final response = await reopenTaskWithHttpInfo(taskId,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
  }

  /// Update a task
  ///
  /// Updates a specified task and returns it as a JSON object. 
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [String] taskId (required):
  ///   The ID of the task to update.
  ///
  /// * [UpdateTaskRequest] updateTaskRequest (required):
  Future<Response> updateTaskWithHttpInfo(String taskId, UpdateTaskRequest updateTaskRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/tasks/{taskId}'
      .replaceAll('{taskId}', taskId);

    // ignore: prefer_final_locals
    Object? postBody = updateTaskRequest;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['application/json'];


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

  /// Update a task
  ///
  /// Updates a specified task and returns it as a JSON object. 
  ///
  /// Parameters:
  ///
  /// * [String] taskId (required):
  ///   The ID of the task to update.
  ///
  /// * [UpdateTaskRequest] updateTaskRequest (required):
  Future<Task?> updateTask(String taskId, UpdateTaskRequest updateTaskRequest,) async {
    final response = await updateTaskWithHttpInfo(taskId, updateTaskRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'Task',) as Task;
    
    }
    return null;
  }
}
