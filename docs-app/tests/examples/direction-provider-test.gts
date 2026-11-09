import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, child } from '@ember-joinery/test-support'
import DirectionProviderExample from 'docs-app/examples/direction-provider'

/**
 * The card inside the provider. The provider wraps content and has no harness of its own, so
 * the test reads the direction where it matters: in the content.
 */
class DirectionCardHarness extends Harness {
  static component = 'direction-card'

  /** The direction the browser lays the card out in. */
  get layout() {
    return getComputedStyle(this.element).direction
  }

  /** Presses the card's button, which reads the direction with getDirection(). */
  async readDirection() {
    await click(this.part('read'))
    return this.part('result').textContent!.replace('getDirection() →', '').trim()
  }
}

class DirectionExampleHarness extends Harness {
  static component = 'direction-example'

  @child(DirectionCardHarness) declare card: DirectionCardHarness

  async switchDirection() {
    await click(this.part('switch'))
  }
}

module('Example | direction-provider', function (hooks) {
  setupRenderingTest(hooks)

  test('content inside reads the provider’s direction from the document', async function (assert) {
    await render(<template><DirectionProviderExample /></template>)
    const example = new DirectionExampleHarness()
    assert.strictEqual(example.card.layout, 'rtl')
    assert.strictEqual(await example.card.readDirection(), 'rtl')

    await example.switchDirection()
    assert.strictEqual(example.card.layout, 'ltr')
    assert.strictEqual(await example.card.readDirection(), 'ltr')
    await a11yAudit()
  })
})
