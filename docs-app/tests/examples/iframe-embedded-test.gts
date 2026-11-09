import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import IframeEmbedded from 'docs-app/examples/iframe-embedded'

class EmbedNoticeHarness extends Harness {
  static component = 'embed-notice'

  get text() {
    return this.element.textContent!.replace(/\s+/g, ' ').trim()
  }
}

module('Example | iframe-embedded', function (hooks) {
  setupRenderingTest(hooks)

  test('the tests run in the top window, so it says the page is on its own', async function (assert) {
    await render(<template><IframeEmbedded /></template>)
    assert.strictEqual(
      new EmbedNoticeHarness().text,
      'This page is open on its own, not in a frame.',
    )
    await a11yAudit()
  })
})
