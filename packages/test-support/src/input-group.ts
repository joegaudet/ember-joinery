import { blur, click, fillIn, focus, typeIn } from '@ember/test-helpers'
import { Harness } from './harness.ts'
import { NotFoundError } from './-private/tree.ts'
import { controlDescription, controlLabel, isMarkedInvalid, textOf } from './-private/control.ts'
import { selectors } from './selectors.ts'

/** Where an addon goes, as `@align` names it. */
export type InputGroupAlign = 'inline-start' | 'inline-end' | 'block-start' | 'block-end'

/**
 * Drives an `<InputGroup>` from `@ember-joinery/ember`: its control (the input or textarea,
 * `data-slot="input-group-control"`), its addons and their text. Reach the components inside
 * it, such as its buttons, with `find()` or `@child`:
 *
 *   const search = new InputGroupHarness('search') // <InputGroup @name="search">
 *   await search.fillIn('shadcn')
 *   assert.strictEqual(search.addonText('inline-end'), '12 results')
 *   await search.find(ButtonHarness, 'copy').click()
 */
export class InputGroupHarness extends Harness {
  static override component = 'input-group'

  /** The group's control: its input, its textarea, or a control of your own. */
  get control(): HTMLInputElement | HTMLTextAreaElement {
    const control = this.element.querySelector<HTMLInputElement | HTMLTextAreaElement>(
      '[data-slot="input-group-control"]',
    )
    if (!control) throw new NotFoundError(`no control found in ${this}`)
    return control
  }

  /** What the control holds. */
  get value(): string {
    return this.control.value
  }

  /** The control's `placeholder`, or `''`. */
  get placeholder(): string {
    return this.control.getAttribute('placeholder') ?? ''
  }

  /** The control's accessible name: its label, `aria-label`, `title` or placeholder. */
  get label(): string {
    return controlLabel(this.control)
  }

  /** The text of what the control's `aria-describedby` names, or `''`. */
  get description(): string {
    return controlDescription(this.control)
  }

  /** Whether the control is `disabled`. */
  get isDisabled(): boolean {
    return this.control.disabled
  }

  /** Whether the control is marked invalid (`aria-invalid`), which rings the whole group. */
  get isInvalid(): boolean {
    return isMarkedInvalid(this.control)
  }

  /** Whether the control has focus. */
  get isFocused(): boolean {
    return this.control.ownerDocument.activeElement === this.control
  }

  /** Its addons, in document order. */
  get addons(): HTMLElement[] {
    return this.parts('addon')
  }

  /** The first addon at `align` (default: the first addon). Throws when there is none. */
  addon(align?: InputGroupAlign): HTMLElement {
    const addon = align
      ? this.addons.find(element => element.getAttribute('data-align') === align)
      : this.addons[0]
    if (!addon) {
      throw new NotFoundError(`no ${align ? `"${align}" ` : ''}addon found in ${this}`)
    }
    return addon
  }

  /** Each addon's `@align`, in document order. */
  get aligns(): string[] {
    return this.addons.map(addon => addon.getAttribute('data-align') ?? '')
  }

  /** An addon's text, whitespace collapsed. */
  addonText(align?: InputGroupAlign): string {
    return textOf(this.addon(align))
  }

  /** The text of each `Text` part, in document order. */
  get texts(): string[] {
    return this.parts('text').map(text => textOf(text))
  }

  /** Clicks an addon (by `@align`, or the first), which focuses the input unless it is on a button. */
  async clickAddon(align?: InputGroupAlign): Promise<void> {
    await click(this.addon(align))
  }

  /** Replaces what the control holds with `text`, as pasting does. */
  async fillIn(text: string): Promise<void> {
    await fillIn(this.control, text)
  }

  /** Types `text` one key at a time after what the control holds. */
  async typeIn(text: string): Promise<void> {
    await typeIn(this.control, text)
  }

  /** Moves focus to the control. */
  async focus(): Promise<void> {
    await focus(this.control)
  }

  /** Moves focus away from the control. */
  async blur(): Promise<void> {
    await blur(this.control)
  }

  /** The icons it shows (lucide's, drawn by `<Icon>`), in document order. */
  get icons(): SVGSVGElement[] {
    return [...this.element.querySelectorAll<SVGSVGElement>(selectors.component('icon'))]
  }
}
