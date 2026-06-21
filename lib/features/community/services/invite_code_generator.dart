import 'dart:math';

/// Generates a 6-character invite code (uppercase letters + digits, no O/0/I/1).
class InviteCodeGenerator {
  InviteCodeGenerator._();

  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  static final _random = Random.secure();

  static String generate() {
    return List.generate(6, (_) => _chars[_random.nextInt(_chars.length)]).join();
  }
}
