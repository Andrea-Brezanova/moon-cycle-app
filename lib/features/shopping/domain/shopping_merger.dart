import 'shopping_item.dart';

/// Something to put on the list.
final class AddRequest {
  const AddRequest({
    required this.key,
    this.foodId,
    required this.name,
    required this.aisleId,
    required this.source,
  });

  final String key;
  final String? foodId;
  final String name;
  final String aisleId;

  /// Its id is replaced when the source is stored.
  final ShoppingSource source;
}

/// What adding did, for feedback and for the repository to store.
sealed class AddOutcome {
  const AddOutcome(this.item);

  /// The item as it is after adding.
  final ShoppingItem item;
}

/// A new item.
final class ItemCreated extends AddOutcome {
  const ItemCreated(super.item);
}

/// An existing item changed: a new [source] (null when only reopened), and
/// [reopened] when it was in Done and moved back to To buy.
final class ItemMerged extends AddOutcome {
  const ItemMerged(super.item, {required this.source, required this.reopened});

  final ShoppingSource? source;
  final bool reopened;
}

/// The same reason was already there: nothing changes (adding a recipe twice
/// never doubles its quantities).
final class ItemUnchanged extends AddOutcome {
  const ItemUnchanged(super.item);
}

/// The merge rule (plan §9.2) over the live list. Pure: ids and the time
/// come from the caller.
AddOutcome addToList(
  List<ShoppingItem> live,
  AddRequest request, {
  required String Function() newId,
  required DateTime now,
}) {
  final source = ShoppingSource(
    id: newId(),
    type: request.source.type,
    phase: request.source.phase,
    recipeId: request.source.recipeId,
    amount: request.source.amount,
    unit: request.source.unit,
    qtyText: request.source.qtyText,
  );
  final existing = live.where((i) => i.key == request.key).firstOrNull;
  if (existing == null) {
    return ItemCreated(
      ShoppingItem(
        id: newId(),
        key: request.key,
        foodId: request.foodId,
        name: request.name,
        aisleId: request.aisleId,
        sources: [source],
        createdAt: now,
      ),
    );
  }
  final already = existing.sources.any(source.sameIdentityAs);
  if (already && !existing.done) return ItemUnchanged(existing);
  final reopened = existing.done;
  return ItemMerged(
    existing.copyWith(
      done: false,
      clearDoneAt: true,
      sources: already ? existing.sources : [...existing.sources, source],
    ),
    source: already ? null : source,
    reopened: reopened,
  );
}
