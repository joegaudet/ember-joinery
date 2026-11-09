/*
 * The SVG paths a chart draws: curves (d3-shape, as recharts' Curve draws them) and bars with
 * rounded corners (recharts' Rectangle).
 */
import {
  area as d3Area,
  curveBasis,
  curveBasisClosed,
  curveBasisOpen,
  curveBumpX,
  curveBumpY,
  curveLinear,
  curveLinearClosed,
  curveMonotoneX,
  curveMonotoneY,
  curveNatural,
  curveStep,
  curveStepAfter,
  curveStepBefore,
  line as d3Line,
  type CurveFactory,
} from 'd3-shape'

/**
 * How a line or area joins its points, as recharts' `type`: `natural`, `monotone`, `linear`,
 * `step` and the rest of d3-shape's curves.
 */
export type CurveType =
  | 'basis'
  | 'basisClosed'
  | 'basisOpen'
  | 'bump'
  | 'bumpX'
  | 'bumpY'
  | 'linear'
  | 'linearClosed'
  | 'monotone'
  | 'monotoneX'
  | 'monotoneY'
  | 'natural'
  | 'step'
  | 'stepAfter'
  | 'stepBefore'

const CURVES: Record<string, CurveFactory> = {
  basis: curveBasis,
  basisClosed: curveBasisClosed,
  basisOpen: curveBasisOpen,
  bumpX: curveBumpX,
  bumpY: curveBumpY,
  linear: curveLinear,
  linearClosed: curveLinearClosed,
  monotoneX: curveMonotoneX,
  monotoneY: curveMonotoneY,
  natural: curveNatural,
  step: curveStep,
  stepAfter: curveStepAfter,
  stepBefore: curveStepBefore,
}

/** The d3 curve for a type; `monotone` and `bump` follow the layout, as recharts' do. */
export function curveFactory(
  type: CurveType | undefined,
  layout: 'horizontal' | 'vertical',
): CurveFactory {
  if (type === 'monotone' || type === 'bump') {
    return CURVES[`${type}${layout === 'vertical' ? 'Y' : 'X'}`]!
  }
  return CURVES[type ?? 'linear'] ?? curveLinear
}

/** A point of a series; `null` coordinates leave a gap. */
export interface Point {
  x: number | null
  y: number | null
}

const defined = (p: Point) =>
  p.x !== null && p.y !== null && Number.isFinite(p.x) && Number.isFinite(p.y)

/** The path through `points`, skipping the gaps (or joining over them, with `connectNulls`). */
export function linePath(
  points: readonly Point[],
  type: CurveType | undefined,
  layout: 'horizontal' | 'vertical',
  connectNulls = false,
): string | null {
  const finalPoints = connectNulls ? points.filter(defined) : points
  return d3Line<Point>()
    .x(p => p.x!)
    .y(p => p.y!)
    .defined(defined)
    .curve(curveFactory(type, layout))(finalPoints)
}

/**
 * The area between `points` and a base: a number (a flat base, the axis's) or a point per
 * point (a stacked area's lower edge).
 */
export function areaPath(
  points: readonly Point[],
  base: number | readonly Point[],
  type: CurveType | undefined,
  layout: 'horizontal' | 'vertical',
  connectNulls = false,
): string | null {
  const curve = curveFactory(type, layout)
  if (Array.isArray(base)) {
    const paired = points.map((point, index) => ({ ...point, base: base[index] as Point }))
    const areaDefined = (d: (typeof paired)[number]) =>
      d.base != null && defined(d.base) && defined(d)
    const generator =
      layout === 'vertical'
        ? d3Area<(typeof paired)[number]>()
            .y(d => d.y!)
            .x1(d => d.x!)
            .x0(d => d.base.x!)
        : d3Area<(typeof paired)[number]>()
            .x(d => d.x!)
            .y1(d => d.y!)
            .y0(d => d.base.y!)
    return generator.defined(areaDefined).curve(curve)(
      connectNulls ? paired.filter(areaDefined) : paired,
    )
  }
  const flat = base as number
  const generator =
    layout === 'vertical'
      ? d3Area<Point>()
          .y(d => d.y!)
          .x1(d => d.x!)
          .x0(flat)
      : d3Area<Point>()
          .x(d => d.x!)
          .y1(d => d.y!)
          .y0(flat)
  return generator.defined(defined).curve(curve)(connectNulls ? points.filter(defined) : points)
}

/** A number with at most four decimals, as recharts writes a rectangle's path. */
function round(value: number): number {
  return Math.round(value * 10000) / 10000
}

function path(strings: TemplateStringsArray, ...values: number[]): string {
  return strings.reduce(
    (out, string, i) => out + string + (i < values.length ? round(values[i]!) : ''),
    '',
  )
}

/**
 * A rectangle's path, its corners rounded by `radius`: one number for all four, or
 * `[topLeft, topRight, bottomRight, bottomLeft]`. recharts' `getRectanglePath`.
 */
export function rectanglePath(
  x: number,
  y: number,
  width: number,
  height: number,
  radius: number | readonly number[] = 0,
): string {
  const maxRadius = Math.min(Math.abs(round(width)) / 2, Math.abs(round(height)) / 2)
  const ySign = round(height) >= 0 ? 1 : -1
  const xSign = round(width) >= 0 ? 1 : -1
  const clockWise =
    (round(height) >= 0 && round(width) >= 0) || (round(height) < 0 && round(width) < 0) ? 1 : 0
  if (maxRadius > 0 && Array.isArray(radius)) {
    const r = [0, 1, 2, 3].map(i => Math.min(radius[i] ?? 0, maxRadius)) as [
      number,
      number,
      number,
      number,
    ]
    let d = path`M${x},${y + ySign * r[0]}`
    if (r[0] > 0) d += path`A ${r[0]},${r[0]},0,0,${clockWise},${x + xSign * r[0]},${y}`
    d += path`L ${x + width - xSign * r[1]},${y}`
    if (r[1] > 0)
      d += path`A ${r[1]},${r[1]},0,0,${clockWise},\n        ${x + width},${y + ySign * r[1]}`
    d += path`L ${x + width},${y + height - ySign * r[2]}`
    if (r[2] > 0)
      d += path`A ${r[2]},${r[2]},0,0,${clockWise},\n        ${x + width - xSign * r[2]},${y + height}`
    d += path`L ${x + xSign * r[3]},${y + height}`
    if (r[3] > 0)
      d += path`A ${r[3]},${r[3]},0,0,${clockWise},\n        ${x},${y + height - ySign * r[3]}`
    return `${d}Z`
  }
  const uniform = typeof radius === 'number' ? radius : 0
  if (maxRadius > 0 && uniform > 0) {
    const r = Math.min(maxRadius, uniform)
    return path`M ${x},${y + ySign * r}
            A ${r},${r},0,0,${clockWise},${x + xSign * r},${y}
            L ${x + width - xSign * r},${y}
            A ${r},${r},0,0,${clockWise},${x + width},${y + ySign * r}
            L ${x + width},${y + height - ySign * r}
            A ${r},${r},0,0,${clockWise},${x + width - xSign * r},${y + height}
            L ${x + xSign * r},${y + height}
            A ${r},${r},0,0,${clockWise},${x},${y + height - ySign * r} Z`
  }
  return path`M ${x},${y} h ${width} v ${height} h ${-width} Z`
}
