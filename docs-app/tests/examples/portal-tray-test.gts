import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import PortalTray from 'docs-app/examples/portal-tray'

/** The example's card. Its note renders in the tray, and the harness follows it there. */
class CardHarness extends Harness {
  static component = 'card'

  get note() {
    return this.part('note')
  }
}

module('Example | portal-tray', function (hooks) {
  setupRenderingTest(hooks)

  test('the card’s note renders in the tray, and is still the card’s', async function (assert) {
    await render(<template><PortalTray /></template>)
    const card = new CardHarness()

    assert.dom(card.note).hasText('A note from the card.', 'found through its owner')
    assert.false(card.element.contains(card.note), 'not inside the card')
    assert.dom(card.note.closest('[aria-label="Tray"]')).exists('but in the tray')
    await a11yAudit()
  })
})
