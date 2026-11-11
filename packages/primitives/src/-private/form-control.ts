import { tracked } from '@glimmer/tracking'
import { registerDestructor } from '@ember/destroyable'
import { waitForPromise } from '@ember/test-waiters'
import Modifier from 'ember-modifier'

/** The attributes of a control (or a radio group's root) that its hidden input repeats. */
const MIRRORED = ['name', 'value', 'form'] as const

/** The form an element belongs to: its `form` attribute's, else the nearest `<form>`. */
function formOf(element: HTMLElement): HTMLFormElement | null {
  const owner = (element as Partial<HTMLButtonElement>).form
  if (owner instanceof HTMLFormElement) return owner
  const id = element.getAttribute('form')
  if (id) {
    const named = element.ownerDocument.getElementById(id)
    return named instanceof HTMLFormElement ? named : null
  }
  return element.closest('form')
}

/** Enter doesn't check a checkbox or choose a radio: only Space does, as natively. */
export function preventEnter(event: KeyboardEvent): void {
  if (event.key === 'Enter') event.preventDefault()
}

export interface FormControlOptions {
  /** Called when the control's form is reset: Radix's Checkbox goes back to its first state. */
  onReset?: () => void
  /**
   * The form field's name, when it comes from an argument rather than the element's `name`
   * attribute: a radio group's root is a `<div>`, which has none.
   */
  name?: () => string | null | undefined
}

interface SourceSignature {
  Element: HTMLElement
}

/**
 * A control's ties to its form, as Radix's Checkbox, Switch and RadioGroup keep them. Radix's
 * controls are buttons, which a form doesn't submit, so in a form each renders a hidden native
 * input beside it (Radix's "bubble input"): the form submits that, checks it when it is
 * `required`, and resets it. This keeps what that input needs:
 *
 * - whether the control is in a form at all (its `form` attribute's, or the nearest `<form>`),
 *   so the input renders only there;
 * - the `name`, `value` and `form` attributes the caller put on the control (or on a radio
 *   group's root), which the input repeats, and follows when they change.
 *
 * It reads them after the control renders, since a render can't change what it has read.
 */
export class FormControl {
  /** Whether the control is in a form, so its hidden input should render. */
  @tracked isFormControl = false
  /** The caller's `name`, the form field the input submits. */
  @tracked name: string | null = null
  /** The caller's `value`, what the input submits when checked. */
  @tracked value: string | null = null
  /** The caller's `form`, the id of the form the control belongs to from outside it. */
  @tracked form: string | null = null

  /** The name the hidden input submits under: the `name` option's, else the `name` attribute's. */
  get fieldName(): string | null {
    return this.#options.name?.() ?? this.name
  }

  /** Put it on the element whose `name`, `value` and `form` the hidden input repeats. */
  readonly source: typeof Modifier<SourceSignature>

  readonly #options: FormControlOptions
  #element: HTMLElement | undefined
  #formElement: HTMLFormElement | null = null

  constructor(options: FormControlOptions = {}) {
    this.#options = options
    this.source = sourceModifier(this)
  }

  /** @internal Starts reading `element`; returns what stops it. */
  connect(element: HTMLElement): () => void {
    this.#element = element
    const observer = new MutationObserver(() => this.#sync())
    observer.observe(element, { attributes: true, attributeFilter: [...MIRRORED] })
    void waitForPromise(Promise.resolve().then(() => this.#sync()))
    return () => {
      observer.disconnect()
      this.#listen(null)
      if (this.#element === element) this.#element = undefined
    }
  }

  #sync(): void {
    const element = this.#element
    if (!element) return
    for (const name of MIRRORED) {
      const value = element.getAttribute(name)
      if (this[name] !== value) this[name] = value
    }
    const form = formOf(element)
    this.#listen(form)
    if (this.isFormControl !== Boolean(form)) this.isFormControl = Boolean(form)
  }

  #listen(form: HTMLFormElement | null): void {
    if (this.#formElement === form) return
    this.#formElement?.removeEventListener('reset', this.#onReset)
    this.#formElement = form
    form?.addEventListener('reset', this.#onReset)
  }

  #onReset = (): void => this.#options.onReset?.()
}

function sourceModifier(control: FormControl): typeof Modifier<SourceSignature> {
  return class FormControlSource extends Modifier<SourceSignature> {
    #installed = false

    override modify(element: HTMLElement): void {
      if (this.#installed) return
      this.#installed = true
      registerDestructor(this, control.connect(element))
    }
  }
}

export interface BubbleInputModifierSignature {
  Element: HTMLInputElement
  Args: {
    Named: {
      checked: boolean
      indeterminate?: boolean
      /** Whether unchecking fires `input` and `change` too. A radio's doesn't, as natively. */
      announceUncheck?: boolean
    }
  }
}

/**
 * Keeps the hidden input in step with its control, as Radix's bubble input does: it lies over
 * the control (so the browser's "please check this box" points at it), unseen and out of the
 * way of the pointer, checked when the control is, and it fires `input` and `change` at the
 * form whenever that changes, as a native input would. Its styles go through the CSSOM, so a
 * strict Content Security Policy allows them.
 */
export class BubbleInput extends Modifier<BubbleInputModifierSignature> {
  #last: { checked: boolean; indeterminate: boolean } | undefined

  override modify(
    input: HTMLInputElement,
    _: [],
    {
      checked,
      indeterminate = false,
      announceUncheck = true,
    }: BubbleInputModifierSignature['Args']['Named'],
  ): void {
    const last = this.#last
    if (input.indeterminate !== indeterminate) input.indeterminate = indeterminate
    if (input.checked !== checked) input.checked = checked
    this.#last = { checked, indeterminate }
    if (!last) return this.#place(input, checked)
    if (last.checked === checked && last.indeterminate === indeterminate) return
    if (!checked && !announceUncheck) return
    input.dispatchEvent(new Event('input', { bubbles: true }))
    input.dispatchEvent(new Event('change', { bubbles: true }))
  }

  #place(input: HTMLInputElement, checked: boolean): void {
    // What a form reset goes back to.
    input.defaultChecked = checked
    const control = input.previousElementSibling
    const box = control?.getBoundingClientRect()
    const style = input.style
    style.setProperty('position', 'absolute')
    style.setProperty('pointer-events', 'none')
    style.setProperty('opacity', '0')
    style.setProperty('margin', '0')
    // It comes after the control, so this pulls it back over the control.
    style.setProperty('transform', 'translateX(-100%)')
    if (box) {
      style.setProperty('width', `${box.width}px`)
      style.setProperty('height', `${box.height}px`)
    }
  }
}
