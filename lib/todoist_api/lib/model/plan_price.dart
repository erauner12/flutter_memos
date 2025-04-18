//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlanPrice {
  /// Returns a new [PlanPrice] instance.
  PlanPrice({
    required this.amount,
    required this.currency,
    required this.billingCycle,
    required this.taxBehavior,
  });

  String amount;

  String currency;

  PlanPriceBillingCycleEnum? billingCycle;

  String taxBehavior;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlanPrice &&
    other.amount == amount &&
    other.currency == currency &&
    other.billingCycle == billingCycle &&
    other.taxBehavior == taxBehavior;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (amount.hashCode) +
    (currency.hashCode) +
    (billingCycle == null ? 0 : billingCycle!.hashCode) +
    (taxBehavior.hashCode);

  @override
  String toString() => 'PlanPrice[amount=$amount, currency=$currency, billingCycle=$billingCycle, taxBehavior=$taxBehavior]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'amount'] = this.amount;
      json[r'currency'] = this.currency;
    if (this.billingCycle != null) {
      json[r'billing_cycle'] = this.billingCycle;
    } else {
      json[r'billing_cycle'] = null;
    }
      json[r'tax_behavior'] = this.taxBehavior;
    return json;
  }

  /// Returns a new [PlanPrice] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlanPrice? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PlanPrice[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PlanPrice[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PlanPrice(
        amount: mapValueOfType<String>(json, r'amount')!,
        currency: mapValueOfType<String>(json, r'currency')!,
        billingCycle: PlanPriceBillingCycleEnum.fromJson(json[r'billing_cycle']),
        taxBehavior: mapValueOfType<String>(json, r'tax_behavior')!,
      );
    }
    return null;
  }

  static List<PlanPrice> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanPrice>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanPrice.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlanPrice> mapFromJson(dynamic json) {
    final map = <String, PlanPrice>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlanPrice.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlanPrice-objects as value to a dart map
  static Map<String, List<PlanPrice>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlanPrice>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlanPrice.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'amount',
    'currency',
    'billing_cycle',
    'tax_behavior',
  };
}


class PlanPriceBillingCycleEnum {
  /// Instantiate a new enum with the provided [value].
  const PlanPriceBillingCycleEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const monthly = PlanPriceBillingCycleEnum._(r'monthly');
  static const yearly = PlanPriceBillingCycleEnum._(r'yearly');

  /// List of all possible values in this [enum][PlanPriceBillingCycleEnum].
  static const values = <PlanPriceBillingCycleEnum>[
    monthly,
    yearly,
  ];

  static PlanPriceBillingCycleEnum? fromJson(dynamic value) => PlanPriceBillingCycleEnumTypeTransformer().decode(value);

  static List<PlanPriceBillingCycleEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanPriceBillingCycleEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanPriceBillingCycleEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlanPriceBillingCycleEnum] to String,
/// and [decode] dynamic data back to [PlanPriceBillingCycleEnum].
class PlanPriceBillingCycleEnumTypeTransformer {
  factory PlanPriceBillingCycleEnumTypeTransformer() => _instance ??= const PlanPriceBillingCycleEnumTypeTransformer._();

  const PlanPriceBillingCycleEnumTypeTransformer._();

  String encode(PlanPriceBillingCycleEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PlanPriceBillingCycleEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlanPriceBillingCycleEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'monthly': return PlanPriceBillingCycleEnum.monthly;
        case r'yearly': return PlanPriceBillingCycleEnum.yearly;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PlanPriceBillingCycleEnumTypeTransformer] instance.
  static PlanPriceBillingCycleEnumTypeTransformer? _instance;
}


