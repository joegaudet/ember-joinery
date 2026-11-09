import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ResizableHandle, ResizablePanel, ResizablePanelGroup } from '@ember-joinery/ember'
import { ResizableHarness } from '@ember-joinery/test-support'

const GROUP = 'width: 400px; height: 200px'

module('Integration | components | resizable', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's slots and classes on Joinery's resizable group", async function (assert) {
    await render(
      <template>
        <ResizablePanelGroup @name="layout" @orientation="horizontal" style={{GROUP}}>
          <ResizablePanel @defaultSize="50%">One</ResizablePanel>
          <ResizableHandle @withHandle={{true}} aria-label="Resize one" />
          <ResizablePanel @defaultSize="50%">Two</ResizablePanel>
        </ResizablePanelGroup>
      </template>,
    )
    const layout = new ResizableHarness('layout')
    assert
      .dom(layout.element)
      .hasClass('jn-resizable-panel-group')
      .hasAttribute('data-slot', 'resizable-panel-group')
      .hasAttribute('data-orientation', 'horizontal')
    for (const panel of layout.panels)
      assert.dom(panel).hasAttribute('data-slot', 'resizable-panel')
    const handle = layout.handle(0)
    assert
      .dom(handle)
      .hasClass('jn-resizable-handle')
      .hasAttribute('data-slot', 'resizable-handle')
      .hasAttribute('role', 'separator')
      .hasAttribute('aria-orientation', 'vertical')
    assert.dom('.jn-resizable-handle-icon', handle).exists('@withHandle draws the grip')
    assert.deepEqual(layout.sizes, [50, 50])
    await a11yAudit()
  })

  test('its style sheet draws the handle: a 1px line, and a grip across it', async function (assert) {
    await render(
      <template>
        <ResizablePanelGroup @name="across" style={{GROUP}}>
          <ResizablePanel>One</ResizablePanel>
          <ResizableHandle @withHandle={{true}} aria-label="Resize" />
          <ResizablePanel>Two</ResizablePanel>
        </ResizablePanelGroup>
        <ResizablePanelGroup @name="stacked" @orientation="vertical" style={{GROUP}}>
          <ResizablePanel>One</ResizablePanel>
          <ResizableHandle @withHandle={{true}} aria-label="Resize stacked" />
          <ResizablePanel>Two</ResizablePanel>
        </ResizablePanelGroup>
        <ResizablePanelGroup @name="plain" style={{GROUP}}>
          <ResizablePanel>One</ResizablePanel>
          <ResizableHandle aria-label="Resize plain" />
          <ResizablePanel>Two</ResizablePanel>
        </ResizablePanelGroup>
      </template>,
    )
    const across = new ResizableHarness('across')
    const handle = getComputedStyle(across.handle(0))
    assert.strictEqual(handle.width, '1px', 'w-px')
    assert.strictEqual(handle.height, '200px', 'the height of the group')
    assert.strictEqual(handle.display, 'flex')
    assert.strictEqual(handle.position, 'relative')
    assert.notStrictEqual(handle.backgroundColor, 'rgba(0, 0, 0, 0)', 'bg-border')
    const grip = getComputedStyle(across.handle(0).querySelector('.jn-resizable-handle-icon')!)
    assert.strictEqual(grip.height, '24px', 'h-6')
    assert.strictEqual(grip.width, '4px', 'w-1')
    assert.strictEqual(grip.zIndex, '10')
    assert.strictEqual(grip.backgroundColor, handle.backgroundColor, 'bg-border')
    const hit = getComputedStyle(across.handle(0), '::after')
    assert.strictEqual(hit.width, '4px', 'a wider hit area: after:w-1')
    assert.strictEqual(hit.position, 'absolute')

    const stacked = new ResizableHarness('stacked')
    const line = getComputedStyle(stacked.handle(0))
    assert.strictEqual(line.height, '1px', 'stacked, the line runs across: h-px')
    assert.strictEqual(line.width, '400px', 'w-full')
    const turned = getComputedStyle(stacked.handle(0).querySelector('.jn-resizable-handle-icon')!)
    assert.notStrictEqual(turned.rotate, 'none', 'and the grip turns: rotate-90')
    assert.strictEqual(getComputedStyle(stacked.handle(0), '::after').height, '4px', 'after:h-1')

    assert.dom('.jn-resizable-handle-icon', new ResizableHarness('plain').handle(0)).doesNotExist()
    await a11yAudit()
  })

  test('it resizes from the keyboard and the pointer, and a focused handle shows a ring', async function (assert) {
    await render(
      <template>
        <ResizablePanelGroup style={{GROUP}}>
          <ResizablePanel @defaultSize="25%" @minSize="10%">Sidebar</ResizablePanel>
          <ResizableHandle @withHandle={{true}} aria-label="Resize the sidebar" />
          <ResizablePanel @defaultSize="75%">Content</ResizablePanel>
        </ResizablePanelGroup>
      </template>,
    )
    const layout = new ResizableHarness()
    await layout.press(0, 'ArrowRight')
    assert.deepEqual(layout.sizes, [30, 70])
    await layout.press(0, 'Home')
    assert.deepEqual(layout.sizes, [10, 90])
    await layout.drag(0, 80)
    assert.deepEqual(layout.sizes.map(Math.round), [30, 70], '80px of the 399 the panels share')
    await layout.focus(0)
    assert.dom(layout.handle(0)).matchesSelector(':focus-visible, :focus')
    await a11yAudit()
  })

  test('right to left, the first panel is on the right and the arrows follow', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <ResizablePanelGroup style={{GROUP}}>
            <ResizablePanel @defaultSize="50%">واحد</ResizablePanel>
            <ResizableHandle @withHandle={{true}} aria-label="تغيير الحجم" />
            <ResizablePanel @defaultSize="50%">اثنان</ResizablePanel>
          </ResizablePanelGroup>
        </DirectionProvider>
      </template>,
    )
    const layout = new ResizableHarness()
    const [first, second] = layout.panels
    assert.true(first!.offsetLeft > second!.offsetLeft, 'the first panel is on the right')
    await layout.press(0, 'ArrowLeft')
    assert.deepEqual(layout.sizes, [55, 45])
    await a11yAudit()
  })

  test('the group yields its parts and its layout', async function (assert) {
    await render(
      <template>
        <ResizablePanelGroup style={{GROUP}} as |g|>
          <g.Panel @id="a">A</g.Panel>
          <g.Handle aria-label="Resize" />
          <g.Panel @id="b">B</g.Panel>
          <output>{{g.layout.length}}</output>
        </ResizablePanelGroup>
      </template>,
    )
    assert.deepEqual(new ResizableHarness().sizes, [50, 50])
    assert.dom('output').hasText('2')
    await a11yAudit()
  })
})
