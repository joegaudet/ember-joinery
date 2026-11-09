import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { HoverCardHarness } from '@ember-joinery/test-support'
import HoverCardSides from 'docs-app/examples/hover-card-sides'

module('Example | hover-card-sides', function (hooks) {
  setupRenderingTest(hooks)

  test('each button’s card opens on the side it names', async function (assert) {
    await render(<template><HoverCardSides /></template>)
    const cards = HoverCardHarness.findAll()
    assert.deepEqual(
      cards.map(card => card.trigger.textContent?.trim()),
      ['left', 'top', 'bottom', 'right'],
    )

    for (const card of cards) {
      const side = card.trigger.textContent!.trim()
      await card.hover()
      assert.true(card.isOpen)
      assert.strictEqual(
        card.text,
        `Hover Card This hover card appears on the ${side} side of the trigger.`,
      )
      const opposite = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }[side]
      assert.true([side, opposite].includes(card.side!), `${side}: placed on ${card.side}`)
      await a11yAudit()
      await card.unhover()
      assert.false(card.isOpen)
    }
  })
})
