"""The proposed final cycle-note wording for Wave 1 (shared by the candidate file and the approval documents).

Built from three kinds of part, in this order:
  1. a sourced iron statement (only when the serving gives 10% or more of the iron reference), using the
     measured iron content of the serving;
  2. any other sourced or descriptive fact already in the profile (calcium, folate, vitamin C pairing, a safety
     or product note), kept as written;
  3. a closing evidence statement.
Nothing about hormones, fertility, PMS, mood or 'support' of the cycle."""
import re

HEADING = 'Nutrition & your cycle'

CLOSING_NUTRIENTS = ('This food provides nutrients that support general health. '
                     'There is currently insufficient evidence to recommend eating this food during one particular menstrual phase.')
CLOSING_PLAIN = 'There is currently insufficient evidence to recommend eating this food during one particular menstrual phase.'


def provides_nutrients(profile):
    """True when a serving gives a meaningful share of at least one nutrient, so 'provides nutrients' is accurate."""
    for n in profile['perServing']['keyNutrients']:
        if n.get('reference') and n['reference'][0]['percent'] >= 10:
            return True
        if n['name'] == 'Protein' and n['amount'] >= 5:
            return True
        if n['name'] == 'Fiber' and n['amount'] >= 3:
            return True
        if n['name'] == 'Vitamin K' and n['amount'] >= 20:
            return True
        if n['name'].startswith('Omega-3') and n['amount'] >= 0.25:
            return True
    return False


def iron_mg(profile):
    for n in profile['perServing']['keyNutrients']:
        if n['name'] == 'Iron' and n.get('reference') and n['reference'][0]['percent'] >= 10:
            return n['amount']
    return None


def _is_claim_sentence(s):
    return bool(re.match(r'\s*(No (cycle-phase|phase-specific) claim|We found no reliable research)', s))


def proposed_cycle_note(profile):
    text = profile['sections']['cycleRelevance']
    keep = []
    if 'Iron needs are higher' in text:
        mg = iron_mg(profile)
        if mg is not None:
            keep.append('Women aged 19 to 50 need 18 mg of iron a day (men: 8 mg), partly because of menstrual blood loss (NIH ODS). '
                        f'That need applies every day of the month, not only during a period. A serving of this food has about {mg} mg.')
        # the longer iron explanation (absorption detail) is dropped; the amounts above come from the data
    else:
        # sentence-level pass: drop the old closing claim, keep descriptive facts
        raw = re.sub(r'\s+', ' ', text).strip()
        parts = re.split(r'(?<=[.!?])\s+', raw)
        for s in parts:
            if re.match(r'\s*No (cycle-phase|phase-specific) claim is made for [^;.]+;\s*', s):
                rest = re.sub(r'^\s*No (cycle-phase|phase-specific) claim is made for [^;.]+;\s*', '', s)
                if rest:
                    keep.append(rest[0].upper() + rest[1:])
            elif _is_claim_sentence(s):
                continue
            else:
                s = re.sub(r'\s*No (cycle-phase|phase-specific) claim is made\.?$', '', s).strip()
                s = re.sub(r';\s*no phase-specific claim is made\.?$', '.', s).strip()
                if s:
                    keep.append(s if s[-1] in '.!?' else s + '.')
    # A fragment that began with "It" or "They" lost its subject when the old first sentence was dropped.
    fixed = []
    for k in keep:
        k = re.sub(r'^It (is|has|contains)\b', r'This food \1', k)
        k = re.sub(r'^They are\b', 'This food is', k)
        k = re.sub(r'^They add\b', 'This food adds', k)
        k = re.sub(r'\(NIH ODS\); ([A-Z])([a-z])', lambda m: f'(NIH ODS); {m.group(1).lower()}{m.group(2)}', k)
        fixed.append(k)
    keep = fixed
    closing = CLOSING_NUTRIENTS if provides_nutrients(profile) else CLOSING_PLAIN
    return ' '.join(keep + [closing])
