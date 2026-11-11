import { Card, Icon } from '@ember-joinery/ember'
import {
  ChartContainer,
  ChartTooltipContent,
  type ChartConfig,
  type TooltipPayloadItem,
} from '@ember-joinery/chart'
import { TrendingUp } from 'lucide'

const desktopData = [
  { month: 'january', desktop: 186, fill: 'var(--color-january)' },
  { month: 'february', desktop: 305, fill: 'var(--color-february)' },
  { month: 'march', desktop: 237, fill: 'var(--color-march)' },
  { month: 'april', desktop: 173, fill: 'var(--color-april)' },
  { month: 'may', desktop: 209, fill: 'var(--color-may)' },
]

const mobileData = [
  { month: 'january', mobile: 80, fill: 'var(--color-january)' },
  { month: 'february', mobile: 200, fill: 'var(--color-february)' },
  { month: 'march', mobile: 120, fill: 'var(--color-march)' },
  { month: 'april', mobile: 190, fill: 'var(--color-april)' },
  { month: 'may', mobile: 130, fill: 'var(--color-may)' },
]

const chartConfig = {
  visitors: {
    label: 'Visitors',
  },
  desktop: {
    label: 'Desktop',
  },
  mobile: {
    label: 'Mobile',
  },
  january: {
    label: 'January',
    color: 'var(--chart-1)',
  },
  february: {
    label: 'February',
    color: 'var(--chart-2)',
  },
  march: {
    label: 'March',
    color: 'var(--chart-3)',
  },
  april: {
    label: 'April',
    color: 'var(--chart-4)',
  },
  may: {
    label: 'May',
    color: 'var(--chart-5)',
  },
} satisfies ChartConfig

const pieLabel = (_: unknown, payload: readonly TooltipPayloadItem[]) =>
  chartConfig[payload?.[0]?.dataKey as keyof typeof chartConfig].label

<template>
  <Card class="flex flex-col" as |card|>
    <card.Header class="items-center pb-0">
      <card.Title>Pie Chart - Stacked</card.Title>
      <card.Description>January - June 2024</card.Description>
    </card.Header>
    <card.Content class="flex-1 pb-0">
      <ChartContainer
        @config={{chartConfig}}
        class="mx-auto aspect-square max-h-[250px]"
        as |chart|
      >
        <chart.PieChart as |c|>
          <c.ChartTooltip
            @content={{component
              ChartTooltipContent
              labelKey="visitors"
              nameKey="month"
              indicator="line"
              labelFormatter=pieLabel
            }}
          />
          <c.Pie @data={{desktopData}} @dataKey="desktop" @outerRadius={{60}} />
          <c.Pie @data={{mobileData}} @dataKey="mobile" @innerRadius={{70}} @outerRadius={{90}} />
        </chart.PieChart>
      </ChartContainer>
    </card.Content>
    <card.Footer class="flex-col gap-2 text-sm">
      <div class="flex items-center gap-2 leading-none font-medium">
        Trending up by 5.2% this month
        <Icon @icon={{TrendingUp}} class="h-4 w-4" />
      </div>
      <div class="leading-none text-muted-foreground">
        Showing total visitors for the last 6 months
      </div>
    </card.Footer>
  </Card>
</template>
