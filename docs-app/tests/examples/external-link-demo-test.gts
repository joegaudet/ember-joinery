import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ExternalLinkHarness } from '@ember-joinery/test-support'
import ExternalLinkDemo from 'docs-app/examples/external-link-demo'

module('Example | external-link-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens a new tab, and tells MDN nothing about this page', async function (assert) {
    await render(<template><ExternalLinkDemo /></template>)
    const mdn = new ExternalLinkHarness()
    assert.strictEqual(mdn.href, 'https://developer.mozilla.org')
    assert.strictEqual(mdn.text, 'MDN ➚')
    assert.true(mdn.opensInNewTab)
    assert.true(mdn.isIsolated)
    await a11yAudit()
  })
})
