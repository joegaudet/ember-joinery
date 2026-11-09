/*
 * The types a chart's config, tooltip and legend use, shaped as shadcn's and recharts' are.
 */
import type { ComponentLike } from '@glint/template'
import type { IconNode } from '@ember-joinery/ember/components/icon'

/** The colour themes a config's `theme` sets, and the selector each applies under. */
export const THEMES = { light: '', dark: '.dark' } as const

/** A config entry's icon: a `lucide` icon, or a component of your own. */
export type ChartIcon = IconNode | ComponentLike<{ Element: Element }>

/**
 * One series (or category) in a chart's config: its human-readable label, an icon, and its
 * colour, either one `color` or a `theme` with a colour for light and one for dark.
 */
export type ChartConfigItem = {
  label?: string
  icon?: ChartIcon
} & ({ color?: string; theme?: never } | { color?: never; theme: Record<keyof typeof THEMES, string> })

/**
 * The labels, icons and colours of a chart's series, by key. Each colour becomes a CSS
 * variable on the chart, `--color-<key>`, so a series can use `var(--color-desktop)`.
 *
 *   const chartConfig = {
 *     desktop: { label: 'Desktop', color: 'var(--chart-1)' },
 *     mobile: { label: 'Mobile', color: 'var(--chart-2)' },
 *   } satisfies ChartConfig
 */
export type ChartConfig = Record<string, ChartConfigItem>

/** One row of a chart's data. */
export type ChartDatum = Record<string, unknown>

/** Where a series or axis finds its value in a row: a key, or a function of the row. */
export type DataKey = string | number | ((datum: ChartDatum) => unknown)

/** One entry of a tooltip, as recharts hands it to the tooltip's content. */
export interface TooltipPayloadItem {
  /** The series' `@name`, or its data key. */
  name?: string | number
  /** The value at the active row. */
  value?: unknown
  dataKey?: DataKey
  /** The series' colour: its stroke, or its fill where it has no stroke. */
  color?: string
  fill?: string
  stroke?: string
  /** The row it came from. */
  payload?: Record<string, unknown>
  /** `none` hides the entry. */
  type?: string
  unit?: string
}

/** One entry of a legend, as recharts hands it to the legend's content. */
export interface LegendPayloadItem {
  /** The series' `@name`, or its data key. */
  value: string
  dataKey?: DataKey
  color?: string
  /** `none` hides the entry. */
  type?: string
  /** Whether the series is hidden (`@hide`). */
  inactive?: boolean
}

/** Formats a tooltip's label: the active row's category (or its config label). */
export type LabelFormatter = (label: unknown, payload: readonly TooltipPayloadItem[]) => unknown

/** Formats a tooltip entry's value. */
export type ValueFormatter = (
  value: unknown,
  name: string | number,
  item: TooltipPayloadItem,
  index: number,
  payload: unknown,
) => unknown

/** What a chart hands its tooltip's `@content`, besides that component's own arguments. */
export interface ChartTooltipContentArgs {
  /** Whether the tooltip is showing. */
  active?: boolean
  /** The entries at the active row, one per series. */
  payload?: readonly TooltipPayloadItem[]
  /** The active row's category. */
  label?: unknown
  /** The chart's config, from `ChartContainer`. */
  config?: ChartConfig
  labelFormatter?: LabelFormatter
  labelClassName?: string
  formatter?: ValueFormatter
  /** Where the tooltip points, in the chart's pixels. */
  coordinate?: { x: number; y: number }
}

/** What a chart hands its legend's `@content`, besides that component's own arguments. */
export interface ChartLegendContentArgs {
  payload?: readonly LegendPayloadItem[]
  verticalAlign?: 'top' | 'middle' | 'bottom'
  config?: ChartConfig
}
