import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { fillIn, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import StoreDrafts from 'docs-app/examples/store-drafts'

/** One reply box: its text, and the count its draft keeps. */
class ReplyHarness extends Harness {
  static component = 'reply'

  get count() {
    return this.part('count').textContent!.trim()
  }

  async write(text: string) {
    await fillIn(this.part('text'), text)
  }
}

module('Example | store-drafts', function (hooks) {
  setupRenderingTest(hooks)

  test('each reply keeps its own draft', async function (assert) {
    await render(<template><StoreDrafts /></template>)
    const ada = new ReplyHarness('Ada')
    const grace = new ReplyHarness('Grace')

    await ada.write('Thanks!')
    assert.strictEqual(ada.count, '7 characters')
    assert.strictEqual(grace.count, '0 characters', "Grace's draft is another instance")

    await grace.write('See you then.')
    assert.strictEqual(grace.count, '13 characters')
    assert.strictEqual(ada.count, '7 characters')
    await a11yAudit()
  })
})
