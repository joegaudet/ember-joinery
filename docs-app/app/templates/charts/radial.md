# Radial Charts

The radial charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/radial), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is a `RadialBarChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Radar Charts](/charts/radar.md)
for the polar parts they share, and [Chart](/components/chart.md) for the container, config,
tooltip and legend.

## Radial Chart

Each row's `fill` colours its bar, as Recharts spreads a row over its bar.

<Example @name="chart-radial-simple" @title="Radial Chart" />

## Radial Chart - Label

A bar's `LabelList` with `@position="insideStart"` runs along the bar from its start, on a
`<textPath>`, as Recharts draws it.

<Example @name="chart-radial-label" @title="Radial Chart - Label" />

## Radial Chart - Grid

<Example @name="chart-radial-grid" @title="Radial Chart - Grid" />

## Radial Chart - Text

The radius axis's `Label` takes a component as its `@content`, handed `@viewBox`: the chart's
centre (`cx`, `cy`) and the axis's radii, as upstream's `content` function is.

<Example @name="chart-radial-text" @title="Radial Chart - Text" />

## Radial Chart - Shape

<Example @name="chart-radial-shape" @title="Radial Chart - Shape" />

## Radial Chart - Stacked

Stacked bars share a ring. As in Recharts, a radial chart's angle axis runs to the largest single
value rather than the largest stack, so the outer bar of a stack is cut at the end of the axis.

<Example @name="chart-radial-stacked" @title="Radial Chart - Stacked" />

## API Reference

### RadialBarChart

Recharts' `RadialBarChart`, from the container's yield (`chart.RadialBarChart`). It takes the
same arguments as [`RadarChart`](/charts/radar.md#api-reference), with these defaults, and the bar
layout of a bar chart:

| Argument          | Type                            | Default  | What it does                                                  |
| ----------------- | ------------------------------- | -------- | ------------------------------------------------------------- |
| `@startAngle`     | `number`                        | `0`      | Where the bars start, in degrees anticlockwise from 3 o'clock |
| `@endAngle`       | `number`                        | `360`    | Where the angle axis ends: the largest value reaches it       |
| `@innerRadius`    | `number`, `string`              | `0`      | Where the innermost ring starts                               |
| `@outerRadius`    | `number`, `string`              | `"80%"`  | Where the outermost ends                                      |
| `@barCategoryGap` | `number`, `string`              | `"10%"`  | The space at each side of a ring's bars                       |
| `@barGap`         | `number`, `string`              | `4`      | The space between bars in a ring                              |
| `@barSize`        | `number`                        |          | Every bar's width                                             |
| `@stackOffset`    | `"none"`, `"expand"`, `"sign"`… | `"none"` | How bars with a `@stackId` stack                              |

It yields the polar parts: `PolarGrid`, `PolarAngleAxis`, `PolarRadiusAxis`, `Radar`,
`RadialBar`, `ChartTooltip` and `ChartLegend`.

### RadialBar

A bar round the chart for each row.

| Argument        | Type                         | Default | What it does                                                |
| --------------- | ---------------------------- | ------- | ----------------------------------------------------------- |
| `@dataKey`      | `string`, `(row) => value`   |         | Each row's value                                            |
| `@fill`         | `string`                     |         | The bars' colour; a row's own `fill` wins                   |
| `@background`   | `boolean`, `{ fill, class }` | `false` | A track behind each bar, round the whole chart              |
| `@cornerRadius` | `number`, `string`           | `0`     | Rounds the bars' corners (at most half a bar's width)       |
| `@stackId`      | `string`, `number`           |         | Bars with the same stack id stack in one ring               |
| `@minPointSize` | `number`                     | `0`     | The least angle a bar is drawn with                         |
| `@barSize`      | `number`                     |         | The bar's width                                             |
| `@name`         | `string`                     |         | Its name in the tooltip                                     |
| `@class`        | `string`                     |         | Classes for the bars' group (`stroke-transparent stroke-2`) |

It yields `LabelList`, a label on each bar: `@position` (`insideStart`, `insideEnd` and `end` run
along the bar; `middle`, the default, `outside`, `center`… sit at a point), `@offset` (5: degrees
along the bar), `@dataKey`, `@formatter`, `@fontSize`, `@fill` (default the bar's) and `@class`.

```gts
<c.RadialBar @dataKey="visitors" @background={{true}} as |bar|>
  <bar.LabelList @position="insideStart" @dataKey="browser" @class="fill-white" />
</c.RadialBar>
```

### Label

A `PolarRadiusAxis` yields `Label`: `@value` placed at `@position` against the axis's ring
(`middle` by default), or `@content`, a component handed `@viewBox` (`cx`, `cy`, `innerRadius`,
`outerRadius`, `startAngle`, `endAngle`), `@value`, `@offset` and `@position`:

```gts
import type { TOC } from '@ember/component/template-only'
import type { PolarLabelContentSignature } from '@ember-joinery/chart'

const Total: TOC<PolarLabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle">1,830</text>
</template>

<template>
  <c.PolarRadiusAxis @tick={{false}} @axisLine={{false}} as |axis|>
    <axis.Label @content={{Total}} />
  </c.PolarRadiusAxis>
</template>
```

Each radial bar carries `data-test-jn-part="sector"`, and its track `background-sector`.

## Keyboard interactions

As on a [radar chart](/charts/radar.md#keyboard-interactions): `Tab` shows the tooltip at the
first row, the arrow keys move it from ring to ring, and `Enter` hides or shows it. A tooltip the
keyboard opens points at the middle of the row's bar.

## Testing

`PolarChartHarness` reads a radial chart's bars (`radialBars(key)`), their tracks
(`backgroundSectors`), labels (`labels(key)`), grid and axes, and `hover(index)` points at a
row's ring; see [Radar Charts](/charts/radar.md#testing).

## Upstream

shadcn/ui's [radial charts](https://ui.shadcn.com/charts/radial), from
`apps/v4/registry/new-york-v4/charts/chart-radial-*.tsx` at shadcn-ui/ui@8ab2771, drawn as
Recharts 3.8 draws them.
