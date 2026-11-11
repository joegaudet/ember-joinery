import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselSize from 'docs-app/examples/carousel-size'

module('Example | carousel-size', function (hooks) {
  setupRenderingTest(hooks)

  test('a third of the carousel each on a wide screen, aligned to the start', async function (assert) {
    await render(<template><CarouselSize /></template>)
    const carousel = new CarouselHarness()

    // The test runs in a 1440px window, so the lg: and md: classes apply.
    assert.strictEqual(carousel.element.offsetWidth, 384, 'md:max-w-sm')
    const [first] = carousel.slides
    assert.strictEqual(getComputedStyle(first!).flexBasis, '33.3333%', 'lg:basis-1/3')
    assert.deepEqual(carousel.slidesInView, [0, 1, 2], 'three at once, from the start')

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1, 2, 3])
    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [2, 3, 4])
    assert.false(carousel.canScrollNext, 'it stops where the last card shows')
    await a11yAudit()
  })
})
