import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { SeparatorHarness } from '@ember-joinery/test-support'
import SeparatorVertical from 'docs-app/examples/separator-vertical'

module('Example | separator-vertical', function (hooks) {
  setupRenderingTest(hooks)

  test('vertical lines the height of their row, between three links', async function (assert) {
    await render(<template><SeparatorVertical /></template>)
    const separators = SeparatorHarness.findAll()
    assert.strictEqual(separators.length, 2)
    for (const separator of separators) {
      assert.strictEqual(separator.orientation, 'vertical')
      const line = getComputedStyle(separator.element)
      assert.strictEqual(line.width, '1px')
      assert.strictEqual(line.height, '20px', 'the h-5 row')
    }
    await a11yAudit()
  })
})
