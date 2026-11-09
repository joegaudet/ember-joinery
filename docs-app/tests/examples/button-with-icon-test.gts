import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, IconHarness } from '@ember-joinery/test-support'
import ButtonWithIcon from 'docs-app/examples/button-with-icon'

module('Example | button-with-icon', function (hooks) {
  setupRenderingTest(hooks)

  test('a small button with an icon before its text', async function (assert) {
    await render(<template><ButtonWithIcon /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.label, 'New Branch')
    assert.strictEqual(button.size, 'sm')
    const icon = button.find(IconHarness)
    assert.true(icon.isDecorative)
    assert.strictEqual(getComputedStyle(icon.element).width, '14px', 'size-3.5 in a small button')
    await a11yAudit()
  })
})
