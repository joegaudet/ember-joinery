import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { click, currentURL, visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'

/** The view switcher: the option marked current, the status line, and a click on an option. */
class ViewSwitcherHarness extends Harness {
  static component = 'view-switcher'

  get current() {
    return this.parts('option')
      .find(option => option.getAttribute('aria-current') === 'page')
      ?.getAttribute('data-test-jn-value')
  }

  get status() {
    return this.part('status').textContent!.replace(/\s+/g, ' ').trim()
  }

  async choose(view: 'grid' | 'list' | 'default') {
    await click(this.part('option', view))
  }
}

module('Example | query-params-view', function (hooks) {
  // The view lives in the URL, so this visits the page the example is on, as an app's
  // acceptance test would visit the page with the switcher.
  setupApplicationTest(hooks)

  test('the URL picks the view, and the links change it', async function (assert) {
    await visit('/primitives/query-params.md?view=grid')
    await waitFor('[data-test-jn="view-switcher"]')
    const switcher = new ViewSwitcherHarness()
    assert.strictEqual(switcher.current, 'grid')
    assert.strictEqual(switcher.status, 'Showing the grid view.')

    await switcher.choose('list')
    assert.strictEqual(currentURL(), '/primitives/query-params.md?view=list')
    assert.strictEqual(switcher.current, 'list')

    await switcher.choose('default')
    assert.strictEqual(currentURL(), '/primitives/query-params.md')
    assert.strictEqual(switcher.status, 'Showing the default view.')
    await a11yAudit()
  })

  test('castToBoolean reads a flag', async function (assert) {
    await visit('/primitives/query-params.md?view=list&compact=1')
    await waitFor('[data-test-jn="view-switcher"]')
    assert.strictEqual(new ViewSwitcherHarness().status, 'Showing the list view, compact.')

    await visit('/primitives/query-params.md?view=list&compact=false')
    assert.strictEqual(new ViewSwitcherHarness().status, 'Showing the list view.')
    await a11yAudit()
  })
})
