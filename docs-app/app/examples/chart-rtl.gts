import {
  ChartContainer,
  ChartLegendContent,
  ChartTooltipContent,
  type ChartConfig,
} from '@ember-joinery/chart'

// Upstream's example opens in Arabic, and offers Hebrew and English (a picker the guide's frame
// doesn't have).
const t = {
  january: 'يناير',
  february: 'فبراير',
  march: 'مارس',
  april: 'أبريل',
  may: 'مايو',
  june: 'يونيو',
  desktop: 'سطح المكتب',
  mobile: 'الجوال',
}

const chartData = [
  { month: 'january', desktop: 186, mobile: 80 },
  { month: 'february', desktop: 305, mobile: 200 },
  { month: 'march', desktop: 237, mobile: 120 },
  { month: 'april', desktop: 73, mobile: 190 },
  { month: 'may', desktop: 209, mobile: 130 },
  { month: 'june', desktop: 214, mobile: 140 },
]

const chartConfig = {
  desktop: {
    label: t.desktop,
    color: 'var(--chart-2)',
  },
  mobile: {
    label: t.mobile,
    color: 'var(--chart-1)',
  },
} satisfies ChartConfig

const monthAbbr = (value: string) => t[value as keyof typeof t].slice(0, 3)
const monthName = (value: unknown) => t[value as keyof typeof t]

<template>
  <ChartContainer @config={{chartConfig}} class="min-h-[200px] w-full" as |chart|>
    <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
      {{! Right to left, the categories run from the right: upstream reverses the x-axis. }}
      <c.CartesianGrid @vertical={{false}} @orientation="right" />
      <c.XAxis
        @dataKey="month"
        @tickLine={{false}}
        @tickMargin={{10}}
        @axisLine={{false}}
        @tickFormatter={{monthAbbr}}
        @reversed={{true}}
      />
      <c.ChartTooltip
        @content={{component ChartTooltipContent labelFormatter=monthName}}
        @labelClassName="w-32"
      />
      <c.ChartLegend @content={{component ChartLegendContent}} />
      <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
      <c.Bar @dataKey="mobile" @fill="var(--color-mobile)" @radius={{4}} />
    </chart.BarChart>
  </ChartContainer>
</template>
