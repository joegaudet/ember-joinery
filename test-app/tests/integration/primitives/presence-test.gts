import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { find, render, rerender, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { part } from '@ember-joinery/primitives/part'
import { Presence } from '@ember-joinery/primitives/presence'
import {
  FxPrimitiveDisclosure,
  FxPrimitiveDisclosureHarness,
} from 'test-app/tests/fixtures/primitives/disclosure'

/** Enter and exit animations keyed off data-state, as shadcn's styles do. */
const Animations = <template>
  <style>
    @keyframes test-enter {
      from {
        opacity: 0;
      }
      to {
        opacity: 1;
      }
    }
    @keyframes test-exit {
      from {
        opacity: 1;
      }
      to {
        opacity: 0;
      }
    }
    .animated[data-state="open"] {
      animation: test-enter 40ms;
    }
    .animated[data-state="closed"] {
      animation: test-exit 150ms;
    }
    .same[data-state] {
      animation: test-enter 150ms;
    }
    .hidden-when-closed[data-state="closed"] {
      display: none;
      animation: test-exit 150ms;
    }
  </style>
</template>

class State {
  @tracked open = true
}

const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

module('Integration | primitives | presence', function (hooks) {
  setupRenderingTest(hooks)

  test('without an exit animation, the content goes at once', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Presence @present={{state.open}} as |presence|>
          <div id="content" {{presence.ref}} data-state={{if state.open "open" "closed"}}>Hi</div>
        </Presence>
      </template>,
    )
    assert.dom('#content').exists()

    state.open = false
    await settled()
    assert.dom('#content').doesNotExist()

    state.open = true
    await settled()
    assert.dom('#content').exists('it comes back')
    await a11yAudit()
  })

  test('it keeps the content through its exit animation', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}} as |presence|>
          <div
            id="content"
            class="animated"
            {{presence.ref}}
            data-state={{if state.open "open" "closed"}}
          >Hi</div>
        </Presence>
      </template>,
    )
    await wait(60)

    state.open = false
    const closed = performance.now()
    await rerender()
    assert.dom('#content').exists('still rendered while it animates out')
    assert.dom('#content').hasAttribute('data-state', 'closed')

    await settled()
    assert.dom('#content').doesNotExist('gone once the animation ends')
    const elapsed = performance.now() - closed
    assert.true(elapsed >= 140, `it waited for the 150ms animation (${Math.round(elapsed)}ms)`)
    await a11yAudit()
  })

  test('ref can come before the modifier that sets data-state', async function (assert) {
    const state = new State()
    // A part modifier sets data-state, as Joinery's components do, after ref in template order.
    const content = part(() => ({ attributes: { 'data-state': state.open ? 'open' : 'closed' } }))
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}} as |presence|>
          <div id="content" class="animated" {{presence.ref}} {{content}}>Hi</div>
        </Presence>
      </template>,
    )
    await wait(60)

    state.open = false
    const closed = performance.now()
    await rerender()
    assert.dom('#content').exists('still rendered while it animates out')

    await settled()
    assert.dom('#content').doesNotExist()
    const elapsed = performance.now() - closed
    assert.true(elapsed >= 140, `it waited for the 150ms animation (${Math.round(elapsed)}ms)`)

    state.open = true
    await settled()
    await wait(60)
    state.open = false
    await rerender()
    assert.dom('#content').exists('reopened and closed again, it waits again')
    await settled()
    assert.dom('#content').doesNotExist()
    await a11yAudit()
  })

  test('opening again during the exit keeps the content', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}} as |presence|>
          <div
            id="content"
            class="animated"
            {{presence.ref}}
            data-state={{if state.open "open" "closed"}}
          >Hi</div>
        </Presence>
      </template>,
    )
    await wait(60)
    state.open = false
    await rerender()
    const element = find('#content')

    state.open = true
    await settled()
    await wait(200)
    await settled()
    assert.dom('#content').exists('the cancelled exit removed nothing')
    assert.strictEqual(find('#content'), element, 'and the element was kept, not re-made')
    assert.dom('#content').hasAttribute('data-state', 'open')
    await a11yAudit()
  })

  test('the same animation open and closed is not an exit animation', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}} as |presence|>
          <div
            id="content"
            class="same"
            {{presence.ref}}
            data-state={{if state.open "open" "closed"}}
          >Hi</div>
        </Presence>
      </template>,
    )
    state.open = false
    await rerender()
    await Promise.resolve()
    await rerender()
    assert.dom('#content').doesNotExist('removed in the same task')
    await a11yAudit()
  })

  test('hidden content is removed without waiting', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}} as |presence|>
          <div
            id="content"
            class="hidden-when-closed"
            {{presence.ref}}
            data-state={{if state.open "open" "closed"}}
          >Hi</div>
        </Presence>
      </template>,
    )
    state.open = false
    await rerender()
    await Promise.resolve()
    await rerender()
    assert.dom('#content').doesNotExist()
    await a11yAudit()
  })

  test('without a ref there is nothing to wait for', async function (assert) {
    const state = new State()
    await render(
      <template>
        <Animations />
        <Presence @present={{state.open}}>
          <div id="content" class="animated" data-state={{if state.open "open" "closed"}}>Hi</div>
        </Presence>
      </template>,
    )
    state.open = false
    await rerender()
    assert.dom('#content').doesNotExist()
    await a11yAudit()
  })

  test('@forceMount keeps it rendered, and it starts absent when not present', async function (assert) {
    const state = new State()
    state.open = false
    await render(
      <template>
        <Presence @present={{state.open}} as |presence|>
          <p id="lazy" {{presence.ref}}>Lazy {{if presence.isPresent "shown" "leaving"}}</p>
        </Presence>
        <Presence @present={{state.open}} @forceMount={{true}} as |presence|>
          <p id="forced" {{presence.ref}} hidden={{if presence.isPresent false true}}>Forced</p>
        </Presence>
      </template>,
    )
    assert.dom('#lazy').doesNotExist('not rendered until present')
    assert.dom('#forced').exists().isNotVisible()

    state.open = true
    await settled()
    assert.dom('#lazy').hasText('Lazy shown')
    assert.dom('#forced').isVisible()

    state.open = false
    await settled()
    assert.dom('#lazy').doesNotExist()
    assert.dom('#forced').exists('force-mounted content stays')
    await a11yAudit()
  })

  test('a component part animates out through Presence', async function (assert) {
    await render(
      <template>
        <Animations />
        <FxPrimitiveDisclosure @defaultOpen={{true}} as |d|>
          <d.Trigger>Details</d.Trigger>
          <d.Content class="animated">The details.</d.Content>
        </FxPrimitiveDisclosure>
      </template>,
    )
    const disclosure = new FxPrimitiveDisclosureHarness()
    assert.dom(disclosure.content).hasAttribute('data-state', 'open')
    await wait(60)

    await disclosure.toggle()
    assert.false(disclosure.isOpen)
    assert.strictEqual(disclosure.content, null, 'the harness waited for the exit animation')
    await a11yAudit()
  })
})
