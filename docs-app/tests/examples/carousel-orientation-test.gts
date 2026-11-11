import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselOrientation from 'docs-app/examples/carousel-orientation'

module('Example | carousel-orientation', function (hooks) {
  setupRenderingTest(hooks)

  test('vertical: two cards at a time, with the buttons above and below', async function (assert) {
    await render(<template><CarouselOrientation /></template>)
    const carousel = new CarouselHarness()

    assert.strictEqual(carousel.orientation, 'vertical')
    assert.strictEqual(carousel.container.offsetHeight, 270, 'h-[270px]')
    assert.strictEqual(getComputedStyle(carousel.container).marginTop, '-4px', '-mt-1')
    assert.deepEqual(carousel.slidesInView, [0, 1], 'basis-1/2')

    const content = carousel.content.getBoundingClientRect()
    assert.ok(carousel.previous!.getBoundingClientRect().bottom <= content.top, 'previous above')
    assert.ok(carousel.next!.getBoundingClientRect().top >= content.bottom, 'next below')
    assert.strictEqual(getComputedStyle(carousel.previous!).rotate, '90deg', 'its arrow points up')

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1, 2])
    await carousel.press('ArrowDown')
    assert.deepEqual(carousel.slidesInView, [2, 3], 'the down arrow goes on')
    await carousel.swipe('previous')
    assert.deepEqual(carousel.slidesInView, [1, 2], 'a swipe down goes back')
    await a11yAudit()
  })
})
