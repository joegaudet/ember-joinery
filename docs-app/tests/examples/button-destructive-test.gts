import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonDestructive from 'docs-app/examples/button-destructive'

module('Example | button-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('a destructive button', async function (assert) {
    await render(<template><ButtonDestructive /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'destructive')
    assert.strictEqual(button.size, 'default')
    assert.strictEqual(button.label, 'Destructive')
    assert.dom(button.element).hasTagName('button')
    await a11yAudit()
  })
})
