/*
 * The geometry of a pie chart, computed the way recharts 3 computes it, so a Joinery pie draws
 * the same sectors, labels and label lines in the same places: each sector's angles and radii
 * (recharts' `computePieSectors`), a sector's path (its `Sector`, with or without rounded
 * corners), where a pie's labels go (its `PieLabels` and polar `Label`), and which sector a
 * point falls in (`inRangeOfSector`).
 *
 * recharts is MIT licensed; its notice is in NOTICE, and the build keeps it in the module that
 * ships this (see rollup.config.mjs).
 */
import { valueOf, type DataKey } from './cartesian.ts'

export const RADIAN = Math.PI / 180

export interface Point {
  x: number
  y: number
}

/** A point at `radius` and `angle` (degrees, counter-clockwise from 3 o'clock) from the centre. */
export function polarToCartesian(cx: number, cy: number, radius: number, angle: number): Point {
  return {
    x: cx + Math.cos(-RADIAN * angle) * radius,
    y: cy + Math.sin(-RADIAN * angle) * radius,
  }
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number' && !Number.isNaN(value)
}

export function mathSign(value: number): number {
  if (value === 0) return 0
  return value > 0 ? 1 : -1
}

/**
 * recharts' `getPercentValue`: a percentage of `total` (`'80%'`), or a number as is. With
 * `validate`, a value over the total is the total.
 */
export function percentOf(
  value: number | string | undefined | null,
  total: number,
  fallback = 0,
  validate = false,
): number {
  if (!isNumber(value) && typeof value !== 'string') return fallback
  let result: number
  if (typeof value === 'string' && value.includes('%')) {
    result = (total * parseFloat(value.slice(0, value.indexOf('%')))) / 100
  } else {
    result = +value
  }
  if (Number.isNaN(result)) result = fallback
  if (validate && result > total) result = total
  return result
}

/** recharts' `round`: four decimals, and never `-0`. */
export function round(value: number, precision = 4): number {
  const factor = 10 ** precision
  const rounded = Math.round(value * factor) / factor
  return Object.is(rounded, -0) ? 0 : rounded
}

/** A path from a template, each number rounded as recharts' `roundTemplateLiteral` rounds it. */
function path(strings: TemplateStringsArray, ...values: (number | string)[]): string {
  return strings.reduce((result, string, i) => {
    const value = values[i - 1]
    if (typeof value === 'string') return result + value + string
    if (value !== undefined) return result + round(value) + string
    return result + string
  }, '')
}

// ---------------------------------------------------------------------------------------------
// Sectors

function sectorDeltaAngle(startAngle: number, endAngle: number): number {
  const sign = mathSign(endAngle - startAngle)
  const deltaAngle = Math.min(Math.abs(endAngle - startAngle), 359.999)
  return sign * deltaAngle
}

/** The geometry a sector is drawn from. */
export interface SectorGeometry {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
  /** Rounds the corners: a number, or a percentage of the ring's width. */
  cornerRadius?: number | string
  forceCornerRadius?: boolean
  cornerIsExternal?: boolean
}

function sectorPath({
  cx,
  cy,
  innerRadius,
  outerRadius,
  startAngle,
  endAngle,
}: Omit<SectorGeometry, 'cornerRadius'>): string {
  const angle = sectorDeltaAngle(startAngle, endAngle)
  // When the angle is 360, the start and end points coincide.
  const tempEndAngle = startAngle + angle
  const outerStart = polarToCartesian(cx, cy, outerRadius, startAngle)
  const outerEnd = polarToCartesian(cx, cy, outerRadius, tempEndAngle)
  let d = path`M ${outerStart.x},${outerStart.y}
    A ${outerRadius},${outerRadius},0,
    ${+(Math.abs(angle) > 180)},${+(startAngle > tempEndAngle)},
    ${outerEnd.x},${outerEnd.y}
  `
  if (innerRadius > 0) {
    const innerStart = polarToCartesian(cx, cy, innerRadius, startAngle)
    const innerEnd = polarToCartesian(cx, cy, innerRadius, tempEndAngle)
    d += path`L ${innerEnd.x},${innerEnd.y}
            A ${innerRadius},${innerRadius},0,
            ${+(Math.abs(angle) > 180)},${+(startAngle <= tempEndAngle)},
            ${innerStart.x},${innerStart.y} Z`
  } else {
    d += path`L ${cx},${cy} Z`
  }
  return d
}

function tangentCircle(options: {
  cx: number
  cy: number
  radius: number
  angle: number
  sign: number
  isExternal?: boolean
  cornerRadius: number
  cornerIsExternal?: boolean
}) {
  const { cx, cy, radius, angle, sign, isExternal, cornerRadius, cornerIsExternal } = options
  const centerRadius = cornerRadius * (isExternal ? 1 : -1) + radius
  const theta = Math.asin(cornerRadius / centerRadius) / RADIAN
  const centerAngle = cornerIsExternal ? angle : angle + sign * theta
  // The point where the corner's circle touches the arc, and where it touches the radius line.
  const circleTangency = polarToCartesian(cx, cy, radius, centerAngle)
  const lineTangencyAngle = cornerIsExternal ? angle - sign * theta : angle
  const lineTangency = polarToCartesian(
    cx,
    cy,
    centerRadius * Math.cos(theta * RADIAN),
    lineTangencyAngle,
  )
  return { circleTangency, lineTangency, theta }
}

function sectorWithCorner(
  options: Required<Omit<SectorGeometry, 'cornerRadius'>> & { cornerRadius: number },
): string {
  const {
    cx,
    cy,
    innerRadius,
    outerRadius,
    cornerRadius,
    forceCornerRadius,
    cornerIsExternal,
    startAngle,
    endAngle,
  } = options
  const sign = mathSign(endAngle - startAngle)
  const start = tangentCircle({
    cx,
    cy,
    radius: outerRadius,
    angle: startAngle,
    sign,
    cornerRadius,
    cornerIsExternal,
  })
  const end = tangentCircle({
    cx,
    cy,
    radius: outerRadius,
    angle: endAngle,
    sign: -sign,
    cornerRadius,
    cornerIsExternal,
  })
  const outerArcAngle = cornerIsExternal
    ? Math.abs(startAngle - endAngle)
    : Math.abs(startAngle - endAngle) - start.theta - end.theta
  if (outerArcAngle < 0) {
    if (forceCornerRadius) {
      return path`M ${start.lineTangency.x},${start.lineTangency.y}
        a${cornerRadius},${cornerRadius},0,0,1,${cornerRadius * 2},0
        a${cornerRadius},${cornerRadius},0,0,1,${-cornerRadius * 2},0
      `
    }
    return sectorPath({ cx, cy, innerRadius, outerRadius, startAngle, endAngle })
  }
  let d = path`M ${start.lineTangency.x},${start.lineTangency.y}
    A${cornerRadius},${cornerRadius},0,0,${+(sign < 0)},${start.circleTangency.x},${start.circleTangency.y}
    A${outerRadius},${outerRadius},0,${+(outerArcAngle > 180)},${+(sign < 0)},${end.circleTangency.x},${end.circleTangency.y}
    A${cornerRadius},${cornerRadius},0,0,${+(sign < 0)},${end.lineTangency.x},${end.lineTangency.y}
  `
  if (innerRadius > 0) {
    const innerStart = tangentCircle({
      cx,
      cy,
      radius: innerRadius,
      angle: startAngle,
      sign,
      isExternal: true,
      cornerRadius,
      cornerIsExternal,
    })
    const innerEnd = tangentCircle({
      cx,
      cy,
      radius: innerRadius,
      angle: endAngle,
      sign: -sign,
      isExternal: true,
      cornerRadius,
      cornerIsExternal,
    })
    const innerArcAngle = cornerIsExternal
      ? Math.abs(startAngle - endAngle)
      : Math.abs(startAngle - endAngle) - innerStart.theta - innerEnd.theta
    if (innerArcAngle < 0 && cornerRadius === 0) return `${d}L${cx},${cy}Z`
    d += path`L${innerEnd.lineTangency.x},${innerEnd.lineTangency.y}
      A${cornerRadius},${cornerRadius},0,0,${+(sign < 0)},${innerEnd.circleTangency.x},${innerEnd.circleTangency.y}
      A${innerRadius},${innerRadius},0,${+(innerArcAngle > 180)},${+(sign > 0)},${innerStart.circleTangency.x},${innerStart.circleTangency.y}
      A${cornerRadius},${cornerRadius},0,0,${+(sign < 0)},${innerStart.lineTangency.x},${innerStart.lineTangency.y}Z`
  } else {
    d += path`L${cx},${cy}Z`
  }
  return d
}

/**
 * A sector's path, as recharts' `Sector` draws it, or null where it draws nothing (an outer
 * radius inside the inner one, or no angle).
 */
export function sectorD(sector: SectorGeometry): string | null {
  const { innerRadius, outerRadius, startAngle, endAngle } = sector
  if (outerRadius < innerRadius || startAngle === endAngle) return null
  const deltaRadius = outerRadius - innerRadius
  const cornerRadius = percentOf(sector.cornerRadius ?? 0, deltaRadius, 0, true)
  if (cornerRadius > 0 && Math.abs(startAngle - endAngle) < 360) {
    return sectorWithCorner({
      cx: sector.cx,
      cy: sector.cy,
      innerRadius,
      outerRadius,
      cornerRadius: Math.min(cornerRadius, deltaRadius / 2),
      forceCornerRadius: sector.forceCornerRadius ?? false,
      cornerIsExternal: sector.cornerIsExternal ?? false,
      startAngle,
      endAngle,
    })
  }
  return sectorPath(sector)
}

// ---------------------------------------------------------------------------------------------
// Pies

/** What a pie does, with recharts' defaults filled in. */
export interface PieSettings {
  dataKey: DataKey
  nameKey: DataKey
  name?: string
  cx: number | string
  cy: number | string
  innerRadius: number | string
  outerRadius: number | string | ((datum: unknown) => number | string)
  startAngle: number
  endAngle: number
  paddingAngle: number
  minAngle: number
  cornerRadius?: number | string
  maxRadius?: number
  /** The sectors' fill where neither the row nor a `Cell` gives one. */
  fill: string
}

/** recharts' defaults for a `Pie`. */
export const PIE_DEFAULTS = {
  cx: '50%',
  cy: '50%',
  dataKey: 'value',
  nameKey: 'name',
  startAngle: 0,
  endAngle: 360,
  innerRadius: 0,
  outerRadius: '80%',
  paddingAngle: 0,
  minAngle: 0,
  fill: '#808080',
  stroke: '#fff',
} as const

/** A sector of a pie, as recharts computes it. */
export interface PieSector {
  index: number
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  maxRadius: number
  startAngle: number
  endAngle: number
  midAngle: number
  middleRadius: number
  paddingAngle: number
  percent: number
  cornerRadius?: number | string
  value: number
  /** The row's name (its `nameKey`), or its index. */
  name: unknown
  /** The row, with its `Cell`'s attributes over it. */
  payload: Record<string, unknown>
  /** The row's (or its `Cell`'s) fill, else the pie's. */
  fill: string
  /** Where the tooltip points for this sector: the middle of its ring, at its middle angle. */
  tooltipPosition: Point
}

/** The plot area: the chart less its margins and its legend. */
export interface Offset {
  top: number
  left: number
  width: number
  height: number
}

function deltaAngle(startAngle: number, endAngle: number): number {
  const sign = mathSign(endAngle - startAngle)
  return sign * Math.min(Math.abs(endAngle - startAngle), 360)
}

/** A row's value at `dataKey`, or `fallback` where it has none. */
function valueAt(datum: unknown, dataKey: DataKey, fallback: unknown): unknown {
  const value = valueOf(datum, dataKey)
  return value === null || value === undefined ? fallback : value
}

/** recharts' `parseCoordinateOfPie`: a pie's centre and radii in the plot area. */
function pieCoordinate(settings: PieSettings, offset: Offset, datum: unknown) {
  const { top, left, width, height } = offset
  const maxPieRadius = Math.min(Math.abs(width), Math.abs(height)) / 2
  const outer =
    typeof settings.outerRadius === 'function' ? settings.outerRadius(datum) : settings.outerRadius
  return {
    cx: left + percentOf(settings.cx, width, width / 2),
    cy: top + percentOf(settings.cy, height, height / 2),
    innerRadius: percentOf(settings.innerRadius, maxPieRadius, 0),
    outerRadius: percentOf(outer, maxPieRadius, maxPieRadius * 0.8),
    maxRadius: settings.maxRadius || Math.sqrt(width * width + height * height) / 2,
  }
}

/**
 * recharts' `computePieSectors`: each row's sector, its angle its share of the total. A `Cell`
 * at a row's index lays its attributes (its `fill`) over the row. Undefined when the rows sum
 * to nothing.
 */
export function pieSectors(
  settings: PieSettings,
  data: readonly unknown[],
  cells: readonly Record<string, unknown>[],
  offset: Offset,
): PieSector[] | undefined {
  const { startAngle, endAngle, dataKey, nameKey, cornerRadius } = settings
  const minAngle = Math.abs(settings.minAngle)
  const delta = deltaAngle(startAngle, endAngle)
  const absDeltaAngle = Math.abs(delta)
  const paddingAngle = data.length <= 1 ? 0 : (settings.paddingAngle ?? 0)
  const notZeroItemCount = data.filter(entry => valueAt(entry, dataKey, 0) !== 0).length
  const totalPaddingAngle =
    (absDeltaAngle >= 360 ? notZeroItemCount : notZeroItemCount - 1) * paddingAngle
  const realTotalAngle = absDeltaAngle - notZeroItemCount * minAngle - totalPaddingAngle
  const sum = data.reduce<number>((result, entry) => {
    const value = valueAt(entry, dataKey, 0)
    return result + (isNumber(value) ? value : 0)
  }, 0)
  if (!(sum > 0)) return undefined
  let previous: PieSector | undefined
  return data.map((entry, i) => {
    const raw = valueAt(entry, dataKey, 0)
    const value = isNumber(raw) ? raw : 0
    const name = valueAt(entry, nameKey, i)
    const coordinate = pieCoordinate(settings, offset, entry)
    const percent = value / sum
    const payload = { ...(entry as Record<string, unknown>), ...cells[i] }
    const fill = typeof payload['fill'] === 'string' ? payload['fill'] : settings.fill
    const sectorStart = i
      ? previous!.endAngle + mathSign(delta) * paddingAngle * (raw !== 0 ? 1 : 0)
      : startAngle
    const sectorEnd =
      sectorStart + mathSign(delta) * ((raw !== 0 ? minAngle : 0) + percent * realTotalAngle)
    const midAngle = (sectorStart + sectorEnd) / 2
    const middleRadius = (coordinate.innerRadius + coordinate.outerRadius) / 2
    previous = {
      index: i,
      ...coordinate,
      startAngle: sectorStart,
      endAngle: sectorEnd,
      midAngle,
      middleRadius,
      paddingAngle: mathSign(delta) * paddingAngle,
      percent,
      cornerRadius,
      value: (isNumber(raw) ? raw : 0) as number,
      name,
      payload,
      fill,
      tooltipPosition: polarToCartesian(coordinate.cx, coordinate.cy, middleRadius, midAngle),
    }
    return previous
  })
}

/**
 * The angles recharts draws a pie's sectors at. Its animation (which ends there even when it
 * doesn't run) lays each sector after the last by its angle, rounded to four decimals, so the
 * drawn sectors carry that rounding: the last can end a hair past 360°. Labels and the tooltip
 * keep the angles `pieSectors()` computed, as recharts' do.
 */
export function drawnSectorAngles(
  sectors: readonly PieSector[],
): { startAngle: number; endAngle: number }[] {
  let current = sectors[0]?.startAngle ?? 0
  return sectors.map((sector, index) => {
    const padding = index > 0 ? sector.paddingAngle : 0
    const angle = round(0 + 1 * (sector.endAngle - sector.startAngle))
    const startAngle = current + padding
    const endAngle = current + angle + padding
    current = endAngle
    return { startAngle, endAngle }
  })
}

// ---------------------------------------------------------------------------------------------
// Labels

/** A text's `dy` for its vertical anchor, on one line, as recharts' `Text` works it out. */
export const TEXT_DY = { start: '0.71em', middle: '0.355em', end: '0em' } as const

export interface PieLabelPlacement {
  /** Where the text goes, and which end of it is there. */
  x: number
  y: number
  textAnchor: 'start' | 'middle' | 'end'
  /** The label line, from the sector's edge out to the text. */
  line: [Point, Point]
}

/**
 * recharts' `PieLabels`: a label out past a sector's edge (by `offsetRadius`, 20 by default), at
 * its middle angle, with a line to it, its text anchored away from the centre.
 */
export function pieLabelPlacement(sector: PieSector, offsetRadius = 20): PieLabelPlacement {
  const midAngle = (sector.startAngle + sector.endAngle) / 2
  const end = polarToCartesian(sector.cx, sector.cy, sector.outerRadius + offsetRadius, midAngle)
  const textAnchor = end.x > sector.cx ? 'start' : end.x < sector.cx ? 'end' : 'middle'
  return {
    x: end.x,
    y: end.y,
    textAnchor,
    line: [polarToCartesian(sector.cx, sector.cy, sector.outerRadius, midAngle), end],
  }
}

/** Where a polar label sits against a sector (or the chart's ring). */
export type PolarLabelPosition = 'outside' | 'center' | 'centerTop' | 'centerBottom' | 'middle'

/** A sector, or the chart's whole ring, as a polar label reads it: recharts' polar view box. */
export interface PolarViewBox {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
  clockWise: boolean
}

/** recharts' `getAttrsOfPolarLabel`: where a label sits against a sector, and how it is anchored. */
export function polarLabelPlacement(
  viewBox: Omit<PolarViewBox, 'clockWise'>,
  offset: number,
  position: PolarLabelPosition | undefined,
): { x: number; y: number; textAnchor: 'start' | 'middle' | 'end'; dy: string } {
  const { cx, cy, innerRadius, outerRadius, startAngle, endAngle } = viewBox
  const midAngle = (startAngle + endAngle) / 2
  if (position === 'outside') {
    const { x, y } = polarToCartesian(cx, cy, outerRadius + offset, midAngle)
    return { x, y, textAnchor: x >= cx ? 'start' : 'end', dy: TEXT_DY.middle }
  }
  if (position === 'center') return { x: cx, y: cy, textAnchor: 'middle', dy: TEXT_DY.middle }
  if (position === 'centerTop') return { x: cx, y: cy, textAnchor: 'middle', dy: TEXT_DY.start }
  if (position === 'centerBottom') return { x: cx, y: cy, textAnchor: 'middle', dy: TEXT_DY.end }
  const r = (innerRadius + outerRadius) / 2
  const { x, y } = polarToCartesian(cx, cy, r, midAngle)
  return { x, y, textAnchor: 'middle', dy: TEXT_DY.middle }
}

// ---------------------------------------------------------------------------------------------
// Hit testing

function angleOfPoint(point: Point, center: { cx: number; cy: number }) {
  const radius = Math.sqrt((point.x - center.cx) ** 2 + (point.y - center.cy) ** 2)
  if (radius <= 0) return { radius, angle: 0 }
  let angleInRadian = Math.acos((point.x - center.cx) / radius)
  if (point.y > center.cy) angleInRadian = 2 * Math.PI - angleInRadian
  return { radius, angle: angleInRadian / RADIAN }
}

/** recharts' `inRangeOfSector`: whether a point is inside a sector's ring and angles. */
export function inSector(point: Point, sector: Omit<SectorGeometry, 'cornerRadius'>): boolean {
  const { radius, angle } = angleOfPoint(point, sector)
  if (radius === 0 || radius < sector.innerRadius || radius > sector.outerRadius) return false
  const startCount = Math.floor(sector.startAngle / 360)
  const endCount = Math.floor(sector.endAngle / 360)
  const min = Math.min(startCount, endCount)
  const startAngle = sector.startAngle - min * 360
  const endAngle = sector.endAngle - min * 360
  let formatted = angle
  if (startAngle <= endAngle) {
    while (formatted > endAngle) formatted -= 360
    while (formatted < startAngle) formatted += 360
    return formatted >= startAngle && formatted <= endAngle
  }
  while (formatted > startAngle) formatted -= 360
  while (formatted < endAngle) formatted += 360
  return formatted >= endAngle && formatted <= startAngle
}
