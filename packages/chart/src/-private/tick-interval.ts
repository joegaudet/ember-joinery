/*
 * Which of an axis's ticks to show, so their labels don't overlap: recharts' `interval`
 * (recharts/src/cartesian/getTicks.ts and getEquidistantTicks.ts), ported as is.
 */
import { getStringSize, type TextStyle } from './text-size.ts'

/** One tick: its value, where it sits along the axis, and its index among the axis's ticks. */
export interface Tick {
  value: unknown
  coordinate: number
  index: number
  /** Where its label is drawn, when it is moved to stay inside the chart. */
  tickCoord?: number
  isShow?: boolean
}

/** How an axis thins its ticks: as recharts' `interval` prop. */
export type TickInterval =
  | number
  | 'preserveStart'
  | 'preserveEnd'
  | 'preserveStartEnd'
  | 'equidistantPreserveStart'
  | 'equidistantPreserveEnd'

export type Orientation = 'top' | 'bottom' | 'left' | 'right'

export interface TickIntervalOptions {
  ticks: Tick[]
  /** The area the labels must fit in: the whole chart. */
  viewBox: { x: number; y: number; width: number; height: number }
  orientation: Orientation
  interval: TickInterval
  minTickGap: number
  tickFormatter?: (value: never, index: number) => unknown
  unit?: string
  /** Whether labels are drawn at all (`tick={false}` draws none). */
  tick: boolean
  angle?: number
  style: TextStyle
}

type GetSize = (tick: Tick, index: number) => number

function isVisible(
  sign: number,
  position: number,
  getSize: () => number,
  start: number,
  end: number,
): boolean {
  if (sign * position < sign * start || sign * position > sign * end) return false
  const size = getSize()
  return sign * (position - (sign * size) / 2 - start) >= 0 && sign * (position + (sign * size) / 2 - end) <= 0
}

function everyNth<T>(items: T[], n: number): T[] {
  if (n < 1) return []
  if (n === 1) return items
  return items.filter((_, i) => i % n === 0)
}

function ticksEnd(sign: number, start: number, end: number, getSize: GetSize, ticks: Tick[], gap: number): Tick[] {
  const result = ticks.slice()
  for (let i = result.length - 1; i >= 0; i--) {
    let entry = result[i]!
    let size: number | undefined
    const tickSize = () => (size ??= getSize(ticks[i]!, i))
    if (i === result.length - 1) {
      const overflow = sign * (entry.coordinate + (sign * tickSize()) / 2 - end)
      entry = { ...entry, tickCoord: overflow > 0 ? entry.coordinate - overflow * sign : entry.coordinate }
    } else {
      entry = { ...entry, tickCoord: entry.coordinate }
    }
    result[i] = entry
    if (isVisible(sign, entry.tickCoord!, tickSize, start, end)) {
      end = entry.tickCoord! - sign * (tickSize() / 2 + gap)
      result[i] = { ...entry, isShow: true }
    }
  }
  return result
}

function ticksStart(
  sign: number,
  start: number,
  end: number,
  getSize: GetSize,
  ticks: Tick[],
  gap: number,
  preserveEnd: boolean,
): Tick[] {
  const result = ticks.slice()
  const len = result.length
  if (preserveEnd) {
    const tail = ticks[len - 1]
    if (tail) {
      const tailSize = getSize(tail, len - 1)
      const overflow = sign * (tail.coordinate + (sign * tailSize) / 2 - end)
      const entry = { ...tail, tickCoord: overflow > 0 ? tail.coordinate - overflow * sign : tail.coordinate }
      result[len - 1] = entry
      if (isVisible(sign, entry.tickCoord, () => tailSize, start, end)) {
        end = entry.tickCoord - sign * (tailSize / 2 + gap)
        result[len - 1] = { ...entry, isShow: true }
      }
    }
  }
  const count = preserveEnd ? len - 1 : len
  for (let i = 0; i < count; i++) {
    let entry = result[i]!
    let size: number | undefined
    const tickSize = () => (size ??= getSize(ticks[i]!, i))
    if (i === 0) {
      const overflow = sign * (entry.coordinate - (sign * tickSize()) / 2 - start)
      entry = { ...entry, tickCoord: overflow < 0 ? entry.coordinate - overflow * sign : entry.coordinate }
    } else {
      entry = { ...entry, tickCoord: entry.coordinate }
    }
    result[i] = entry
    if (isVisible(sign, entry.tickCoord!, tickSize, start, end)) {
      start = entry.tickCoord! + sign * (tickSize() / 2 + gap)
      result[i] = { ...entry, isShow: true }
    }
  }
  return result
}

function equidistant(sign: number, initialStart: number, end: number, getSize: GetSize, ticks: Tick[], gap: number): Tick[] {
  for (let step = 1; step <= ticks.length; step++) {
    let start = initialStart
    let ok = true
    for (let index = 0; index < ticks.length; index += step) {
      const entry = ticks[index]!
      let size: number | undefined
      const tickSize = () => (size ??= getSize(entry, index))
      if (index !== 0 && !isVisible(sign, entry.coordinate, tickSize, start, end)) {
        ok = false
        break
      }
      start = entry.coordinate + sign * (tickSize() / 2 + gap)
    }
    if (ok) return everyNth(ticks, step)
  }
  return []
}

function equidistantPreserveEnd(
  sign: number,
  initialStart: number,
  end: number,
  getSize: GetSize,
  ticks: Tick[],
  gap: number,
): Tick[] {
  const len = ticks.length
  for (let step = 1; step <= len; step++) {
    const offset = (len - 1) % step
    let start = initialStart
    let ok = true
    for (let index = offset; index < len; index += step) {
      const entry = ticks[index]!
      let size: number | undefined
      const tickSize = () => (size ??= getSize(entry, index))
      if (index !== offset && !isVisible(sign, entry.coordinate, tickSize, start, end)) {
        ok = false
        break
      }
      start = entry.coordinate + sign * (tickSize() / 2 + gap)
    }
    if (ok) {
      const kept: Tick[] = []
      for (let index = offset; index < len; index += step) kept.push(ticks[index]!)
      return kept
    }
  }
  return []
}

/** The width a label takes along a horizontal axis once rotated by `angle` degrees. */
function angledWidth(size: { width: number; height: number }, angle = 0): number {
  if (angle % 180 === 0) return size.width
  const radians = (angle * Math.PI) / 180
  const sinAngle = Math.abs(Math.sin(radians))
  const cosAngle = Math.abs(Math.cos(radians))
  const angleThreshold = Math.atan(size.height / size.width)
  return radians > angleThreshold && radians < Math.PI - angleThreshold
    ? size.height / sinAngle
    : size.width / cosAngle
}

/** The ticks to draw, each with where its label goes (`tickCoord`). */
export function visibleTicks(options: TickIntervalOptions): Tick[] {
  const { ticks, viewBox, orientation, interval, minTickGap, tickFormatter, unit, style } = options
  if (!ticks.length || !options.tick) return []
  if (typeof interval === 'number') return everyNth(ticks, interval + 1)

  const sizeKey = orientation === 'top' || orientation === 'bottom' ? 'width' : 'height'
  const unitSize = unit && sizeKey === 'width' ? getStringSize(unit, style) : { width: 0, height: 0 }
  const getSize: GetSize = (tick, index) => {
    const value = tickFormatter ? tickFormatter(tick.value as never, index) : tick.value
    const size = getStringSize(value, style)
    return sizeKey === 'width'
      ? angledWidth({ width: size.width + unitSize.width, height: size.height + unitSize.height }, options.angle)
      : size.height
  }
  const [first, second] = ticks
  const sign = second ? Math.sign(second.coordinate - first!.coordinate) || 1 : 1
  const isWidth = sizeKey === 'width'
  const { x, y, width, height } = viewBox
  const start = sign === 1 ? (isWidth ? x : y) : isWidth ? x + width : y + height
  const end = sign === 1 ? (isWidth ? x + width : y + height) : isWidth ? x : y

  if (interval === 'equidistantPreserveStart') return equidistant(sign, start, end, getSize, ticks, minTickGap)
  if (interval === 'equidistantPreserveEnd')
    return equidistantPreserveEnd(sign, start, end, getSize, ticks, minTickGap)
  const candidates =
    interval === 'preserveStart' || interval === 'preserveStartEnd'
      ? ticksStart(sign, start, end, getSize, ticks, minTickGap, interval === 'preserveStartEnd')
      : ticksEnd(sign, start, end, getSize, ticks, minTickGap)
  return candidates.filter(tick => tick.isShow)
}
