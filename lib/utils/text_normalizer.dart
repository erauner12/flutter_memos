import 'dart:convert';

import 'package:flutter/foundation.dart'; // For kDebugMode

/// Utility class to handle potential text encoding issues, like double-encoded UTF-8.
class TextNormalizer {

  /// Attempts a single pass of fixing double-encoded UTF-8 (Latin-1 -> UTF-8).
  /// Returns the potentially corrected string or the original if correction fails.
  static String _singleDecodeAttempt(String input) {
    try {
      // 1) Convert "visually corrupted" characters from their Latin-1 representation
      //    back into bytes. This assumes the original misinterpretation was Latin-1.
      final latin1Bytes = latin1.encode(input);

      // 2) Decode those bytes as proper UTF-8
      //    If the original text was valid UTF-8 that got misinterpreted as Latin-1,
      //    this step should recover the original characters.
      final corrected = utf8.decode(latin1Bytes, allowMalformed: false); // Be strict

      // Avoid returning the same string if decoding didn't change anything,
      // which can happen if the input wasn't actually Latin-1 encoded UTF-8 bytes.
      return corrected == input ? input : corrected;
    } catch (e) {
      // If decoding fails (e.g., `allowMalformed: false` throws), it likely wasn't
      // the expected double-encoding pattern. Return the original input as fallback.
      // Consider logging the error `e` for debugging.
      // if (kDebugMode) {
      //   print('Text normalization single pass failed for input: $input. Error: $e');
      // }
      return input;
    }
  }

  /// Attempt to fix common double-encoded UTF-8 issues with a single pass.
  ///
  /// Returns a 'best-effort' corrected string, or the original if it doesn't
  /// appear corrupted or if correction fails. This is suitable if you expect
  /// at most one level of mis-encoding.
  static String normalize(String input) {
    if (!_likelyCorrupted(input)) {
      return input; // Skip if it doesn't look corrupted.
    }
    return _singleDecodeAttempt(input);
  }

  /// Attempt to fix potentially multi-level double-encoded UTF-8 issues iteratively.
  ///
  /// This repeatedly applies the Latin-1 -> UTF-8 decoding logic up to `maxRounds`
  /// times, as long as the text still appears corrupted after each pass.
  ///
  /// Use this if you suspect text might have been mis-encoded multiple times.
  ///
  /// - [input]: The string to normalize.
  /// - [maxRounds]: The maximum number of decoding attempts (default: 3).
  ///
  /// Returns the best-effort corrected string after iterations.
  static String iterativeNormalize(String input, {int maxRounds = 3}) {
    String current = input;
    bool changedInLastRound = false;

    for (int i = 0; i < maxRounds; i++) {
      if (!_likelyCorrupted(current)) {
        if (kDebugMode && i > 0 && changedInLastRound) {
          // Only log if normalization actually happened and then stopped.
          print(
            '[TextNormalizer] Iterative normalization stopped after $i rounds as text no longer looks corrupted.',
          );
        }
        break; // Stop if the text no longer looks corrupted
      }

      String previous = current;
      current = _singleDecodeAttempt(current);

      if (current == previous) {
        if (kDebugMode && i > 0 && changedInLastRound) {
          // Log if it stopped changing after having changed before.
          print(
            '[TextNormalizer] Iterative normalization stopped after $i rounds as text did not change further.',
          );
        }
        // If a decode attempt didn't change the string, further attempts are unlikely to help.
        break;
      } else {
        changedInLastRound = true; // Mark that a change occurred in this round
        if (kDebugMode) {
          print(
            '[TextNormalizer] Iterative normalization completed round ${i + 1}.',
          );
        }
      }

      if (i == maxRounds - 1 && kDebugMode && changedInLastRound) {
        print(
          '[TextNormalizer] Iterative normalization reached max rounds ($maxRounds). Final result: "$current"',
        );
      }
    }
    return current;
  }


  /// Basic check to see if the string contains characters often resulting from
  /// double-encoding UTF-8 as Latin-1 or similar.
  /// This is a heuristic and might yield false positives or negatives.
  static bool _likelyCorrupted(String input) {
    // Common artifacts include 'Ã' followed by another character,
    // or 'Â' which often appears with symbols or spaces.
    // Examples: 'Ã©', 'Â°', 'Ã±', 'Ã¼', 'Â ', 'Â£'
    // Added check for common multi-byte UTF-8 start patterns misinterpreted as single bytes.
    return input.contains('Ã') || input.contains('Â');
    // Consider more sophisticated checks if needed, e.g., regex for specific patterns
    // like /Ã[A-Z]/ or checking character codes.
  }
}
