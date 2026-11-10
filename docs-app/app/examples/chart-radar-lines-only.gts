import { Card, Icon } from '@ember-joinery/ember'
import { ChartContainer, ChartTooltipContent, type ChartConfig } from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const chartData = [
  { month: 'January', desktop: 186, mobile: 160 },
  { month: 'February', desktop: 185, mobile: 170 },
  { month: 'March', desktop: 207, mobile: 180 },
  { month: 'April', desktop: 173, mobile: 160 },
  { month: 'May', desktop: 160, mobile: 190 },
  { month: 'June', desktop: 174, mobile: 204 },
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
      <card.Title>Radar Chart - Lines Only</card.Title>
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
            @content={{component ChartTooltipContent indicator="line"}}
          />
          <c.PolarAngleAxis @dataKey="month" />
          <c.PolarGrid @radialLines={{false}} />
          <c.Radar
            @dataKey="desktop"
            @fill="var(--color-desktop)"
            @fillOpacity={{0}}
            @stroke="var(--color-desktop)"
            @strokeWidth={{2}}
          />
          <c.Radar
            @dataKey="mobile"
            @fill="var(--color-mobile)"
            @fillOpacity={{0}}
            @stroke="var(--color-mobile)"
            @strokeWidth={{2}}
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
