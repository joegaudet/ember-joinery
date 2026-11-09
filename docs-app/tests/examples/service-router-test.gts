import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'

class CurrentPageHarness extends Harness {
  static component = 'current-page'

  get url() {
    return this.part('url').textContent!.trim()
  }
}

module('Example | service-router', function (hooks) {
  // The router has a URL once the app has routed, so this visits the page that shows it.
  setupApplicationTest(hooks)

  test('it shows the URL the router is on', async function (assert) {
    await visit('/primitives/service.md')
    await waitFor('[data-test-jn="current-page"]')
    assert.strictEqual(new CurrentPageHarness().url, '/primitives/service.md')
    await a11yAudit()
  })
})
