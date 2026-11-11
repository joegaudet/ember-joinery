import { module, test } from 'qunit'
import { setupApplicationTest } from 'docs-app/tests/helpers'
import { currentURL, visit, waitFor } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LinkHarness } from '@ember-joinery/test-support'

/** The example's links, by their text. */
function links(): Record<string, LinkHarness> {
  const example = document.querySelector('[data-test-example="link-active"]')!
  return Object.fromEntries(
    LinkHarness.findAll()
      .filter(link => example.contains(link.element))
      .map(link => [link.text, link]),
  )
}

module('Example | link-active', function (hooks) {
  // Active links depend on the router's URL, so this visits the page the example is on.
  setupApplicationTest(hooks)

  test('the link to this page is active, and red', async function (assert) {
    await visit('/primitives/link.md')
    await waitFor('[data-test-example="link-active"] [data-test-jn="link"]')
    const { 'This page': here, 'Related page': related } = links()

    assert.true(here!.isCurrent)
    assert.strictEqual(here!.current, 'page')
    assert.dom(here!.element).hasAttribute('data-active', 'true')
    assert.strictEqual(getComputedStyle(here!.element).color, 'rgb(204, 0, 0)')
    assert.false(related!.isCurrent)

    await related!.follow()
    assert.strictEqual(currentURL(), '/primitives/proper-links.md', 'a click is a transition')
    await a11yAudit()
  })
})
