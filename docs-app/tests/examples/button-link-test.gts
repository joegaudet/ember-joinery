import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonLink from 'docs-app/examples/button-link'

module('Example | button-link', function (hooks) {
  setupRenderingTest(hooks)

  test('a link button', async function (assert) {
    await render(<template><ButtonLink /></template>)
    const button = new ButtonHarness()
    assert.strictEqual(button.variant, 'link')
    assert.strictEqual(button.size, 'default')
    assert.strictEqual(button.label, 'Link')
    assert.dom(button.element).hasTagName('button')
    await a11yAudit()
  })
})
