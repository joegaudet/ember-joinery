# Chart

Beautiful charts. Drawn as Glimmer SVG, with an API shaped like Recharts. Copy and paste into
your apps.

<Example @name="chart-demo" @title="Chart" />

Introducing **Charts**. A collection of chart components that you can copy and paste into your
apps.

Charts are designed to look great out of the box. They work well with the other components and
are fully customizable to fit your project.

[Browse the Charts Library](/charts/index.md).

## Component

shadcn's charts use [Recharts](https://recharts.org/) under the hood. Joinery's
`@ember-joinery/chart` draws the same charts as declarative Glimmer SVG on `d3-scale` and
`d3-shape`, with Recharts' parts, arguments and defaults (and its geometry: the same chart draws
the same paths), and recharts' class names on what it draws, so shadcn's chart CSS styles both.

We designed the chart component with composition in mind. **You build your charts from the parts
a chart yields, and only bring in custom components, such as `ChartTooltipContent`, when and
where you need it**.

```gts
import { ChartContainer, ChartTooltipContent } from '@ember-joinery/chart'

<template>
  <ChartContainer @config={{chartConfig}} as |chart|>
    <chart.BarChart @data={{data}} as |c|>
      <c.Bar @dataKey="value" />
      <c.ChartTooltip @content={{component ChartTooltipContent}} />
    </chart.BarChart>
  </ChartContainer>
</template>
```

`ChartContainer` yields the charts (`AreaChart`, `BarChart`, `LineChart`), and each chart yields
its parts: `XAxis`, `YAxis`, `CartesianGrid`, `Area`, `Bar`, `Line`, `ChartTooltip` and
`ChartLegend`. A part draws nothing where you write it: it tells its chart what to draw, and the
chart draws everything in Recharts' order (grid, areas, bars, lines, axes, dots, labels),
whatever order you write them in.

## Installation

```bash
pnpm add @ember-joinery/chart
```

The chart's styles are in Joinery's CSS (see [Installation](/getting-started/installation.md)),
so there is nothing more to import. The colours are the theme's `--chart-1` to `--chart-5`,
which `tokens.css` and every base colour define, light and dark:

```css
:root {
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
  --chart-3: oklch(0.398 0.07 227.392);
  --chart-4: oklch(0.828 0.189 84.429);
  --chart-5: oklch(0.769 0.188 70.08);
}

.dark {
  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
  --chart-3: oklch(0.769 0.188 70.08);
  --chart-4: oklch(0.627 0.265 303.9);
  --chart-5: oklch(0.645 0.246 16.439);
}
```

## Your First Chart

Let's build your first chart. We'll build a bar chart, add a grid, axis, tooltip and legend.

**Start by defining your data.** The following data represents the number of desktop and mobile
users for each month.

Your data can be in any shape. You are not limited to the shape of the data below. Use the
`@dataKey` argument to map your data to the chart.

```ts
const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
  { month: 'April', desktop: 73, mobile: 190 },
  { month: 'May', desktop: 209, mobile: 130 },
  { month: 'June', desktop: 214, mobile: 140 },
]
```

**Define your chart config.** The chart config holds configuration for the chart. This is where
you place human-readable strings, such as labels, icons and color tokens for theming.

```ts
import type { ChartConfig } from '@ember-joinery/chart'

const chartConfig = {
  desktop: {
    label: 'Desktop',
    color: '#2563eb',
  },
  mobile: {
    label: 'Mobile',
    color: '#60a5fa',
  },
} satisfies ChartConfig
```

**Build your chart.** Remember to give the `ChartContainer` a height: a `min-h-*`, an `h-*` or
an aspect ratio (it is `aspect-video` by default). This is required for the chart to be
responsive.

<Example @name="chart-example" @title="Your first chart" />

### Add a Grid

Let's add a grid to the chart: the chart yields `CartesianGrid`.

```gts
<ChartContainer @config={{chartConfig}} class="min-h-[200px] w-full" as |chart|>
  <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
    <c.CartesianGrid @vertical={{false}} />
    <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
    <c.Bar @dataKey="mobile" @fill="var(--color-mobile)" @radius={{4}} />
  </chart.BarChart>
</ChartContainer>
```

<Example @name="chart-example-grid" @title="Add a grid" />

### Add an Axis

To add an x-axis to the chart, we'll use the `XAxis` part.

```gts
<c.XAxis
  @dataKey="month"
  @tickLine={{false}}
  @tickMargin={{10}}
  @axisLine={{false}}
  @tickFormatter={{monthAbbr}}
/>
```

where `const monthAbbr = (value: string) => value.slice(0, 3)`.

<Example @name="chart-example-axis" @title="Add an axis" />

### Add Tooltip

So far we've only used the chart's own parts. They look great out of the box thanks to some
customization in the chart's CSS.

To add a tooltip, we'll use the `ChartTooltip` part and the `ChartTooltipContent` component.
`@content` takes the component, with any of its arguments curried in:

```gts
import { ChartTooltipContent } from '@ember-joinery/chart'

<c.ChartTooltip @content={{component ChartTooltipContent}} />
```

<Example @name="chart-example-tooltip" @title="Add a tooltip" />

Hover to see the tooltips. Easy, right? Two components, and we've got a beautiful tooltip.

### Add Legend

We'll do the same for the legend. We'll use the `ChartLegend` part and the `ChartLegendContent`
component.

```gts
import { ChartLegendContent } from '@ember-joinery/chart'

<c.ChartLegend @content={{component ChartLegendContent}} />
```

<Example @name="chart-example-legend" @title="Add a legend" />

Done. You've built your first chart! What's next?

- [Themes and Colors](#theming)
- [Tooltip](#tooltip)
- [Legend](#legend)

## Chart Config

The chart config is where you define the labels, icons and colors for a chart.

It is intentionally decoupled from chart data.

This allows you to share config and color tokens between charts. It can also work independently
for cases where your data or color tokens live remotely or in a different format.

```ts
import { Monitor } from 'lucide'
import type { ChartConfig } from '@ember-joinery/chart'

const chartConfig = {
  desktop: {
    label: 'Desktop',
    icon: Monitor,
    // A color like 'hsl(220, 98%, 61%)' or 'var(--color-name)'
    color: '#2563eb',
    // OR a theme object with 'light' and 'dark' keys
    theme: {
      light: '#2563eb',
      dark: '#dc2626',
    },
  },
} satisfies ChartConfig
```

An `icon` is a `lucide` icon (as `<Icon>` takes it) or a component of your own.

## Theming

Charts have built-in support for theming. You can use css variables (recommended) or color
values in any color format, such as hex, hsl or oklch.

### CSS Variables

Define your colors in your css file:

```css
:root {
  --chart-1: oklch(0.646 0.222 41.116);
  --chart-2: oklch(0.6 0.118 184.704);
}

.dark {
  --chart-1: oklch(0.488 0.243 264.376);
  --chart-2: oklch(0.696 0.17 162.48);
}
```

Then add the color to your `chartConfig`:

```ts
const chartConfig = {
  desktop: {
    label: 'Desktop',
    color: 'var(--chart-1)',
  },
  mobile: {
    label: 'Mobile',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig
```

### hex, hsl or oklch

You can also define your colors directly in the chart config. Use the color format you prefer.

```ts
const chartConfig = {
  desktop: { label: 'Desktop', color: '#2563eb' },
  mobile: { label: 'Mobile', color: 'hsl(220, 98%, 61%)' },
  tablet: { label: 'Tablet', color: 'oklch(0.5 0.2 240)' },
  laptop: { label: 'Laptop', color: 'var(--chart-2)' },
} satisfies ChartConfig
```

### Using Colors

To use the theme colors in your chart, reference the colors using the format `var(--color-KEY)`:
`ChartContainer` sets one CSS variable for each config entry with a colour.

In the chart's parts:

```gts
<c.Bar @dataKey="desktop" @fill="var(--color-desktop)" />
```

In the chart's data:

```ts
const chartData = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
]
```

With Tailwind:

```gts
<line.LabelList @class="fill-(--color-desktop)" />
```

## Tooltip

A chart tooltip contains a label, name, indicator and value. You can use a combination of these
to customize your tooltip.

<Example @name="chart-tooltip" @title="Tooltip" />

You can turn on/off any of these using the `@hideLabel`, `@hideIndicator` arguments and
customize the indicator style using the `@indicator` argument.

Use `@labelKey` and `@nameKey` to use a custom key for the tooltip label and name.

Chart comes with the `ChartTooltip` part and the `ChartTooltipContent` component. You can use
these two to add custom tooltips to your chart.

```gts
import { ChartTooltipContent } from '@ember-joinery/chart'

<c.ChartTooltip @content={{component ChartTooltipContent}} />
```

### Arguments

Use the following arguments to customize the tooltip. Curry them into its `@content`:
`@content={{component ChartTooltipContent indicator="line"}}`.

| Argument         | Type                          | Description                                  |
| ---------------- | ----------------------------- | -------------------------------------------- |
| `@labelKey`      | `string`                      | The config or data key to use for the label. |
| `@nameKey`       | `string`                      | The config or data key to use for the name.  |
| `@indicator`     | `"dot"`, `"line"`, `"dashed"` | The indicator style for the tooltip.         |
| `@hideLabel`     | `boolean`                     | Whether to hide the label.                   |
| `@hideIndicator` | `boolean`                     | Whether to hide the indicator.               |

### Colors

Colors are automatically referenced from the chart config.

### Custom

To use a custom key for tooltip label and names, use the `@labelKey` and `@nameKey` arguments.

```ts
const chartData = [
  { browser: 'chrome', visitors: 187, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
]

const chartConfig = {
  visitors: {
    label: 'Total Visitors',
  },
  chrome: {
    label: 'Chrome',
    color: 'var(--chart-1)',
  },
  safari: {
    label: 'Safari',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig
```

```gts
<c.ChartTooltip
  @content={{component ChartTooltipContent labelKey="visitors" nameKey="browser"}}
/>
```

This will use `Total Visitors` for label and `Chrome` and `Safari` for the tooltip names.

## Legend

You can use the `ChartLegend` part and the `ChartLegendContent` component to add a legend to your
chart.

```gts
import { ChartLegendContent } from '@ember-joinery/chart'

<c.ChartLegend @content={{component ChartLegendContent}} />
```

### Colors

Colors are automatically referenced from the chart config.

### Custom

To use a custom key for legend names, use the `@nameKey` argument.

```ts
const chartData = [
  { browser: 'chrome', visitors: 187, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
]

const chartConfig = {
  chrome: {
    label: 'Chrome',
    color: 'var(--chart-1)',
  },
  safari: {
    label: 'Safari',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig
```

```gts
<c.ChartLegend @content={{component ChartLegendContent nameKey="browser"}} />
```

This will use `Chrome` and `Safari` for the legend names.

## Accessibility

You can turn on the `@accessibilityLayer` argument to add an accessible layer to your chart. As
in Recharts 3, it is on unless you turn it off.

This argument adds keyboard access and screen reader support to your charts.

```gts
<chart.LineChart @accessibilityLayer={{true}} />
```

## RTL

Joinery's charts take the page's direction for their tooltip and legend. A chart's x-axis runs
left to right unless you reverse it, as upstream's right-to-left example does
(`<c.XAxis @reversed={{true}} />`); the arrow keys then follow the axis.

<Example @name="chart-rtl" @title="RTL" @dir="rtl" />

## API Reference

### ChartContainer

The box a chart draws in, and its colours.

| Argument  | Type          | Default   | What it does                                       |
| --------- | ------------- | --------- | -------------------------------------------------- |
| `@config` | `ChartConfig` |           | The labels, icons and colours of the chart's data  |
| `@id`     | `string`      | a new one | Its id, in `data-chart`                            |
| `@name`   | `string`      |           | Its name, for `ChartHarness` (`data-test-jn-name`) |

It takes attributes on its element, `class` and `style` included, and yields `AreaChart`,
`BarChart` and `LineChart`, each given the config.

### AreaChart, BarChart, LineChart

Recharts' charts. Each fills the container and follows its size, or draws at `@width` and
`@height` when given both.

| Argument              | Type                            | Default        | What it does                                                     |
| --------------------- | ------------------------------- | -------------- | ---------------------------------------------------------------- |
| `@data`               | `object[]`                      |                | The rows to draw                                                 |
| `@margin`             | `{ top, right, bottom, left }`  | 5 on each side | The space around the plot area; a side left out of a margin is 0 |
| `@layout`             | `"horizontal"`, `"vertical"`    | `"horizontal"` | Categories along x, or down y                                    |
| `@stackOffset`        | `"none"`, `"expand"`, `"sign"`… | `"none"`       | How series with a `@stackId` stack (`expand` stacks to 100%)     |
| `@barCategoryGap`     | `number`, `string`              | `"10%"`        | The space at each side of a band of bars                         |
| `@barGap`             | `number`, `string`              | `4`            | The space between bars in a band                                 |
| `@barSize`            | `number`                        |                | Every bar's width                                                |
| `@accessibilityLayer` | `boolean`                       | `true`         | Keyboard access and the `application` role                       |
| `@width`, `@height`   | `number`                        |                | A fixed size                                                     |
| `@title`, `@desc`     | `string`                        |                | The svg's `<title>` and `<desc>`                                 |

The chart's block renders inside its `<svg>`, so it can also hold the `<defs>` (gradients) its
series fill with, as in the [gradient area chart](/charts/area.md).

### The parts

Each chart yields its parts, with Recharts' arguments and defaults:

| Part              | What it draws                                                                                                                                 |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| `c.XAxis`         | The x-axis: `@dataKey`, `@type`, `@tickLine`, `@axisLine`, `@tickMargin`, `@tickFormatter`, `@minTickGap`, `@interval`, `@reversed`, `@hide`… |
| `c.YAxis`         | The y-axis: as `XAxis`, with `@width` (60), `@tickCount` (5) and `@domain` (`[0, "auto"]`). Without one, the chart lays out a hidden one      |
| `c.CartesianGrid` | Grid lines at the axes' ticks: `@horizontal`, `@vertical`, `@stroke`, `@strokeDasharray`                                                      |
| `c.Area`          | An area: `@dataKey`, `@type` (`linear`, `natural`, `monotone`, `step`…), `@fill`, `@fillOpacity`, `@stroke`, `@stackId`, `@dot`, `@activeDot` |
| `c.Line`          | A line: `@dataKey`, `@type`, `@stroke`, `@strokeWidth`, `@dot` (a circle at each point, or a component), `@activeDot`                         |
| `c.Bar`           | A bar per row: `@dataKey`, `@fill`, `@radius`, `@stackId`, `@barSize`                                                                         |
| `c.ChartTooltip`  | The tooltip: `@content` (a component), `@cursor`, `@defaultIndex`, `@labelFormatter`, `@labelClassName`, `@formatter`                         |
| `c.ChartLegend`   | The legend: `@content` (a component), `@verticalAlign`, `@align`                                                                              |

Each series yields `LabelList`, labels at its points or bars: `@position`, `@offset`,
`@dataKey`, `@formatter`, `@fontSize` and `@class`:

```gts
<c.Line @dataKey="desktop" as |line|>
  <line.LabelList @position="top" @offset={{12}} @class="fill-foreground" @fontSize={{12}} />
</c.Line>
```

A series' `@dot` and `@activeDot` take `false`, attributes (`{ r: 6 }`), or a component, handed
`@cx`, `@cy`, `@r`, `@index`, `@value`, `@payload` (the row) and the series' colours. `Dot` is
Recharts' circle, for a component of your own:

```gts
import { Dot, type DotArgs } from '@ember-joinery/chart'

const ColoredDot: TOC<{ Args: DotArgs; Element: Element }> = <template>
  <Dot @cx={{@cx}} @cy={{@cy}} @r={{5}} fill={{@payload.fill}} />
</template>
```

### ChartTooltipContent

The tooltip's box. The chart gives it `@active`, `@payload`, `@label` and `@config`; it also
renders on its own, given them.

| Argument          | Type                          | Default | What it does                                 |
| ----------------- | ----------------------------- | ------- | -------------------------------------------- |
| `@indicator`      | `"dot"`, `"line"`, `"dashed"` | `"dot"` | How each entry is marked                     |
| `@hideLabel`      | `boolean`                     | `false` | Hides the label                              |
| `@hideIndicator`  | `boolean`                     | `false` | Hides the indicators                         |
| `@labelKey`       | `string`                      |         | The config or data key of the label          |
| `@nameKey`        | `string`                      |         | The config or data key of each entry's name  |
| `@labelFormatter` | `(label, payload) => string`  |         | Formats the label                            |
| `@labelClassName` | `string`                      |         | Classes for the label                        |
| `@formatter`      | `(value, name, …) => string`  |         | Formats each entry                           |
| `@color`          | `string`                      |         | One indicator colour for every entry         |
| `@class`          | `string`                      |         | Classes for the box, in a curried `@content` |

### ChartLegendContent

The legend. The chart gives it `@payload`, `@verticalAlign` and `@config`.

| Argument    | Type      | Default | What it does                                    |
| ----------- | --------- | ------- | ----------------------------------------------- |
| `@nameKey`  | `string`  |         | The config or data key of each entry's label    |
| `@hideIcon` | `boolean` | `false` | Shows a swatch even where the config has icon   |
| `@class`    | `string`  |         | Classes for the legend, in a curried `@content` |

`ChartStyle` writes the `--color-*` variables; `ChartContainer` renders it, so you need it only
for a chart outside one.

### Data attributes

| Element                           | Attribute                 | Value                                                  |
| --------------------------------- | ------------------------- | ------------------------------------------------------ |
| `ChartContainer`                  | `class`                   | `jn-chart`                                             |
|                                   | `data-slot`               | `chart`                                                |
|                                   | `data-chart`              | its id, which `ChartStyle`'s rules select              |
|                                   | `data-test-jn`            | `chart`                                                |
| the chart (`.recharts-wrapper`)   | `data-test-jn-part`       | `wrapper`                                              |
|                                   | `data-test-jn-categories` | where each row sits along the category axis, in pixels |
| its `<svg>` (`.recharts-surface`) | `data-test-jn-part`       | `surface`                                              |
| a series                          | `data-test-jn-part`       | `series`, with `data-test-jn-value` its data key       |
|                                   | `data-test-jn-points`     | its points, as `x,y` pairs                             |
| `ChartTooltipContent`             | `data-test-jn`            | `chart-tooltip`                                        |
|                                   | `data-indicator`          | its `@indicator`                                       |
| `ChartLegendContent`              | `data-test-jn`            | `chart-legend`                                         |

What a chart draws carries Recharts' class names (`recharts-area-area`, `recharts-cartesian-grid`,
`recharts-tooltip-cursor`…), which the chart's CSS styles.

## Keyboard interactions

With the accessibility layer, the chart takes focus.

| Key                        | What it does                                                   |
| -------------------------- | -------------------------------------------------------------- |
| `Tab`                      | Focuses the chart, and shows the tooltip at the first row      |
| `ArrowRight` / `ArrowLeft` | Moves the tooltip to the next or previous row along the x-axis |
| `Enter`                    | Hides the tooltip, or shows it again                           |

Leaving the chart hides the tooltip.

## Accessibility

- With the accessibility layer, the chart's `<svg>` has the `application` role and takes focus,
  and the arrow keys read it row by row through the tooltip, as Recharts' does. Give it a
  `@title` (and a `@desc`) to name it for a screen reader.
- The axes' labels keep Recharts 3's `#666`. shadcn's CSS greys `.recharts-cartesian-axis-tick
text`, where Recharts 2 drew the labels; Recharts 3 draws them in
  `.recharts-cartesian-axis-tick-label`, so they are `#666` on ui.shadcn.com too, as here.
- A chart shows its data as a picture. Where the numbers matter, show them as text or a table
  beside it too.

## Testing

`ChartHarness` from `@ember-joinery/chart/test-support` drives a chart (`data-test-jn="chart"`):
it reads its series, axes, grid, labels and legend, and moves the tooltip as a user does.

```ts
import { ChartHarness } from '@ember-joinery/chart/test-support'

const chart = new ChartHarness('visitors') // <ChartContainer @name="visitors">
assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
await chart.hover(1)
assert.strictEqual(chart.tooltip?.label, 'February')
assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'])
assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'])
```

| Member                 | What it is                                                                 |
| ---------------------- | -------------------------------------------------------------------------- |
| `width`, `height`      | The size the chart drew at                                                 |
| `plot`                 | The plot area: `{ x, y, width, height }`                                   |
| `color(key)`           | The chart's `--color-<key>`                                                |
| `series`               | Each series: `key`, `type`, `points`, `path`, `areaPath`, `fill`, `stroke` |
| `seriesFor(key)`       | One series, by data key                                                    |
| `bars(key)`            | A bar series' bars                                                         |
| `dots(key)`            | A series' dots                                                             |
| `labels(key)`          | A series' labels' text                                                     |
| `xTicks`, `yTicks`     | The axes' tick labels                                                      |
| `gridLines`            | `{ horizontal, vertical }`: where the grid's lines are                     |
| `categories`           | Where each row sits along the category axis                                |
| `hover(index)`         | Points at row `index`                                                      |
| `unhover()`            | Moves the pointer off the chart                                            |
| `focus()`, `blur()`    | Focuses the chart, or leaves it                                            |
| `press(key)`           | Presses `ArrowRight`, `ArrowLeft` or `Enter` on it                         |
| `isTooltipVisible`     | Whether the tooltip shows                                                  |
| `tooltip`              | The tooltip, a `ChartTooltipHarness`, while it shows                       |
| `tooltipPosition`      | Where the tooltip box is, against the chart                                |
| `cursor`, `activeDots` | The cursor and the active dots, while the tooltip shows                    |
| `legend`               | The legend, a `ChartLegendHarness`                                         |

`ChartTooltipHarness` reads a tooltip's `label`, `indicator`, `items` (each `key`, `name`,
`value` and `indicator`), `names` and `entryValues`; `ChartLegendHarness`, a legend's `items` and
`labels`. Each example's Test tab has more.

## Upstream

shadcn/ui's [Chart](https://ui.shadcn.com/docs/components/radix/chart), from
`apps/v4/registry/bases/radix/ui/chart.tsx` at shadcn-ui/ui@8ab2771, in the Nova style, drawn
as Recharts 3.8 draws it.
