import 'dart:convert';
import 'dart:io';
import 'dart:ui' show Rect;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/config/app_version.dart';
import '../../../core/time/today.dart';
import '../../content/application/content_providers.dart';
import '../../cycle/data/cycle_repository.dart';
import '../../diary/data/diary_note_repository.dart';
import '../../diary/data/diary_repository.dart';
import '../../generation/application/generation_providers.dart';
import '../../generation/data/personal_recipe_repository.dart';
import '../../generation/data/saved_recipe_repository.dart';
import '../../preferences/data/preferences_repository.dart';
import '../../shopping/data/shopping_repository.dart';
import '../domain/data_export.dart';

/// "Export my data": builds the export on the phone and hands it to the
/// share sheet. Nothing is uploaded.
class DataExportService {
  DataExportService(this._ref);

  final Ref _ref;

  /// The JSON export, as it would be shared.
  Future<String> exportJson() async {
    final cycle = _ref.read(cycleRepositoryProvider);
    final preferences = _ref.read(preferencesRepositoryProvider);
    final catalogue = _ref.read(catalogueProvider);
    final export = buildDataExport(
      exportedAt: _ref.read(clockProvider)(),
      appVersion: _ref.read(appVersionProvider),
      profile: await cycle.profile(),
      periods: await cycle.periodLogs(),
      diet: await preferences.watchDiet().first,
      avoidances: await preferences.avoidances(),
      reminders: await preferences.watchReminders().first,
      shoppingList: await _ref.read(shoppingRepositoryProvider).items(),
      savedRecipes: await _ref.read(savedRecipeRepositoryProvider).all(),
      diary: await _ref.read(diaryRepositoryProvider).all(),
      notes: await _ref.read(diaryNoteRepositoryProvider).all(),
      personalRecipes: switch (_ref.read(authSessionProvider)) {
        final session? =>
          await _ref.read(personalRecipeRepositoryProvider).all(session.userId),
        null => const [],
      },
      foodName: (id) => catalogue.food(id)?.displayName,
    );
    return const JsonEncoder.withIndent('  ').convert(export);
  }

  /// Writes the JSON and a CSV of periods to temporary files, opens the
  /// share sheet, then deletes the files (they aren't encrypted).
  /// [origin] anchors the share popover on iPad.
  Future<void> share({Rect? origin}) async {
    final json = await exportJson();
    final csv = periodLogsCsv(
      await _ref.read(cycleRepositoryProvider).periodLogs(),
    );
    final date = _ref.read(todayProvider);
    final dir = await Directory(
      '${(await getTemporaryDirectory()).path}/export',
    ).create(recursive: true);
    final jsonFile = File('${dir.path}/moon-cycle-data-$date.json');
    final csvFile = File('${dir.path}/moon-cycle-periods-$date.csv');
    try {
      await jsonFile.writeAsString(json, flush: true);
      await csvFile.writeAsString(csv, flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(jsonFile.path, mimeType: 'application/json'),
            XFile(csvFile.path, mimeType: 'text/csv'),
          ],
          subject: 'Moon Cycle data',
          sharePositionOrigin: origin,
        ),
      );
    } finally {
      for (final f in [jsonFile, csvFile]) {
        if (f.existsSync()) f.deleteSync();
      }
    }
  }
}

final dataExportServiceProvider = Provider<DataExportService>(
  DataExportService.new,
);
