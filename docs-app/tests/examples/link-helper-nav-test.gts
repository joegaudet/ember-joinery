import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { click, currentURL, visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'

/** The nav: which link is current, which leave the guide, and following one. */
class RoutingNavHarness extends Harness {
  static component = 'routing-nav'

  link(label: string) {
    const link = this.parts('link').find(element => element.textContent!.includes(label))
    if (!link) throw new Error(`no link "${label}"`)
    return link
  }

  get current() {
    return this.parts('link')
      .filter(link => link.getAttribute('aria-current') === 'page')
      .map(link => link.textContent!.trim())
  }

  async follow(label: string) {
    await click(this.link(label))
  }
}

module('Example | link-helper-nav', function (hooks) {
  // Active links depend on the router's URL, so this visits the page the example is on.
  setupApplicationTest(hooks)

  test('the link to this page is current, and a click is a transition', async function (assert) {
    await visit('/primitives/link-helper.md')
    await waitFor('[data-test-jn="routing-nav"]')
    const nav = new RoutingNavHarness()
    assert.deepEqual(nav.current, ['Link helper'])
    assert.dom(nav.link('ember-primitives')).hasAttribute('target', '_blank', 'external: a new tab')
    assert.dom(nav.link('Proper links')).doesNotHaveAttribute('target')

    await nav.follow('Proper links')
    assert.strictEqual(currentURL(), '/primitives/proper-links.md')
    await a11yAudit()
  })
})
