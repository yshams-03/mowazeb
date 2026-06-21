import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeId {
  dawnWarrior('dawn_warrior'),
  dawnWarrior30('dawn_warrior_30'),
  perfectWeek('perfect_week'),
  earlyBird('early_bird'),
  nightOwl('night_owl'),
  circleChampion('circle_champion');

  const BadgeId(this.value);
  final String value;

  static BadgeId? parse(String? raw) {
    if (raw == null) return null;
    for (final badge in BadgeId.values) {
      if (badge.value == raw) return badge;
    }
    return null;
  }
}

class BadgeDefinition {
  const BadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.iconName,
  });

  final BadgeId id;
  final String title;
  final String description;
  final String iconName;

  static const all = [
    BadgeDefinition(
      id: BadgeId.dawnWarrior,
      title: 'Dawn Warrior',
      description: '7 consecutive Fajr prayers on time',
      iconName: 'wb_sunny',
    ),
    BadgeDefinition(
      id: BadgeId.dawnWarrior30,
      title: '30-Day Dawn Warrior',
      description: '30 consecutive Fajr prayers on time',
      iconName: 'brightness_7',
    ),
    BadgeDefinition(
      id: BadgeId.perfectWeek,
      title: 'Perfect Week',
      description: 'All 5 prayers on time for 7 days straight',
      iconName: 'emoji_events',
    ),
    BadgeDefinition(
      id: BadgeId.earlyBird,
      title: 'Early Bird',
      description: 'Fajr within 15 min of adhan for 10 days',
      iconName: 'alarm',
    ),
    BadgeDefinition(
      id: BadgeId.nightOwl,
      title: 'Night Owl',
      description: 'Isha within 15 min of adhan for 10 days',
      iconName: 'nightlight',
    ),
    BadgeDefinition(
      id: BadgeId.circleChampion,
      title: 'Circle Champion',
      description: 'Your circle reached a 7-day group streak',
      iconName: 'groups',
    ),
  ];

  static BadgeDefinition? byId(BadgeId id) {
    for (final badge in all) {
      if (badge.id == id) return badge;
    }
    return null;
  }
}

class UserBadge {
  const UserBadge({
    required this.badgeId,
    required this.unlockedAt,
  });

  final BadgeId badgeId;
  final DateTime unlockedAt;

  factory UserBadge.fromFirestore(String id, Map<String, dynamic> data) {
    final unlockedRaw = data['unlockedAt'];
    DateTime unlockedAt = DateTime.now();
    if (unlockedRaw is Timestamp) {
      unlockedAt = unlockedRaw.toDate();
    }

    return UserBadge(
      badgeId: BadgeId.parse(id) ?? BadgeId.dawnWarrior,
      unlockedAt: unlockedAt,
    );
  }
}
