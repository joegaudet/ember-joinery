import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import HideOthersSpotlight from 'docs-app/examples/hide-others-spotlight'

class SpotlightHarness extends Harness {
  static override component = 'spotlight'

  card(name: string) {
    return this.part('card', name)
  }

  async press(name: string) {
    await click(this.card(name).querySelector('button')!)
  }
}

module('Example | hide-others-spotlight', function (hooks) {
  setupRenderingTest(hooks)

  test('the spotlit card is the only thing left to use', async function (assert) {
    await render(<template><HideOthersSpotlight /></template>)
    const spotlight = new SpotlightHarness()
    await spotlight.press('Billing')

    assert.dom(spotlight.card('Profile')).hasAttribute('inert')
    assert.dom(spotlight.card('Security')).hasAttribute('inert')
    assert.dom(spotlight.card('Billing')).doesNotHaveAttribute('inert')
    await a11yAudit()

    await spotlight.press('Billing')
    assert.dom(spotlight.card('Profile')).doesNotHaveAttribute('inert', 'Done puts it back')
    await a11yAudit()
  })
})
