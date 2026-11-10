import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { MarkerHarness } from '@ember-joinery/test-support'
import MarkerShimmer from 'docs-app/examples/marker-shimmer'

module('Example | marker-shimmer', function (hooks) {
  setupRenderingTest(hooks)

  test("streaming status text, with shadcn's shimmer utility on the content", async function (assert) {
    await render(<template><MarkerShimmer /></template>)
    const [thinking, reading] = MarkerHarness.findAll()
    assert.strictEqual(thinking!.text, 'Thinking...')
    assert.strictEqual(reading!.text, 'Reading 4 files')
    assert.strictEqual(reading!.variant, 'separator')
    for (const marker of [thinking!, reading!]) {
      assert.true(marker.isStatus)
      const style = getComputedStyle(marker.content)
      assert.notStrictEqual(style.animationName, 'none', 'the shimmer animates')
      assert.notStrictEqual(style.backgroundImage, 'none', 'a gradient, clipped to the text')
    }
    await a11yAudit()
  })
})
