import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ExternalLink } from '@ember-joinery/primitives/external-link'
import { ExternalLinkHarness, LinkHarness } from '@ember-joinery/test-support'

module('Integration | primitives | external-link', function (hooks) {
  setupRenderingTest(hooks)

  test('it opens a new tab, and tells the page it opens nothing about this one', async function (assert) {
    await render(
      <template>
        <ExternalLink @name="mdn" href="https://developer.mozilla.org" class="ref">
          MDN
          <span aria-hidden="true">↗</span>
        </ExternalLink>
      </template>,
    )
    const mdn = new ExternalLinkHarness('mdn')
    assert.dom(mdn.element).hasTagName('a').hasClass('ref')
    assert.strictEqual(mdn.href, 'https://developer.mozilla.org')
    assert.true(mdn.opensInNewTab)
    assert.true(mdn.isIsolated)
    assert.dom(mdn.element).hasAttribute('rel', 'noreferrer noopener')
    assert.strictEqual(mdn.text, 'MDN ↗')
    assert.false(mdn.isCurrent, 'an external link is never the current page')
    assert.true(new LinkHarness('mdn').exists, 'a LinkHarness drives it too')
    await a11yAudit()
  })

  test('without an href, its href says so', async function (assert) {
    await render(
      <template>
        <ExternalLink>Nowhere</ExternalLink>
      </template>,
    )
    assert.strictEqual(new ExternalLinkHarness().href, '##missing##')
    await a11yAudit()
  })

  test('its attributes win', async function (assert) {
    await render(
      <template>
        <ExternalLink href="https://example.com" target="_self" rel="noopener">Here</ExternalLink>
      </template>,
    )
    const link = new ExternalLinkHarness()
    assert.false(link.opensInNewTab)
    assert.false(link.isIsolated)
    await a11yAudit()
  })
})
