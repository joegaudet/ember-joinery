# Radar Charts

The radar charts of shadcn's [charts gallery](https://ui.shadcn.com/charts/radar), from
`apps/v4/registry/new-york-v4/charts` at shadcn-ui/ui@8ab2771. Each is a `RadarChart` from
`@ember-joinery/chart` in a [Card](/components/card.md); see [Chart](/components/chart.md) for
the container, config, tooltip and legend they share with every chart.

## Radar Chart

<Example @name="chart-radar-default" @title="Radar Chart" />

## Radar Chart - Dots

A radar's `@dot` takes `true`, a dot's attributes (`{ r: 4, fillOpacity: 1 }`), or a component,
as a line's does.

<Example @name="chart-radar-dots" @title="Radar Chart - Dots" />

## Radar Chart - Lines Only

<Example @name="chart-radar-lines-only" @title="Radar Chart - Lines Only" />

## Radar Chart - Custom Label

A `PolarAngleAxis`'s `@tick` takes a component that draws each label, handed where Recharts
puts it (`@x`, `@y`, `@textAnchor`), its `@index`, its `@payload` and its text (`@value`), as
upstream's `tick` function is.

<Example @name="chart-radar-label-custom" @title="Radar Chart - Custom Label" />

## Radar Chart - Radius Axis

<Example @name="chart-radar-radius" @title="Radar Chart - Radius Axis" />

## Radar Chart - Grid Custom

<Example @name="chart-radar-grid-custom" @title="Radar Chart - Grid Custom" />

## Radar Chart - Grid Filled

A `PolarGrid`'s `@class` goes on each of its rings and spokes, as Recharts puts a grid's
`className` on each, so `fill-(--color-desktop) opacity-20` fills every ring, deepest at the
centre.

<Example @name="chart-radar-grid-fill" @title="Radar Chart - Grid Filled" />

## Radar Chart - Grid None

<Example @name="chart-radar-grid-none" @title="Radar Chart - Grid None" />

## Radar Chart - Grid Circle

<Example @name="chart-radar-grid-circle" @title="Radar Chart - Grid Circle" />

## Radar Chart - Grid Circle - No lines

<Example @name="chart-radar-grid-circle-no-lines" @title="Radar Chart - Grid Circle - No lines" />

## Radar Chart - Grid Circle Filled

<Example @name="chart-radar-grid-circle-fill" @title="Radar Chart - Grid Circle Filled" />

## Radar Chart - Multiple

<Example @name="chart-radar-multiple" @title="Radar Chart - Multiple" />

## Radar Chart - Legend

Upstream's `ChartLegend` passes its `className` (`mt-8`) to its content; here the content takes
it as `class`, curried in: `@content={{component ChartLegendContent class="mt-8"}}`.

<Example @name="chart-radar-legend" @title="Radar Chart - Legend" />

## Radar Chart - Icons

<Example @name="chart-radar-icons" @title="Radar Chart - Icons" />

## API Reference

### RadarChart

Recharts' `RadarChart`, from the container's yield (`chart.RadarChart`). It fills the container
and follows its size, or draws at `@width` and `@height` when given both.

| Argument              | Type                           | Default        | What it does                                                         |
| --------------------- | ------------------------------ | -------------- | -------------------------------------------------------------------- |
| `@data`               | `object[]`                     |                | The rows to draw, one per spoke                                      |
| `@margin`             | `{ top, right, bottom, left }` | 5 on each side | The space around the ring; a side left out of a margin is 0          |
| `@cx`, `@cy`          | `number`, `string`             | `"50%"`        | The ring's centre, in pixels or a percentage of the chart's size     |
| `@innerRadius`        | `number`, `string`             | `0`            | The ring's inner radius, in pixels or a percentage of the largest    |
| `@outerRadius`        | `number`, `string`             | `"80%"`        | Its outer radius                                                     |
| `@startAngle`         | `number`                       | `90`           | Where the rows start, in degrees anticlockwise from 3 o'clock        |
| `@endAngle`           | `number`                       | `-270`         | Where they end: by default, all the way round clockwise from the top |
| `@accessibilityLayer` | `boolean`                      | `true`         | Keyboard access and the `application` role                           |
| `@width`, `@height`   | `number`                       |                | A fixed size                                                         |
| `@title`, `@desc`     | `string`                       |                | The svg's `<title>` and `<desc>`                                     |

### The polar parts

A `RadarChart` and a [`RadialBarChart`](/charts/radial.md) yield the same parts, with Recharts'
arguments and defaults, besides `ChartTooltip` and `ChartLegend` (see
[Chart](/components/chart.md#api-reference)):

| Part                | What it draws                                                                                                                                                                                                       |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `c.PolarGrid`       | Rings at the radius axis's ticks and spokes at the angle axis's: `@gridType` (`polygon`, `circle`), `@radialLines` (true), `@polarRadius`, `@polarAngles`, `@stroke`, `@strokeWidth`, `@fill`, `@class`             |
| `c.PolarAngleAxis`  | The axis round the ring: `@dataKey`, `@tick` (true, false, or a component), `@tickLine`, `@tickSize` (8), `@axisLine`, `@axisLineType`, `@orientation` (`outer`, `inner`), `@tickFormatter`, `@stroke`, `@reversed` |
| `c.PolarRadiusAxis` | The axis out from the centre: `@angle` (0), `@orientation` (`right`, `left`, `middle`), `@tick`, `@axisLine`, `@stroke` (`#ccc`), `@tickCount` (5), `@domain`, `@tickFormatter`. It yields `Label`                  |
| `c.Radar`           | A polygon through each row's value: `@dataKey`, `@fill`, `@fillOpacity`, `@stroke`, `@strokeWidth`, `@dot` (none), `@activeDot` (true), `@connectNulls`, `@name`, `@hide`, `@class`                                 |
| `c.RadialBar`       | A bar round the chart per row; see [Radial Charts](/charts/radial.md#api-reference)                                                                                                                                 |

A `Radar` whose values are `[low, high]` pairs draws the ring between them. A radius axis's
`Label` (`<axis.Label @content={{Total}} />`) draws a label against the axis's ring, as on the
[radial charts](/charts/radial.md).

### Data attributes

| Element                         | Attribute                 | Value                                                                   |
| ------------------------------- | ------------------------- | ----------------------------------------------------------------------- |
| the chart (`.recharts-wrapper`) | `data-layout`             | `centric` (rows round the ring), or `radial` in a radial bar chart      |
| its clip `<rect>`               | `data-test-jn-ring`       | the ring: `cx cy innerRadius outerRadius startAngle endAngle`           |
|                                 | `data-test-jn-categories` | where each row sits: its spoke's angle (or its ring's radius)           |
| the grid                        | `data-test-jn-part`       | `polar-grid`, with `data-grid-type`; its `grid-ring`s and `grid-spoke`s |
| the axes                        | `data-test-jn-part`       | `angle-axis`, `radius-axis`                                             |
| a radar                         | `data-test-jn-part`       | `series`, with `data-test-jn-value` its data key and `data-series-type` |

What a chart draws carries Recharts' class names (`recharts-polar-grid`, `recharts-radar`,
`recharts-polar-angle-axis-tick-value`…), which the chart's CSS styles.

## Keyboard interactions

With the accessibility layer, the chart takes focus.

| Key                        | What it does                                              |
| -------------------------- | --------------------------------------------------------- |
| `Tab`                      | Focuses the chart, and shows the tooltip at the first row |
| `ArrowRight` / `ArrowLeft` | Moves the tooltip to the next or previous row             |
| `Enter`                    | Hides the tooltip, or shows it again                      |

The rows run in the order of `@data`, clockwise round a radar from the top. A tooltip the
keyboard (or `@defaultIndex`) opens points at the first radar's point on the row; Recharts 3
places it with arithmetic meant for a cartesian chart, which lands off the row.

## Accessibility

The chart's `<svg>` has the `application` role and takes focus; give it a `@title` (its
`<title>`) to name it. Everything it shows is also in its tooltip, which the keyboard moves
through. Right to left, a polar chart draws as in left to right, as Recharts does, and its
tooltip and legend take the page's direction.

## Testing

`PolarChartHarness` from `@ember-joinery/chart/test-support` drives a radar or radial bar chart.
It is a `ChartHarness`, so it also reads the tooltip, legend, dots and labels, and
`hover(index)` points at a row on its spoke (or its ring).

```ts
import { PolarChartHarness } from '@ember-joinery/chart/test-support'

const chart = new PolarChartHarness('visitors') // <ChartContainer @name="visitors">
assert.deepEqual(chart.angleTicks, ['January', 'February', 'March', 'April', 'May', 'June'])
assert.dom(chart.polygon('desktop')).hasAttribute('fill', 'var(--color-desktop)')
await chart.hover(1)
assert.strictEqual(chart.tooltip?.label, 'February')
```

| Member                      | What it is                                                                    |
| --------------------------- | ----------------------------------------------------------------------------- |
| `layout`                    | `centric` (a radar chart) or `radial` (a radial bar chart)                    |
| `ring`                      | `{ cx, cy, innerRadius, outerRadius, startAngle, endAngle }`                  |
| `categories`                | Where each row sits: its spoke's angle, or its ring's radius                  |
| `polarGrid`                 | The grid: `type`, `radii`, `angles`, its `rings` and `spokes`; `null` without |
| `angleTicks`, `radiusTicks` | The axes' labels, as drawn                                                    |
| `angleAxis`, `radiusAxis`   | The axes' groups (a radius axis's `Label` draws inside it)                    |
| `polygon(key)`              | A radar's polygon                                                             |
| `radialBars(key)`           | A radial bar series' bars                                                     |
| `backgroundSectors`         | The tracks behind the radial bars                                             |
| `hover(index)`              | Points at row `index`                                                         |

Each example's Test tab has more.

## Upstream

shadcn/ui's [radar charts](https://ui.shadcn.com/charts/radar), from
`apps/v4/registry/new-york-v4/charts/chart-radar-*.tsx` at shadcn-ui/ui@8ab2771, drawn as
Recharts 3.8 draws them.
