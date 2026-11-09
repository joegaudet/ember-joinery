import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, focus, render, settled } from '@ember/test-helpers'
import { fn, hash } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import {
  anchorMode,
  isAnchorFallbackForced,
  supportsAnchorPositioning,
} from '@ember-joinery/primitives/anchor'
import { Popover } from '@ember-joinery/primitives/popover'
import { isScrollLocked } from '@ember-joinery/primitives/scroll-lock'
import {
  PopoverHarness,
  placementOf,
  pressOutside,
  setupAnchorFallback,
  tab,
  type TestHooks,
} from '@ember-joinery/test-support'

/** Fixed sizes, and none of the browser's popover border or padding, so edges line up. */
const Styles = <template>
  <style>
    .po-stage {
      position: fixed;
      top: 200px;
      left: 300px;
    }
    .po-trigger {
      width: 60px;
      height: 20px;
      padding: 0;
      border: 0;
    }
    .po-content {
      width: 100px;
      height: 40px;
      padding: 0;
      border: 0;
      overflow: visible;
    }
  </style>
</template>

class State {
  @tracked open = false
  changes: boolean[] = []
  setOpen = (open: boolean) => {
    this.changes.push(open)
    this.open = open
  }
}

type Assert = Parameters<Parameters<typeof test>[1]>[0]

const rect = (element: Element) => element.getBoundingClientRect()

function near(assert: Assert, actual: number, expected: number, message: string) {
  assert.true(Math.abs(actual - expected) <= 1, `${message} (${actual} ≈ ${expected})`)
}

/** Placement, in both ways of anchoring: each module runs these. */
function placementTests(hooks: TestHooks) {
  void hooks

  test('it places the content below its trigger by default, centred and touching it', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger class="po-trigger">Open</p.Trigger>
            <p.Content class="po-content">Content</p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    const t = rect(popover.trigger)
    const c = rect(popover.content!)
    near(assert, c.top, t.bottom, 'below, with no offset (Radix’s default)')
    near(assert, c.left + c.width / 2, t.left + t.width / 2, 'centred')
    assert.deepEqual(placementOf(popover.content!), { side: 'bottom', align: 'center' })
    await a11yAudit()
  })

  test('@side, @align and @sideOffset place it', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger class="po-trigger">Right</p.Trigger>
            <p.Content class="po-content" @side="right" @align="start" @sideOffset={{6}}>
              Content
            </p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    near(
      assert,
      rect(popover.content!).left,
      rect(popover.trigger).right + 6,
      'to the right, 6px off',
    )
    near(assert, rect(popover.content!).top, rect(popover.trigger).top, 'top edges lined up')
    assert.deepEqual(placementOf(popover.content!), { side: 'right', align: 'start' })
    await a11yAudit()
  })

  test('it flips to the other side when there is no room', async function (assert) {
    await render(
      <template>
        <Styles />
        <div style="position: fixed; bottom: 4px; left: 600px">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger class="po-trigger">Low</p.Trigger>
            <p.Content class="po-content" @sideOffset={{4}}>Content</p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.strictEqual(popover.side, 'top', 'no room below, so above')
    near(assert, rect(popover.content!).bottom, rect(popover.trigger).top - 4, 'above, 4px off')
    await a11yAudit()
  })

  test('start follows the text direction', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage" dir="rtl">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger class="po-trigger">فتح</p.Trigger>
            <p.Content class="po-content" @align="start">المحتوى</p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    near(
      assert,
      rect(popover.content!).right,
      rect(popover.trigger).right,
      'start is the right edge, right to left',
    )
    await a11yAudit()
  })

  test('an Anchor places the content instead of the trigger', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Anchor id="anchor" style="width: 200px; height: 10px">
              <p.Trigger class="po-trigger">Open</p.Trigger>
            </p.Anchor>
            <p.Content class="po-content" @align="end">Content</p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    const anchor = document.getElementById('anchor')!
    near(assert, rect(popover.content!).top, rect(anchor).bottom, 'below the anchor')
    near(assert, rect(popover.content!).right, rect(anchor).right, 'at its end')
    await a11yAudit()
  })

  test('an Arrow sits on the edge facing the trigger, and adds its height to the offset', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage">
          <Popover @defaultOpen={{true}} as |p|>
            <p.Trigger class="po-trigger">Open</p.Trigger>
            <p.Content class="po-content" @sideOffset={{2}}>
              Content
              <p.Arrow />
            </p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    const arrow = popover.arrow!
    assert.dom(arrow.querySelector('svg')).hasAttribute('aria-hidden', 'true')
    assert.dom(arrow.querySelector('polygon')).exists('Radix’s triangle')
    near(assert, rect(popover.content!).top, rect(popover.trigger).bottom + 2 + 5, '2px + 5px')
    assert.strictEqual(arrow.style.transform, 'rotate(180deg)', 'pointing up at the trigger')
    near(
      assert,
      rect(arrow).left + rect(arrow).width / 2,
      rect(popover.trigger).left + rect(popover.trigger).width / 2,
      'centred on the trigger',
    )
    await a11yAudit()
  })
}

module('Integration | primitives | popover', function (hooks) {
  setupRenderingTest(hooks)

  test('a click on the trigger opens it in the top layer, and focus moves in', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Open popover</p.Trigger>
          <p.Content>
            <a href="#help">Help</a>
            <input aria-label="Width" value="100%" />
          </p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.false(popover.isOpen)
    assert
      .dom(popover.trigger)
      .hasTagName('button')
      .hasAttribute('type', 'button')
      .hasAttribute('aria-haspopup', 'dialog')
      .hasAttribute('aria-expanded', 'false')
      .hasAttribute('data-state', 'closed')
      .doesNotHaveAttribute('aria-controls')
    assert.strictEqual(popover.content, null)
    await a11yAudit()

    await popover.open()
    assert.true(popover.isOpen)
    assert.true(popover.isShown, 'in the top layer')
    const content = popover.content!
    assert
      .dom(content)
      .hasAttribute('role', 'dialog')
      .hasAttribute('data-state', 'open')
      .hasAttribute('tabindex', '-1')
    assert.dom(popover.trigger).hasAttribute('aria-controls', content.id)
    assert.strictEqual(popover.label, 'Open popover', 'with no Title, its trigger names it')
    assert.dom('input', content).isFocused('focus moves to its first focusable that isn’t a link')
    assert.ok(
      content.style.getPropertyValue('--radix-popover-content-transform-origin'),
      'Radix’s custom properties, for upstream’s classes',
    )
    await a11yAudit()

    await popover.close()
    assert.false(popover.isOpen)
    assert.strictEqual(popover.content, null)
    assert.dom(popover.trigger).isFocused('focus goes back to the trigger')
    await a11yAudit()
  })

  test('Escape closes it and focus returns; a press outside closes it and leaves focus be', async function (assert) {
    await render(
      <template>
        <button id="elsewhere" type="button">Elsewhere</button>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content><button type="button">Inside</button></p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    await popover.pressEscape()
    assert.false(popover.isOpen, 'Escape closes it')
    assert.dom(popover.trigger).isFocused('and focus returns to the trigger')

    await popover.open()
    await pressOutside(document.getElementById('elsewhere')!)
    assert.false(popover.isOpen, 'a press outside closes it')
    assert.dom(popover.trigger).isNotFocused('focus stays where the user pressed')
    await a11yAudit()
  })

  test('a press on the trigger toggles it, without dismissing it first', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Content</p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    // pointerdown on the trigger is inside the layer, then its click closes it once.
    await pressOutside(popover.trigger)
    assert.false(popover.isOpen)
    await a11yAudit()
  })

  test('it can start open', async function (assert) {
    await render(
      <template>
        <Popover @defaultOpen={{true}} as |p|>
          <p.Trigger>Uncontrolled</p.Trigger>
          <p.Content>Content</p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.true(popover.isOpen, '@defaultOpen starts it open')
    assert.true(popover.isShown)
    await popover.close()
    assert.false(popover.isOpen)
    await a11yAudit()
  })

  test('its state can be controlled', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Popover @name="controlled" @open={{state.open}} @onOpenChange={{state.setOpen}} as |p|>
          <p.Trigger>Controlled</p.Trigger>
          <p.Content>Content</p.Content>
        </Popover>
      </template>,
    )
    const controlled = new PopoverHarness('controlled')

    await controlled.toggle()
    assert.deepEqual(state.changes, [true], '@onOpenChange hears the request')
    assert.true(controlled.isOpen)

    state.open = false
    await settled()
    assert.false(controlled.isOpen, 'the caller closes it')
    await a11yAudit()
  })

  test('a Title names it and a Description describes it; an aria-label of your own wins', async function (assert) {
    await render(
      <template>
        <Popover @name="titled" @defaultOpen={{true}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>
            <p.Title>Dimensions</p.Title>
            <p.Description>Set the dimensions for the layer.</p.Description>
            <p.Close>Done</p.Close>
          </p.Content>
        </Popover>
      </template>,
    )
    const titled = new PopoverHarness('titled')
    assert.strictEqual(titled.label, 'Dimensions')
    assert.strictEqual(titled.title, 'Dimensions')
    assert.strictEqual(titled.description, 'Set the dimensions for the layer.')
    assert.dom(titled.queryPart('title')).hasTagName('h2')
    await a11yAudit()

    await titled.clickClose()
    assert.false(titled.isOpen, 'Close closes it')
    assert.dom(titled.trigger).isFocused()

    await render(
      <template>
        <Popover @name="labelled" @defaultOpen={{true}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content aria-label="Settings">Content</p.Content>
        </Popover>
      </template>,
    )
    const labelled = new PopoverHarness('labelled')
    assert.strictEqual(labelled.label, 'Settings')
    assert.dom(labelled.content).doesNotHaveAttribute('aria-labelledby')
    await a11yAudit()
  })

  test('Tab goes round inside it, as in Radix’s popover', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>
            <button id="first" type="button">First</button>
            <button id="last" type="button">Last</button>
          </p.Content>
        </Popover>
        <button type="button">After</button>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    assert.dom('#first').isFocused()
    await tab()
    assert.dom('#last').isFocused()
    await tab()
    assert.dom('#first').isFocused('from the last, back to the first')
    await tab({ shift: true })
    assert.dom('#last').isFocused('and back the other way')
    await a11yAudit()
  })

  test('a modal one keeps focus in and the pointer off the page, until it closes', async function (assert) {
    await render(
      <template>
        <button id="outside" type="button">Outside</button>
        <Popover @modal={{true}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content><button id="inside" type="button">Inside</button></p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    assert.dom('#inside').isFocused()
    assert.strictEqual(document.body.style.pointerEvents, 'none', 'the page ignores the pointer')
    assert.strictEqual(popover.content!.style.pointerEvents, 'auto', 'but the content takes it')
    assert.dom('#outside').hasAttribute('aria-hidden', 'true', 'the page is hidden, as Radix’s')
    assert.dom(popover.trigger).hasAttribute('aria-hidden', 'true', 'the trigger too')
    assert.dom(popover.content).doesNotHaveAttribute('aria-hidden', 'but not the content')
    assert.true(isScrollLocked(), 'and the page doesn’t scroll')

    await focus('#outside')
    assert.dom('#inside').isFocused('focus that leaves is brought back')
    assert.true(popover.isOpen, 'and doesn’t close it')

    await popover.pressEscape()
    assert.false(popover.isOpen)
    assert.strictEqual(document.body.style.pointerEvents, '', 'the pointer is back')
    assert.dom('#outside').doesNotHaveAttribute('aria-hidden', 'the page is heard again')
    assert.false(isScrollLocked(), 'and scrolls again')
    assert.dom(popover.trigger).isFocused()
    await a11yAudit()
  })

  test('focus moving outside closes a non-modal one', async function (assert) {
    await render(
      <template>
        <button id="outside" type="button">Outside</button>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content><button type="button">Inside</button></p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    await popover.open()
    assert.dom('#outside').doesNotHaveAttribute('aria-hidden', 'the page is still heard')
    assert.false(isScrollLocked(), 'and still scrolls')
    await focus('#outside')
    assert.false(popover.isOpen)
    assert.dom('#outside').isFocused('focus stays where it went')
    await a11yAudit()
  })

  test('a popover inside another is nested in it: pressing it leaves the outer open', async function (assert) {
    await render(
      <template>
        <Popover @name="outer" as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <Popover @name="inner" as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content><button type="button">Deep</button></inner.Content>
            </Popover>
          </outer.Content>
        </Popover>
      </template>,
    )
    const outer = new PopoverHarness('outer')
    const inner = new PopoverHarness('inner')
    await outer.open()
    await inner.open()
    assert.true(inner.isShown)
    await click(inner.content!.querySelector('button')!)
    assert.true(outer.isOpen, 'a press in the inner one is inside the outer one')

    await inner.pressEscape()
    assert.false(inner.isOpen, 'Escape closes the top one')
    assert.true(outer.isOpen, 'and only it')
    await a11yAudit()
  })

  test('the trigger can be your own element, and the parts take @as', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Popover @open={{state.open}} @onOpenChange={{state.setOpen}} as |p|>
          <span role="button" tabindex="0" id="own" {{p.trigger}}>Own trigger</span>
          <p.Content @as="section" aria-label="Details">
            <p.Close @as="span" role="button" tabindex="0">Close</p.Close>
          </p.Content>
          <button type="button" {{on "click" (fn p.setOpen true)}}>Open from outside</button>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.dom(popover.trigger).hasAttribute('id', 'own', 'its own id stays')
    await popover.open()
    assert.dom(popover.content).hasTagName('section')
    assert.dom(popover.queryPart('close')).hasTagName('span')
    await a11yAudit()
  })

  test('@forceMount keeps the content rendered while closed', async function (assert) {
    await render(
      <template>
        <Popover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content @forceMount={{true}} aria-label="Always">Content</p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.dom(popover.content).hasAttribute('data-state', 'closed')
    assert.dom(popover.trigger).isNotFocused('and it doesn’t take focus while closed')
    await popover.open()
    assert.dom(popover.content).hasAttribute('data-state', 'open')
    await a11yAudit()
  })

  test('ember-primitives’ arguments and yields: placement, offset, reference and data', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage">
          <Popover @defaultOpen={{true}} @placement="top-start" @offsetOptions={{8}} as |p|>
            <button id="reference" type="button" class="po-trigger" {{p.reference}}>Ref</button>
            <p.Content
              class="po-content"
              aria-label="Floating"
              data-test-placement={{p.data.placement}}
            >
              Content
              <div id="own-arrow" style="width: 8px; height: 6px" {{p.arrow}}></div>
            </p.Content>
          </Popover>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    const reference = document.getElementById('reference')!
    near(
      assert,
      rect(popover.content!).bottom,
      rect(reference).top - 8 - 6,
      'above, 8px off, and the arrow’s height',
    )
    near(assert, rect(popover.content!).left, rect(reference).left, 'at the start')
    assert.dom(popover.content).hasAttribute('data-test-placement', 'top-start', 'data is yielded')
    assert.strictEqual(
      document.getElementById('own-arrow')!.style.position,
      'absolute',
      'your own element can be the arrow',
    )
    await a11yAudit()
  })

  test('flipOptions’ elementContext "both" flips when a scroll container clips the trigger', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="po-stage" style="height: 60px; overflow: auto">
          <div style="height: 200px; padding-top: 50px">
            <Popover @defaultOpen={{true}} @flipOptions={{hash elementContext="both"}} as |p|>
              <p.Trigger class="po-trigger">Open</p.Trigger>
              <p.Content class="po-content" aria-label="Flips">Content</p.Content>
            </Popover>
          </div>
        </div>
      </template>,
    )
    const popover = new PopoverHarness()
    assert.strictEqual(
      anchorMode(popover.trigger, { flipOptions: { elementContext: 'both' } }),
      'floating-ui',
      'only Floating UI can tell',
    )
    assert.strictEqual(popover.side, 'top', 'the trigger is clipped below, so it goes above')
    await a11yAudit()
  })
})

module('Integration | primitives | popover | placement, CSS anchor positioning', function (hooks) {
  setupRenderingTest(hooks)

  test('it uses CSS anchor positioning where the browser has it', async function (assert) {
    await render(
      <template>
        <Popover @defaultOpen={{true}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content aria-label="Content">Content</p.Content>
        </Popover>
      </template>,
    )
    const popover = new PopoverHarness()
    const expected =
      isAnchorFallbackForced() || !supportsAnchorPositioning() ? 'floating-ui' : 'css'
    assert.strictEqual(anchorMode(popover.trigger), expected)
    if (expected === 'css') {
      assert.ok(popover.content!.style.getPropertyValue('position-anchor'), 'position-anchor')
    }
    await a11yAudit()
  })

  placementTests(hooks)
})

module('Integration | primitives | popover | placement, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)
  placementTests(hooks)
})
