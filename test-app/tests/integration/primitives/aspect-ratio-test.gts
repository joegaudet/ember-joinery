import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { AspectRatio } from '@ember-joinery/primitives/aspect-ratio'
import { AspectRatioHarness } from '@ember-joinery/test-support'

const WIDESCREEN = 16 / 9
const PORTRAIT = 9 / 16

module('Integration | primitives | aspect-ratio', function (hooks) {
  setupRenderingTest(hooks)

  test('it holds its content to the ratio, as wide as its container', async function (assert) {
    await render(
      <template>
        <div style="width: 320px">
          <AspectRatio @name="wide" @ratio={{WIDESCREEN}} class="mine">
            <div id="content" style="width: 100%; height: 100%"></div>
          </AspectRatio>
        </div>
        <div style="width: 160px">
          <AspectRatio @name="tall" @ratio={{PORTRAIT}} />
        </div>
        <div style="width: 100px">
          <AspectRatio @name="square" />
        </div>
      </template>,
    )
    const wide = new AspectRatioHarness('wide')
    assert.dom(wide.element).hasTagName('div').hasClass('mine')
    assert.dom(wide.element).doesNotHaveAttribute('data-slot', 'no styles, so no slot')
    assert.strictEqual(wide.width, 320)
    assert.strictEqual(wide.height, 180, '320 × 9 / 16')
    assert.strictEqual(Math.round(wide.ratio * 1000) / 1000, 1.778)
    const content = getComputedStyle(document.querySelector('#content')!)
    assert.deepEqual([content.width, content.height], ['320px', '180px'], 'the content fills it')

    const tall = new AspectRatioHarness('tall')
    assert.deepEqual([tall.width, Math.round(tall.height * 100) / 100], [160, 284.44])

    const square = new AspectRatioHarness('square')
    assert.deepEqual([square.width, square.height], [100, 100], 'a square without @ratio')
    await a11yAudit()
  })

  test('it is the inner of two boxes, like Radix', async function (assert) {
    await render(
      <template>
        <div style="width: 200px">
          <AspectRatio @ratio={{2}} style="color: rebeccapurple" />
        </div>
      </template>,
    )
    const harness = new AspectRatioHarness()
    const { wrapper, element } = harness
    assert.dom(wrapper).hasAttribute('data-jn-aspect-ratio-wrapper')
    assert.strictEqual(wrapper.style.position, 'relative')
    assert.strictEqual(wrapper.style.width, '100%')
    assert.strictEqual(wrapper.style.paddingBottom, '50%')
    assert.strictEqual(element.style.position, 'absolute')
    assert.deepEqual(
      [element.style.top, element.style.right, element.style.bottom, element.style.left],
      ['0px', '0px', '0px', '0px'],
    )
    assert.strictEqual(element.style.color, 'rebeccapurple', 'its own style stays')
    assert.strictEqual(harness.height, 100)
    await a11yAudit()
  })

  test('it follows @ratio, and @as renders another tag', async function (assert) {
    class State {
      @tracked ratio = 1
    }
    const state = new State()
    await render(
      <template>
        <div style="width: 300px">
          <AspectRatio @as="section" aria-label="Map" @ratio={{state.ratio}} />
        </div>
      </template>,
    )
    const harness = new AspectRatioHarness()
    assert.dom(harness.element).hasTagName('section')
    assert.strictEqual(harness.height, 300)
    state.ratio = 3
    await settled()
    assert.strictEqual(harness.height, 100)
    state.ratio = 0
    await settled()
    assert.strictEqual(harness.height, 300, 'a ratio it cannot use is a square')
    await a11yAudit()
  })
})
