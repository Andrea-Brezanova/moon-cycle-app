import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/browse_scope.dart';

/// "This phase" or "All foods" on Foods. Session state; the phase itself is
/// the shared viewing phase.
final foodsScopeProvider = NotifierProvider<FoodsScope, BrowseScope>(
  FoodsScope.new,
);

class FoodsScope extends Notifier<BrowseScope> {
  @override
  BrowseScope build() => BrowseScope.phase;

  void set(BrowseScope scope) => state = scope;
  void showAll() => state = BrowseScope.all;
}
