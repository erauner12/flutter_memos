import 'package:flutter/foundation.dart';
// Removed import for WorkbenchItemType as it's no longer needed here.

/// Parses a string [raw] into an enum value of type [T].
///
/// Uses a case-insensitive comparison against the string representation
/// of the enum values obtained via [describeEnum].
///
/// If [raw] is null or does not match any enum value, returns the
/// provided [defaultValue].
T enumFromString<T>(
  Iterable<T> values,
  String? raw, {
  required T defaultValue, // Changed from WorkbenchItemType to T
}) {
  if (raw == null) {
    // Return default if raw string is null
    return defaultValue; // Use the provided generic default value
  }
  final rawLower = raw.toLowerCase();
  for (final value in values) {
    // Ensure value is treated as Object for describeEnum
    final enumName = describeEnum(value as Object).toLowerCase();
    if (enumName == rawLower) {
      return value;
    }
  }
  // Return default if no match found
  // Optionally, throw an exception here:
  // throw ArgumentError('"$raw" is not a valid value for enum $T');
  if (kDebugMode) {
    print(
      'Warning: Enum value "$raw" not found in ${T.toString()}. Defaulting to ${describeEnum(defaultValue as Object)}.',
    );
  }
  return defaultValue; // Use the provided generic default value
}
