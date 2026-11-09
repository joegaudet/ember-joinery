import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { focus, render, settled, triggerEvent } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { dismissableBranch, dismissableLayers } from '@ember-joinery/primitives/dismiss'
import type { DismissReason } from '@ember-joinery/primitives/dismiss'
import { Portal } from '@ember-joinery/primitives/portal'
import { press, pressEscape, pressOutside } from '@ember-joinery/test-support'
import {
  FxLayeredPopover,
  FxLayeredPopoverHarness,
} from 'test-app/tests/fixtures/primitives/layered-popover'

class Outer extends FxLayeredPopoverHarness {
  static override named = 'outer'
}

class Inner extends FxLayeredPopoverHarness {
  static override named = 'inner'
}

/** Two popovers, the inner one opened from inside the outer one's content. */
const Nested = <template>
  <FxLayeredPopover @name="outer" as |outer|>
    <outer.Trigger>Outer</outer.Trigger>
    <outer.Content>
      <p data-test-outer-text>Outer content</p>
      <FxLayeredPopover @name="inner" as |inner|>
        <inner.Trigger>Inner</inner.Trigger>
        <inner.Content><p data-test-inner-text>Inner content</p></inner.Content>
      </FxLayeredPopover>
    </outer.Content>
  </FxLayeredPopover>
</template>

module('Integration | primitives | dismiss', function (hooks) {
  setupRenderingTest(hooks)

  test('Escape closes the top layer and cancels the keydown', async function (assert) {
    const reasons: DismissReason[] = []
    const onDismiss = (reason: DismissReason) => reasons.push(reason)
    await render(
      <template>
        <FxLayeredPopover @onDismiss={{onDismiss}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Hello</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()
    assert.true(popover.isOpen)

    let prevented: boolean | undefined
    const listen = (event: KeyboardEvent) => (prevented = event.defaultPrevented)
    document.addEventListener('keydown', listen)
    await pressEscape(popover.trigger)
    document.removeEventListener('keydown', listen)

    assert.false(popover.isOpen)
    assert.strictEqual(popover.content, null)
    assert.deepEqual(reasons, ['escape-key'])
    assert.true(prevented, 'so a <dialog> or popover underneath stays open')
    assert.deepEqual(dismissableLayers(), [], 'the stack is empty again')
    await a11yAudit()
  })

  test('Escape closes only the top layer, one at a time', async function (assert) {
    await render(Nested)
    const outer = new Outer()
    const inner = new Inner()
    await outer.open()
    await inner.open()
    assert.deepEqual(dismissableLayers(), [outer.content!, inner.content!], 'inner on top')

    await pressEscape(inner.trigger)
    assert.false(inner.isOpen, 'the inner layer closed')
    assert.true(outer.isOpen, 'the outer one stayed')

    await pressEscape(outer.trigger)
    assert.false(outer.isOpen)
    await a11yAudit()
  })

  test('the stack orders layers that open together by nesting', async function (assert) {
    // A nested element's modifiers install before its parent's.
    await render(
      <template>
        <FxLayeredPopover @name="outer" @defaultOpen={{true}} as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <FxLayeredPopover @name="inner" @defaultOpen={{true}} as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content>Inner content</inner.Content>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const outer = new Outer()
    const inner = new Inner()
    assert.deepEqual(dismissableLayers(), [outer.content!, inner.content!])

    await pressEscape(inner.content!)
    assert.false(inner.isOpen)
    assert.true(outer.isOpen)
    await a11yAudit()
  })

  test('onEscapeKeyDown can keep the layer, and nothing under it closes', async function (assert) {
    const keep = (event: KeyboardEvent) => event.preventDefault()
    await render(
      <template>
        <FxLayeredPopover @name="outer" as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <FxLayeredPopover @name="inner" @onEscapeKeyDown={{keep}} as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content>Inner content</inner.Content>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const outer = new Outer()
    const inner = new Inner()
    await outer.open()
    await inner.open()

    await pressEscape(inner.trigger)
    assert.true(inner.isOpen, 'kept')
    assert.true(outer.isOpen, 'the layer below never heard it')
    await a11yAudit()
  })

  test('a press outside closes it; a press inside or on the trigger does not', async function (assert) {
    const reasons: DismissReason[] = []
    const onDismiss = (reason: DismissReason) => reasons.push(reason)
    await render(
      <template>
        <button type="button" data-test-elsewhere>Elsewhere</button>
        <FxLayeredPopover @onDismiss={{onDismiss}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content><button type="button" data-test-inside>Inside</button></p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()

    await press(popover.content!.querySelector('[data-test-inside]')!)
    assert.true(popover.isOpen, 'a press inside keeps it')

    // The trigger counts as inside, so the press toggles it closed, and nothing reopens it.
    await press(popover.trigger)
    assert.false(popover.isOpen, 'the trigger closes it')
    assert.deepEqual(reasons, [], 'by toggling, not by dismissing')

    await popover.open()
    await pressOutside(document.querySelector('[data-test-elsewhere]')!)
    assert.false(popover.isOpen, 'a press outside closes it')
    assert.deepEqual(reasons, ['pointer-outside'])
    await a11yAudit()
  })

  test('a nested layer counts as inside the one it is in', async function (assert) {
    await render(Nested)
    const outer = new Outer()
    const inner = new Inner()
    await outer.open()
    await inner.open()

    await press(inner.content!.querySelector('[data-test-inner-text]')!)
    assert.true(inner.isOpen)
    assert.true(outer.isOpen, 'a press in the inner layer is inside the outer one')

    await press(outer.content!.querySelector('[data-test-outer-text]')!)
    assert.false(inner.isOpen, 'a press in the outer layer closes the inner one')
    assert.true(outer.isOpen)

    await inner.open()
    await pressOutside()
    assert.false(outer.isOpen, 'a press outside both closes both')
    assert.false(inner.exists, 'the inner one with it')
    await a11yAudit()
  })

  test('a nested layer rendered elsewhere still counts, through its trigger', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover @name="outer" as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <FxLayeredPopover @name="inner" as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <Portal>
                <inner.Content><p data-test-inner-text>Inner content</p></inner.Content>
              </Portal>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const outer = new Outer()
    const inner = new Inner()
    await outer.open()
    await inner.open()
    assert.strictEqual(inner.content!.parentElement, document.body, 'rendered at the end of body')

    await press(inner.content!.querySelector('[data-test-inner-text]')!)
    assert.true(outer.isOpen, 'still inside the outer layer')
    assert.true(inner.isOpen)

    await pressEscape(inner.content!)
    assert.false(inner.isOpen)
    assert.true(outer.isOpen)
    await a11yAudit()
  })

  test('onPointerDownOutside can keep the layer', async function (assert) {
    const keep = (event: Event) => event.preventDefault()
    await render(
      <template>
        <FxLayeredPopover @onPointerDownOutside={{keep}} as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Hello</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()
    await pressOutside()
    assert.true(popover.isOpen)
    await a11yAudit()
  })

  test('focus moving outside closes it; into a nested layer does not', async function (assert) {
    const reasons: DismissReason[] = []
    const onDismiss = (reason: DismissReason) => reasons.push(reason)
    await render(
      <template>
        <button type="button" data-test-elsewhere>Elsewhere</button>
        <FxLayeredPopover @name="outer" @onDismiss={{onDismiss}} as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <FxLayeredPopover @name="inner" as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content><button type="button" data-test-deep>Deep</button></inner.Content>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const outer = new Outer()
    const inner = new Inner()
    await outer.open()
    await inner.open()

    await focus(inner.content!.querySelector('[data-test-deep]')!)
    assert.true(outer.isOpen, 'focus in a nested layer is inside')

    await focus(document.querySelector('[data-test-elsewhere]')!)
    assert.false(outer.isOpen)
    assert.false(inner.exists, 'the inner one closed with it')
    assert.deepEqual(reasons, ['focus-outside'])
    await a11yAudit()
  })

  test('a modal layer turns pointers outside it off', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover @name="outer" as |outer|>
          <outer.Trigger>Outer</outer.Trigger>
          <outer.Content>
            <p data-test-outer-text>Outer content</p>
            <FxLayeredPopover @name="inner" @modal={{true}} as |inner|>
              <inner.Trigger>Inner</inner.Trigger>
              <inner.Content>Inner content</inner.Content>
            </FxLayeredPopover>
          </outer.Content>
        </FxLayeredPopover>
      </template>,
    )
    const outer = new Outer()
    const inner = new Inner()
    const before = document.body.style.pointerEvents
    await outer.open()
    await inner.open()

    assert.strictEqual(document.body.style.pointerEvents, 'none', 'the page ignores the pointer')
    assert.strictEqual(inner.content!.style.pointerEvents, 'auto', 'the modal layer takes it')
    assert.strictEqual(outer.content!.style.pointerEvents, 'none', 'the layer below does not')

    await pressOutside()
    assert.false(inner.isOpen, 'the modal layer closes')
    assert.true(outer.isOpen, 'the layer below it never heard the press')
    assert.strictEqual(document.body.style.pointerEvents, before, 'put back')
    assert.strictEqual(outer.content!.style.pointerEvents, '', 'put back')
    await a11yAudit()
  })

  test('events from before the layer opened are ignored', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Hello</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    // Made before the popover opens, as the press that opens a layer is.
    const early = new PointerEvent('pointerdown', { bubbles: true, pointerType: 'mouse' })
    await popover.open()
    document.body.dispatchEvent(early)
    await settled()
    assert.true(popover.isOpen)
    await a11yAudit()
  })

  test('a touch outside waits for its click', async function (assert) {
    await render(
      <template>
        <FxLayeredPopover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Hello</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()

    await triggerEvent(document.body, 'pointerdown', { pointerType: 'touch' })
    assert.true(popover.isOpen, 'a finger going down to scroll closes nothing')

    await pressOutside(undefined, { pointerType: 'touch' })
    assert.false(popover.isOpen, 'a tap does')
    await a11yAudit()
  })

  test('a branch counts as inside every layer', async function (assert) {
    await render(
      <template>
        <ol {{dismissableBranch}}><li data-test-toast>A toast</li></ol>
        <FxLayeredPopover as |p|>
          <p.Trigger>Open</p.Trigger>
          <p.Content>Hello</p.Content>
        </FxLayeredPopover>
      </template>,
    )
    const popover = new FxLayeredPopoverHarness()
    await popover.open()
    await press(document.querySelector('[data-test-toast]')!)
    assert.true(popover.isOpen)
    await a11yAudit()
  })
})
