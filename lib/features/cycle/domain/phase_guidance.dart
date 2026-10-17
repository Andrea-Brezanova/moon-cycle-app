import '../../../core/domain/phase.dart';

/// A short, medically conservative description of what is happening in the
/// cycle during [phase]. Shown under the phase name on Home.
///
/// Phases are estimates, and people differ: this never says how anyone will
/// feel. The ovulatory text describes the days *around* estimated ovulation,
/// not ovulation itself (which is brief).
String phaseDescription(Phase phase) => switch (phase) {
  Phase.menstrual =>
    'The uterine lining is shed as your period. Hormone levels start low.',
  Phase.follicular =>
    'Follicles develop in the ovaries and oestrogen rises as the lining '
        'rebuilds.',
  Phase.ovulatory =>
    'The days around estimated ovulation, when an egg may be released.',
  Phase.luteal =>
    'After ovulation, progesterone rises. Without a pregnancy, hormones '
        'fall and a period follows.',
};

/// The three general principles shown in Home's "Your focus", per phase.
/// General principles only: individual foods are listed elsewhere.
List<String> phaseFocusPrinciples(Phase phase) => switch (phase) {
  Phase.menstrual => const [
    'Iron priority, with vitamin C alongside',
    'Warm, nourishing, comforting meals',
    'Soups, stews, porridge and warm bowls',
  ],
  Phase.follicular => const [
    'Balanced, nutrient-dense foods',
    'Lighter, fresh, quick meals',
    'Fresh produce, simple bowls, sautés and salads',
  ],
  Phase.ovulatory => const [
    'Fresh, hydrating, crisp and colourful',
    'Lighter meals',
    'Fresh, raw or lightly cooked where practical',
  ],
  Phase.luteal => const [
    'Protein, fibre and slower carbohydrates',
    'Hearty, filling, grounding meals',
    'Roasting, baking, warm bowls and one-pot meals',
  ],
};

/// The Foods page's three explanatory points for [phase], in order: what your
/// body may need, why these foods, how to eat this phase. Approved wording,
/// aligned with the featured-phase model (one featured phase per food).
({String need, String why, String how}) foodsIntroCopy(Phase phase) =>
    switch (phase) {
      Phase.menstrual => (
        need:
            'Iron is the main nutrition focus because menstrual blood loss '
            'increases iron losses. Vitamin C helps the body absorb '
            'plant-based iron.',
        why:
            'We feature iron-rich foods, vitamin-C-rich companions and '
            'nourishing foods that fit warm menstrual meals. Each food is '
            'featured in one phase to encourage variety across the cycle.',
        how:
            'Warm, comforting meals such as soups, stews, porridge and warm '
            'bowls.',
      ),
      Phase.follicular => (
        need:
            'Think fresh starts: colourful produce, nourishing whole foods and '
            'plenty of variety to build light, balanced meals.',
        why:
            'We feature fresh, versatile foods that make it easy to build '
            'colourful, lighter meals and bring new variety into the cycle.',
        how:
            'Fresh, light and quick: salads, bowls, light steaming and quick '
            'sautés.',
      ),
      Phase.ovulatory => (
        need:
            'Keep it bright and fresh: juicy fruit, crisp vegetables and '
            'balanced meals that feel light and vibrant.',
        why:
            'We feature crisp, colourful and hydrating foods that work '
            'naturally in fresh bowls, salads and quick meals.',
        how:
            'Crisp, fresh and lightly cooked: salads, chilled dishes, bowls '
            'and quick-cooked meals.',
      ),
      Phase.luteal => (
        need:
            'Appetite and energy intake may increase for some people, so '
            'protein, fibre and slower-digesting carbohydrates can help make '
            'meals more satisfying.',
        why:
            'We feature foods that help build filling meals with protein, '
            'fibre and substantial whole-food carbohydrates, while '
            'introducing foods not emphasized earlier in the cycle.',
        how:
            'Hearty, grounding meals such as roasting, baking, warm bowls '
            'and one-pot dishes.',
      ),
    };

/// Shown under the Foods intro.
const foodsUniversalNote =
    'These are suggestions, not rules. We feature different foods across '
    'your cycle to encourage variety — you can enjoy any food at any time.';

/// The Foods grid helper line.
const foodsHintText = 'Tap a food to see why we feature it and find recipes.';

/// Home's "Your focus": three short points per phase (title and one line).
/// The same meaning as [phaseFocusPrinciples], just more compact.
List<({String title, String line})> phaseFocusCompact(Phase phase) =>
    switch (phase) {
      Phase.menstrual => const [
        (
          title: 'Iron + vitamin C',
          line: 'Pair iron-rich foods with vitamin C.',
        ),
        (
          title: 'Warm, nourishing meals',
          line: 'Choose comforting, substantial foods.',
        ),
        (
          title: 'Gentle cooking',
          line: 'Think soups, stews, porridge and warm bowls.',
        ),
      ],
      Phase.follicular => const [
        (
          title: 'Fresh variety',
          line: 'Build meals from a colourful mix of whole foods.',
        ),
        (
          title: 'Light and balanced',
          line: 'Keep meals fresh, simple and satisfying.',
        ),
        (
          title: 'Quick preparation',
          line: 'Think bowls, salads, steaming and quick sautés.',
        ),
      ],
      Phase.ovulatory => const [
        (
          title: 'Fresh and hydrating',
          line: 'Choose juicy fruit and crisp vegetables.',
        ),
        (
          title: 'Bright, balanced meals',
          line: 'Keep combinations colourful and simple.',
        ),
        (
          title: 'Light preparation',
          line: 'Think salads, chilled dishes and quick cooking.',
        ),
      ],
      Phase.luteal => const [
        (title: 'Protein + fibre', line: 'Build satisfying meals.'),
        (
          title: 'Slower carbohydrates',
          line: 'Choose substantial whole-food bases.',
        ),
        (
          title: 'Warm and grounding',
          line: 'Think roasts, bakes, bowls and one-pot meals.',
        ),
      ],
    };
