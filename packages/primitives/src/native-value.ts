import { registerDestructor } from '@ember/destroyable'
import { buildWaiter } from '@ember/test-waiters'
import Modifier from 'ember-modifier'
import { ControllableState } from './controllable-state.ts'

const waiter = buildWaiter('@ember-joinery/primitives:native-value')

/** A native form control with a string value: an `<input>`, a `<textarea>` or a `<select>`. */
export type NativeControl = HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement

/** What `{{nativeValue}}` takes: a control's value, by Radix's naming. */
export interface NativeValueArgs {
  /**
   * The value, when you control it. The control always shows it, and a change someone makes
   * goes to `onValueChange`, which decides what it becomes: a change you don't pass back is
   * undone. Leave it out (`undefined`) for a control that keeps its own value.
   */
  value?: string
  /** The value it starts with when you don't control it. */
  defaultValue?: string
  /** Called with the new value whenever someone changes it (on `input`), controlled or not. */
  onValueChange?: (value: string) => void
}

export interface NativeValueSignature {
  Element: NativeControl
  Args: { Named: NativeValueArgs }
}

/**
 * A native control's value, controlled or uncontrolled, as Radix's controls have it (on
 * `ControllableState`). Joinery's Input, Textarea and NativeSelect use it; it works on any
 * `<input>`, `<textarea>` or `<select>` of your own:
 *
 *   <input {{nativeValue value=@value defaultValue=@defaultValue onValueChange=@onValueChange}} />
 *
 * - With `value`, the control shows it, from the start and whenever it changes. Someone typing
 *   (or choosing) calls `onValueChange`, and then the control shows `value` again: pass the new
 *   value back to take the change, change it (a username in lower case), or leave it to refuse
 *   it. While an input method is composing, that waits until it is done.
 * - Without it, the control keeps its own value, starting from `defaultValue`, or with none, from
 *   what it shows when inserted (its `value` attribute, a select's first or `selected` option).
 *   `onValueChange` still hears every change.
 * - A form reset puts the control back to the value it started with, and calls
 *   `onValueChange` with it, as Radix's controls do.
 * - A `<select>` shows the value again when its options change (an `{{#each}}`, data that loads
 *   later). One without an option for the value keeps the option it shows, as React's does.
 *   A file input's value can only be cleared, so it shows only an empty `value`.
 */
export class nativeValue extends Modifier<NativeValueSignature> {
  #named: NativeValueArgs = {}
  #element: NativeControl | undefined
  /** What the control showed when it was inserted, for an uncontrolled one with no default. */
  #shown: string | undefined

  #state = new ControllableState<string>({
    name: 'value',
    value: () => this.#named.value,
    defaultValue: () => this.#named.defaultValue ?? this.#shown,
    onChange: () => this.#named.onValueChange,
    fallback: '',
  })

  override modify(element: NativeControl, _: [], named: NativeValueArgs): void {
    this.#named = named
    if (this.#element !== element) {
      this.#element = element
      registerDestructor(this, this.#connect(element))
    }
    this.#show(element)
  }

  /** Puts the value in the element, unless it shows it already or can't. */
  #show(element: NativeControl): void {
    const value = this.#state.value
    if (element.value === value) return
    // A file input's value can only be cleared; browsers throw on anything else.
    if (element instanceof HTMLInputElement && element.type === 'file' && value !== '') return
    // A select with no option for the value keeps the option it shows, rather than none.
    if (
      element instanceof HTMLSelectElement &&
      ![...element.options].some(option => option.value === value)
    ) {
      return
    }
    element.value = value
  }

  /** Listens to the element, once, and returns what stops it. */
  #connect(element: NativeControl): () => void {
    if (!this.#state.isControlled && this.#named.defaultValue === undefined) {
      this.#shown = element.value
    }
    // What a form reset goes back to.
    const start = this.#state.value

    // Controlled, the caller's new `value` is there as soon as `onValueChange` returns (a
    // component's arguments are read live), so a change it didn't take is undone at once.
    const onInput = (event: Event): void => {
      this.#state.set(element.value)
      if (!(event as InputEvent).isComposing) this.#show(element)
    }
    const onCompositionEnd = (): void => this.#show(element)

    let reset: { timer: ReturnType<typeof setTimeout>; token: unknown } | undefined
    const onReset = (event: Event): void => {
      if (event.target !== element.form || event.defaultPrevented || reset) return
      // The browser resets the form's controls after the event, so this goes after that.
      const token = waiter.beginAsync()
      const timer = setTimeout(() => {
        reset = undefined
        try {
          this.#state.set(start)
          this.#show(element)
        } finally {
          waiter.endAsync(token)
        }
      }, 0)
      reset = { timer, token }
    }

    const options =
      element instanceof HTMLSelectElement ? new MutationObserver(() => this.#show(element)) : null
    options?.observe(element, {
      childList: true,
      subtree: true,
      attributes: true,
      attributeFilter: ['value'],
    })

    const document = element.ownerDocument
    element.addEventListener('input', onInput)
    element.addEventListener('compositionend', onCompositionEnd)
    document.addEventListener('reset', onReset)
    return () => {
      element.removeEventListener('input', onInput)
      element.removeEventListener('compositionend', onCompositionEnd)
      document.removeEventListener('reset', onReset)
      options?.disconnect()
      if (reset) {
        clearTimeout(reset.timer)
        waiter.endAsync(reset.token)
      }
    }
  }
}
