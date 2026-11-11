import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render } from '@ember/test-helpers'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { AspectRatio } from '@ember-joinery/ember'
import { AspectRatioHarness } from '@ember-joinery/test-support'

const WIDESCREEN = 16 / 9
const PORTRAIT = 9 / 16

module('Integration | components | aspect-ratio', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders the primitive with upstream data attributes', async function (assert) {
    await render(
      <template>
        <div style="width: 384px">
          <AspectRatio @name="photo" @ratio={{WIDESCREEN}} class="mine">
            <div id="fill" style="width: 100%; height: 100%"></div>
          </AspectRatio>
        </div>
      </template>,
    )
    const photo = new AspectRatioHarness('photo')
    assert
      .dom(photo.element)
      .hasTagName('div')
      .hasClass('jn-aspect-ratio')
      .hasClass('mine')
      .hasAttribute('data-slot', 'aspect-ratio')
      .hasAttribute('data-test-jn', 'aspect-ratio')
    assert.dom(photo.wrapper).hasAttribute('data-jn-aspect-ratio-wrapper')
    assert.deepEqual([photo.width, photo.height], [384, 216], '384 × 9 / 16')
    const fill = getComputedStyle(document.querySelector('#fill')!)
    assert.deepEqual([fill.width, fill.height], ['384px', '216px'], 'its content fills it')
    await a11yAudit()
  })

  test('square and portrait, and an image inside that fills it', async function (assert) {
    await render(
      <template>
        <div style="width: 192px">
          <AspectRatio @name="square" @ratio={{1}} />
        </div>
        <div style="width: 160px">
          <AspectRatio @name="portrait" @ratio={{PORTRAIT}}>
            <img
              alt="A placeholder"
              src="data:image/gif;base64,R0lGODlhAQABAAAAACw="
              style="position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover"
            />
          </AspectRatio>
        </div>
      </template>,
    )
    const square = new AspectRatioHarness('square')
    assert.deepEqual([square.width, square.height], [192, 192])
    assert.strictEqual(square.ratio, 1)
    const portrait = new AspectRatioHarness('portrait')
    assert.strictEqual(Math.round(portrait.height * 100) / 100, 284.44, '160 × 16 / 9')
    const image = getComputedStyle(portrait.element.querySelector('img')!)
    assert.strictEqual(
      Math.round(Number.parseFloat(image.height) * 100) / 100,
      284.44,
      'the image fills it',
    )
    assert.strictEqual(image.width, '160px')
    await a11yAudit()
  })

  test('RTL: it lays out the same, and fills its container from the right', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <div style="width: 320px">
            <AspectRatio @name="rtl" @ratio={{WIDESCREEN}} />
          </div>
        </DirectionProvider>
      </template>,
    )
    const rtl = new AspectRatioHarness('rtl')
    assert.deepEqual([rtl.width, rtl.height], [320, 180])
    assert.strictEqual(
      rtl.element.getBoundingClientRect().left,
      rtl.wrapper.getBoundingClientRect().left,
      'the inner box covers the outer one',
    )
    await a11yAudit()
  })
})
