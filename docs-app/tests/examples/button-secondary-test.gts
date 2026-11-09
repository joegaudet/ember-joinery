import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonSecondary from 'docs-app/examples/button-secondary'

module('Example | button-secondary', function (hooks) {
  setupRenderingTest(hooks)

  test('a secondary button', async function (assert) {
    await render(<template><ButtonSecondary /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'secondary')
    assert.strictEqual(button.size, 'default')
    assert.strictEqual(button.label, 'Secondary')
    assert.dom(button.element).hasTagName('button')
    await a11yAudit()
  })
})
