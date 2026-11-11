import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LinkHarness } from '@ember-joinery/test-support'

module('Example | link-demo', function (hooks) {
  // A Link reads the router, so this visits the page the example is on.
  setupApplicationTest(hooks)

  test('a link to another origin is external, and says so', async function (assert) {
    await visit('/primitives/link.md')
    await waitFor('[data-test-example="link-demo"] [data-test-jn="link"]')
    const example = document.querySelector('[data-test-example="link-demo"]')!
    const [home, mdn] = LinkHarness.findAll().filter(link => example.contains(link.element))

    assert.strictEqual(home!.text, 'Home')
    assert.false(home!.opensInNewTab)
    assert.strictEqual(mdn!.text, 'MDN ➚', 'it yields isExternal')
    assert.true(mdn!.opensInNewTab && mdn!.isIsolated)
    await a11yAudit()
  })
})
