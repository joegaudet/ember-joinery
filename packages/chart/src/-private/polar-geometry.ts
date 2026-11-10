/*
 * The geometry of a polar chart (radar and radial bar charts), computed the way recharts 3
 * computes it, so a Joinery chart draws the same marks in the same places: the chart's ring
 * (its centre and radii, left by the margins and the legend); each polar axis's domain, scale and
 * ticks; a radar's points; and each radial bar's sector, stacked where bars share a `stackId`.
 * It also has recharts' sector and polygon paths, the path a radial label runs along, and the
 * hit test that finds the row under the pointer.
 *
 * Everything here is a pure function of the chart's settings and size.
 *
 * recharts is MIT licensed; its notice is in NOTICE, and the build keeps it in the module that
 * ships this (see rollup.config.mjs).
 */
import { scaleBand, scaleLinear, scalePoint } from 'd3-scale'
import {
  stack as d3Stack,
  stackOffsetExpand,
  stackOffsetNone,
  stackOffsetSilhouette,
  stackOffsetWiggle,
  stackOrderNone,
} from 'd3-shape'
import { getNiceTickValues, getTickValuesFixedDomain } from './nice-ticks.ts'
import {
  defaultAxis,
  plotArea,
  valueOf,
  type Box,
  type DataKey,
  type DomainBound,
  type Margin,
  type StackOffset,
} from './cartesian.ts'

export const RADIAN = Math.PI / 180

export interface PolarPoint {
  x: number
  y: number
}

/** recharts' `polarToCartesian`: the point at `angle` degrees (counter-clockwise from 3 o'clock). */
export function polarToCartesian(
  cx: number,
  cy: number,
  radius: number,
  angle: number,
): PolarPoint {
  return {
    x: cx + Math.cos(-RADIAN * angle) * radius,
    y: cy + Math.sin(-RADIAN * angle) * radius,
  }
}

export function mathSign(value: number): number {
  if (value === 0) return 0
  return value > 0 ? 1 : -1
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value)
}

/**
 * recharts' `getPercentValue`: a percentage of `total` (`'80%'`), or a number as is. With
 * `validate`, never more than `total`. It multiplies before it divides, as recharts does, so the
 * radii come out as recharts' do to the last digit.
 */
export function percentValue(
  value: number | string | undefined | null,
  total: number,
  fallback = 0,
  validate = false,
): number {
  if (typeof value !== 'string' && !isNumber(value)) return fallback
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
export function round4(value: number): number {
  const rounded = Math.round(value * 10000) / 10000
  return Object.is(rounded, -0) ? 0 : rounded
}

/** recharts' `roundTemplateLiteral`: a path with each number rounded to four decimals. */
function path(strings: TemplateStringsArray, ...values: (number | string)[]): string {
  return strings.reduce((out, string, i) => {
    if (i === 0) return string
    const value = values[i - 1]
    return out + (typeof value === 'string' ? value : round4(value!)) + string
  }, '')
}

// ---------------------------------------------------------------------------------------------
// Settings

export type PolarChartName = 'RadarChart' | 'RadialBarChart'
/** `centric`: categories around the ring (a radar). `radial`: categories out from the centre. */
export type PolarLayout = 'centric' | 'radial'
export type PolarAxisType = 'angleAxis' | 'radiusAxis'

/** What a polar axis does, with recharts' defaults filled in. */
export interface PolarAxisSettings {
  dataKey?: DataKey
  /** `auto` takes the layout's: category around a radar, number out from its centre. */
  type: 'auto' | 'category' | 'number'
  domain?: readonly [DomainBound, DomainBound]
  allowDecimals: boolean
  allowDataOverflow: boolean
  allowDuplicatedCategory: boolean
  /** How many ticks a number axis aims for; an angle axis has none unless given. */
  tickCount?: number
  ticks?: readonly unknown[]
  reversed: boolean
  scale: 'auto' | 'linear' | 'band' | 'point'
}

/** recharts' defaults for an angle axis (`PolarAngleAxis`, or the one a chart makes up). */
export function defaultAngleAxis(): PolarAxisSettings {
  return {
    type: 'auto',
    allowDecimals: false,
    allowDataOverflow: false,
    // PolarAngleAxis always lays its axis out as if this were false.
    allowDuplicatedCategory: false,
    reversed: false,
    scale: 'auto',
  }
}

/** recharts' defaults for a radius axis (`PolarRadiusAxis`, or the one a chart makes up). */
export function defaultRadiusAxis(): PolarAxisSettings {
  return {
    type: 'auto',
    allowDecimals: false,
    allowDataOverflow: false,
    allowDuplicatedCategory: true,
    tickCount: 5,
    reversed: false,
    scale: 'auto',
  }
}

export interface RadarSettings {
  id: string
  dataKey: DataKey
  hide: boolean
}

export interface RadialBarSettings {
  id: string
  dataKey: DataKey
  stackId?: string | number
  hide: boolean
  minPointSize: number
  barSize?: number
  maxBarSize?: number
}

export interface PolarInput {
  chartName: PolarChartName
  layout: PolarLayout
  width: number
  height: number
  margin: Required<Margin>
  /** The legend's box, once measured, which the ring makes room for. */
  legend?: {
    width: number
    height: number
    align: 'left' | 'center' | 'right'
    verticalAlign: 'top' | 'middle' | 'bottom'
    layout: 'horizontal' | 'vertical'
  }
  cx: number | string
  cy: number | string
  innerRadius: number | string
  outerRadius: number | string
  startAngle: number
  endAngle: number
  data: readonly unknown[]
  angleAxis: PolarAxisSettings
  radiusAxis: PolarAxisSettings
  radars: RadarSettings[]
  radialBars: RadialBarSettings[]
  stackOffset: StackOffset
  barGap: number | string
  barCategoryGap: number | string
  barSize?: number
  maxBarSize?: number
}

// ---------------------------------------------------------------------------------------------
// Output

/** The chart's ring: recharts' polar view box. */
export interface PolarViewBox {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
  clockWise: boolean
}

export interface PolarTick {
  index: number
  /** An angle (in degrees) on the angle axis, a radius on the radius axis. */
  coordinate: number
  value: unknown
  offset: number
}

export interface PolarAxisGeometry {
  axisType: PolarAxisType
  settings: PolarAxisSettings
  type: 'category' | 'number'
  isCategorical: boolean
  domain: unknown[]
  range: [number, number]
  /** The axis's ticks, as recharts' `selectPolarAxisTicks` gives them. */
  ticks: PolarTick[]
  /** The ticks a series lays out against (no band offset). */
  itemTicks: PolarTick[]
  /** The ticks the tooltip finds rows by. */
  tooltipTicks: PolarTick[]
  niceTicks?: number[]
  realScale: 'band' | 'point' | 'linear'
  bandwidth: number
  scale: (value: unknown) => number | undefined
}

export interface RadarPoint {
  x: number
  y: number
  cx: number
  cy: number
  radius: number
  angle: number
  name: unknown
  value: unknown
  payload: unknown
  index: number
}

export interface RadarGeometry {
  settings: RadarSettings
  points: RadarPoint[]
  isRange: boolean
  baseLinePoints: RadarPoint[]
}

export interface SectorGeometry {
  cx: number
  cy: number
  innerRadius: number
  outerRadius: number
  startAngle: number
  endAngle: number
}

export interface RadialBarSector extends SectorGeometry {
  index: number
  /** The bar's value: a number, or a stacked bar's `[bottom, top]`. */
  value: unknown
  payload: unknown
  /** The bar's full track, for its background. */
  background?: SectorGeometry
}

export interface RadialBarGeometry {
  settings: RadialBarSettings
  sectors: RadialBarSector[]
}

export interface PolarGeometry {
  /** The chart less its margins and legend. */
  offset: Box
  viewBox: PolarViewBox
  angleAxis: PolarAxisGeometry
  radiusAxis: PolarAxisGeometry
  /** The angle axis's ticks with those that fall on the same angle (0° and 360°) dropped. */
  angleAxisTicks: PolarTick[]
  /** The axis the tooltip follows: the angle axis around a radar, the radius axis out from it. */
  tooltipAxis: PolarAxisGeometry
  /** Its ticks: where each row sits on it. */
  tooltipTicks: PolarTick[]
  radars: RadarGeometry[]
  radialBars: RadialBarGeometry[]
}

// ---------------------------------------------------------------------------------------------
// Axes

/** recharts' `isCategoricalAxis` for a polar chart. */
function isCategoricalAxis(layout: PolarLayout, axisType: PolarAxisType): boolean {
  return (
    (layout === 'centric' && axisType === 'angleAxis') ||
    (layout === 'radial' && axisType === 'radiusAxis')
  )
}

function range(start: number, end: number): number[] {
  return Array.from({ length: Math.max(end - start, 0) }, (_, i) => start + i)
}

function hasDuplicate(values: readonly unknown[]): boolean {
  return new Set(values).size !== values.length
}

function makeNumber(value: unknown): number | undefined {
  if (value === null || value === undefined || value === '') return undefined
  const number = Number(value)
  return Number.isFinite(number) ? number : undefined
}

/** recharts' `makeDomain`: a value's extent (a pair for a range value). */
function makeDomain(value: unknown): [number, number] | undefined {
  if (Array.isArray(value)) {
    const low = makeNumber(value[0])
    const high = makeNumber(value[1])
    return low !== undefined && high !== undefined ? [low, high] : undefined
  }
  const number = makeNumber(value)
  return number === undefined ? undefined : [number, number]
}

const MIN_VALUE_REG = /^dataMin[\s]*-[\s]*([0-9]+([.]{1}[0-9]+){0,1})$/
const MAX_VALUE_REG = /^dataMax[\s]*\+[\s]*([0-9]+([.]{1}[0-9]+){0,1})$/

/** recharts' `parseNumericalUserDomain`: the user's domain resolved against the data's. */
function parseNumericalDomain(
  definition: readonly [DomainBound, DomainBound],
  data: [number, number] | undefined,
  allowDataOverflow: boolean,
): [number, number] | undefined {
  if (!allowDataOverflow && !data) return undefined
  const bound = (value: DomainBound, which: 0 | 1): number | undefined => {
    const regex = which === 0 ? MIN_VALUE_REG : MAX_VALUE_REG
    if (value === 'auto') {
      return data ? (which === 0 ? Math.min(...data) : Math.max(...data)) : undefined
    }
    if (isNumber(value)) return value
    if (typeof value === 'function') {
      try {
        return data ? value(data[which]) : undefined
      } catch {
        return undefined
      }
    }
    if (typeof value === 'string' && regex.test(value)) {
      const match = regex.exec(value)
      if (!match?.[1] || !data) return undefined
      return which === 0 ? data[0] - Number(match[1]) : data[1] + Number(match[1])
    }
    return data?.[which]
  }
  const low = bound(definition[0], 0)
  const high = bound(definition[1], 1)
  if (!isNumber(low) || !isNumber(high)) return undefined
  if (!data || allowDataOverflow) return [low, high]
  return [Math.min(low, data[0]), Math.max(high, data[1])]
}

/** recharts' `getDomainDefinition`. */
function domainDefinition(
  axis: PolarAxisSettings,
  type: 'category' | 'number',
): readonly [DomainBound, DomainBound] {
  if (axis.domain) return axis.domain
  if (axis.ticks && type === 'number') {
    const values = axis.ticks.map(makeNumber).filter(isNumber)
    return [Math.min(...values), Math.max(...values)]
  }
  return [0, 'auto']
}

interface AxisItem {
  dataKey: DataKey
}

/** recharts' `combineAppliedValues`: the values an axis lays out. */
function appliedValues(
  data: readonly unknown[],
  axis: PolarAxisSettings,
  items: readonly AxisItem[],
): unknown[] {
  if (axis.dataKey !== undefined) return data.map(row => valueOf(row, axis.dataKey))
  if (items.length) return items.flatMap(item => data.map(row => valueOf(row, item.dataKey)))
  return [...data]
}

function resolveAxis(
  input: PolarInput,
  axisType: PolarAxisType,
  items: readonly AxisItem[],
): PolarAxisGeometry {
  const { layout, data } = input
  const settings = axisType === 'angleAxis' ? input.angleAxis : input.radiusAxis
  const isCategorical = isCategoricalAxis(layout, axisType)
  const type: 'category' | 'number' =
    settings.type === 'auto' ? (isCategorical ? 'category' : 'number') : settings.type
  const axis = { ...settings, type }
  const applied = appliedValues(data, settings, items)

  // combineAxisDomain
  let domain: unknown[]
  if (isCategorical && settings.dataKey === undefined) {
    domain = range(0, data.length)
  } else if (type === 'category') {
    const categories = applied.filter(
      value => typeof value === 'string' || isNumber(value) || value instanceof Date,
    )
    if (
      isCategorical &&
      (settings.dataKey === undefined ||
        (settings.allowDuplicatedCategory && hasDuplicate(categories)))
    ) {
      domain = range(0, applied.length)
    } else {
      domain = settings.allowDuplicatedCategory ? categories : [...new Set(categories)]
    }
  } else if (input.stackOffset === 'expand') {
    domain = [0, 1]
  } else {
    // combineNumericalDomain: the items' values (and the axis's own data key's); a polar chart
    // leaves stacking out of its domain, as recharts does.
    let low: number | undefined
    let high: number | undefined
    const extend = (value: unknown) => {
      const extent = makeDomain(value)
      if (!extent) return
      low = low === undefined ? extent[0] : Math.min(low, extent[0])
      high = high === undefined ? extent[1] : Math.max(high, extent[1])
    }
    for (const row of data) {
      for (const item of items) extend(valueOf(row, settings.dataKey ?? item.dataKey))
    }
    if (settings.dataKey !== undefined)
      for (const row of data) extend(valueOf(row, settings.dataKey))
    const extent = isNumber(low) && isNumber(high) ? ([low, high] as [number, number]) : undefined
    domain =
      parseNumericalDomain(domainDefinition(axis, type), extent, settings.allowDataOverflow) ?? []
  }

  // combineRealScaleType
  const realScale: 'band' | 'point' | 'linear' =
    settings.scale !== 'auto' ? settings.scale : type === 'category' ? 'band' : 'linear'

  // combineNiceTicks, and the domain they extend (the angle axis's they don't)
  let niceTicks: number[] | undefined
  const numeric = domain.length === 2 && isNumber(domain[0]) && isNumber(domain[1])
  if (realScale === 'linear' && settings.tickCount && numeric) {
    const definition = domainDefinition(axis, type)
    const hasAuto = definition[0] === 'auto' || definition[1] === 'auto'
    const pair = domain as [number, number]
    if (hasAuto) niceTicks = getNiceTickValues(pair, settings.tickCount, settings.allowDecimals)
    else if (type === 'number')
      niceTicks = getTickValuesFixedDomain(pair, settings.tickCount, settings.allowDecimals)
  }
  if (axisType !== 'angleAxis' && type === 'number' && numeric && niceTicks?.length) {
    domain = [
      Math.min(domain[0] as number, niceTicks[0]!),
      Math.max(domain[1] as number, niceTicks[niceTicks.length - 1]!),
    ]
  }

  // The range: the angles, or the radii; then `reversed`.
  const viewBox = viewBoxOf(input)
  let axisRange: [number, number] =
    axisType === 'angleAxis'
      ? [input.startAngle, input.endAngle]
      : [viewBox.innerRadius, viewBox.outerRadius]
  if (settings.reversed) axisRange = [axisRange[1], axisRange[0]]

  let bandwidth = 0
  let scale: (value: unknown) => number | undefined
  let scaleTicks: ((count?: number) => number[]) | undefined
  if (realScale === 'band') {
    const band = scaleBand<string>()
      .domain(domain.map(value => value as string))
      .range(axisRange)
    bandwidth = band.bandwidth()
    scale = value => band(value as string)
  } else if (realScale === 'point') {
    const point = scalePoint<string>()
      .domain(domain.map(value => value as string))
      .range(axisRange)
    bandwidth = point.bandwidth()
    scale = value => point(value as string)
  } else {
    const linear = scaleLinear()
      .domain(domain as [number, number])
      .range(axisRange)
    scale = value => {
      const number = makeNumber(value)
      return number === undefined ? undefined : linear(number)
    }
    scaleTicks = count => linear.ticks(count)
  }

  // combineDuplicateDomain and combineCategoricalDomain
  const allValues = applied
  const duplicateDomain =
    settings.dataKey !== undefined &&
    isCategorical &&
    type === 'category' &&
    settings.allowDuplicatedCategory &&
    hasDuplicate(allValues)
      ? allValues
      : undefined
  const categoricalDomain =
    settings.dataKey !== undefined &&
    isCategorical &&
    (type === 'number' || settings.scale !== 'auto')
      ? allValues
      : undefined

  // combineAxisTicks: a band's ticks sit at its middle; around the ring, recharts moves them a
  // whole band along, in the direction the angles run.
  let offset = type === 'category' && realScale !== 'linear' ? bandwidth / 2 : 0
  if (axisType === 'angleAxis') offset = mathSign(axisRange[0] - axisRange[1]) * 2 * offset
  const tick = (value: unknown, index: number, scaled: number | undefined, at: number) =>
    isNumber(scaled) ? { index, coordinate: scaled + at, value, offset: at } : null
  // mode `axis`: combineAxisTicks; `item`: combineGraphicalItemTicks; `tooltip`:
  // combineTicksOfTooltipAxis. They differ in whether they take the axis's own and nice ticks,
  // and a linear scale's.
  const ticksFrom = (at: number, mode: 'axis' | 'item' | 'tooltip'): PolarTick[] => {
    const list = mode === 'axis' ? (settings.ticks ?? niceTicks) : undefined
    let result: (PolarTick | null)[]
    if (list) {
      result = list.map((entry, index) =>
        tick(entry, index, scale(duplicateDomain ? duplicateDomain.indexOf(entry) : entry), at),
      )
    } else if (isCategorical && categoricalDomain) {
      result = categoricalDomain.map((entry, index) => tick(entry, index, scale(entry), at))
    } else if (scaleTicks && mode !== 'tooltip') {
      result = scaleTicks(settings.tickCount).map((entry, index) =>
        tick(entry, index, scale(entry), at),
      )
    } else {
      result = domain.map((entry, index) =>
        tick(duplicateDomain ? duplicateDomain[entry as number] : entry, index, scale(entry), at),
      )
    }
    return result.filter((entry): entry is PolarTick => entry !== null)
  }

  return {
    axisType,
    settings,
    type,
    isCategorical,
    domain,
    range: axisRange,
    ticks: ticksFrom(offset, 'axis'),
    itemTicks: axisRange[0] === axisRange[1] ? [] : ticksFrom(0, 'item'),
    tooltipTicks: ticksFrom(offset, 'tooltip'),
    bandwidth,
    scale,
    niceTicks,
    realScale,
  }
}

/** recharts' `getBandSizeOfAxis`. */
function bandSizeOf(
  axis: PolarAxisGeometry,
  ticks: readonly PolarTick[],
  isBar: boolean,
): number | undefined {
  if (axis.bandwidth && (!isBar || axis.bandwidth > 0)) return axis.bandwidth
  if (ticks.length >= 2) {
    const sorted = [...ticks].sort((a, b) => a.coordinate - b.coordinate)
    let size = Infinity
    for (let i = 1; i < sorted.length; i++) {
      size = Math.min(sorted[i]!.coordinate - sorted[i - 1]!.coordinate, size)
    }
    return size === Infinity ? 0 : size
  }
  return isBar ? undefined : 0
}

// ---------------------------------------------------------------------------------------------
// The ring

function offsetOf(input: PolarInput): Box {
  return plotArea({
    width: input.width,
    height: input.height,
    margin: input.margin,
    xAxis: defaultAxis('x', true),
    yAxis: defaultAxis('y', true),
    legend: input.legend,
  })
}

/** recharts' `selectPolarViewBox`: the ring's centre, radii and angles. */
export function viewBoxOf(input: PolarInput): PolarViewBox {
  const offset = offsetOf(input)
  const maxRadius =
    Math.min(
      Math.abs(input.width - offset.left - offset.right),
      Math.abs(input.height - offset.top - offset.bottom),
    ) / 2
  return {
    cx: percentValue(input.cx, input.width, input.width / 2),
    cy: percentValue(input.cy, input.height, input.height / 2),
    innerRadius: percentValue(input.innerRadius, maxRadius, 0),
    outerRadius: percentValue(input.outerRadius, maxRadius, maxRadius * 0.8),
    startAngle: input.startAngle,
    endAngle: input.endAngle,
    clockWise: false,
  }
}

// ---------------------------------------------------------------------------------------------
// Stacking and bars

const OFFSETS = {
  none: stackOffsetNone,
  expand: stackOffsetExpand,
  silhouette: stackOffsetSilhouette,
  wiggle: stackOffsetWiggle,
}

/** recharts' `sign` and `positive` offsets. */
function signedOffset(onlyPositive: boolean) {
  return (series: number[][][], order: Iterable<number>): void => {
    const n = series[0]?.length ?? 0
    for (let j = 0; j < n; ++j) {
      let positive = 0
      let negative = 0
      for (const i of order) {
        const point = series[i]![j]!
        const value = Number.isNaN(point[1]!) ? point[0]! : point[1]!
        if (value >= 0) {
          point[0] = positive
          point[1] = positive + value
          positive = point[1]
        } else if (onlyPositive) {
          point[0] = 0
          point[1] = 0
        } else {
          point[0] = negative
          point[1] = negative + value
          negative = point[1]
        }
      }
    }
  }
}

/** Each stacked bar's `[bottom, top]` per row, by bar id. */
function stackBars(
  input: PolarInput,
  bars: readonly RadialBarSettings[],
): Map<string, [number, number][]> {
  const groups = new Map<string, RadialBarSettings[]>()
  for (const bar of bars) {
    if (bar.stackId === undefined || bar.stackId === null) continue
    const key = String(bar.stackId)
    groups.set(key, [...(groups.get(key) ?? []), bar])
  }
  const result = new Map<string, [number, number][]>()
  for (const members of groups.values()) {
    const offset =
      input.stackOffset === 'sign'
        ? signedOffset(false)
        : input.stackOffset === 'positive'
          ? signedOffset(true)
          : OFFSETS[input.stackOffset]
    const stacked = d3Stack<unknown, number>()
      .keys(members.map((_, i) => i))
      .value((row, i) => makeNumber(valueOf(row, members[i]!.dataKey)) ?? 0)
      .order(stackOrderNone)
      .offset(offset as never)(input.data as unknown[])
    stacked.forEach((layer, i) => {
      result.set(
        members[i]!.id,
        layer.map(point => [point[0], point[1]]),
      )
    })
  }
  return result
}

interface BarSlot {
  stackId?: string | number
  ids: string[]
  barSize?: number
}

/** recharts' `combineBarSizeList`: one slot per stack, and one per unstacked bar. */
function barSlots(bars: readonly RadialBarSettings[], globalSize: number | undefined): BarSlot[] {
  const stacks = new Map<string, RadialBarSettings[]>()
  for (const bar of bars) {
    if (bar.stackId === undefined || bar.stackId === null) continue
    const key = String(bar.stackId)
    stacks.set(key, [...(stacks.get(key) ?? []), bar])
  }
  return [
    ...[...stacks.values()].map(members => ({
      stackId: members[0]!.stackId,
      ids: members.map(bar => bar.id),
      barSize: members[0]!.barSize ?? globalSize,
    })),
    ...bars
      .filter(bar => bar.stackId === undefined || bar.stackId === null)
      .map(bar => ({ stackId: undefined, ids: [bar.id], barSize: bar.barSize ?? globalSize })),
  ]
}

/** recharts' `getBarPositions`: each slot's offset in the band and its size. */
function barPositions(
  bandSize: number,
  slots: readonly BarSlot[],
  barGap: number | string,
  barCategoryGap: number | string,
  maxBarSize: number | undefined,
): { offset: number; size: number }[] {
  const len = slots.length
  if (len < 1) return []
  let gap = percentValue(barGap, bandSize, 0, true)
  if (isNumber(slots[0]!.barSize)) {
    let useFull = false
    let fullBarSize = bandSize / len
    let sum = slots.reduce((total, slot) => total + (slot.barSize ?? 0), 0) + (len - 1) * gap
    if (sum >= bandSize) {
      sum -= (len - 1) * gap
      gap = 0
    }
    if (sum >= bandSize && fullBarSize > 0) {
      useFull = true
      fullBarSize *= 0.9
      sum = len * fullBarSize
    }
    const start = ((bandSize - sum) / 2) >> 0
    let previous = { offset: start - gap, size: 0 }
    return slots.map(slot => {
      const position = {
        offset: previous.offset + previous.size + gap,
        size: useFull ? fullBarSize : (slot.barSize ?? 0),
      }
      previous = position
      return position
    })
  }
  const offset = percentValue(barCategoryGap, bandSize, 0, true)
  if (bandSize - 2 * offset - (len - 1) * gap <= 0) gap = 0
  let originalSize = (bandSize - 2 * offset - (len - 1) * gap) / len
  if (originalSize > 1) originalSize >>= 0
  const size = isNumber(maxBarSize) ? Math.min(originalSize, maxBarSize) : originalSize
  return slots.map((_, i) => ({
    offset: offset + (originalSize + gap) * i + (originalSize - size) / 2,
    size,
  }))
}

/** recharts' `truncateByDomain`: a stacked bar cut to the axis's domain. */
function truncateByDomain(value: [number, number], domain: unknown[]): [number, number] {
  const [a, b] = domain
  if (!isNumber(a) || !isNumber(b)) return value
  const min = Math.min(a, b)
  const max = Math.max(a, b)
  const result: [number, number] = [value[0], value[1]]
  if (!isNumber(value[0]) || value[0] < min) result[0] = min
  if (!isNumber(value[1]) || value[1] > max) result[1] = max
  if (result[0] > max) result[0] = max
  if (result[1] < min) result[1] = min
  return result
}

/** recharts' `getBaseValueOfBar`: where an unstacked bar starts on the number axis. */
function baseValueOf(axis: PolarAxisGeometry): unknown {
  const [a, b] = axis.domain
  if (axis.type === 'number' && isNumber(a) && isNumber(b)) {
    const min = Math.min(a, b)
    const max = Math.max(a, b)
    if (min <= 0 && max >= 0) return 0
    return max < 0 ? max : min
  }
  return axis.domain[0]
}

/** recharts' `getCateCoordinateOfBar`: where a bar starts on the category axis. */
function categoryCoordinateOf(
  axis: PolarAxisGeometry,
  row: unknown,
  index: number,
  bandSize: number,
  offset: number,
): number | null {
  if (axis.type === 'category') {
    const tick = axis.itemTicks[index]
    return tick ? tick.coordinate + offset : null
  }
  const value = valueOf(row, axis.settings.dataKey, axis.domain[index])
  if (value === null || value === undefined) return null
  const scaled = axis.scale(value)
  return isNumber(scaled) ? scaled - bandSize / 2 + offset : null
}

// ---------------------------------------------------------------------------------------------
// The layout

export function polarGeometry(input: PolarInput): PolarGeometry {
  const { layout, data } = input
  const viewBox = viewBoxOf(input)
  const visibleBars = input.radialBars.filter(bar => !bar.hide)
  const items: AxisItem[] = [...input.radars.filter(radar => !radar.hide), ...visibleBars]
  const angleAxis = resolveAxis(input, 'angleAxis', items)
  const radiusAxis = resolveAxis(input, 'radiusAxis', items)

  // selectPolarAngleAxisTicks: around a full circle, 0° and 360° are one tick.
  const seen = new Set<number>()
  const angleAxisTicks = angleAxis.ticks.filter(tick => {
    const normalized = (tick.coordinate + 360) % 360
    if (seen.has(normalized)) return false
    seen.add(normalized)
    return true
  })

  // Radars: computeRadarPoints
  const radarBandSize =
    layout === 'radial'
      ? (bandSizeOf(radiusAxis, radiusAxis.ticks, false) ?? 0)
      : (bandSizeOf(angleAxis, angleAxis.ticks, false) ?? 0)
  const radars = input.radars.map(settings => {
    const angleBand = angleAxis.type !== 'number' ? radarBandSize : 0
    let isRange = false
    const points: RadarPoint[] = data.map((row, index) => {
      const name = valueOf(row, angleAxis.settings.dataKey, index)
      const value = valueOf(row, settings.dataKey)
      const angle = (angleAxis.scale(name) ?? 0) + angleBand
      const pointValue = Array.isArray(value) ? value[value.length - 1] : value
      const radius =
        pointValue === null || pointValue === undefined ? 0 : (radiusAxis.scale(pointValue) ?? 0)
      if (Array.isArray(value) && value.length >= 2) isRange = true
      return {
        ...polarToCartesian(viewBox.cx, viewBox.cy, radius, angle),
        cx: viewBox.cx,
        cy: viewBox.cy,
        radius,
        angle,
        name,
        value,
        payload: row,
        index,
      }
    })
    const baseLinePoints = isRange
      ? points.map(point => {
          if (!Array.isArray(point.value)) return point
          const base = point.value[0] as unknown
          const radius = base === null || base === undefined ? 0 : (radiusAxis.scale(base) ?? 0)
          return {
            ...point,
            radius,
            ...polarToCartesian(viewBox.cx, viewBox.cy, radius, point.angle),
          }
        })
      : []
    return { settings, points, isRange, baseLinePoints }
  })

  // Radial bars: computeRadialBarDataItems
  const categoryAxis = layout === 'centric' ? angleAxis : radiusAxis
  const numericAxis = layout === 'centric' ? radiusAxis : angleAxis
  const barBandSize =
    bandSizeOf(categoryAxis, categoryAxis.itemTicks, true) ?? input.maxBarSize ?? 0
  const bandSize = bandSizeOf(categoryAxis, categoryAxis.itemTicks, false) ?? 0
  const slots = barSlots(visibleBars, input.barSize)
  const stacks = stackBars(input, visibleBars)
  const baseValue = baseValueOf(numericAxis)
  const radialBars = input.radialBars.map(settings => {
    if (settings.hide) return { settings, sectors: [] }
    const slotIndex = slots.findIndex(slot => slot.ids.includes(settings.id))
    const positions = barPositions(
      barBandSize !== bandSize ? barBandSize : bandSize,
      slots,
      input.barGap,
      input.barCategoryGap,
      settings.maxBarSize ?? input.maxBarSize,
    ).map(position =>
      barBandSize !== bandSize
        ? { ...position, offset: position.offset - barBandSize / 2 }
        : position,
    )
    const position = positions[slotIndex]
    if (!position) return { settings, sectors: [] }
    const stacked = stacks.get(settings.id)
    const sectors: RadialBarSector[] = []
    data.forEach((row, index) => {
      let value: [unknown, unknown]
      if (stacked) {
        value = truncateByDomain(stacked[index]!, numericAxis.domain)
      } else {
        const raw = valueOf(row, settings.dataKey)
        value = Array.isArray(raw) ? [raw[0], raw[1]] : [baseValue, raw]
      }
      let innerRadius: number | undefined | null
      let outerRadius: number | undefined
      let startAngle: number | undefined | null
      let endAngle: number | undefined
      let background: SectorGeometry | undefined
      if (layout === 'radial') {
        startAngle = angleAxis.scale(value[0]) ?? input.startAngle
        endAngle = angleAxis.scale(value[1]) ?? input.endAngle
        innerRadius = categoryCoordinateOf(radiusAxis, row, index, bandSize, position.offset)
        if (isNumber(innerRadius)) {
          outerRadius = innerRadius + position.size
          const delta = endAngle - startAngle
          const min = settings.minPointSize
          if (Math.abs(min) > 0 && Math.abs(delta) < Math.abs(min)) {
            endAngle += mathSign(delta || min) * (Math.abs(min) - Math.abs(delta))
          }
          background = {
            cx: viewBox.cx,
            cy: viewBox.cy,
            innerRadius,
            outerRadius,
            startAngle: input.startAngle,
            endAngle: input.endAngle,
          }
        }
      } else {
        innerRadius = radiusAxis.scale(value[0])
        outerRadius = radiusAxis.scale(value[1])
        startAngle = categoryCoordinateOf(angleAxis, row, index, bandSize, position.offset)
        if (isNumber(innerRadius) && isNumber(outerRadius) && isNumber(startAngle)) {
          endAngle = startAngle + position.size
          const delta = outerRadius - innerRadius
          const min = settings.minPointSize
          if (Math.abs(min) > 0 && Math.abs(delta) < Math.abs(min)) {
            outerRadius += mathSign(delta || min) * (Math.abs(min) - Math.abs(delta))
          }
        }
      }
      if (
        !isNumber(innerRadius) ||
        !isNumber(outerRadius) ||
        !isNumber(startAngle) ||
        !isNumber(endAngle)
      ) {
        return
      }
      sectors.push({
        index,
        value: stacked ? value : value[1],
        payload: row,
        cx: viewBox.cx,
        cy: viewBox.cy,
        innerRadius,
        outerRadius,
        startAngle,
        endAngle,
        background,
      })
    })
    return { settings, sectors }
  })

  const tooltipAxis = layout === 'centric' ? angleAxis : radiusAxis
  return {
    offset: offsetOf(input),
    viewBox,
    angleAxis,
    radiusAxis,
    angleAxisTicks,
    tooltipAxis,
    tooltipTicks: tooltipAxis.tooltipTicks,
    radars,
    radialBars,
  }
}

// ---------------------------------------------------------------------------------------------
// Paths

/** recharts' `getSinglePolygonPath`, for points that are all defined. */
function polygonSegmentPath(points: readonly PolarPoint[]): string {
  return points.reduce(
    (d, point, index) => path`${d}${index === 0 ? 'M' : 'L'}${point.x},${point.y}`,
    '',
  )
}

/**
 * recharts' `Polygon` path through `points`, back to the first and closed. A point that isn't a
 * number breaks the outline, unless `connectNulls` joins over it.
 */
export function polygonPath(
  points: readonly { x: number | null; y: number | null }[],
  connectNulls = false,
): string | null {
  if (!points.length) return null
  const valid = (point: { x: number | null; y: number | null } | undefined): point is PolarPoint =>
    !!point && isNumber(point.x) && isNumber(point.y)
  let segments: PolarPoint[][] = [[]]
  for (const point of points) {
    const last = segments[segments.length - 1]!
    if (valid(point)) last.push(point)
    else if (last.length) segments.push([])
  }
  if (valid(points[0])) segments[segments.length - 1]!.push(points[0])
  if (!segments[segments.length - 1]!.length) segments = segments.slice(0, -1)
  if (connectNulls) segments = [segments.flat()]
  const d = segments.map(polygonSegmentPath).join('')
  return segments.length === 1 ? `${d}Z` : d
}

/** recharts' `getRanglePath`: a ring between a range radar's outline and its baseline. */
export function rangePolygonPath(
  points: readonly PolarPoint[],
  baseLinePoints: readonly PolarPoint[],
  connectNulls = false,
): string {
  const outer = polygonPath(points, connectNulls) ?? ''
  const inner = polygonPath([...baseLinePoints].reverse(), connectNulls) ?? ''
  return `${outer.endsWith('Z') ? outer.slice(0, -1) : outer}L${inner.slice(1)}`
}

/** A polar grid's polygon at `radius`, through `angles` (recharts' `getPolygonPath`, unrounded). */
export function gridPolygonPath(
  radius: number,
  cx: number,
  cy: number,
  angles: readonly number[],
): string {
  let d = ''
  angles.forEach((angle, i) => {
    const point = polarToCartesian(cx, cy, radius, angle)
    d += `${i ? 'L' : 'M'} ${point.x},${point.y}`
  })
  return `${d}Z`
}

function deltaAngle(startAngle: number, endAngle: number): number {
  return mathSign(endAngle - startAngle) * Math.min(Math.abs(endAngle - startAngle), 359.999)
}

function sectorPathPlain(sector: SectorGeometry): string {
  const { cx, cy, innerRadius, outerRadius, startAngle, endAngle } = sector
  const angle = deltaAngle(startAngle, endAngle)
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
  cornerIsExternal: boolean
}) {
  const { cx, cy, radius, angle, sign, isExternal, cornerRadius, cornerIsExternal } = options
  const centerRadius = cornerRadius * (isExternal ? 1 : -1) + radius
  const theta = Math.asin(cornerRadius / centerRadius) / RADIAN
  const centerAngle = cornerIsExternal ? angle : angle + sign * theta
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

function sectorPathWithCorner(
  sector: SectorGeometry & {
    cornerRadius: number
    forceCornerRadius: boolean
    cornerIsExternal: boolean
  },
): string {
  const { cx, cy, innerRadius, outerRadius, cornerRadius, forceCornerRadius, cornerIsExternal } =
    sector
  const { startAngle, endAngle } = sector
  const sign = mathSign(endAngle - startAngle)
  const common = { cx, cy, cornerRadius, cornerIsExternal }
  const start = tangentCircle({ ...common, radius: outerRadius, angle: startAngle, sign })
  const end = tangentCircle({ ...common, radius: outerRadius, angle: endAngle, sign: -sign })
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
    return sectorPathPlain(sector)
  }
  const s = +(sign < 0)
  let d = path`M ${start.lineTangency.x},${start.lineTangency.y}
    A${cornerRadius},${cornerRadius},0,0,${s},${start.circleTangency.x},${start.circleTangency.y}
    A${outerRadius},${outerRadius},0,${+(outerArcAngle > 180)},${s},${end.circleTangency.x},${end.circleTangency.y}
    A${cornerRadius},${cornerRadius},0,0,${s},${end.lineTangency.x},${end.lineTangency.y}
  `
  if (innerRadius > 0) {
    const innerStart = tangentCircle({
      ...common,
      radius: innerRadius,
      angle: startAngle,
      sign,
      isExternal: true,
    })
    const innerEnd = tangentCircle({
      ...common,
      radius: innerRadius,
      angle: endAngle,
      sign: -sign,
      isExternal: true,
    })
    const innerArcAngle = cornerIsExternal
      ? Math.abs(startAngle - endAngle)
      : Math.abs(startAngle - endAngle) - innerStart.theta - innerEnd.theta
    if (innerArcAngle < 0 && cornerRadius === 0) return `${d}L${cx},${cy}Z`
    d += path`L${innerEnd.lineTangency.x},${innerEnd.lineTangency.y}
      A${cornerRadius},${cornerRadius},0,0,${s},${innerEnd.circleTangency.x},${innerEnd.circleTangency.y}
      A${innerRadius},${innerRadius},0,${+(innerArcAngle > 180)},${+(sign > 0)},${innerStart.circleTangency.x},${innerStart.circleTangency.y}
      A${cornerRadius},${cornerRadius},0,0,${s},${innerStart.lineTangency.x},${innerStart.lineTangency.y}Z`
  } else {
    d += path`L${cx},${cy}Z`
  }
  return d
}

/**
 * recharts' `Sector` path: a ring segment from `startAngle` to `endAngle`, its corners rounded by
 * `cornerRadius` (a number, or a percentage of the ring's width). Null where recharts draws
 * nothing: an empty angle, or an outer radius inside the inner one.
 */
export function sectorPath(
  sector: SectorGeometry & {
    cornerRadius?: number | string
    forceCornerRadius?: boolean
    cornerIsExternal?: boolean
  },
): string | null {
  const { innerRadius, outerRadius, startAngle, endAngle } = sector
  if (outerRadius < innerRadius || startAngle === endAngle) return null
  const deltaRadius = outerRadius - innerRadius
  const cornerRadius = percentValue(sector.cornerRadius ?? 0, deltaRadius, 0, true)
  if (cornerRadius > 0 && Math.abs(startAngle - endAngle) < 360) {
    return sectorPathWithCorner({
      ...sector,
      cornerRadius: Math.min(cornerRadius, deltaRadius / 2),
      forceCornerRadius: sector.forceCornerRadius ?? false,
      cornerIsExternal: sector.cornerIsExternal ?? false,
    })
  }
  return sectorPathPlain(sector)
}

// ---------------------------------------------------------------------------------------------
// Labels

export const TEXT_DY = { start: '0.71em', middle: '0.355em', end: '0em' } as const

/** Where a label sits against a sector (or the ring): recharts' polar positions. */
export type PolarPosition =
  | 'insideStart'
  | 'insideEnd'
  | 'end'
  | 'outside'
  | 'center'
  | 'centerTop'
  | 'centerBottom'
  | 'middle'

/**
 * recharts' `renderRadialLabel`: the arc a label along a sector (`insideStart`, `insideEnd`,
 * `end`) runs on, as a `<textPath>`'s path.
 */
export function radialLabelPath(
  viewBox: SectorGeometry & { clockWise?: boolean },
  position: 'insideStart' | 'insideEnd' | 'end',
  offset: number,
): string {
  const { cx, cy, innerRadius, outerRadius, startAngle, endAngle } = viewBox
  const clockWise = viewBox.clockWise ?? false
  const radius = (innerRadius + outerRadius) / 2
  const delta = mathSign(endAngle - startAngle) * Math.min(Math.abs(endAngle - startAngle), 360)
  const sign = delta >= 0 ? 1 : -1
  let labelAngle: number
  let direction: boolean
  if (position === 'insideStart') {
    labelAngle = startAngle + sign * offset
    direction = clockWise
  } else if (position === 'insideEnd') {
    labelAngle = endAngle - sign * offset
    direction = !clockWise
  } else {
    labelAngle = endAngle + sign * offset
    direction = clockWise
  }
  direction = delta <= 0 ? direction : !direction
  const start = polarToCartesian(cx, cy, radius, labelAngle)
  const end = polarToCartesian(cx, cy, radius, labelAngle + (direction ? 1 : -1) * 359)
  return `M${start.x},${start.y}
    A${radius},${radius},0,1,${direction ? 0 : 1},
    ${end.x},${end.y}`
}

/** recharts' `getAttrsOfPolarLabel`: where a label sits against a sector, and its anchors. */
export function polarLabelAttrs(
  viewBox: SectorGeometry,
  offset: number,
  position: Exclude<PolarPosition, 'insideStart' | 'insideEnd' | 'end'> | undefined,
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
// The pointer

/** recharts' `inRangeOfSector`: the pointer's radius and angle, when it is on the ring. */
export function inRangeOfSector(
  point: PolarPoint,
  viewBox: PolarViewBox,
): { radius: number; angle: number } | null {
  const radius = Math.sqrt((point.x - viewBox.cx) ** 2 + (point.y - viewBox.cy) ** 2)
  if (radius < viewBox.innerRadius || radius > viewBox.outerRadius || radius === 0) return null
  let radians = Math.acos((point.x - viewBox.cx) / radius)
  if (point.y > viewBox.cy) radians = 2 * Math.PI - radians
  const angle = radians / RADIAN
  const min = Math.min(Math.floor(viewBox.startAngle / 360), Math.floor(viewBox.endAngle / 360))
  const startAngle = viewBox.startAngle - min * 360
  const endAngle = viewBox.endAngle - min * 360
  let formatted = angle
  let inRange: boolean
  if (startAngle <= endAngle) {
    while (formatted > endAngle) formatted -= 360
    while (formatted < startAngle) formatted += 360
    inRange = formatted >= startAngle && formatted <= endAngle
  } else {
    while (formatted > startAngle) formatted -= 360
    while (formatted < endAngle) formatted += 360
    inRange = formatted >= endAngle && formatted <= startAngle
  }
  return inRange ? { radius, angle: formatted + min * 360 } : null
}

/**
 * recharts' `calculateActiveTickIndex`: the row whose tick is nearest `coordinate` (an angle
 * or a radius), going round the circle on a full-circle angle axis. -1 for none.
 */
export function activeTickIndex(
  coordinate: number,
  ticks: readonly PolarTick[],
  axisType: PolarAxisType,
  axisRange: readonly [number, number],
): number {
  const len = ticks.length
  if (len <= 1) return 0
  const sorted = [...ticks].sort((a, b) => a.coordinate - b.coordinate)
  if (axisType === 'angleAxis' && Math.abs(Math.abs(axisRange[1] - axisRange[0]) - 360) <= 1e-6) {
    for (let i = 0; i < len; i++) {
      const before = (i > 0 ? ticks[i - 1] : ticks[len - 1])!.coordinate
      const cur = ticks[i]!.coordinate
      const after = (i >= len - 1 ? ticks[0] : ticks[i + 1])!.coordinate
      if (mathSign(cur - before) !== mathSign(after - cur)) {
        let same: number
        const diff: [number, number] = [0, 0]
        if (mathSign(after - cur) === mathSign(axisRange[1] - axisRange[0])) {
          same = after
          const curInRange = cur + axisRange[1] - axisRange[0]
          diff[0] = Math.min(curInRange, (curInRange + before) / 2)
          diff[1] = Math.max(curInRange, (curInRange + before) / 2)
        } else {
          same = before
          const afterInRange = after + axisRange[1] - axisRange[0]
          diff[0] = Math.min(cur, (afterInRange + cur) / 2)
          diff[1] = Math.max(cur, (afterInRange + cur) / 2)
        }
        const sameInterval = [Math.min(cur, (same + cur) / 2), Math.max(cur, (same + cur) / 2)]
        if (
          (coordinate > sameInterval[0]! && coordinate <= sameInterval[1]!) ||
          (coordinate >= diff[0] && coordinate <= diff[1])
        ) {
          return ticks[i]!.index
        }
      } else {
        const min = Math.min(before, after)
        const max = Math.max(before, after)
        if (coordinate > (min + cur) / 2 && coordinate <= (max + cur) / 2) return ticks[i]!.index
      }
    }
    return -1
  }
  for (let i = 0; i < len; i++) {
    const cur = sorted[i]!
    const next = sorted[i + 1]
    const prev = sorted[i - 1]
    if (i === 0 && next && coordinate <= (cur.coordinate + next.coordinate) / 2) return cur.index
    if (i === len - 1 && prev && coordinate > (cur.coordinate + prev.coordinate) / 2)
      return cur.index
    if (
      i > 0 &&
      i < len - 1 &&
      prev &&
      next &&
      coordinate > (cur.coordinate + prev.coordinate) / 2 &&
      coordinate <= (cur.coordinate + next.coordinate) / 2
    ) {
      return cur.index
    }
  }
  return -1
}
