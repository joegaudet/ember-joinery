import Component from '@glimmer/component'
import { hash } from '@ember/helper'
import type { WithBoundArgs } from '@glint/template'
import { idFor } from '@ember-joinery/primitives/id'
import ChartStyle from './chart-style.gts'
import AreaChart from './area-chart.gts'
import BarChart from './bar-chart.gts'
import LineChart from './line-chart.gts'
import type { ChartConfig } from '../types.ts'

/** What `ChartContainer` yields: the charts, each given the container's config. */
export interface ChartContainerParts {
  /** An area chart: recharts' `AreaChart`. */
  AreaChart: WithBoundArgs<typeof AreaChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A bar chart: recharts' `BarChart`. */
  BarChart: WithBoundArgs<typeof BarChart, 'config' | 'inContainer' | 'initialDimension'>
  /** A line chart: recharts' `LineChart`. */
  LineChart: WithBoundArgs<typeof LineChart, 'config' | 'inContainer' | 'initialDimension'>
}

export interface ChartContainerSignature {
  Args: {
    /** The labels, icons and colours of the chart's series. */
    config: ChartConfig
    /** The chart's id, in `data-chart`. Default a unique one. */
    id?: string
    /** The chart's name, for its harness (`data-test-jn-name`). */
    name?: string
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
            AreaChart config=@config inContainer=true initialDimension=INITIAL_DIMENSION
          )
          BarChart=(component
            BarChart config=@config inContainer=true initialDimension=INITIAL_DIMENSION
          )
          LineChart=(component
            LineChart config=@config inContainer=true initialDimension=INITIAL_DIMENSION
          )
        )
      }}
    </div>
  </template>
}
