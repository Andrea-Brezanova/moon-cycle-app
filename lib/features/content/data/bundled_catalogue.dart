import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/catalogue.dart';
import 'catalogue_parser.dart';

/// Loads the catalogue bundled with the app (works offline).
Future<Catalogue> loadBundledCatalogue([AssetBundle? bundle]) async {
  final assets = bundle ?? rootBundle;
  Future<Map<String, Object?>> read(String name) async =>
      jsonDecode(await assets.loadString('assets/content/$name.json'))
          as Map<String, Object?>;
  return parseCatalogue(
    taxonomy: await read('taxonomy'),
    phases: await read('phases'),
    foods: await read('foods'),
    recipes: await read('recipes'),
  );
}
