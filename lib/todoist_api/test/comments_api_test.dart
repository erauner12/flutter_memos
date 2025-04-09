//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

import 'package:todoist_flutter_api/api.dart';
import 'package:test/test.dart';


/// tests for CommentsApi
void main() {
  // final instance = CommentsApi();

  group('tests for CommentsApi', () {
    // Create a new comment
    //
    // Creates a new comment on a project or task and returns it as a JSON object. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<Comment> createComment(String content, { String taskId, String projectId, CreateCommentAttachmentParameter attachment }) async
    test('test createComment', () async {
      // TODO
    });

    // Delete a comment
    //
    // Deletes a comment.  A successful response has 204 No Content status and an empty body. 
    //
    //Future deleteComment(int commentId) async
    test('test deleteComment', () async {
      // TODO
    });

    // Get all comments
    //
    // Returns a JSON-encoded array of all comments for a given task_id or project_id. Note that one of task_id or project_id arguments is required.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<List<Comment>> getAllComments({ String projectId, String taskId }) async
    test('test getAllComments', () async {
      // TODO
    });

    // Get a comment
    //
    // Returns a single comment as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<Comment> getComment(int commentId) async
    test('test getComment', () async {
      // TODO
    });

    // Update a comment
    //
    // Updates a comment and returns it as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<Comment> updateComment(String commentId, String content) async
    test('test updateComment', () async {
      // TODO
    });

  });
}
