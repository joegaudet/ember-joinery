import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

function numberOf(value: string | null): number | null {
  if (value === null || value.trim() === '') return null
  const number = Number(value)
  return Number.isNaN(number) ? null : number
}

/**
 * Drives a `<Progress>`, from `@ember-joinery/ember` or `@ember-joinery/primitives/progress`.
 * Everything comes from its `progressbar` ARIA, as assistive technology reads it, and its
 * `data-state`.
 *
 *   const upload = new ProgressHarness('upload') // <Progress @name="upload">
 *   assert.strictEqual(upload.value, 66)
 *   assert.strictEqual(upload.valueText, '66%')
 */
export class ProgressHarness extends Harness {
  static override component = 'progress'

  /** The bar that shows how far along it is (`data-test-jn-part="indicator"`). */
  get indicator(): HTMLElement {
    return this.part('indicator')
  }

  /** Its value (`aria-valuenow`), or `null` while it is indeterminate. */
  get value(): number | null {
    return numberOf(this.element.getAttribute('aria-valuenow'))
  }

  /** Its maximum (`aria-valuemax`): 100 unless given `@max`. */
  get max(): number {
    return numberOf(this.element.getAttribute('aria-valuemax')) ?? 100
  }

  /** Its minimum (`aria-valuemin`), always 0. */
  get min(): number {
    return numberOf(this.element.getAttribute('aria-valuemin')) ?? 0
  }

  /** What assistive technology announces for the value (`aria-valuetext`): `66%` by default. */
  get valueText(): string | null {
    return this.element.getAttribute('aria-valuetext')
  }

  /** How far along it is, from 0 to 100, or `null` while it is indeterminate. */
  get percent(): number | null {
    const value = this.value
    if (value === null) return null
    return Math.round(((value - this.min) / (this.max - this.min)) * 100 * 100) / 100
  }

  /** Radix's `data-state`: `indeterminate` (no value), `loading`, or `complete` (at its max). */
  get state(): string | null {
    return this.element.getAttribute('data-state')
  }

  /** Whether it has no value, so it shows no particular progress. */
  get isIndeterminate(): boolean {
    return this.value === null
  }

  /** Whether its value is its max. */
  get isComplete(): boolean {
    return this.value !== null && this.value === this.max
  }

  /**
   * Its accessible name: `aria-label`, else the text of the elements `aria-labelledby` names.
   * A `<label for>` doesn't name a progress bar (it isn't a form control), so give it one of
   * those.
   */
  get label(): string {
    const element = this.element
    const label = element.getAttribute('aria-label')
    if (label) return label.trim()
    const labelledBy = element.getAttribute('aria-labelledby')
    if (!labelledBy) return ''
    return labelledBy
      .split(/\s+/)
      .map(id => element.ownerDocument.getElementById(id))
      .filter((found): found is HTMLElement => Boolean(found))
      .map(text)
      .join(' ')
  }
}
