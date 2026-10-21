import 'dart:convert';
import 'dart:io';

import 'package:moon_cycle/features/content/data/catalogue_parser.dart';
import 'package:moon_cycle/features/content/domain/catalogue.dart';

Map<String, Object?> readContentFile(String name) =>
    jsonDecode(File('assets/content/$name.json').readAsStringSync())
        as Map<String, Object?>;

/// The real bundled catalogue, read from disk (tests run from the repo root).
final Catalogue testCatalogue = parseCatalogue(
  taxonomy: readContentFile('taxonomy'),
  phases: readContentFile('phases'),
  foods: readContentFile('foods'),
  recipes: readContentFile('recipes'),
);
