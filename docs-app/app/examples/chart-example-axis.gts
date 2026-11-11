import { ChartContainer, type ChartConfig } from '@ember-joinery/chart'

const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
  { month: 'April', desktop: 73, mobile: 190 },
  { month: 'May', desktop: 209, mobile: 130 },
  { month: 'June', desktop: 214, mobile: 140 },
]

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

const monthAbbr = (value: string) => value.slice(0, 3)

<template>
  <ChartContainer @config={{chartConfig}} class="min-h-[200px] w-full" as |chart|>
    <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
      <c.CartesianGrid @vertical={{false}} />
      <c.XAxis
        @dataKey="month"
        @tickLine={{false}}
        @tickMargin={{10}}
        @axisLine={{false}}
        @tickFormatter={{monthAbbr}}
      />
      <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
      <c.Bar @dataKey="mobile" @fill="var(--color-mobile)" @radius={{4}} />
    </chart.BarChart>
  </ChartContainer>
</template>
