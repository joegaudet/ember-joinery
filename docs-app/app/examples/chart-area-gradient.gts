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

const margin = { left: 12, right: 12 }
const monthAbbr = (value: string) => value.slice(0, 3)

<template>
  <Card as |card|>
    <card.Header>
      <card.Title>Area Chart - Gradient</card.Title>
      <card.Description>
        Showing total visitors for the last 6 months
      </card.Description>
    </card.Header>
    <card.Content>
      <ChartContainer @config={{chartConfig}} as |chart|>
        <chart.AreaChart @accessibilityLayer={{true}} @data={{chartData}} @margin={{margin}} as |c|>
          <c.CartesianGrid @vertical={{false}} />
          <c.XAxis
            @dataKey="month"
            @tickLine={{false}}
            @axisLine={{false}}
            @tickMargin={{8}}
            @tickFormatter={{monthAbbr}}
          />
          <c.ChartTooltip @cursor={{false}} @content={{component ChartTooltipContent}} />
          <defs>
            <linearGradient id="fillDesktop" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stop-color="var(--color-desktop)" stop-opacity="0.8" />
              <stop offset="95%" stop-color="var(--color-desktop)" stop-opacity="0.1" />
            </linearGradient>
            <linearGradient id="fillMobile" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stop-color="var(--color-mobile)" stop-opacity="0.8" />
              <stop offset="95%" stop-color="var(--color-mobile)" stop-opacity="0.1" />
            </linearGradient>
          </defs>
          <c.Area
            @dataKey="mobile"
            @type="natural"
            @fill="url(#fillMobile)"
            @fillOpacity={{0.4}}
            @stroke="var(--color-mobile)"
            @stackId="a"
          />
          <c.Area
            @dataKey="desktop"
            @type="natural"
            @fill="url(#fillDesktop)"
            @fillOpacity={{0.4}}
            @stroke="var(--color-desktop)"
            @stackId="a"
          />
        </chart.AreaChart>
      </ChartContainer>
    </card.Content>
    <card.Footer>
      <div class="flex w-full items-start gap-2 text-sm">
        <div class="grid gap-2">
          <div class="flex items-center gap-2 leading-none font-medium">
            Trending up by 5.2% this month
            <Icon @icon={{TrendingUp}} class="h-4 w-4" />
          </div>
          <div class="flex items-center gap-2 leading-none text-muted-foreground">
            January - June 2024
          </div>
        </div>
      </div>
    </card.Footer>
  </Card>
</template>
