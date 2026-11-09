import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { find, render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselApiDemo from 'docs-app/examples/carousel-api'

module('Example | carousel-api', function (hooks) {
  setupRenderingTest(hooks)

  test('the API counts the slides, and its select event follows the current one', async function (assert) {
    await render(<template><CarouselApiDemo /></template>)
    const carousel = new CarouselHarness()
    const count = () => find('.text-muted-foreground')!.textContent!.replace(/\s+/g, ' ').trim()

    assert.strictEqual(count(), 'Slide 1 of 5', 'from scrollSnapList() and selectedScrollSnap()')
    await carousel.scrollNext()
    assert.strictEqual(count(), 'Slide 2 of 5', 'on select')
    await carousel.scrollNext()
    assert.strictEqual(count(), 'Slide 3 of 5')
    await carousel.scrollPrev()
    assert.strictEqual(count(), 'Slide 2 of 5')
    assert.deepEqual(carousel.slidesInView, [1])
    await a11yAudit()
  })
})
