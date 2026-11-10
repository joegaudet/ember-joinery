import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness, SpinnerHarness } from '@ember-joinery/test-support'
import MarkerDemo from 'docs-app/examples/marker-demo'

module('Example | marker-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('notes with icons, a thinking status, and a separator, in a thread', async function (assert) {
    await render(<template><MarkerDemo /></template>)
    const markers = MarkerHarness.findAll()
    assert.deepEqual(
      markers.map(marker => marker.text),
      ['Switched to a new branch', 'Thinking...', 'Conversation compacted', 'Explored 4 files'],
    )
    assert.deepEqual(
      markers.map(marker => marker.variant),
      ['default', 'default', 'separator', 'default'],
    )
    assert.deepEqual(
      markers.map(marker => marker.hasIcon),
      [true, true, false, true],
    )
    assert.dom(markers[0]!.icon).hasAttribute('aria-hidden', 'true', 'icons are decoration')

    const thinking = markers[1]!
    assert.true(thinking.isStatus, 'announced as it changes')
    assert.true(thinking.find(SpinnerHarness).exists)
    assert.dom(thinking.content).hasClass('shimmer')
    assert.notStrictEqual(
      getComputedStyle(thinking.content).animationName,
      'none',
      'the shimmer animates',
    )
    await a11yAudit()
  })
})
