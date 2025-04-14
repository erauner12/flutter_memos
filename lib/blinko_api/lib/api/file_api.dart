//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;


class FileApi {
  FileApi([ApiClient? apiClient]) : apiClient = apiClient ?? defaultApiClient;

  final ApiClient apiClient;

  /// Delete File
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [DeleteFileRequest] deleteFileRequest (required):
  Future<Response> deleteFileWithHttpInfo(DeleteFileRequest deleteFileRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/file/delete';

    // ignore: prefer_final_locals
    Object? postBody = deleteFileRequest;

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

  /// Delete File
  ///
  /// Parameters:
  ///
  /// * [DeleteFileRequest] deleteFileRequest (required):
  Future<DeleteFile200Response?> deleteFile(DeleteFileRequest deleteFileRequest,) async {
    final response = await deleteFileWithHttpInfo(deleteFileRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'DeleteFile200Response',) as DeleteFile200Response;
    
    }
    return null;
  }

  /// Upload File
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   Upload File
  Future<Response> uploadFileWithHttpInfo(MultipartFile file,) async {
    // ignore: prefer_const_declarations
    final path = r'/file/upload';

    // ignore: prefer_final_locals
    Object? postBody;

    final queryParams = <QueryParam>[];
    final headerParams = <String, String>{};
    final formParams = <String, String>{};

    const contentTypes = <String>['multipart/form-data'];

    bool hasFields = false;
    final mp = MultipartRequest('POST', Uri.parse(path));
    if (file != null) {
      hasFields = true;
      mp.fields[r'file'] = file.field;
      mp.files.add(file);
    }
    if (hasFields) {
      postBody = mp;
    }

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

  /// Upload File
  ///
  /// Parameters:
  ///
  /// * [MultipartFile] file (required):
  ///   Upload File
  Future<UploadFile200Response?> uploadFile(MultipartFile file,) async {
    final response = await uploadFileWithHttpInfo(file,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UploadFile200Response',) as UploadFile200Response;
    
    }
    return null;
  }

  /// Upload File by URL
  ///
  /// Note: This method returns the HTTP [Response].
  ///
  /// Parameters:
  ///
  /// * [UploadFileByUrlRequest] uploadFileByUrlRequest (required):
  Future<Response> uploadFileByUrlWithHttpInfo(UploadFileByUrlRequest uploadFileByUrlRequest,) async {
    // ignore: prefer_const_declarations
    final path = r'/file/upload-by-url';

    // ignore: prefer_final_locals
    Object? postBody = uploadFileByUrlRequest;

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

  /// Upload File by URL
  ///
  /// Parameters:
  ///
  /// * [UploadFileByUrlRequest] uploadFileByUrlRequest (required):
  Future<UploadFileByUrl200Response?> uploadFileByUrl(UploadFileByUrlRequest uploadFileByUrlRequest,) async {
    final response = await uploadFileByUrlWithHttpInfo(uploadFileByUrlRequest,);
    if (response.statusCode >= HttpStatus.badRequest) {
      throw ApiException(response.statusCode, await _decodeBodyBytes(response));
    }
    // When a remote server returns no body with a status of 204, we shall not decode it.
    // At the time of writing this, `dart:convert` will throw an "Unexpected end of input"
    // FormatException when trying to decode an empty string.
    if (response.body.isNotEmpty && response.statusCode != HttpStatus.noContent) {
      return await apiClient.deserializeAsync(await _decodeBodyBytes(response), 'UploadFileByUrl200Response',) as UploadFileByUrl200Response;
    
    }
    return null;
  }
}
