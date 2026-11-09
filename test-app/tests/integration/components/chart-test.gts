import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender, settled } from '@ember/test-helpers'
import Component from '@glimmer/component'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { TrendingDown, TrendingUp } from 'lucide'
import {
  ChartContainer,
  ChartLegendContent,
  ChartStyle,
  ChartTooltipContent,
  Dot,
  type ChartConfig,
  type DotArgs,
  type TooltipFormatterSignature,
} from '@ember-joinery/chart'
import { ChartHarness, ChartTooltipHarness } from '@ember-joinery/chart/test-support'

// The data and config of shadcn's chart examples.
const chartData = [
  { month: 'January', desktop: 186, mobile: 80 },
  { month: 'February', desktop: 305, mobile: 200 },
  { month: 'March', desktop: 237, mobile: 120 },
  { month: 'April', desktop: 73, mobile: 190 },
  { month: 'May', desktop: 209, mobile: 130 },
  { month: 'June', desktop: 214, mobile: 140 },
]

const chartConfig = {
  desktop: { label: 'Desktop', color: 'var(--chart-1)' },
  mobile: { label: 'Mobile', color: 'var(--chart-2)' },
} satisfies ChartConfig

const monthAbbr = (value: string) => value.slice(0, 3)
const twelve = { left: 12, right: 12 }

// What recharts 3.8 draws for the same charts at the same size (dumped from the parity app), so
// these tests hold Joinery's geometry to recharts'.
const RECHARTS = {
  areaDefault: {
    area: 'M12,41.456C25.667,25.385,39.333,9.313,53,4.641C66.667,-0.032,80.333,6.696,94,25.678C107.667,44.661,121.333,75.898,135,76.416C148.667,76.933,162.333,46.731,176,34.341C189.667,21.95,203.333,27.372,217,32.794L217,99C203.333,99,189.667,99,176,99C162.333,99,148.667,99,135,99C121.333,99,107.667,99,94,99C80.333,99,66.667,99,53,99C39.333,99,25.667,99,12,99Z',
    curve:
      'M12,41.456C25.667,25.385,39.333,9.313,53,4.641C66.667,-0.032,80.333,6.696,94,25.678C107.667,44.661,121.333,75.898,135,76.416C148.667,76.933,162.333,46.731,176,34.341C189.667,21.95,203.333,27.372,217,32.794',
  },
  areaAxes: {
    mobile:
      'M40,85.8C51.8,75.505,63.6,65.211,75.4,66C87.2,66.789,99,78.663,110.8,79.2C122.6,79.737,134.4,68.937,146.2,67.65C158,66.363,169.8,74.589,181.6,77.55C193.4,80.511,205.2,78.205,217,75.9L217,99C205.2,99,193.4,99,181.6,99C169.8,99,158,99,146.2,99C134.4,99,122.6,99,110.8,99C99,99,87.2,99,75.4,99C63.6,99,51.8,99,40,99Z',
    desktop:
      'M40,55.11C51.8,36.244,63.6,17.377,75.4,15.675C87.2,13.973,99,29.434,110.8,40.095C122.6,50.756,134.4,56.616,146.2,55.605C158,54.594,169.8,46.713,181.6,43.065C193.4,39.417,205.2,40.004,217,40.59L217,75.9C205.2,78.205,193.4,80.511,181.6,77.55C169.8,74.589,158,66.363,146.2,67.65C134.4,68.937,122.6,79.737,110.8,79.2C99,78.663,87.2,66.789,75.4,66C63.6,65.211,51.8,75.505,40,85.8Z',
  },
  lineDots: {
    curve:
      'M12,52.344C28.733,32.051,45.467,11.759,62.2,5.859C78.933,-0.04,95.667,8.454,112.4,32.422C129.133,56.39,145.867,95.831,162.6,96.484C179.333,97.138,196.067,59.004,212.8,43.359C229.533,27.715,246.267,34.561,263,41.406',
  },
}

module('Integration | components | chart', function (hooks) {
  setupRenderingTest(hooks)

  test('ChartContainer renders upstream classes, data attributes and colour variables', async function (assert) {
    const config = {
      desktop: { label: 'Desktop', color: '#2563eb' },
      mobile: { label: 'Mobile', theme: { light: '#60a5fa', dark: '#dc2626' } },
      views: { label: 'Page Views' },
    } satisfies ChartConfig
    await render(
      <template>
        <ChartContainer
          @config={{config}}
          @id="visitors"
          @name="visitors"
          class="h-[200px]"
          as |chart|
        >
          <chart.BarChart @data={{chartData}} as |c|>
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness('visitors')
    assert
      .dom(chart.element)
      .hasClass('jn-chart')
      .hasAttribute('data-slot', 'chart')
      .hasAttribute('data-chart', 'chart-visitors')
      .hasAttribute('data-test-jn', 'chart')
    assert.strictEqual(chart.color('desktop'), '#2563eb', 'a config colour')
    assert.strictEqual(chart.color('mobile'), '#60a5fa', "a theme's light colour")
    assert.strictEqual(chart.color('views'), '', 'nothing for an entry without a colour')
    const style = chart.element.querySelector('style')!.textContent!
    assert.true(style.includes('.dark [data-chart=chart-visitors]'), 'a rule for dark mode')
    assert.true(style.includes('--color-mobile: #dc2626;'), "the theme's dark colour")
    assert.strictEqual(
      getComputedStyle(chart.element).display,
      'flex',
      "upstream's inline utilities",
    )
    assert.strictEqual(getComputedStyle(chart.element).fontSize, '12px', 'text-xs')
    await a11yAudit()
  })

  test('an area chart draws the same area and line recharts draws', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="area" style="width: 229px" as |chart|>
          <chart.AreaChart
            @data={{chartData}}
            @margin={{twelve}}
            @accessibilityLayer={{true}}
            as |c|
          >
            <c.CartesianGrid @vertical={{false}} />
            <c.XAxis
              @dataKey="month"
              @tickLine={{false}}
              @axisLine={{false}}
              @tickMargin={{8}}
              @tickFormatter={{monthAbbr}}
            />
            <c.Area
              @dataKey="desktop"
              @type="natural"
              @fill="var(--color-desktop)"
              @fillOpacity={{0.4}}
              @stroke="var(--color-desktop)"
            />
          </chart.AreaChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness('area')
    assert.strictEqual(chart.width, 229)
    assert.strictEqual(chart.height, 129, 'aspect-video: 229 × 9 / 16, rounded')
    assert.deepEqual(chart.plot, { x: 12, y: 0, width: 205, height: 99 }, 'margins and the x-axis')
    const area = chart.seriesFor('desktop')
    assert.strictEqual(area.type, 'area')
    assert.strictEqual(area.areaPath, RECHARTS.areaDefault.area)
    assert.strictEqual(area.path, RECHARTS.areaDefault.curve)
    assert.strictEqual(area.fill, 'var(--color-desktop)')
    assert.deepEqual(chart.xTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    assert.deepEqual(chart.yTicks, [], 'no y-axis drawn')
    assert.true(
      chart.gridLines.horizontal.includes(99) && chart.gridLines.horizontal.includes(0),
      'the plot edges',
    )
    assert.deepEqual(chart.gridLines.vertical, [], 'vertical={false}')
    const tick = chart.surface.querySelector('.recharts-xAxis-tick-labels text')!
    assert
      .dom(tick)
      .hasAttribute('x', '12')
      .hasAttribute('y', '113', 'below the plot by tickSize and tickMargin')
    assert.dom(tick.querySelector('tspan')).hasAttribute('dy', '0.71em')
    // shadcn's CSS greys `.recharts-cartesian-axis-tick text`, recharts 2's labels; recharts 3
    // draws them in `.recharts-cartesian-axis-tick-label`, so they keep #666 on ui.shadcn.com too.
    assert.dom(tick).hasAttribute('fill', '#666')
    await a11yAudit()
  })

  test('stacked areas stack, and a y-axis takes its tick count', async function (assert) {
    const margin = { left: -20, right: 12 }
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 229px" as |chart|>
          <chart.AreaChart @data={{chartData}} @margin={{margin}} as |c|>
            <c.CartesianGrid @vertical={{false}} />
            <c.XAxis
              @dataKey="month"
              @tickLine={{false}}
              @axisLine={{false}}
              @tickMargin={{8}}
              @tickFormatter={{monthAbbr}}
            />
            <c.YAxis @tickLine={{false}} @axisLine={{false}} @tickMargin={{8}} @tickCount={{3}} />
            <c.Area
              @dataKey="mobile"
              @type="natural"
              @fill="var(--color-mobile)"
              @fillOpacity={{0.4}}
              @stroke="var(--color-mobile)"
              @stackId="a"
            />
            <c.Area
              @dataKey="desktop"
              @type="natural"
              @fill="var(--color-desktop)"
              @fillOpacity={{0.4}}
              @stroke="var(--color-desktop)"
              @stackId="a"
            />
          </chart.AreaChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(
      chart.plot,
      { x: 40, y: 0, width: 177, height: 99 },
      'the y-axis takes 60px from the left margin',
    )
    assert.deepEqual(chart.yTicks, ['0', '300', '600'], 'nice ticks over the stacked total')
    assert.strictEqual(chart.seriesFor('mobile').areaPath, RECHARTS.areaAxes.mobile)
    assert.strictEqual(
      chart.seriesFor('desktop').areaPath,
      RECHARTS.areaAxes.desktop,
      'on top of mobile',
    )
    const label = chart.surface.querySelector('.recharts-yAxis-tick-labels text')!
    assert.dom(label).hasAttribute('x', '26').hasAttribute('text-anchor', 'end')
    await a11yAudit()
  })

  test('a line chart draws its line and dots as recharts does', async function (assert) {
    const dot = { fill: 'var(--color-desktop)' }
    const activeDot = { r: 6 }
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 275px" as |chart|>
          <chart.LineChart @data={{chartData}} @margin={{twelve}} as |c|>
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
              @content={{component ChartTooltipContent hideLabel=true}}
            />
            <c.Line
              @dataKey="desktop"
              @type="natural"
              @stroke="var(--color-desktop)"
              @strokeWidth={{2}}
              @dot={{dot}}
              @activeDot={{activeDot}}
            />
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const line = chart.seriesFor('desktop')
    assert.strictEqual(line.type, 'line')
    assert.strictEqual(line.path, RECHARTS.lineDots.curve)
    assert.strictEqual(line.stroke, 'var(--color-desktop)')
    const dots = chart.dots('desktop')
    assert.strictEqual(dots.length, 6)
    assert
      .dom(dots[1])
      .hasAttribute('r', '3')
      .hasAttribute('cx', '62.2')
      .hasAttribute('cy', '5.859375')
    assert
      .dom(dots[1])
      .hasAttribute('fill', 'var(--color-desktop)')
      .hasAttribute('stroke-width', '2')
      .hasClass('recharts-line-dot')

    await chart.hover(1)
    assert.true(chart.isTooltipVisible)
    assert.strictEqual(chart.activeDots.length, 1)
    assert
      .dom(chart.activeDots[0])
      .hasAttribute('r', '6', 'activeDot={{r: 6}}')
      .hasAttribute('stroke', '#fff')
    assert.strictEqual(chart.cursor, null, 'cursor={false}')
    assert.strictEqual(chart.tooltip?.label, null, 'hideLabel')
    assert.deepEqual(chart.tooltip?.names, ['Desktop'])
    await a11yAudit()
  })

  test('a bar chart lays out grouped bars, its legend, and a band cursor', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 1200px" as |chart|>
          <chart.BarChart @data={{chartData}} @accessibilityLayer={{true}} as |c|>
            <c.CartesianGrid @vertical={{false}} />
            <c.XAxis
              @dataKey="month"
              @tickLine={{false}}
              @tickMargin={{10}}
              @axisLine={{false}}
              @tickFormatter={{monthAbbr}}
            />
            <c.ChartTooltip @content={{component ChartTooltipContent}} />
            <c.ChartLegend @content={{component ChartLegendContent}} />
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
            <c.Bar @dataKey="mobile" @fill="var(--color-mobile)" @radius={{4}} />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.strictEqual(chart.height, 675)
    assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'])
    const legendHeight = chart.wrapper.querySelector<HTMLElement>(
      '.recharts-legend-wrapper',
    )!.offsetHeight
    assert.strictEqual(legendHeight, 28, 'pt-3 and a 16px line')
    assert.deepEqual(
      chart.plot,
      { x: 5, y: 5, width: 1190, height: 607 },
      'the legend takes its height from the plot',
    )
    const [january] = chart.bars('desktop')
    assert.strictEqual(
      january!.getAttribute('d')!.replace(/\s+/g, ' '),
      'M 24.8333,263.1813 A 4,4,0,0,1,28.8333,259.1813 L 97.8333,259.1813 A 4,4,0,0,1,101.8333,263.1813 L 101.8333,608 A 4,4,0,0,1,97.8333,612 L 28.8333,612 A 4,4,0,0,1,24.8333,608 Z',
      "recharts' bar: 10% of the band each side, a 4px gap, radius 4",
    )
    assert.deepEqual(
      chart.seriesFor('mobile').points.map(point => point.x),
      [105.833, 304.167, 502.5, 700.833, 899.167, 1097.5],
    )
    assert.deepEqual(
      chart.categories,
      [104.167, 302.5, 500.833, 699.167, 897.5, 1095.833],
      'band centres',
    )

    await chart.hover(1)
    assert.true(chart.isTooltipVisible)
    assert.strictEqual(chart.tooltip?.label, 'February')
    assert.deepEqual(
      chart.tooltip?.names,
      ['Desktop', 'Mobile'],
      'sorted by name, as recharts sorts them',
    )
    assert.deepEqual(chart.tooltip?.entryValues, ['305', '200'])
    assert.strictEqual(chart.tooltip?.indicator, 'dot')
    assert.dom(chart.cursor).hasClass('recharts-rectangle').hasClass('recharts-tooltip-cursor')
    assert.strictEqual(
      chart.cursor!.getAttribute('d')!.replace(/\s+/g, ' '),
      'M 203.3333,5.5 h 198.3333 v 606 h -198.3333 Z',
      "the band under the pointer, as recharts' cursor",
    )
    await chart.unhover()
    assert.false(chart.isTooltipVisible)
    await a11yAudit()
  })

  test('the tooltip follows the pointer and stays inside the plot', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 229px" as |chart|>
          <chart.AreaChart @data={{chartData}} @margin={{twelve}} as |c|>
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
            <c.Area
              @dataKey="desktop"
              @type="natural"
              @fill="var(--color-desktop)"
              @fillOpacity={{0.4}}
              @stroke="var(--color-desktop)"
            />
          </chart.AreaChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    await chart.hover(2)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.indicator, 'line')
    assert.strictEqual(tooltip.label, 'March', 'one series and a line: the label nests beside it')
    assert.deepEqual(
      tooltip.items.map(item => [item.name, item.value]),
      [['Desktop', '237']],
    )
    assert.dom(tooltip.items[0]!.indicator).hasStyle({ width: '4px' }, 'w-1')
    const [dot] = chart.activeDots
    assert
      .dom(dot)
      .hasAttribute('cx', '94')
      .hasAttribute('r', '4')
      .hasAttribute('fill', 'var(--color-desktop)')
    const position = chart.tooltipPosition!
    const box = chart.wrapper.querySelector<HTMLElement>('.recharts-tooltip-wrapper')!
    const width = box.offsetWidth
    assert.true(position.x >= 12 && position.x + width <= 217 + 1, 'inside the plot across')
    assert.strictEqual(
      position.x,
      Math.max(94 - width - 10, 12),
      'flipped to the left of the point',
    )
    await a11yAudit()
  })

  test('the keyboard moves the tooltip between rows (the accessibility layer)', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.LineChart @data={{chartData}} @accessibilityLayer={{true}} as |c|>
            <c.XAxis @dataKey="month" />
            <c.ChartTooltip @content={{component ChartTooltipContent}} />
            <c.Line @dataKey="desktop" @stroke="var(--color-desktop)" />
            <c.Line @dataKey="mobile" @stroke="var(--color-mobile)" />
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.dom(chart.surface).hasAttribute('role', 'application').hasAttribute('tabindex', '0')
    assert.false(chart.isTooltipVisible)

    await chart.focus()
    assert.true(chart.isTooltipVisible, 'focus shows the first row')
    assert.strictEqual(chart.tooltip?.label, 'January')
    await chart.press('ArrowRight')
    assert.strictEqual(chart.tooltip?.label, 'February')
    await chart.press('ArrowLeft')
    await chart.press('ArrowLeft')
    assert.strictEqual(chart.tooltip?.label, 'January', 'stops at the first row')
    await chart.press('Enter')
    assert.false(chart.isTooltipVisible, 'Enter hides it')
    await chart.press('Enter')
    assert.true(chart.isTooltipVisible, 'and shows it again')
    await chart.blur()
    assert.false(chart.isTooltipVisible, 'leaving the chart hides it')
    await a11yAudit()
  })

  test('without the accessibility layer the chart takes no focus', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.LineChart @data={{chartData}} @accessibilityLayer={{false}} as |c|>
            <c.Line @dataKey="desktop" />
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.dom(chart.surface).doesNotHaveAttribute('role').doesNotHaveAttribute('tabindex')
    await a11yAudit()
  })

  test('a reversed x-axis runs right to left, and the arrow keys follow it (RTL)', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
            <chart.BarChart @data={{chartData}} as |c|>
              <c.CartesianGrid @vertical={{false}} />
              <c.XAxis
                @dataKey="month"
                @tickLine={{false}}
                @axisLine={{false}}
                @tickFormatter={{monthAbbr}}
                @reversed={{true}}
              />
              <c.ChartTooltip @content={{component ChartTooltipContent}} />
              <c.ChartLegend @content={{component ChartLegendContent}} />
              <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{4}} />
            </chart.BarChart>
          </ChartContainer>
        </DirectionProvider>
      </template>,
    )
    const chart = new ChartHarness()
    const [first, , , , , last] = chart.categories
    assert.true(first! > last!, 'January on the right')
    const legend = chart.legend!.element
    assert.strictEqual(
      getComputedStyle(legend).direction,
      'rtl',
      'the legend lays out right to left',
    )
    await chart.focus()
    assert.strictEqual(chart.tooltip?.label, 'January')
    await chart.press('ArrowLeft')
    assert.strictEqual(chart.tooltip?.label, 'February', 'left moves on along a reversed axis')
    await a11yAudit()
  })

  test('the chart fills its container and follows its size', async function (assert) {
    class State {
      @tracked width = 300
    }
    const state = new State()
    const style = (width: number) => `width: ${width}px; min-height: 200px`
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{style state.width}} as |chart|>
          <chart.LineChart @data={{chartData}} as |c|>
            <c.Line @dataKey="desktop" />
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.strictEqual(chart.width, 300)
    assert.strictEqual(chart.height, 200, 'a min-height over aspect-video (169)')
    state.width = 640
    await rerender()
    await new Promise(resolve => requestAnimationFrame(() => requestAnimationFrame(resolve)))
    await settled()
    assert.strictEqual(chart.width, 640, 'a resize redraws it')
    assert.strictEqual(chart.height, 360, 'aspect-video')
    await a11yAudit()
  })

  test('a config icon replaces the legend swatch and the tooltip indicator', async function (assert) {
    const config = {
      desktop: { label: 'Desktop', color: 'var(--chart-1)', icon: TrendingDown },
      mobile: { label: 'Mobile', color: 'var(--chart-2)', icon: TrendingUp },
    } satisfies ChartConfig
    await render(
      <template>
        <ChartContainer @config={{config}} style="width: 400px" as |chart|>
          <chart.AreaChart @data={{chartData}} as |c|>
            <c.ChartTooltip @content={{component ChartTooltipContent}} />
            <c.ChartLegend @content={{component ChartLegendContent}} />
            <c.Area
              @dataKey="mobile"
              @stackId="a"
              @stroke="var(--color-mobile)"
              @fill="var(--color-mobile)"
            />
            <c.Area
              @dataKey="desktop"
              @stackId="a"
              @stroke="var(--color-desktop)"
              @fill="var(--color-desktop)"
            />
          </chart.AreaChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const legend = chart.legend!
    assert.deepEqual(
      legend.labels,
      ['Desktop', 'Mobile'],
      'sorted by data key, as recharts sorts the legend',
    )
    assert.strictEqual(legend.items[0]!.swatch, null, 'an icon in place of the swatch')
    assert.dom(legend.element.querySelector('svg')).hasStyle({ width: '12px', height: '12px' })
    await chart.hover(0)
    assert.strictEqual(chart.tooltip!.items[0]!.indicator, null)
    assert.dom(chart.tooltip!.element.querySelector('svg')).hasStyle({ width: '10px' })
    await a11yAudit()
  })

  test('stackOffset="expand" stacks to 100%', async function (assert) {
    const data = [
      { month: 'January', desktop: 186, mobile: 80, other: 45 },
      { month: 'February', desktop: 305, mobile: 200, other: 100 },
    ]
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 300px" as |chart|>
          <chart.AreaChart @data={{data}} @stackOffset="expand" @margin={{twelve}} as |c|>
            <c.YAxis />
            <c.Area @dataKey="other" @stackId="a" />
            <c.Area @dataKey="mobile" @stackId="a" />
            <c.Area @dataKey="desktop" @stackId="a" />
          </chart.AreaChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const ticks = ['0', '0.25', '0.5', '0.75', '1']
    assert.true(
      chart.yTicks.every(tick => ticks.includes(tick)),
      'fractions of the whole',
    )
    assert.strictEqual(chart.yTicks.at(-1), '1')
    const top = chart.seriesFor('desktop').points.map(point => point.y)
    assert.deepEqual(top, [chart.plot.y, chart.plot.y], 'the top series reaches 100% in every row')
    await a11yAudit()
  })

  test('a label list labels each point, and a custom dot draws itself', async function (assert) {
    const formatter = (value: string) => value.toUpperCase()
    const margin = { top: 20, left: 12, right: 12 }
    const ColoredDot: TOC<{ Args: DotArgs; Element: Element }> = <template>
      <Dot
        @cx={{@cx}}
        @cy={{@cy}}
        @r={{5}}
        fill={{@payload.fill}}
        stroke={{@payload.fill}}
        data-test-dot
      />
    </template>
    const data = [
      { browser: 'chrome', visitors: 275, fill: 'red' },
      { browser: 'safari', visitors: 200, fill: 'blue' },
    ]
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 300px" as |chart|>
          <chart.LineChart @data={{data}} @margin={{margin}} as |c|>
            <c.Line @dataKey="visitors" @dot={{ColoredDot}} as |line|>
              <line.LabelList
                @position="top"
                @offset={{12}}
                @class="fill-foreground"
                @fontSize={{12}}
                @dataKey="browser"
                @formatter={{formatter}}
              />
            </c.Line>
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(chart.labels('visitors'), ['CHROME', 'SAFARI'])
    const [label] = chart.surface.querySelectorAll('.recharts-label-list text')
    const [point] = chart.seriesFor('visitors').points
    assert.true(
      Math.abs(Number(label!.getAttribute('y')) - (point!.y - 12)) < 0.001,
      '12px above its point',
    )
    assert.dom(label).hasAttribute('text-anchor', 'middle').hasAttribute('font-size', '12')
    const dots = chart.dots('visitors')
    assert.strictEqual(dots.length, 2)
    assert
      .dom(dots[0])
      .hasAttribute('data-test-dot')
      .hasAttribute('fill', 'red')
      .hasAttribute('r', '5')
      .hasClass('recharts-dot')
    await a11yAudit()
  })

  test("the chart tooltip's own label formatter and class reach its content", async function (assert) {
    const upper = (value: unknown) => String(value).toUpperCase()
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.BarChart @data={{chartData}} as |c|>
            <c.XAxis @dataKey="month" />
            <c.ChartTooltip
              @content={{component ChartTooltipContent indicator="line"}}
              @labelFormatter={{upper}}
              @labelClassName="w-32"
            />
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    await chart.hover(0)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.label, 'JANUARY', "the tooltip's labelFormatter")
    assert.strictEqual(tooltip.indicator, 'line', "the content's own curried arguments stay")
    assert.dom(tooltip.part('label')).hasClass('w-32')
    await a11yAudit()
  })

  test("a component @formatter draws each entry, as recharts' formatter can return markup", async function (assert) {
    // The shape of upstream's chart-tooltip-advanced: the label, the value with a unit, and a
    // total under the last entry.
    const totalOf = (row: Record<string, unknown> | undefined) => String(row?.['total'])
    const Kcal: TOC<TooltipFormatterSignature> = <template>
      <span data-test-kcal={{@name}}>{{@value}} kcal</span>
      {{#if @index}}<span data-test-total>Total {{totalOf @payload}}</span>{{/if}}
    </template>
    const data = chartData.map(row => ({ ...row, total: row.desktop + row.mobile }))
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.BarChart @data={{data}} as |c|>
            <c.XAxis @dataKey="month" />
            <c.ChartTooltip
              @content={{component ChartTooltipContent hideLabel=true formatter=Kcal}}
            />
            <c.Bar @dataKey="desktop" @stackId="a" @fill="var(--color-desktop)" />
            <c.Bar @dataKey="mobile" @stackId="a" @fill="var(--color-mobile)" />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    await chart.hover(1)
    const tooltip = chart.tooltip!
    assert.strictEqual(tooltip.items.length, 2)
    assert.dom('[data-test-kcal="desktop"]', tooltip.element).hasText('305 kcal')
    assert.dom('[data-test-kcal="mobile"]', tooltip.element).hasText('200 kcal')
    assert.dom('[data-test-total]', tooltip.element).exists({ count: 1 }).hasText('Total 505')
    assert.deepEqual(
      tooltip.items.map(item => [item.indicator, item.value]),
      [
        [null, null],
        [null, null],
      ],
      'in place of the indicator, name and value',
    )
    await a11yAudit()
  })

  test("the chart tooltip's own @formatter can be a class component, handed the config", async function (assert) {
    class Labelled extends Component<TooltipFormatterSignature> {
      get label(): string {
        return this.args.config[String(this.args.name)]?.label ?? String(this.args.name)
      }
      <template>
        <span data-test-labelled>{{this.label}} {{@value}} ({{@item.color}})</span>
      </template>
    }
    const toText = (value: unknown, name: string | number) => `${String(name)}=${String(value)}`
    const payload = [{ name: 'desktop', value: 186, dataKey: 'desktop', payload: {} }]
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.LineChart @data={{chartData}} as |c|>
            <c.XAxis @dataKey="month" />
            <c.ChartTooltip @content={{component ChartTooltipContent}} @formatter={{Labelled}} />
            <c.Line @dataKey="desktop" @stroke="var(--color-desktop)" />
          </chart.LineChart>
        </ChartContainer>
        <div data-test-text>
          <ChartTooltipContent @active={{true}} @payload={{payload}} @formatter={{toText}} />
        </div>
      </template>,
    )
    const chart = new ChartHarness()
    await chart.hover(2)
    assert
      .dom('[data-test-labelled]', chart.tooltip!.element)
      .hasText('Desktop 237 (var(--color-desktop))')
    assert
      .dom('[data-test-text] [data-test-jn-part="item"]')
      .hasText('desktop=186', 'a function still formats the entry as text')
    await a11yAudit()
  })

  test('the tooltip can start on a row, or be kept hidden (@defaultIndex, @active)', async function (assert) {
    class State {
      @tracked active: boolean | undefined = undefined
    }
    const state = new State()
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.LineChart @data={{chartData}} as |c|>
            <c.XAxis @dataKey="month" />
            <c.ChartTooltip
              @content={{component ChartTooltipContent}}
              @defaultIndex={{2}}
              @active={{state.active}}
            />
            <c.Line @dataKey="desktop" @stroke="var(--color-desktop)" />
          </chart.LineChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.strictEqual(chart.tooltip?.label, 'March', 'shown at @defaultIndex before any pointer')
    await chart.hover(4)
    assert.strictEqual(chart.tooltip?.label, 'May', 'the pointer takes over')
    await chart.unhover()
    state.active = false
    await rerender()
    await chart.hover(1)
    assert.false(chart.isTooltipVisible, '@active={{false}} never shows it')
    await a11yAudit()
  })

  test('a vertical bar chart lays its categories down the y-axis', async function (assert) {
    const margin = { left: -20 }
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 400px" as |chart|>
          <chart.BarChart @data={{chartData}} @layout="vertical" @margin={{margin}} as |c|>
            <c.XAxis @type="number" @dataKey="desktop" @hide={{true}} />
            <c.YAxis
              @dataKey="month"
              @type="category"
              @tickLine={{false}}
              @tickMargin={{10}}
              @axisLine={{false}}
              @tickFormatter={{monthAbbr}}
            />
            <c.ChartTooltip @content={{component ChartTooltipContent}} />
            <c.Bar @dataKey="desktop" @fill="var(--color-desktop)" @radius={{5}} />
          </chart.BarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(chart.yTicks, ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'])
    const bars = chart.bars('desktop').map(bar => bar.getBoundingClientRect())
    assert.true(bars[0]!.top < bars[1]!.top, 'January above February')
    assert.true(bars[1]!.width > bars[0]!.width, 'February (305) longer than January (186)')
    await chart.hover(1)
    assert.strictEqual(chart.tooltip?.label, 'February')
    await a11yAudit()
  })

  test('ChartTooltipContent renders on its own, with labelKey, nameKey and formatters', async function (assert) {
    const payload = [
      {
        name: 'chrome',
        value: 1286,
        dataKey: 'visitors',
        payload: { browser: 'chrome', fill: 'var(--chart-1)' },
      },
    ]
    const config = {
      visitors: { label: 'Total Visitors' },
      chrome: { label: 'Chrome', color: 'var(--chart-1)' },
    } satisfies ChartConfig
    const labelFormatter = (value: unknown) => `→ ${String(value)}`
    await render(
      <template>
        <ChartTooltipContent
          @active={{true}}
          @payload={{payload}}
          @label="ignored"
          @config={{config}}
          @labelKey="visitors"
          @nameKey="browser"
          @labelFormatter={{labelFormatter}}
        />
        <ChartTooltipContent @active={{false}} @payload={{payload}} @label="hidden" />
      </template>,
    )
    const tooltips = ChartTooltipHarness.findAll()
    assert.strictEqual(tooltips.length, 1, 'an inactive tooltip draws nothing')
    const tooltip = tooltips[0]!
    assert.strictEqual(
      tooltip.label,
      '→ Total Visitors',
      'labelKey finds the config label; labelFormatter formats it',
    )
    assert.deepEqual(tooltip.names, ['Chrome'], "nameKey finds the row's browser in the config")
    assert.deepEqual(tooltip.entryValues, ['1,286'], 'numbers are formatted')
    assert.dom(tooltip.items[0]!.indicator).hasStyle({ width: '10px', height: '10px' }, 'a dot')
    assert.dom(tooltip.element).hasClass('jn-chart-tooltip').hasStyle({ fontSize: '12px' })
    await a11yAudit()
  })

  test('ChartStyle writes nothing for a config without colours', async function (assert) {
    const config = { views: { label: 'Views' } } satisfies ChartConfig
    await render(
      <template>
        <div data-test-style><ChartStyle @id="x" @config={{config}} /></div>
      </template>,
    )
    assert.dom('[data-test-style] style').doesNotExist()
    await a11yAudit()
  })
})
