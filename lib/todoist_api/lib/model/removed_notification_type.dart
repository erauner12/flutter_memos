//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

part of openapi.api;

/// A set of legacy NotificationType values that have been removed from the mailers and database, but are still referenced by clients therefore we have to maintain the contract.  Ensures we still send down the keys without needing to maintain the associated mailer code and database values.
class RemovedNotificationType {
  /// Instantiate a new enum with the provided [value].
  const RemovedNotificationType._(this.value);

  /// The underlying value of this enum member.
  final String value;

  @override
  String toString() => value;

  String toJson() => value;

  static const bizTrialEnterCc = RemovedNotificationType._(r'biz_trial_enter_cc');
  static const bizTrialWillEnd = RemovedNotificationType._(r'biz_trial_will_end');
  static const bizPaymentFailed = RemovedNotificationType._(r'biz_payment_failed');
  static const bizAccountDisabled = RemovedNotificationType._(r'biz_account_disabled');
  static const bizInvitationCreated = RemovedNotificationType._(r'biz_invitation_created');
  static const bizInvitationAccepted = RemovedNotificationType._(r'biz_invitation_accepted');
  static const bizInvitationRejected = RemovedNotificationType._(r'biz_invitation_rejected');
  static const bizPolicyDisallowedInvitation = RemovedNotificationType._(r'biz_policy_disallowed_invitation');
  static const bizPolicyRejectedInvitation = RemovedNotificationType._(r'biz_policy_rejected_invitation');

  /// List of all possible values in this [enum][RemovedNotificationType].
  static const values = <RemovedNotificationType>[
    bizTrialEnterCc,
    bizTrialWillEnd,
    bizPaymentFailed,
    bizAccountDisabled,
    bizInvitationCreated,
    bizInvitationAccepted,
    bizInvitationRejected,
    bizPolicyDisallowedInvitation,
    bizPolicyRejectedInvitation,
  ];

  static RemovedNotificationType? fromJson(dynamic value) => RemovedNotificationTypeTypeTransformer().decode(value);

  static List<RemovedNotificationType> listFromJson(dynamic json, {bool growable = false,}) {
    final result = <RemovedNotificationType>[];
    if (json is List && json.isNotEmpty) {
      for (final row in json) {
        final value = RemovedNotificationType.fromJson(row);
        if (value != null) {
          result.add(value);
        }
      }
    }
    return result.toList(growable: growable);
  }
}

/// Transformation class that can [encode] an instance of [RemovedNotificationType] to String,
/// and [decode] dynamic data back to [RemovedNotificationType].
class RemovedNotificationTypeTypeTransformer {
  factory RemovedNotificationTypeTypeTransformer() => _instance ??= const RemovedNotificationTypeTypeTransformer._();

  const RemovedNotificationTypeTypeTransformer._();

  String encode(RemovedNotificationType data) => data.value;

  /// Decodes a [dynamic value][data] to a RemovedNotificationType.
  ///
  /// If [allowNull] is true and the [dynamic value][data] cannot be decoded successfully,
  /// then null is returned. However, if [allowNull] is false and the [dynamic value][data]
  /// cannot be decoded successfully, then an [UnimplementedError] is thrown.
  ///
  /// The [allowNull] is very handy when an API changes and a new enum value is added or removed,
  /// and users are still using an old app with the old code.
  RemovedNotificationType? decode(dynamic data, {bool allowNull = true}) {
    if (data != null) {
      switch (data) {
        case r'biz_trial_enter_cc': return RemovedNotificationType.bizTrialEnterCc;
        case r'biz_trial_will_end': return RemovedNotificationType.bizTrialWillEnd;
        case r'biz_payment_failed': return RemovedNotificationType.bizPaymentFailed;
        case r'biz_account_disabled': return RemovedNotificationType.bizAccountDisabled;
        case r'biz_invitation_created': return RemovedNotificationType.bizInvitationCreated;
        case r'biz_invitation_accepted': return RemovedNotificationType.bizInvitationAccepted;
        case r'biz_invitation_rejected': return RemovedNotificationType.bizInvitationRejected;
        case r'biz_policy_disallowed_invitation': return RemovedNotificationType.bizPolicyDisallowedInvitation;
        case r'biz_policy_rejected_invitation': return RemovedNotificationType.bizPolicyRejectedInvitation;
        default:
          if (!allowNull) {
            throw ArgumentError('Unknown enum value to decode: $data');
          }
      }
    }
    return null;
  }

  /// Singleton [RemovedNotificationTypeTypeTransformer] instance.
  static RemovedNotificationTypeTypeTransformer? _instance;
}

