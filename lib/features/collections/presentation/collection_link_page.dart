import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/moon_theme.dart';
import '../../../core/design/tokens/moon_layout.dart';
import '../../../core/design/tokens/moon_typography.dart';
import '../../../core/design/widgets/centered_header.dart';
import '../../../core/design/widgets/editorial_text.dart';
import '../../../core/design/widgets/form_field_box.dart';
import '../../../core/design/widgets/moon_button.dart';
import '../../../core/design/widgets/pill_choice.dart';
import '../../../core/design/widgets/text_link.dart';
import '../data/collection_link_repository.dart';
import '../domain/collection_link.dart';
import 'open_link.dart';

/// Add a link to My Collections, or open one to read, edit, change its
/// category, open the original or delete it. The user types everything; the
/// page behind the address is never fetched.
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

  String? get _addressProblem {
    if (!_tried) return null;
    return parseLinkAddress(_address.text) == null
        ? 'Enter a web address that starts with http or https, like '
              'youtube.com/watch?v=…'
        : null;
  }

  String? get _titleProblem =>
      _tried && _title.text.trim().isEmpty ? 'Give it a name.' : null;

  Future<void> _save() async {
    setState(() => _tried = true);
    if (parseLinkAddress(_address.text) == null || _title.text.trim().isEmpty) {
      return;
    }
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

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this link?'),
        content: const Text(
          'It will be removed from My Collections. The original is not '
          'affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(collectionLinkRepositoryProvider).delete(widget.linkId!);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final link = _editing
        ? ref
              .watch(collectionLinksProvider)
              .value
              ?.where((l) => l.id == widget.linkId)
              .firstOrNull
        : null;
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 18),
      child: Overline(text),
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
            CenteredHeader(
              title: _editing ? 'Edit link' : 'Add a link',
              onBack: () => context.pop(),
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
                      padding: const EdgeInsets.fromLTRB(
                        MoonSpace.gutter,
                        0,
                        MoonSpace.gutter,
                        42,
                      ),
                      children: [
                        label('Where does it belong?'),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final cat in LinkCategory.values)
                              PillChoice(
                                label: cat.label,
                                selected: _category == cat,
                                onTap: () => setState(() => _category = cat),
                              ),
                          ],
                        ),
                        label('Web address'),
                        FormFieldBox(
                          controller: _address,
                          hint: 'https://…',
                          keyboardType: TextInputType.url,
                          capitalization: TextCapitalization.none,
                          onChanged: (_) => setState(() {}),
                        ),
                        problem(_addressProblem),
                        label('Name'),
                        FormFieldBox(
                          controller: _title,
                          hint: 'What is it called?',
                          onChanged: (_) => setState(() {}),
                        ),
                        problem(_titleProblem),
                        label('Creator (optional)'),
                        FormFieldBox(
                          controller: _creator,
                          hint: 'Who made it?',
                        ),
                        label('Your note (optional)'),
                        FormFieldBox(
                          controller: _note,
                          hint: 'Why you saved it',
                          minLines: 3,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Only what you type is saved, privately on this '
                          'phone. Moon Cycle doesn’t open the page, copy it or '
                          'send it anywhere.',
                          style: dmSans(13, height: 1.45, color: c.textMuted),
                        ),
                        const SizedBox(height: 22),
                        MoonButton(
                          _editing ? 'Save changes' : 'Save link',
                          onPressed: _save,
                        ),
                        if (_editing && link != null) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: TextLink(
                              'Open the original',
                              onTap: () => openLink(context, ref, link.url),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: TextLink('Delete this link', onTap: _delete),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
