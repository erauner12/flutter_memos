//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PublicHubSiteList200ResponseInner {
  /// Returns a new [PublicHubSiteList200ResponseInner] instance.
  PublicHubSiteList200ResponseInner({
    required this.title,
    required this.url,
    this.tags = const [],
    this.siteDescription,
    this.image,
    this.version,
  });

  String title;

  String url;

  List<String> tags;

  String? siteDescription;

  String? image;

  ///
  /// Please note: This property should have been non-nullable! Since the specification file
  /// does not include a default value (using the "default:" property), however, the generated
  /// source code must fall back to having a nullable type.
  /// Consider adding a "default:" property in the specification file to hide this note.
  ///
  String? version;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PublicHubSiteList200ResponseInner &&
    other.title == title &&
    other.url == url &&
    _deepEquality.equals(other.tags, tags) &&
    other.siteDescription == siteDescription &&
    other.image == image &&
    other.version == version;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (title.hashCode) +
    (url.hashCode) +
    (tags.hashCode) +
    (siteDescription == null ? 0 : siteDescription!.hashCode) +
    (image == null ? 0 : image!.hashCode) +
    (version == null ? 0 : version!.hashCode);

  @override
  String toString() => 'PublicHubSiteList200ResponseInner[title=$title, url=$url, tags=$tags, siteDescription=$siteDescription, image=$image, version=$version]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'title'] = this.title;
      json[r'url'] = this.url;
      json[r'tags'] = this.tags;
    if (this.siteDescription != null) {
      json[r'site_description'] = this.siteDescription;
    } else {
      json[r'site_description'] = null;
    }
    if (this.image != null) {
      json[r'image'] = this.image;
    } else {
      json[r'image'] = null;
    }
    if (this.version != null) {
      json[r'version'] = this.version;
    } else {
      json[r'version'] = null;
    }
    return json;
  }

  /// Returns a new [PublicHubSiteList200ResponseInner] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PublicHubSiteList200ResponseInner? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PublicHubSiteList200ResponseInner[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PublicHubSiteList200ResponseInner[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PublicHubSiteList200ResponseInner(
        title: mapValueOfType<String>(json, r'title')!,
        url: mapValueOfType<String>(json, r'url')!,
        tags: json[r'tags'] is Iterable
            ? (json[r'tags'] as Iterable).cast<String>().toList(growable: false)
            : const [],
        siteDescription: mapValueOfType<String>(json, r'site_description'),
        image: mapValueOfType<String>(json, r'image'),
        version: mapValueOfType<String>(json, r'version'),
      );
    }
    return null;
  }

  static List<PublicHubSiteList200ResponseInner> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PublicHubSiteList200ResponseInner>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PublicHubSiteList200ResponseInner.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PublicHubSiteList200ResponseInner> mapFromJson(dynamic json) {
    final map = <String, PublicHubSiteList200ResponseInner>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PublicHubSiteList200ResponseInner.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PublicHubSiteList200ResponseInner-objects as value to a dart map
  static Map<String, List<PublicHubSiteList200ResponseInner>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PublicHubSiteList200ResponseInner>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PublicHubSiteList200ResponseInner.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'title',
    'url',
  };
}

