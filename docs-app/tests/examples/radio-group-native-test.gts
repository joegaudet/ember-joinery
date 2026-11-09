import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { click, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { RadioGroupHarness, tab } from '@ember-joinery/test-support'
import RadioGroupNative from 'docs-app/examples/radio-group-native'

module('Example | radio-group-native', function (hooks) {
  setupRenderingTest(hooks)

  test('three spacings, comfortable chosen; labels and arrow keys choose', async function (assert) {
    await render(<template><RadioGroupNative /></template>)
    const spacing = new RadioGroupHarness()

    assert.deepEqual(spacing.options, ['default', 'comfortable', 'compact'])
    assert.strictEqual(spacing.value, 'comfortable')
    assert.strictEqual(spacing.labelOf('compact'), 'Compact')

    await tab()
    assert.strictEqual(spacing.focused, 'comfortable', 'Tab lands on the choice')
    await spacing.press('ArrowDown')
    assert.strictEqual(spacing.value, 'compact', 'and the arrows move it')

    await click('label[for="r1-native"]')
    assert.strictEqual(spacing.value, 'default', 'a click on a label chooses its item')
    await a11yAudit()
  })
})
