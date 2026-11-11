import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { LabelHarness, RadioGroupHarness, tab } from '@ember-joinery/test-support'
import RadioGroupDemo from 'docs-app/examples/radio-group-demo'

module('Example | radio-group-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('three spacings, comfortable chosen; labels and arrow keys choose', async function (assert) {
    await render(<template><RadioGroupDemo /></template>)
    const spacing = new RadioGroupHarness()
    const labels = LabelHarness.findAll()

    assert.deepEqual(spacing.options, ['default', 'comfortable', 'compact'])
    assert.strictEqual(spacing.value, 'comfortable')
    assert.deepEqual(
      labels.map(label => label.text),
      ['Default', 'Comfortable', 'Compact'],
    )
    assert.strictEqual(spacing.labelOf('compact'), 'Compact', 'each Label names its item')

    await tab()
    assert.strictEqual(spacing.focused, 'comfortable', 'Tab lands on the choice')
    await spacing.press('ArrowDown')
    assert.strictEqual(spacing.value, 'compact', 'and the arrows move it')

    await labels[0]!.click()
    assert.strictEqual(spacing.value, 'default', 'a click on a label chooses its item')
    await a11yAudit()
  })
})
