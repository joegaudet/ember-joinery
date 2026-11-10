import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness } from '@ember-joinery/test-support'
import MarkerSeparator from 'docs-app/examples/marker-separator'

module('Example | marker-separator', function (hooks) {
  setupRenderingTest(hooks)

  test('labelled dividers, read as their text', async function (assert) {
    await render(<template><MarkerSeparator /></template>)
    const separators = MarkerHarness.findAll()
    assert.deepEqual(
      separators.map(marker => marker.text),
      ['Today', 'Worked for 42s', 'Conversation compacted'],
    )
    for (const marker of separators) {
      assert.strictEqual(marker.variant, 'separator')
      assert.strictEqual(marker.role, null, 'no separator role, so the label is announced')
      const box = marker.element.getBoundingClientRect()
      const label = marker.content.getBoundingClientRect()
      assert.ok(
        Math.abs(label.left - box.left - (box.right - label.right)) <= 1,
        `${marker.text}: centred between its lines`,
      )
    }
    await a11yAudit()
  })
})
