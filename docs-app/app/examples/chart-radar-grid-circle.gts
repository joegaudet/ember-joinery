import { Card, Icon } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { month: 'January', desktop: 186 },
  { month: 'February', desktop: 305 },
  { month: 'March', desktop: 237 },
  { month: 'April', desktop: 273 },
  { month: 'May', desktop: 209 },
  { month: 'June', desktop: 214 },
]

const chartConfig = {
  desktop: {
    label: 'Desktop',
    color: 'var(--chart-1)',
  },
} satisfies ChartConfig

const dot = { r: 4, fillOpacity: 1 }

<template>
  <Card as |card|>
    <card.Header class="items-center pb-4">
      <card.Title>Radar Chart - Grid Circle</card.Title>
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
            @content={{component ChartTooltipContent hideLabel=true}}
          />
          <c.PolarGrid @gridType="circle" />
          <c.PolarAngleAxis @dataKey="month" />
          <c.Radar
            @dataKey="desktop"
            @fill="var(--color-desktop)"
            @fillOpacity={{0.6}}
            @dot={{dot}}
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
