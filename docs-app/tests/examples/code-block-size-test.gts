import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockSize from 'docs-app/examples/code-block-size'

module('Example | code-block-size', function (hooks) {
  setupRenderingTest(hooks)

  test('the default size and sm, for tool output', async function (assert) {
    await render(<template><CodeBlockSize /></template>)
    const [normal, small] = CodeBlockHarness.findAll()
    assert.strictEqual(normal!.size, 'default')
    assert.strictEqual(small!.size, 'sm')
    assert.strictEqual(getComputedStyle(normal!.content).fontSize, '14px')
    assert.strictEqual(getComputedStyle(small!.content).fontSize, '12px', 'text-xs')
    assert.ok(
      Number.parseFloat(getComputedStyle(small!.content).paddingLeft) <
        Number.parseFloat(getComputedStyle(normal!.content).paddingLeft),
      'tighter padding',
    )
    assert.strictEqual(normal!.code, small!.code)
    await a11yAudit()
  })
})
