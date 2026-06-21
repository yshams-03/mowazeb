import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/analytics/models/badge_model.dart';

void main() {
  group('BadgeId', () {
    test('parse returns matching badge id', () {
      expect(BadgeId.parse('dawn_warrior'), BadgeId.dawnWarrior);
      expect(BadgeId.parse('circle_champion'), BadgeId.circleChampion);
    });

    test('parse returns null for unknown or missing values', () {
      expect(BadgeId.parse(null), isNull);
      expect(BadgeId.parse('unknown_badge'), isNull);
    });
  });

  group('BadgeDefinition', () {
    test('byId returns the expected definition', () {
      final definition = BadgeDefinition.byId(BadgeId.perfectWeek);

      expect(definition, isNotNull);
      expect(definition!.title, 'Perfect Week');
      expect(definition.iconName, 'emoji_events');
    });
  });

  group('UserBadge', () {
    test('fromFirestore parses unlocked timestamp', () {
      final unlockedAt = DateTime(2026, 6, 21, 8, 30);

      final badge = UserBadge.fromFirestore('night_owl', {
        'unlockedAt': Timestamp.fromDate(unlockedAt),
      });

      expect(badge.badgeId, BadgeId.nightOwl);
      expect(badge.unlockedAt, unlockedAt);
    });

    test('fromFirestore falls back to dawnWarrior for unknown ids', () {
      final badge = UserBadge.fromFirestore('not_real', const {});

      expect(badge.badgeId, BadgeId.dawnWarrior);
    });
  });
}
