/*
 * The geometry of a cartesian chart (area, bar and line charts), computed the way recharts 3
 * computes it, so a Joinery chart draws the same marks in the same places: the plot area left
 * by the margins, axes and legend; each axis's domain, scale and ticks; the grid's lines; and
 * each series' points, stacked where they share a `stackId`.
 *
 * Everything here is a pure function of the chart's settings and size, except text
 * measurement (./text-size.ts), which the axes use to drop overlapping ticks.
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
import { visibleTicks, type Orientation, type Tick, type TickInterval } from './tick-interval.ts'
import type { TextStyle } from './text-size.ts'

/** One row of a chart's `@data`. */
export type Datum = Record<string, unknown>

/** Where a value comes from in a row: a key, or a function of the row. */
export type DataKey = string | number | ((datum: Datum) => unknown)

/** The value at `dataKey` in a row. */
export function valueOf(datum: unknown, dataKey: DataKey | undefined, fallback?: unknown): unknown {
  if (dataKey === undefined || datum === null || datum === undefined) return fallback
  if (typeof dataKey === 'function') return dataKey(datum as Datum)
  return (datum as Datum)[dataKey] ?? fallback
}

/** The space around the plot area, in pixels. */
export interface Margin {
  top?: number
  right?: number
  bottom?: number
  left?: number
}

export interface Box {
  top: number
  right: number
  bottom: number
  left: number
  width: number
  height: number
}

export type Layout = 'horizontal' | 'vertical'
export type ChartName = 'AreaChart' | 'BarChart' | 'LineChart' | 'ComposedChart'
export type StackOffset = 'none' | 'expand' | 'sign' | 'positive' | 'silhouette' | 'wiggle'

/** A domain bound: a number, `auto`, `dataMin`/`dataMax`, `dataMin - 10`, or a function. */
export type DomainBound = number | string | ((value: number) => number)

/** What an axis does, with recharts' defaults filled in. */
export interface AxisSettings {
  axis: 'x' | 'y'
  /** Whether the chart has this axis as an element (`XAxis`/`YAxis`) or made it up. */
  implicit: boolean
  dataKey?: DataKey
  type: 'category' | 'number'
  hide: boolean
  /** An x-axis's height; a y-axis's is the plot's. */
  height: number
  /** A y-axis's width; an x-axis's is the plot's. */
  width: number
  orientation: Orientation
  mirror: boolean
  reversed: boolean
  padding: { start: number; end: number }
  domain?: readonly [DomainBound, DomainBound]
  allowDataOverflow: boolean
  allowDecimals: boolean
  tickCount: number
  ticks?: readonly unknown[]
  tick: boolean
  tickLine: boolean
  axisLine: boolean
  tickSize: number
  tickMargin: number
  minTickGap: number
  interval: TickInterval
  tickFormatter?: (value: never, index: number) => unknown
  unit?: string
  angle: number
  stroke: string
  scale: 'auto' | 'linear' | 'band' | 'point'
}

export const DEFAULT_Y_AXIS_WIDTH = 60
export const DEFAULT_X_AXIS_HEIGHT = 30

/** recharts' defaults for an axis, before an `XAxis` or `YAxis` overrides them. */
export function defaultAxis(axis: 'x' | 'y', implicit: boolean): AxisSettings {
  return {
    axis,
    implicit,
    type: axis === 'x' ? 'category' : 'number',
    hide: implicit,
    height: DEFAULT_X_AXIS_HEIGHT,
    width: DEFAULT_Y_AXIS_WIDTH,
    orientation: axis === 'x' ? 'bottom' : 'left',
    mirror: false,
    reversed: false,
    padding: { start: 0, end: 0 },
    allowDataOverflow: false,
    allowDecimals: true,
    tickCount: 5,
    tick: true,
    tickLine: true,
    axisLine: true,
    tickSize: 6,
    tickMargin: 2,
    minTickGap: 5,
    interval: 'preserveEnd',
    angle: 0,
    stroke: '#666',
    scale: 'auto',
  }
}

export type SeriesType = 'area' | 'bar' | 'line'

/** A series as the chart reads it: its kind, where its values come from, and its stack. */
export interface SeriesSettings {
  id: string
  type: SeriesType
  dataKey: DataKey
  name?: string
  stackId?: string | number
  hide: boolean
  /** An area's base: a number, or `dataMin`/`dataMax`. Default: the axis's base. */
  baseValue?: number | 'dataMin' | 'dataMax'
  barSize?: number
  maxBarSize?: number
}

/** A point of a series, with the value it shows and the row it came from. */
export interface SeriesPoint {
  x: number | null
  y: number | null
  value: unknown
  payload: unknown
  index: number
}

/** A bar: its rectangle and the value it shows. */
export interface BarRectangle {
  x: number
  y: number
  width: number
  height: number
  value: unknown
  payload: unknown
  index: number
  /** The x (or y, in a vertical chart) of the bar's band, for the tooltip's cursor. */
  background: { x: number; y: number; width: number; height: number }
}

export interface SeriesGeometry {
  settings: SeriesSettings
  points: SeriesPoint[]
  /** An area's base: a pixel line, or the stacked series' points below it. */
  base: number | SeriesPoint[]
  bars: BarRectangle[]
}

/** A tick an axis draws: its line, its label's position, and its text. */
export interface AxisTick {
  value: unknown
  index: number
  coordinate: number
  line: { x1: number; y1: number; x2: number; y2: number }
  label: { x: number; y: number }
  text: string
}

export interface AxisGeometry {
  settings: AxisSettings
  /** The axis's own box: beside the plot area for an axis that is drawn. */
  box: { x: number; y: number; width: number; height: number }
  line: { x1: number; y1: number; x2: number; y2: number }
  ticks: AxisTick[]
  textAnchor: 'start' | 'middle' | 'end'
  /** The first line's `dy`, which sets the label's baseline against its anchor point. */
  dy: string
}

export interface CartesianInput {
  chartName: ChartName
  layout: Layout
  width: number
  height: number
  margin: Required<Margin>
  data: readonly unknown[]
  xAxis: AxisSettings
  yAxis: AxisSettings
  series: readonly SeriesSettings[]
  stackOffset: StackOffset
  barCategoryGap: number | string
  barGap: number | string
  barSize?: number
  maxBarSize?: number
  /** The legend's measured box and where it sits, when the chart has one. */
  legend?: {
    width: number
    height: number
    verticalAlign: 'top' | 'middle' | 'bottom'
    align: 'left' | 'center' | 'right'
    layout: Layout
  }
  /** The tick labels' font, read from the rendered labels (as recharts reads it). */
  tickStyle: { x: TextStyle; y: TextStyle }
  /** Whether to drop overlapping ticks by measuring their labels; off in a server render. */
  measure: boolean
}

export interface CartesianGeometry {
  offset: Box
  xAxis: AxisGeometry
  yAxis: AxisGeometry
  /** The category axis's ticks, one per row, as the tooltip finds the row under the pointer. */
  categoryTicks: { index: number; coordinate: number; value: unknown }[]
  bandSize: number
  grid: { horizontal: number[]; vertical: number[] }
  series: SeriesGeometry[]
  /** The value axis's domain, after stacking and nice ticks. */
  valueDomain: [number, number]
}

/** A percentage of `total` (`'10%'`), or a number as is. */
export function percentValue(
  value: number | string | undefined,
  total: number,
  fallback = 0,
): number {
  if (value === undefined || value === null) return fallback
  if (typeof value === 'number') return value
  const trimmed = value.trim()
  if (trimmed.endsWith('%')) {
    const ratio = parseFloat(trimmed) / 100
    return Number.isFinite(ratio) ? total * ratio : fallback
  }
  const number = parseFloat(trimmed)
  return Number.isFinite(number) ? number : fallback
}

function isNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value)
}

/** recharts' plot area: the chart less its margins, its drawn axes and its legend. */
export function plotArea(
  input: Pick<CartesianInput, 'width' | 'height' | 'margin' | 'xAxis' | 'yAxis' | 'legend'>,
): Box {
  const { margin, xAxis, yAxis, legend } = input
  const shown = (axis: AxisSettings) => !axis.hide && !axis.mirror
  const offset = {
    top: margin.top + (shown(xAxis) && xAxis.orientation === 'top' ? xAxis.height : 0),
    bottom: margin.bottom + (shown(xAxis) && xAxis.orientation === 'bottom' ? xAxis.height : 0),
    left: margin.left + (shown(yAxis) && yAxis.orientation === 'left' ? yAxis.width : 0),
    right: margin.right + (shown(yAxis) && yAxis.orientation === 'right' ? yAxis.width : 0),
  }
  if (legend) {
    const { align, verticalAlign, layout } = legend
    if (
      (layout === 'vertical' || (layout === 'horizontal' && verticalAlign === 'middle')) &&
      align !== 'center'
    ) {
      offset[align] += legend.width
    } else if (
      (layout === 'horizontal' || (layout === 'vertical' && align === 'center')) &&
      verticalAlign !== 'middle'
    ) {
      offset[verticalAlign] += legend.height
    }
  }
  return {
    ...offset,
    width: Math.max(input.width - offset.left - offset.right, 0),
    height: Math.max(input.height - offset.top - offset.bottom, 0),
  }
}

/** Which axis lays out the categories: x, unless the chart is vertical. */
function categoryAxisOf(layout: Layout): 'x' | 'y' {
  return layout === 'horizontal' ? 'x' : 'y'
}

/** recharts' `combineRealScaleType`: a line or area chart puts categories on points, bars in bands. */
function scaleTypeOf(
  axis: AxisSettings,
  chartName: ChartName,
  hasBar: boolean,
): 'point' | 'band' | 'linear' {
  if (axis.scale !== 'auto') return axis.scale
  if (axis.type === 'category') {
    if (
      chartName === 'LineChart' ||
      chartName === 'AreaChart' ||
      (chartName === 'ComposedChart' && !hasBar)
    ) {
      return 'point'
    }
    return 'band'
  }
  return 'linear'
}

/** The pixel range an axis maps to, before `reversed`. */
function rangeOf(axis: AxisSettings, offset: Box, layout: Layout): [number, number] {
  if (axis.axis === 'x') {
    return [offset.left + axis.padding.start, offset.left + offset.width - axis.padding.end]
  }
  // A y-axis runs bottom to top, but categories in a vertical chart run top to bottom.
  if (layout === 'horizontal' || axis.type === 'number') {
    return [offset.top + offset.height - axis.padding.end, offset.top + axis.padding.start]
  }
  return [offset.top + axis.padding.start, offset.top + offset.height - axis.padding.end]
}

const OFFSETS = {
  none: stackOffsetNone,
  expand: stackOffsetExpand,
  silhouette: stackOffsetSilhouette,
  wiggle: stackOffsetWiggle,
}

/** recharts' `sign` offset: positives stack up from 0, negatives down. */
function offsetSign(series: number[][][], order: Iterable<number>): void {
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
      } else {
        point[0] = negative
        point[1] = negative + value
        negative = point[1]
      }
    }
  }
}

/** recharts' `positive` offset: only positives stack; negatives count as 0. */
function offsetPositive(series: number[][][], order: Iterable<number>): void {
  const n = series[0]?.length ?? 0
  for (let j = 0; j < n; ++j) {
    let positive = 0
    for (const i of order) {
      const point = series[i]![j]!
      const value = Number.isNaN(point[1]!) ? point[0]! : point[1]!
      if (value >= 0) {
        point[0] = positive
        point[1] = positive + value
        positive = point[1]
      } else {
        point[0] = 0
        point[1] = 0
      }
    }
  }
}

/** Each stacked series' `[bottom, top]` per row, by series id. */
function stackGroups(input: CartesianInput): Map<string, [number, number][]> {
  const groups = new Map<string, SeriesSettings[]>()
  for (const series of input.series) {
    if (series.hide || series.stackId === undefined || series.stackId === null) continue
    // Bars and areas stack separately, as recharts keeps one group per kind and stack id.
    const key = `${series.type}:${series.stackId}`
    groups.set(key, [...(groups.get(key) ?? []), series])
  }
  const result = new Map<string, [number, number][]>()
  for (const members of groups.values()) {
    const offset =
      input.stackOffset === 'sign'
        ? offsetSign
        : input.stackOffset === 'positive'
          ? offsetPositive
          : OFFSETS[input.stackOffset]
    const stacked = d3Stack<unknown, number>()
      .keys(members.map((_, i) => i))
      .value((datum, i) => {
        const value = Number(valueOf(datum, members[i]!.dataKey))
        return Number.isFinite(value) ? value : 0
      })
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

/** A domain bound the chart resolves from the data: `auto`, `dataMin - 5`, a function. */
function resolveBound(
  bound: DomainBound,
  data: [number, number],
  which: 0 | 1,
): number | undefined {
  if (isNumber(bound)) return bound
  if (typeof bound === 'function') return bound(data[which])
  if (bound === 'auto') return data[which]
  const match = /^data(Min|Max)\s*([+-])?\s*(\d+(?:\.\d+)?)?$/.exec(String(bound))
  if (match) {
    const base = match[1] === 'Min' ? data[0] : data[1]
    const delta = match[3] ? Number(match[3]) : 0
    return match[2] === '-' ? base - delta : base + delta
  }
  return undefined
}

/** The value axis's domain: the data's (stacked) extent, the user's `domain`, and nice ticks. */
function valueDomain(
  input: CartesianInput,
  axis: AxisSettings,
  stacks: Map<string, [number, number][]>,
): { domain: [number, number]; niceTicks?: number[] } {
  const definition = axis.domain ?? [0, 'auto']
  if (input.stackOffset === 'expand' && stacks.size) {
    const ticks = getNiceTickValues([0, 1], axis.tickCount, axis.allowDecimals)
    return { domain: [0, 1], niceTicks: ticks }
  }
  let min = Infinity
  let max = -Infinity
  for (const series of input.series) {
    if (series.hide) continue
    const stacked = stacks.get(series.id)
    if (stacked) {
      for (const [bottom, top] of stacked) {
        min = Math.min(min, bottom, top)
        max = Math.max(max, bottom, top)
      }
      continue
    }
    for (const datum of input.data) {
      const raw = valueOf(datum, series.dataKey)
      const values = Array.isArray(raw) ? raw : [raw]
      for (const value of values) {
        const number = Number(value)
        if (value === null || value === undefined || value === '' || !Number.isFinite(number))
          continue
        min = Math.min(min, number)
        max = Math.max(max, number)
      }
    }
  }
  const data: [number, number] = Number.isFinite(min) ? [min, max] : [0, 0]
  let lower = resolveBound(definition[0], data, 0) ?? data[0]
  let upper = resolveBound(definition[1], data, 1) ?? data[1]
  if (!axis.allowDataOverflow) {
    lower = Math.min(lower, data[0])
    upper = Math.max(upper, data[1])
  }
  const hasAuto = definition[0] === 'auto' || definition[1] === 'auto'
  let niceTicks: number[] | undefined
  if (axis.ticks) {
    niceTicks = undefined
  } else if (hasAuto) {
    niceTicks = getNiceTickValues([lower, upper], axis.tickCount, axis.allowDecimals)
  } else {
    niceTicks = getTickValuesFixedDomain([lower, upper], axis.tickCount, axis.allowDecimals)
  }
  if (niceTicks?.length) {
    lower = Math.min(lower, niceTicks[0]!)
    upper = Math.max(upper, niceTicks[niceTicks.length - 1]!)
  }
  return { domain: [lower, upper], niceTicks }
}

/** recharts' `getBaseValue`: where an area or bar starts on the value axis. */
function baseValueOf(domain: [number, number], baseValue: SeriesSettings['baseValue']): number {
  const [a, b] = domain
  const domainMax = Math.max(a, b)
  const domainMin = Math.min(a, b)
  if (isNumber(baseValue)) return baseValue
  if (baseValue === 'dataMin') return domainMin
  if (baseValue === 'dataMax') return domainMax
  return domainMax < 0 ? domainMax : Math.max(domainMin, 0)
}

interface BarPosition {
  offset: number
  size: number
}

/** recharts' `getBarPositions`: each bar slot's offset in the band and its width. */
function barPositions(
  bandSize: number,
  slots: { barSize?: number }[],
  barGap: number | string,
  barCategoryGap: number | string,
  maxBarSize?: number,
): BarPosition[] {
  const len = slots.length
  if (len < 1) return []
  let realBarGap = percentValue(barGap, bandSize)
  if (isNumber(slots[0]!.barSize)) {
    let useFull = false
    let fullBarSize = bandSize / len
    let sum = slots.reduce((total, slot) => total + (slot.barSize ?? 0), 0) + (len - 1) * realBarGap
    if (sum >= bandSize) {
      sum -= (len - 1) * realBarGap
      realBarGap = 0
    }
    if (sum >= bandSize && fullBarSize > 0) {
      useFull = true
      fullBarSize *= 0.9
      sum = len * fullBarSize
    }
    const offset = ((bandSize - sum) / 2) >> 0
    let previous = { offset: offset - realBarGap, size: 0 }
    return slots.map(slot => {
      const position = {
        offset: previous.offset + previous.size + realBarGap,
        size: useFull ? fullBarSize : (slot.barSize ?? 0),
      }
      previous = position
      return position
    })
  }
  const offset = percentValue(barCategoryGap, bandSize)
  if (bandSize - 2 * offset - (len - 1) * realBarGap <= 0) realBarGap = 0
  let originalSize = (bandSize - 2 * offset - (len - 1) * realBarGap) / len
  if (originalSize > 1) originalSize >>= 0
  const size = isNumber(maxBarSize) ? Math.min(originalSize, maxBarSize) : originalSize
  return slots.map((_, i) => ({
    offset: offset + (originalSize + realBarGap) * i + (originalSize - size) / 2,
    size,
  }))
}

function formatTick(axis: AxisSettings, value: unknown, index: number): string {
  const formatted = axis.tickFormatter ? axis.tickFormatter(value as never, index) : value
  return `${formatted ?? ''}${axis.unit ?? ''}`
}

/** recharts' `getTickLineCoord`: a tick's line and where its label is anchored. */
function tickGeometry(
  tick: Tick,
  box: AxisGeometry['box'],
  axis: AxisSettings,
): Pick<AxisTick, 'line' | 'label'> {
  const { x, y, width, height } = box
  const sign = axis.mirror ? -1 : 1
  const size = axis.tickSize
  const margin = axis.tickMargin
  const coord = isNumber(tick.tickCoord) ? tick.tickCoord : tick.coordinate
  let x1: number, x2: number, y1: number, y2: number, tx: number, ty: number
  switch (axis.orientation) {
    case 'top':
      x1 = x2 = tick.coordinate
      y2 = y + Number(!axis.mirror) * height
      y1 = y2 - sign * size
      ty = y1 - sign * margin
      tx = coord
      break
    case 'left':
      y1 = y2 = tick.coordinate
      x2 = x + Number(!axis.mirror) * width
      x1 = x2 - sign * size
      tx = x1 - sign * margin
      ty = coord
      break
    case 'right':
      y1 = y2 = tick.coordinate
      x2 = x + Number(axis.mirror) * width
      x1 = x2 + sign * size
      tx = x1 + sign * margin
      ty = coord
      break
    default:
      x1 = x2 = tick.coordinate
      y2 = y + Number(axis.mirror) * height
      y1 = y2 + sign * size
      ty = y1 + sign * margin
      tx = coord
  }
  return { line: { x1, y1, x2, y2 }, label: { x: tx, y: ty } }
}

function axisLineOf(axis: AxisSettings, box: AxisGeometry['box']): AxisGeometry['line'] {
  const { x, y, width, height } = box
  if (axis.orientation === 'top' || axis.orientation === 'bottom') {
    const needHeight = Number(
      (axis.orientation === 'top' && !axis.mirror) ||
        (axis.orientation === 'bottom' && axis.mirror),
    )
    return { x1: x, y1: y + needHeight * height, x2: x + width, y2: y + needHeight * height }
  }
  const needWidth = Number(
    (axis.orientation === 'left' && !axis.mirror) || (axis.orientation === 'right' && axis.mirror),
  )
  return { x1: x + needWidth * width, y1: y, x2: x + needWidth * width, y2: y + height }
}

/** An axis's box, beside the plot area on its side. */
function axisBox(axis: AxisSettings, offset: Box): AxisGeometry['box'] {
  if (axis.axis === 'x') {
    const y = axis.orientation === 'top' ? offset.top - axis.height : offset.top + offset.height
    return {
      x: offset.left,
      y: axis.mirror
        ? axis.orientation === 'top'
          ? offset.top
          : offset.top + offset.height - axis.height
        : y,
      width: offset.width,
      height: axis.height,
    }
  }
  const x =
    axis.orientation === 'left'
      ? axis.mirror
        ? offset.left
        : offset.left - axis.width
      : axis.mirror
        ? offset.left + offset.width - axis.width
        : offset.left + offset.width
  return { x, y: offset.top, width: axis.width, height: offset.height }
}

/**
 * Everything a cartesian chart draws, in pixels. recharts' selectors, in one pass: the plot
 * area, both axes' scales and ticks, the grid, and every series' points and bars.
 */
export function cartesianGeometry(input: CartesianInput): CartesianGeometry {
  const { layout, data } = input
  const offset = plotArea(input)
  const categoryKey = categoryAxisOf(layout)
  const categoryAxis = categoryKey === 'x' ? input.xAxis : input.yAxis
  const valueAxis = categoryKey === 'x' ? input.yAxis : input.xAxis
  const hasBar = input.series.some(series => series.type === 'bar' && !series.hide)

  // The category axis: one slot per row (or the axis's own numbers, for type="number").
  const categoryValues = data.map((datum, index) =>
    categoryAxis.dataKey === undefined ? index : valueOf(datum, categoryAxis.dataKey),
  )
  const categoryScaleType = scaleTypeOf(categoryAxis, input.chartName, hasBar)
  let categoryRange = rangeOf(categoryAxis, offset, layout)
  if (categoryAxis.reversed) categoryRange = [categoryRange[1], categoryRange[0]]
  let bandSize = 0
  let categoryPosition: (index: number) => number | null
  if (categoryScaleType === 'band' || categoryScaleType === 'point') {
    const indexes = data.map((_, index) => index)
    const scale =
      categoryScaleType === 'band'
        ? scaleBand<number>().domain(indexes).range(categoryRange)
        : scalePoint<number>().domain(indexes).range(categoryRange)
    bandSize = scale.bandwidth()
    categoryPosition = index => scale(index) ?? null
  } else {
    const numbers = categoryValues.map(Number).filter(Number.isFinite)
    const extent: [number, number] = numbers.length
      ? [Math.min(...numbers), Math.max(...numbers)]
      : [0, 0]
    const scale = scaleLinear().domain(extent).range(categoryRange)
    categoryPosition = index => {
      const value = Number(categoryValues[index])
      return Number.isFinite(value) ? scale(value) : null
    }
  }
  const categoryOffset = categoryScaleType === 'band' ? bandSize / 2 : 0
  const categoryTicks = data.map((_, index) => ({
    index,
    coordinate: (categoryPosition(index) ?? 0) + categoryOffset,
    value: categoryValues[index],
  }))

  // The value axis: the data's extent, stacked, made nice.
  const stacks = stackGroups(input)
  const { domain, niceTicks } = valueDomain(input, valueAxis, stacks)
  let valueRange = rangeOf(valueAxis, offset, layout)
  if (valueAxis.reversed) valueRange = [valueRange[1], valueRange[0]]
  const valueScale = scaleLinear().domain(domain).range(valueRange)

  // Ticks: every category, or the value axis's nice ticks.
  const valueTickValues =
    (valueAxis.ticks as number[] | undefined) ?? niceTicks ?? valueScale.ticks(valueAxis.tickCount)
  const rawCategoryTicks: Tick[] = (
    categoryAxis.ticks
      ? categoryAxis.ticks.map((value, index) => ({
          index,
          value,
          coordinate: (categoryPosition(categoryValues.indexOf(value)) ?? NaN) + categoryOffset,
        }))
      : categoryTicks.map(tick => ({ ...tick }))
  ).filter(tick => Number.isFinite(tick.coordinate))
  const rawValueTicks: Tick[] = valueTickValues
    .map((value, index) => ({ index, value, coordinate: valueScale(value) }))
    .filter(tick => Number.isFinite(tick.coordinate))

  const viewBox = { x: 0, y: 0, width: input.width, height: input.height }
  const axisGeometry = (axis: AxisSettings, rawTicks: Tick[]): AxisGeometry => {
    const box = axisBox(axis, offset)
    const style = axis.axis === 'x' ? input.tickStyle.x : input.tickStyle.y
    const shown = input.measure
      ? visibleTicks({
          ticks: rawTicks,
          viewBox,
          orientation: axis.orientation,
          interval: axis.interval,
          minTickGap: axis.minTickGap,
          tickFormatter: axis.tickFormatter,
          unit: axis.unit,
          tick: axis.tick,
          angle: axis.angle,
          style,
        })
      : rawTicks.filter(
          (_, i) => typeof axis.interval !== 'number' || i % (axis.interval + 1) === 0,
        )
    const vertical = axis.orientation === 'left' || axis.orientation === 'right'
    return {
      settings: axis,
      box,
      line: axisLineOf(axis, box),
      ticks: shown.map(tick => ({
        value: tick.value,
        index: tick.index,
        coordinate: tick.coordinate,
        ...tickGeometry(tick, box, axis),
        text: formatTick(axis, tick.value, tick.index),
      })),
      textAnchor:
        axis.orientation === 'left'
          ? axis.mirror
            ? 'start'
            : 'end'
          : axis.orientation === 'right'
            ? axis.mirror
              ? 'end'
              : 'start'
            : 'middle',
      dy: vertical ? '0.355em' : (axis.orientation === 'top') !== axis.mirror ? '0em' : '0.71em',
    }
  }
  const xTicks = categoryKey === 'x' ? rawCategoryTicks : rawValueTicks
  const yTicks = categoryKey === 'x' ? rawValueTicks : rawCategoryTicks
  const xAxis = axisGeometry(input.xAxis, xTicks)
  const yAxis = axisGeometry(input.yAxis, yTicks)

  // The grid: the ticks each axis would draw (measured in the page's own font, as recharts'
  // grid measures them), plus the plot area's edges.
  const gridTicks = (axis: AxisSettings, rawTicks: Tick[]) => {
    const shown = input.measure
      ? visibleTicks({
          ticks: rawTicks,
          viewBox,
          orientation: axis.orientation,
          interval: axis.interval,
          minTickGap: axis.minTickGap,
          tickFormatter: axis.tickFormatter,
          unit: axis.unit,
          tick: axis.tick,
          angle: axis.angle,
          style: {},
        })
      : rawTicks
    return shown.map(tick => tick.coordinate)
  }
  const withEdges = (coordinates: number[], min: number, max: number) => {
    const result = coordinates.slice()
    if (!result.includes(min)) result.push(min)
    if (!result.includes(max)) result.push(max)
    return result
  }
  // The grid of a band axis sits on the band's middle, like its ticks; a point axis's on the points.
  const grid = {
    horizontal: withEdges(gridTicks(input.yAxis, yTicks), offset.top, offset.top + offset.height),
    vertical: withEdges(gridTicks(input.xAxis, xTicks), offset.left, offset.left + offset.width),
  }

  // The series.
  const toPixel = (
    category: number | null,
    value: number | null,
  ): { x: number | null; y: number | null } =>
    layout === 'horizontal' ? { x: category, y: value } : { x: value, y: category }
  const visibleBars = input.series.filter(series => series.type === 'bar' && !series.hide)
  const slots: { key: string; barSize?: number }[] = []
  for (const bar of visibleBars) {
    const key =
      bar.stackId !== undefined && bar.stackId !== null ? `stack:${bar.stackId}` : `bar:${bar.id}`
    if (!slots.some(slot => slot.key === key))
      slots.push({ key, barSize: bar.barSize ?? input.barSize })
  }
  const positions = barPositions(
    bandSize,
    slots,
    input.barGap,
    input.barCategoryGap,
    input.maxBarSize,
  )

  const series = input.series.map((settings): SeriesGeometry => {
    const stacked = stacks.get(settings.id)
    const seriesBase = baseValueOf(domain, settings.baseValue)
    if (settings.type === 'bar') {
      const key =
        settings.stackId !== undefined && settings.stackId !== null
          ? `stack:${settings.stackId}`
          : `bar:${settings.id}`
      const position = positions[slots.findIndex(slot => slot.key === key)]
      const bars: BarRectangle[] = []
      if (!settings.hide && position) {
        data.forEach((datum, index) => {
          const start = categoryPosition(index)
          if (start === null) return
          const raw = valueOf(datum, settings.dataKey)
          let low: number
          let high: number
          if (stacked) {
            ;[low, high] = stacked[index]!
          } else if (Array.isArray(raw)) {
            ;[low, high] = [Number(raw[0]), Number(raw[1])]
          } else {
            low = seriesBase
            high = Number(raw)
          }
          if (!Number.isFinite(high) || !Number.isFinite(low)) return
          const valueStart = valueScale(low)
          const valueEnd = valueScale(high)
          const bandStart = start + position.offset
          const background =
            layout === 'horizontal'
              ? { x: bandStart, y: offset.top, width: position.size, height: offset.height }
              : { x: offset.left, y: bandStart, width: offset.width, height: position.size }
          bars.push(
            layout === 'horizontal'
              ? {
                  x: bandStart,
                  y: valueEnd,
                  width: position.size,
                  height: valueStart - valueEnd,
                  value: raw,
                  payload: datum,
                  index,
                  background,
                }
              : {
                  x: valueStart,
                  y: bandStart,
                  width: valueEnd - valueStart,
                  height: position.size,
                  value: raw,
                  payload: datum,
                  index,
                  background,
                },
          )
        })
      }
      return { settings, points: [], base: valueScale(seriesBase), bars }
    }
    const points: SeriesPoint[] = data.map((datum, index) => {
      const category = categoryPosition(index)
      const center = category === null ? null : category + categoryOffset
      const raw = valueOf(datum, settings.dataKey)
      let top: number | null
      if (stacked) {
        top = raw === null || raw === undefined ? null : valueScale(stacked[index]![1])
      } else if (Array.isArray(raw)) {
        top = Number.isFinite(Number(raw[1])) ? valueScale(Number(raw[1])) : null
      } else {
        const number = Number(raw)
        top =
          raw === null || raw === undefined || raw === '' || !Number.isFinite(number)
            ? null
            : valueScale(number)
      }
      return { ...toPixel(center, top), value: raw, payload: datum, index }
    })
    let areaBase: number | SeriesPoint[] = valueScale(seriesBase)
    if (settings.type === 'area') {
      if (stacked) {
        areaBase = data.map((datum, index) => {
          const category = categoryPosition(index)
          const center = category === null ? null : category + categoryOffset
          return {
            ...toPixel(center, valueScale(stacked[index]![0])),
            value: undefined,
            payload: datum,
            index,
          }
        })
      } else if (data.some(datum => Array.isArray(valueOf(datum, settings.dataKey)))) {
        areaBase = data.map((datum, index) => {
          const category = categoryPosition(index)
          const center = category === null ? null : category + categoryOffset
          const raw = valueOf(datum, settings.dataKey)
          const low = Array.isArray(raw) ? Number(raw[0]) : seriesBase
          return { ...toPixel(center, valueScale(low)), value: undefined, payload: datum, index }
        })
      }
    }
    return { settings, points, base: areaBase, bars: [] }
  })

  return {
    offset,
    xAxis,
    yAxis,
    categoryTicks,
    bandSize,
    grid,
    series,
    valueDomain: domain,
  }
}

/** The row under a pointer at `position` along the category axis: the nearest tick. */
export function activeIndexAt(
  ticks: readonly { index: number; coordinate: number }[],
  position: number,
): number | null {
  if (!ticks.length) return null
  let best = ticks[0]!
  for (const tick of ticks) {
    if (Math.abs(tick.coordinate - position) < Math.abs(best.coordinate - position)) best = tick
  }
  return best.index
}

/** recharts' `getTooltipTranslateXY`: where the tooltip box goes on one axis. */
export function tooltipTranslate(options: {
  coordinate: number
  offset: number
  tooltipSize: number
  viewBoxStart: number
  viewBoxSize: number
  allowEscape: boolean
  reverse: boolean
  position?: number
}): number {
  const {
    coordinate,
    offset,
    tooltipSize,
    viewBoxStart,
    viewBoxSize,
    allowEscape,
    reverse,
    position,
  } = options
  if (isNumber(position)) return position
  const negative = coordinate - tooltipSize - (offset > 0 ? offset : 0)
  const positive = coordinate + offset
  if (allowEscape) return reverse ? negative : positive
  if (reverse) {
    return negative < viewBoxStart
      ? Math.max(positive, viewBoxStart)
      : Math.max(negative, viewBoxStart)
  }
  return positive + tooltipSize > viewBoxStart + viewBoxSize
    ? Math.max(negative, viewBoxStart)
    : Math.max(positive, viewBoxStart)
}
