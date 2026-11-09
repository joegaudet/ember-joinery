---
'@ember-joinery/chart': major
'@ember-joinery/ember': minor
---

`@ember-joinery/chart` is a new add-on: shadcn's charts, drawn as declarative Glimmer SVG on
`d3-scale` and `d3-shape` with an API shaped like recharts. `ChartContainer` takes the chart's
`@config` (labels, icons and colours, set as `--color-<key>` variables, light and dark) and
yields `AreaChart`, `BarChart` and `LineChart`, which yield recharts' parts: `XAxis`, `YAxis`,
`CartesianGrid`, `Area`, `Bar` and `Line` (each with `LabelList`), `ChartTooltip` and
`ChartLegend`. The geometry is recharts 3's (margins, nice ticks, overlapping labels dropped,
stacking, bar bands, curves), so a chart draws the paths recharts draws, with recharts' class
names. `ChartTooltipContent` and `ChartLegendContent` are shadcn's; the tooltip follows the
pointer and, with the accessibility layer, the arrow keys, and its `@formatter` is a function
that returns an entry's text or a component that draws the entry (recharts' formatter can
return markup). `Dot` and `ChartStyle` go with them. Its `/test-support` has `ChartHarness`,
`ChartTooltipHarness` and `ChartLegendHarness`. `@ember-joinery/ember`'s CSS styles the chart,
its tooltip and its legend. The built modules that hold code ported from recharts keep
recharts' MIT notice.
