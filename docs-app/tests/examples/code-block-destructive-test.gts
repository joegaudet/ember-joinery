import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockDestructive from 'docs-app/examples/code-block-destructive'

module('Example | code-block-destructive', function (hooks) {
  setupRenderingTest(hooks)

  test('an error, in the destructive tone, wrapped', async function (assert) {
    await render(<template><CodeBlockDestructive /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.variant, 'destructive')
    assert.strictEqual(block.title, 'Error')
    assert.true(block.isWrapped)
    assert.ok(block.lines[0]!.text.startsWith('TypeError'))
    assert.strictEqual(
      getComputedStyle(block.content).color,
      getComputedStyle(block.part('title')).color,
      'the title and the code share the destructive colour',
    )
    await a11yAudit()
  })
})
