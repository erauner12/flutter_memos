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


/// tests for TasksApi
void main() {
  // final instance = TasksApi();

  group('tests for TasksApi', () {
    // Close a task
    //
    // Closes a task. Regular tasks are marked complete and moved to history, along with their subtasks. Tasks with recurring due dates will be scheduled to their next occurrence.  A successful response has 204 No Content status and an empty body. 
    //
    //Future closeTask(int taskId) async
    test('test closeTask', () async {
      // TODO
    });

    // Create a new task
    //
    // Creates a new task and returns it as a JSON object. 
    //
    //Future<Task> createTask(CreateTaskRequest createTaskRequest) async
    test('test createTask', () async {
      // TODO
    });

    // Delete a task
    //
    // Deletes a task.   A successful response has 204 No Content status and an empty body. 
    //
    //Future deleteTask(int taskId) async
    test('test deleteTask', () async {
      // TODO
    });

    // Get an active task
    //
    // Returns a single active (non-completed) task by ID as a JSON object.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<Task> getActiveTask(int taskId) async
    test('test getActiveTask', () async {
      // TODO
    });

    // Get active tasks
    //
    // Returns a JSON-encoded array containing all active tasks.  A successful response has 200 OK status and application/json Content-Type. 
    //
    //Future<List<Task>> getActiveTasks({ String projectId, String sectionId, String label, String filter, String lang, List<int> ids }) async
    test('test getActiveTasks', () async {
      // TODO
    });

    // Reopen a task
    //
    // Reopens a task. Any ancestor items or sections will also be marked as uncomplete and restored from history. The reinstated items and sections will appear at the end of the list within their parent, after any previously active items.  A successful response has 204 No Content status... 
    //
    //Future reopenTask(int taskId) async
    test('test reopenTask', () async {
      // TODO
    });

    // Update a task
    //
    // Updates a specified task and returns it as a JSON object. 
    //
    //Future<Task> updateTask(String taskId, UpdateTaskRequest updateTaskRequest) async
    test('test updateTask', () async {
      // TODO
    });

  });
}
