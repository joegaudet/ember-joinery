import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { ButtonHarness, CardHarness } from '@ember-joinery/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselDemo from 'docs-app/examples/carousel-demo'

module('Example | carousel-demo', function (hooks) {
  setupRenderingTest(hooks)

  test('five numbered cards, one at a time, with a button either side', async function (assert) {
    await render(<template><CarouselDemo /></template>)
    const carousel = new CarouselHarness()

    assert.strictEqual(carousel.label, 'Numbers')
    assert.strictEqual(carousel.roleDescription, 'carousel')
    assert.deepEqual(carousel.slideTexts, ['1', '2', '3', '4', '5'])
    assert.deepEqual(carousel.slideLabels, ['1 of 5', '2 of 5', '3 of 5', '4 of 5', '5 of 5'])
    assert.strictEqual(carousel.element.offsetWidth, 320, 'sm:max-w-xs')
    assert.strictEqual(carousel.findAll(CardHarness).length, 5, 'a card in each slide')
    const card = carousel.find(CardHarness).content
    assert.strictEqual(card.offsetWidth, card.offsetHeight, 'aspect-square')

    assert.deepEqual(carousel.slidesInView, [0])
    assert.false(carousel.canScrollPrev, 'it starts at the first')
    const [previous, next] = carousel.findAll(ButtonHarness)
    assert.strictEqual(previous!.label, 'Previous slide')
    assert.strictEqual(next!.label, 'Next slide')

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1], 'the next card')
    await carousel.press('ArrowRight')
    assert.deepEqual(carousel.slidesInView, [2], 'and with the arrow keys')
    await carousel.swipe('previous')
    assert.deepEqual(carousel.slidesInView, [1], 'or a swipe')
    await a11yAudit()
  })
})
