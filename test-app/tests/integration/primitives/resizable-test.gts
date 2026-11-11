import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, render, rerender, settled } from '@ember/test-helpers'
import { on } from '@ember/modifier'
import { array, fn, hash } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Resizable,
  ResizableHandle,
  ResizablePanel,
  adjustLayout,
  validateLayout,
  type PanelConstraints,
  type ResizableLayoutMap,
  type ResizableLayoutMeta,
} from '@ember-joinery/primitives/resizable'
import { ResizableHarness, pressKey } from '@ember-joinery/test-support'

/** The group's size in the tests: 400 by 200 pixels, with 0-width handles. */
const GROUP = 'width: 400px; height: 200px'

function constraints(...partial: Partial<PanelConstraints>[]): PanelConstraints[] {
  return partial.map(p => ({
    minSize: 0,
    maxSize: 100,
    collapsible: false,
    collapsedSize: 0,
    disabled: false,
    ...p,
  }))
}

module('Integration | primitives | resizable', function (hooks) {
  setupRenderingTest(hooks)

  test('panels share the group, and each handle is a window splitter for the panel before it', async function (assert) {
    await render(
      <template>
        <Resizable @name="layout" style={{GROUP}} as |r|>
          <r.Panel @id="sidebar" @defaultSize="25%">Sidebar</r.Panel>
          <r.Handle aria-label="Resize the sidebar" />
          <r.Panel @id="content">Content</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness('layout')

    assert.strictEqual(layout.orientation, 'horizontal')
    assert.dom(layout.element).hasAttribute('data-slot', 'resizable')
    assert.strictEqual(getComputedStyle(layout.element).display, 'flex')
    assert.strictEqual(getComputedStyle(layout.element).flexDirection, 'row')
    assert.deepEqual(layout.sizes, [25, 75], 'the panel without a size takes the rest')

    const handle = layout.handle(0)
    assert
      .dom(handle)
      .hasAttribute('role', 'separator')
      .hasAttribute('tabindex', '0')
      .hasAttribute('aria-orientation', 'vertical', 'a splitter between side-by-side panes')
      .hasAttribute('aria-valuenow', '25')
      .hasAttribute('aria-valuemin', '0')
      .hasAttribute('aria-valuemax', '100')
      .hasAttribute('data-separator', 'inactive')
    assert.strictEqual(layout.controls(0), layout.panel('sidebar'), 'aria-controls')
    assert.dom(layout.panel('sidebar')).hasAttribute('id', 'sidebar').hasAttribute('data-panel')
    await a11yAudit()
  })

  test('without sizes the panels share equally, and stacked panels resize with Up and Down', async function (assert) {
    await render(
      <template>
        <Resizable @orientation="vertical" style={{GROUP}} as |r|>
          <r.Panel>One</r.Panel>
          <r.Handle aria-label="Resize one" />
          <r.Panel>Two</r.Panel>
          <r.Handle aria-label="Resize two" />
          <r.Panel>Three</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.strictEqual(layout.orientation, 'vertical')
    assert.strictEqual(getComputedStyle(layout.element).flexDirection, 'column')
    assert.dom(layout.handle(0)).hasAttribute('aria-orientation', 'horizontal')
    assert.deepEqual(layout.sizes, [33.3, 33.3, 33.3])

    assert.true(await layout.press(0, 'ArrowDown'), 'the key is used')
    assert.deepEqual(layout.sizes, [38.3, 28.3, 33.3])
    assert.strictEqual(Math.round(layout.valueNow(0)), 38, 'aria-valuenow follows')
    await layout.press(0, 'ArrowUp')
    await layout.press(0, 'ArrowUp')
    assert.deepEqual(layout.sizes, [28.3, 38.3, 33.3])
    await layout.press(0, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [28.3, 38.3, 33.3], 'Left and Right do nothing here')
    await a11yAudit()
  })

  test('the keyboard: arrows move by 5%, Shift by 10%, Home and End to the limits', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @defaultSize="50%" @minSize="20%" @maxSize="70%">A</r.Panel>
          <r.Handle aria-label="Resize A" />
          <r.Panel>B</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.deepEqual(layout.range(0), { min: 20, max: 70 })

    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [55, 45])
    await layout.press(0, 'ArrowLeft', { shiftKey: true })
    assert.deepEqual(layout.sizes, [45, 55])
    await layout.press(0, 'End')
    assert.deepEqual(layout.sizes, [70, 30], 'End: the most the panel can take')
    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [70, 30], 'no further than its maximum')
    await layout.press(0, 'Home')
    assert.deepEqual(layout.sizes, [20, 80], 'Home: its minimum')
    assert.strictEqual(layout.handleState(0), 'focus')
    await a11yAudit()
  })

  test('a drag resizes the panels either side, within their limits', async function (assert) {
    const changes: number[][] = []
    const changed: [number[], ResizableLayoutMap, ResizableLayoutMeta][] = []
    const onChange = (sizes: number[]) => changes.push(sizes)
    const onChanged = (sizes: number[], map: ResizableLayoutMap, meta: ResizableLayoutMeta) =>
      changed.push([sizes, map, meta])
    await render(
      <template>
        <Resizable
          style={{GROUP}}
          @onLayoutChange={{onChange}}
          @onLayoutChanged={{onChanged}}
          as |r|
        >
          <r.Panel @id="left" @minSize="25%">Left</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel @id="right" @minSize="100px">Right</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.deepEqual(changes, [[50, 50]], 'the first layout is told')
    assert.deepEqual(changed, [[[50, 50], { left: 50, right: 50 }, { isUserInteraction: false }]])

    await layout.drag(0, 40)
    assert.deepEqual(layout.sizes, [60, 40], '40px of 400 is 10%')
    assert.strictEqual(changes.length, 5, 'told on every move')
    assert.strictEqual(changed.length, 2, 'and once when it is over')
    assert.deepEqual(changed[1], [[60, 40], { left: 60, right: 40 }, { isUserInteraction: true }])

    await layout.drag(0, 200)
    assert.deepEqual(layout.sizes, [75, 25], 'the right panel keeps its 100px')
    await layout.drag(0, -400)
    assert.deepEqual(layout.sizes, [25, 75], 'the left keeps its 25%')
    await a11yAudit()
  })

  test('the handle shows its state: hover, dragging, focus', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel>A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    await layout.hover(0)
    assert.strictEqual(layout.handleState(0), 'hover')
    assert.strictEqual(getComputedStyle(layout.handle(0)).cursor, 'col-resize')
    await layout.hover(0, false)
    assert.strictEqual(layout.handleState(0), 'inactive')
    await layout.focus(0)
    assert.strictEqual(layout.handleState(0), 'focus')
    await a11yAudit()
  })

  test('a collapsible panel snaps closed past its threshold, and Enter toggles it', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @id="nav" @defaultSize="30%" @minSize="20%" @collapsible={{true}} as |panel|>
            <span data-test-collapsed>{{if panel.isCollapsed "collapsed" "open"}}</span>
          </r.Panel>
          <r.Handle aria-label="Resize the navigation" />
          <r.Panel>Content</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.false(layout.isCollapsed('nav'))
    assert.deepEqual(layout.range(0), { min: 0, max: 100 }, 'it can collapse to 0')

    await layout.drag(0, -60)
    assert.deepEqual(layout.sizes, [20, 80], 'held at its minimum, short of the threshold (10%)')
    await layout.drag(0, -24)
    assert.deepEqual(layout.sizes, [20, 80], 'still short: 6% past its minimum')
    await layout.drag(0, -44)
    assert.deepEqual(layout.sizes, [0, 100], 'past it: collapsed')
    assert.true(layout.isCollapsed('nav'))
    assert.dom('[data-test-collapsed]').hasText('collapsed', 'the panel yields its state')

    await layout.press(0, 'Enter')
    assert.deepEqual(layout.sizes, [20, 80], 'Enter expands it to the size it had')
    await layout.press(0, 'Enter')
    assert.deepEqual(layout.sizes, [0, 100], 'and collapses it again')
    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [20, 80], 'an arrow opens it to its minimum in one step')
    await layout.press(0, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [0, 100], 'and closes it in one step from there')
    await a11yAudit()
  })

  test('right to left, the first panel is on the right, and Left and a drag left grow it', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Resizable style={{GROUP}} as |r|>
            <r.Panel @id="first">First</r.Panel>
            <r.Handle aria-label="Resize" />
            <r.Panel @id="second">Second</r.Panel>
          </Resizable>
        </DirectionProvider>
      </template>,
    )
    const layout = new ResizableHarness()
    const first = layout.panel('first').getBoundingClientRect()
    const second = layout.panel('second').getBoundingClientRect()
    assert.true(first.left > second.left, 'the first panel is on the right')

    await layout.press(0, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [55, 45], 'Left moves the handle left: the first panel grows')
    await layout.press(0, 'ArrowRight')
    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [45, 55])
    await layout.drag(0, -40)
    assert.deepEqual(layout.sizes, [55, 45], 'a drag left grows it too')
    await a11yAudit()
  })

  test('@dir overrides the document direction', async function (assert) {
    await render(
      <template>
        <Resizable @dir="rtl" style={{GROUP}} as |r|>
          <r.Panel>A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    await layout.press(0, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [55, 45])
    await a11yAudit()
  })

  test('sizes take units: pixels, rem and percent', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @defaultSize={{100}}>100px</r.Panel>
          <r.Handle aria-label="Resize one" />
          <r.Panel @defaultSize="5rem">5rem</r.Panel>
          <r.Handle aria-label="Resize two" />
          <r.Panel @minSize="60">At least 60%</r.Panel>
        </Resizable>
        <Resizable @name="all" style={{GROUP}} as |r|>
          <r.Panel @defaultSize="30">30</r.Panel>
          <r.Handle aria-label="Resize three" />
          <r.Panel @defaultSize="45%">45%</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.deepEqual(layout.sizes, [20, 20, 60], "100px gives way to the last panel's 60%")
    assert.deepEqual(
      new ResizableHarness('all').sizes,
      [40, 60],
      'sizes that leave space over grow to fill it, in proportion',
    )
    await a11yAudit()
  })

  test('@defaultLayout, by order or by id, and setLayout()', async function (assert) {
    await render(
      <template>
        <Resizable @defaultLayout={{array 20 80}} style={{GROUP}} as |r|>
          <r.Panel>A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
          <button type="button" {{on "click" (fn r.setLayout (array 60 40))}}>Set</button>
          <output>{{join r.layout}}</output>
        </Resizable>
        <Resizable @name="by-id" @defaultLayout={{hash b=70 a=30}} style={{GROUP}} as |r|>
          <r.Panel @id="a">A</r.Panel>
          <r.Handle aria-label="Resize by id" />
          <r.Panel @id="b">B</r.Panel>
        </Resizable>
      </template>,
    )
    assert.deepEqual(new ResizableHarness().sizes, [20, 80])
    assert.deepEqual(new ResizableHarness('by-id').sizes, [30, 70])
    assert.dom('output').hasText('20,80', 'the layout is yielded, and tracked')
    await click('button')
    assert.deepEqual(new ResizableHarness().sizes, [60, 40])
    assert.dom('output').hasText('60,40')
    await a11yAudit()
  })

  test("a panel's API resizes, collapses and expands it", async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @collapsible={{true}} @minSize="10%" as |panel|>
            <button type="button" data-resize {{on "click" (fn panel.resize "40%")}}>40%</button>
            <button type="button" data-collapse {{on "click" panel.collapse}}>Collapse</button>
            <button type="button" data-expand {{on "click" panel.expand}}>Expand</button>
            <output>{{panel.size}}</output>
          </r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.dom('output').hasText('50')
    await click('[data-resize]')
    assert.deepEqual(layout.sizes, [40, 60])
    assert.dom('output').hasText('40', 'the size is tracked')
    await click('[data-collapse]')
    assert.deepEqual(layout.sizes, [0, 100])
    assert.true(layout.isCollapsed(0))
    await click('[data-expand]')
    assert.deepEqual(layout.sizes, [40, 60], 'back to the size it had')
    await a11yAudit()
  })

  test('a double-click puts a panel back to its default size', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @defaultSize="30%">A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
          <r.Handle aria-label="Resize again" @disableDoubleClick={{true}} />
          <r.Panel @defaultSize="20%">C</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.deepEqual(layout.sizes, [30, 50, 20])
    await layout.press(0, 'ArrowRight')
    await layout.press(1, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [35, 40, 25])
    await layout.doubleClick(0)
    assert.deepEqual(layout.sizes, [30, 45, 25])
    await layout.doubleClick(1)
    assert.deepEqual(layout.sizes, [30, 45, 25], '@disableDoubleClick')
    await a11yAudit()
  })

  test('F6 moves focus to the next handle, and Shift+F6 back', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel>A</r.Panel>
          <r.Handle aria-label="One" />
          <r.Panel>B</r.Panel>
          <r.Handle aria-label="Two" />
          <r.Panel>C</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    await layout.focus(0)
    await pressKey('F6')
    assert.dom(layout.handle(1)).isFocused()
    await pressKey('F6')
    assert.dom(layout.handle(0)).isFocused('it wraps')
    await pressKey('F6', { shiftKey: true })
    assert.dom(layout.handle(1)).isFocused()
    await a11yAudit()
  })

  test('a disabled group or handle leaves the tab order and ignores keys and drags', async function (assert) {
    class State {
      @tracked disabled = true
    }
    const state = new State()
    await render(
      <template>
        <Resizable @disabled={{state.disabled}} style={{GROUP}} as |r|>
          <r.Panel>A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
          <r.Handle aria-label="Resize again" @disabled={{true}} />
          <r.Panel @disabled={{true}}>C</r.Panel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.true(layout.isHandleDisabled(0))
    assert
      .dom(layout.handle(0))
      .doesNotHaveAttribute('tabindex')
      .hasAttribute('data-separator', 'disabled')
    await layout.drag(0, 40)
    assert.deepEqual(layout.sizes, [33.3, 33.3, 33.3])

    state.disabled = false
    await rerender()
    await settled()
    assert.false(layout.isHandleDisabled(0))
    assert.dom(layout.handle(0)).hasAttribute('tabindex', '0')
    assert.true(layout.isHandleDisabled(1), 'a handle of its own')
    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [38.3, 28.3, 33.3])
    assert.dom(layout.panel(2)).hasAttribute('data-disabled')
    await layout.press(0, 'End')
    assert.deepEqual(layout.sizes, [66.7, 0, 33.3], 'the disabled panel keeps its size')
    await a11yAudit()
  })

  test('a panel that comes later takes its size, and the others make room; one that goes gives its space back', async function (assert) {
    class State {
      @tracked showRight = false
    }
    const state = new State()
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @id="left" @defaultSize="30%">Left</r.Panel>
          <r.Handle aria-label="Resize left" />
          <r.Panel @id="main">Main</r.Panel>
          {{#if state.showRight}}
            <r.Handle aria-label="Resize right" />
            <r.Panel @id="right" @defaultSize="20%">Right</r.Panel>
          {{/if}}
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.deepEqual(layout.sizes, [30, 70])
    state.showRight = true
    await settled()
    assert.strictEqual(layout.panels.length, 3)
    assert.deepEqual(layout.sizes, [25, 58.3, 16.7], 'scaled to fit the new one in')
    state.showRight = false
    await settled()
    assert.deepEqual(layout.sizes, [30, 70])
    await a11yAudit()
  })

  test('a panel can hold a group of its own, and each group has its own panels', async function (assert) {
    await render(
      <template>
        <Resizable @name="outer" style={{GROUP}} as |outer|>
          <outer.Panel>One</outer.Panel>
          <outer.Handle aria-label="Resize one" />
          <outer.Panel>
            <Resizable @name="inner" @orientation="vertical" style="height: 100%" as |inner|>
              <inner.Panel @defaultSize="25%">Two</inner.Panel>
              <inner.Handle aria-label="Resize two" />
              <inner.Panel>Three</inner.Panel>
            </Resizable>
          </outer.Panel>
        </Resizable>
      </template>,
    )
    const outer = new ResizableHarness('outer')
    const inner = new ResizableHarness('inner')
    assert.strictEqual(outer.panels.length, 2)
    assert.strictEqual(outer.handles.length, 1)
    assert.strictEqual(inner.panels.length, 2)
    assert.deepEqual(inner.sizes, [25, 75])
    await inner.press(0, 'ArrowDown')
    assert.deepEqual(inner.sizes, [30, 70])
    assert.deepEqual(outer.sizes, [50, 50], 'the outer group is left alone')
    await a11yAudit()
  })

  test('@onResize tells each panel its size, in percent and pixels', async function (assert) {
    const sizes: [number, number, string][] = []
    const onResize = (size: { asPercentage: number; inPixels: number }, id: string) =>
      sizes.push([size.asPercentage, size.inPixels, id])
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <r.Panel @id="a" @onResize={{onResize}}>A</r.Panel>
          <r.Handle aria-label="Resize" />
          <r.Panel>B</r.Panel>
        </Resizable>
      </template>,
    )
    assert.deepEqual(sizes, [[50, 200, 'a']])
    await new ResizableHarness().press(0, 'ArrowRight')
    assert.deepEqual(sizes[1], [55, 220, 'a'])
    await a11yAudit()
  })

  test('the parts come as modifiers for elements of your own, and as components on their own', async function (assert) {
    await render(
      <template>
        <Resizable style={{GROUP}} as |r|>
          <section {{r.panel defaultSize="40%" id="own"}} aria-label="Own panel">Own</section>
          <div {{r.handle}} aria-label="Resize"></div>
          <ResizablePanel @id="imported">Imported</ResizablePanel>
          <ResizableHandle aria-label="Resize again" />
          <ResizablePanel>Last</ResizablePanel>
        </Resizable>
      </template>,
    )
    const layout = new ResizableHarness()
    assert.strictEqual(layout.panels.length, 3)
    assert.dom(layout.panel('own')).hasTagName('section')
    assert.dom(layout.handle(0)).hasAttribute('role', 'separator').hasAttribute('tabindex', '0')
    assert.deepEqual(layout.sizes, [40, 30, 30])
    await layout.press(1, 'ArrowRight')
    assert.deepEqual(layout.sizes, [40, 35, 25])
    await a11yAudit()
  })

  test('adjustLayout and validateLayout, the layout math', function (assert) {
    const c = constraints({ minSize: 10 }, {}, { minSize: 20 })
    assert.deepEqual(
      adjustLayout({
        delta: 30,
        initial: [30, 30, 40],
        previous: [30, 30, 40],
        constraints: c,
        pivot: [0, 1],
        trigger: 'pointer',
      }),
      [60, 0, 40],
    )
    assert.deepEqual(
      adjustLayout({
        delta: 50,
        initial: [30, 30, 40],
        previous: [30, 30, 40],
        constraints: c,
        pivot: [0, 1],
        trigger: 'pointer',
      }),
      [80, 0, 20],
      'the shrinking side gives up space beyond the nearest panel, down to its minimum',
    )
    assert.deepEqual(validateLayout([1, 1, 2], c), [25, 25, 50], 'scaled to 100')
    assert.deepEqual(validateLayout([5, 75, 20], c), [10, 70, 20], 'minimums hold')
  })
})

/** `{{join list}}`: the items with commas. */
function join(list: readonly number[]): string {
  return list.join(',')
}
