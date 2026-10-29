"""The proposed final cycle-note wording for Wave 1 (shared by the candidate file and the approval documents).

Facts first (sourced NIH ODS sentences, with the iron need stated as applying every day of the month),
then one plain sentence that no phase-specific research was found. Nothing about hormones, fertility,
PMS, mood or 'support'."""
import re

HEADING = 'Nutrition & your cycle'


def proposed_cycle_note(name, cycle_text):
    t = cycle_text.replace('partly because of menstrual blood loss (NIH ODS)',
                           'partly because of menstrual blood loss (NIH ODS), and that need applies every day of the month')
    t = re.sub(r'\s*No (cycle-phase|phase-specific) claim is made( for [^.;]+)?[.;]?\s*', ' ', t).strip()
    t = re.sub(r'\s+', ' ', t)
    tail = f'We found no reliable research linking {name.lower()} to a particular phase of the cycle.'
    return (t + ' ' + tail).strip() if t else tail
