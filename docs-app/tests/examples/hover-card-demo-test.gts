import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, HoverCardHarness } from '@ember-joinery/test-support'
import HoverCardDemo from 'docs-app/examples/hover-card-demo'

module('Example | hover-card-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('resting the pointer on the link shows the card, and moving away hides it', async function (assert) {
    await render(<template><HoverCardDemo /></template>)
    const card = new HoverCardHarness()
    const button = new ButtonHarness()
    assert.strictEqual(card.trigger, button.element)
    assert.strictEqual(button.variant, 'link')

    await card.hover()
    assert.true(card.isOpen)
    assert.strictEqual(
      card.text,
      '@nextjs The React Framework – created and maintained by @vercel. Joined December 2021',
    )
    for (const animation of card.content!.getAnimations()) animation.finish()
    assert.strictEqual(getComputedStyle(card.content!).width, '256px', 'w-64')
    assert.strictEqual(getComputedStyle(card.content!).flexDirection, 'column')
    assert.strictEqual(card.side, 'bottom')
    await a11yAudit()

    await card.hoverContent()
    assert.true(card.isOpen, 'the pointer can move onto the card')
    await card.unhoverContent()
    assert.false(card.isOpen)
    await a11yAudit()
  })
})
