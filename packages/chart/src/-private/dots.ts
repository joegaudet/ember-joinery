/*
 * How a series' `dot`/`activeDot` option becomes what the chart draws: nothing, a circle with
 * attributes, or the caller's component.
 */
import type { DotArgs, DotOption } from './parts.gts'

export interface CircleDot {
  kind: 'circle'
  component?: undefined
  attrs: { r: number; fill: string; stroke: string; strokeWidth: string; class?: string }
  args: DotArgs
}

export interface ComponentDot {
  kind: 'component'
  component: Exclude<DotOption, boolean | Record<string, unknown>>
  args: DotArgs
}

export type DotRender = CircleDot | ComponentDot

/** A plain object of attributes, as opposed to a component (a class, or a curried definition). */
export function isPlainObject(value: unknown): value is Record<string, unknown> {
  if (typeof value !== 'object' || value === null) return false
  const proto = Object.getPrototypeOf(value) as unknown
  return proto === Object.prototype || proto === null
}

/**
 * The dot to draw for `option`, or null for none. `defaults` are the series' own: a line's dot
 * is a white circle in its stroke, an active dot a filled one with a white ring.
 */
export function dotFor(
  option: DotOption | undefined,
  fallback: boolean,
  defaults: CircleDot['attrs'],
  args: DotArgs,
): DotRender | null {
  const value = option ?? fallback
  if (value === false) return null
  if (value === true) return { kind: 'circle', attrs: defaults, args: { ...args, r: defaults.r } }
  if (isPlainObject(value)) {
    const attrs = {
      ...defaults,
      ...(value.r !== undefined ? { r: Number(value.r) } : {}),
      ...(value.fill !== undefined ? { fill: String(value.fill) } : {}),
      ...(value.stroke !== undefined ? { stroke: String(value.stroke) } : {}),
      ...(value.strokeWidth !== undefined ? { strokeWidth: String(value.strokeWidth) } : {}),
      ...(value.class !== undefined ? { class: String(value.class) } : {}),
    }
    return { kind: 'circle', attrs, args: { ...args, r: attrs.r } }
  }
  return { kind: 'component', component: value as ComponentDot['component'], args }
}
