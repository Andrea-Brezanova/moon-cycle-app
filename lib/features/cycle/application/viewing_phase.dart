import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import 'cycle_providers.dart';

/// The one phase every phase-dependent screen (Home, Foods, Recipes, Shop)
/// is browsing. It is separate from [actualPhaseProvider], the phase
/// calculated from the user's cycle and today's date, and choosing a phase
/// here never changes stored cycle dates or the actual phase.
///
/// It starts as the actual phase, follows it until the user picks another
/// phase (Home's moon or any phase selector), and goes back to it whenever
/// the app returns to the foreground (plan §13).
final viewingPhaseProvider = NotifierProvider<ViewingPhase, Phase>(
  ViewingPhase.new,
);

class ViewingPhase extends Notifier<Phase> {
  Phase? _chosen;
  AppLifecycleListener? _lifecycle;

  @override
  Phase build() {
    _lifecycle ??= AppLifecycleListener(onResume: showActual);
    ref.onDispose(() {
      _lifecycle?.dispose();
      _lifecycle = null;
    });
    final actual = ref.watch(actualPhaseProvider);
    return _chosen ?? actual;
  }

  void choose(Phase phase) {
    _chosen = phase == ref.read(actualPhaseProvider) ? null : phase;
    state = phase;
  }

  /// Back to the real phase ("Back to follicular").
  void showActual() {
    _chosen = null;
    state = ref.read(actualPhaseProvider);
  }
}

/// The user's real phase today (follicular until the cycle has loaded).
final actualPhaseProvider = Provider<Phase>(
  (ref) => ref.watch(cycleStateProvider).value?.phase ?? Phase.follicular,
);
