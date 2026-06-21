import 'package:ummah_pulse/features/community/services/invite_code_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InviteCodeGenerator', () {
    test('generates 6 character code', () {
      final code = InviteCodeGenerator.generate();
      expect(code.length, 6);
    });

    test('uses allowed characters only', () {
      for (var i = 0; i < 20; i++) {
        final code = InviteCodeGenerator.generate();
        expect(RegExp(r'^[ABCDEFGHJKLMNPQRSTUVWXYZ23456789]+$').hasMatch(code), isTrue);
      }
    });
  });
}
