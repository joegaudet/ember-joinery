import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import DomContextIndependent from 'docs-app/examples/dom-context-independent'

class StoreHarness extends Harness {
  static component = 'store'

  get count() {
    return Number(this.part('count').textContent)
  }

  async act() {
    await click(this.part('action'))
  }
}

module('Example | dom-context-independent', function (hooks) {
  setupRenderingTest(hooks)

  test('each consumer reads its own nearest provider of the key', async function (assert) {
    await render(<template><DomContextIndependent /></template>)
    const incrementer = new StoreHarness('incrementer')
    const doubler = new StoreHarness('doubler')
    assert.deepEqual([incrementer.count, doubler.count], [2, 2])

    await incrementer.act()
    await incrementer.act()
    assert.deepEqual([incrementer.count, doubler.count], [4, 2], 'the doubler is untouched')

    await doubler.act()
    await doubler.act()
    await doubler.act()
    assert.deepEqual([incrementer.count, doubler.count], [4, 16], 'and the other way round')
    await a11yAudit()
  })
})
