import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, waitUntil } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ProgressHarness } from '@ember-joinery/test-support'
import ProgressDemo from 'docs-app/examples/progress-demo'

module('Example | progress-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('it starts at 13%, and moves to 66% half a second later', async function (assert) {
    await render(<template><ProgressDemo /></template>)
    const progress = new ProgressHarness()

    assert.strictEqual(progress.value, 13)
    assert.strictEqual(progress.label, 'Progress')
    await waitUntil(() => progress.value === 66, { timeout: 2000 })
    assert.strictEqual(progress.valueText, '66%')
    assert.dom(progress.indicator).hasAttribute('style', 'transform: translateX(-34%)')
    await a11yAudit()
  })
})
