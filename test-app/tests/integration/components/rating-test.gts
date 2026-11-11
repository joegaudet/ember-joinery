import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { render, rerender } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { Heart } from 'lucide'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import { Icon, Rating } from '@ember-joinery/ember'
import { IconHarness, RatingHarness, tab } from '@ember-joinery/test-support'

/** A colour as the browser resolves it, for comparing with a token. */
function resolved(color: string): string {
  const probe = document.createElement('span')
  probe.style.color = color
  document.querySelector('#ember-testing')!.append(probe)
  const value = getComputedStyle(probe).color
  probe.remove()
  return value
}

const iconOf = (item: HTMLElement) => item.querySelector<SVGElement>('.jn-rating-icon')!

/**
 * The space between one element's bottom and the next one's top, in CSS pixels: the test
 * container is drawn scaled, so its boxes are measured in layout pixels.
 */
function spaceBetween(above: HTMLElement, below: HTMLElement): number {
  const container = document.querySelector<HTMLElement>('#ember-testing')!
  const scale = container.getBoundingClientRect().width / container.offsetWidth
  return (below.getBoundingClientRect().top - above.getBoundingClientRect().bottom) / scale
}

module('Integration | components | rating', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders the primitive with its classes, a legend, and a lucide star per item', async function (assert) {
    await render(
      <template>
        <Rating @name="recipe" @defaultValue={{3}}>
          <:label>Rate this recipe</:label>
        </Rating>
      </template>,
    )
    const rating = new RatingHarness('recipe')
    assert
      .dom(rating.element)
      .hasTagName('fieldset')
      .hasClass('jn-rating')
      .hasAttribute('data-slot', 'rating')
      .hasAttribute('data-size', 'default')
      .hasAttribute('role', 'radiogroup')
    assert
      .dom(rating.part('label'))
      .hasTagName('legend')
      .hasClass('jn-rating-label')
      .hasAttribute('data-slot', 'rating-label')
      .hasText('Rate this recipe')
    assert.strictEqual(rating.label, 'Rate this recipe')
    assert
      .dom(rating.part('items'))
      .hasClass('jn-rating-items')
      .hasAttribute('data-slot', 'rating-items')
    assert.dom(rating.item(1)).hasClass('jn-rating-item').hasAttribute('data-slot', 'rating-item')
    const star = rating.find(IconHarness)
    assert.true(star.isDecorative, 'the star is hidden from assistive technology')
    assert.dom(star.element).hasClass('lucide').hasClass('jn-rating-icon')
    assert.strictEqual(rating.stars, '★ ★ ★ ☆ ☆')
    assert.strictEqual(rating.labelOf(3), '3 stars')
    assert.strictEqual(
      Math.round(spaceBetween(rating.part('label'), rating.part('items'))),
      8,
      'mb-2 under the legend',
    )
    await a11yAudit()
  })

  test('its stylesheet draws outlined stars, filled in --primary up to the rating', async function (assert) {
    await render(
      <template>
        <Rating @name="default" @defaultValue={{2}} aria-label="Default" />
        <Rating @name="sm" @size="sm" aria-label="Small" />
        <Rating @name="lg" @size="lg" aria-label="Large" />
      </template>,
    )
    const rating = new RatingHarness('default')
    const on = getComputedStyle(iconOf(rating.item(2)))
    const off = getComputedStyle(iconOf(rating.item(3)))
    assert.strictEqual(on.width, '20px', 'default: 20px stars')
    assert.strictEqual(on.color, resolved('var(--primary)'))
    assert.strictEqual(on.fill, resolved('var(--primary)'))
    assert.strictEqual(off.color, resolved('var(--muted-foreground)'))
    assert.strictEqual(off.fill, 'rgba(0, 0, 0, 0)', 'outlined')
    assert.strictEqual(getComputedStyle(rating.part('items')).columnGap, '4px', 'gap-1')
    const radio = getComputedStyle(rating.input(1))
    assert.strictEqual(radio.position, 'absolute', 'the radio is visually hidden')
    assert.strictEqual(radio.width, '1px')
    assert.strictEqual(getComputedStyle(rating.element).borderTopWidth, '0px', 'no fieldset frame')
    assert.strictEqual(
      getComputedStyle(iconOf(new RatingHarness('sm').item(1))).width,
      '16px',
      'sm: 16px',
    )
    assert.strictEqual(
      getComputedStyle(iconOf(new RatingHarness('lg').item(1))).width,
      '24px',
      'lg: 24px',
    )
    await a11yAudit()
  })

  test('half ratings: each item is half a star, flipped right to left', async function (assert) {
    await render(
      <template>
        <Rating @name="ltr" @step={{0.5}} @defaultValue={{1.5}} aria-label="Rating" />
        <DirectionProvider @dir="rtl">
          <Rating @name="rtl" @step={{0.5}} @defaultValue={{1.5}} aria-label="تقييم" />
        </DirectionProvider>
      </template>,
    )
    const ltr = new RatingHarness('ltr')
    assert.strictEqual(ltr.total, 10)
    assert.dom(ltr.item(0.5)).hasAttribute('data-half', 'start')
    assert.dom(ltr.item(1)).hasAttribute('data-half', 'end')
    const label = (item: HTMLElement) => item.querySelector('label')!
    assert.strictEqual(label(ltr.item(0.5)).offsetWidth, 10, 'half of a 20px star')
    const start = iconOf(ltr.item(0.5)).getBoundingClientRect()
    const startBox = label(ltr.item(0.5)).getBoundingClientRect()
    assert.strictEqual(
      Math.round(start.left),
      Math.round(startBox.left),
      'the start half shows its left',
    )
    const end = iconOf(ltr.item(1)).getBoundingClientRect()
    const endBox = label(ltr.item(1)).getBoundingClientRect()
    assert.strictEqual(
      Math.round(end.right),
      Math.round(endBox.right),
      'the end half shows its right',
    )
    assert.strictEqual(
      getComputedStyle(ltr.item(1)).marginInlineEnd,
      '4px',
      'a gap after each star',
    )
    assert.strictEqual(ltr.stars, '★ ★ ★ ☆ ☆ ☆ ☆ ☆ ☆ ☆')

    const rtl = new RatingHarness('rtl')
    const first = rtl.item(0.5).getBoundingClientRect()
    const second = rtl.item(1).getBoundingClientRect()
    assert.true(first.left > second.left, 'the first half on the right')
    const rtlStart = iconOf(rtl.item(0.5)).getBoundingClientRect()
    assert.strictEqual(
      Math.round(rtlStart.right),
      Math.round(label(rtl.item(0.5)).getBoundingClientRect().right),
      'right to left, the start half shows its right',
    )
    await a11yAudit()
  })

  test('the keyboard: a ring on the stars while a radio has focus; the arrows pick', async function (assert) {
    await render(<template><Rating @defaultValue={{2}} aria-label="Rating" /></template>)
    const rating = new RatingHarness()
    assert.strictEqual(getComputedStyle(rating.part('items')).boxShadow, 'none')
    await tab()
    assert.strictEqual(rating.focused, 2)
    assert.notStrictEqual(
      getComputedStyle(rating.part('items')).boxShadow,
      'none',
      'has-[:focus-visible]:ring-3',
    )
    await rating.press('ArrowRight')
    assert.strictEqual(rating.value, 3)
    await a11yAudit()
  })

  test('controlled, readonly, display-only and disabled', async function (assert) {
    class State {
      @tracked value = 1
    }
    const state = new State()
    const set = (value: number) => (state.value = value)
    await render(
      <template>
        <Rating @name="controlled" @value={{state.value}} @onValueChange={{set}} aria-label="A" />
        <Rating @name="readonly" @value={{3}} @readonly={{true}} aria-label="B" />
        <Rating @name="display" @value={{4}} @interactive={{false}} />
        <Rating @name="shown" @value={{4}} @interactive={{false}}>
          <:label as |s|>{{s.value}} of {{s.total}}</:label>
        </Rating>
        <Rating @name="disabled" @value={{2}} @disabled={{true}} aria-label="C" />
      </template>,
    )
    const controlled = new RatingHarness('controlled')
    await controlled.select(4)
    assert.strictEqual(state.value, 4)
    assert.strictEqual(controlled.value, 4)
    state.value = 2
    await rerender()
    assert.strictEqual(controlled.stars, '★ ★ ☆ ☆ ☆')

    const readonly = new RatingHarness('readonly')
    assert.true(readonly.isReadonly)
    await readonly.select(5)
    assert.strictEqual(readonly.value, 3)
    assert.strictEqual(getComputedStyle(readonly.item(1).querySelector('label')!).cursor, 'default')

    const display = new RatingHarness('display')
    assert.strictEqual(display.summary, 'Rated 4 out of 5')
    const shown = new RatingHarness('shown')
    assert.dom(shown.part('label')).hasTagName('span').hasText('4 of 5')
    assert.strictEqual(shown.summary, '')
    assert.strictEqual(
      Math.round(spaceBetween(shown.part('label'), shown.part('items'))),
      8,
      'the gap alone spaces a span label, as a legend’s margin does',
    )

    const disabled = new RatingHarness('disabled')
    assert.true(disabled.isDisabled)
    assert.strictEqual(getComputedStyle(disabled.element).opacity, '0.5')
    await a11yAudit()
  })

  test('@icon draws another lucide icon, and @itemLabel names the items', async function (assert) {
    const hearts = (value: number) => `${value} heart${value === 1 ? '' : 's'}`
    await render(
      <template>
        <Rating @icon={{Heart}} @itemLabel={{hearts}} @max={{3}} aria-label="Love it" />
        <Icon @icon={{Heart}} data-test-heart />
      </template>,
    )
    const rating = new RatingHarness()
    assert.strictEqual(
      iconOf(rating.item(1)).innerHTML,
      document.querySelector('[data-test-heart]')!.innerHTML,
      "lucide's Heart",
    )
    assert.deepEqual(
      rating.options.map(value => rating.labelOf(value)),
      ['1 heart', '2 hearts', '3 hearts'],
    )
    await a11yAudit()
  })
})
