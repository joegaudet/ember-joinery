import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Harness } from '@ember-joinery/test-support'
import LoadOnDemand from 'docs-app/examples/load-on-demand'

class RevenueHarness extends Harness {
  static component = 'revenue'

  get caption() {
    return this.element.querySelector('figcaption')!.textContent!.trim()
  }

  get total() {
    return this.part('total').textContent!.trim()
  }
}

module('Example | load-on-demand', function (hooks) {
  setupRenderingTest(hooks)

  test('the summary renders once its code has loaded', async function (assert) {
    await render(<template><LoadOnDemand /></template>)
    // render() waits for the import; the loading state came and went.
    const revenue = new RevenueHarness()
    assert.strictEqual(revenue.caption, 'Revenue in 2026', 'with the argument the block gave it')
    assert.strictEqual(revenue.total, '$1.2M, up 14%')
    assert.dom('[role="status"]').doesNotExist()
    await a11yAudit()
  })
})
