import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { CardHarness } from '@ember-joinery/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselSpacing from 'docs-app/examples/carousel-spacing'

module('Example | carousel-spacing', function (hooks) {
  setupRenderingTest(hooks)

  test('the slides closer together: -ml-1 on the content, pl-1 on each slide', async function (assert) {
    await render(<template><CarouselSpacing /></template>)
    const carousel = new CarouselHarness()

    assert.strictEqual(getComputedStyle(carousel.container).marginLeft, '-4px', '-ml-1, not -ml-4')
    const [first, second] = carousel.slides
    assert.strictEqual(getComputedStyle(first!).paddingLeft, '4px', 'pl-1, not pl-4')
    assert.deepEqual(carousel.slidesInView, [0, 1, 2])
    const [one, two] = carousel.findAll(CardHarness)
    const gap =
      two!.element.getBoundingClientRect().left - one!.element.getBoundingClientRect().right
    const scale = carousel.element.getBoundingClientRect().width / carousel.element.offsetWidth
    assert.strictEqual(Math.round(gap / scale), 12, 'p-1 each side of a card, and pl-1 between')
    assert.strictEqual(second!.offsetWidth, first!.offsetWidth)

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1, 2, 3])
    await a11yAudit()
  })
})
