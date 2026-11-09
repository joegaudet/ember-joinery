import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CodeBlockHarness } from '@ember-joinery/code-block/test-support'
import CodeBlockRtl from 'docs-app/examples/code-block-rtl'

module('Example | code-block-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('an Arabic page: the header right to left, the code left to right', async function (assert) {
    await render(<template><CodeBlockRtl /></template>)
    const block = new CodeBlockHarness()
    assert.strictEqual(block.title, 'الطرفية')
    assert.strictEqual(getComputedStyle(block.element).direction, 'rtl')
    assert.strictEqual(getComputedStyle(block.content).direction, 'ltr')

    const title = block.part('title').getBoundingClientRect()
    const copy = block.copyButton!.getBoundingClientRect()
    assert.ok(copy.right < title.left, 'the copy button is at the inline end, on the left')
    assert.strictEqual(block.copyLabel, 'Copy')
    assert.deepEqual(
      block.lines.map(line => [line.number, line.text]),
      [
        [1, 'pnpm add ai @ai-sdk/react zod'],
        [2, 'pnpm dev'],
      ],
    )
    assert.true(block.isHighlighted)
    await a11yAudit()
  })
})
