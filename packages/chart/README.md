# @ember-joinery/chart

shadcn/ui's [Chart](https://ui.shadcn.com/docs/components/radix/chart) for Ember, an opt-in
add-on to [Joinery](https://joegaudet.com/ember-joinery/): area, bar, line, pie, radar and
radial bar charts drawn as declarative Glimmer SVG on [d3-scale](https://d3js.org/d3-scale) and
[d3-shape](https://d3js.org/d3-shape), with an API shaped like
[recharts](https://recharts.org/), which shadcn's charts use.

```bash
npm install @ember-joinery/chart @ember-joinery/ember
```

It ships no CSS of its own: `@ember-joinery/ember`'s `joinery.css` (or any of its styles)
styles the charts, their tooltip and their legend, in the theme's `--chart-1` to `--chart-5`.

```gts
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'

const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
]

const chartConfig = {
  desktop: { label: 'Desktop', color: 'var(--chart-1)' },
  mobile: { label: 'Mobile', color: 'var(--chart-2)' },
} satisfies ChartConfig

<template>
  <ChartContainer @config={{chartConfig}} class="min-h-[200px] w-full" as |chart|>
    <chart.BarChart @data={{chartData}} as |c|>
      <c.CartesianGrid @vertical={{false}} />
      <c.XAxis @dataKey="month" @tickLine={{false}} @axisLine={{false}} />
      <c.ChartTooltip @content={{component ChartTooltipContent}} />
      <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
      <c.Bar @dataKey="mobile" @fill="var(--color-mobile)" @radius={{4}} />
    </chart.BarChart>
  </ChartContainer>
</template>
```

`ChartContainer` takes the chart's `@config` (each series' label, icon and colour, set as
`--color-<key>`, light and dark) and yields `AreaChart`, `BarChart`, `LineChart`, `PieChart`,
`RadarChart` and `RadialBarChart`. Each chart yields recharts' parts, with recharts' arguments
and defaults: `XAxis`, `YAxis`, `CartesianGrid`, `Area`, `Bar` and `Line` (each with
`LabelList`, and a bar with `Cell`), or a pie chart's `Pie` (with `LabelList`, `Label` and
`Cell`), and `ChartTooltip` and `ChartLegend`. `RadarChart` and `RadialBarChart` yield recharts'
polar parts instead: `PolarGrid`, `PolarAngleAxis`, `PolarRadiusAxis` (with a `Label`), `Radar`
and `RadialBar` (with `LabelList`), drawn with recharts 3's polar layout. `Rectangle` and
`Sector` draw a bar or a sector in a `@shape` of your own. `ChartTooltipContent` and
`ChartLegendContent` are shadcn's. The geometry is recharts 3's (margins, nice ticks,
overlapping labels dropped, stacking, bar bands, curves, a pie's sectors and labels), so a chart
draws the paths recharts draws, with recharts' class names. The chart follows its container's
size (until it has been measured, it draws at the container's `@initialDimension`, 320 × 200 by
default), and with the accessibility layer (on by default) it takes focus and the arrow keys
move its tooltip.

Its harnesses, `ChartHarness`, `PolarChartHarness` (for a radar or radial bar chart),
`ChartTooltipHarness` and `ChartLegendHarness`, are in `@ember-joinery/chart/test-support`: they
read a chart's series (a pie's sectors), axes, grid, labels and legend, and move its tooltip as a
user does.

Full documentation: the Chart page and the Charts section of the guide at
**https://joegaudet.com/ember-joinery/guide/**. Design and API ported from
[shadcn/ui](https://ui.shadcn.com/) (MIT). Its tick selection, nice ticks, text measurement,
cartesian, pie and polar layout, tooltip placement, and rectangle, sector and polygon paths port
[recharts](https://github.com/recharts/recharts) 3.8 (MIT, © recharts); the built modules that
hold that code keep recharts' notice, and the repository's
[NOTICE](https://github.com/joegaudet/ember-joinery/blob/main/NOTICE) has it in full.
