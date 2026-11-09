import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonOutline from 'docs-app/examples/button-outline'

module('Example | button-outline', function (hooks) {
  setupRenderingTest(hooks)

  test('a outline button', async function (assert) {
    await render(<template><ButtonOutline /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'outline')
    assert.strictEqual(button.size, 'default')
    assert.strictEqual(button.label, 'Outline')
    assert.dom(button.element).hasTagName('button')
    await a11yAudit()
  })
})
