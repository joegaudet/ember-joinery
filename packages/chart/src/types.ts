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
} & (
  { color?: string; theme?: never } | { color?: never; theme: Record<keyof typeof THEMES, string> }
)

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

/** Formats a tooltip entry as text, in place of its indicator, name and value. */
export type ValueFormatter = (
  value: unknown,
  name: string | number,
  item: TooltipPayloadItem,
  index: number,
  payload: unknown,
) => unknown

/**
 * A component that draws a tooltip entry, in place of its indicator, name and value: what
 * recharts' `formatter` does when it returns markup. It is handed recharts' formatter
 * arguments by name, and the chart's config.
 */
export interface TooltipFormatterSignature {
  Args: {
    /** The entry's value at the active row: a number, or a string. */
    value: number | string
    /** The series' name (its `@name`, or its data key). */
    name: string | number
    /** The whole entry. */
    item: TooltipPayloadItem
    /** The entry's index among the tooltip's entries. */
    index: number
    /** The row the entry came from. */
    payload: Record<string, unknown> | undefined
    /** The chart's config. */
    config: ChartConfig
  }
}

/**
 * A tooltip's `@formatter`: a function that returns an entry's text (`ValueFormatter`), or a
 * component that draws the entry (`TooltipFormatterSignature`), for markup.
 */
export type TooltipFormatter = ValueFormatter | ComponentLike<TooltipFormatterSignature>

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
  /** Where the tooltip points, in the chart's pixels. */
  coordinate?: { x: number; y: number }
  /**
   * The chart tooltip's own `@labelClassName`, `@labelFormatter` and `@formatter`, for its
   * content (each one the tooltip was given wins over the content's own, as in recharts).
   */
  tooltip?: {
    labelClassName?: string
    labelFormatter?: LabelFormatter
    formatter?: TooltipFormatter
  }
}

/** What a chart hands its legend's `@content`, besides that component's own arguments. */
export interface ChartLegendContentArgs {
  payload?: readonly LegendPayloadItem[]
  verticalAlign?: 'top' | 'middle' | 'bottom'
  config?: ChartConfig
}

export type {
  AreaSignature,
  AxisArgs,
  BarSignature,
  CartesianGridSignature,
  ChartLegendSignature,
  ChartTooltipSignature,
  DotArgs,
  DotOption,
  LabelListSignature,
  LabelPosition,
  LineSignature,
  SeriesArgs,
  XAxisSignature,
  YAxisSignature,
} from './-private/parts.gts'
export type { CurveType } from './-private/paths.ts'
export type { CartesianChartSignature, CartesianChartParts } from './-private/cartesian-chart.gts'
