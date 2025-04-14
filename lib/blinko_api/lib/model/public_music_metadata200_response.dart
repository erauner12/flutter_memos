//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicMusicMetadata200Response {
  /// Returns a new [PublicMusicMetadata200Response] instance.
  PublicMusicMetadata200Response({
    this.coverUrl,
    this.trackName,
    this.albumName,
    this.artists = const [],
  });

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? coverUrl;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? trackName;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? albumName;

  List<String> artists;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicMusicMetadata200Response &&
    other.coverUrl == coverUrl &&
    other.trackName == trackName &&
    other.albumName == albumName &&
    _deepEquality.equals(other.artists, artists);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (coverUrl == null ? 0 : coverUrl!.hashCode) +
    (trackName == null ? 0 : trackName!.hashCode) +
    (albumName == null ? 0 : albumName!.hashCode) +
    (artists.hashCode);

  @override
  String toString() => 'PublicMusicMetadata200Response[coverUrl=$coverUrl, trackName=$trackName, albumName=$albumName, artists=$artists]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (this.coverUrl != null) {
      json[r'coverUrl'] = this.coverUrl;
    } else {
      json[r'coverUrl'] = null;
    }
    if (this.trackName != null) {
      json[r'trackName'] = this.trackName;
    } else {
      json[r'trackName'] = null;
    }
    if (this.albumName != null) {
      json[r'albumName'] = this.albumName;
    } else {
      json[r'albumName'] = null;
    }
      json[r'artists'] = this.artists;
    return json;
  }

  /// Returns a new [PublicMusicMetadata200Response] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicMusicMetadata200Response? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicMusicMetadata200Response[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicMusicMetadata200Response[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicMusicMetadata200Response(
        coverUrl: mapValueOfType<String>(json, r'coverUrl'),
        trackName: mapValueOfType<String>(json, r'trackName'),
        albumName: mapValueOfType<String>(json, r'albumName'),
        artists: json[r'artists'] is Iterable
            ? (json[r'artists'] as Iterable).cast<String>().toList(growable: false)
            : const [],
      );
    }
    return null;
  }

  static List<PublicMusicMetadata200Response> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicMusicMetadata200Response>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicMusicMetadata200Response.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicMusicMetadata200Response> mapFromJson(dynamic json) {
    final map = <String, PublicMusicMetadata200Response>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicMusicMetadata200Response.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicMusicMetadata200Response-objects as value to a dart map
  static Map<String, List<PublicMusicMetadata200Response>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicMusicMetadata200Response>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicMusicMetadata200Response.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
  };
}

