import 'package:cloud_firestore/cloud_firestore.dart';

class DuaRequest {
  const DuaRequest({
    required this.id,
    required this.authorUid,
    required this.authorName,
    required this.message,
    required this.createdAt,
    this.duaSenders = const [],
  });

  final String id;
  final String authorUid;
  final String authorName;
  final String message;
  final DateTime createdAt;
  final List<String> duaSenders;

  factory DuaRequest.fromFirestore(String id, Map<String, dynamic> data) {
    final createdRaw = data['createdAt'];
    DateTime createdAt = DateTime.now();
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }

    return DuaRequest(
      id: id,
      authorUid: data['authorUid'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'Member',
      message: data['message'] as String? ?? '',
      createdAt: createdAt,
      duaSenders: List<String>.from(data['duaSenders'] as List? ?? const []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'authorUid': authorUid,
      'authorName': authorName,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'duaSenders': duaSenders,
    };
  }

  bool hasSentDua(String uid) => duaSenders.contains(uid);
}
