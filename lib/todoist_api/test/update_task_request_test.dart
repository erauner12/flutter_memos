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

// tests for UpdateTaskRequest
void main() {
  // final instance = UpdateTaskRequest();

  group('test UpdateTaskRequest', () {
    // Task content. This value may contain markdown-formatted text and hyperlinks.
    // String content
    test('to test the property `content`', () async {
      // TODO
    });

    // A description for the task. This value may contain markdown-formatted text and hyperlinks.
    // String description
    test('to test the property `description`', () async {
      // TODO
    });

    // The task's labels (a list of names that may represent either personal or shared labels).
    // List<String> labels (default value: const [])
    test('to test the property `labels`', () async {
      // TODO
    });

    // Task priority from 1 (normal) to 4 (urgent).
    // int priority
    test('to test the property `priority`', () async {
      // TODO
    });

    // Human-defined task due date (ex. \"next Monday,\" \"Tomorrow\"). Value is set using local (not UTC) time.
    // String dueString
    test('to test the property `dueString`', () async {
      // TODO
    });

    // Specific date in YYYY-MM-DD format relative to the user's timezone.
    // String dueDate
    test('to test the property `dueDate`', () async {
      // TODO
    });

    // Specific date and time in RFC3339 format in UTC.
    // String dueDatetime
    test('to test the property `dueDatetime`', () async {
      // TODO
    });

    // 2-letter code specifying the language in case due_string is not written in English.
    // String dueLang
    test('to test the property `dueLang`', () async {
      // TODO
    });

    // The responsible user ID or null to unset (for shared tasks).
    // String assigneeId
    test('to test the property `assigneeId`', () async {
      // TODO
    });

    // A positive integer for the task duration, or null to unset. If specified, you must define a duration_unit.
    // int duration
    test('to test the property `duration`', () async {
      // TODO
    });

    // The unit of time for the duration. Must be either 'minute' or 'day'.
    // String durationUnit
    test('to test the property `durationUnit`', () async {
      // TODO
    });


  });

}
