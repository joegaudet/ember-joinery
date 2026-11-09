import { click, fillIn, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { attributes } from './selectors.ts'
import { pressKey, type KeyModifiers } from './focus.ts'
import { accessibleName, textOf } from './-private/checkable.ts'

const SELECTED = '★'
const UNSELECTED = '☆'

/**
 * Drives a `<Rating>` from `@ember-joinery/ember`, or the headless one from
 * `@ember-joinery/primitives/rating`. Its items are native radios, found by their value
 * (`data-test-jn-value`); its rating is the root's `data-value`.
 *
 *   const recipe = new RatingHarness('recipe') // <Rating @name="recipe">
 *   await recipe.select(4)
 *   assert.strictEqual(recipe.value, 4)
 *   assert.strictEqual(recipe.stars, '★ ★ ★ ★ ☆')
 *   await recipe.select(4) // picking it again clears it
 *   assert.strictEqual(recipe.value, 0)
 */
export class RatingHarness extends Harness {
  static override component = 'rating'

  /** The current rating: `0` for none. */
  get value(): number {
    return parseFloat(this.element.getAttribute('data-value') ?? '0')
  }

  /** How many items it has (`data-total`). */
  get total(): number {
    return parseInt(this.element.getAttribute('data-total') ?? '0', 10)
  }

  /** Each item's value, in order. */
  get options(): number[] {
    return this.values('item').map(value => parseFloat(value))
  }

  /** Each item's element, in order. */
  get items(): HTMLElement[] {
    return this.parts('item')
  }

  /** The item worth `value`. Throws when there is none. */
  item(value: number): HTMLElement {
    return this.part('item', String(value))
  }

  /** The radio of the item worth `value`. */
  input(value: number): HTMLInputElement {
    return this.item(value).querySelector('input[type="radio"]')!
  }

  /** Each item as `★` while the rating reaches it, `☆` otherwise, joined with spaces. */
  get stars(): string {
    return this.items
      .map(item => (item.hasAttribute('data-selected') ? SELECTED : UNSELECTED))
      .join(' ')
  }

  /** How much of the item worth `value` the rating fills, from 0 to 100. */
  percentOf(value: number): number {
    return parseFloat(this.item(value).getAttribute('data-percent-selected') ?? '0')
  }

  /** The accessible name of the item worth `value`: `3 stars`. */
  labelOf(value: number): string {
    return accessibleName(this.input(value))
  }

  /** The group's accessible name: its legend, `aria-label` or `aria-labelledby`. */
  get label(): string {
    const named = accessibleName(this.element)
    if (this.element.hasAttribute('aria-label') || this.element.hasAttribute('aria-labelledby')) {
      return named
    }
    const legend = this.element.querySelector(':scope > legend')
    return legend ? textOf(legend) : ''
  }

  /** What a display-only rating says for assistive technology, or `''`: `Rated 3 out of 5`. */
  get summary(): string {
    const summary = this.queryPart('summary')
    return summary ? textOf(summary) : ''
  }

  /** Whether it can't be changed (`aria-readonly="true"`): readonly, or display-only. */
  get isReadonly(): boolean {
    return this.element.getAttribute('aria-readonly') === 'true'
  }

  /** Whether it is disabled (`<fieldset disabled>`). */
  get isDisabled(): boolean {
    return this.element.matches(':disabled')
  }

  /** The value of the item whose radio has focus, or `null`. */
  get focused(): number | null {
    const active = this.element.ownerDocument.activeElement
    if (!(active instanceof HTMLInputElement) || active.type !== 'radio') return null
    if (!this.element.contains(active)) return null
    return parseFloat(active.value)
  }

  /**
   * Picks `value`, as a click on its item does: picking the current rating clears it. A value
   * between the items' is filled in on the rating's range input (`rating.Range`), when it has
   * one.
   */
  async select(value: number): Promise<void> {
    const item = this.queryPart('item', String(value))
    if (item) {
      await click(item.querySelector('input[type="radio"]')!)
      return
    }
    const range = this.queryPart<HTMLInputElement>('range')
    if (range) {
      await fillIn(range, String(value))
      return
    }
    throw new Error(
      `Joinery harness: ${this} has no item worth ${value} (its items: ${this.values('item').join(', ')})`,
    )
  }

  /** Focuses the checked radio, or the first, as Tab does. */
  async focus(): Promise<void> {
    const checked = this.element.querySelector<HTMLInputElement>('input[type="radio"]:checked')
    await focus(checked ?? this.element.querySelector<HTMLInputElement>('input[type="radio"]')!)
  }

  /**
   * Presses a key on the focused radio, and does what the browser does for a native radio
   * group, which a test's events don't make it do: the arrow keys move focus to the next or
   * previous item, going round, and pick it (a click), and Space picks the focused one. Right
   * to left, the left and right arrows swap. Tests can't press real keys, as with `tab()`.
   */
  async press(key: string, modifiers: KeyModifiers = {}): Promise<void> {
    const radios = [...this.element.querySelectorAll<HTMLInputElement>('input[type="radio"]')]
    const active = this.element.ownerDocument.activeElement as HTMLInputElement | null
    const index = active ? radios.indexOf(active) : -1
    const prevented = await pressKey(key, modifiers)
    if (prevented || index === -1) return
    if (key === ' ') {
      await click(radios[index]!)
      return
    }
    const rtl = getComputedStyle(this.element).direction === 'rtl'
    const forward = ['ArrowDown', rtl ? 'ArrowLeft' : 'ArrowRight']
    const backward = ['ArrowUp', rtl ? 'ArrowRight' : 'ArrowLeft']
    let next: number
    if (forward.includes(key)) next = (index + 1) % radios.length
    else if (backward.includes(key)) next = (index - 1 + radios.length) % radios.length
    else return
    const radio = radios[next]!
    await focus(radio)
    if (radio.getAttribute(attributes.part) === 'input') await click(radio)
  }
}
