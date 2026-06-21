import 'package:cloud_firestore/cloud_firestore.dart';

class AccountabilityCircle {
  const AccountabilityCircle({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.members,
    required this.inviteCode,
    this.groupStreak = 0,
  });

  final String id;
  final String name;
  final String createdBy;
  final List<String> members;
  final String inviteCode;
  final int groupStreak;

  factory AccountabilityCircle.fromFirestore(String id, Map<String, dynamic> data) {
    return AccountabilityCircle(
      id: id,
      name: data['name'] as String? ?? 'Circle',
      createdBy: data['createdBy'] as String? ?? '',
      members: List<String>.from(data['members'] as List? ?? const []),
      inviteCode: data['inviteCode'] as String? ?? '',
      groupStreak: data['groupStreak'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'createdBy': createdBy,
      'members': members,
      'inviteCode': inviteCode,
      'groupStreak': groupStreak,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  AccountabilityCircle copyWith({
    String? name,
    List<String>? members,
    int? groupStreak,
  }) {
    return AccountabilityCircle(
      id: id,
      name: name ?? this.name,
      createdBy: createdBy,
      members: members ?? this.members,
      inviteCode: inviteCode,
      groupStreak: groupStreak ?? this.groupStreak,
    );
  }
}
