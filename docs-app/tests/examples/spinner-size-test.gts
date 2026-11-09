import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SpinnerHarness } from '@ember-joinery/test-support'
import SpinnerSize from 'docs-app/examples/spinner-size'

module('Example | spinner-size', function (hooks) {
  setupRenderingTest(hooks)

  test('a size-* class sizes each spinner', async function (assert) {
    await render(<template><SpinnerSize /></template>)
    const spinners = SpinnerHarness.findAll()
    assert.deepEqual(
      spinners.map(spinner => getComputedStyle(spinner.element).width),
      ['12px', '16px', '24px', '32px'],
    )
    for (const spinner of spinners) {
      assert.strictEqual(spinner.label, 'Loading')
      assert.strictEqual(spinner.role, 'status')
    }
    await a11yAudit()
  })
})
