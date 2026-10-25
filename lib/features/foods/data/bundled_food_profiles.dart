import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/food_profile.dart';

/// Loads the reviewed food profiles bundled with the app (works offline).
Future<Map<String, FoodProfile>> loadBundledFoodProfiles([
  AssetBundle? bundle,
]) async => parseFoodProfiles(
  jsonDecode(
    await (bundle ?? rootBundle).loadString(
      'assets/content/food_profiles.json',
    ),
  ) as Map<String, Object?>,
);
