import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness, SkeletonHarness } from '@ember-joinery/test-support'
import SkeletonCard from 'docs-app/examples/skeleton-card'

module('Example | skeleton-card', function (hooks) {
  setupRenderingTest(hooks)

  test("a card's title, description and image, loading", async function (assert) {
    await render(<template><SkeletonCard /></template>)
    const card = new CardHarness()
    assert.strictEqual(card.text, '', 'nothing has loaded')

    // The header's two lines, two thirds and half of its 288px (max-w-xs, less 16px a side).
    const [title, description] = card.findAll(SkeletonHarness)
    assert.true(card.header.contains(title!.element) && card.header.contains(description!.element))
    assert.deepEqual([title!.width, title!.height], [192, 16], 'h-4 w-2/3')
    assert.deepEqual([description!.width, description!.height], [144, 16], 'h-4 w-1/2')

    // The content's 16:9 image, as wide as the content.
    const image = card.findAll(SkeletonHarness)[2]!
    assert.true(card.content.contains(image.element))
    assert.deepEqual([image.width, image.height], [288, 162], 'aspect-video w-full')
    assert.true(image.isPulsing)
    await a11yAudit()
  })
})
