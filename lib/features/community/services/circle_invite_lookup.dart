import 'package:cloud_firestore/cloud_firestore.dart';

/// Maps invite codes to circle IDs so join/create lookups don't require
/// querying the circles collection (blocked by member-only read rules).
class CircleInviteLookup {
  CircleInviteLookup._();

  static String docPath(String inviteCode) => 'circle_lookup/${inviteCode.toUpperCase()}';

  static Map<String, dynamic> toFirestore({
    required String circleId,
    required String createdBy,
  }) {
    return {
      'circleId': circleId,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  static String? circleIdFrom(Map<String, dynamic>? data) {
    return data?['circleId'] as String?;
  }
}
