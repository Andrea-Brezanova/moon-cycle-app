// Phase logic reference implementation. Phase ranges are derived from each user's own data;
// nothing here assumes a fixed 28-day cycle.
import { differenceInCalendarDays, addDays } from 'date-fns';
import type { Phase } from './theme';

export type CycleData = {
  lastPeriodStart: Date;   // day 1 of the most recent period
  cycleLength?: number;    // average of the last 3–6 logged cycles; default 28
  periodLength?: number;   // average period length; default 5
  lutealLength?: number;   // default 14
};

export type PhaseRange = { phase: Phase; start: number; end: number; length: number };

const clamp = (n: number, lo: number, hi: number) => Math.min(hi, Math.max(lo, Math.round(n)));

export function phaseRanges(data: Omit<CycleData, 'lastPeriodStart'>): PhaseRange[] {
  const cycle = clamp(data.cycleLength ?? 28, 21, 45);
  const period = clamp(data.periodLength ?? 5, 2, 10);
  const luteal = clamp(data.lutealLength ?? 14, 10, 16);

  const ovulationDay = cycle - luteal;
  // Follicular always gets at least one day.
  let ovStart = Math.max(ovulationDay - 2, period + 2);
  let ovEnd = Math.min(ovStart + 3, cycle - 1);
  ovStart = Math.min(ovStart, ovEnd);

  const r = (phase: Phase, start: number, end: number): PhaseRange => ({ phase, start, end, length: end - start + 1 });
  return [
    r('menstrual', 1, period),
    r('follicular', period + 1, ovStart - 1),
    r('ovulatory', ovStart, ovEnd),
    r('luteal', ovEnd + 1, cycle),
  ];
}

export type CycleState = {
  cycleDay: number;        // 1-based; may exceed cycleLength when a period is late
  cycleLength: number;
  phase: Phase;
  phaseDay: number;        // "Day 2 of 6 in phase"
  phaseLength: number;
  ranges: PhaseRange[];
  isLate: boolean;
  nextPeriod: Date;
  nextPhase: Phase;
  daysToNextPhase: number;
  /** 0..1 position of the day's centre around the ring (12 o'clock = 0). */
  markerFraction: number;
};

export function cycleState(data: CycleData, today: Date = new Date()): CycleState {
  const ranges = phaseRanges(data);
  const cycleLength = ranges[3].end;
  const cycleDay = Math.max(1, differenceInCalendarDays(today, data.lastPeriodStart) + 1);
  const isLate = cycleDay > cycleLength;
  const dayOnRing = Math.min(cycleDay, cycleLength);
  const idx = ranges.findIndex((x) => dayOnRing >= x.start && dayOnRing <= x.end);
  const cur = ranges[idx];
  const next = ranges[(idx + 1) % 4];
  return {
    cycleDay,
    cycleLength,
    phase: cur.phase,
    phaseDay: dayOnRing - cur.start + 1,
    phaseLength: cur.length,
    ranges,
    isLate,
    nextPeriod: addDays(data.lastPeriodStart, cycleLength),
    nextPhase: next.phase,
    daysToNextPhase: idx === 3 ? Math.max(0, cycleLength - dayOnRing + 1) : next.start - dayOnRing,
    markerFraction: isLate ? 1 : (dayOnRing - 0.5) / cycleLength,
  };
}

/** Phase of an arbitrary day, for the Home orbit drag preview. */
export function phaseOfDay(day: number, ranges: PhaseRange[]): PhaseRange {
  return ranges.find((x) => day >= x.start && day <= x.end) ?? ranges[3];
}

/** Onboarding reveal ring: arc for one phase, using circle r = 80 (circumference ≈ 502.65), drawn from 12 o'clock clockwise. */
export function ringSegment(range: PhaseRange, cycleLength: number, r = 80) {
  const c = 2 * Math.PI * r;
  return { strokeDasharray: `${(c * range.length) / cycleLength} ${c}`, strokeDashoffset: (-c * (range.start - 1)) / cycleLength };
}

/**
 * Home moon hero: SVG path for one phase's orbit segment (viewBox 300 × 300, centre 150, radius 136).
 * Draw with stroke width 12 and strokeLinecap="butt". `gap` is the fraction of the full circle
 * trimmed from each end, so neighbouring segments almost touch (see theme.ts › orbit).
 */
export function orbitSegmentPath(range: PhaseRange, cycleLength: number, r = 136, c = 150, gap = 0.0035) {
  const f0 = (range.start - 1) / cycleLength + gap;
  const f1 = range.end / cycleLength - gap;
  const p = (f: number) => [c + r * Math.sin(f * 2 * Math.PI), c - r * Math.cos(f * 2 * Math.PI)].map((v) => v.toFixed(2));
  const [x0, y0] = p(f0), [x1, y1] = p(f1);
  return `M ${x0} ${y0} A ${r} ${r} 0 ${f1 - f0 > 0.5 ? 1 : 0} 1 ${x1} ${y1}`;
}

/** Centre of the today dot on the Home orbit (viewBox 300). */
export function orbitDot(day: number, cycleLength: number, r = 136, c = 150) {
  const f = (day - 0.5) / cycleLength;
  return { x: c + r * Math.sin(f * 2 * Math.PI), y: c - r * Math.cos(f * 2 * Math.PI) };
}

/** Day under a touch point (Home orbit drag). x/y are relative to the ring centre. */
export function dayFromPoint(x: number, y: number, cycleLength: number) {
  let a = (Math.atan2(x, -y) * 180) / Math.PI;
  if (a < 0) a += 360;
  return Math.min(cycleLength, Math.floor((a / 360) * cycleLength) + 1);
}

// Check against the design: 28-day cycle, 5-day period → 1–5, 6–11, 12–15, 16–28.
