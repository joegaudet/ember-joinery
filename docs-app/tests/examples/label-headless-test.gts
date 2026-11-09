import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LabelHarness } from '@ember-joinery/test-support'
import LabelHeadless from 'docs-app/examples/label-headless'

module('Example | label-headless', function (hooks) {
  setupRenderingTest(hooks)

  test('a label names its input, and a click on it focuses the input', async function (assert) {
    await render(<template><LabelHeadless /></template>)
    const label = new LabelHarness()
    assert.strictEqual(label.text, 'Your email address')
    assert.strictEqual(label.control, find('#email-headless'))
    await label.click()
    assert.dom('#email-headless').isFocused()
    await a11yAudit()
  })
})
