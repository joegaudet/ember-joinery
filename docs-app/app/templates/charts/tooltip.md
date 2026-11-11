# Tooltips

The tooltip charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/tooltip), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771: one stacked `BarChart` with each
of `ChartTooltipContent`'s options. Each starts with its tooltip on the second day
(`@defaultIndex={{1}}`); move the pointer over the chart, or focus it and use the arrow keys, to
move it. See [Chart](/components/chart.md#tooltip) for the tooltip's arguments.

The gallery shows each in a cell as wide as its column; here each fills the preview.

## Tooltip - Default

<Example @name="chart-tooltip-default" @title="Tooltip - Default" @fullWidth={{true}} />

## Tooltip - Line Indicator

<Example @name="chart-tooltip-indicator-line" @title="Tooltip - Line Indicator" @fullWidth={{true}} />

## Tooltip - No Indicator

<Example @name="chart-tooltip-indicator-none" @title="Tooltip - No Indicator" @fullWidth={{true}} />

## Tooltip - Custom label

`labelKey="activities"` labels the tooltip with the config's `activities` entry.

<Example @name="chart-tooltip-label-custom" @title="Tooltip - Custom label" @fullWidth={{true}} />

## Tooltip - Label Formatter

<Example @name="chart-tooltip-label-formatter" @title="Tooltip - Label Formatter" @fullWidth={{true}} />

## Tooltip - No Label

<Example @name="chart-tooltip-label-none" @title="Tooltip - No Label" @fullWidth={{true}} />

## Tooltip - Formatter

Upstream's `formatter` returns markup; here `formatter` is a component, handed the same
arguments (`@value`, `@name`, `@item`, `@index`, `@payload`) and the chart's `@config`.

<Example @name="chart-tooltip-formatter" @title="Tooltip - Formatter" @fullWidth={{true}} />

## Tooltip - Icons

<Example @name="chart-tooltip-icons" @title="Tooltip - Icons" @fullWidth={{true}} />

## Tooltip - Advanced

<Example @name="chart-tooltip-advanced" @title="Tooltip - Advanced" @fullWidth={{true}} />

## Testing

Each example's Test tab reads its tooltip with `ChartHarness`'s `tooltip`, a
`ChartTooltipHarness` (see [Chart](/components/chart.md#testing)).

## Upstream

shadcn/ui's [tooltip charts](https://ui.shadcn.com/charts/tooltip), from
`apps/v4/registry/new-york-v4/charts/chart-tooltip-*.tsx` at shadcn-ui/ui@8ab2771.
