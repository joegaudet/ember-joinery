import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ProgressHarness } from '@ember-joinery/test-support'
import ProgressHeadless from 'docs-app/examples/progress-headless'

module('Example | progress-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('seven of twelve files, as its value label says', async function (assert) {
    await render(<template><ProgressHeadless /></template>)
    const upload = new ProgressHarness()

    assert.strictEqual(upload.value, 7)
    assert.strictEqual(upload.max, 12)
    assert.strictEqual(upload.valueText, '7 of 12 files')
    assert.strictEqual(upload.percent, 58.33)
    assert.dom(upload.indicator).hasAttribute('style', 'width: 58.33%')
    await a11yAudit()
  })
})
