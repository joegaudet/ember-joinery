import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, scrollIntoView } from '@ember-joinery/test-support'
import ViewportContain from 'docs-app/examples/viewport-contain'

class ScrollerHarness extends Harness {
  static component = 'scroller'

  get placeholder() {
    return this.queryPart('placeholder')
  }

  get content() {
    return this.queryPart('content')
  }

  async scrollDown() {
    await scrollIntoView(this.part('placeholder'))
  }

  async scrollToTop() {
    await scrollIntoView(this.part('top'))
  }
}

module('Example | viewport-contain', function (hooks) {
  setupRenderingTest(hooks)

  test('the content renders inside the placeholder, which stays', async function (assert) {
    await render(<template><ViewportContain /></template>)
    const scroller = new ScrollerHarness()
    await scroller.scrollToTop()
    assert.strictEqual(scroller.placeholder?.tagName, 'DIV', 'an empty div, to be watched')
    assert.strictEqual(scroller.content, null, 'nothing rendered below the fold')

    await scroller.scrollDown()
    assert.true(scroller.content!.textContent!.includes('Content in contain mode'))
    assert.true(scroller.placeholder!.contains(scroller.content), 'inside the placeholder')

    await scroller.scrollToTop()
    assert.notStrictEqual(scroller.content, null, 'and it stays')
    await a11yAudit()
  })
})
