import 'dart:io';

void main() {
  final text = File('coverage/lcov.info').readAsStringSync();
  final records = text.split('end_of_record');
  final gaps = <Map<String, dynamic>>[];

  for (final r in records) {
    final sf = RegExp(r'SF:(.+)').firstMatch(r);
    if (sf == null || !sf.group(1)!.contains(r'lib\')) continue;
    final path = sf.group(1)!;
    if (path.contains('l10n') || path.contains('.g.dart')) continue;

    final das = RegExp(r'DA:(\d+),(\d+)').allMatches(r);
    var hit = 0;
    var total = 0;
    var miss = 0;
    for (final d in das) {
      total++;
      if (int.parse(d.group(2)!) > 0) {
        hit++;
      } else {
        miss++;
      }
    }
    if (total == 0) continue;
    final pct = 100 * hit / total;
    if (pct < 80) {
      gaps.add({
        'path': path.split(r'lib\').last,
        'hit': hit,
        'total': total,
        'miss': miss,
        'pct': pct,
      });
    }
  }

  gaps.sort((a, b) => (b['miss'] as int).compareTo(a['miss'] as int));
  for (final g in gaps.take(25)) {
    stdout.writeln(
      '${(g['miss'] as int).toString().padLeft(4)} miss  '
      '${(g['pct'] as double).toStringAsFixed(1).padLeft(5)}%  '
      '${g['path']}',
    );
  }

  var th = 0;
  var tl = 0;
  for (final x in RegExp(r'DA:(\d+),(\d+)').allMatches(text)) {
    tl++;
    if (int.parse(x.group(2)!) > 0) th++;
  }
  stdout.writeln('---');
  stdout.writeln('OVERALL: $th/$tl (${(100 * th / tl).toStringAsFixed(1)}%)');
  stdout.writeln('Need ${((0.8 * tl).ceil() - th).clamp(0, 9999)} more hits for 80%');
}
