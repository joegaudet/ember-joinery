# Line Charts

The line charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/line), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is a `LineChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Chart](/components/chart.md) for
the parts they use.

## Line Chart - Interactive

<Example @name="chart-line-interactive" @title="Line Chart - Interactive" />

## Line Chart

<Example @name="chart-line-default" @title="Line Chart" />

## Line Chart - Linear

<Example @name="chart-line-linear" @title="Line Chart - Linear" />

## Line Chart - Step

<Example @name="chart-line-step" @title="Line Chart - Step" />

## Line Chart - Multiple

<Example @name="chart-line-multiple" @title="Line Chart - Multiple" />

## Line Chart - Dots

<Example @name="chart-line-dots" @title="Line Chart - Dots" />

## Line Chart - Custom Dots

A line's `@dot` takes a component: here each point is lucide's `GitCommitVertical`, drawn by
`<Icon>`.

<Example @name="chart-line-dots-custom" @title="Line Chart - Custom Dots" />

## Line Chart - Dots Colors

<Example @name="chart-line-dots-colors" @title="Line Chart - Dots Colors" />

## Line Chart - Label

<Example @name="chart-line-label" @title="Line Chart - Label" />

## Line Chart - Custom Label

<Example @name="chart-line-label-custom" @title="Line Chart - Custom Label" />

## Testing

Each example's Test tab drives it with `ChartHarness` from `@ember-joinery/chart/test-support`
(see [Chart](/components/chart.md#testing)).
