import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HoverCard } from '@ember-joinery/primitives/hover-card'
import {
  HoverCardHarness,
  placementOf,
  setupAnchorFallback,
  type TestHooks,
} from '@ember-joinery/test-support'

/** Fixed sizes, and none of the browser's popover border or padding, so edges line up. */
const Styles = <template>
  <style>
    .hc-stage {
      position: fixed;
      top: 200px;
      left: 300px;
    }
    .hc-trigger {
      display: inline-block;
      width: 60px;
      height: 20px;
    }
    .hc-content {
      width: 120px;
      height: 60px;
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

function placementTests(hooks: TestHooks) {
  void hooks

  test('it goes below its trigger by default, and on the side asked for', async function (assert) {
    await render(
      <template>
        <Styles />
        <div class="hc-stage">
          <HoverCard @defaultOpen={{true}} as |h|>
            <h.Trigger href="#nextjs" class="hc-trigger">@nextjs</h.Trigger>
            <h.Content class="hc-content">The React Framework</h.Content>
          </HoverCard>
        </div>
      </template>,
    )
    const card = new HoverCardHarness()
    near(assert, rect(card.content!).top, rect(card.trigger).bottom, 'below, touching it')
    assert.deepEqual(placementOf(card.content!), { side: 'bottom', align: 'center' })

    await render(
      <template>
        <Styles />
        <div class="hc-stage">
          <HoverCard @defaultOpen={{true}} as |h|>
            <h.Trigger href="#nextjs" class="hc-trigger">@nextjs</h.Trigger>
            <h.Content class="hc-content" @side="top" @align="start" @sideOffset={{4}}>
              The React Framework
            </h.Content>
          </HoverCard>
        </div>
      </template>,
    )
    near(assert, rect(card.content!).bottom, rect(card.trigger).top - 4, 'above, 4px off')
    near(assert, rect(card.content!).left, rect(card.trigger).left, 'at the start')
    await a11yAudit()
  })
}

module('Integration | primitives | hover-card', function (hooks) {
  setupRenderingTest(hooks)

  test('resting the pointer on the trigger opens it after the open delay; leaving closes it after the close delay', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{40}} @closeDelay={{40}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>
            The React Framework – created and maintained by
            <a href="#vercel">@vercel</a>.
          </h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    assert
      .dom(card.trigger)
      .hasTagName('a', 'an <a>, as Radix’s')
      .hasAttribute('data-state', 'closed')
    assert.false(card.isOpen)

    let started = performance.now()
    await card.hover()
    assert.true(performance.now() - started >= 35, 'it waited for the open delay')
    assert.true(card.isOpen)
    assert.true(card.isShown, 'in the top layer')
    assert.dom(card.content).hasAttribute('data-state', 'open').doesNotHaveAttribute('role')
    assert
      .dom('a', card.content!)
      .hasAttribute('tabindex', '-1', 'its links are out of the tab order')
    assert.ok(
      card.content!.style.getPropertyValue('--radix-hover-card-content-transform-origin'),
      'Radix’s custom properties, for upstream’s classes',
    )
    await a11yAudit()

    started = performance.now()
    await card.unhover()
    assert.true(performance.now() - started >= 35, 'it waited for the close delay')
    assert.false(card.isOpen)
    assert.strictEqual(card.content, null)
    await a11yAudit()
  })

  test('the pointer can move onto the card, and leaving it closes it', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{0}} @closeDelay={{50}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    await card.hover()
    await card.hoverContent()
    assert.true(card.isOpen, 'on the card, it stays open')
    await card.unhoverContent()
    assert.false(card.isOpen, 'off it, it closes')
    await a11yAudit()
  })

  test('focus opens it and blur closes it; Escape and a press outside close it at once', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{0}} @closeDelay={{0}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    await card.focus()
    assert.true(card.isOpen, 'focus opens it')
    await card.blur()
    assert.false(card.isOpen, 'blur closes it')

    await card.focus()
    await card.pressEscape()
    assert.false(card.isOpen, 'Escape')

    await card.hover()
    assert.true(card.isOpen)
    await card.pressOutside()
    assert.false(card.isOpen, 'a press outside')
    await a11yAudit()
  })

  test('a touch doesn’t open it', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{0}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    await card.hover({ pointerType: 'touch' })
    assert.false(card.isOpen)
    await a11yAudit()
  })

  test('its state can be controlled', async function (assert) {
    const state = new State()
    await render(
      <template>
        <HoverCard @open={{state.open}} @onOpenChange={{state.setOpen}} @openDelay={{0}} as |h|>
          <h.Trigger href="#nextjs">@nextjs</h.Trigger>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    await card.hover()
    assert.deepEqual(state.changes, [true])
    assert.true(card.isOpen)
    state.open = false
    await settled()
    assert.false(card.isOpen)
    await a11yAudit()
  })

  test('the trigger can be your own element', async function (assert) {
    await render(
      <template>
        <HoverCard @openDelay={{0}} as |h|>
          <button type="button" {{h.trigger}}>Hover Here</button>
          <h.Content>The React Framework</h.Content>
        </HoverCard>
      </template>,
    )
    const card = new HoverCardHarness()
    assert.dom(card.trigger).hasTagName('button')
    await card.hover()
    assert.true(card.isOpen)
    assert.strictEqual(card.text, 'The React Framework')
    await a11yAudit()
  })
})

module(
  'Integration | primitives | hover-card | placement, CSS anchor positioning',
  function (hooks) {
    setupRenderingTest(hooks)
    placementTests(hooks)
  },
)

module('Integration | primitives | hover-card | placement, Floating UI', function (hooks) {
  setupRenderingTest(hooks)
  setupAnchorFallback(hooks)
  placementTests(hooks)
})
