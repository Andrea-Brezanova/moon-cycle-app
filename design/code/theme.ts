// Moon Cycle · Editorial direction (Cream & Plum): design tokens, light and dark.
// Units are pt/dp. Every text colour below passes WCAG AA (4.5:1) on its background.

export type Phase = 'menstrual' | 'follicular' | 'ovulatory' | 'luteal';
export const PHASES: Phase[] = ['menstrual', 'follicular', 'ovulatory', 'luteal'];
export const PHASE_LABEL: Record<Phase, string> = { menstrual: 'Menstrual', follicular: 'Follicular', ovulatory: 'Ovulatory', luteal: 'Luteal' };
export const PHASE_SEASON: Record<Phase, string> = { menstrual: 'Inner winter', follicular: 'Inner spring', ovulatory: 'Inner summer', luteal: 'Inner autumn' };

type PhaseSet = { accent: string; text: string; tint: string };

export type Theme = {
  bg: string;          // page background
  raised: string;      // inputs, tab bar, calendar card, the occasional card
  sand: string;        // chips, round icon buttons, pressed food row
  line: string;        // hairline dividers
  text: string;        // primary text + icons ("plum" in light, "cream" in dark)
  textMuted: string;   // secondary text, overlines
  inverseBg: string;   // filled secondary button, pressed chip, selected date
  inverseText: string; // text on inverseBg
  shopBlockBg: string; // "Your shopping list" block on Home (plum in light, hero purple in dark)
  shopBlockText: string;
  ochre: string;       // primary CTA, active-tab dot, progress, link underline
  onOchre: string;     // text/icons on ochre
  checkboxBorder: string;
  chevron: string;     // chevron on food rows with no recipes
  removeIcon: string;  // × on shopping rows, settings chevrons
  shopBlockSub: string;// subtitle on the shopping block (inverseBg)
  welcomeBg: string;   // onboarding welcome background
  welcomeText: string;
  phase: Record<Phase, PhaseSet>;
  scheme: 'light' | 'dark';
};

export const light: Theme = {
  scheme: 'light',
  bg: '#FCFAF5', raised: '#FFFFFF', sand: '#ECE3D2', line: '#E3D9C8',
  text: '#37255C', textMuted: '#5F527A',
  inverseBg: '#37255C', inverseText: '#FCFAF5',
  shopBlockBg: '#37255C', shopBlockText: '#FCFAF5',
  ochre: '#E4AC24', onOchre: '#37255C',
  checkboxBorder: '#B9AEC9', chevron: '#C9C0D3', removeIcon: '#9A8FAD', shopBlockSub: '#D9D0E6',
  welcomeBg: '#37255C', welcomeText: '#FCFAF5',
  phase: {
    menstrual:  { accent: '#E58E73', text: '#A0513D', tint: '#F3DCCD' },
    follicular: { accent: '#4F8A72', text: '#3D6E5B', tint: '#DCE4D5' },
    ovulatory:  { accent: '#E4AC24', text: '#86621A', tint: '#F2E2BE' },
    luteal:     { accent: '#7A63B8', text: '#6550A6', tint: '#E6DEEE' },
  },
};

// Dark mode is built on the onboarding purple: deepest plum page, hero-purple surfaces, lighter plum for cards/selected.
export const dark: Theme = {
  scheme: 'dark',
  bg: '#1B152E', raised: '#2A1F47', sand: '#332650', line: '#4A3C63',
  text: '#FFFDF8', textMuted: '#C8C1D3',
  inverseBg: '#FFFDF8', inverseText: '#1B152E',
  shopBlockBg: '#2A1F47', shopBlockText: '#FFFDF8',
  ochre: '#F1B821', onOchre: '#1B152E',   // ochre is used sparingly in dark: one CTA, the active-tab dot, progress
  checkboxBorder: '#7A6D96', chevron: '#6B5E87', removeIcon: '#9A8FAD', shopBlockSub: '#C8C1D3',
  welcomeBg: '#2A1F47', welcomeText: '#FFFDF8',
  phase: {
    menstrual:  { accent: '#EE9A80', text: '#F4B19C', tint: '#523843' },
    follicular: { accent: '#6FAA8F', text: '#A3D3BC', tint: '#313C47' },
    ovulatory:  { accent: '#F1B821', text: '#F6CC5E', tint: '#533F2B' },
    luteal:     { accent: '#9A86DA', text: '#C3B6F1', tint: '#3C325B' },
  },
};

// ---------------------------------------------------------------------------
// Home hero (moon + phase orbit). See Spec §3.3 and §6, and assets/ui/moon-hero-*.svg. The onboarding reveal uses the same hero.
// The hero is full-bleed (edge to edge, no rounded corners), starts under the status bar,
// and fades into the page over its last 64 pt.
export const heroOrder: Phase[] = ['menstrual', 'follicular', 'ovulatory', 'luteal']; // clockwise from 12 o'clock

// Light mode: one off-white base with a very faint wash of the current phase colour, so the screen stays
// predominantly white. Wash = page cream #FCFAF5 mixed with the phase accent: 7% (8% for ovulatory, because
// yellow reads lighter). Text is plum in every phase; the orbit uses the light palette in every phase.
export const heroLight: Record<Phase, { bg: string; text: string; sub: string; muted: string; season: string }> = {
  menstrual:  { bg: '#FAF2EC', text: '#37255C', sub: '#37255C', muted: '#5F527A', season: '#A0513D' },
  follicular: { bg: '#F0F2EC', text: '#37255C', sub: '#37255C', muted: '#5F527A', season: '#3D6E5B' },
  ovulatory:  { bg: '#FAF4E4', text: '#37255C', sub: '#37255C', muted: '#5F527A', season: '#86621A' },
  luteal:     { bg: '#F3EFF1', text: '#37255C', sub: '#37255C', muted: '#5F527A', season: '#6550A6' },
};
// Dark mode: ONE night-plum background for all four phases, fading to the page:
// linear-gradient(180deg, #37255C 0%, #2E2150 calc(100% - 64pt), #1B152E 100%)
// The phase shows only as information: the active orbit segment, the marker ring, the season label
// (phase dark `text` colour) and a faint glow around the moon in the phase accent.
export const heroDark = {
  top: '#37255C', solid: '#2E2150', end: '#1B152E', text: '#FFFDF8', sub: '#EDE7F2', muted: '#C8C1D3',
  glow: { innerStop: 0.68, innerOpacity: 0.30, radius: 150 }, // radial gradient of the phase accent, 0.30 → 0 opacity
  markerRingWidth: 2.6,                                         // phase-accent ring around the cream today dot
} as const;
export const heroFadePt = 64;

// Orbit segment colours: active phase = acc, other three = tint.
export const orbitLight = {
  acc:  { menstrual: '#E58E73', follicular: '#4F8A72', ovulatory: '#E4AC24', luteal: '#7A63B8' },
  tint: { menstrual: '#F3DCCD', follicular: '#DCE4D5', ovulatory: '#F2E2BE', luteal: '#E6DEEE' },
} as const;
export const orbitNight = { // dark mode (all phases)
  acc:  { menstrual: '#EE9A80', follicular: '#6FAA8F', ovulatory: '#F1B821', luteal: '#9A86DA' },
  tint: { menstrual: '#523843', follicular: '#313C47', ovulatory: '#533F2B', luteal: '#3C325B' },
} as const;

// Moon: radial gradient (cx 40%, cy 36%, r 70%) between two tints of the theme ochre (20% and 42% ochre on cream).
export const moonLight = { inner: '#F7EACB', outer: '#F2D99D' } as const; // from #E4AC24
export const moonDark  = { inner: '#FAEDCB', outer: '#F7DE9C' } as const; // from #F1B821

// Geometry in a 300 × 300 viewBox (render at 300 pt on a 390 pt screen; scale with width on smaller screens).
export const orbit = {
  viewBox: 300, centre: 150,
  radius: 136, stroke: 12, lineCap: 'butt' as const,  // flat ends, like the logo
  gap: 0.0035,           // fraction of the full circle trimmed from each end of each segment (segments almost touch)
  moonRadius: 108,
  dotHalo: 12 * 0.95,    // 11.4, filled with the hero background colour (cut-out look)
  dot: 12 * 0.72,        // 8.64; plum in light mode, #FFFDF8 with a 2.6 pt phase-accent ring in dark mode
  // Today dot angle = (day - 0.5) / cycleLength of a full turn, clockwise from 12 o'clock.
  // Segment i spans (start - 1) / cycleLength → end / cycleLength, using the user's computed phase ranges (cycle.ts).
} as const;
// Centre of the moon: overline "DAY" (#5F527A, 11 pt) above the day number (Fraunces Light 100, #37255C), in every theme.

// Brand phase-ring colours (logo, app icon, onboarding), clockwise from 12 o'clock. Same in both themes.
// The ring logo is not shown on Home: the Home header uses the wordmark alone.
export const brandRing = ['#E58E73', '#4F8A72', '#E4AC24', '#7A63B8'] as const;

// Fonts: file names in assets/fonts (register with expo-font). Fraunces = display/headings (SOFT 50, WONK 0).
// Use the 72pt cut at 40 pt and up, the 24pt cut below 40.
export const fonts = {
  displayLight: 'Fraunces_72pt-Light', display: 'Fraunces_72pt-Regular', displayItalic: 'Fraunces_72pt-Italic',
  heading: 'Fraunces_24pt-Regular', headingMedium: 'Fraunces_24pt-Medium',
  headingItalic: 'Fraunces_24pt-Italic', headingMediumItalic: 'Fraunces_24pt-MediumItalic',
  body: 'DMSans_14pt-Regular', bodyMedium: 'DMSans_14pt-Medium', bodySemiBold: 'DMSans_14pt-SemiBold', bodyBold: 'DMSans_14pt-Bold',
  wordmark: 'Gwendolyn-Bold', // only for the "mooncycle" wordmark; prefer the outlined SVGs in assets/logo
} as const;

const t = (fontFamily: string, fontSize: number, lineHeight: number, trackingEm = 0, extra: object = {}) => ({
  fontFamily, fontSize, lineHeight: Math.round(fontSize * lineHeight), letterSpacing: +(fontSize * trackingEm).toFixed(2), ...extra,
});

export const type = {
  wordmarkHeader: t(fonts.wordmark, 34.8, 1.0, 0.01),  // x-height 12 pt; same as assets/logo/wordmark-header-*.svg
  dayNumber:   t(fonts.displayLight, 100, 1.0, -0.035), // Home moon (78 in onboarding reveal, 72 in steppers / Shop count)
  shopCount:   t(fonts.displayLight, 72, 0.9, -0.04),
  h1Reveal:    t(fonts.display, 54, 1.0, -0.02),         // "Follicular" on the reveal
  h1:          t(fonts.display, 44, 1.0, -0.02),         // screen titles; Home phase name 48
  h1Welcome:   t(fonts.display, 44, 1.04, -0.02),
  h2:          t(fonts.heading, 36, 1.08, -0.02),        // onboarding questions, Foods intro 32, Home focus 30
  h3:          t(fonts.headingMedium, 26, 1.08, -0.02),  // section heads
  categoryHead:t(fonts.headingMedium, 22, 1.08, -0.02),  // Foods categories, Done header 24
  cardTitle:   t(fonts.headingMedium, 21, 1.2, -0.02),   // recipe cards (feature 26 Regular, grid 18 Medium)
  season:      t(fonts.headingItalic, 18, 1.08, -0.02),  // "Inner spring" in phase text colour (20 on reveal)
  bodyL:       t(fonts.body, 17, 1.5),
  body:        t(fonts.body, 16, 1.55),
  rowLabel:    t(fonts.bodyMedium, 17, 1.25),            // Shop + Settings rows; food rows 16
  button:      t(fonts.bodySemiBold, 16, 1.0),
  ui:          t(fonts.bodyMedium, 15, 1.3),
  small:       t(fonts.bodyMedium, 13, 1.4),
  micro:       t(fonts.bodyMedium, 12, 1.3),
  tab:         t(fonts.bodyMedium, 11, 1.0),             // SemiBold when active
  overline:    t(fonts.bodySemiBold, 12, 1.2, 0.14, { textTransform: 'uppercase' as const }),
} as const;
// Italic accent words inside headings (e.g. "with your *cycle.*", "*energising*") use the matching Fraunces italic cut.

export const space = { gutter: 24, gutterOnboarding: 26, sectionGap: 48, foodsSectionGap: 34, headerGap: 18, chipGap: 8, gridGap: 14 } as const;

export const radius = { pill: 999, recipeFeature: 30, shopBlock: 30, recipeCard: 26, calendar: 28, foodRowPressed: 14, infoNote: 20, gridCard: 24 } as const;

export const sizes = {
  button: 56, chip: 42, dietPill: 44, phaseSegment: 40, foodRow: 52, shopRow: 60, settingsRow: 64,
  checkbox: 26, roundIconButton: 52, iconButton: 44, input: 52, tabBar: 88, tabIcon: 23, activeDot: 5,
  homeHero: 300,       // moon + orbit, see `orbit`
  ring: { reveal: 230, viewBox: 200, r: 80, track: 4, active: 11, markerHalo: 10, marker: 7 }, // onboarding reveal ring
  onListMark: 22, recipeCountIcon: 14,
} as const;

export const motion = { theme: 250, ring: 250, sheet: 300 } as const;
