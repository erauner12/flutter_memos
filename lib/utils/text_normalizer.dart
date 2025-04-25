import 'dart:convert';

/// Utility class to handle potential text encoding issues, like double-encoded UTF-8.
class TextNormalizer {
  /// Attempt to fix common double-encoded UTF-8 or similar issues.
  ///
  /// This typically occurs when UTF-8 bytes are incorrectly interpreted as a
  /// single-byte encoding (like Latin-1 or Windows-1252) and then re-encoded
  /// as UTF-8, resulting in garbled characters (e.g., "Ã©" instead of "é").
  ///
  /// Returns a 'best-effort' corrected string, or the original if it doesn't
  /// appear corrupted or if correction fails.
  static String normalize(String input) {
    // Optionally detect if it’s actually double-encoded.
    // For example, checking for common corruption patterns like 'Ã' or 'Â'.
    if (!_likelyCorrupted(input)) {
      return input; // If it doesn't look corrupted, skip extra logic.
    }

    try {
      // 1) Convert "visually corrupted" characters from their Latin-1 representation
      //    back into bytes. This assumes the original misinterpretation was Latin-1.
      final latin1Bytes = latin1.encode(input);

      // 2) Decode those bytes as proper UTF-8
      //    If the original text was valid UTF-8 that got misinterpreted as Latin-1,
      //    this step should recover the original characters.
      final corrected = utf8.decode(latin1Bytes, allowMalformed: false); // Be strict

      // Optional: Add a check here to see if the 'corrected' string still looks like gibberish
      // or contains replacement characters (U+FFFD). If so, the original might not
      // have been double-encoded UTF-8, or the misinterpretation wasn't Latin-1.
      // In complex cases, you might try other encodings like Windows-1252 here.

      return corrected;
    } catch (e) {
      // If decoding fails (e.g., `allowMalformed: false` throws), it likely wasn't
      // the expected double-encoding pattern. Return the original input as fallback.
      // Consider logging the error `e` for debugging.
      // print('Text normalization failed for input: $input. Error: $e');
      return input;
    }
  }

  /// Basic check to see if the string contains characters often resulting from
  /// double-encoding UTF-8 as Latin-1 or similar.
  /// This is a heuristic and might yield false positives or negatives.
  static bool _likelyCorrupted(String input) {
    // Common artifacts include 'Ã' followed by another character.
    // Add more patterns if needed based on observed corruption.
    // Examples: 'Ã©', 'Â°', 'Ã±', 'Ã¼'
    return input.contains('Ã') || input.contains('Â');
    // A more robust check might involve looking for specific sequences or
    // character ranges common in such corruption.
  }
}
