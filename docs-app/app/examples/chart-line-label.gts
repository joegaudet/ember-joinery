import { Card, Icon } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

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
    color: 'var(--chart-1)',
  },
  mobile: {
    label: 'Mobile',
    color: 'var(--chart-2)',
  },
} satisfies ChartConfig

const margin = { top: 20, left: 12, right: 12 }
const monthAbbr = (value: string) => value.slice(0, 3)
const dot = { fill: 'var(--color-desktop)' }
const activeDot = { r: 6 }

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Line Chart - Label</card.Title>
      <card.Description>
        January - June 2024
      </card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.LineChart @accessibilityLayer={{true}} @data={{chartData}} @margin={{margin}} as |c|>
          <c.CartesianGrid @vertical={{false}} />
          <c.XAxis
            @dataKey="month"
            @tickLine={{false}}
            @axisLine={{false}}
            @tickMargin={{8}}
            @tickFormatter={{monthAbbr}}
          />
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent indicator="line"}}
          />
          <c.Line
            @dataKey="desktop"
            @type="natural"
            @stroke="var(--color-desktop)"
            @strokeWidth={{2}}
            @dot={{dot}}
            @activeDot={{activeDot}}
            as |line|
          >
            <line.LabelList
              @position="top"
              @offset={{12}}
              @class="fill-foreground"
              @fontSize={{12}}
            />
          </c.Line>
        </chart.LineChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col items-start gap-2 text-sm">
      <div class="flex gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="leading-none text-muted-foreground">
        Showing total visitors for the last 6 months
      </div>
    </card.Footer>
  </Card>
</template>
