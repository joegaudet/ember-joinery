import { module, test } from 'qunit'
import { setupRenderingTest } from 'test-app/tests/helpers'
import { click, find, render, rerender } from '@ember/test-helpers'
import { tracked } from '@glimmer/tracking'
import { on } from '@ember/modifier'
import type { TOC } from '@ember/component/template-only'
import { a11yAudit } from 'ember-a11y-testing/test-support'
import { DirectionProvider } from '@ember-joinery/primitives/direction'
import {
  Rating,
  ratingPercent,
  ratingValues,
  type RatingIconSignature,
} from '@ember-joinery/primitives/rating'
import { RatingHarness, tab } from '@ember-joinery/test-support'

module('Integration | primitives | rating', function (hooks) {
  setupRenderingTest(hooks)

  test('it renders a radio group of five native radios, each named, with nothing picked', async function (assert) {
    await render(<template><Rating @name="recipe" aria-label="Rate this recipe" /></template>)
    const rating = new RatingHarness('recipe')
    assert
      .dom(rating.element)
      .hasTagName('fieldset')
      .hasAttribute('role', 'radiogroup')
      .hasAttribute('data-total', '5')
      .hasAttribute('data-value', '0')
      .doesNotHaveAttribute('aria-readonly')
      .doesNotHaveAttribute('data-readonly')
    assert.deepEqual(rating.options, [1, 2, 3, 4, 5])
    assert.strictEqual(rating.value, 0)
    assert.strictEqual(rating.stars, '☆ ☆ ☆ ☆ ☆')
    assert.strictEqual(rating.label, 'Rate this recipe')
    assert.deepEqual(
      rating.options.map(value => rating.labelOf(value)),
      ['1 star', '2 stars', '3 stars', '4 stars', '5 stars'],
    )
    const names = new Set(rating.options.map(value => rating.input(value).name))
    assert.strictEqual(names.size, 1, 'its radios share a name of their own')
    assert.dom('[aria-hidden="true"]', rating.item(1)).hasText('★', 'the default icon')
    await a11yAudit()
  })

  test('a click picks a rating, and a click on the same one clears it', async function (assert) {
    const changes: number[] = []
    const record = (value: number) => changes.push(value)
    await render(<template><Rating @onValueChange={{record}} aria-label="Rating" /></template>)
    const rating = new RatingHarness()
    await rating.select(3)
    assert.strictEqual(rating.value, 3)
    assert.strictEqual(rating.stars, '★ ★ ★ ☆ ☆')
    assert.dom(rating.input(3)).isChecked()
    await rating.select(5)
    assert.strictEqual(rating.stars, '★ ★ ★ ★ ★')
    await rating.select(5)
    assert.strictEqual(rating.value, 0, 'the same one again clears it')
    assert.dom('input:checked').doesNotExist()
    assert.deepEqual(changes, [3, 5, 0])
    await a11yAudit()
  })

  test('controlled: @value shows, and a pick only asks', async function (assert) {
    class State {
      @tracked value = 2
    }
    const state = new State()
    const asked: number[] = []
    const ask = (value: number) => asked.push(value)
    await render(
      <template>
        <Rating @value={{state.value}} @onValueChange={{ask}} aria-label="Rating" />
      </template>,
    )
    const rating = new RatingHarness()
    assert.strictEqual(rating.value, 2)
    await rating.select(4)
    assert.deepEqual(asked, [4])
    assert.strictEqual(rating.value, 2, 'it stays at the controlled value')
    assert.dom(rating.input(2)).isChecked('its radio is put back')
    assert.dom(rating.input(4)).isNotChecked()
    state.value = 4
    await rerender()
    assert.strictEqual(rating.stars, '★ ★ ★ ★ ☆')
    await a11yAudit()
  })

  test('@defaultValue, @max and two ratings on a page apart', async function (assert) {
    await render(
      <template>
        <Rating @name="first" @defaultValue={{1}} aria-label="First" />
        <Rating @name="second" @max={{7}} aria-label="Second" />
      </template>,
    )
    const first = new RatingHarness('first')
    const second = new RatingHarness('second')
    assert.strictEqual(first.value, 1)
    assert.strictEqual(second.total, 7)
    await second.select(7)
    assert.strictEqual(second.value, 7)
    assert.strictEqual(first.value, 1, 'one rating leaves the other alone')
    assert.notStrictEqual(first.input(1).name, second.input(1).name)
    await a11yAudit()
  })

  test('half ratings: @step={{0.5}} gives an item to each half', async function (assert) {
    await render(
      <template><Rating @step={{0.5}} @defaultValue={{3.5}} aria-label="Rating" /></template>,
    )
    const rating = new RatingHarness()
    assert.strictEqual(rating.total, 10)
    assert.deepEqual(rating.options, [0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5])
    assert.strictEqual(rating.value, 3.5)
    assert.dom(rating.element).hasAttribute('data-value', '3.5')
    assert.strictEqual(rating.stars, '★ ★ ★ ★ ★ ★ ★ ☆ ☆ ☆')
    assert.strictEqual(rating.labelOf(3.5), '3.5 stars')
    await rating.select(1.5)
    assert.strictEqual(rating.value, 1.5)
    await rating.select(1.5)
    assert.strictEqual(rating.value, 0)
    await a11yAudit()
  })

  test('data-percent-selected says how much of each item a rating fills', async function (assert) {
    await render(<template><Rating @value={{3.5}} @interactive={{false}} /></template>)
    const rating = new RatingHarness()
    assert.deepEqual(
      rating.options.map(value => rating.percentOf(value)),
      [100, 100, 100, 50, 0],
    )
    assert.strictEqual(ratingPercent(4, 3.25, 1), 25)
    assert.deepEqual(ratingValues(1, 0.1).length, 10, 'steps add up without drift')
    assert.deepEqual(ratingValues(3, 0), [])
    await a11yAudit()
  })

  test('a range input picks values between the items', async function (assert) {
    const Icon: TOC<RatingIconSignature> = <template>{{@value}}</template>
    await render(
      <template>
        <Rating as |r|>
          <legend>Rating</legend>
          <r.Range step="0.25" aria-label="Fine rating" />
          <r.Stars @icon={{Icon}} />
        </Rating>
      </template>,
    )
    const rating = new RatingHarness()
    await rating.select(2.75)
    assert.strictEqual(rating.value, 2.75)
    assert.strictEqual(rating.stars, '★ ★ ☆ ☆ ☆')
    assert.strictEqual(rating.percentOf(3), 75)
    await rating.select(4)
    assert.strictEqual(rating.value, 4, 'an item still picks')
    assert.dom('[aria-hidden="true"]', rating.item(2)).hasText('2', 'the icon component')
    await a11yAudit()
  })

  test('@icon: a string, or a component told each item’s state', async function (assert) {
    const Face: TOC<RatingIconSignature> = <template>
      <span data-face ...attributes>{{if @isSelected "(x)" "()"}}</span>
    </template>
    await render(
      <template>
        <Rating @name="text" @icon="x" aria-label="Text" />
        <Rating @name="faces" @icon={{Face}} @defaultValue={{2}} aria-label="Faces" />
      </template>,
    )
    const text = new RatingHarness('text')
    assert.strictEqual(text.starTexts, 'x x x x x', 'each icon’s text')
    const faces = new RatingHarness('faces')
    assert.strictEqual(faces.starTexts, '(x) (x) () () ()')
    await faces.select(3)
    assert.strictEqual(faces.starTexts, '(x) (x) (x) () ()')
    assert.dom('[data-face]', faces.item(3)).exists('the component renders in the item')
    await a11yAudit()
  })

  test('the harness fills in a number input of the block’s own for values between items', async function (assert) {
    class State {
      @tracked value = 2
      set = (value: number) => (this.value = value)
    }
    const state = new State()
    const setFrom = (event: Event) =>
      state.set(parseFloat((event.target as HTMLInputElement).value))
    await render(
      <template>
        <Rating @value={{state.value}} @onValueChange={{state.set}} aria-label="Score" as |r|>
          <input
            type="number"
            min="0"
            max="5"
            step="0.1"
            aria-label="Score, to a tenth"
            value={{r.value}}
            {{on "change" setFrom}}
          />
          <r.Stars />
        </Rating>
      </template>,
    )
    const rating = new RatingHarness()
    await rating.select(3.4)
    assert.strictEqual(rating.value, 3.4)
    assert.strictEqual(rating.percentOf(4), 40)
    await rating.select(5)
    assert.strictEqual(rating.value, 5, 'an item still picks')
    await a11yAudit()
  })

  test('@readonly shows its rating but keeps it, its radios included', async function (assert) {
    await render(
      <template><Rating @value={{2}} @readonly={{true}} aria-label="Rating" /></template>,
    )
    const rating = new RatingHarness()
    assert.true(rating.isReadonly)
    assert.dom(rating.element).hasAttribute('aria-readonly', 'true').hasAttribute('data-readonly')
    assert.dom(rating.item(1)).hasAttribute('data-readonly')
    await click(rating.input(4))
    assert.strictEqual(rating.value, 2)
    assert.dom('input:checked').hasValue('2', 'the click is cancelled')
    await rating.focus()
    await rating.press('ArrowRight')
    assert.dom('input:checked').hasValue('2', 'the arrow keys change nothing')
    await a11yAudit()
  })

  test('@interactive={{false}} summarises itself, or shows its label block', async function (assert) {
    await render(
      <template>
        <Rating @name="plain" @value={{2}} @interactive={{false}} />
        <Rating @name="labelled" @value={{4}} @interactive={{false}}>
          <:label as |state|>{{state.value}} of {{state.total}}</:label>
        </Rating>
        <Rating
          @name="worded"
          @value={{3}}
          @interactive={{false}}
          @summary={{(summarise)}}
          @itemLabel={{(starWord)}}
        />
      </template>,
    )
    const plain = new RatingHarness('plain')
    assert.true(plain.isReadonly)
    assert.strictEqual(plain.summary, 'Rated 2 out of 5')
    await plain.select(4)
    assert.strictEqual(plain.value, 2)
    const labelled = new RatingHarness('labelled')
    assert.strictEqual(labelled.summary, '')
    assert.dom(labelled.part('label')).hasText('4 of 5')
    const worded = new RatingHarness('worded')
    assert.strictEqual(worded.summary, 'Note : 3 / 5')
    assert.strictEqual(worded.labelOf(2), '2 étoiles')
    await a11yAudit()
  })

  test('the <:label> block is a legend that names the group', async function (assert) {
    await render(
      <template>
        <Rating>
          <:label>Rate me</:label>
        </Rating>
      </template>,
    )
    const rating = new RatingHarness()
    assert.dom('legend', rating.element).hasText('Rate me')
    assert.strictEqual(rating.label, 'Rate me')
    await a11yAudit()
  })

  test('keyboard: Tab reaches the picked radio; the arrows move and pick; Space clears', async function (assert) {
    await render(
      <template>
        <button type="button">Before</button>
        <Rating @defaultValue={{2}} aria-label="Rating" />
      </template>,
    )
    const rating = new RatingHarness()
    await tab()
    await tab()
    assert.strictEqual(rating.focused, 2, 'Tab lands on the picked radio')
    await rating.press('ArrowRight')
    assert.strictEqual(rating.focused, 3)
    assert.strictEqual(rating.value, 3, 'and picks it')
    await rating.press('ArrowLeft')
    assert.strictEqual(rating.value, 2)
    await rating.press('ArrowLeft')
    await rating.press('ArrowLeft')
    assert.strictEqual(rating.value, 5, 'going round at the start')
    await rating.press(' ')
    assert.strictEqual(rating.value, 0, 'Space on the picked one clears it')
    await a11yAudit()
  })

  test('RTL: the first item is on the right, and the arrows swap', async function (assert) {
    await render(
      <template>
        <DirectionProvider @dir="rtl">
          <Rating @defaultValue={{1}} aria-label="تقييم" as |r|>
            <r.Stars style="display: flex" />
          </Rating>
        </DirectionProvider>
      </template>,
    )
    const rating = new RatingHarness()
    const [first, second] = rating.items
    assert.true(
      first!.getBoundingClientRect().left > second!.getBoundingClientRect().left,
      'the first item on the right',
    )
    await rating.focus()
    await rating.press('ArrowLeft')
    assert.strictEqual(rating.value, 2, 'ArrowLeft moves on, right to left')
    await a11yAudit()
  })

  test('in a form, @formName submits the rating; @disabled disables it', async function (assert) {
    class State {
      @tracked disabled = false
    }
    const state = new State()
    await render(
      <template>
        <form data-test-form>
          <Rating
            @formName="stars"
            @defaultValue={{4}}
            @disabled={{state.disabled}}
            aria-label="Rating"
          />
        </form>
      </template>,
    )
    const formElement = find('[data-test-form]') as HTMLFormElement
    assert.deepEqual([...new FormData(formElement).entries()], [['stars', '4']])
    const rating = new RatingHarness()
    state.disabled = true
    await rerender()
    assert.true(rating.isDisabled)
    assert.dom(rating.element).hasAttribute('data-disabled')
    assert.true(
      rating.options.every(value => rating.input(value).matches(':disabled')),
      'every radio is disabled',
    )
    assert.strictEqual(rating.value, 4)
    await a11yAudit()
  })

  test('the harness fails clearly for a value it has no item for', async function (assert) {
    await render(<template><Rating aria-label="Rating" /></template>)
    await assert.rejects(new RatingHarness().select(6), /has no item worth 6/)
    await a11yAudit()
  })
})

function summarise() {
  return ({ value, total }: { value: number; total: number }) => `Note : ${value} / ${total}`
}

function starWord() {
  return (value: number) => `${value} étoile${value === 1 ? '' : 's'}`
}
