import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, scrollIntoView } from '@ember-joinery/test-support'
import ViewportReplace from 'docs-app/examples/viewport-replace'

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

module('Example | viewport-replace', function (hooks) {
  setupRenderingTest(hooks)

  test('the content takes the place of the placeholder', async function (assert) {
    await render(<template><ViewportReplace /></template>)
    const scroller = new ScrollerHarness()
    await scroller.scrollToTop()
    assert.notStrictEqual(scroller.placeholder, null, 'a placeholder, to be watched')
    assert.strictEqual(scroller.content, null, 'nothing rendered below the fold')

    await scroller.scrollDown()
    assert.true(scroller.content!.textContent!.includes('This replaces the placeholder'))
    assert.strictEqual(scroller.placeholder, null, 'the placeholder went')

    await scroller.scrollToTop()
    assert.notStrictEqual(scroller.content, null, 'and the content stays')
    await a11yAudit()
  })
})
