import '../../../core/domain/local_date.dart';

/// How energetic the day felt. Closed vocabulary; nothing is interpreted.
enum EnergyLevel {
  veryLow('very-low', 'Very low'),
  low('low', 'Low'),
  okay('okay', 'Okay'),
  good('good', 'Good'),
  high('high', 'High');

  const EnergyLevel(this.key, this.label);
  final String key;
  final String label;

  static EnergyLevel? parse(String key) =>
      values.where((e) => e.key == key).firstOrNull;
}

enum Mood {
  calm('calm', 'Calm'),
  happy('happy', 'Happy'),
  motivated('motivated', 'Motivated'),
  sensitive('sensitive', 'Sensitive'),
  irritable('irritable', 'Irritable'),
  anxious('anxious', 'Anxious'),
  low('low', 'Low');

  const Mood(this.key, this.label);
  final String key;
  final String label;

  static Mood? parse(String key) =>
      values.where((e) => e.key == key).firstOrNull;
}

enum SleepQuality {
  poor('poor', 'Poor'),
  restless('restless', 'Restless'),
  okay('okay', 'Okay'),
  good('good', 'Good'),
  great('great', 'Great');

  const SleepQuality(this.key, this.label);
  final String key;
  final String label;

  static SleepQuality? parse(String key) =>
      values.where((e) => e.key == key).firstOrNull;
}

/// An optional strength for a body symptom.
enum Strength {
  mild('mild', 'Mild'),
  moderate('moderate', 'Moderate'),
  strong('strong', 'Strong'),
  spotting('spotting', 'Spotting'),
  light('light', 'Light'),
  medium('medium', 'Medium'),
  heavy('heavy', 'Heavy');

  const Strength(this.key, this.label);
  final String key;
  final String label;

  static Strength? parse(String? key) =>
      values.where((e) => e.key == key).firstOrNull;
}

enum BodySymptom {
  bleeding('bleeding', 'Bleeding', 'how heavy?', [
    Strength.spotting,
    Strength.light,
    Strength.medium,
    Strength.heavy,
  ]),
  cramps('cramps', 'Cramps', 'how strong?', _scale),
  bloating('bloating', 'Bloating', 'how strong?', _scale),
  headache('headache', 'Headache', 'how strong?', _scale),
  breastTenderness(
    'breast-tenderness',
    'Breast tenderness',
    'how strong?',
    _scale,
  );

  const BodySymptom(
    this.key,
    this.label,
    this.strengthQuestion,
    this.strengths,
  );
  final String key;
  final String label;

  /// "how heavy?" / "how strong?", after the symptom's name.
  final String strengthQuestion;
  final List<Strength> strengths;

  static const _scale = [Strength.mild, Strength.moderate, Strength.strong];

  static BodySymptom? parse(String key) =>
      values.where((e) => e.key == key).firstOrNull;
}

/// One day's check-in: any of the answers, in any combination.
final class SymptomDay {
  const SymptomDay({
    required this.date,
    this.energy,
    this.sleep,
    this.moods = const {},
    this.body = const {},
    this.note,
  });

  final LocalDate date;
  final EnergyLevel? energy;
  final SleepQuality? sleep;
  final Set<Mood> moods;

  /// Each chosen body symptom and its strength (null when not given).
  final Map<BodySymptom, Strength?> body;
  final String? note;

  bool get isEmpty =>
      energy == null &&
      sleep == null &&
      moods.isEmpty &&
      body.isEmpty &&
      (note == null || note!.trim().isEmpty);

  /// "Bloating · mild", or just "Cramps".
  static String bodyText(BodySymptom s, Strength? v) =>
      v == null ? s.label : '${s.label} · ${v.label.toLowerCase()}';

  /// A one-line summary for the history: "Energy low · Cramps, mild · Sleep
  /// restless". Only what was answered.
  String get summary => [
    if (energy != null) 'Energy ${energy!.label.toLowerCase()}',
    if (moods.isNotEmpty)
      'Mood ${moods.map((m) => m.label.toLowerCase()).join(', ')}',
    if (body.isNotEmpty)
      body.entries
          .map(
            (e) => e.value == null
                ? e.key.label
                : '${e.key.label}, ${e.value!.label.toLowerCase()}',
          )
          .join(' · '),
    if (sleep != null) 'Sleep ${sleep!.label.toLowerCase()}',
  ].join(' · ');
}
