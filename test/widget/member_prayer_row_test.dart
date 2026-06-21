import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/community/models/prayer_log_entry.dart';
import 'package:ummah_pulse/features/community/providers/prayer_log_provider.dart';
import 'package:ummah_pulse/features/community/widgets/member_prayer_row.dart';
import 'package:ummah_pulse/features/prayer/models/prayer_time_model.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('MemberPrayerRow', () {
    testWidgets('renders member name and prayer icons', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: MemberPrayerRow(
            feed: testMemberFeed(displayName: 'Ahmed', isCurrentUser: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsWidgets);
    });

    testWidgets('current user can check off pending prayer', (tester) async {
      var checkedPrayer = PrayerName.fajr;

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            prayerLogActionsProvider.overrideWith(
              (ref) => _RecordingPrayerLogActions(
                onCheckOff: (prayer) => checkedPrayer = prayer,
              ),
            ),
            todayPrayerLogsOverride(const {}),
          ],
          child: MemberPrayerRow(
            feed: testMemberFeed(displayName: 'You', isCurrentUser: true),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.radio_button_unchecked).first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(checkedPrayer, PrayerName.fajr);
    });

    testWidgets('shows completed icon for checked prayers', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          child: MemberPrayerRow(
            feed: testMemberFeed(
              entries: {
                PrayerName.fajr: PrayerLogEntry.completed(PrayerName.fajr),
                for (final prayer in PrayerName.values.where((p) => p != PrayerName.fajr))
                  prayer: PrayerLogEntry(prayerName: prayer),
              },
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}

class _RecordingPrayerLogActions extends PrayerLogActions {
  _RecordingPrayerLogActions({required void Function(PrayerName prayer) onCheckOff})
      : _onCheckOff = onCheckOff,
        super(FakeFirebaseFirestore(), MockFirebaseAuth());

  final void Function(PrayerName prayer) _onCheckOff;

  @override
  Future<void> checkOff(PrayerName prayer) async {
    _onCheckOff(prayer);
  }
}
