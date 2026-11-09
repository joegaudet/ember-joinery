import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'
import ButtonIcon from 'docs-app/examples/button-icon'

module('Example | button-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('a square outline button with only an icon', async function (assert) {
    await render(<template><ButtonIcon /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.size, 'icon')
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(button.label, 'Upgrade')
    assert.true(button.find(IconHarness).exists)
    assert.strictEqual(getComputedStyle(button.element).width, '32px')
    await a11yAudit()
  })
})
