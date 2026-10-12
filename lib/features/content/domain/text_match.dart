/// Lower case, trimmed, single spaces, no punctuation: "  Spring-Onions! "
/// → "spring onions". Used to compare typed text with food names.
String normaliseName(String text) => text
    .toLowerCase()
    .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

/// Whether [phrase] appears in [text] as whole words, allowing a plural
/// "s"/"es" on its last word: "mushroom" matches "Shiitake mushrooms", but
/// "pea" doesn't match "Peach".
bool containsPhrase(String text, String phrase) {
  final p = normaliseName(phrase);
  if (p.isEmpty) return false;
  final pattern = RegExp(
    '(^| )${RegExp.escape(p)}(s|es)?( |\$)',
    unicode: true,
  );
  return pattern.hasMatch(normaliseName(text));
}
