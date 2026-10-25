import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/hero_tokens.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/moon_icon.dart';
import '../../../core/design/widgets/pressable.dart';
import '../../../core/domain/phase.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';

/// "Add to My Collections" (and Edit link): the address, a name, an optional
/// creator, where to keep it (Recipes, Workouts or Spa) and an optional note.
/// The user types everything; the page behind the address is never fetched.
class CollectionLinkPage extends ConsumerStatefulWidget {
  const CollectionLinkPage({super.key, this.linkId, this.category});

  /// Null to add a link.
  final String? linkId;

  /// The category to start in when adding.
  final LinkCategory? category;

  @override
  ConsumerState<CollectionLinkPage> createState() => _CollectionLinkPageState();
}

class _CollectionLinkPageState extends ConsumerState<CollectionLinkPage> {
  final _address = TextEditingController();
  final _title = TextEditingController();
  final _creator = TextEditingController();
  final _note = TextEditingController();
  late LinkCategory _category = widget.category ?? LinkCategory.recipes;
  bool _loaded = false;
  bool _missing = false;
  bool _tried = false;

  bool get _editing => widget.linkId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  Future<void> _load() async {
    final link = await ref
        .read(collectionLinkRepositoryProvider)
        .byId(widget.linkId!);
    if (!mounted) return;
    setState(() {
      _loaded = true;
      if (link == null) {
        _missing = true;
        return;
      }
      _category = link.category;
      _address.text = link.url.toString();
      _title.text = link.title;
      _creator.text = link.creator ?? '';
      _note.text = link.note ?? '';
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _title.dispose();
    _creator.dispose();
    _note.dispose();
    super.dispose();
  }

  Uri? get _parsed => parseLinkAddress(_address.text);

  Future<void> _save() async {
    setState(() => _tried = true);
    if (_parsed == null || _title.text.trim().isEmpty) return;
    final repo = ref.read(collectionLinkRepositoryProvider);
    final ok = _editing
        ? await repo.update(
            widget.linkId!,
            category: _category,
            address: _address.text,
            title: _title.text,
            creator: _creator.text,
            note: _note.text,
          )
        : (await repo.add(
                category: _category,
                address: _address.text,
                title: _title.text,
                creator: _creator.text,
                note: _note.text,
              )) !=
              null;
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We couldn’t save that. Please try again.'),
        ),
      );
      return;
    }
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final parsed = _parsed;
    final platform = parsed == null ? null : platformOf(parsed);
    final addressProblem = _tried && parsed == null
        ? 'Enter a web address that starts with http or https, like '
              'youtube.com/watch?v=…'
        : null;
    final titleProblem = _tried && _title.text.trim().isEmpty
        ? 'Give it a name.'
        : null;

    Widget label(String text, {bool optional = false}) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text.rich(
        TextSpan(
          text: text,
          children: [
            if (optional)
              TextSpan(
                text: ' optional',
                style: dmSans(
                  14,
                  weight: FontWeight.w500,
                  height: 1.2,
                  color: c.textMuted,
                ),
              ),
          ],
        ),
        style: dmSans(14, weight: FontWeight.w600, height: 1.2, color: c.text),
      ),
    );

    // Keyed, so a field keeps its own text when the platform note appears above
    // it and the list below shifts.
    Widget field(
      Key key,
      TextEditingController controller,
      String hint, {
      MoonIconName? icon,
      int minLines = 1,
      TextInputType? keyboardType,
      bool autocorrect = true,
      TextCapitalization capitalization = TextCapitalization.sentences,
    }) => Container(
      key: key,
      constraints: BoxConstraints(minHeight: minLines > 1 ? 84 : 52),
      padding: EdgeInsets.fromLTRB(16, minLines > 1 ? 4 : 0, 12, 0),
      decoration: BoxDecoration(
        color: c.raised,
        border: Border.all(color: c.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: minLines > 1
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Padding(
              padding: EdgeInsets.only(top: minLines > 1 ? 16 : 0),
              child: MoonIcon(
                icon,
                size: 19,
                color: c.textMuted,
                strokeWidth: 1.8,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              minLines: minLines,
              maxLines: minLines > 1 ? 6 : 1,
              keyboardType: keyboardType,
              autocorrect: autocorrect,
              enableSuggestions: autocorrect,
              textCapitalization: capitalization,
              onChanged: (_) => setState(() {}),
              style: dmSans(15, height: 1.45, color: c.text),
              cursorColor: c.text,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: dmSans(15, height: 1.45, color: c.textMuted),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isCollapsed: false,
                contentPadding: EdgeInsets.symmetric(
                  vertical: minLines > 1 ? 12 : 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Widget problem(String? text) => text == null
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.only(top: 6, left: 6),
            child: Text(
              text,
              style: dmSans(13, height: 1.35, color: c.destructive),
            ),
          );

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Pressable(
                        key: const ValueKey('link-cancel'),
                        onTap: () => context.pop(),
                        semanticLabel: 'Cancel',
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            minHeight: 44,
                            minWidth: 44,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Center(
                              widthFactor: 1,
                              child: Text(
                                'Cancel',
                                style: dmSans(
                                  16,
                                  weight: FontWeight.w500,
                                  height: 1.2,
                                  color: c.text,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      _editing ? 'Edit link' : 'Add to My Collections',
                      style: dmSans(
                        17,
                        weight: FontWeight.w600,
                        height: 1.2,
                        color: c.text,
                      ),
                    ),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                ],
              ),
            ),
            Expanded(
              child: !_loaded
                  ? const SizedBox.shrink()
                  : _missing
                  ? Center(
                      child: Text(
                        'This link is no longer here.',
                        style: dmSans(15, color: c.textMuted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                      children: [
                        label('Link'),
                        field(
                          const ValueKey('field-address'),
                          _address,
                          'youtube.com/watch?v=…',
                          icon: MoonIconName.link,
                          keyboardType: TextInputType.url,
                          autocorrect: false,
                          capitalization: TextCapitalization.none,
                        ),
                        problem(addressProblem),
                        if (platform != null) ...[
                          const SizedBox(height: 18),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? HeroTokens.darkSolid
                                  : HeroTokens.lightWash[Phase.follicular],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                MoonIcon(
                                  MoonIconName.check,
                                  size: 16,
                                  color: c.phase(_phase).text,
                                  strokeWidth: 2.4,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    platform == LinkPlatform.website
                                        ? 'Website link. It will open in your '
                                              'browser; nothing is downloaded.'
                                        : '${platform.label} link. It will open '
                                              'in ${platform.label}; nothing is '
                                              'downloaded.',
                                    key: const ValueKey('platform-note'),
                                    style: dmSans(
                                      13.5,
                                      height: 1.4,
                                      color: c.text,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        label('Title'),
                        field(
                          const ValueKey('field-title'),
                          _title,
                          'What is it called?',
                        ),
                        problem(titleProblem),
                        const SizedBox(height: 18),
                        label('Creator', optional: true),
                        field(
                          const ValueKey('field-creator'),
                          _creator,
                          'Who made it?',
                        ),
                        const SizedBox(height: 18),
                        label('Save to'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final cat in LinkCategory.values)
                              _CategoryPill(
                                label: cat.label,
                                selected: _category == cat,
                                onTap: () => setState(() => _category = cat),
                              ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        label('Your note', optional: true),
                        field(
                          const ValueKey('field-note'),
                          _note,
                          'Why you saved it',
                          minLines: 3,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Only what you type is saved, privately on this '
                          'phone. Moon Cycle doesn’t open the page, copy it or '
                          'send it anywhere.',
                          style: dmSans(13, height: 1.45, color: c.textMuted),
                        ),
                      ],
                    ),
            ),
            if (_loaded && !_missing)
              Container(
                padding: EdgeInsets.fromLTRB(
                  24,
                  14,
                  24,
                  14 + MediaQuery.paddingOf(context).bottom,
                ),
                decoration: BoxDecoration(
                  color: c.bg,
                  border: Border(top: BorderSide(color: c.line)),
                ),
                child: Pressable(
                  key: const ValueKey('link-save'),
                  onTap: _save,
                  semanticLabel: _editing
                      ? 'Save changes'
                      : 'Save to My Collections',
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 54),
                    decoration: ShapeDecoration(
                      color: c.inverseBg,
                      shape: const StadiumBorder(),
                    ),
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          MoonIcon(
                            MoonIconName.bookmark,
                            size: 18,
                            color: c.inverseText,
                            strokeWidth: 1.9,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _editing
                                  ? 'Save changes'
                                  : 'Save to My Collections',
                              textAlign: TextAlign.center,
                              style: dmSans(
                                15.5,
                                weight: FontWeight.w600,
                                height: 1.2,
                                color: c.inverseText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The phase whose green is the accent for confirmations on this page.
const _phase = Phase.follicular;

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    return Pressable(
      onTap: onTap,
      selected: selected,
      semanticLabel: label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 44),
        child: Center(
          widthFactor: 1,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: selected ? c.inverseBg : c.raised,
              border: selected ? null : Border.all(color: c.line),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              widthFactor: 1,
              child: Text(
                label,
                style: dmSans(
                  14,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  height: 1.2,
                  color: selected ? c.inverseText : c.text,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
