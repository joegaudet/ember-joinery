import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  ChartContainer,
  ChartLegendContent,
  ChartTooltipContent,
  type ChartConfig,
  type PolarAngleAxisTickArgs,
} from '@ember-joinery/chart'
import { PolarChartHarness } from '@ember-joinery/chart/test-support'

// The data and config of shadcn's radar charts (registry/new-york-v4/charts/chart-radar-*).
const desktopData = [
  { month: 'January', desktop: 186 },
  { month: 'February', desktop: 305 },
  { month: 'March', desktop: 237 },
  { month: 'April', desktop: 273 },
  { month: 'May', desktop: 209 },
  { month: 'June', desktop: 214 },
]

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

// The gallery's charts are 229px square (`aspect-square max-h-[250px]` in their card).
const square = 'width: 229px; height: 229px; aspect-ratio: auto'

// What recharts 3.8 draws for the same charts at the same size (dumped from the parity app), so
// these tests hold Joinery's geometry to recharts'.
const RECHARTS = {
  default: {
    polygon:
      'M114.5,63.5825L186.8077,72.7531L170.6866,146.9394L114.5,189.2337L64.9514,143.1069L63.7661,85.2088L114.5,63.5825Z',
    ring: 'M 114.5,92.6L 133.4659563428792,103.55L 133.4659563428792,125.45L 114.5,136.4L 95.53404365712079,125.45L 95.5340436571208,103.55Z',
    axisLine:
      'M114.5,26.9L190.3638,70.7L190.3638,158.3L114.5,202.1L38.6362,158.3L38.6362,70.7L114.5,26.9Z',
    ticks: [
      ['114.5', '18.900000000000006', 'middle', '0em', 'January'],
      ['197.29202860179234', '66.70000000000002', 'start', '0.355em', 'February'],
      ['197.29202860179234', '162.29999999999998', 'start', '0.355em', 'March'],
      ['114.5', '210.1', 'middle', '0.71em', 'April'],
      ['31.70797139820766', '162.29999999999998', 'end', '0.355em', 'May'],
      ['31.707971398207675', '66.69999999999999', 'end', '0.355em', 'June'],
    ],
  },
  dots: [
    ['114.5', '63.582499999999996'],
    ['186.807708557227', '72.75312500000001'],
    ['170.68664566577965', '146.93937499999998'],
    ['114.5', '189.23375'],
    ['64.95143905422808', '143.106875'],
    ['63.766066782798134', '85.20875'],
  ],
  multiple: {
    desktop:
      'M114.5,63.5825L186.8077,72.7531L170.6866,146.9394L114.5,134.4837L64.9514,143.1069L63.7661,85.2088L114.5,63.5825Z',
    mobile:
      'M114.5,92.6L161.9149,87.125L142.9489,130.925L114.5,166.5125L83.6803,132.2938L81.3096,95.3375L114.5,92.6Z',
  },
  labelCustom: {
    desktop:
      'M114.5,65.9075L183.506,74.6594L168.121,145.4581L114.5,133.5713L67.2139,141.8006L66.0827,86.5463L114.5,65.9075Z',
    // Upstream's tick draws January 10px higher than it is handed; this test's tick doesn't.
    ticks: [
      ['114.5', '22.900000000000006', 'middle'],
      ['193.82792698665457', '68.70000000000002', 'start'],
      ['193.82792698665457', '160.29999999999998', 'start'],
      ['114.5', '206.1', 'middle'],
      ['35.172073013345425', '160.29999999999998', 'end'],
      ['35.172073013345425', '68.69999999999999', 'end'],
    ],
  },
  radius: [
    ['rotate(30, 114.5, 114.5)', '0'],
    ['rotate(30, 125.45, 95.5340436571208)', '80'],
    ['rotate(30, 136.4, 76.5680873142416)', '160'],
    ['rotate(30, 147.35, 57.60213097136239)', '240'],
    ['rotate(30, 158.3, 38.63617462848319)', '320'],
  ],
}

const dot = { r: 4, fillOpacity: 1 }
const fillClass = 'fill-(--color-desktop) opacity-20'
const ninety = [90]
const tenAround = { top: 10, right: 10, bottom: 10, left: 10 }

module('Integration | components | chart-radar', function (hooks) {
  setupRenderingTest(hooks)

  test('a radar chart draws the grid, polygon and angle axis recharts draws', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="radar" style={{square}} as |chart|>
          <chart.RadarChart @data={{desktopData}} as |c|>
            <c.ChartTooltip @cursor={{false}} @content={{component ChartTooltipContent}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.PolarGrid />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('radar')
    assert.strictEqual(chart.width, 229)
    assert.strictEqual(chart.layout, 'centric')
    assert.deepEqual(
      chart.ring,
      { cx: 114.5, cy: 114.5, innerRadius: 0, outerRadius: 87.6, startAngle: 90, endAngle: -270 },
      "the ring: 80% of the largest radius the margins leave, from 12 o'clock clockwise",
    )
    assert.deepEqual(chart.categories, [90, 30, -30, -90, -150, -210], 'a spoke per month')

    const radar = chart.seriesFor('desktop')
    assert.strictEqual(radar.type, 'radar')
    assert
      .dom(chart.polygon('desktop'))
      .hasAttribute('d', RECHARTS.default.polygon)
      .hasAttribute('fill', 'var(--color-desktop)')
      .hasAttribute('fill-opacity', '0.6')
      .hasClass('recharts-polygon')
      .doesNotHaveAttribute('stroke')
    assert.dom(radar.element).hasClass('recharts-radar')

    const grid = chart.polarGrid!
    assert.strictEqual(grid.type, 'polygon')
    assert.deepEqual(
      grid.radii,
      [0, 21.9, 43.8, 65.69999999999999, 87.6],
      "a ring at each of the radius axis's nice ticks (0 to 320)",
    )
    assert
      .dom(grid.rings[1])
      .hasAttribute('d', RECHARTS.default.ring)
      .hasAttribute('stroke', '#ccc')
    assert.deepEqual(grid.angles, [90, 30, -30, -90, -150, -210], 'a spoke at each month')
    assert.dom(grid.spokes[0]).hasAttribute('x2', '114.5').hasAttribute('y2', '26.900000000000006')
    assert.notStrictEqual(
      getComputedStyle(grid.rings[1]!).stroke,
      'rgb(204, 204, 204)',
      "the chart's CSS turns the grid's #ccc into --border",
    )

    assert.deepEqual(chart.angleTicks, ['January', 'February', 'March', 'April', 'May', 'June'])
    const texts = Array.from(chart.angleAxis!.querySelectorAll('text'))
    assert.deepEqual(
      texts.map(text => [
        text.getAttribute('x'),
        text.getAttribute('y'),
        text.getAttribute('text-anchor'),
        text.querySelector('tspan')!.getAttribute('dy'),
        text.textContent,
      ]),
      RECHARTS.default.ticks,
      "each label at its tick mark's end, anchored away from the ring",
    )
    assert
      .dom(texts[0])
      .hasAttribute('fill', '#808080')
      .hasClass('recharts-polar-angle-axis-tick-value')
    const axisLine = chart.angleAxis!.querySelector('.recharts-polar-angle-axis-line')!
    assert.dom(axisLine).hasAttribute('d', RECHARTS.default.axisLine).doesNotHaveAttribute('stroke')
    assert.deepEqual(chart.dots('desktop'), [], 'no dots by default')
    await a11yAudit()
  })

  test("a radar's dots, and the grid's circles, spokes and rings", async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="dots" style={{square}} as |chart|>
          <chart.RadarChart @data={{desktopData}} as |c|>
            <c.PolarGrid @gridType="circle" @radialLines={{false}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar
              @dataKey="desktop"
              @fill="var(--color-desktop)"
              @fillOpacity={{0.6}}
              @dot={{dot}}
            />
          </chart.RadarChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="custom" style={{square}} as |chart|>
          <chart.RadarChart @data={{desktopData}} as |c|>
            <c.PolarGrid @radialLines={{false}} @polarRadius={{ninety}} @strokeWidth={{1}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.RadarChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="filled" style={{square}} as |chart|>
          <chart.RadarChart @data={{desktopData}} as |c|>
            <c.PolarGrid @class={{fillClass}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const dots = new PolarChartHarness('dots')
    assert.deepEqual(
      dots.dots('desktop').map(circle => [circle.getAttribute('cx'), circle.getAttribute('cy')]),
      RECHARTS.dots,
      'a dot at each point',
    )
    assert
      .dom(dots.dots('desktop')[0])
      .hasClass('recharts-radar-dot')
      .hasAttribute('r', '4')
      .hasAttribute('fill', 'var(--color-desktop)')
      .hasAttribute('fill-opacity', '1')
    const circles = dots.polarGrid!
    assert.strictEqual(circles.type, 'circle')
    assert.deepEqual(circles.spokes, [], 'no spokes')
    assert
      .dom(circles.rings[4])
      .hasAttribute('r', '87.6')
      .hasClass('recharts-polar-grid-concentric-circle')

    const custom = new PolarChartHarness('custom').polarGrid!
    assert.deepEqual(custom.radii, [90], 'one ring, at the radius given')
    assert.dom(custom.rings[0]).hasAttribute('stroke-width', '1')

    const filled = new PolarChartHarness('filled').polarGrid!
    assert.dom(filled.rings[2]).hasClass('opacity-20', "the grid's class on each ring")
    assert.dom(filled.spokes[2]).hasClass('opacity-20', '…and on each spoke, as recharts puts it')
    await a11yAudit()
  })

  test('two radars, a legend and lines only', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="multiple" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
            <c.ChartTooltip
              @cursor={{false}}
              @content={{component ChartTooltipContent indicator="line"}}
            />
            <c.PolarAngleAxis @dataKey="month" />
            <c.PolarGrid />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
            <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
            <c.ChartLegend @content={{component ChartLegendContent}} />
          </chart.RadarChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="lines" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
            <c.PolarGrid @radialLines={{false}} />
            <c.Radar
              @dataKey="mobile"
              @fill="var(--color-mobile)"
              @fillOpacity={{0}}
              @stroke="var(--color-mobile)"
              @strokeWidth={{2}}
            />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('multiple')
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    assert.dom(chart.polygon('mobile')).hasAttribute('fill', 'var(--color-mobile)')
    assert.deepEqual(chart.legend?.labels, ['Desktop', 'Mobile'], 'the legend names each radar')
    const wrapper = chart.wrapper.querySelector<HTMLElement>('.recharts-legend-wrapper')!
    assert.true(wrapper.style.bottom === '5px', 'the legend sits in the bottom margin')

    const lines = new PolarChartHarness('lines')
    assert
      .dom(lines.polygon('mobile'))
      .hasAttribute('fill-opacity', '0')
      .hasAttribute('stroke', 'var(--color-mobile)')
      .hasAttribute('stroke-width', '2')
    assert.strictEqual(lines.polarGrid!.spokes.length, 0)
    assert.deepEqual(lines.angleTicks, [], 'no angle axis drawn without one')
    await a11yAudit()
  })

  test('the geometry matches recharts with two radars and a margin', async function (assert) {
    const Tick: TOC<{ Args: PolarAngleAxisTickArgs; Element: SVGElement }> = <template>
      <text x={{@x}} y={{@y}} text-anchor={{@textAnchor}} stroke={{@stroke}}>
        <tspan>{{@value}}</tspan>
      </text>
    </template>
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="custom" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} @margin={{tenAround}} as |c|>
            <c.PolarAngleAxis @dataKey="month" @tick={{Tick}} />
            <c.PolarGrid />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
            <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
          </chart.RadarChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="multiple" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
            <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const custom = new PolarChartHarness('custom')
    assert.dom(custom.polygon('desktop')).hasAttribute('d', RECHARTS.labelCustom.desktop)
    const texts = Array.from(custom.angleAxis!.querySelectorAll('text'))
    assert.deepEqual(
      texts.map(text => [
        text.getAttribute('x'),
        text.getAttribute('y'),
        text.getAttribute('text-anchor'),
      ]),
      RECHARTS.labelCustom.ticks,
      'a custom tick is handed where recharts puts its label',
    )
    assert.dom(texts[0]).hasAttribute('stroke', 'none').hasText('January')
    assert.deepEqual(custom.angleTicks[1], 'February', 'the harness reads a custom tick too')

    const multiple = new PolarChartHarness('multiple')
    assert.dom(multiple.polygon('desktop')).hasAttribute('d', RECHARTS.multiple.desktop)
    assert.dom(multiple.polygon('mobile')).hasAttribute('d', RECHARTS.multiple.mobile)
    await a11yAudit()
  })

  test("a radius axis at an angle, with recharts' labels", async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="radius" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
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
      </template>,
    )
    const chart = new PolarChartHarness('radius')
    assert.deepEqual(chart.radiusTicks, ['0', '80', '160', '240', '320'])
    const texts = Array.from(chart.radiusAxis!.querySelectorAll('text'))
    assert.deepEqual(
      texts.map(text => [text.getAttribute('transform'), text.textContent]),
      RECHARTS.radius,
      'each label along the axis, turned to read across it',
    )
    assert
      .dom(texts[1])
      .hasAttribute('text-anchor', 'middle')
      .hasAttribute('fill', 'var(--foreground)')
    assert.dom(chart.radiusAxis!.querySelector('.recharts-polar-radius-axis-line')).doesNotExist()
    assert.deepEqual(chart.angleTicks, [], 'no angle axis: the chart numbers the rows')
    await a11yAudit()
  })

  test('the tooltip follows the pointer round the chart, with active dots', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="tooltip" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
            <c.ChartTooltip
              @isAnimationActive={{false}}
              @content={{component ChartTooltipContent indicator="line"}}
            />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
            <c.Radar @dataKey="mobile" @fill="var(--color-mobile)" />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('tooltip')
    assert.false(chart.isTooltipVisible)
    await chart.hover(1)
    assert.true(chart.isTooltipVisible)
    assert.strictEqual(chart.tooltip?.label, 'February')
    assert.deepEqual(chart.tooltip?.names, ['Desktop', 'Mobile'], 'sorted by name')
    assert.deepEqual(chart.tooltip?.entryValues, ['305', '200'])
    assert.strictEqual(chart.activeDots.length, 2, 'a dot on each radar at the row')
    assert
      .dom(chart.activeDots[0])
      .hasAttribute('stroke', '#fff')
      .hasAttribute('fill', 'var(--color-desktop)')
      .hasAttribute('r', '4')
    assert
      .dom(chart.cursor)
      .hasClass('recharts-curve')
      .hasAttribute(
        'd',
        'M114.5,114.5L190.36382537151684,70.70000000000002',
        "a cursor along the row's spoke, recharts' default",
      )
    await chart.hover(3)
    assert.strictEqual(chart.tooltip?.label, 'April')
    await chart.unhover()
    assert.false(chart.isTooltipVisible)
    assert.strictEqual(chart.activeDots.length, 0)
    await a11yAudit()
  })

  test('the keyboard moves the tooltip from row to row', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="keys" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} as |c|>
            <c.ChartTooltip @cursor={{false}} @content={{component ChartTooltipContent}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('keys')
    assert.dom(chart.surface).hasAttribute('role', 'application').hasAttribute('tabindex', '0')
    await chart.focus()
    assert.strictEqual(chart.tooltip?.label, 'January', 'focus shows the first row')
    const [point] = chart.seriesFor('desktop').points
    assert.true(
      Math.abs(chart.tooltipPosition!.y - (point!.y + 10)) < 1,
      "the tooltip points at the radar's point on the row, 10px below it",
    )
    await chart.press('ArrowRight')
    assert.strictEqual(chart.tooltip?.label, 'February')
    await chart.press('ArrowLeft')
    assert.strictEqual(chart.tooltip?.label, 'January')
    await chart.press('ArrowLeft')
    assert.strictEqual(chart.tooltip?.label, 'January', 'it stops at the first row')
    await chart.press('Enter')
    assert.false(chart.isTooltipVisible, 'Enter hides it')
    await chart.press('Enter')
    assert.true(chart.isTooltipVisible, 'and shows it again')
    await chart.blur()
    assert.false(chart.isTooltipVisible, 'leaving the chart hides it')
    await a11yAudit()
  })

  test('@accessibilityLayer={{false}} and @defaultIndex', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="quiet" style={{square}} as |chart|>
          <chart.RadarChart @data={{chartData}} @accessibilityLayer={{false}} as |c|>
            <c.ChartTooltip @defaultIndex={{2}} @content={{component ChartTooltipContent}} />
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness('quiet')
    assert.dom(chart.surface).doesNotHaveAttribute('role').doesNotHaveAttribute('tabindex')
    assert.strictEqual(chart.tooltip?.label, 'March', 'the row it starts at')
    await a11yAudit()
  })

  test('right to left, the chart draws as in left to right, as recharts does (RTL)', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="ltr" style={{square}} as |chart|>
          <chart.RadarChart @data={{desktopData}} as |c|>
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
            <c.ChartLegend @content={{component ChartLegendContent}} />
          </chart.RadarChart>
        </ChartContainer>
        <DirectionProvider @dir="rtl">
          <ChartContainer @config={{chartConfig}} @name="rtl" style={{square}} as |chart|>
            <chart.RadarChart @data={{desktopData}} as |c|>
              <c.ChartTooltip @content={{component ChartTooltipContent}} />
              <c.PolarAngleAxis @dataKey="month" />
              <c.Radar @dataKey="desktop" @fill="var(--color-desktop)" @fillOpacity={{0.6}} />
              <c.ChartLegend @content={{component ChartLegendContent}} />
            </chart.RadarChart>
          </ChartContainer>
        </DirectionProvider>
      </template>,
    )
    const chart = new PolarChartHarness('rtl')
    const ltr = new PolarChartHarness('ltr')
    assert
      .dom(chart.polygon('desktop'))
      .hasAttribute('d', ltr.polygon('desktop').getAttribute('d')!, 'the same polygon')
    assert.deepEqual(chart.categories, [90, 30, -30, -90, -150, -210], 'clockwise from the top')
    assert.strictEqual(
      getComputedStyle(chart.legend!.element).direction,
      'rtl',
      'the legend lays out right to left',
    )
    await chart.focus()
    await chart.press('ArrowRight')
    assert.strictEqual(chart.tooltip?.label, 'February', 'ArrowRight moves on to the next row')
    assert.strictEqual(getComputedStyle(chart.tooltip!.element).direction, 'rtl')
    await a11yAudit()
  })

  test('PolarChartHarness reads the chart outside a container', async function (assert) {
    const side = 229
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} as |chart|>
          <chart.RadarChart
            @data={{desktopData}}
            @width={{side}}
            @height={{side}}
            @title="Visitors"
            as |c|
          >
            <c.PolarAngleAxis @dataKey="month" />
            <c.Radar @dataKey="desktop" @fillOpacity={{0.6}} />
          </chart.RadarChart>
        </ChartContainer>
      </template>,
    )
    const chart = new PolarChartHarness()
    assert.strictEqual(chart.width, 229, 'a fixed size')
    assert.dom(chart.surface.querySelector('title')).hasText('Visitors')
    assert.dom(chart.polygon('desktop')).hasAttribute('d', RECHARTS.default.polygon)
    await a11yAudit()
  })
})
