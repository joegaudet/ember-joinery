import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render, settled, triggerEvent } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselPlugin from 'docs-app/examples/carousel-plugin'

const wait = (ms: number) => new Promise(resolve => setTimeout(resolve, ms))

module('Example | carousel-plugin', function (hooks) {
  setupRenderingTest(hooks)

  test('autoplay moves on every two seconds, until the pointer is over it', async function (assert) {
    await render(<template><CarouselPlugin /></template>)
    const carousel = new CarouselHarness()
    assert.deepEqual(carousel.slidesInView, [0])

    await carousel.waitForSlide(1, { timeout: 4000 })
    assert.deepEqual(carousel.slidesInView, [1], 'on to the next, by itself')

    await triggerEvent(carousel.element, 'mouseenter')
    await wait(2500)
    await settled()
    assert.deepEqual(carousel.slidesInView, [1], 'hovering stops it')
    await a11yAudit()
  })
})
