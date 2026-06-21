import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/models/user_status.dart';
import 'package:ummah_pulse/features/community/providers/circles_provider.dart';
import 'package:ummah_pulse/features/community/providers/dua_provider.dart';
import 'package:ummah_pulse/features/community/screens/circle_detail_screen.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CircleDetailScreen', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        switch (call.method) {
          case 'Clipboard.setData':
            return null;
          case 'Clipboard.getData':
            return {'text': 'XYZ789'};
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('shows circle name, invite code, and member feed', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            circleProvider('circle-1').overrideWith(
              (ref) => Stream.value(
                testCircle(
                  id: 'circle-1',
                  name: 'Family',
                  members: ['uid-1', 'uid-2'],
                  inviteCode: 'ABC123',
                  groupStreak: 4,
                ),
              ),
            ),
            circleFeedProvider('circle-1').overrideWith(
              (ref) => Stream.value([
                testMemberFeed(
                  displayName: 'Yassin',
                  isCurrentUser: true,
                  entries: {
                    PrayerName.fajr: PrayerLogEntry.completed(PrayerName.fajr),
                    for (final p in PrayerName.values.where((p) => p != PrayerName.fajr))
                      p: PrayerLogEntry(prayerName: p),
                  },
                ),
                testMemberFeed(
                  uid: 'uid-2',
                  displayName: 'Ahmed',
                  isCurrentUser: false,
                  entries: {
                    PrayerName.fajr: PrayerLogEntry(
                      prayerName: PrayerName.fajr,
                      status: PrayerLogStatus.missed,
                    ),
                    for (final p in PrayerName.values.where((p) => p != PrayerName.fajr))
                      p: PrayerLogEntry(prayerName: p),
                  },
                ),
              ]),
            ),
          ],
          child: const CircleDetailScreen(circleId: 'circle-1'),
        ),
      );
      await tester.pump();

      expect(find.text('Family'), findsOneWidget);
      expect(find.textContaining('ABC123'), findsOneWidget);
      expect(find.textContaining('2 members'), findsOneWidget);
      expect(find.text('Group streak: 4 days'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.cancel), findsOneWidget);
    });

    testWidgets('invite code tap copies to clipboard', (tester) async {
      String? copiedText;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = call.arguments['text'] as String?;
          return null;
        }
        return null;
      });

      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            circleProvider('circle-1').overrideWith(
              (ref) => Stream.value(testCircle(inviteCode: 'XYZ789')),
            ),
            circleFeedProvider('circle-1').overrideWith(
              (ref) => Stream.value([testMemberFeed()]),
            ),
          ],
          child: const CircleDetailScreen(circleId: 'circle-1'),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.share_outlined));
      await tester.pump();

      expect(copiedText, 'XYZ789');
    });

    testWidgets('switches to Dua Board tab', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            circleProvider('circle-1').overrideWith(
              (ref) => Stream.value(testCircle()),
            ),
            circleFeedProvider('circle-1').overrideWith(
              (ref) => Stream.value([testMemberFeed()]),
            ),
            duaRequestsProvider('circle-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const CircleDetailScreen(circleId: 'circle-1'),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Dua Board'));
      await tester.pumpAndSettle();

      expect(find.text('No Dua requests yet'), findsOneWidget);
    });

    testWidgets('traveling member suppresses missed icon', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            circleProvider('circle-1').overrideWith(
              (ref) => Stream.value(testCircle()),
            ),
            circleFeedProvider('circle-1').overrideWith(
              (ref) => Stream.value([
                MemberPrayerFeed(
                  uid: 'uid-2',
                  displayName: 'Traveler',
                  isCurrentUser: false,
                  presenceStatus: UserPresenceStatus.traveling,
                  entries: {
                    PrayerName.fajr: PrayerLogEntry(
                      prayerName: PrayerName.fajr,
                      status: PrayerLogStatus.missed,
                    ),
                    for (final p in PrayerName.values.where((p) => p != PrayerName.fajr))
                      p: PrayerLogEntry(prayerName: p),
                  },
                ),
              ]),
            ),
          ],
          child: const CircleDetailScreen(circleId: 'circle-1'),
        ),
      );
      await tester.pump();

      expect(find.textContaining('Traveling'), findsWidgets);
      expect(find.byIcon(Icons.cancel), findsNothing);
    });
  });
}
