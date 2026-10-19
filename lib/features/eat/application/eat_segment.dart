import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/routes.dart';

/// Which half of Eat is showing. Kept for the session, so leaving Eat (to open
/// a food or a recipe) and coming back finds the same half.
enum EatSegment { foods, recipes }

final eatSegmentProvider = NotifierProvider<EatSegmentNotifier, EatSegment>(
  EatSegmentNotifier.new,
);

class EatSegmentNotifier extends Notifier<EatSegment> {
  @override
  EatSegment build() => EatSegment.foods;

  void set(EatSegment s) => state = s;
}

/// Opens Eat on [segment].
void goEat(WidgetRef ref, BuildContext context, EatSegment segment) {
  ref.read(eatSegmentProvider.notifier).set(segment);
  context.go(AppTab.eat.path);
}
