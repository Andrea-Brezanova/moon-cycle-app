import 'package:flutter/material.dart';

import '../../domain/local_date.dart';
import '../../domain/phase.dart';
import '../moon_theme.dart';
import '../tokens/hero_tokens.dart';
import '../tokens/moon_colors.dart';
import '../tokens/moon_layout.dart';
import '../tokens/moon_typography.dart';
import '../widgets/brand.dart';
import '../widgets/editorial_text.dart';
import '../widgets/hero_backdrop.dart';
import '../widgets/month_calendar.dart';
import '../widgets/moon_button.dart';
import '../widgets/moon_chip.dart';
import '../widgets/moon_controls.dart';
import '../widgets/moon_icon.dart';
import '../widgets/moon_list.dart';
import '../widgets/moon_orbit.dart';
import '../widgets/moon_surfaces.dart';
import '../widgets/number_stepper.dart';
import '../widgets/phase_selector.dart';
import '../widgets/recipe_photo.dart';
import '../widgets/text_link.dart';

/// Debug builds only: every Editorial component in one scrolling page, in
/// light or dark, to compare against `design/screens/00-design-system.png`.
/// Not part of the product UI.
class ComponentGallery extends StatefulWidget {
  const ComponentGallery({super.key, this.initialDark = false});

  final bool initialDark;

  @override
  State<ComponentGallery> createState() => _ComponentGalleryState();
}

class _ComponentGalleryState extends State<ComponentGallery> {
  late bool _dark = widget.initialDark;

  @override
  Widget build(BuildContext context) => Theme(
    data: moonTheme(_dark ? Brightness.dark : Brightness.light),
    child: Builder(
      builder: (context) => Scaffold(
        backgroundColor: context.moon.bg,
        body: SafeArea(
          bottom: false,
          child: GalleryContent(
            dark: _dark,
            onToggleTheme: (v) => setState(() => _dark = v),
          ),
        ),
      ),
    ),
  );
}

/// The gallery's sections. Each is wrapped in a keyed [RepaintBoundary]
/// (`gallery-<name>`) so golden tests can capture it.
class GalleryContent extends StatefulWidget {
  const GalleryContent({
    super.key,
    required this.dark,
    this.onToggleTheme,
    this.scrollable = true,
  });

  final bool dark;
  final ValueChanged<bool>? onToggleTheme;

  /// Golden tests lay everything out at once instead of scrolling.
  final bool scrollable;

  @override
  State<GalleryContent> createState() => _GalleryContentState();
}

class _GalleryContentState extends State<GalleryContent> {
  Phase _phase = Phase.follicular;
  Phase _heroPhase = Phase.follicular;
  bool _late = false;
  bool _checked = true;
  bool _toggle = true;
  int _cycleLength = 28;
  LocalDate _selected = LocalDate(2025, 9, 28);
  (int, int) _month = (2025, 9);

  static const _heroDays = {
    Phase.menstrual: 2,
    Phase.follicular: 7,
    Phase.ovulatory: 13,
    Phase.luteal: 21,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.moon;
    final sections = <Widget>[
      _section('header', [
        const Overline('Moon Cycle · Editorial v3'),
        const SizedBox(height: 10),
        EditorialHeading('Cream, plum &\n*ochre*', style: MoonType.h1),
        const SizedBox(height: 16),
        MoonListRow(
          label: 'Dark mode',
          subtitle: 'Preview both themes',
          trailing: MoonToggle(
            value: widget.dark,
            onChanged: widget.onToggleTheme,
            semanticLabel: 'Dark mode',
          ),
        ),
      ]),
      _section('colours', [
        const SectionHead('Colour'),
        const SizedBox(height: 14),
        _swatches(c),
      ]),
      _section('type', [const SectionHead('Typography'), ..._typeRows(c)]),
      _section('buttons', [
        const SectionHead('Buttons'),
        const SizedBox(height: 14),
        MoonButton(
          'Get started',
          onPressed: () {},
          trailingIcon: MoonIconName.arrow,
        ),
        const SizedBox(height: 12),
        MoonButton(
          'Continue',
          onPressed: () {},
          variant: MoonButtonVariant.secondary,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 18,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            MoonButton(
              'I’m not sure',
              onPressed: () {},
              variant: MoonButtonVariant.ghost,
              expand: false,
            ),
            TextLink('All foods', onTap: () {}, size: 14),
            TextLink('Clear all', onTap: () {}, size: 14),
            TextLink.onboarding('I’m not sure', onTap: () {}),
          ],
        ),
        const SizedBox(height: 12),
        MoonDoneButton('On your list', checkColor: c.phase(_phase).text),
        const SizedBox(height: 12),
        MoonButton(
          'Delete my data',
          onPressed: () {},
          variant: MoonButtonVariant.destructive,
        ),
        const SizedBox(height: 12),
        const MoonButton('Continue (disabled)', onPressed: null),
      ]),
      _section('selection', [
        const SectionHead('Phase selector and chips'),
        const SizedBox(height: 14),
        PhaseSelector(
          selected: _phase,
          onChanged: (p) => setState(() => _phase = p),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: MoonSpace.chipGap,
          runSpacing: MoonSpace.chipGap,
          children: [
            MoonChip('Barley', onTap: () {}),
            MoonChip(
              'Broccoli',
              onTap: () {},
              state: MoonChipState.onList,
              palette: c.phase(_phase),
            ),
            MoonChip('Chicken', onTap: () {}, state: MoonChipState.selected),
            MoonChip(
              'Omnivore',
              onTap: () {},
              state: MoonChipState.selected,
              height: MoonSize.dietPill,
            ),
            MoonChip('Vegan', onTap: () {}, height: MoonSize.dietPill),
            MoonOutlineChip('Add another', onTap: () {}),
            MoonRemovableChip(
              label: 'Mushrooms',
              tint: c.phase(Phase.menstrual).tint,
              onRemove: () {},
              removeLabel: 'Remove mushrooms',
            ),
            MoonRemovableChip(
              prefix: 'Cook with: ',
              label: 'Chicken',
              tint: c.phase(_phase).tint,
              height: 44,
              onRemove: () {},
              removeLabel: 'Clear ingredient',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MoonPill(
              'Recommended for your ${_phase.name} phase',
              background: c.phase(_phase).tint,
            ),
            MoonPill(
              _label(_phase),
              background: c.phase(_phase).tint,
              dot: c.phase(_phase).accent,
            ),
            MoonPill('Meals', background: c.sand),
          ],
        ),
      ]),
      _section('controls', [
        const SectionHead('Controls and lists'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            RoundCheckbox(
              checked: false,
              onChanged: (_) {},
              semanticLabel: 'Avocado',
            ),
            RoundCheckbox(
              checked: _checked,
              onChanged: (v) => setState(() => _checked = v),
              semanticLabel: 'Broccoli',
            ),
            const SizedBox(width: 12),
            OnListMark(palette: c.phase(_phase)),
            const SizedBox(width: 16),
            const RecipeCountBadge(2),
            const SizedBox(width: 16),
            MoonToggle(
              value: _toggle,
              onChanged: (v) => setState(() => _toggle = v),
              semanticLabel: 'Reminders',
            ),
            const SizedBox(width: 10),
            MoonToggle(value: false, onChanged: (_) {}, semanticLabel: 'Off'),
          ],
        ),
        const SizedBox(height: 18),
        MoonListGroup(
          title: 'Personalisation',
          children: [
            MoonListRow(
              icon: MoonIconName.cycle,
              label: 'My Cycle',
              subtitle: '28-day cycle · 5-day period · Next period 26 Oct',
              onTap: () {},
            ),
            MoonListRow(
              label: 'Cycle length',
              value: '28 days',
              subtitle: 'Average of your last 3 cycles',
              onTap: () {},
            ),
            MoonListRow(
              label: 'Reminders',
              subtitle: 'Phase and period reminders',
              trailing: MoonToggle(
                value: _toggle,
                onChanged: (v) => setState(() => _toggle = v),
                semanticLabel: 'Reminders',
              ),
            ),
            MoonListRow(
              label: 'Delete my data',
              labelColor: c.destructive,
              showChevron: false,
              onTap: () {},
            ),
          ],
        ),
      ]),
      _section('subscreen', [
        SubScreenHeader(
          backLabel: 'Settings',
          onBack: () {},
          title: 'My Cycle',
        ),
        const SizedBox(height: 20),
        SectionHead('Foods for today', linkLabel: 'All foods', onLink: () {}),
      ], padded: false),
      _section('stepper', [
        NumberStepper(
          label: 'Cycle length',
          value: _cycleLength,
          min: 21,
          max: 45,
          hint: 'From the first day of one period to the next.',
          onChanged: (v) => setState(() => _cycleLength = v),
        ),
      ]),
      _section('calendar', [
        MonthCalendar(
          year: _month.$1,
          month: _month.$2,
          today: LocalDate(2025, 10, 4),
          selected: _selected,
          highlighted: {for (var i = 1; i < 5; i++) _selected.addDays(i)},
          onSelect: (d) => setState(() => _selected = d),
          onMonthChanged: (d) => setState(() => _month = (d.year, d.month)),
        ),
      ]),
      _section('inputs', [
        Row(
          children: [
            const Expanded(child: MoonTextField(hint: 'Add an item')),
            const SizedBox(width: 10),
            RoundIconButton.add(onPressed: () {}),
          ],
        ),
        const SizedBox(height: 12),
        const MoonTextField(
          hint: 'Search foods',
          leadingIcon: MoonIconName.search,
        ),
        const SizedBox(height: 16),
        const InfoNote(
          icon: MoonIconName.avoid,
          text: TextSpan(
            text:
                'Always check labels. We filter with our ingredient data, but '
                'we can’t guarantee a food or recipe is free from an allergen.',
          ),
        ),
      ]),
      _section('states', [
        EmptyState(
          icon: MoonIconName.recipes,
          title: 'No follicular snacks *yet*',
          body:
              'None of this phase’s recipes is a snack. Try another meal type.',
          palette: c.phase(_phase),
          actions: [TextLink('Show all meal types', onTap: () {})],
        ),
        const SizedBox(height: 24),
        UndoToast(message: '3 done items cleared', onUndo: () {}),
        const SizedBox(height: 24),
        RecipePhoto(height: 170, radius: 24, palette: c.phase(_phase)),
      ]),
      _section('sheet', [
        ColoredBox(
          color: c.scrim,
          child: Padding(
            padding: const EdgeInsets.only(top: 40),
            child: MoonSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Overline('Meat'),
                  const SizedBox(height: 10),
                  Text(
                    'Chicken',
                    style: fraunces(42, height: 1, color: c.text),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: MoonPill(
                      'Recommended for your follicular phase',
                      background: c.phase(Phase.follicular).tint,
                    ),
                  ),
                  const SizedBox(height: 16),
                  MoonButton(
                    'See 1 recipe with chicken',
                    onPressed: () {},
                    trailingIcon: MoonIconName.arrow,
                  ),
                ],
              ),
            ),
          ),
        ),
      ], padded: false),
      _section('hero', [
        _hero(c),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: MoonSpace.gutter),
          child: Column(
            children: [
              PhaseSelector(
                selected: _heroPhase,
                onChanged: (p) => setState(() => _heroPhase = p),
              ),
              MoonListRow(
                label: 'Period late (day 32)',
                trailing: MoonToggle(
                  value: _late,
                  onChanged: (v) => setState(() => _late = v),
                  semanticLabel: 'Period late',
                ),
              ),
            ],
          ),
        ),
      ], padded: false),
      _section('brand', [
        const SectionHead('Wordmark and lockup'),
        const SizedBox(height: 16),
        Wordmark(xHeight: 12, color: c.text),
        const SizedBox(height: 12),
        Wordmark(xHeight: 24, color: c.text),
        const SizedBox(height: 16),
        Lockup(height: 40, onPlum: widget.dark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          color: c.welcomeBg,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  PhaseRingMark(size: 72, onPlum: true),
                  Wordmark(xHeight: 15, color: Color(0xFFFCFAF5)),
                ],
              ),
              const SizedBox(height: 16),
              TextLink.onboarding(
                'I already have an account',
                onTap: () {},
                color: c.welcomeText,
              ),
            ],
          ),
        ),
      ]),
    ];

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections,
    );
    return widget.scrollable ? SingleChildScrollView(child: column) : column;
  }

  Widget _hero(MoonColors c) {
    const ranges = [
      (Phase.menstrual, 1, 5),
      (Phase.follicular, 6, 11),
      (Phase.ovulatory, 12, 15),
      (Phase.luteal, 16, 28),
    ];
    final phase = _late ? Phase.luteal : _heroPhase;
    final day = _late ? 32 : _heroDays[phase]!;
    final dark = widget.dark;
    final halo = dark ? HeroTokens.darkSolid : HeroTokens.lightWash[phase]!;
    return HeroBackdrop(
      phase: phase,
      dark: dark,
      pageColor: c.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          MoonSpace.gutter,
          16,
          MoonSpace.gutter,
          56,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Wordmark(
                  xHeight: 12,
                  color: dark ? HeroTokens.darkText : HeroTokens.lightText,
                ),
                const Spacer(),
                Text(
                  'Sat 4 Oct',
                  style: dmSans(
                    13,
                    weight: FontWeight.w500,
                    height: 1,
                    color: dark ? HeroTokens.darkMuted : HeroTokens.lightMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            MoonOrbit(
              dark: dark,
              haloColor: halo,
              spec: MoonOrbitSpec(
                segments: [
                  for (final (p, a, b) in ranges) OrbitSegment(p, a, b),
                ],
                cycleLength: 28,
                activePhase: phase,
                markerDay: day > 28 ? 28 : day,
                dayNumber: day,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              {
                Phase.menstrual: 'Inner winter',
                Phase.follicular: 'Inner spring',
                Phase.ovulatory: 'Inner summer',
                Phase.luteal: 'Inner autumn',
              }[phase]!,
              style: MoonType.season.copyWith(color: c.phase(phase).text),
            ),
            const SizedBox(height: 6),
            Text(
              _label(phase),
              style: MoonType.phaseName.copyWith(
                color: dark ? HeroTokens.darkText : HeroTokens.lightText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(Phase p) =>
      '${p.name[0].toUpperCase()}${p.name.substring(1)}';

  Widget _section(String name, List<Widget> children, {bool padded = true}) =>
      RepaintBoundary(
        key: ValueKey('gallery-$name'),
        child: ColoredBox(
          color: context.moon.bg,
          child: Padding(
            padding: padded
                ? const EdgeInsets.fromLTRB(
                    MoonSpace.gutter,
                    20,
                    MoonSpace.gutter,
                    20,
                  )
                : const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      );

  Widget _swatches(MoonColors c) {
    final core = <(String, Color)>[
      ('bg', c.bg),
      ('raised', c.raised),
      ('sand', c.sand),
      ('line', c.line),
      ('text', c.text),
      ('textMuted', c.textMuted),
      ('ochre', c.ochre),
      ('destructive', c.destructive),
    ];
    Widget chip(String name, Color color) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 74,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.line),
          ),
        ),
        const SizedBox(height: 4),
        Text(name, style: MoonType.micro.copyWith(color: c.textMuted)),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [for (final (n, col) in core) chip(n, col)],
        ),
        const SizedBox(height: 16),
        for (final p in Phase.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _label(p),
                    style: MoonType.ui.copyWith(color: c.text),
                  ),
                ),
                for (final col in [
                  c.phase(p).accent,
                  c.phase(p).text,
                  c.phase(p).tint,
                ]) ...[
                  Container(
                    width: 48,
                    height: 28,
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
      ],
    );
  }

  List<Widget> _typeRows(MoonColors c) {
    final rows = <(String, TextStyle, String)>[
      ('Day number · Fraunces Light 100', MoonType.dayNumber, '7'),
      ('Phase name · 48', MoonType.phaseName, 'Follicular'),
      ('H1 · 44', MoonType.h1, 'Foods'),
      ('H2 · 36', MoonType.h2, 'Fresh, light'),
      ('H3 · Medium 26', MoonType.h3, 'Foods for today'),
      ('Category · Medium 22', MoonType.categoryHead, 'Vegetables'),
      ('Season · italic 18', MoonType.season, 'Inner spring'),
      (
        'Body large · 17',
        MoonType.bodyL,
        'Estrogen is rising and energy returns.',
      ),
      ('Body · 16', MoonType.body, 'Go for fresh, vibrant foods.'),
      ('Row label · Medium 17', MoonType.rowLabel, 'My Cycle'),
      ('Button · SemiBold 16', MoonType.button, 'Add to shopping list'),
      ('Small · Medium 13', MoonType.small, 'Day 2 of 6 in phase'),
    ];
    return [
      for (final (label, style, sample) in rows)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: c.line)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: MoonType.micro.copyWith(color: c.textMuted)),
              const SizedBox(height: 6),
              Text(sample, style: style.copyWith(color: c.text)),
            ],
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Overline('Overline · SemiBold 12, +14%', color: c.textMuted),
      ),
      const SizedBox(height: 10),
      EditorialHeading(
        'Fresh, light and *energising*',
        style: fraunces(30, height: 1.12),
      ),
    ];
  }
}
