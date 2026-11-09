import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertHarness } from '@ember-joinery/test-support'
import AlertColors from 'docs-app/examples/alert-colors'

module('Example | alert-colors', function (hooks) {
  setupRenderingTest(hooks)

  test('utility classes give it amber colours, over its own', async function (assert) {
    await render(<template><AlertColors /></template>)
    const alert = new AlertHarness()
    assert.strictEqual(alert.title, 'Your subscription will expire in 3 days.')
    assert.strictEqual(alert.variant, 'default')
    const probe = document.createElement('span')
    probe.className = 'bg-amber-50 text-amber-900 border-amber-200'
    alert.element.append(probe)
    const amber = getComputedStyle(probe)
    const style = getComputedStyle(alert.element)
    assert.strictEqual(style.backgroundColor, amber.backgroundColor, 'bg-amber-50 wins')
    assert.strictEqual(style.color, amber.color, 'text-amber-900 wins')
    assert.strictEqual(style.borderTopColor, amber.borderTopColor, 'border-amber-200 wins')
    probe.remove()
    await a11yAudit()
  })
})
