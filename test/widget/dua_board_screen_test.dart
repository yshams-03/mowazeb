import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/dua_request.dart';
import 'package:ummah_pulse/features/community/providers/dua_provider.dart';
import 'package:ummah_pulse/features/community/screens/dua_board_screen.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('DuaBoardScreen', () {
    DuaRequest testRequest({
      String id = 'req-1',
      String authorUid = 'uid-author',
      List<String> duaSenders = const [],
    }) {
      return DuaRequest(
        id: id,
        authorUid: authorUid,
        authorName: 'Ahmed',
        message: 'Exams tomorrow',
        createdAt: DateTime(2026, 6, 21, 10, 0),
        duaSenders: duaSenders,
      );
    }

    testWidgets('empty state message', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            duaRequestsProvider('circle-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const Scaffold(body: DuaBoardScreen(circleId: 'circle-1')),
        ),
      );
      await tester.pump();

      expect(find.text('No Dua requests yet'), findsOneWidget);
    });

    testWidgets('lists requests with make dua button', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(
              MockFirebaseAuth(
                mockUser: MockUser(uid: 'uid-member'),
                signedIn: true,
              ),
            ),
            duaRequestsProvider('circle-1').overrideWith(
              (ref) => Stream.value([testRequest()]),
            ),
          ],
          child: const Scaffold(body: DuaBoardScreen(circleId: 'circle-1')),
        ),
      );
      await tester.pump();

      expect(find.text('Ahmed'), findsOneWidget);
      expect(find.text('Exams tomorrow'), findsOneWidget);
      expect(find.text('🤲 Make Dua'), findsOneWidget);
    });

    testWidgets('already sent dua shows disabled label', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firebaseAuthProvider.overrideWithValue(
              MockFirebaseAuth(
                mockUser: MockUser(uid: 'uid-member'),
                signedIn: true,
              ),
            ),
            duaRequestsProvider('circle-1').overrideWith(
              (ref) => Stream.value([
                testRequest(duaSenders: ['uid-member']),
              ]),
            ),
          ],
          child: const Scaffold(body: DuaBoardScreen(circleId: 'circle-1')),
        ),
      );
      await tester.pump();

      expect(find.text('Dua Sent ✓'), findsOneWidget);
    });

    testWidgets('FAB opens post request sheet', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            duaRequestsProvider('circle-1').overrideWith(
              (ref) => Stream.value(const []),
            ),
          ],
          child: const Scaffold(body: DuaBoardScreen(circleId: 'circle-1')),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Post Request'));
      await tester.pumpAndSettle();

      expect(find.text('Post Dua Request'), findsOneWidget);
    });
  });
}
