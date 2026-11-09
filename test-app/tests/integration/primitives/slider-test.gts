import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, settled, triggerKeyEvent } from '@ember/test-helpers'
import { array } from '@ember/helper'
import { on } from '@ember/modifier'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Slider, defaultSliderThumbLabel } from '@ember-joinery/primitives/slider'
import { SliderHarness, tab } from '@ember-joinery/test-support'

/**
 * An unstyled slider with the shape upstream's styles give it: a 200px track, and 10px thumbs
 * placed against it. The primitive places the parts; this only gives them a size.
 */
const STYLE = `
  [data-case] { display: flex; position: relative; align-items: center; width: 200px; height: 20px; touch-action: none; }
  [data-case][data-orientation='vertical'] { flex-direction: column; width: 20px; height: 200px; }
  [data-case] [data-test-jn-part='track'] { position: relative; flex-grow: 1; align-self: stretch; }
  [data-case] [data-test-jn-part='range'] { position: absolute; top: 0; bottom: 0; background: black; }
  [data-case][data-orientation='vertical'] [data-test-jn-part='range'] { left: 0; right: 0; top: auto; bottom: auto; }
  [data-case] [data-test-jn-part='thumb'] { display: block; width: 10px; height: 10px; background: gray; }
  [data-case] output { position: absolute; top: 100%; }
`

class Values {
  @tracked value: number[] = [25, 75]
  changes: unknown[] = []
  commits: unknown[] = []
  change = (value: unknown) => {
    this.changes.push(value)
    if (Array.isArray(value)) this.value = value as number[]
  }
  commit = (value: unknown) => this.commits.push(value)
}

/**
 * Where an element sits along a slider, as shares of the slider's length from where its values
 * start (the left, the right in RTL, or the bottom). Shares, not pixels: the test container is
 * scaled to half size, and a share is the same either way.
 */
function along(element: Element, slider: Element) {
  const root = slider.getBoundingClientRect()
  const box = element.getBoundingClientRect()
  if (slider.getAttribute('data-orientation') === 'vertical') {
    const length = root.height
    return { start: (root.bottom - box.bottom) / length, size: box.height / length }
  }
  const length = root.width
  const rtl = getComputedStyle(slider).direction === 'rtl'
  const start = rtl ? root.right - box.right : box.left - root.left
  return { start: start / length, size: box.width / length }
}

/** Two shares, as near as layout rounding leaves them. */
function near(actual: number, expected: number): boolean {
  return Math.abs(actual - expected) < 0.01
}

module('Integration | primitives | slider', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a role="slider" thumb per value, with its value in ARIA', async function (assert) {
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider @defaultValue={{array 25 75}} @name="price" data-case as |s|>
          <s.Track><s.Range /></s.Track>
          {{#each s.thumbs as |thumb|}}
            <s.Thumb @index={{thumb.index}} />
          {{/each}}
          <output>{{s.min}}–{{s.max}} by {{s.step}}: {{s.values.length}}</output>
        </Slider>
      </template>,
    )
    const slider = new SliderHarness('price')
    assert.dom(slider.element).hasTagName('span').hasAttribute('data-orientation', 'horizontal')
    assert.dom(slider.element).doesNotHaveAttribute('data-disabled')
    assert.strictEqual(slider.thumbs.length, 2)
    for (const thumb of slider.thumbs) {
      assert
        .dom(thumb)
        .hasAttribute('role', 'slider')
        .hasAttribute('aria-valuemin', '0')
        .hasAttribute('aria-valuemax', '100')
        .hasAttribute('aria-orientation', 'horizontal')
        .hasAttribute('tabindex', '0')
    }
    assert.deepEqual(slider.value, [25, 75])
    assert.deepEqual(slider.labels, ['Minimum', 'Maximum'], "Radix's names for a range")
    assert.strictEqual(slider.min, 0)
    assert.strictEqual(slider.max, 100)
    assert.dom('output').hasText('0–100 by 1: 2', 'it yields its bounds, step and values')
    assert.dom('[data-test-jn-part="track"]').hasAttribute('data-orientation', 'horizontal')
    assert.dom('[data-test-jn-part="range"]').hasAttribute('data-orientation', 'horizontal')
    await a11yAudit()
  })

  test('the default thumb names, and @getThumbLabel', async function (assert) {
    const label = (index: number, count: number) => `Band ${index + 1} of ${count}`
    await render(
      <template>
        <Slider @defaultValue={{array 50}} @name="one" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
        <Slider @defaultValue={{array 10 20 30}} @name="three" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
        <Slider @defaultValue={{array 10 20}} @getThumbLabel={{label}} @name="own" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
        <Slider @defaultValue={{array 10}} @name="labelled" as |s|>
          <span id="volume-label">Volume</span>
          <s.Thumb aria-labelledby="volume-label" />
        </Slider>
      </template>,
    )
    assert.deepEqual(new SliderHarness('one').labels, ['Value'], "ember-primitives' name for one")
    assert.deepEqual(new SliderHarness('three').labels, [
      'Value 1 of 3',
      'Value 2 of 3',
      'Value 3 of 3',
    ])
    assert.deepEqual(new SliderHarness('own').labels, ['Band 1 of 2', 'Band 2 of 2'])
    assert.deepEqual(new SliderHarness('labelled').labels, ['Volume'], 'aria-labelledby wins')
    assert.strictEqual(defaultSliderThumbLabel(1, 2), 'Maximum')
    await a11yAudit()
  })

  test('uncontrolled: the APG keys step the focused thumb, and commit each step', async function (assert) {
    const values = new Values()
    await render(
      <template>
        <Slider
          @defaultValue={{array 50}}
          @onValueChange={{values.change}}
          @onValueCommit={{values.commit}}
          as |s|
        >
          <s.Thumb />
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    await slider.focus()
    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [51], 'ArrowRight steps up')
    await slider.press('ArrowUp')
    assert.deepEqual(slider.value, [52], 'ArrowUp steps up')
    await slider.press('ArrowLeft')
    await slider.press('ArrowDown')
    assert.deepEqual(slider.value, [50], 'ArrowLeft and ArrowDown step down')
    await slider.press('PageUp')
    assert.deepEqual(slider.value, [60], 'PageUp steps ten')
    await slider.press('ArrowRight', { shiftKey: true })
    assert.deepEqual(slider.value, [70], 'Shift+Arrow steps ten')
    await slider.press('PageDown')
    assert.deepEqual(slider.value, [60])
    await slider.press('End')
    assert.deepEqual(slider.value, [100], 'End goes to the max')
    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [100], 'not past it')
    await slider.press('Home')
    assert.deepEqual(slider.value, [0], 'Home goes to the min')
    assert.deepEqual(values.changes, [[51], [52], [51], [50], [60], [70], [60], [100], [0]])
    assert.deepEqual(values.commits, values.changes, 'a key commits as it moves')
    assert.strictEqual(slider.focused, 0, 'focus stays on the thumb')
    await a11yAudit()
  })

  test('controlled: @value is the value, and @onValueChange asks for a new one', async function (assert) {
    const values = new Values()
    const asked: unknown[] = []
    const ask = (value: unknown) => asked.push(value)
    await render(
      <template>
        <Slider @value={{values.value}} @onValueChange={{values.change}} @name="taken" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
        <Slider @value={{array 10 90}} @onValueChange={{ask}} @name="kept" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
      </template>,
    )
    const taken = new SliderHarness('taken')
    await taken.press('ArrowRight', { thumb: 1 })
    assert.deepEqual(values.changes, [[25, 76]])
    assert.deepEqual(taken.value, [25, 76], 'the caller took it')

    values.value = [10, 90]
    await settled()
    assert.deepEqual(taken.value, [10, 90], 'it follows @value')

    const kept = new SliderHarness('kept')
    await kept.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(asked, [[11, 90]], 'it asked')
    assert.deepEqual(kept.value, [10, 90], 'but stays as the caller has it')
    await a11yAudit()
  })

  test('a number value gives a number back, as ember-primitives does', async function (assert) {
    const changes: unknown[] = []
    const change = (value: number) => changes.push(value)
    await render(
      <template>
        <Slider @defaultValue={{40}} @step={{5}} @onValueChange={{change}} as |s|>
          <s.Thumb />
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    await slider.press('ArrowRight')
    assert.deepEqual(changes, [45])
    assert.deepEqual(slider.value, [45])
    await a11yAudit()
  })

  test('thumbs pass each other, and focus follows the value that moved', async function (assert) {
    await render(
      <template>
        <Slider @defaultValue={{array 10 12}} @name="free" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
        <Slider @defaultValue={{array 10 12}} @minStepsBetweenThumbs={{1}} @name="apart" as |s|>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
      </template>,
    )
    const free = new SliderHarness('free')
    await free.press('ArrowRight', { thumb: 0 })
    await free.press('ArrowRight')
    assert.deepEqual(free.value, [12, 12], 'they can meet')
    await free.press('ArrowRight')
    assert.deepEqual(free.value, [12, 13], 'and pass: the values stay sorted')
    assert.strictEqual(free.focused, 1, 'focus moved to the thumb now holding the value')

    const apart = new SliderHarness('apart')
    await apart.press('ArrowRight', { thumb: 0 })
    assert.deepEqual(apart.value, [11, 12])
    await apart.press('ArrowRight')
    assert.deepEqual(apart.value, [11, 12], '@minStepsBetweenThumbs keeps them a step apart')
    await a11yAudit()
  })

  test('a @step array snaps to its values, evenly spaced', async function (assert) {
    const changes: unknown[] = []
    const change = (value: number) => changes.push(value)
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider
          @defaultValue={{10}}
          @step={{array 50 0 10 20 20}}
          @onValueChange={{change}}
          data-case
          as |s|
        >
          <s.Track><s.Range /></s.Track>
          <s.Thumb />
          <output>{{#each s.tickValues as |tick|}}{{tick}} {{/each}}</output>
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    assert.dom('output').hasText('0 10 20 50', 'the ticks, sorted and unique')
    assert.strictEqual(slider.min, 0)
    assert.strictEqual(slider.max, 50)
    assert.deepEqual(slider.value, [10])
    assert.true(
      near(along(slider.part('range'), slider.element).size, 1 / 3),
      'one tick of three along',
    )

    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [20])
    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [50], 'the next tick, however far')
    await slider.press('Home')
    assert.deepEqual(changes, [20, 50, 0])
    await a11yAudit()
  })

  test('the range and thumbs place themselves, kept inside the track', async function (assert) {
    const values = new Values()
    values.value = [0, 50]
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider @value={{values.value}} @onValueChange={{values.change}} data-case as |s|>
          <s.Track><s.Range /></s.Track>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    const range = along(slider.part('range'), slider.element)
    assert.true(near(range.start, 0), 'the range starts at the first thumb')
    assert.true(near(range.size, 0.5), 'and ends at the second')

    const thumb = along(slider.thumb(0), slider.element).size
    const [first, second] = slider.thumbs.map(element => along(element, slider.element))
    assert.true(near(first!.start, 0), 'at the min, the thumb touches the start')
    assert.true(near(second!.start + thumb / 2, 0.5), 'halfway, it is centred')

    values.value = [0, 100]
    await settled()
    const end = along(slider.thumb(1), slider.element)
    assert.true(near(end.start + end.size, 1), 'at the max, it touches the end')
    assert.true(near(along(slider.part('range'), slider.element).size, 1))
    await a11yAudit()
  })

  test('the pointer: a press on the track moves the nearest thumb, and a drag slides it', async function (assert) {
    const values = new Values()
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider
          @value={{values.value}}
          @onValueChange={{values.change}}
          @onValueCommit={{values.commit}}
          data-case
          as |s|
        >
          <s.Track><s.Range /></s.Track>
          {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    await slider.slideTo(60)
    assert.deepEqual(slider.value, [25, 60], 'the nearer thumb moved there')
    assert.strictEqual(slider.focused, 1, 'and took focus')
    assert.deepEqual(values.commits, [[25, 60]], 'letting go commits')

    await slider.drag(10, { thumb: 0 })
    assert.deepEqual(slider.value, [10, 60], 'dragged')
    assert.strictEqual(slider.focused, 0)
    assert.deepEqual(values.commits.at(-1), [10, 60])

    await slider.drag(90, { thumb: 0 })
    assert.deepEqual(slider.value, [60, 90], 'dragged past the other, the values stay sorted')
    assert.strictEqual(slider.focused, 1, 'and the dragged value keeps the focus')
    await a11yAudit()
  })

  test('disabled: out of the tab order, and neither keys nor pointer move it', async function (assert) {
    const values = new Values()
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider
          @defaultValue={{array 50}}
          @disabled={{true}}
          @onValueChange={{values.change}}
          data-case
          as |s|
        >
          <s.Track><s.Range /></s.Track>
          <s.Thumb />
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    assert.true(slider.isDisabled)
    assert.dom(slider.element).hasAttribute('aria-disabled', 'true')
    assert.dom(slider.thumb()).doesNotHaveAttribute('tabindex').hasAttribute('data-disabled')
    assert.dom(slider.part('track')).hasAttribute('data-disabled')
    await tab()
    assert.strictEqual(slider.focused, null, 'Tab passes it by')

    await triggerKeyEvent(slider.thumb(), 'keydown', 'ArrowRight')
    await slider.slideTo(90)
    assert.deepEqual(slider.value, [50])
    assert.deepEqual(values.changes, [])
    await a11yAudit()
  })

  test('vertical: up is up, and the values run from the bottom', async function (assert) {
    const values = new Values()
    values.value = [50]
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider
          @value={{values.value}}
          @onValueChange={{values.change}}
          @orientation="vertical"
          data-case
          as |s|
        >
          <s.Track><s.Range /></s.Track>
          <s.Thumb />
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    assert.strictEqual(slider.orientation, 'vertical')
    assert.dom(slider.thumb()).hasAttribute('aria-orientation', 'vertical')
    await slider.press('ArrowUp')
    assert.deepEqual(slider.value, [51])
    await slider.press('ArrowLeft')
    assert.deepEqual(slider.value, [50])

    const range = along(slider.part('range'), slider.element)
    assert.true(near(range.start, 0), 'the range fills from the bottom')
    assert.true(near(range.size, 0.5), 'to the thumb')

    await slider.slideTo(20)
    assert.deepEqual(slider.value, [20], 'a press near the bottom is near the min')
    await a11yAudit()
  })

  test('RTL: the values run from the right, and the arrows follow', async function (assert) {
    const values = new Values()
    values.value = [25]
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <DirectionProvider @dir="rtl">
          <Slider @value={{values.value}} @onValueChange={{values.change}} data-case as |s|>
            <s.Track><s.Range /></s.Track>
            <s.Thumb />
          </Slider>
        </DirectionProvider>
      </template>,
    )
    const slider = new SliderHarness()
    const root = slider.element.getBoundingClientRect()
    const box = slider.part('range').getBoundingClientRect()
    assert.true(near((root.right - box.right) / root.width, 0), 'the range fills from the right')
    const range = along(slider.part('range'), slider.element)
    assert.true(near(range.size, 0.25), 'a quarter of the way')
    const thumb = along(slider.thumb(), slider.element)
    assert.true(
      near(thumb.start, 0.25 * (1 - thumb.size)),
      'the thumb is a quarter in, from the right',
    )

    await slider.press('ArrowLeft')
    assert.deepEqual(slider.value, [26], 'ArrowLeft steps up, right to left')
    await slider.press('ArrowRight')
    assert.deepEqual(slider.value, [25], 'ArrowRight steps down')

    await slider.slideTo(75)
    assert.deepEqual(slider.value, [75], 'a press three quarters from the right')
    await a11yAudit()
  })

  test('@inverted runs the values the other way', async function (assert) {
    await render(
      <template>
        <style>
          {{STYLE}}
        </style>
        <Slider @defaultValue={{array 25}} @inverted={{true}} data-case as |s|>
          <s.Track><s.Range /></s.Track>
          <s.Thumb />
        </Slider>
      </template>,
    )
    const slider = new SliderHarness()
    const root = slider.element.getBoundingClientRect()
    const box = slider.part('range').getBoundingClientRect()
    assert.true(near((root.right - box.right) / root.width, 0), 'it fills from the right')
    await slider.press('ArrowLeft')
    assert.deepEqual(slider.value, [26], 'from the right, ArrowLeft steps up')
    await a11yAudit()
  })

  test('@fieldName puts each value in its form, and tells the form when it changes', async function (assert) {
    let inputs = 0
    const count = () => inputs++
    await render(
      <template>
        <form id="filters" {{on "input" count}}>
          <Slider @defaultValue={{array 20 80}} @fieldName="price" @name="price" as |s|>
            {{#each s.thumbs as |thumb|}}<s.Thumb @index={{thumb.index}} />{{/each}}
          </Slider>
        </form>
        <Slider @defaultValue={{array 3}} @fieldName="rating" @form="filters" @name="rating" as |s|>
          <s.Thumb />
        </Slider>
      </template>,
    )
    // Not `form`: a binding by that name would turn the template's <form> into a call to it.
    const filters = document.querySelector<HTMLFormElement>('#filters')!
    assert.deepEqual(
      [...new FormData(filters).entries()],
      [
        ['price[]', '20'],
        ['price[]', '80'],
        ['rating', '3'],
      ],
    )
    await new SliderHarness('price').press('ArrowRight', { thumb: 0 })
    assert.deepEqual(new FormData(filters).getAll('price[]'), ['21', '80'])
    assert.strictEqual(inputs, 1, 'an input event bubbled to the form')
    await a11yAudit()
  })
})
