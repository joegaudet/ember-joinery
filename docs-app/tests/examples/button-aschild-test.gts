import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { getRootElement, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness } from '@ember-joinery/test-support'
import ButtonAsChild from 'docs-app/examples/button-aschild'

module('Example | button-aschild', function (hooks) {
  setupRenderingTest(hooks)

  test('a link that looks like a button', async function (assert) {
    await render(<template><ButtonAsChild /></template>)
    const login = new ButtonHarness()
    assert.dom(login.element).hasTagName('a').hasAttribute('href', '/login')
    assert.strictEqual(login.label, 'Login')
    assert.strictEqual(getRootElement().textContent!.trim(), 'Login', 'the link and nothing else')
    assert.strictEqual(login.variant, 'default')
    assert.strictEqual(getComputedStyle(login.element).display, 'inline-flex', 'styled as a button')
    await a11yAudit()
  })
})
