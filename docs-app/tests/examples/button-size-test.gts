import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonSize from 'docs-app/examples/button-size'

module('Example | button-size', function (hooks) {
  setupRenderingTest(hooks)

  test('each size, with its square icon size beside it', async function (assert) {
    await render(<template><ButtonSize /></template>)
    const buttons = ButtonHarness.findAll()
    assert.deepEqual(
      buttons.map(button => button.size),
      ['xs', 'icon-xs', 'sm', 'icon-sm', 'default', 'icon', 'lg', 'icon-lg'],
    )
    assert.deepEqual(
      buttons.filter((_, index) => index % 2 === 0).map(button => button.label),
      ['Extra Small', 'Small', 'Default', 'Large'],
    )
    const heights = buttons.map(button => getComputedStyle(button.element).height)
    assert.deepEqual(heights, ['24px', '24px', '28px', '28px', '32px', '32px', '36px', '36px'])
    // The small sizes round to min(var(--radius-md), …): 0.8 of the theme's 10px radius.
    const radii = buttons.map(button => getComputedStyle(button.element).borderTopLeftRadius)
    assert.deepEqual(radii, ['8px', '8px', '8px', '8px', '10px', '10px', '10px', '10px'])
    for (const icon of buttons.filter((_, index) => index % 2 === 1)) {
      assert.strictEqual(icon.label, 'Submit')
      assert.strictEqual(
        getComputedStyle(icon.element).width,
        getComputedStyle(icon.element).height,
        `${icon.size} is square`,
      )
    }
    await a11yAudit()
  })
})
