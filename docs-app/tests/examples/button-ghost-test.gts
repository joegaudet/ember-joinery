import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonGhost from 'docs-app/examples/button-ghost'

module('Example | button-ghost', function (hooks) {
  setupRenderingTest(hooks)

  test('a ghost button', async function (assert) {
    await render(<template><ButtonGhost /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'ghost')
    assert.strictEqual(button.size, 'default')
    assert.strictEqual(button.label, 'Ghost')
    assert.dom(button.element).hasTagName('button')
    await a11yAudit()
  })
})
