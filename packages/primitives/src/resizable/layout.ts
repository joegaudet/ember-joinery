// The layout math of a resizable group, as react-resizable-panels (v4) does it: a layout is
// one size per panel, in percent of the space the panels share, adding up to 100. Pure
// functions, so they are easy to follow and to test.

/** A size as a panel's arguments give it: a number of pixels, or a string with a unit. */
export type PanelSize = number | string

/** The units a size can be in. A string without a unit is a percentage. */
export type SizeUnit = '%' | 'px' | 'rem' | 'em' | 'vh' | 'vw'

/** One panel's constraints, in percent of the group. */
export interface PanelConstraints {
  /** Default 0. */
  minSize: number
  /** Default 100. */
  maxSize: number
  /** Whether it can collapse to `collapsedSize`. */
  collapsible: boolean
  /** Its size when collapsed. Default 0. */
  collapsedSize: number
  /** How far past `minSize` (or `collapsedSize`) it must go to collapse (or expand). */
  collapsedThreshold?: number
  /** Its first size, if it asks for one. */
  defaultSize?: number
  /** A disabled panel isn't resized, by its own handles or by another's. */
  disabled: boolean
}

/** What caused a change: it decides how collapsible panels snap. */
export type ResizeTrigger = 'keyboard' | 'pointer' | 'imperative'

/** Sizes are rounded to three decimals, as react-resizable-panels' are, so float dust is equal. */
export function round(value: number): number {
  return parseFloat(value.toFixed(3))
}

/** Whether two sizes are the same, within `tolerance` after rounding. */
export function same(a: number, b: number, tolerance = 0): boolean {
  return Math.abs(round(a) - round(b)) <= tolerance
}

/** -1, 0 or 1, comparing two sizes as `same()` does. */
export function compare(a: number, b: number): -1 | 0 | 1 {
  if (same(a, b)) return 0
  return a > b ? 1 : -1
}

/** Whether two layouts have the same sizes. */
export function sameLayout(a: readonly number[], b: readonly number[]): boolean {
  return a.length === b.length && a.every((size, index) => compare(size, b[index]!) === 0)
}

/**
 * A size argument's number and unit: a number is pixels, and a string is a percentage unless it
 * ends in `%`, `px`, `rem`, `em`, `vh` or `vw`.
 */
export function parseSize(size: PanelSize): [value: number, unit: SizeUnit] {
  if (typeof size === 'number') return [size, 'px']
  const value = parseFloat(size)
  const trimmed = size.trim()
  for (const unit of ['%', 'px', 'rem', 'vh', 'vw', 'em'] as const) {
    if (trimmed.endsWith(unit)) return [value, unit]
  }
  return [value, '%']
}

/**
 * A size in pixels: a percentage of `axisSize`, or pixels, `em` (the element's font size),
 * `rem` (the root's), `vh` or `vw`.
 */
export function toPixels(size: PanelSize, axisSize: number, element: Element): number {
  const [value, unit] = parseSize(size)
  const view = element.ownerDocument.defaultView ?? window
  switch (unit) {
    case '%':
      return (value / 100) * axisSize
    case 'px':
      return value
    case 'em':
      return value * parseFloat(view.getComputedStyle(element).fontSize)
    case 'rem':
      return (
        value * parseFloat(view.getComputedStyle(element.ownerDocument.documentElement).fontSize)
      )
    case 'vh':
      return (value / 100) * view.innerHeight
    case 'vw':
      return (value / 100) * view.innerWidth
  }
}

/** A size in percent of `axisSize`, rounded. A percentage needs no `axisSize`. */
export function toPercent(size: PanelSize, axisSize: number, element: Element): number {
  const [value, unit] = parseSize(size)
  if (unit === '%') return round(value)
  if (axisSize <= 0) return 0
  return round((toPixels(size, axisSize, element) / axisSize) * 100)
}

/** Whether a size depends on the group's size: anything but a percentage. */
export function isAbsolute(size: PanelSize | undefined): boolean {
  return size !== undefined && parseSize(size)[1] !== '%'
}

/**
 * The size a panel can take when asked for `size`: its minimum, or its collapsed size past the
 * threshold, when below the minimum, and no more than its maximum. A disabled panel keeps
 * `previous` unless `override` (an imperative resize, or validating a layout).
 */
export function constrain(
  constraints: PanelConstraints,
  previous: number,
  size: number,
  override = false,
): number {
  const { collapsedSize, collapsedThreshold, collapsible, disabled, maxSize, minSize } = constraints
  if (disabled && !override) return previous
  if (compare(size, minSize) < 0) {
    if (collapsible) {
      const threshold = collapsedThreshold ?? (minSize - collapsedSize) / 2
      const wasCollapsed = compare(previous, collapsedSize) <= 0
      const boundary = wasCollapsed ? collapsedSize + threshold : minSize - threshold
      const side = compare(size, boundary)
      const collapses =
        compare(size, collapsedSize) <= 0 ||
        side < 0 ||
        (collapsedThreshold !== undefined && wasCollapsed && side === 0)
      size = collapses ? collapsedSize : minSize
    } else {
      size = minSize
    }
  }
  return round(Math.min(maxSize, size))
}

/**
 * The first layout: each panel's `defaultSize`, and the space left shared equally by the panels
 * that don't ask for one. Not yet validated.
 */
export function defaultLayout(constraints: readonly PanelConstraints[]): number[] {
  let asked = 0
  let total = 0
  for (const panel of constraints) {
    if (panel.defaultSize === undefined) continue
    asked += 1
    total += round(panel.defaultSize)
  }
  const share = constraints.length > asked ? round((100 - total) / (constraints.length - asked)) : 0
  return constraints.map(panel =>
    panel.defaultSize === undefined ? share : round(panel.defaultSize),
  )
}

/**
 * A layout every panel's constraints accept, adding up to 100: scaled to 100 first, then each
 * size constrained, and what that leaves over (or short) given to the first panels that can
 * take it.
 */
export function validateLayout(
  layout: readonly number[],
  constraints: readonly PanelConstraints[],
): number[] {
  if (layout.length !== constraints.length) {
    throw new Error(
      `Joinery: a layout of ${layout.length} sizes for ${constraints.length} resizable panels`,
    )
  }
  const next = [...layout]
  const total = next.reduce((sum, size) => sum + size, 0)
  if (!same(total, 100) && next.length > 0) {
    for (let index = 0; index < next.length; index++) {
      next[index] = total > 0 ? (100 / total) * next[index]! : 100 / next.length
    }
  }
  let remaining = 0
  for (let index = 0; index < next.length; index++) {
    const unsafe = next[index]!
    const safe = constrain(constraints[index]!, layout[index]!, unsafe, true)
    if (unsafe !== safe) {
      remaining += unsafe - safe
      next[index] = safe
    }
  }
  if (!same(remaining, 0)) {
    for (let index = 0; index < next.length; index++) {
      const previous = next[index]!
      const safe = constrain(constraints[index]!, previous, previous + remaining, true)
      if (previous !== safe) {
        remaining -= safe - previous
        next[index] = safe
        if (same(remaining, 0)) break
      }
    }
  }
  return next
}

export interface AdjustOptions {
  /** How far to move the boundary, in percent: positive grows the panels before it. */
  delta: number
  /** The layout when the move started (the drag's first, or the current). */
  initial: readonly number[]
  /** The layout now, returned unchanged when the move can't happen. */
  previous: readonly number[]
  constraints: readonly PanelConstraints[]
  /** The panels either side of the boundary: `[before, after]`, as indices. */
  pivot: readonly [number, number]
  trigger: ResizeTrigger
}

/**
 * Moves the boundary between two panels by `delta` percent, as react-resizable-panels'
 * `adjustLayoutByDelta` does: the panel on the growing side grows, and the panels on the
 * shrinking side give up the space, the nearest first, each down to its minimum (or collapsed,
 * past its threshold). Constraints bound the move on both sides, so a drag past a limit stops
 * there. Returns `previous` when nothing can change.
 */
export function adjustLayout({
  delta,
  initial,
  previous,
  constraints,
  pivot: [before, after],
  trigger,
}: AdjustOptions): readonly number[] {
  if (same(delta, 0)) return initial
  const override = trigger === 'imperative'
  const next = [...initial]
  let applied = 0

  if (trigger === 'keyboard') {
    // A key press expands a collapsed panel to its minimum, and collapses one at its minimum,
    // in one step.
    {
      const index = delta < 0 ? after : before
      const panel = constraints[index]!
      if (panel.collapsible && same(initial[index]!, panel.collapsedSize)) {
        const local = panel.minSize - initial[index]!
        if (compare(local, Math.abs(delta)) > 0) delta = delta < 0 ? -local : local
      }
    }
    {
      const index = delta < 0 ? before : after
      const panel = constraints[index]!
      if (panel.collapsible && same(initial[index]!, panel.minSize)) {
        const local = initial[index]! - panel.collapsedSize
        if (compare(local, Math.abs(delta)) > 0) delta = delta < 0 ? -local : local
      }
    }
  } else {
    // A collapsed panel that a drag (or a resize) grows opens only past its threshold, and
    // then all the way to its minimum.
    const index = delta < 0 ? after : before
    const panel = constraints[index]!
    const size = initial[index]!
    if (panel.collapsible && compare(size, panel.minSize) < 0) {
      const range = panel.minSize - panel.collapsedSize
      const threshold = panel.collapsedThreshold ?? range / 2
      if (compare(size + Math.abs(delta), panel.minSize) < 0) {
        const side = compare(Math.abs(delta), threshold)
        const opens =
          side > 0 || (side === 0 && panel.collapsedThreshold === undefined && delta < 0)
        delta = opens ? (delta < 0 ? -range : range) : 0
      }
    }
  }

  // The most the growing side can take: no move goes further than that.
  {
    const step = delta < 0 ? 1 : -1
    let index = delta < 0 ? after : before
    let available = 0
    while (index >= 0 && index < constraints.length) {
      const size = initial[index]!
      available += constrain(constraints[index]!, size, 100, override) - size
      index += step
    }
    const limited = Math.min(Math.abs(delta), Math.abs(available))
    delta = delta < 0 ? -limited : limited
  }

  // The shrinking side gives up the space, the panel nearest the boundary first.
  {
    let index = delta < 0 ? before : after
    while (index >= 0 && index < constraints.length) {
      const remaining = Math.abs(delta) - Math.abs(applied)
      const size = initial[index]!
      const safe = constrain(constraints[index]!, size, size - remaining, override)
      if (!same(size, safe)) {
        applied += size - safe
        next[index] = safe
        if (compare(applied, Math.abs(delta)) >= 0) break
      }
      index += delta < 0 ? -1 : 1
    }
  }

  if (sameLayout(previous, next)) return previous

  // The growing side takes what was given up: the panel nearest the boundary, then, if it
  // can't take it all, the ones beyond it.
  {
    const index = delta < 0 ? after : before
    const size = initial[index]!
    const unsafe = size + applied
    const safe = constrain(constraints[index]!, size, unsafe, override)
    next[index] = safe
    if (!same(safe, unsafe)) {
      let remaining = unsafe - safe
      let other = index
      while (other >= 0 && other < constraints.length) {
        const current = next[other]!
        const fitted = constrain(constraints[other]!, current, current + remaining, override)
        if (!same(current, fitted)) {
          remaining -= fitted - current
          next[other] = fitted
        }
        if (same(remaining, 0)) break
        other += delta > 0 ? -1 : 1
      }
    }
  }

  const total = next.reduce((sum, size) => sum + size, 0)
  return same(total, 100, 0.1) ? next : previous
}

/**
 * The ARIA values of the handle after panel `index`: the panel's size now, and the smallest
 * and largest it can reach by moving that handle (collapsed, or its minimum, to its maximum),
 * given its neighbours' constraints.
 */
export function handleRange(
  layout: readonly number[],
  constraints: readonly PanelConstraints[],
  index: number,
): { now: number; min: number; max: number } {
  const panel = constraints[index]!
  const now = layout[index]!
  const pivot = [index, index + 1] as const
  const reach = (target: number) =>
    validateLayout(
      adjustLayout({
        delta: target - now,
        initial: layout,
        previous: layout,
        constraints,
        pivot,
        trigger: 'pointer',
      }),
      constraints,
    )[index]!
  return {
    now,
    min: reach(panel.collapsible ? panel.collapsedSize : panel.minSize),
    max: reach(panel.maxSize),
  }
}
