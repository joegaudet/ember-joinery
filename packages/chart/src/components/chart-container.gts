import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { idFor } from '@ember-joinery/primitives/id'
import ChartStyle from './chart-style.gts'
import AreaChart from './area-chart.gts'
import BarChart from './bar-chart.gts'
import LineChart from './line-chart.gts'
import PieChart from './pie-chart.gts'
import RadarChart from './radar-chart.gts'
import RadialBarChart from './radial-bar-chart.gts'
import type { ChartConfig } from '../types.ts'

/** What `ChartContainer` yields: the charts, each given the container's config. */
export interface ChartContainerParts {
  /** An area chart: recharts' `AreaChart`. */
  AreaChart: WithBoundArgs<typeof AreaChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A bar chart: recharts' `BarChart`. */
  BarChart: WithBoundArgs<typeof BarChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A line chart: recharts' `LineChart`. */
  LineChart: WithBoundArgs<typeof LineChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A pie chart: recharts' `PieChart`. */
  PieChart: WithBoundArgs<typeof PieChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A radar chart: recharts' `RadarChart`. */
  RadarChart: WithBoundArgs<typeof RadarChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A radial bar chart: recharts' `RadialBarChart`. */
  RadialBarChart: WithBoundArgs<
    typeof RadialBarChart,
    'config' | 'inContainer' | 'initialDimension'
  >
}

export interface ChartContainerSignature {
  Args: {
    /** The labels, icons and colours of the chart's series. */
    config: ChartConfig
    /** The chart's id, in `data-chart`. Default a unique one. */
    id?: string
    /** The chart's name, for its harness (`data-test-jn-name`). */
    name?: string
    /**
     * The size the chart draws at before the container has been measured (and in a page
     * rendered on the server), as shadcn's `initialDimension`. Default 320 × 200.
     */
    initialDimension?: { width: number; height: number }
  }
  Blocks: {
    /** The chart, from the parts it yields: `<ChartContainer as |chart|><chart.BarChart …>`. */
    default: [ChartContainerParts]
  }
  Element: HTMLDivElement
}

/** The size a chart draws at before its container has been measured, as shadcn's. */
const INITIAL_DIMENSION = { width: 320, height: 200 }

/**
 * The box a chart draws in, and its colours: shadcn's `ChartContainer`. It sets a
 * `--color-<key>` variable for each series in `@config`, and yields the charts, which fill it
 * (keep a height, a `min-h-*` or an aspect ratio on it; it is `aspect-video` by default).
 *
 *   <ChartContainer @config={{chartConfig}} class="min-h-[200px] w-full" as |chart|>
 *     <chart.BarChart @data={{chartData}} as |c|>
 *       <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
 *     </chart.BarChart>
 *   </ChartContainer>
 */
export default class ChartContainer extends Component<ChartContainerSignature> {
  get chartId(): string {
    return `chart-${this.args.id ?? idFor(this)}`
  }

  get initialDimension(): { width: number; height: number } {
    return this.args.initialDimension ?? INITIAL_DIMENSION
  }

  <template>
    <div
      class="jn-chart"
      data-slot="chart"
      data-chart={{this.chartId}}
      data-test-jn="chart"
      data-test-jn-name={{@name}}
      ...attributes
    >
      <ChartStyle @id={{this.chartId}} @config={{@config}} />
      {{yield
        (hash
          AreaChart=(component
            AreaChart config=@config inContainer=true initialDimension=this.initialDimension
          )
          BarChart=(component
            BarChart config=@config inContainer=true initialDimension=this.initialDimension
          )
          LineChart=(component
            LineChart config=@config inContainer=true initialDimension=this.initialDimension
          )
          PieChart=(component
            PieChart config=@config inContainer=true initialDimension=this.initialDimension
          )
          RadarChart=(component
            RadarChart config=@config inContainer=true initialDimension=this.initialDimension
          )
          RadialBarChart=(component
            RadialBarChart config=@config inContainer=true initialDimension=this.initialDimension
          )
        )
      }}
    </div>
  </template>
}
