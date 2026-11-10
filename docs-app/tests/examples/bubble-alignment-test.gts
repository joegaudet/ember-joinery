import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { BubbleHarness } from '@ember-joinery/test-support'
import BubbleAlignment from 'docs-app/examples/bubble-alignment'

module('Example | bubble-alignment', function (hooks) {
  setupRenderingTest(hooks)

  test('one bubble at the start, the default, and one at the end', async function (assert) {
    await render(<template><BubbleAlignment /></template>)
    const [start, end] = BubbleHarness.findAll()
    const thread = start!.element.parentElement!.getBoundingClientRect()

    assert.strictEqual(start!.align, 'start')
    assert.strictEqual(start!.variant, 'muted')
    assert.strictEqual(
      Math.round(start!.element.getBoundingClientRect().left),
      Math.round(thread.left),
    )
    assert.strictEqual(end!.align, 'end')
    assert.strictEqual(
      Math.round(end!.element.getBoundingClientRect().right),
      Math.round(thread.right),
    )
    assert.strictEqual(end!.text, 'This bubble is aligned to the end. Use this for user messages.')
    await a11yAudit()
  })
})
