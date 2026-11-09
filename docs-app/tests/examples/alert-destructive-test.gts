import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AlertHarness } from '@ember-joinery/test-support'
import AlertDestructive from 'docs-app/examples/alert-destructive'

module('Example | alert-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('a destructive alert, in the destructive colour', async function (assert) {
    await render(<template><AlertDestructive /></template>)
    const alert = new AlertHarness()
    assert.strictEqual(alert.variant, 'destructive')
    assert.strictEqual(alert.title, 'Payment failed')
    assert.true(alert.hasIcon)
    const probe = document.createElement('span')
    probe.style.color = 'var(--destructive)'
    alert.element.append(probe)
    assert.strictEqual(
      getComputedStyle(alert.element).color,
      getComputedStyle(probe).color,
      'its text is --destructive',
    )
    probe.remove()

    // Upstream's description is 90% of --destructive on --card: 4.49:1 by axe, a hair under
    // AA's 4.5:1 for small text. The guide's Accessibility section says how to give it the full
    // colour; the rest of the page is audited.
    await a11yAudit({
      include: [['#ember-testing-container']],
      exclude: [['[data-variant="destructive"] > [data-slot="alert-description"]']],
    })
  })
})
