import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, scrollIntoView } from '@ember-joinery/test-support'
import ViewportVisibility from 'docs-app/examples/viewport-visibility'

class FeedHarness extends Harness {
  static component = 'feed'

  get status() {
    return this.part('status').textContent!.trim()
  }

  async scrollToVideo() {
    await scrollIntoView(this.part('video'))
  }

  async scrollToTop() {
    await scrollIntoView(this.part('top'))
  }
}

module('Example | viewport-visibility', function (hooks) {
  setupRenderingTest(hooks)

  test('the video plays while half of it is in view', async function (assert) {
    await render(<template><ViewportVisibility /></template>)
    const feed = new FeedHarness()
    await feed.scrollToTop()
    assert.strictEqual(feed.status, 'Paused')

    await feed.scrollToVideo()
    assert.strictEqual(feed.status, 'Playing')

    await feed.scrollToTop()
    assert.strictEqual(feed.status, 'Paused', 'paused again out of view')
    await a11yAudit()
  })
})
