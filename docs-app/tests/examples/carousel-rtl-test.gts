import { module, test } from 'qunit'
import { setupRenderingTest } from 'docs-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { ButtonHarness } from '@ember-joinery/test-support'
import { CarouselHarness } from '@ember-joinery/carousel/test-support'
import CarouselRtl from 'docs-app/examples/carousel-rtl'

module('Example | carousel-rtl', function (hooks) {
  setupRenderingTest(hooks)

  test('right to left: Arabic numerals, the slides run from the right', async function (assert) {
    // The guide shows it with dir="rtl" on the preview; a provider does the same here.
    await render(
      <template>
        <DirectionProvider @dir="rtl"><CarouselRtl /></DirectionProvider>
      </template>,
    )
    const carousel = new CarouselHarness()

    assert.strictEqual(carousel.direction, 'rtl')
    assert.strictEqual(carousel.label, 'أرقام')
    assert.deepEqual(carousel.slideTexts, ['١', '٢', '٣', '٤', '٥'])
    assert.strictEqual(carousel.slideLabels[1], '٢ من ٥', 'named in Arabic')
    const [first, second] = carousel.slides
    assert.ok(
      second!.getBoundingClientRect().left < first!.getBoundingClientRect().left,
      'the second card waits on the left',
    )

    const [previous, next] = carousel.findAll(ButtonHarness)
    assert.strictEqual(previous!.label, 'الشريحة السابقة')
    assert.strictEqual(next!.label, 'الشريحة التالية')
    const content = carousel.content.getBoundingClientRect()
    assert.ok(
      previous!.element.getBoundingClientRect().left >= content.right,
      'previous on the right',
    )
    assert.ok(next!.element.getBoundingClientRect().right <= content.left, 'next on the left')

    await carousel.scrollNext()
    assert.deepEqual(carousel.slidesInView, [1])
    await carousel.press('ArrowLeft')
    assert.deepEqual(carousel.slidesInView, [2], 'the left arrow goes on')
    await carousel.swipe('previous')
    assert.deepEqual(carousel.slidesInView, [1], 'a swipe to the left goes back')
    await a11yAudit()
  })
})
