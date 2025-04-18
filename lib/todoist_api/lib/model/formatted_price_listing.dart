//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class FormattedPriceListing {
  /// Returns a new [FormattedPriceListing] instance.
  FormattedPriceListing({
    required this.billingCycle,
    this.prices = const [],
  });

  FormattedPriceListingBillingCycleEnum billingCycle;

  List<FormattedPrice> prices;

  @override
  bool operator ==(Object other) => identical(this, other) || other is FormattedPriceListing &&
    other.billingCycle == billingCycle &&
    _deepEquality.equals(other.prices, prices);

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (billingCycle.hashCode) +
    (prices.hashCode);

  @override
  String toString() => 'FormattedPriceListing[billingCycle=$billingCycle, prices=$prices]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'billing_cycle'] = this.billingCycle;
      json[r'prices'] = this.prices;
    return json;
  }

  /// Returns a new [FormattedPriceListing] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static FormattedPriceListing? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "FormattedPriceListing[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "FormattedPriceListing[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return FormattedPriceListing(
        billingCycle: FormattedPriceListingBillingCycleEnum.fromJson(json[r'billing_cycle'])!,
        prices: FormattedPrice.listFromJson(json[r'prices']),
      );
    }
    return null;
  }

  static List<FormattedPriceListing> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FormattedPriceListing>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FormattedPriceListing.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, FormattedPriceListing> mapFromJson(dynamic json) {
    final map = <String, FormattedPriceListing>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = FormattedPriceListing.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of FormattedPriceListing-objects as value to a dart map
  static Map<String, List<FormattedPriceListing>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<FormattedPriceListing>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = FormattedPriceListing.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'billing_cycle',
    'prices',
  };
}


class FormattedPriceListingBillingCycleEnum {
  /// Instantiate a new enum with the provided [value].
  const FormattedPriceListingBillingCycleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const monthly = FormattedPriceListingBillingCycleEnum._(r'monthly');
  static const yearly = FormattedPriceListingBillingCycleEnum._(r'yearly');

  /// List of all possible values in this [enum][FormattedPriceListingBillingCycleEnum].
  static const values = <FormattedPriceListingBillingCycleEnum>[
    monthly,
    yearly,
  ];

  static FormattedPriceListingBillingCycleEnum? fromJson(dynamic value) => FormattedPriceListingBillingCycleEnumTypeTransformer().decode(value);

  static List<FormattedPriceListingBillingCycleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <FormattedPriceListingBillingCycleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = FormattedPriceListingBillingCycleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [FormattedPriceListingBillingCycleEnum] to String,
/// and [decode] dynamic data back to [FormattedPriceListingBillingCycleEnum].
class FormattedPriceListingBillingCycleEnumTypeTransformer {
  factory FormattedPriceListingBillingCycleEnumTypeTransformer() => _instance ??= const FormattedPriceListingBillingCycleEnumTypeTransformer._();

  const FormattedPriceListingBillingCycleEnumTypeTransformer._();

  String encode(FormattedPriceListingBillingCycleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a FormattedPriceListingBillingCycleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  FormattedPriceListingBillingCycleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'monthly': return FormattedPriceListingBillingCycleEnum.monthly;
        case r'yearly': return FormattedPriceListingBillingCycleEnum.yearly;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [FormattedPriceListingBillingCycleEnumTypeTransformer] instance.
  static FormattedPriceListingBillingCycleEnumTypeTransformer? _instance;
}


