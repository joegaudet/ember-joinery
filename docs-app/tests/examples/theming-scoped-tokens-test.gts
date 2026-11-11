import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BadgeHarness, ButtonHarness, CardHarness } from '@ember-joinery/test-support'
import ThemingScopedTokens from 'docs-app/examples/theming-scoped-tokens'

module('Example | theming-scoped-tokens', function (hooks) {
  setupRenderingTest(hooks)

  test('tokens set on one card reach every component inside it, and no further', async function (assert) {
    await render(<template><ThemingScopedTokens /></template>)
    const [plain, blue] = CardHarness.findAll()
    assert.strictEqual(plain!.title, 'Default')
    assert.strictEqual(blue!.title, 'Blue')

    const background = (element: Element) => getComputedStyle(element).backgroundColor
    const blueSave = blue!.find(ButtonHarness)
    const plainSave = plain!.find(ButtonHarness)
    assert.strictEqual(background(blueSave.element), 'oklch(0.488 0.243 264.376)', 'its --primary')
    assert.notStrictEqual(background(plainSave.element), background(blueSave.element))
    assert.strictEqual(
      background(blue!.find(BadgeHarness).element),
      'oklch(0.488 0.243 264.376)',
      'the badge takes it too',
    )

    const radius = (card: CardHarness) =>
      parseFloat(getComputedStyle(card.element).borderTopLeftRadius)
    assert.true(radius(blue!) > radius(plain!), 'and its --radius rounds it more')
    await a11yAudit()
  })
})
