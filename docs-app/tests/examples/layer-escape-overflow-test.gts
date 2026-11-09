import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, isInTopLayer, placementOf, pressOutside } from '@ember-joinery/test-support'
import LayerEscapeOverflow from 'docs-app/examples/layer-escape-overflow'

/** The example's card, the button in it, and the popover the button opens. */
class ClippingCardHarness extends Harness {
  static component = 'clipping-card'

  get trigger() {
    return this.part('trigger')
  }

  /** The popover, or `null` while it is closed. */
  get popover() {
    return this.queryPart('popover')
  }

  get isOpen() {
    return this.trigger.getAttribute('aria-expanded') === 'true'
  }

  async toggle() {
    await click(this.trigger)
  }
}

module('Example | layer-escape-overflow', function (hooks) {
  setupRenderingTest(hooks)

  test('the popover shows above the card that would clip it', async function (assert) {
    await render(<template><LayerEscapeOverflow /></template>)
    const card = new ClippingCardHarness()
    assert.strictEqual(card.popover, null)

    await card.toggle()
    const popover = card.popover!
    assert.true(isInTopLayer(popover), 'in the top layer')
    assert.true(
      popover.getBoundingClientRect().bottom > card.element.getBoundingClientRect().bottom,
      'it reaches past the bottom of the card, unclipped',
    )
    assert.strictEqual(placementOf(popover).side, 'bottom', 'below its button')

    await pressOutside()
    assert.false(card.isOpen, 'a press outside closes it')
    await a11yAudit()
  })
})
