# Bar Charts

The bar charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/bar), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is a `BarChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Chart](/components/chart.md) for
the parts they use.

## Bar Chart - Interactive

<Example @name="chart-bar-interactive" @title="Bar Chart - Interactive" @fullWidth={{true}} />

## Bar Chart

<Example @name="chart-bar-default" @title="Bar Chart" />

## Bar Chart - Horizontal

<Example @name="chart-bar-horizontal" @title="Bar Chart - Horizontal" />

## Bar Chart - Multiple

<Example @name="chart-bar-multiple" @title="Bar Chart - Multiple" />

## Bar Chart - Stacked + Legend

<Example @name="chart-bar-stacked" @title="Bar Chart - Stacked + Legend" />

## Bar Chart - Label

<Example @name="chart-bar-label" @title="Bar Chart - Label" />

## Bar Chart - Custom Label

<Example @name="chart-bar-label-custom" @title="Bar Chart - Custom Label" />

## Bar Chart - Mixed

Each bar takes the `fill` in its row, as recharts spreads the row over the bar.

<Example @name="chart-bar-mixed" @title="Bar Chart - Mixed" />

## Bar Chart - Active

The bar's `@shape` is a component that draws each bar with `Rectangle`, handed the bar's
`@props` and `@index`, as upstream's `shape` function is.

<Example @name="chart-bar-active" @title="Bar Chart - Active" />

## Bar Chart - Negative

A `Cell` per row gives each bar its colour, and the labels take it.

<Example @name="chart-bar-negative" @title="Bar Chart - Negative" />

## Testing

Each example's Test tab drives it with `ChartHarness` from `@ember-joinery/chart/test-support`
(see [Chart](/components/chart.md#testing)): `bars(key)` has a series' bars, and `labels(key)`
and `labelLists(key)` its labels.
