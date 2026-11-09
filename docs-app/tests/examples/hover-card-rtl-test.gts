import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { HoverCardHarness } from '@ember-joinery/test-support'
import HoverCardRtl from 'docs-app/examples/hover-card-rtl'

module('Example | hover-card-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left, each card opens on its own physical side, in Arabic', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><HoverCardRtl /></DirectionProvider>
      </template>,
    )
    const cards = HoverCardHarness.findAll()
    assert.deepEqual(
      cards.map(card => card.trigger.textContent?.trim()),
      ['يسار', 'أعلى', 'أسفل', 'يمين'],
    )
    const sides = ['left', 'top', 'bottom', 'right']
    for (const [index, card] of cards.entries()) {
      await card.hover()
      assert.strictEqual(card.text, 'سماعات لاسلكية ٩٩.٩٩ $')
      assert.dom(card.content).hasAttribute('dir', 'rtl')
      const side = sides[index]!
      const opposite = { left: 'right', right: 'left', top: 'bottom', bottom: 'top' }[side]
      assert.true([side, opposite].includes(card.side!), `${side}: placed on ${card.side}`)
      await a11yAudit()
      await card.unhover()
    }
  })
})
