import { registerDestructor } from '@ember/destroyable'
import Modifier from 'ember-modifier'
import { Maskito, maskitoTransform, type MaskitoOptions } from '@maskito/core'

export type { MaskitoOptions }

/** The input or textarea a mask goes on. */
export type MaskedElement = HTMLInputElement | HTMLTextAreaElement

export interface MaskitoSignature {
  Element: MaskedElement
  Args: {
    /** The Maskito options, such as a preset's (`numberMask()`); none leaves the element alone. */
    Positional: [options: MaskitoOptions | null | undefined]
  }
}

/**
 * Puts what the element holds through the mask now, as Maskito does after an `input` it didn't
 * see coming (a paste or autofill without `beforeinput`, or a test's `fillIn`). Maskito does the
 * same once the event reaches its own listener, and then sends a second `input` with the masked
 * text; doing it here, in the capture phase, first, means every `input` listener on the element,
 * wherever it was added, reads the masked text.
 */
function fitToMask(element: MaskedElement, options: MaskitoOptions, event: Event): void {
  if ((event as InputEvent).inputType === 'insertCompositionText') return
  const { value, selectionStart, selectionEnd } = element
  const state = maskitoTransform(
    { value, selection: [selectionStart ?? 0, selectionEnd ?? 0] },
    options,
  )
  if (state.value === value) return
  element.value = state.value
  if (element.matches(':focus')) element.setSelectionRange(...state.selection)
}

/**
 * Masks an `<input>` or `<textarea>` of your own as it is typed in, with
 * [Maskito](https://maskito.dev): give it any Maskito options, such as those of a preset
 * (`numberMask`, `dateMask`, `timeMask`…) or your own `{ mask: [...] }`.
 *
 *   <input {{asInput}} {{maskito this.cardMask}} {{on "input" this.update}} />
 *
 * The mask shapes what is typed, pasted, dropped and autofilled, and every `input` listener on
 * the element reads the masked text. New options replace the mask; none (`undefined`) takes it
 * off; the same options object keeps the mask as it is, history and all, so build them once
 * (a getter with `@cached`, a constant, or a helper whose arguments don't change). A value set
 * from code isn't masked: put it through `maskText()` first, as `MaskedInput` does.
 *
 * It isn't named after the element: a binding named `input` would turn every `<input>` in the
 * template into a call to it.
 */
export class maskito extends Modifier<MaskitoSignature> {
  #element: MaskedElement | undefined
  #options: MaskitoOptions | null | undefined
  #teardown: (() => void) | undefined

  override modify(element: MaskedElement, [options]: [MaskitoOptions | null | undefined]): void {
    // The same options keep the same mask, with its history and its caret.
    if (element === this.#element && options === this.#options) return
    if (!this.#element) registerDestructor(this, () => this.#teardown?.())
    this.#teardown?.()
    this.#teardown = undefined
    this.#element = element
    this.#options = options
    if (!options) return
    const instance = new Maskito(element, options)
    const onInput = (event: Event) => fitToMask(element, options, event)
    element.addEventListener('input', onInput, { capture: true })
    this.#teardown = () => {
      element.removeEventListener('input', onInput, { capture: true })
      instance.destroy()
    }
  }
}

/**
 * Text as the mask would shape it: what a value set from code looks like masked.
 *
 *   maskText('5551234567', phoneMask) // '(555) 123-4567'
 *
 * Without options, or without text (`''`, `undefined`), it is returned as it is.
 */
export function maskText(text: string, options?: MaskitoOptions | null): string
export function maskText(
  text: string | undefined,
  options?: MaskitoOptions | null,
): string | undefined
export function maskText(
  text: string | undefined,
  options?: MaskitoOptions | null,
): string | undefined {
  if (!options || !text) return text
  return maskitoTransform(text, options)
}
