import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
// Renamed: a template's own `(modifier …)` keyword would otherwise mean this function.
import { modifier as functionModifier } from 'ember-modifier'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  ANCHOR_PROPERTIES,
  FloatingUI,
  anchorMode,
  anchorTo,
  isAnchorFallbackForced,
  supportsAnchorPositioning,
  type Align,
  type AnchorMode,
  type Middleware,
  type Side,
  type VirtualElement,
} from '@ember-joinery/primitives/anchor'
import { topLayer } from '@ember-joinery/primitives/layer'
import { placementOf, setupAnchorFallback, type TestHooks } from '@ember-joinery/test-support'
import {
  FxLayeredPopover,
  FxLayeredPopoverHarness,
} from 'test-app/tests/fixtures/primitives/layered-popover'

/** Fixed sizes, and none of the browser's popover border or padding, so edges line up. */
const Styles = <template>
  <style>
    .anchor-stage {
      position: fixed;
      top: 200px;
      left: 300px;
    }
    .anchor-trigger {
      width: 60px;
      height: 20px;
      padding: 0;
      border: 0;
    }
    .anchor-content {
      width: 100px;
      height: 40px;
      padding: 0;
      border: 0;
      overflow: visible;
    }
    .anchor-wide {
      width: 300px;
    }
    .anchor-arrow {
      display: block;
      width: 10px;
      height: 5px;
    }
  </style>
</template>

class Placement {
  @tracked side: Side = 'bottom'
  @tracked align: Align = 'center'
}

class ArrowState {
  @tracked arrow: HTMLElement | null = null
  @tracked shown = true
}

/** Hands the element to the state once the render is over, as a component's part would. */
const capture = functionModifier((element: HTMLElement, [state]: [ArrowState]) => {
  queueMicrotask(() => (state.arrow = element))
})

type Assert = Parameters<Parameters<typeof test>[1]>[0]

const rect = (element: Element) => element.getBoundingClientRect()

function near(assert: Assert, actual: number, expected: number, message: string) {
  assert.true(Math.abs(actual - expected) <= 1, `${message} (${actual} ≈ ${expected})`)
}

/** What anchoring should use in this run: CI's fallback run forces Floating UI everywhere. */
function expectedMode(): AnchorMode {
  return isAnchorFallbackForced() || !supportsAnchorPositioning() ? 'floating-ui' : 'css'
}

/** Checks the content sits on the side and at the alignment asked for, `offset` away. */
function assertPlaced(
  assert: Assert,
  trigger: Element,
  content: Element,
  side: Side,
  align: Align,
  offset: number,
) {
  const t = rect(trigger)
  const c = rect(content)
  const what = `${side} ${align}`
  if (side === 'bottom') near(assert, c.top, t.bottom + offset, `${what}: below`)
  if (side === 'top') near(assert, c.bottom, t.top - offset, `${what}: above`)
  if (side === 'right') near(assert, c.left, t.right + offset, `${what}: to the right`)
  if (side === 'left') near(assert, c.right, t.left - offset, `${what}: to the left`)
  const vertical = side === 'top' || side === 'bottom'
  if (align === 'center' && vertical) {
    near(assert, c.left + c.width / 2, t.left + t.width / 2, `${what}: centred`)
  } else if (align === 'center') {
    near(assert, c.top + c.height / 2, t.top + t.height / 2, `${what}: centred`)
  } else if (vertical) {
    if (align === 'start') near(assert, c.left, t.left, `${what}: left edges`)
    else near(assert, c.right, t.right, `${what}: right edges`)
  } else if (align === 'start') {
    near(assert, c.top, t.top, `${what}: top edges`)
  } else {
    near(assert, c.bottom, t.bottom, `${what}: bottom edges`)
  }
  assert.deepEqual(placementOf(content), { side, align }, `${what}: data-side and data-align`)
}

/** The behaviour both modes share: each module runs these. */
function anchoringTests(hooks: TestHooks) {
  void hooks

  test('it places the content below its trigger, centred, and says where', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <FxLayeredPopover @sideOffset={{4}} as |p|>
            <p.Trigger class="anchor-trigger">Open</p.Trigger>
            <p.Content class="anchor-content">Content</p.Content>
          </FxLayeredPopover>
        </div>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()
    assert.true(popover.isInTopLayer)
    assertPlaced(assert, popover.trigger, popover.content!, 'bottom', 'center', 4)
    await a11yAudit()
  })

  test('it places the content on each side, at each alignment', async function (assert) {
    const placement = new Placement()
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <FxLayeredPopover
            @defaultOpen={{true}}
            @side={{placement.side}}
            @align={{placement.align}}
            @sideOffset={{6}}
            as |p|
          >
            <p.Trigger class="anchor-trigger">Open</p.Trigger>
            <p.Content class="anchor-content">Content</p.Content>
          </FxLayeredPopover>
        </div>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    for (const side of ['top', 'right', 'bottom', 'left'] as const) {
      for (const align of ['start', 'center', 'end'] as const) {
        placement.side = side
        placement.align = align
        await settled()
        assertPlaced(assert, popover.trigger, popover.content!, side, align, 6)
      }
    }
    await a11yAudit()
  })

  test('it flips to the other side when there is no room', async function (assert) {
    await render(
      <template>
        <Styles />
        <div style="position: fixed; bottom: 4px; left: 300px">
          <FxLayeredPopover @defaultOpen={{true}} @sideOffset={{4}} as |p|>
            <p.Trigger class="anchor-trigger">Open</p.Trigger>
            <p.Content class="anchor-content">Content</p.Content>
          </FxLayeredPopover>
        </div>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    assertPlaced(assert, popover.trigger, popover.content!, 'top', 'center', 4)
    await a11yAudit()
  })

  test('it shifts along the side to stay in view', async function (assert) {
    await render(
      <template>
        <Styles />
        <div style="position: fixed; top: 200px; left: 0">
          <FxLayeredPopover @defaultOpen={{true}} as |p|>
            <p.Trigger class="anchor-trigger">Open</p.Trigger>
            <p.Content class="anchor-content anchor-wide">Content</p.Content>
          </FxLayeredPopover>
        </div>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    const c = rect(popover.content!)
    assert.true(c.left >= -0.5, `centred on a trigger at the edge, it stays on screen (${c.left})`)
    near(assert, c.top, rect(popover.trigger).bottom, 'still below its trigger')
    assert.deepEqual(placementOf(popover.content!), { side: 'bottom', align: 'center' })
    await a11yAudit()
  })

  test('start and end follow the text direction', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="anchor-stage" dir="rtl">
          <FxLayeredPopover @defaultOpen={{true}} @align="start" as |p|>
            <p.Trigger class="anchor-trigger">فتح</p.Trigger>
            <p.Content class="anchor-content">المحتوى</p.Content>
          </FxLayeredPopover>
        </div>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    const t = rect(popover.trigger)
    const c = rect(popover.content!)
    near(assert, c.right, t.right, 'start is the right edge, right to left')
    assert.deepEqual(placementOf(popover.content!), { side: 'bottom', align: 'start' })
    await a11yAudit()
  })

  test('it sets the anchor’s size and the arrow’s place, as Radix’s Popper does', async function (assert) {
    const state = new ArrowState()
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <button id="trigger" type="button" class="anchor-trigger">Trigger</button>
        </div>
        <div
          id="content"
          class="anchor-content"
          {{topLayer}}
          {{anchorTo "#trigger" side="bottom" sideOffset=2 arrow=state.arrow}}
        >
          Content
          <span class="anchor-arrow" {{capture state}}></span>
        </div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    const arrow = content.querySelector<HTMLElement>('.anchor-arrow')!

    // The arrow's height adds to the offset, so its tip touches the trigger.
    assertPlaced(assert, trigger, content, 'bottom', 'center', 2 + 5)
    const style = content.style
    assert.strictEqual(style.getPropertyValue(ANCHOR_PROPERTIES.width), `${rect(trigger).width}px`)
    assert.strictEqual(
      style.getPropertyValue(ANCHOR_PROPERTIES.height),
      `${rect(trigger).height}px`,
    )
    assert.ok(style.getPropertyValue(ANCHOR_PROPERTIES.availableHeight).endsWith('px'))
    assert.strictEqual(
      style.getPropertyValue(ANCHOR_PROPERTIES.transformOrigin),
      `${45 + 5}px -5px`,
      'it grows from the arrow’s tip',
    )

    assert.strictEqual(arrow.style.position, 'absolute')
    assert.strictEqual(arrow.style.top, '0px', 'on the edge facing the trigger')
    assert.strictEqual(arrow.style.transform, 'rotate(180deg)', 'pointing at it')
    near(
      assert,
      rect(arrow).left + rect(arrow).width / 2,
      rect(trigger).left + rect(trigger).width / 2,
      'centred on the trigger',
    )
    await a11yAudit()
  })

  test('it puts back everything it set when it stops', async function (assert) {
    const state = new ArrowState()
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <button id="trigger" type="button" class="anchor-trigger">Trigger</button>
        </div>
        <div
          id="content"
          class="anchor-content"
          {{(if state.shown (modifier (modifier anchorTo "#trigger") side="right"))}}
        >Content</div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    assert.dom(content).hasAttribute('data-side', 'right')

    state.shown = false
    await settled()
    assert.dom(content).doesNotHaveAttribute('data-side')
    assert.dom(content).doesNotHaveAttribute('data-align')
    assert.strictEqual(content.getAttribute('style'), null, 'no inline styles left')
    assert.strictEqual(trigger.style.getPropertyValue('anchor-name'), '', 'nor an anchor name')
    await a11yAudit()
  })

  test('FloatingUI yields the modifiers and the data, as ember-primitives’ does', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <FloatingUI @placement="top-start" @offsetOptions={{8}} as |reference floating util|>
            <button id="trigger" type="button" class="anchor-trigger" {{reference}}>Trigger</button>
            {{#if floating}}
              <div
                id="content"
                class="anchor-content"
                data-test-placement={{util.data.placement}}
                data-test-mode={{util.data.mode}}
                {{topLayer}}
                {{floating}}
              >Content</div>
            {{/if}}
          </FloatingUI>
        </div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    assertPlaced(assert, trigger, content, 'top', 'start', 8)
    assert.dom(content).hasAttribute('data-test-placement', 'top-start')
    assert.dom(content).hasAttribute('data-test-mode', expectedMode())
    await a11yAudit()
  })

  test('custom middleware runs, through Floating UI', async function (assert) {
    let ran = 0
    const spy: Middleware = {
      name: 'spy',
      fn: ({ x, y }) => {
        ran += 1
        return { x: x + 10, y }
      },
    }
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <FloatingUI @middleware={{array spy}} as |reference floating util|>
            <button id="trigger" type="button" class="anchor-trigger" {{reference}}>Trigger</button>
            {{#if floating}}
              <div
                id="content"
                class="anchor-content"
                data-test-mode={{util.data.mode}}
                {{topLayer}}
                {{floating}}
              >Content</div>
            {{/if}}
          </FloatingUI>
        </div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    assert.true(ran > 0, 'the middleware ran')
    assert.dom(content).hasAttribute('data-test-mode', 'floating-ui')
    near(
      assert,
      rect(content).left + rect(content).width / 2,
      rect(trigger).left + rect(trigger).width / 2 + 10,
      'and moved the element',
    )
    await a11yAudit()
  })

  test('a virtual reference, such as a pointer position', async function (assert) {
    const virtual: VirtualElement = {
      getBoundingClientRect: () => new DOMRect(150, 120, 0, 0),
    }
    await render(
      <template>
        <Styles />
        <div class="anchor-content" id="content" {{topLayer}} {{anchorTo virtual align="start"}}>
          Menu
        </div>
      </template>,
    )
    const content = document.getElementById('content')!
    near(assert, rect(content).top, 120, 'below the point')
    near(assert, rect(content).left, 150, 'starting at it')
    assert.strictEqual(anchorMode(virtual), 'floating-ui', 'which only Floating UI can follow')
    await a11yAudit()
  })
}

module('Integration | primitives | anchor', function (hooks) {
  setupRenderingTest(hooks)

  anchoringTests(hooks)

  test('it uses CSS anchor positioning where the browser has it', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <button id="trigger" type="button" class="anchor-trigger">Trigger</button>
        </div>
        <div id="content" class="anchor-content" {{topLayer}} {{anchorTo "#trigger"}}>Content</div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    assert.strictEqual(anchorMode(trigger), expectedMode())
    if (expectedMode() === 'css') {
      const name = content.style.getPropertyValue('position-anchor')
      assert.true(name.startsWith('--jn-anchor-'), 'the content names its anchor')
      assert.strictEqual(trigger.style.getPropertyValue('anchor-name'), name)
      assert.strictEqual(content.style.getPropertyValue('position-area'), 'bottom')
      assert.strictEqual(content.style.getPropertyValue('position-try-fallbacks'), 'flip-block')
    } else {
      assert.ok(true, 'this run forces the Floating UI fallback, or the browser has no anchors')
    }
    await a11yAudit()
  })
})

module('Integration | primitives | anchor (Floating UI fallback)', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)

  anchoringTests(hooks)

  test('the forced fallback positions with Floating UI', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="anchor-stage">
          <button id="trigger" type="button" class="anchor-trigger">Trigger</button>
        </div>
        <div id="content" class="anchor-content" {{topLayer}} {{anchorTo "#trigger"}}>Content</div>
      </template>,
    )
    const trigger = document.getElementById('trigger')!
    const content = document.getElementById('content')!
    assert.true(isAnchorFallbackForced())
    assert.strictEqual(anchorMode(trigger), 'floating-ui')
    assert.strictEqual(content.style.getPropertyValue('position-anchor'), '', 'no CSS anchor')
    assert.strictEqual(trigger.style.getPropertyValue('anchor-name'), '')
    assert.true(content.style.left.endsWith('px'), 'placed by coordinates')
    assert.true(content.style.top.endsWith('px'))
    await a11yAudit()
  })
})
