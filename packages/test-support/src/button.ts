import { blur, click, focus } from '@ember/test-helpers'
import { Harness } from './harness.ts'

function text(element: Element): string {
  return (element.textContent ?? '').replace(/\s+/g, ' ').trim()
}

/**
 * Drives a `<Button>` from `@ember-joinery/ember`, or an element made a button with its
 * `button` modifier (`<LinkTo {{button}}>`). State comes from the element and its ARIA.
 *
 *   const save = new ButtonHarness('save') // <Button @name="save">
 *   await save.click()
 *   assert.false(save.isDisabled)
 */
export class ButtonHarness extends Harness {
  static override component = 'button'

  /** The text it shows, whitespace collapsed. */
  get text(): string {
    return text(this.element)
  }

  /**
   * Its accessible name, as assistive technology reads it: `aria-label`, else the text of
   * the elements `aria-labelledby` names, else its text. An icon button needs one of the first
   * two.
   */
  get label(): string {
    const element = this.element
    const label = element.getAttribute('aria-label')
    if (label) return label.trim()
    const labelledBy = element.getAttribute('aria-labelledby')
    if (labelledBy) {
      return labelledBy
        .split(/\s+/)
        .map(id => element.ownerDocument.getElementById(id))
        .filter((found): found is HTMLElement => Boolean(found))
        .map(text)
        .join(' ')
    }
    return this.text
  }

  /** Its `@variant`: `default`, `outline`, `secondary`, `ghost`, `destructive` or `link`. */
  get variant(): string | null {
    return this.element.getAttribute('data-variant')
  }

  /** Its `@size`: `default`, `xs`, `sm`, `lg`, `icon`, `icon-xs`, `icon-sm` or `icon-lg`. */
  get size(): string | null {
    return this.element.getAttribute('data-size')
  }

  /** Whether it can't be used: `disabled`, or `aria-disabled="true"` on an element of your own. */
  get isDisabled(): boolean {
    const element = this.element
    if ('disabled' in element && (element as HTMLButtonElement).disabled) return true
    return element.getAttribute('aria-disabled') === 'true'
  }

  /** For a toggle button, whether it is pressed (`aria-pressed`); otherwise `undefined`. */
  get isPressed(): boolean | undefined {
    const pressed = this.element.getAttribute('aria-pressed')
    return pressed === null ? undefined : pressed === 'true'
  }

  /** Whether it has focus. */
  get isFocused(): boolean {
    return this.element.ownerDocument.activeElement === this.element
  }

  /** Clicks it, as a user would. A disabled button ignores the click, as in a browser. */
  async click(): Promise<void> {
    await click(this.element)
  }

  /** Moves focus to it, as tabbing to it would. Fails if it can't take focus. */
  async focus(): Promise<void> {
    await focus(this.element)
  }

  /** Moves focus away from it. */
  async blur(): Promise<void> {
    await blur(this.element)
  }
}
