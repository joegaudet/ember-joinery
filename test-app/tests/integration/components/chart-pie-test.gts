import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  ChartContainer,
  ChartLegendContent,
  ChartTooltipContent,
  Sector,
  type ChartConfig,
  type LabelContentSignature,
  type PieLabelSignature,
  type PieShapeSignature,
} from '@ember-joinery/chart'
import { ChartHarness } from '@ember-joinery/chart/test-support'

// The data and config of shadcn's pie charts (registry/new-york-v4/charts/chart-pie-*).
const chartData = [
  { browser: 'chrome', visitors: 275, fill: 'var(--color-chrome)' },
  { browser: 'safari', visitors: 200, fill: 'var(--color-safari)' },
  { browser: 'firefox', visitors: 187, fill: 'var(--color-firefox)' },
  { browser: 'edge', visitors: 173, fill: 'var(--color-edge)' },
  { browser: 'other', visitors: 90, fill: 'var(--color-other)' },
]

const chartConfig = {
  visitors: { label: 'Visitors' },
  chrome: { label: 'Chrome', color: 'var(--chart-1)' },
  safari: { label: 'Safari', color: 'var(--chart-2)' },
  firefox: { label: 'Firefox', color: 'var(--chart-3)' },
  edge: { label: 'Edge', color: 'var(--chart-4)' },
  other: { label: 'Other', color: 'var(--chart-5)' },
} satisfies ChartConfig

const size = 'width: 250px; height: 250px'
const flat = (d: string | null) => (d ?? '').replace(/\s+/g, ' ')

// What recharts 3.8 draws for the same pies at 250 × 250 (dumped from the parity app), so these
// tests hold Joinery's geometry to recharts'.
const RECHARTS = {
  pie: [
    'M 221,125 A 96,96,0, 0,0, 96.8891,33.208 L 125,125 Z',
    'M 96.8891,33.208 A 96,96,0, 0,0, 29.3458,133.1413 L 125,125 Z',
    'M 29.3458,133.1413 A 96,96,0, 0,0, 104.4561,218.7761 L 125,125 Z',
    'M 104.4561,218.7761 A 96,96,0, 0,0, 203.6125,180.1005 L 125,125 Z',
    'M 203.6125,180.1005 A 96,96,0, 0,0, 221,125.0002 L 125,125 Z',
  ],
  donutFirst: 'M 221,125 A 96,96,0, 0,0, 96.8891,33.208 L 107.4307,67.63 A 60,60,0, 0,1, 185,125 Z',
  donutActiveFirst:
    'M 231,125 A 106,106,0, 0,0, 93.9608,23.6463 L 107.4307,67.63 A 60,60,0, 0,1, 185,125 Z',
  stackedInnerFirst: 'M 185,125 A 60,60,0, 0,0, 154.7054,72.8695 L 125,125 Z',
  stackedOuterFirst:
    'M 215,125 A 90,90,0, 0,0, 193.944,67.1491 L 178.6231,80.0049 A 70,70,0, 0,1, 195,125 Z',
  labelLine: 'M182.085,47.816L193.977,31.736',
}

const ACTIVE_INDEX = 0
const grow = (index: number, outerRadius: number) =>
  index === ACTIVE_INDEX ? outerRadius + 10 : outerRadius

const ActiveShape: TOC<PieShapeSignature> = <template>
  <Sector @props={{@props}} @outerRadius={{grow @index @props.outerRadius}} />
</template>

const Total: TOC<LabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} text-anchor="middle" dominant-baseline="middle">
    <tspan x={{@viewBox.cx}} y={{@viewBox.cy}} data-test-total>925</tspan>
  </text>
</template>

const VisitorsLabel: TOC<PieLabelSignature> = <template>
  <text
    x={{@props.x}}
    y={{@props.y}}
    text-anchor={{@props.textAnchor}}
    fill="var(--foreground)"
    data-test-custom-label
  >{{@props.payload.visitors}}</text>
</template>

class LabelState {
  @tracked visitors = 186
}

const shown = (value: unknown) => String(value)

const VisitorsValue: TOC<LabelContentSignature> = <template>
  <text x={{@viewBox.cx}} y={{@viewBox.cy}} data-test-visitors>{{shown @value}}</text>
</template>

const browserLabel = (value: string) => chartConfig[value as keyof typeof chartConfig]?.label

module('Integration | components | chart | pie', function (hooks) {
  setupRenderingTest(hooks)

  test("a pie chart draws recharts' sectors, each in its row's fill", async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="pie" style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie @data={{chartData}} @dataKey="visitors" @nameKey="browser" />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness('pie')
    assert.true(chart.isPie)
    assert.strictEqual(chart.width, 250)
    assert.deepEqual(chart.plot, { x: 5, y: 5, width: 240, height: 240 }, 'a 5px margin')
    const pie = chart.seriesFor('visitors')
    assert.strictEqual(pie.type, 'pie')
    assert.dom(pie.element).hasClass('recharts-pie').hasClass('recharts-layer')
    const sectors = chart.sectors('visitors')
    assert.deepEqual(
      sectors.map(sector => flat(sector.getAttribute('d'))),
      RECHARTS.pie,
    )
    assert.deepEqual(chart.sectorNames('visitors'), [
      'chrome',
      'safari',
      'firefox',
      'edge',
      'other',
    ])
    assert.deepEqual(
      sectors.map(sector => sector.getAttribute('fill')),
      chartData.map(row => row.fill),
      "each row's fill",
    )
    assert.dom(sectors[0]).hasClass('recharts-sector').hasAttribute('stroke', '#fff')
    assert.dom(sectors[0]!.parentElement).hasClass('recharts-shape')
    assert.dom(sectors[0]!.parentElement!.parentElement).hasClass('recharts-pie-sector')
    assert.strictEqual(
      getComputedStyle(sectors[0]!).stroke,
      'rgba(0, 0, 0, 0)',
      "the chart's CSS makes the white stroke transparent",
    )
    assert.notStrictEqual(
      getComputedStyle(sectors[0]!).fill,
      'rgb(0, 0, 0)',
      "the config's colour reaches the sector through --color-chrome",
    )
    assert.deepEqual(
      pie.points.map(point => [Math.round(point.x), Math.round(point.y)]),
      [
        [154, 86],
        [85, 98],
        [89, 157],
        [142, 170],
        [171, 139],
      ],
      "each sector's middle, where the tooltip points",
    )
    await a11yAudit()
  })

  test('a donut, a label in its hole, and a shape that grows the first sector', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie
              @data={{chartData}}
              @dataKey="visitors"
              @nameKey="browser"
              @innerRadius={{60}}
              @strokeWidth={{5}}
              as |pie|
            >
              <pie.Label @content={{Total}} />
            </c.Pie>
          </chart.PieChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie
              @data={{chartData}}
              @dataKey="visitors"
              @nameKey="browser"
              @innerRadius={{60}}
              @strokeWidth={{5}}
              @shape={{ActiveShape}}
            />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const [donut, active] = ChartHarness.findAll()
    const [first] = donut!.sectors('visitors')
    assert.strictEqual(flat(first!.getAttribute('d')), RECHARTS.donutFirst, 'a ring')
    assert.dom(first).hasAttribute('stroke-width', '5')
    const total = donut!.element.querySelector('[data-test-total]')!
    assert.dom(total).hasText('925')
    assert.dom(total).hasAttribute('x', '125').hasAttribute('y', '125')
    assert.true(
      donut!.seriesFor('visitors').element.contains(total),
      'the label draws inside the pie, after its sectors',
    )
    const shapes = active!.sectors('visitors')
    assert.strictEqual(
      flat(shapes[0]!.getAttribute('d')),
      RECHARTS.donutActiveFirst,
      'the shape grows the first sector by 10px',
    )
    assert.strictEqual(
      flat(shapes[1]!.getAttribute('d')),
      flat(donut!.sectors('visitors')[1]!.getAttribute('d')),
    )
    assert
      .dom(shapes[0])
      .hasAttribute('fill', 'var(--color-chrome)')
      .hasAttribute('stroke-width', '5')
    await a11yAudit()
  })

  test('labels past the sectors, with lines, a custom label, and a label list', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} @name="labels" style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie @data={{chartData}} @dataKey="visitors" @label={{true}} @nameKey="browser" />
          </chart.PieChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="custom" style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie
              @data={{chartData}}
              @dataKey="visitors"
              @labelLine={{false}}
              @label={{VisitorsLabel}}
              @nameKey="browser"
            />
          </chart.PieChart>
        </ChartContainer>
        <ChartContainer @config={{chartConfig}} @name="list" style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie @data={{chartData}} @dataKey="visitors" as |pie|>
              <pie.LabelList
                @dataKey="browser"
                @class="fill-background"
                @stroke="none"
                @fontSize={{12}}
                @formatter={{browserLabel}}
              />
            </c.Pie>
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const labels = new ChartHarness('labels')
    assert.deepEqual(labels.labels('visitors'), ['275', '200', '187', '173', '90'])
    const [chrome] = labels.labelLines('visitors')
    assert.strictEqual(chrome!.getAttribute('d'), RECHARTS.labelLine, "recharts' label line")
    assert
      .dom(chrome)
      .hasClass('recharts-pie-label-line')
      .hasAttribute('stroke', 'var(--color-chrome)')
    const texts = labels.surface.querySelectorAll('.recharts-pie-label-text')
    assert.strictEqual(Number(texts[0]!.getAttribute('x')).toFixed(3), '193.977')
    assert.strictEqual(Number(texts[0]!.getAttribute('y')).toFixed(3), '31.736')
    assert
      .dom(texts[0])
      .hasAttribute('text-anchor', 'start')
      .hasAttribute('fill', 'var(--color-chrome)')
    assert.dom(texts[1]).hasAttribute('text-anchor', 'end', 'anchored away from the centre')

    const custom = new ChartHarness('custom')
    assert.strictEqual(custom.labelLines('visitors').length, 0, '@labelLine={{false}}')
    const customLabels = custom.element.querySelectorAll('[data-test-custom-label]')
    assert.deepEqual(
      Array.from(customLabels, label => label.textContent),
      ['275', '200', '187', '173', '90'],
      'the component draws each label from its row',
    )
    assert.dom(customLabels[0]).hasAttribute('x', texts[0]!.getAttribute('x')!)

    const list = new ChartHarness('list')
    assert.deepEqual(list.labels('visitors'), ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'])
    const [first] = list.surface.querySelectorAll('.recharts-label-list text')
    assert.dom(first).hasClass('recharts-text').hasClass('fill-background')
    assert.dom(first).hasAttribute('stroke', 'none').hasAttribute('font-size', '12')
    assert.strictEqual(Number(first!.getAttribute('x')).toFixed(3), '153.542', 'the ring’s middle')
    assert.strictEqual(Number(first!.getAttribute('y')).toFixed(3), '86.408')
    assert.dom(first!.querySelector('tspan')).hasAttribute('dy', '0.355em')
    assert.deepEqual(list.sectorNames('visitors'), ['0', '1', '2', '3', '4'], 'no nameKey')
    await a11yAudit()
  })

  test('the tooltip shows the sector under the pointer, beside its middle', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.ChartTooltip
              @cursor={{false}}
              @content={{component ChartTooltipContent hideLabel=true}}
            />
            <c.Pie @data={{chartData}} @dataKey="visitors" @nameKey="browser" />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.false(chart.isTooltipVisible)
    await chart.hover(0)
    assert.true(chart.isTooltipVisible)
    assert.deepEqual(chart.tooltip!.names, ['Chrome'])
    assert.deepEqual(chart.tooltip!.entryValues, ['275'])
    assert.strictEqual(chart.tooltip!.label, null, 'hideLabel')
    const [chrome] = chart.sectors('visitors')
    assert.dom(chrome!.parentElement).hasClass('recharts-active-shape', 'the sector is active')
    const box = chart.wrapper.querySelector<HTMLElement>('.recharts-tooltip-wrapper')!
    // recharts puts it 10px beside the sector's middle (153.54, 86.41): to its left, here, as it
    // wouldn't fit to its right.
    const position = chart.tooltipPosition!
    assert.strictEqual(Math.round((position.x + box.offsetWidth + 10) * 100) / 100, 153.54)
    assert.strictEqual(Math.round(position.y * 100) / 100, 96.41)
    await chart.hover(3)
    assert.deepEqual(chart.tooltip!.names, ['Edge'])
    const indicator = chart.tooltip!.items[0]!.indicator!
    assert.true(
      indicator.getAttribute('style')!.includes('var(--color-edge)'),
      "the indicator takes the sector's fill",
    )
    await chart.unhover()
    assert.false(chart.isTooltipVisible)
    assert.dom(chrome!.parentElement).hasClass('recharts-shape')
    await a11yAudit()
  })

  test('the keyboard steps through the sectors (the accessibility layer)', async function (assert) {
    const desktop = [
      { month: 'january', desktop: 186, fill: 'var(--color-january)' },
      { month: 'february', desktop: 305, fill: 'var(--color-february)' },
    ]
    const mobile = [
      { month: 'january', mobile: 80, fill: 'var(--color-january)' },
      { month: 'february', mobile: 200, fill: 'var(--color-february)' },
    ]
    const config = {
      january: { label: 'January', color: 'var(--chart-1)' },
      february: { label: 'February', color: 'var(--chart-2)' },
    } satisfies ChartConfig
    await render(
      <template>
        <ChartContainer @config={{config}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.ChartTooltip
              @content={{component ChartTooltipContent nameKey="month" hideLabel=true}}
            />
            <c.Pie @data={{desktop}} @dataKey="desktop" @outerRadius={{60}} />
            <c.Pie @data={{mobile}} @dataKey="mobile" @innerRadius={{70}} @outerRadius={{90}} />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.dom(chart.surface).hasAttribute('role', 'application').hasAttribute('tabindex', '0')
    await chart.focus()
    assert.deepEqual(chart.tooltip!.names, ['January'], 'focus shows the first sector')
    assert.deepEqual(chart.tooltip!.entryValues, ['186'])
    await chart.press('ArrowRight')
    assert.deepEqual(chart.tooltip!.entryValues, ['305'])
    await chart.press('ArrowRight')
    assert.deepEqual(chart.tooltip!.entryValues, ['80'], "on to the next pie's first sector")
    await chart.press('ArrowRight')
    await chart.press('ArrowRight')
    assert.deepEqual(chart.tooltip!.entryValues, ['200'], 'stops at the last sector')
    await chart.press('ArrowLeft')
    assert.deepEqual(chart.tooltip!.entryValues, ['80'])
    await chart.press('Enter')
    assert.false(chart.isTooltipVisible, 'Enter hides it')
    await chart.press('Enter')
    assert.true(chart.isTooltipVisible, 'and shows it again')
    await chart.blur()
    assert.false(chart.isTooltipVisible, 'leaving the chart hides it')
    await chart.hover(1, 'mobile')
    assert.deepEqual(
      chart.tooltip!.entryValues,
      ['200'],
      "the pointer finds the outer pie's sector",
    )
    await a11yAudit()
  })

  test('stacked pies, as recharts lays them out', async function (assert) {
    const desktop = [
      { month: 'january', desktop: 186 },
      { month: 'february', desktop: 305 },
      { month: 'march', desktop: 237 },
      { month: 'april', desktop: 173 },
      { month: 'may', desktop: 209 },
    ]
    const mobile = [
      { month: 'january', mobile: 80 },
      { month: 'february', mobile: 200 },
      { month: 'march', mobile: 120 },
      { month: 'april', mobile: 190 },
      { month: 'may', mobile: 130 },
    ]
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie @data={{desktop}} @dataKey="desktop" @outerRadius={{60}} />
            <c.Pie @data={{mobile}} @dataKey="mobile" @innerRadius={{70}} @outerRadius={{90}} />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(
      chart.series.map(series => series.key),
      ['desktop', 'mobile'],
    )
    assert.strictEqual(
      flat(chart.sectors('desktop')[0]!.getAttribute('d')),
      RECHARTS.stackedInnerFirst,
    )
    assert.strictEqual(
      flat(chart.sectors('mobile')[0]!.getAttribute('d')),
      RECHARTS.stackedOuterFirst,
    )
    assert.dom(chart.sectors('mobile')[0]).hasAttribute('fill', '#808080', "the pie's default fill")
    await a11yAudit()
  })

  test('a legend names each sector, and takes its height from the pie', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style="width: 300px; height: 300px" as |chart|>
          <chart.PieChart as |c|>
            <c.Pie @data={{chartData}} @dataKey="visitors" />
            <c.ChartLegend
              @content={{component ChartLegendContent nameKey="browser"}}
              @class="-translate-y-2 flex-wrap gap-2"
            />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const legend = chart.legend!
    assert.deepEqual(
      legend.labels,
      ['Chrome', 'Safari', 'Firefox', 'Edge', 'Other'],
      "each row, by its browser's config label, in the rows' order (their names are all the data key)",
    )
    assert.true(
      legend.items[0]!.swatch!.getAttribute('style')!.includes('var(--color-chrome)'),
      "each swatch in its row's fill",
    )
    assert.dom(legend.element).hasClass('flex-wrap', "the legend's @class reaches its content")
    const legendHeight = chart.wrapper.querySelector<HTMLElement>(
      '.recharts-legend-wrapper',
    )!.offsetHeight
    assert.true(legendHeight > 0)
    assert.strictEqual(chart.plot.height, 290 - legendHeight, 'the legend takes its height')
    await a11yAudit()
  })

  test('a Cell gives a sector its fill', async function (assert) {
    const rows = [
      { name: 'a', value: 1 },
      { name: 'b', value: 3 },
    ]
    const fills = ['red', 'blue']
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart @data={{rows}} as |c|>
            <c.ChartTooltip
              @defaultIndex={{0}}
              @content={{component ChartTooltipContent hideLabel=true}}
            />
            <c.ChartLegend />
            <c.Pie as |pie|>
              {{#each fills as |fill|}}
                <pie.Cell @fill={{fill}} />
              {{/each}}
              <pie.Label @value="Total" @position="center" @class="fill-foreground" />
            </c.Pie>
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.deepEqual(
      chart.sectors('value').map(sector => sector.getAttribute('fill')),
      ['red', 'blue'],
      "recharts' defaults: the value key `value`, the name key `name`",
    )
    assert.deepEqual(chart.sectorNames('value'), ['a', 'b'], "the chart's @data")
    assert.true(chart.legend!.items[0]!.swatch!.getAttribute('style')!.includes('red'))
    assert.deepEqual(chart.tooltip!.entryValues, ['1'], '@defaultIndex shows the first sector')
    const total = chart.surface.querySelector('text.fill-foreground')!
    assert
      .dom(total)
      .hasText('Total')
      .hasClass('fill-foreground')
      .hasAttribute('text-anchor', 'middle')
    assert.strictEqual(
      Number(total.getAttribute('x')),
      chart.width / 2,
      "a Label's @value, centred",
    )
    await chart.hover(1)
    assert.true(chart.tooltip!.items[0]!.indicator!.getAttribute('style')!.includes('blue'))
    await a11yAudit()
  })

  test('a Label follows its @value, drawn by @content or as text', async function (assert) {
    const state = new LabelState()
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart as |c|>
            <c.Pie
              @data={{chartData}}
              @dataKey="visitors"
              @nameKey="browser"
              @innerRadius={{60}}
              as |pie|
            >
              <pie.Label @value={{state.visitors}} @content={{VisitorsValue}} />
              <pie.Label @value={{state.visitors}} @class="fill-foreground" />
            </c.Pie>
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    const drawn = () => chart.surface.querySelector('[data-test-visitors]')
    const text = () => chart.surface.querySelector('text.fill-foreground')
    assert.dom(drawn()).hasText('186')
    assert.dom(text()).hasText('186')

    state.visitors = 237
    await rerender()
    assert.dom(drawn()).hasText('237', "the content is handed the label's new @value")
    assert.dom(text()).hasText('237', 'the text shows it')
    await a11yAudit()
  })

  test('a pie draws the same right to left; its tooltip and legend take the direction (RTL)', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div dir="rtl">
            <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
              <chart.PieChart as |c|>
                <c.ChartTooltip @content={{component ChartTooltipContent hideLabel=true}} />
                <c.ChartLegend @content={{component ChartLegendContent nameKey="browser"}} />
                <c.Pie @data={{chartData}} @dataKey="visitors" @nameKey="browser" />
              </chart.PieChart>
            </ChartContainer>
          </div>
        </DirectionProvider>
      </template>,
    )
    const chart = new ChartHarness()
    const [chrome] = chart.sectors('visitors')
    assert.true(
      flat(chrome!.getAttribute('d')).startsWith('M '),
      'sectors still run counter-clockwise from 3 o’clock, as in recharts',
    )
    const items = chart.legend!.items
    assert.true(
      items[0]!.swatch!.getBoundingClientRect().left >
        items[1]!.swatch!.getBoundingClientRect().left,
      'the legend reads right to left',
    )
    await chart.hover(0)
    assert.deepEqual(chart.tooltip!.names, ['Chrome'])
    await a11yAudit()
  })

  test('without the accessibility layer the chart takes no focus', async function (assert) {
    await render(
      <template>
        <ChartContainer @config={{chartConfig}} style={{size}} as |chart|>
          <chart.PieChart @accessibilityLayer={{false}} as |c|>
            <c.Pie @data={{chartData}} @dataKey="visitors" />
          </chart.PieChart>
        </ChartContainer>
      </template>,
    )
    const chart = new ChartHarness()
    assert.dom(chart.surface).doesNotHaveAttribute('role').doesNotHaveAttribute('tabindex')
    await a11yAudit()
  })
})
