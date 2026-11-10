import { Card } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'

const chartData = [
  { date: '2024-07-15', running: 450, swimming: 300 },
  { date: '2024-07-16', running: 380, swimming: 420 },
  { date: '2024-07-17', running: 520, swimming: 120 },
  { date: '2024-07-18', running: 140, swimming: 550 },
  { date: '2024-07-19', running: 600, swimming: 350 },
  { date: '2024-07-20', running: 480, swimming: 400 },
]

const chartConfig = {
  running: {
    label: 'Running',
    color: 'var(--chart-1)',
  },
  swimming: {
    label: 'Swimming',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig

const weekday = (value: string) =>
  new Date(value).toLocaleDateString('en-US', {
    weekday: 'short',
  })
const bottom = [0, 0, 4, 4]
const top = [4, 4, 0, 0]

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Tooltip - Line Indicator</card.Title>
      <card.Description>Tooltip with line indicator.</card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.BarChart @accessibilityLayer={{true}} @data={{chartData}} as |c|>
          <c.XAxis
            @dataKey="date"
            @tickLine={{false}}
            @tickMargin={{10}}
            @axisLine={{false}}
            @tickFormatter={{weekday}}
          />
          <c.Bar @dataKey="running" @stackId="a" @fill="var(--color-running)" @radius={{bottom}} />
          <c.Bar @dataKey="swimming" @stackId="a" @fill="var(--color-swimming)" @radius={{top}} />
          <c.ChartTooltip
            @content={{component ChartTooltipContent indicator="line"}}
            @cursor={{false}}
            @defaultIndex={{1}}
          />
        </chart.BarChart>
      </ChartContainer>
    </card.Content>
  </Card>
</template>
