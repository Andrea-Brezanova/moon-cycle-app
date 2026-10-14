import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import '../../content/application/content_providers.dart';
import '../../content/domain/food.dart';
import '../../content/domain/recipe.dart';
import '../../cycle/application/cycle_providers.dart';
import '../../cycle/application/viewing_phase.dart';

/// The cycle day Home's moon was last dragged to, or null for today.
///
/// Read [homeShownDayProvider] for what the moon actually shows: dragging also
/// changes the shared viewing phase, and a phase picked elsewhere moves the
/// moon with it.
final homePreviewProvider = NotifierProvider<HomePreview, int?>(
  HomePreview.new,
);

class HomePreview extends Notifier<int?> {
  @override
  int? build() {
    // A new day (or a logged period) ends any preview.
    ref.watch(cycleStateProvider.select((s) => s.value?.cycleDay));
    // A phase chosen elsewhere ends a drag that is in another phase.
    ref.listen(viewingPhaseProvider, (_, next) {
      final s = ref.read(cycleStateProvider).value;
      final day = state;
      if (s != null && day != null && s.ranges.forDay(day).phase != next) {
        state = null;
      }
    });
    return null;
  }

  /// Previews [day] of the cycle and browses its phase everywhere. Browsing
  /// never touches the stored cycle dates or the real phase.
  void preview(int day) {
    final s = ref.read(cycleStateProvider).value;
    if (s == null) return;
    state = day == s.orbitDay ? null : day;
    ref.read(viewingPhaseProvider.notifier).choose(s.ranges.forDay(day).phase);
  }

  /// Back to today's day and the real phase.
  void backToToday() {
    state = null;
    ref.read(viewingPhaseProvider.notifier).showActual();
  }
}

/// The day Home's moon shows when it isn't on today: the dragged day, or the
/// first day of the viewing phase when another screen chose it. Null when the
/// moon is on today.
final homeShownDayProvider = Provider<int?>((ref) {
  final s = ref.watch(cycleStateProvider).value;
  if (s == null) return null;
  final viewing = ref.watch(viewingPhaseProvider);
  final dragged = ref.watch(homePreviewProvider);
  if (dragged != null && s.ranges.forDay(dragged).phase == viewing) {
    return dragged;
  }
  if (viewing == s.phase) return null;
  return s.ranges.of(viewing).firstDay;
});

/// "Foods for this phase": up to six foods, the first the user eats from each
/// category, in the stored order (PRD §7).
final foodsForPhaseProvider = Provider.family<List<Food>, Phase>((ref, phase) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  return [
    for (final category in catalogue.phase(phase).categories)
      ?category.foodIds
          .map(catalogue.food)
          .whereType<Food>()
          .where(filter.allowsFood)
          .firstOrNull,
  ].take(6).toList();
});

/// "Recipes for this phase": the phase's recipes the user's preferences allow,
/// in the stored order.
final recipesForPhaseProvider = Provider.family<List<Recipe>, Phase>((
  ref,
  phase,
) {
  final catalogue = ref.watch(catalogueProvider);
  final filter = ref.watch(foodFilterProvider);
  return [
    for (final r in catalogue.recipesFor(phase))
      if (filter.allowsRecipe(r, catalogue)) r,
  ];
});
