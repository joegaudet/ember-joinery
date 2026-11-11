import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockHighlighting from 'docs-app/examples/code-block-highlighting'

module('Example | code-block-highlighting', function (hooks) {
  setupRenderingTest(hooks)

  test('a tool result as highlighted JSON', async function (assert) {
    await render(<template><CodeBlockHighlighting /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.title, 'getWeather output')
    assert.true(block.isHighlighted)
    const tokens = block.tokens(1)
    const key = tokens.find(token => token.text.includes('location'))!
    const value = tokens.find(token => token.text.includes('San Francisco'))!
    assert.notStrictEqual(key.color, value.color, 'keys and strings take different colours')
    assert.strictEqual(block.lines[2]!.text, '  "temperature": 18,')
    await a11yAudit()
  })
})
