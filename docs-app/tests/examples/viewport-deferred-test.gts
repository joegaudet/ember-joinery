import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness, scrollIntoView } from '@ember-joinery/test-support'
import ViewportDeferred from 'docs-app/examples/viewport-deferred'

class ArticleHarness extends Harness {
  static component = 'article'

  get comments() {
    return this.parts('comment').map(comment => comment.textContent!.trim())
  }

  async scrollToComments() {
    await scrollIntoView(this.part('comments'))
  }

  async scrollToTop() {
    await scrollIntoView(this.part('top'))
  }
}

module('Example | viewport-deferred', function (hooks) {
  setupRenderingTest(hooks)

  test('the comments render once they scroll near, and stay', async function (assert) {
    await render(<template><ViewportDeferred /></template>)
    const article = new ArticleHarness()
    await article.scrollToTop()
    assert.deepEqual(article.comments, [], 'not rendered below the fold')

    await article.scrollToComments()
    assert.deepEqual(article.comments, [
      'Great write-up.',
      'This saved me a day.',
      'Could it work with RTL?',
    ])

    await article.scrollToTop()
    assert.strictEqual(article.comments.length, 3, 'still there')
    await a11yAudit()
  })
})
