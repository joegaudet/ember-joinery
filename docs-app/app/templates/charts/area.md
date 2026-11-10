# Area Charts

The area charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/area), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is an `AreaChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Chart](/components/chart.md) for
the parts they use.

## Area Chart

<Example @name="chart-area-default" @title="Area Chart" />

## Area Chart - Linear

<Example @name="chart-area-linear" @title="Area Chart - Linear" />

## Area Chart - Step

<Example @name="chart-area-step" @title="Area Chart - Step" />

## Area Chart - Legend

<Example @name="chart-area-legend" @title="Area Chart - Legend" />

## Area Chart - Stacked

<Example @name="chart-area-stacked" @title="Area Chart - Stacked" />

## Area Chart - Stacked Expanded

<Example @name="chart-area-stacked-expand" @title="Area Chart - Stacked Expanded" />

## Area Chart - Icons

<Example @name="chart-area-icons" @title="Area Chart - Icons" />

## Area Chart - Gradient

The gradients are `<defs>` in the chart's block, which renders inside its `<svg>`.

<Example @name="chart-area-gradient" @title="Area Chart - Gradient" />

## Area Chart - Axes

<Example @name="chart-area-axes" @title="Area Chart - Axes" />

## Area Chart - Interactive

Upstream's interactive area chart picks its time range with a
[Select](/components/select.md). Select has landed, but the example isn't ported yet.

## Testing

Each example's Test tab drives it with `ChartHarness` from `@ember-joinery/chart/test-support`
(see [Chart](/components/chart.md#testing)).
