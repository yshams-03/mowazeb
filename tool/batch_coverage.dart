import 'dart:io';

void main() {
  final text = File('coverage/lcov.info').readAsStringSync();
  const files = [
    'qibla_screen.dart',
    'circles_provider.dart',
    'auth_provider.dart',
    'onboarding_provider.dart',
    'locations_provider.dart',
    'places_screen.dart',
    'commute_screen.dart',
    'profile_screen.dart',
    'settings_screen.dart',
  ];
  for (final name in files) {
    final re = RegExp('SF:.*${RegExp.escape(name)}\\n(.*?)end_of_record', dotAll: true);
    final m = re.firstMatch(text);
    if (m == null) {
      stdout.writeln('$name: NOT FOUND');
      continue;
    }
    var hit = 0;
    var total = 0;
    for (final x in RegExp(r'DA:(\d+),(\d+)').allMatches(m.group(1)!)) {
      total++;
      if (int.parse(x.group(2)!) > 0) hit++;
    }
    stdout.writeln('$name: $hit/$total (${(100 * hit / total).toStringAsFixed(1)}%)');
  }
}
