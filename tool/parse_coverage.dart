import 'dart:io';

void main() {
  final text = File('coverage/lcov.info').readAsStringSync();
  const names = [
    'prayer_provider.dart',
    'onboarding_provider.dart',
    'commute_provider.dart',
    'circles_provider.dart',
    'map_picker_screen.dart',
    'qibla_screen.dart',
    'notification_service.dart',
    'aladhan_service.dart',
    'aladhan_sync_service.dart',
    'home_widget_service.dart',
  ];
  for (final name in names) {
    final re = RegExp('SF:.*${RegExp.escape(name)}\\n(.*?)end_of_record', dotAll: true);
    final m = re.firstMatch(text);
    if (m == null) {
      stdout.writeln('$name: NOT FOUND');
      continue;
    }
    final da = RegExp(r'DA:(\d+),(\d+)').allMatches(m.group(1)!);
    var hit = 0;
    var total = 0;
    for (final x in da) {
      total++;
      if (int.parse(x.group(2)!) > 0) hit++;
    }
    stdout.writeln('$name: $hit/$total (${(100 * hit / total).toStringAsFixed(1)}%)');
  }
  final all = RegExp(r'DA:(\d+),(\d+)').allMatches(text);
  var th = 0;
  var tl = 0;
  for (final x in all) {
    tl++;
    if (int.parse(x.group(2)!) > 0) th++;
  }
  stdout.writeln('OVERALL: $th/$tl (${(100 * th / tl).toStringAsFixed(1)}%)');
}
