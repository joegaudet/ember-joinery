import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CardHarness } from '@ember-joinery/test-support'
import CardSmall from 'docs-app/examples/card-small'

module('Example | card-small', function (hooks) {
  setupRenderingTest(hooks)

  test('a small card, with tighter spacing and a full-width button', async function (assert) {
    await render(<template><CardSmall /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.size, 'sm')
    assert.strictEqual(card.title, 'Small Card')
    assert.strictEqual(card.description, 'This card uses the small size variant.')
    assert.strictEqual(getComputedStyle(card.element).paddingTop, '12px', 'the sm spacing')
    assert.strictEqual(getComputedStyle(card.part('title')).fontSize, '14px')

    const action = card.find(ButtonHarness)
    assert.strictEqual(action.label, 'Action')
    assert.strictEqual(action.variant, 'outline')
    assert.strictEqual(action.size, 'sm')
    assert.strictEqual(
      action.element.offsetWidth,
      card.footer.clientWidth - 24,
      'w-full, inside the footer',
    )
    await a11yAudit()
  })
})
