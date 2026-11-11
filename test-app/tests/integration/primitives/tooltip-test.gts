import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled, waitUntil } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Tooltip, TooltipProvider } from '@ember-joinery/primitives/tooltip'
import {
  TooltipHarness,
  hover,
  placementOf,
  press,
  pressOutside,
  setupAnchorFallback,
  unhover,
  type TestHooks,
} from '@ember-joinery/test-support'

/** Fixed sizes, and none of the browser's popover border or padding, so edges line up. */
const Styles = <template>
  <style>
    .tt-stage {
      position: fixed;
      top: 200px;
      left: 300px;
      display: flex;
      gap: 40px;
    }
    .tt-trigger {
      width: 60px;
      height: 20px;
      padding: 0;
      border: 0;
    }
    .tt-content {
      width: 100px;
      height: 30px;
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

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

function placementTests(hooks: TestHooks) {
  void hooks

  test('it goes above its trigger by default, and flips when there is no room', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="tt-stage">
          <Tooltip @name="top" @defaultOpen={{true}} as |t|>
            <t.Trigger class="tt-trigger">Top</t.Trigger>
            <t.Content class="tt-content">Above</t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const top = new TooltipHarness('top')
    near(assert, rect(top.content!).bottom, rect(top.trigger).top, 'above, touching it')
    assert.deepEqual(placementOf(top.content!), { side: 'top', align: 'center' })

    await render(
      <template>
        <Styles />
        <div style="position: fixed; bottom: 4px; left: 300px">
          <Tooltip @defaultOpen={{true}} as |t|>
            <t.Trigger class="tt-trigger">Low</t.Trigger>
            <t.Content class="tt-content" @side="bottom" @sideOffset={{4}}>Above</t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const flipped = new TooltipHarness()
    assert.strictEqual(flipped.side, 'top', 'no room below, so above')
    near(assert, rect(flipped.content!).bottom, rect(flipped.trigger).top - 4, 'above, 4px off')
    await a11yAudit()
  })

  test('each side, and an arrow that points at the trigger', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="tt-stage">
          <Tooltip @defaultOpen={{true}} as |t|>
            <t.Trigger class="tt-trigger">Left</t.Trigger>
            <t.Content class="tt-content" @side="left">
              Left
              <t.Arrow />
            </t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const tooltip = new TooltipHarness()
    assert.strictEqual(tooltip.side, 'left')
    near(
      assert,
      rect(tooltip.content!).right,
      rect(tooltip.trigger).left - 5,
      'to the left, the arrow’s height off',
    )
    assert.strictEqual(
      tooltip.arrow!.style.transform,
      'translateY(50%) rotate(-90deg) translateX(50%)',
    )
    await a11yAudit()
  })
}

module('Integration | primitives | tooltip', function (hooks) {
  setupRenderingTest(hooks)

  test('resting the pointer on the trigger opens it after its delay; moving away closes it', async function (assert) {
    await render(
      <template>
        <Tooltip @delayDuration={{50}} as |t|>
          <t.Trigger>Hover</t.Trigger>
          <t.Content>Add to library</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    assert.dom(tooltip.trigger).hasTagName('button').hasAttribute('type', 'button')
    assert.strictEqual(tooltip.state, 'closed')
    assert.strictEqual(tooltip.description, '')

    const started = performance.now()
    await tooltip.hover()
    assert.true(performance.now() - started >= 45, 'it waited for the delay')
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.state, 'delayed-open')
    assert.true(tooltip.isShown, 'in the top layer')
    assert
      .dom(tooltip.content)
      .hasAttribute('role', 'tooltip')
      .hasAttribute('data-state', 'delayed-open')
    assert.strictEqual(tooltip.description, 'Add to library', 'the trigger is described by it')
    assert.ok(
      tooltip.content!.style.getPropertyValue('--radix-tooltip-content-transform-origin'),
      'Radix’s custom properties, for upstream’s classes',
    )
    await a11yAudit()

    await tooltip.unhover()
    assert.false(tooltip.isOpen)
    assert.strictEqual(tooltip.content, null)
    assert.dom(tooltip.trigger).doesNotHaveAttribute('aria-describedby')
    await a11yAudit()
  })

  test('focus opens it at once and blur closes it; a press on the trigger closes it', async function (assert) {
    await render(
      <template>
        <Tooltip as |t|>
          <t.Trigger>Focus me</t.Trigger>
          <t.Content>Described</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.focus()
    assert.strictEqual(tooltip.state, 'instant-open', 'no delay for the keyboard')
    await tooltip.blur()
    assert.false(tooltip.isOpen)

    await tooltip.focus()
    await press(tooltip.trigger)
    assert.false(tooltip.isOpen, 'a press closes it, and the focus it brings doesn’t reopen it')
    await a11yAudit()
  })

  test('Escape and a press outside close it', async function (assert) {
    await render(
      <template>
        <Tooltip as |t|>
          <t.Trigger>Trigger</t.Trigger>
          <t.Content>Tip</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.focus()
    await tooltip.pressEscape()
    assert.false(tooltip.isOpen, 'Escape')

    await tooltip.hover()
    assert.true(tooltip.isOpen)
    await pressOutside()
    assert.false(tooltip.isOpen, 'a press outside')
    await a11yAudit()
  })

  test('the pointer can move from the trigger onto it, and leaving it closes it', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="tt-stage">
          <Tooltip @delayDuration={{0}} as |t|>
            <t.Trigger class="tt-trigger">Trigger</t.Trigger>
            <t.Content class="tt-content" @sideOffset={{4}}>Hover me too</t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.hover()
    await tooltip.hoverContent()
    assert.true(tooltip.isOpen, 'crossing the gap keeps it open')

    await unhover(tooltip.content!, { away: tooltip.trigger })
    assert.false(tooltip.isOpen, 'leaving it for elsewhere closes it')
    await a11yAudit()
  })

  test('with @disableHoverableContent, leaving the trigger closes it at once', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="tt-stage">
          <Tooltip @delayDuration={{0}} @disableHoverableContent={{true}} as |t|>
            <t.Trigger class="tt-trigger">Trigger</t.Trigger>
            <t.Content class="tt-content">Tip</t.Content>
          </Tooltip>
        </div>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.hover()
    assert.true(tooltip.isOpen)
    await unhover(tooltip.trigger, { side: 'top', distance: 1 })
    assert.false(tooltip.isOpen, 'even towards the tooltip')
    await a11yAudit()
  })

  test('a touch doesn’t open it', async function (assert) {
    await render(
      <template>
        <Tooltip @delayDuration={{0}} as |t|>
          <t.Trigger>Trigger</t.Trigger>
          <t.Content>Tip</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.hover({ pointerType: 'touch' })
    assert.false(tooltip.isOpen)
    await a11yAudit()
  })

  test('only one is open at a time', async function (assert) {
    await render(
      <template>
        <Tooltip @name="one" as |t|>
          <t.Trigger>One</t.Trigger>
          <t.Content>First</t.Content>
        </Tooltip>
        <Tooltip @name="two" as |t|>
          <t.Trigger>Two</t.Trigger>
          <t.Content>Second</t.Content>
        </Tooltip>
      </template>,
    )
    const one = new TooltipHarness('one')
    const two = new TooltipHarness('two')
    await one.focus()
    assert.true(one.isOpen)
    // Just after the first opened, the second opens at once, and the first closes.
    await hover(two.trigger)
    await waitUntil(() => two.isOpen)
    assert.false(one.isOpen, 'opening one closes the other')
    await a11yAudit()
  })

  test('a provider’s tooltips share their delays: just after one closes, the next opens at once', async function (assert) {
    await render(
      <template>
        <TooltipProvider @delayDuration={{60}} @skipDelayDuration={{200}}>
          <Tooltip @name="bold" as |t|>
            <t.Trigger>Bold</t.Trigger>
            <t.Content>Bold</t.Content>
          </Tooltip>
          <Tooltip @name="italic" as |t|>
            <t.Trigger>Italic</t.Trigger>
            <t.Content>Italic</t.Content>
          </Tooltip>
          <Tooltip @name="own" @delayDuration={{0}} as |t|>
            <t.Trigger>Own</t.Trigger>
            <t.Content>Own</t.Content>
          </Tooltip>
        </TooltipProvider>
      </template>,
    )
    const bold = new TooltipHarness('bold')
    const italic = new TooltipHarness('italic')
    assert.dom('[data-jn-tooltip-provider]').exists()

    const started = performance.now()
    await bold.hover()
    assert.true(performance.now() - started >= 55, 'the provider’s delay')
    assert.strictEqual(bold.state, 'delayed-open')
    await bold.unhover()
    assert.false(bold.isOpen)

    await italic.hover()
    assert.strictEqual(italic.state, 'instant-open', 'within the skip delay, at once')
    await italic.unhover()

    await sleep(250)
    await bold.hover()
    assert.strictEqual(bold.state, 'delayed-open', 'after it, with the delay again')
    await bold.unhover()
    await a11yAudit()
  })

  test('its state can be controlled', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Tooltip @open={{state.open}} @onOpenChange={{state.setOpen}} as |t|>
          <t.Trigger>Trigger</t.Trigger>
          <t.Content>Tip</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    await tooltip.focus()
    assert.deepEqual(state.changes, [true])
    assert.true(tooltip.isOpen)
    state.open = false
    await settled()
    assert.false(tooltip.isOpen)
    await a11yAudit()
  })

  test('the trigger can be your own element', async function (assert) {
    await render(
      <template>
        <Tooltip @delayDuration={{0}} as |t|>
          <span tabindex="0" {{t.trigger}}>
            <button type="button" disabled>Disabled</button>
          </span>
          <t.Content>This feature is currently unavailable</t.Content>
        </Tooltip>
      </template>,
    )
    const tooltip = new TooltipHarness()
    assert.dom(tooltip.trigger).hasTagName('span')
    await tooltip.hover()
    assert.true(tooltip.isOpen)
    assert.strictEqual(tooltip.text, 'This feature is currently unavailable')
    await a11yAudit()
  })
})

module('Integration | primitives | tooltip | placement, CSS anchor positioning', function (hooks) {
  setupRenderingTest(hooks)
  placementTests(hooks)
})

module('Integration | primitives | tooltip | placement, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)
  placementTests(hooks)
})
