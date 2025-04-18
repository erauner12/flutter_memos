//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

class PlanDetailsResponse {
  /// Returns a new [PlanDetailsResponse] instance.
  PlanDetailsResponse({
    required this.currentMemberCount,
    required this.currentPlan,
    required this.currentPlanStatus,
    required this.downgradeAt,
    required this.currentActiveProjects,
    required this.maximumActiveProjects,
    this.priceList = const [],
    required this.workspaceId,
    required this.isTrialing,
    required this.trialEndsAt,
    required this.cancelAtPeriodEnd,
    required this.hasTrialed,
    required this.planPrice,
    required this.hasBillingPortal,
    required this.hasBillingPortalSwitchToAnnual,
  });

  int currentMemberCount;

  PlanDetailsResponseCurrentPlanEnum currentPlan;

  PlanDetailsResponseCurrentPlanStatusEnum currentPlanStatus;

  String? downgradeAt;

  int currentActiveProjects;

  int maximumActiveProjects;

  List<FormattedPriceListing> priceList;

  int workspaceId;

  bool isTrialing;

  String? trialEndsAt;

  bool cancelAtPeriodEnd;

  bool hasTrialed;

  PlanPrice? planPrice;

  bool hasBillingPortal;

  bool hasBillingPortalSwitchToAnnual;

  @override
  bool operator ==(Object other) => identical(this, other) || other is PlanDetailsResponse &&
    other.currentMemberCount == currentMemberCount &&
    other.currentPlan == currentPlan &&
    other.currentPlanStatus == currentPlanStatus &&
    other.downgradeAt == downgradeAt &&
    other.currentActiveProjects == currentActiveProjects &&
    other.maximumActiveProjects == maximumActiveProjects &&
    _deepEquality.equals(other.priceList, priceList) &&
    other.workspaceId == workspaceId &&
    other.isTrialing == isTrialing &&
    other.trialEndsAt == trialEndsAt &&
    other.cancelAtPeriodEnd == cancelAtPeriodEnd &&
    other.hasTrialed == hasTrialed &&
    other.planPrice == planPrice &&
    other.hasBillingPortal == hasBillingPortal &&
    other.hasBillingPortalSwitchToAnnual == hasBillingPortalSwitchToAnnual;

  @override
  int get hashCode =>
    // ignore: unnecessary_parenthesis
    (currentMemberCount.hashCode) +
    (currentPlan.hashCode) +
    (currentPlanStatus.hashCode) +
    (downgradeAt == null ? 0 : downgradeAt!.hashCode) +
    (currentActiveProjects.hashCode) +
    (maximumActiveProjects.hashCode) +
    (priceList.hashCode) +
    (workspaceId.hashCode) +
    (isTrialing.hashCode) +
    (trialEndsAt == null ? 0 : trialEndsAt!.hashCode) +
    (cancelAtPeriodEnd.hashCode) +
    (hasTrialed.hashCode) +
    (planPrice == null ? 0 : planPrice!.hashCode) +
    (hasBillingPortal.hashCode) +
    (hasBillingPortalSwitchToAnnual.hashCode);

  @override
  String toString() => 'PlanDetailsResponse[currentMemberCount=$currentMemberCount, currentPlan=$currentPlan, currentPlanStatus=$currentPlanStatus, downgradeAt=$downgradeAt, currentActiveProjects=$currentActiveProjects, maximumActiveProjects=$maximumActiveProjects, priceList=$priceList, workspaceId=$workspaceId, isTrialing=$isTrialing, trialEndsAt=$trialEndsAt, cancelAtPeriodEnd=$cancelAtPeriodEnd, hasTrialed=$hasTrialed, planPrice=$planPrice, hasBillingPortal=$hasBillingPortal, hasBillingPortalSwitchToAnnual=$hasBillingPortalSwitchToAnnual]';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
      json[r'current_member_count'] = this.currentMemberCount;
      json[r'current_plan'] = this.currentPlan;
      json[r'current_plan_status'] = this.currentPlanStatus;
    if (this.downgradeAt != null) {
      json[r'downgrade_at'] = this.downgradeAt;
    } else {
      json[r'downgrade_at'] = null;
    }
      json[r'current_active_projects'] = this.currentActiveProjects;
      json[r'maximum_active_projects'] = this.maximumActiveProjects;
      json[r'price_list'] = this.priceList;
      json[r'workspace_id'] = this.workspaceId;
      json[r'is_trialing'] = this.isTrialing;
    if (this.trialEndsAt != null) {
      json[r'trial_ends_at'] = this.trialEndsAt;
    } else {
      json[r'trial_ends_at'] = null;
    }
      json[r'cancel_at_period_end'] = this.cancelAtPeriodEnd;
      json[r'has_trialed'] = this.hasTrialed;
    if (this.planPrice != null) {
      json[r'plan_price'] = this.planPrice;
    } else {
      json[r'plan_price'] = null;
    }
      json[r'has_billing_portal'] = this.hasBillingPortal;
      json[r'has_billing_portal_switch_to_annual'] = this.hasBillingPortalSwitchToAnnual;
    return json;
  }

  /// Returns a new [PlanDetailsResponse] instance and imports its values from
  /// [value] if it's a [Map], null otherwise.
  // ignore: prefer_constructors_over_static_methods
  static PlanDetailsResponse? fromJson(dynamic value) {
    if (value is Map) {
      final json = value.cast<String, dynamic>();

      // Ensure that the map contains the required keys.
      // Note 1: the values aren't checked for validity beyond being non-null.
      // Note 2: this code is stripped in release mode!
      assert(() {
        requiredKeys.forEach((key) {
          assert(json.containsKey(key), 'Required key "PlanDetailsResponse[$key]" is missing from JSON.');
          assert(json[key] != null, 'Required key "PlanDetailsResponse[$key]" has a null value in JSON.');
        });
        return true;
      }());

      return PlanDetailsResponse(
        currentMemberCount: mapValueOfType<int>(json, r'current_member_count')!,
        currentPlan: PlanDetailsResponseCurrentPlanEnum.fromJson(json[r'current_plan'])!,
        currentPlanStatus: PlanDetailsResponseCurrentPlanStatusEnum.fromJson(json[r'current_plan_status'])!,
        downgradeAt: mapValueOfType<String>(json, r'downgrade_at'),
        currentActiveProjects: mapValueOfType<int>(json, r'current_active_projects')!,
        maximumActiveProjects: mapValueOfType<int>(json, r'maximum_active_projects')!,
        priceList: FormattedPriceListing.listFromJson(json[r'price_list']),
        workspaceId: mapValueOfType<int>(json, r'workspace_id')!,
        isTrialing: mapValueOfType<bool>(json, r'is_trialing')!,
        trialEndsAt: mapValueOfType<String>(json, r'trial_ends_at'),
        cancelAtPeriodEnd: mapValueOfType<bool>(json, r'cancel_at_period_end')!,
        hasTrialed: mapValueOfType<bool>(json, r'has_trialed')!,
        planPrice: PlanPrice.fromJson(json[r'plan_price']),
        hasBillingPortal: mapValueOfType<bool>(json, r'has_billing_portal')!,
        hasBillingPortalSwitchToAnnual: mapValueOfType<bool>(json, r'has_billing_portal_switch_to_annual')!,
      );
    }
    return null;
  }

  static List<PlanDetailsResponse> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanDetailsResponse>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanDetailsResponse.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }

  static Map<String, PlanDetailsResponse> mapFromJson(dynamic json) {
    final map = <String, PlanDetailsResponse>{};
    if (json is Map && json.isNotEmpty) {
      json = json.cast<String, dynamic>(); // ignore: parameter_assignments
      for (final entry in json.entries) {
        final value = PlanDetailsResponse.fromJson(entry.value);
        if (value != null) {
          map[entry.key] = value;
        }
      }
    }
    return map;
  }

  // maps a json object with a list of PlanDetailsResponse-objects as value to a dart map
  static Map<String, List<PlanDetailsResponse>> mapListFromJson(dynamic json, {bool growable = false,}) {
    final map = <String, List<PlanDetailsResponse>>{};
    if (json is Map && json.isNotEmpty) {
      // ignore: parameter_assignments
      json = json.cast<String, dynamic>();
      for (final entry in json.entries) {
        map[entry.key] = PlanDetailsResponse.listFromJson(entry.value, growable: growable,);
      }
    }
    return map;
  }

  /// The list of required keys that must be present in a JSON.
  static const requiredKeys = <String>{
    'current_member_count',
    'current_plan',
    'current_plan_status',
    'downgrade_at',
    'current_active_projects',
    'maximum_active_projects',
    'price_list',
    'workspace_id',
    'is_trialing',
    'trial_ends_at',
    'cancel_at_period_end',
    'has_trialed',
    'plan_price',
    'has_billing_portal',
    'has_billing_portal_switch_to_annual',
  };
}


class PlanDetailsResponseCurrentPlanEnum {
  /// Instantiate a new enum with the provided [value].
  const PlanDetailsResponseCurrentPlanEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const business = PlanDetailsResponseCurrentPlanEnum._(r'Business');
  static const starter = PlanDetailsResponseCurrentPlanEnum._(r'Starter');

  /// List of all possible values in this [enum][PlanDetailsResponseCurrentPlanEnum].
  static const values = <PlanDetailsResponseCurrentPlanEnum>[
    business,
    starter,
  ];

  static PlanDetailsResponseCurrentPlanEnum? fromJson(dynamic value) => PlanDetailsResponseCurrentPlanEnumTypeTransformer().decode(value);

  static List<PlanDetailsResponseCurrentPlanEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanDetailsResponseCurrentPlanEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanDetailsResponseCurrentPlanEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlanDetailsResponseCurrentPlanEnum] to String,
/// and [decode] dynamic data back to [PlanDetailsResponseCurrentPlanEnum].
class PlanDetailsResponseCurrentPlanEnumTypeTransformer {
  factory PlanDetailsResponseCurrentPlanEnumTypeTransformer() => _instance ??= const PlanDetailsResponseCurrentPlanEnumTypeTransformer._();

  const PlanDetailsResponseCurrentPlanEnumTypeTransformer._();

  String encode(PlanDetailsResponseCurrentPlanEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PlanDetailsResponseCurrentPlanEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlanDetailsResponseCurrentPlanEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'Business': return PlanDetailsResponseCurrentPlanEnum.business;
        case r'Starter': return PlanDetailsResponseCurrentPlanEnum.starter;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PlanDetailsResponseCurrentPlanEnumTypeTransformer] instance.
  static PlanDetailsResponseCurrentPlanEnumTypeTransformer? _instance;
}



class PlanDetailsResponseCurrentPlanStatusEnum {
  /// Instantiate a new enum with the provided [value].
  const PlanDetailsResponseCurrentPlanStatusEnum._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const active = PlanDetailsResponseCurrentPlanStatusEnum._(r'Active');
  static const downgraded = PlanDetailsResponseCurrentPlanStatusEnum._(r'Downgraded');
  static const cancelled = PlanDetailsResponseCurrentPlanStatusEnum._(r'Cancelled');
  static const neverSubscribed = PlanDetailsResponseCurrentPlanStatusEnum._(r'NeverSubscribed');

  /// List of all possible values in this [enum][PlanDetailsResponseCurrentPlanStatusEnum].
  static const values = <PlanDetailsResponseCurrentPlanStatusEnum>[
    active,
    downgraded,
    cancelled,
    neverSubscribed,
  ];

  static PlanDetailsResponseCurrentPlanStatusEnum? fromJson(dynamic value) => PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer().decode(value);

  static List<PlanDetailsResponseCurrentPlanStatusEnum> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <PlanDetailsResponseCurrentPlanStatusEnum>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = PlanDetailsResponseCurrentPlanStatusEnum.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [PlanDetailsResponseCurrentPlanStatusEnum] to String,
/// and [decode] dynamic data back to [PlanDetailsResponseCurrentPlanStatusEnum].
class PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer {
  factory PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer() => _instance ??= const PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer._();

  const PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer._();

  String encode(PlanDetailsResponseCurrentPlanStatusEnum data) => data.value;

  /// Decodes a [dynamic value][data] to a PlanDetailsResponseCurrentPlanStatusEnum.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  PlanDetailsResponseCurrentPlanStatusEnum? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'Active': return PlanDetailsResponseCurrentPlanStatusEnum.active;
        case r'Downgraded': return PlanDetailsResponseCurrentPlanStatusEnum.downgraded;
        case r'Cancelled': return PlanDetailsResponseCurrentPlanStatusEnum.cancelled;
        case r'NeverSubscribed': return PlanDetailsResponseCurrentPlanStatusEnum.neverSubscribed;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer] instance.
  static PlanDetailsResponseCurrentPlanStatusEnumTypeTransformer? _instance;
}


