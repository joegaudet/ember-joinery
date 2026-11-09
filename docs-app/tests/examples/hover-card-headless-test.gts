import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HoverCardHarness } from '@ember-joinery/test-support'
import HoverCardHeadless from 'docs-app/examples/hover-card-headless'

module('Example | hover-card-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a card of your own on a link in a sentence, opened by focus too', async function (assert) {
    await render(<template><HoverCardHeadless /></template>)
    const card = new HoverCardHarness()
    assert.dom(card.trigger).hasTagName('a').hasAttribute('href', 'https://ui.shadcn.com/')

    await card.focus()
    assert.true(card.isOpen)
    assert.strictEqual(card.side, 'top')
    assert.strictEqual(
      card.text,
      'Beautifully designed components, built with Radix UI and Tailwind CSS.',
    )
    await card.blur()
    assert.false(card.isOpen)
    await a11yAudit()
  })
})
