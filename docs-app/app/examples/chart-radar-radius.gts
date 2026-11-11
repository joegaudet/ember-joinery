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

<template>
  <Card as |card|>
    <card.Header class="items-center pb-4">
      <card.Title>Radar Chart - Radius Axis</card.Title>
      <card.Description>
        Showing total visitors for the last 6 months
      </card.Description>
    </card.Header>
    <card.Content class="pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px]"
        as |chart|
      >
        <chart.RadarChart @data={{chartData}} as |c|>
          <c.ChartTooltip
            @cursor={{false}}
            @content={{component ChartTooltipContent indicator="line" labelKey="month"}}
          />
          <c.PolarGrid />
          <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
          <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
          <c.PolarRadiusAxis
            @angle={{60}}
            @stroke="var(--foreground)"
            @orientation="middle"
            @axisLine={{false}}
          />
        </chart.RadarChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col gap-2 text-sm">
      <div class="flex items-center gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="flex items-center gap-2 leading-none text-muted-foreground">
        January - June 2024
      </div>
    </card.Footer>
  </Card>
</template>
