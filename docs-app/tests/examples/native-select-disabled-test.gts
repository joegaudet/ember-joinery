import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectDisabled from 'docs-app/examples/native-select-disabled'

module('Example | native-select-disabled', function (hooks) {
  setupRenderingTest(hooks)

  test('a disabled select, dimmed, that nobody can choose from', async function (assert) {
    await render(<template><NativeSelectDisabled /></template>)
    const fruit = new NativeSelectHarness()

    assert.true(fruit.isDisabled)
    assert.strictEqual(getComputedStyle(fruit.element).opacity, '0.5')
    await assert.rejects(fruit.select('apple'), 'a disabled select can’t be chosen from')
    assert.strictEqual(fruit.selectedText, 'Disabled')
    await a11yAudit()
  })
})
