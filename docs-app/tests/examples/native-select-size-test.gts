import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { NativeSelectHarness } from '@ember-joinery/test-support'
import NativeSelectSize from 'docs-app/examples/native-select-size'

module('Example | native-select-size', function (hooks) {
  setupRenderingTest(hooks)

  test('a small select beside a default one, each from its @defaultValue', async function (assert) {
    await render(<template><NativeSelectSize /></template>)
    const small = new NativeSelectHarness('sm')
    const normal = new NativeSelectHarness('default')

    assert.strictEqual(small.size, 'sm')
    assert.strictEqual(normal.size, 'default')
    assert.strictEqual(getComputedStyle(small.control).height, '28px')
    assert.strictEqual(getComputedStyle(normal.control).height, '32px')

    assert.strictEqual(small.selectedText, 'This week')
    await small.select('month')
    assert.strictEqual(small.value, 'month', 'each keeps its own value')
    assert.strictEqual(normal.value, 'week')
    await a11yAudit()
  })
})
