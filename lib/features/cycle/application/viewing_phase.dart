import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/phase.dart';
import 'cycle_providers.dart';

/// The phase Foods, Recipes and Shop are showing (spec §8). Home always shows
/// the real phase.
///
/// It follows the real phase until the user picks another one with the
/// phase selector, and goes back to the real phase whenever the app returns
/// to the foreground (plan §13).
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
