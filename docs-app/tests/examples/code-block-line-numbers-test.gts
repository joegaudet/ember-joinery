import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockLineNumbers from 'docs-app/examples/code-block-line-numbers'

module('Example | code-block-line-numbers', function (hooks) {
  setupRenderingTest(hooks)

  test('a string split into numbered lines', async function (assert) {
    await render(<template><CodeBlockLineNumbers /></template>)
    const block = new CodeBlockHarness()
    assert.true(block.isNumbered)
    assert.deepEqual(
      block.lines.map(line => line.number),
      [1, 2, 3, 4, 5, 6, 7, 8],
    )
    assert.strictEqual(block.lines[1]!.text, '  "name": "chat",')
    await a11yAudit()
  })
})
