import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ummah_pulse/features/auth/providers/auth_provider.dart';
import 'package:ummah_pulse/features/community/models/user_status.dart';
import 'package:ummah_pulse/features/community/providers/status_provider.dart';
import 'package:ummah_pulse/features/community/screens/create_circle_screen.dart';
import 'package:ummah_pulse/features/community/screens/dua_board_screen.dart';
import 'package:ummah_pulse/features/community/screens/join_circle_screen.dart';
import 'package:ummah_pulse/features/community/widgets/post_dua_sheet.dart';
import 'package:ummah_pulse/features/community/widgets/status_toggle.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('CreateCircleScreen', () {
    testWidgets('create button does nothing with empty name', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-create'),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: const CreateCircleScreen(),
        ),
      );
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, 'Create Circle'));
      await tester.pump();

      expect(find.text('Circle created!'), findsNothing);
      expect(find.text('Give your circle a name'), findsOneWidget);
    });

    testWidgets('creates circle and shows invite code', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-create'),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: const CreateCircleScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Family');
      await tester.tap(find.widgetWithText(FilledButton, 'Create Circle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Circle created!'), findsOneWidget);
      expect(find.text('Copy code'), findsOneWidget);
    });
  });

  group('JoinCircleScreen', () {
    testWidgets('join button disabled for short code', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          child: const JoinCircleScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'AB');
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Join Circle'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows error snackbar for invalid code', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'uid-join'),
        signedIn: true,
      );

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
            firebaseAuthProvider.overrideWithValue(auth),
          ],
          child: const JoinCircleScreen(),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'BADBAD');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Join Circle'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Invalid invite code. Check and try again.'),
        findsOneWidget,
      );
    });
  });

  group('StatusToggle', () {
    testWidgets('shows all four status chips', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            currentUserStatusProvider.overrideWith(
              (ref) => Stream.value(const UserStatus()),
            ),
          ],
          child: const Scaffold(body: StatusToggle()),
        ),
      );
      await tester.pump();

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('✈️ Traveling'), findsOneWidget);
      expect(find.text('🤲 Excused'), findsOneWidget);
      expect(find.text('📚 In Exam'), findsOneWidget);
    });
  });

  group('PostDuaSheet', () {
    testWidgets('post button disabled when message empty', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          child: const Scaffold(
            body: PostDuaSheet(circleId: 'circle1'),
          ),
        ),
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post Request'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('post button enabled when message entered', (tester) async {
      setLargeScreen(tester);
      await tester.pumpWidget(
        buildTestApp(
          child: const Scaffold(
            body: PostDuaSheet(circleId: 'circle1'),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byType(TextField),
        'Please make Dua for my exam',
      );
      await tester.pump();

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Post Request'),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  group('DuaBoardScreen', () {
    testWidgets('shows empty state when no requests', (tester) async {
      setLargeScreen(tester);
      final firestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            firestoreProvider.overrideWithValue(firestore),
          ],
          child: const DuaBoardScreen(circleId: 'circle1'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No Dua requests yet'), findsOneWidget);
      expect(find.text('Post Request'), findsOneWidget);
    });
  });
}
