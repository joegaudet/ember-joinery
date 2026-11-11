import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, child } from '@ember-joinery/test-support'
import ControllableStateDisclosure from 'docs-app/examples/controllable-state-disclosure'

/** One disclosure: its state is read from `aria-expanded`, as a screen reader reads it. */
class DisclosureHarness extends Harness {
  static component = 'disclosure'

  get trigger() {
    return this.part('trigger')
  }

  get isOpen() {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle() {
    await click(this.trigger)
  }
}

/** The whole example, as a page object: two disclosures, and the parent's own controls. */
class ExampleHarness extends Harness {
  static component = 'controllable-state-example'

  @child(DisclosureHarness, 'uncontrolled') declare uncontrolled: DisclosureHarness
  @child(DisclosureHarness, 'controlled') declare controlled: DisclosureHarness

  /** What the parent says the controlled one is: `open` or `closed`. */
  get parentState() {
    return this.part('state').textContent!.trim()
  }

  async closeFromOutside() {
    await click(this.part('close'))
  }
}

module('Example | controllable-state-disclosure', function (hooks) {
  setupRenderingTest(hooks)

  test('one disclosure keeps its own state, the other its parent’s', async function (assert) {
    await render(<template><ControllableStateDisclosure /></template>)
    const example = new ExampleHarness()

    assert.true(example.uncontrolled.isOpen, '@defaultOpen starts it open')
    await example.uncontrolled.toggle()
    assert.false(example.uncontrolled.isOpen, 'it changes itself')

    assert.false(example.controlled.isOpen)
    await example.controlled.toggle()
    assert.true(example.controlled.isOpen, 'the parent took the change')
    assert.strictEqual(example.parentState, 'open')

    await example.closeFromOutside()
    assert.false(example.controlled.isOpen, 'and the parent can close it')
    assert.strictEqual(example.parentState, 'closed')
    await a11yAudit()
  })
})
