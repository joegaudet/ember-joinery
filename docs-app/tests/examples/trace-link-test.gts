import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { TraceHarness, tab } from '@ember-joinery/test-support'
import TraceLink from 'docs-app/examples/trace-link'

module('Example | trace-link', function (hooks) {
  setupRenderingTest(hooks)

  test('two link rows, one to a new tab that says so', async function (assert) {
    await render(<template><TraceLink /></template>)
    const [docs, astro] = new TraceHarness().lines
    assert.true(docs!.isLink)
    assert.strictEqual(docs!.href, '#link')
    assert.false(docs!.opensInNewTab)
    assert.true(astro!.opensInNewTab)
    assert.strictEqual(astro!.title, 'Install Astro | docs.astro.build (opens in a new tab)')
    assert.strictEqual(astro!.icons.length, 2, 'an arrow after the title')
    await tab()
    assert.dom(docs!.control).isFocused('the link is the tab stop')
    await a11yAudit()
  })
})
