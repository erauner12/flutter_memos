//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FormattedPrice {
  /// Returns a new [FormattedPrice] instance.
  FormattedPrice({
    required this.currency,
    required this.unitAmount,
    required this.taxBehavior,
  });

  String currency;

  int unitAmount;

  String taxBehavior;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FormattedPrice &&
    other.currency == currency &&
    other.unitAmount == unitAmount &&
    other.taxBehavior == taxBehavior;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (currency.hashCode) +
    (unitAmount.hashCode) +
    (taxBehavior.hashCode);

  @override
  String toString() => 'FormattedPrice[currency=$currency, unitAmount=$unitAmount, taxBehavior=$taxBehavior]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'currency'] = this.currency;
      json[r'unit_amount'] = this.unitAmount;
      json[r'tax_behavior'] = this.taxBehavior;
    return json;
  }

  /// Returns a new [FormattedPrice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FormattedPrice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FormattedPrice[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FormattedPrice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FormattedPrice(
        currency: mapValueOfType<String>(json, r'currency')!,
        unitAmount: mapValueOfType<int>(json, r'unit_amount')!,
        taxBehavior: mapValueOfType<String>(json, r'tax_behavior')!,
      );
    }
    return null;
  }

  static List<FormattedPrice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FormattedPrice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FormattedPrice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FormattedPrice> mapFromJson(dynamic json) {
    final map = <String, FormattedPrice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FormattedPrice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FormattedPrice-objects as value to a dart map
  static Map<String, List<FormattedPrice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FormattedPrice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FormattedPrice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'currency',
    'unit_amount',
    'tax_behavior',
  };
}

