import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Slider } from '@ember-joinery/ember'
import { SliderHarness } from '@ember-joinery/test-support'

/** A rendered length in pixels. */
const px = (value: string) => Number.parseFloat(value)

/** A colour, resolved by the browser, to compare two. */
function colour(value: string): string {
  const probe = document.createElement('span')
  probe.style.color = value
  document.body.append(probe)
  const resolved = getComputedStyle(probe).color
  probe.remove()
  return resolved
}

class Range {
  @tracked value = [25, 75]
  set = (value: number[]) => (this.value = value)
}

module('Integration | components | slider', function (hooks) {
  setupRenderingTest(hooks)

  test("it renders upstream's track, range and a thumb per value", async function (assert) {
    await render(<template><Slider @defaultValue={{array 25 50}} @name="price" /></template>)
    const slider = new SliderHarness('price')
    assert
      .dom(slider.element)
      .hasTagName('span')
      .hasClass('jn-slider')
      .hasAttribute('data-slot', 'slider')
      .hasAttribute('data-orientation', 'horizontal')
    assert
      .dom(slider.part('track'))
      .hasClass('jn-slider-track')
      .hasAttribute('data-slot', 'slider-track')
    assert
      .dom(slider.part('range'))
      .hasClass('jn-slider-range')
      .hasAttribute('data-slot', 'slider-range')
    assert.dom(slider.part('track')).hasAttribute('data-orientation', 'horizontal')
    assert.strictEqual(slider.thumbs.length, 2)
    for (const thumb of slider.thumbs) {
      assert.dom(thumb).hasClass('jn-slider-thumb').hasAttribute('data-slot', 'slider-thumb')
    }
    assert.deepEqual(slider.value, [25, 50])
    assert.deepEqual(slider.labels, ['Minimum', 'Maximum'])
    assert.strictEqual(slider.max, 100, "upstream's default max")
    await a11yAudit()
  })

  test('its style sheet sizes and colours it, without Tailwind', async function (assert) {
    await render(
      <template>
        <div style="width: 300px">
          <Slider @defaultValue={{array 50}} @name="volume" />
        </div>
      </template>,
    )
    const slider = new SliderHarness('volume')
    const root = getComputedStyle(slider.element)
    const track = getComputedStyle(slider.part('track'))
    const range = getComputedStyle(slider.part('range'))
    const thumb = getComputedStyle(slider.thumb())

    assert.strictEqual(root.display, 'flex')
    assert.strictEqual(root.position, 'relative')
    assert.strictEqual(root.width, '300px', 'w-full')
    assert.strictEqual(root.touchAction, 'none')
    assert.strictEqual(root.userSelect, 'none')
    assert.strictEqual(track.height, '4px', 'data-horizontal:h-1')
    assert.strictEqual(track.width, '300px', 'data-horizontal:w-full')
    assert.true(px(track.borderTopLeftRadius) > 1000, 'rounded-full')
    assert.strictEqual(track.overflow, 'hidden')
    assert.strictEqual(track.backgroundColor, colour('var(--muted)'), 'bg-muted')
    assert.strictEqual(range.position, 'absolute')
    assert.strictEqual(range.height, '4px', 'data-horizontal:h-full')
    assert.strictEqual(range.width, '150px', 'to the thumb, halfway')
    assert.strictEqual(range.backgroundColor, colour('var(--primary)'), 'bg-primary')
    assert.strictEqual(thumb.width, '12px', 'size-3')
    assert.strictEqual(thumb.height, '12px')
    assert.strictEqual(thumb.borderTopWidth, '1px')
    assert.strictEqual(thumb.borderTopColor, colour('var(--ring)'), 'border-ring')
    assert.strictEqual(thumb.backgroundColor, 'rgb(255, 255, 255)', 'bg-white')
    assert.true(px(thumb.borderTopLeftRadius) > 1000, 'rounded-full')
    assert.strictEqual(thumb.boxSizing, 'border-box')
    await a11yAudit()
  })

  test('vertical: it stands at least 10rem tall, with the track down its middle', async function (assert) {
    await render(
      <template>
        {{! h-full: as tall as its container, but no less than 10rem }}
        <div style="height: 40px">
          <Slider @defaultValue={{array 50}} @orientation="vertical" @name="level" />
        </div>
      </template>,
    )
    const slider = new SliderHarness('level')
    const root = getComputedStyle(slider.element)
    assert.strictEqual(slider.orientation, 'vertical')
    assert.strictEqual(root.flexDirection, 'column', 'data-vertical:flex-col')
    assert.strictEqual(root.minHeight, '160px', 'data-vertical:min-h-40')
    const track = getComputedStyle(slider.part('track'))
    assert.strictEqual(track.width, '4px', 'data-vertical:w-1')
    assert.strictEqual(px(track.height), 160)
    assert.strictEqual(getComputedStyle(slider.part('range')).height, '80px', 'halfway up')
    await a11yAudit()
  })

  test('disabled: dimmed, and out of the tab order', async function (assert) {
    await render(<template><Slider @defaultValue={{array 50}} @disabled={{true}} /></template>)
    const slider = new SliderHarness()
    assert.true(slider.isDisabled)
    assert.strictEqual(getComputedStyle(slider.element).opacity, '0.5', 'data-disabled:opacity-50')
    assert.dom(slider.thumb()).doesNotHaveAttribute('tabindex')
    await a11yAudit()
  })

  test('the keys, controlled', async function (assert) {
    const range = new Range()
    await render(
      <template>
        <Slider @value={{range.value}} @onValueChange={{range.set}} @step={{5}} />
      </template>,
    )
    const slider = new SliderHarness()
    await slider.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(range.value, [30, 75])
    await slider.press('End', { thumb: 1 })
    assert.deepEqual(slider.value, [30, 100])
    range.value = [0, 10]
    await settled()
    assert.deepEqual(slider.value, [0, 10])
    await a11yAudit()
  })

  test('RTL: the range fills from the right', async function (assert) {
    await render(
      <template>
        <div style="width: 200px">
          <DirectionProvider @dir="rtl">
            <Slider @defaultValue={{array 25}} />
          </DirectionProvider>
        </div>
      </template>,
    )
    const slider = new SliderHarness()
    const range = getComputedStyle(slider.part('range'))
    assert.strictEqual(range.right, '0px', 'its start is the right')
    assert.strictEqual(range.width, '50px')
    const thumb = slider.thumb().parentElement!
    assert.strictEqual(
      px(getComputedStyle(thumb).right),
      50 - 3,
      'a quarter in, less a quarter of its size',
    )
    await slider.press('ArrowLeft')
    assert.deepEqual(slider.value, [26], 'the left arrow steps up')
    await a11yAudit()
  })
})
