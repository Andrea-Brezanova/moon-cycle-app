// A tightly capped, manual probe of the Recipe API *evaluation* account, to
// compare real responses with the adapter's documentation-based assumptions.
//
// SECURITY
//   - The key is read from the RECIPE_API_KEY environment variable or from the
//     file ~/.moon-cycle/recipe_api_key (chmod 600). It is never printed, never
//     put on a command line, and never written to a capture.
//   - Captures go to tool/captures/ (git-ignored).
//
// QUOTA PROTECTION (the evaluation plan has 50 full recipes, lifetime)
//   - A local counter (.recipeapi_usage.json, git-ignored) records every request.
//   - Free calls (ingredient and recipe search) are capped per run (--max-free,
//     default 12, never above 30).
//   - Paid calls (a full recipe) need --details N (default 0, never above 8) and
//     the file must say how many paid calls were already used: the probe refuses
//     once 40 of the 50 are spent, keeping 10 in reserve.
//
//   dart run tool/recipe_api_probe.dart --foods chickpea,spinach --details 2
import 'dart:convert';
import 'dart:io';

const _base = 'https://recipe-api.com/api/v1';
const _usageFile = '.recipeapi_usage.json';
const _paidLifetimeLimit = 40;

Future<void> main(List<String> args) async {
  String arg(String name, String fallback) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback;
  }

  final foods = arg(
    'foods',
    'chickpea',
  ).split(',').map((s) => s.trim()).toList();
  final maxFree = (int.tryParse(arg('max-free', '12')) ?? 12).clamp(1, 30);
  final details = (int.tryParse(arg('details', '0')) ?? 0).clamp(0, 8);

  final key = Platform.environment['RECIPE_API_KEY'] ?? _keyFromFile();
  if (key == null || key.isEmpty) {
    stderr.writeln(
      'No key. Put it in the RECIPE_API_KEY environment variable or in '
      '~/.moon-cycle/recipe_api_key. Never paste it into chat or code.',
    );
    exit(2);
  }

  final usage = _readUsage();
  var free = 0;
  var paid = 0;
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  final out = Directory('tool/captures')..createSync(recursive: true);

  Future<Map<String, Object?>?> get(String path, {required bool isPaid}) async {
    if (isPaid) {
      if (paid >= details || (usage['paid'] as int) >= _paidLifetimeLimit) {
        stderr.writeln('Paid-call limit reached; not calling $path');
        return null;
      }
    } else if (free >= maxFree) {
      stderr.writeln('Free-call limit for this run reached; stopping.');
      return null;
    }
    final sw = Stopwatch()..start();
    final req = await client.getUrl(Uri.parse('$_base/$path'));
    req.headers.set('X-API-Key', key);
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    sw.stop();
    if (isPaid) {
      paid++;
      usage['paid'] = (usage['paid'] as int) + 1;
    } else {
      free++;
      usage['free'] = (usage['free'] as int) + 1;
    }
    _writeUsage(usage);
    stdout.writeln('${res.statusCode}  ${sw.elapsedMilliseconds} ms  $path');
    final name = path.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');
    File('${out.path}/$name.json').writeAsStringSync(body);
    if (res.statusCode != 200) return null;
    return jsonDecode(body) as Map<String, Object?>;
  }

  // --list-ids a,b: only the free recipe list for ingredient ids already known
  // from earlier captures (no ingredient search, never a paid detail).
  final listIds = arg('list-ids', '');
  if (listIds.isNotEmpty) {
    for (final id in listIds.split(',')) {
      await get('recipes?ingredients=$id&per_page=10', isPaid: false);
    }
    stdout.writeln('Done. This run: $free free, 0 paid.');
    client.close();
    return;
  }
  final recipeIds = <String>{};
  for (final food in foods) {
    final ing = await get(
      'ingredients?q=${Uri.encodeQueryComponent(food)}',
      isPaid: false,
    );
    final first = ((ing?['data'] as List<Object?>?) ?? const []).firstOrNull;
    if (first is! Map<String, Object?>) continue;
    final list = await get(
      'recipes?ingredients=${first['id']}&per_page=10',
      isPaid: false,
    );
    for (final r in (list?['data'] as List<Object?>?) ?? const []) {
      if (r is Map<String, Object?> && r['id'] is String) {
        recipeIds.add(r['id']! as String);
      }
    }
  }
  for (final id in recipeIds.take(details)) {
    await get('recipes/$id', isPaid: true);
  }
  stdout.writeln(
    'Done. This run: $free free, $paid paid. Lifetime so far: '
    '${usage['free']} free, ${usage['paid']}/$_paidLifetimeLimit paid.',
  );
  client.close();
}

String? _keyFromFile() {
  final home = Platform.environment['HOME'];
  if (home == null) return null;
  final f = File('$home/.moon-cycle/recipe_api_key');
  return f.existsSync() ? f.readAsStringSync().trim() : null;
}

Map<String, Object?> _readUsage() {
  final f = File(_usageFile);
  if (!f.existsSync()) return {'free': 0, 'paid': 0};
  return jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
}

void _writeUsage(Map<String, Object?> u) =>
    File(_usageFile).writeAsStringSync(jsonEncode(u));
