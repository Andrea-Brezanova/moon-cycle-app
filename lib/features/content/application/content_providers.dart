import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../preferences/application/preference_providers.dart';
import '../domain/catalogue.dart';
import '../domain/food_filter.dart';

/// The bundled catalogue. Loaded in `main()` before the first frame (it is
/// local and small), so screens can read it synchronously.
final catalogueProvider = Provider<Catalogue>(
  (ref) => throw UnimplementedError('catalogueProvider is set in main()'),
);

/// The user's diet and avoidances as one filter. Until they load, nothing is
/// filtered out.
final foodFilterProvider = Provider<FoodFilter>((ref) {
  final diet = ref.watch(dietProvider).value;
  final avoidances = ref.watch(avoidancesProvider).value;
  if (diet == null || avoidances == null) return FoodFilter.none;
  return FoodFilter(diet: diet, avoidances: avoidances);
});
