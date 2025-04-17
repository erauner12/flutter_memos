import 'package:flutter/foundation.dart';

/// Parses a string [raw] into an enum value of type [T].
///
/// Uses a case-insensitive comparison against the string representation
/// of the enum values obtained via [describeEnum].
///
/// If [raw] is null or does not match any enum value, returns the
/// first value in the provided [values] iterable as a safe default.
/// Consider throwing an error or returning null if a default is not desired.
T enumFromString<T>(Iterable<T> values, String? raw) {
  if (raw == null) {
    // Return default if raw string is null
    return values.first;
  }
  final rawLower = raw.toLowerCase();
  for (final value in values) {
    if (describeEnum(value as Object).toLowerCase() == rawLower) {
      return value;
    }
  }
  // Return default if no match found
  // Optionally, throw an exception here:
  // throw ArgumentError('"$raw" is not a valid value for enum $T');
  if (kDebugMode) {
    print('Warning: Enum value "$raw" not found in ${T.toString()}. Defaulting to ${describeEnum(values.first as Object)}.');
  }
  return values.first;
}
